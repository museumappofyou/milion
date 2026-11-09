#!/usr/bin/env python3
"""route_phases.py - evidence-based model routing for the PHASES.md phase prompts.

What this script does
---------------------
1. Parses the real phase prompts out of PHASES.md (structure-aware, not a naive
   Markdown dump) and keeps each prompt verbatim with line numbers and a hash.
2. Asks TypeSafe Jev (System One API) to profile each prompt as a TASK ONLY.
   Jev never sees model names; it describes what kind of work the phase is.
3. Scores every model in a researched, evidence-backed capability registry
   against that task profile with deterministic routing logic.
4. Emits one primary model + thinking level per phase, a fallback, confidence,
   and the reasoning behind it.

Architecture (intentionally layered)
------------------------------------
    phase prompt -> Jev task profiler -> capability requirements
                 -> model capability registry -> deterministic router
                 -> thinking policy -> report

Jev understands the task. The registry understands the models. The router
matches. Adding a future model means editing the registry, not Jev.

Usage
-----
    python route_phases.py PHASES.md                # full run (Jev + routing)
    python route_phases.py PHASES.md --dry-run      # parse only, no API calls
    python route_phases.py PHASES.md --refresh      # force OpenCode Go catalog refresh
    python route_phases.py PHASES.md --force-jev    # recompute every Jev profile
    python route_phases.py PHASES.md --offline      # no network at all (cache/embedded)
    python route_phases.py PHASES.md --cost-aversion high   # push harder toward cheap models
    python route_phases.py --jev-check              # one minimal Jev API sanity call
    python route_phases.py PHASES.md --selftest     # synthetic profiles, no API calls

Cost policy: among models whose capability fit clears the phase's bar, the
cheapest effective-cost model wins. The bar tightens as execution risk rises,
so risky phases keep frontier quality while routine phases use cheap models.

Outputs (written next to this script by default):
    phase_routing.json          machine-readable, one entry per phase
    PHASE_MODEL_ROUTING.md      the human-readable routing plan

Dependencies: Python 3.11+ standard library only.
Environment:  TYPESAFE_API_KEY must be set for Jev calls. The key is read from
              the environment, never written to any output, log or cache file.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Optional

SCRIPT_VERSION = "1.1.0"
JEV_SCHEMA_VERSION = "taskprof-v2"
COST_MODEL_VERSION = "cost-v1"

# The brief estimated ~40 phases. This file genuinely contains 41 prompts:
# P00..P40 inclusive. P00 ("Milion identity and plan") is marked done in the
# file but its prompt is retained as a re-runnable audit, so it is a real
# prompt and is routed like the others. We assert 41 rather than silently
# forcing 40; the generated report states the same.
EXPECTED_PROMPT_COUNT = 41
EXPECTED_FIRST_PHASE = 0
EXPECTED_LAST_PHASE = 40

JEV_ENDPOINT = "https://api.typesafe.ai/v1/systemone"
JEV_MODEL_PRIMARY = "jev-latest"
JEV_MODEL_FALLBACK = "jev-1.13.0"

OPENCODE_GO_MODELS_URL = "https://opencode.ai/zen/go/v1/models"
OPENCODE_GO_CATALOG_TTL_HOURS = 24

DEFAULT_CACHE_DIR = ".phase_router_cache"
CATALOG_RESEARCHED_AT = "2026-09-27"

# ---------------------------------------------------------------------------
# Sources used for the model registry (auditability).
# ---------------------------------------------------------------------------

SOURCES: dict[str, dict[str, str]] = {
    "anthropic_models": {
        "title": "Anthropic - Models overview",
        "url": "https://docs.anthropic.com/en/docs/about-claude/models",
        "accessed": "2026-09-27",
        "supports": "Current Claude lineup (Fable 5.1, Opus 5, Sonnet 5, Haiku 4.5), thinking modes, context and pricing.",
    },
    "anthropic_pricing": {
        "title": "Claude - Plans & Pricing (Team)",
        "url": "https://claude.com/pricing",
        "accessed": "2026-09-27",
        "supports": "Team plan includes Opus/Sonnet/Haiku, no Fable; 200k context on Team; seat usage model.",
    },
    "anthropic_team": {
        "title": "Anthropic Help - What is the Team plan?",
        "url": "https://support.claude.com/en/articles/9266767-what-is-the-team-plan",
        "accessed": "2026-09-27",
        "supports": "Team Standard 1.25x Pro per-session, Premium 6.25x; Claude Code included; shared pool.",
    },
    "anthropic_opus55": {
        "title": "Anthropic - Introducing Claude Opus 5.5 / What's new in Opus 5.5",
        "url": "https://www.anthropic.com/claude-opus-5-5",
        "accessed": "2026-09-27",
        "supports": "Opus 5.5 default effort medium, adaptive thinking always on, Terminal-Bench 4.0 / FrontierCode / CursorBench results.",
    },
    "anthropic_effort": {
        "title": "Claude Platform Docs - Effort",
        "url": "https://platform.claude.com/docs/en/build-with-claude/effort",
        "accessed": "2026-09-27",
        "supports": "low/medium/high/xhigh/max effort, per-model defaults, recommendation for coding/agentic work.",
    },
    "claude_code_effort": {
        "title": "Claude Academy - Choosing the right effort level in Claude Code",
        "url": "https://academy.claude.com/tutorials/choosing-the-right-effort-level-in-claude-code",
        "accessed": "2026-09-27",
        "supports": "/effort control, --effort flag, CLAUDE_CODE_EFFORT_LEVEL, ultracode is not an effort level.",
    },
    "claude_code_default": {
        "title": "Claude Code 2.1.280 coverage (Opus 5.5 default)",
        "url": "https://www.buildthisnow.com/fr/blog/guide/mechanics/claude-opus-5-5-in-claude-code",
        "accessed": "2026-09-27",
        "supports": "Opus 5.5 default on Pro/Team Standard, medium default effort, 1M context on Claude Code.",
    },
    "openai_models": {
        "title": "OpenAI / ChatGPT Learn - Models (Work + Codex)",
        "url": "https://learn.chatgpt.com/docs/models",
        "accessed": "2026-09-27",
        "supports": "GPT-6 Astra/Sol/Luna availability, reasoning efforts (low..max, ultra), Ultra subagents, Plus access via Work/Codex.",
    },
    "openai_56": {
        "title": "OpenAI Help Center - GPT-5.6 in ChatGPT",
        "url": "https://help.openai.com/en/articles/20001354-gpt-5-6-in-chatgpt",
        "accessed": "2026-09-27",
        "supports": "Plus gets Medium/High reasoning in Chat; Extra High/Pro are plan-gated; Codex/Work model split.",
    },
    "openai_gpt6": {
        "title": "OpenAI - GPT-6 Astra announcement",
        "url": "https://openai.com/index/gpt-6-astra/",
        "accessed": "2026-09-27",
        "supports": "Astra availability across plans, ARC-AGI results, agentic positioning.",
    },
    "openai_pricing": {
        "title": "ChatGPT Pricing - Plus",
        "url": "https://chatgpt.com/pricing/",
        "accessed": "2026-09-27",
        "supports": "Plus reasoning context 256K, GPT Reasoning input maximum ~320 pages.",
    },
    "opencode_go_docs": {
        "title": "OpenCode - Go",
        "url": "https://opencode.ai/docs/go/",
        "accessed": "2026-09-27",
        "supports": "OpenCode Go model list, exact model IDs, endpoints, $10/month subscription.",
    },
    "opencode_go_models_endpoint": {
        "title": "OpenCode Go live models endpoint",
        "url": "https://opencode.ai/zen/go/v1/models",
        "accessed": "2026-09-27",
        "supports": "Runtime availability refresh; authoritative current ID list.",
    },
    "models_dev_go": {
        "title": "Models.dev - OpenCode Go provider metadata",
        "url": "https://models.opencode.ai/providers/opencode-go/",
        "accessed": "2026-09-27",
        "supports": "Per-model context, output, price, reasoning/tool/structured flags.",
    },
    "opencode_models_docs": {
        "title": "OpenCode - Models / variants",
        "url": "https://opencode.ai/docs/models/",
        "accessed": "2026-09-27",
        "supports": "reasoningEffort, thinking budgetTokens, built-in variants for Anthropic/OpenAI/Google families.",
    },
    "opencode_go_usage": {
        "title": "OpenCode Go usage limits (provider integration docs)",
        "url": "https://docs.docker.com/ai/docker-agent/providers/opencode-go/",
        "accessed": "2026-09-27",
        "supports": "Go limits: $12 / 5h rolling, $30 / week, $60 / month; more expensive models consume more.",
    },
    "tb4_aa": {
        "title": "Artificial Analysis - Terminal-Bench 4.0 leaderboard",
        "url": "https://artificialanalysis.ai/evaluations/terminalbench-4-0",
        "accessed": "2026-09-27",
        "supports": "Agentic terminal benchmark: Opus 5.5 59.6, GPT-6 Astra 59.6, Fable 5.1 55.1, GPT-6 Sol 43.9, GLM-5.3 41.9, GPT-5.6 Sol 39.9, Qwen3.8 Max 38.9, MiMo-V2.6-Pro 34.8, GLM-5.3 Flash 32.8, DeepSeek V4.1 Flash 26.8, Grok 4.7 25.8.",
    },
    "tb21": {
        "title": "Terminal-Bench 2.1 leaderboards (BenchLM / CodingFleet aggregate)",
        "url": "https://benchlm.ai/benchmarks/terminalbench21",
        "accessed": "2026-09-27",
        "supports": "DeepSeek V4.1 Flash 90.6, MiMo-V2.6-Pro 89.9, Muse Spark 1.3 88.8, Kimi K3 88.3, GLM-5.3 88.2, DeepSeek V4 Pro 87.9, Qwen3.8 Max 86.6, Hy4 85.4, GPT-5.6 Sol 91.9. Harness differs from TB4.0; use directionally.",
    },
    "webdev_arena": {
        "title": "Code Arena - WebDev leaderboard",
        "url": "https://arena.ai/leaderboard/code/webdev/overall",
        "accessed": "2026-09-27",
        "supports": "Front-end/visual arena: GPT-6 Astra #1, Fable 5.1 #2, Opus 5 #3, Qwen3.8 Max #4, Kimi K3 #5, Muse Spark 1.3 #8, Grok 4.6/4.7, GPT-5.6 Sol, GLM-5.3, Hy4.",
    },
    "typesafe_docs": {
        "title": "TypeSafe AI - Jev documentation",
        "url": "https://docs.typesafe.ai/",
        "accessed": "2026-09-27",
        "supports": "System One API: POST /v1/systemone, model jev-latest, choice/score/noul primitives, calibrated probabilities.",
    },
    "typesafe_blog": {
        "title": "TypeSafe AI - Introducing System One Models & Jev",
        "url": "https://typesafe.ai/blog/introducing-system-one-models-and-jev",
        "accessed": "2026-09-27",
        "supports": "Jev positioning: task-shaped decisions, calibrated confidence, $0.042/MTok input, 70-500ms latency.",
    },
}

# ---------------------------------------------------------------------------
# Capability dimensions (reflect THIS project: Flutter/Android, 2.5D/3D
# graphics, ML/CV recognition, Python pipelines, Istanbul content research,
# audio DSP, map/geodata, accessibility, release engineering).
# ---------------------------------------------------------------------------

DIMS: list[str] = [
    "direct_implementation",   # write correct, scoped code fast
    "repo_wide_reasoning",     # understand interacting parts of a codebase
    "architecture",            # system design, interfaces, long-term structure
    "deep_debugging",          # diagnose hard failures (graphics perf, async, platform)
    "agentic_tool_use",        # long tool loops, edits, command execution
    "instruction_following",   # obey explicit constraints and checklists
    "long_spec_adherence",     # keep many detailed requirements straight
    "long_context",            # large inputs (corpus, big specs, 100KB+ documents)
    "code_review",
    "refactoring",
    "test_reasoning",          # test design, edge cases, verification strategy
    "frontend_ui",             # UI/layout/interaction implementation quality
    "visual_reasoning",        # aesthetic judgment, visual design, image reading
    "graphics_3d",             # real-time 3D, shaders, geometry, rendering math
    "ml_cv",                   # ML/CV engineering: ONNX, training, evaluation
    "audio_dsp",               # audio DSP, FFT, convolution, TTS/sound
    "data_pipeline",           # Python/data tooling, ETL, validators, geometry tooling
    "research",                # factual research, sourcing, synthesis
    "ambiguity_handling",      # act sensibly on underspecified instructions
    "precision",               # exactness, anti-slop/honesty rules, bilingual correctness
    "speed",                   # latency / interactive responsiveness
    "usage_efficiency",        # subscription-quota friendliness (high = cheap/light)
]

assert len(DIMS) == len(set(DIMS)), "duplicate dimension names"


def vec(*values: float) -> dict[str, float]:
    if len(values) != len(DIMS):
        raise AssertionError(
            f"capability vector has {len(values)} values, expected {len(DIMS)}"
        )
    return dict(zip(DIMS, [float(v) for v in values]))


# ---------------------------------------------------------------------------
# Model capability registry (researched snapshot; see SOURCES above).
#
# Scores are 0-10 estimates grounded in the cited evidence, not fake
# percentages. Surface is a routing target, not an API account:
#   claude_team    -> Claude Code signed in with the Team subscription
#   chatgpt_plus   -> ChatGPT Plus Work/Codex (manual paste; not an API account)
#   opencode_go    -> OpenCode Go subscription ($10/mo)
# ---------------------------------------------------------------------------

MODEL_REGISTRY: dict[str, dict[str, Any]] = {
    # ------------------------- Claude Team -------------------------
    "claude-opus-5-5": {
        "surface": "claude_team",
        "model_id": "claude-opus-5-5",
        "display": "Claude Opus 5.5",
        "context_tokens": 200_000,
        "vision": True,
        "price_per_mtok": {"input": 4.00, "output": 20.00,
                           "basis": "Anthropic API list price at Opus 5.5 launch (fast mode $8/$40)."},
        "usage_pressure": 0.90,
        "scores": vec(
            9.6, 9.5, 9.6, 9.6, 9.7, 9.6, 9.5, 8.5, 9.5, 9.4,
            9.3, 9.2, 9.0, 9.3, 8.9, 8.7, 9.2, 9.0, 9.3, 9.5,
            7.5, 3.0,
        ),
        "score_confidence": 0.85,
        "thinking": {
            "control": "adaptive_effort",
            "levels": ["low", "medium", "high", "xhigh", "max"],
            "default": "medium",
            "native_prefix": "Claude Code /effort",
            "verified": True,
            "notes": "Adaptive thinking always on; effort is the only reasoning control. "
                     "Default medium on 2.1.280+; docs recommend xhigh for demanding long sessions.",
        },
        "availability": {
            "status": "documented",
            "detail": "Included on Team (Opus row = Yes). Default Opus on Team Standard since Claude Code 2.1.280 (2026-09-22).",
        },
        "evidence": {
            "agentic_tool_use": "Terminal-Bench 4.0 59.6 (AA, tied #1).",
            "frontend_ui": "WebDev data-analytics arena #1 on Opus 5.5 max (2026-09-25).",
            "architecture": "Anthropic positions Opus for complex agentic coding; vendor reports best merge-rate per cost on FrontierCode (54.6 at default effort).",
            "usage_efficiency": "Opus family is separately metered on Team; heaviest quota draw of the three Team models.",
        },
        "sources": ["anthropic_models", "anthropic_pricing", "anthropic_opus55", "anthropic_effort",
                    "claude_code_effort", "claude_code_default", "tb4_aa", "webdev_arena"],
    },
    "claude-sonnet-5": {
        "surface": "claude_team",
        "model_id": "claude-sonnet-5",
        "display": "Claude Sonnet 5",
        "context_tokens": 200_000,
        "vision": True,
        "price_per_mtok": {"input": 2.00, "output": 10.00,
                           "basis": "Anthropic API list price (models overview)."},
        "usage_pressure": 0.45,
        "scores": vec(
            8.5, 8.3, 8.0, 8.2, 8.5, 8.8, 8.5, 8.5, 8.5, 8.3,
            8.5, 8.5, 8.0, 7.8, 7.8, 8.0, 8.2, 8.0, 8.0, 8.5,
            9.0, 6.0,
        ),
        "score_confidence": 0.75,
        "thinking": {
            "control": "adaptive_effort",
            "levels": ["low", "medium", "high", "xhigh", "max"],
            "default": "high",
            "native_prefix": "Claude Code /effort",
            "verified": True,
            "notes": "Adaptive thinking; defaults high; medium documented as roughly Sonnet-4.6-at-high.",
        },
        "availability": {
            "status": "documented",
            "detail": "Included on Team (Sonnet row = Yes).",
        },
        "evidence": {
            "direct_implementation": "Anthropic: 'best combination of speed and intelligence'.",
            "agentic_tool_use": "Terminal-Bench 2.1 80.4 (aggregate leaderboard); competent but below Opus class.",
            "usage_efficiency": "Cheaper per token than Opus on the shared Team pool.",
        },
        "sources": ["anthropic_models", "anthropic_pricing", "anthropic_effort", "claude_code_effort", "tb21"],
    },
    "claude-haiku-4-5": {
        "surface": "claude_team",
        "model_id": "claude-haiku-4-5",
        "display": "Claude Haiku 4.5",
        "context_tokens": 200_000,
        "vision": True,
        "price_per_mtok": {"input": 1.00, "output": 5.00,
                           "basis": "Anthropic API list price (models overview)."},
        "usage_pressure": 0.15,
        "scores": vec(
            7.0, 6.5, 6.0, 6.2, 7.0, 7.5, 6.8, 6.5, 6.5, 6.5,
            7.0, 6.8, 6.2, 5.8, 5.8, 6.0, 6.5, 6.0, 6.0, 7.0,
            9.5, 8.5,
        ),
        "score_confidence": 0.65,
        "thinking": {
            "control": "automatic",
            "levels": [],
            "default": "automatic",
            "native_prefix": None,
            "verified": True,
            "notes": "Fastest current Claude; extended thinking toggle only, no effort parameter.",
        },
        "availability": {
            "status": "documented",
            "detail": "Included on Team (Haiku row = Yes).",
        },
        "evidence": {
            "speed": "Anthropic: fastest model with near-frontier intelligence.",
            "usage_efficiency": "Lightest quota draw of the Team models.",
            "direct_implementation": "Suitable for well-scoped edits; not positioned for repo-wide reasoning.",
        },
        "sources": ["anthropic_models", "anthropic_pricing"],
    },
    # ------------------------- ChatGPT Plus -------------------------
    "gpt-6-astra": {
        "surface": "chatgpt_plus",
        "model_id": "gpt-6-astra",
        "display": "GPT-6 Astra",
        "context_tokens": 1_100_000,
        "vision": True,
        "price_per_mtok": {"input": 10.00, "output": 50.00,
                           "basis": "OpenAI API list price shown for gpt-6-astra (Code Arena)."},
        "usage_pressure": 0.85,
        "scores": vec(
            9.7, 9.6, 9.7, 9.6, 9.7, 9.5, 9.6, 9.5, 9.6, 9.5,
            9.5, 9.7, 9.5, 9.4, 9.4, 9.4, 9.5, 9.6, 9.7, 9.4,
            6.5, 2.5,
        ),
        "score_confidence": 0.85,
        "thinking": {
            "control": "effort",
            "levels": ["low", "medium", "high", "xhigh", "max"],
            "default": "low",
            "native_prefix": "Codex reasoning effort",
            "verified": True,
            "notes": "Light (low) is the recommended starting preset; Extra High may be omitted "
                     "on some paid plans; Max appears only when enabled in settings.",
        },
        "availability": {
            "status": "documented",
            "detail": "Included in ChatGPT Work and Codex on Plus (rolling out from 2026-09-22). "
                      "Not selectable in Chat on Plus; GPT-6 Pro (Astra) in Chat is Pro/Business/Enterprise.",
        },
        "evidence": {
            "frontend_ui": "Code Arena WebDev overall #1 (1800 Elo, 2026-09-11).",
            "agentic_tool_use": "Terminal-Bench 4.0 59.6 (AA, tied #1 with Opus 5.5).",
            "visual_reasoning": "Strongest WebDev visual results and OpenAI's top multi-step model.",
            "usage_efficiency": "Metered separately in Work/Codex; heaviest draw on the Plus surface.",
        },
        "sources": ["openai_models", "openai_gpt6", "openai_56", "tb4_aa", "webdev_arena"],
    },
    "gpt-6-sol": {
        "surface": "chatgpt_plus",
        "model_id": "gpt-6-sol",
        "display": "GPT-6 Sol",
        "context_tokens": 1_100_000,
        "vision": True,
        "price_per_mtok": {"input": 2.00, "output": 10.00,
                           "basis": "OpenAI API list price shown for gpt-6-sol (Code Arena)."},
        "usage_pressure": 0.50,
        "scores": vec(
            9.2, 9.1, 9.2, 9.1, 9.2, 9.3, 9.2, 9.3, 9.1, 9.1,
            9.2, 9.3, 9.0, 9.2, 9.2, 9.2, 9.2, 9.2, 9.2, 9.2,
            7.5, 5.0,
        ),
        "score_confidence": 0.80,
        "thinking": {
            "control": "effort",
            "levels": ["low", "medium", "high", "xhigh", "max", "ultra"],
            "default": "medium",
            "native_prefix": "Codex reasoning effort",
            "verified": True,
            "notes": "Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for "
                     "decomposable tasks. OpenAI recommends Medium as the start.",
        },
        "availability": {
            "status": "documented",
            "detail": "Included in ChatGPT Work and Codex on Plus; not in Chat. "
                      "Use `codex --model gpt-6-sol` or the desktop model picker.",
        },
        "evidence": {
            "agentic_tool_use": "Terminal-Bench 4.0 43.9 (max); the recommended Plus workhorse in Codex.",
            "frontend_ui": "WebDev data-analytics #5 on GPT-6 Sol max (1611 Elo).",
            "long_context": "1.1M context window with Codex experimental context management on Plus.",
        },
        "sources": ["openai_models", "openai_56", "openai_pricing", "tb4_aa", "webdev_arena"],
    },
    "gpt-6-luna": {
        "surface": "chatgpt_plus",
        "model_id": "gpt-6-luna",
        "display": "GPT-6 Luna",
        "context_tokens": 1_050_000,
        "vision": True,
        "price_per_mtok": {"input": 0.10, "output": 0.50,
                           "basis": "OpenAI API list price shown for gpt-6-luna (Code Arena)."},
        "usage_pressure": 0.20,
        "scores": vec(
            8.0, 7.6, 7.0, 7.4, 7.5, 8.4, 7.8, 9.0, 7.6, 7.6,
            8.0, 8.2, 7.6, 7.1, 7.2, 7.4, 7.8, 7.4, 7.3, 8.1,
            9.3, 9.0,
        ),
        "score_confidence": 0.65,
        "thinking": {
            "control": "effort",
            "levels": ["low", "medium", "high", "xhigh", "max"],
            "default": "high",
            "native_prefix": "Codex reasoning effort",
            "verified": True,
            "notes": "OpenAI recommends High for Luna; supports up to Max but not Ultra.",
        },
        "availability": {
            "status": "documented",
            "detail": "Included in ChatGPT Work and Codex on Plus (desktop app).",
        },
        "evidence": {
            "direct_implementation": "Positioned for focused, repeatable tasks: extraction, transformation, focused coding.",
            "speed": "Efficiency model; cheap within Plus Work/Codex.",
            "usage_efficiency": "Lowest draw of the Plus models.",
        },
        "sources": ["openai_models", "openai_pricing"],
    },
    "gpt-5-6-sol": {
        "surface": "chatgpt_plus",
        "model_id": "gpt-5.6-sol",
        "display": "GPT-5.6 Sol",
        "context_tokens": 256_000,
        "vision": True,
        "price_per_mtok": {"input": 4.00, "output": 20.00,
                           "basis": "OpenAI API list price shown for gpt-5.6-sol (Code Arena)."},
        "usage_pressure": 0.45,
        "scores": vec(
            9.0, 8.8, 8.8, 8.8, 9.0, 9.0, 8.9, 8.5, 8.8, 8.7,
            8.9, 9.0, 8.8, 8.7, 8.6, 8.6, 8.8, 8.8, 8.7, 8.8,
            8.5, 5.5,
        ),
        "score_confidence": 0.75,
        "thinking": {
            "control": "effort",
            "levels": ["instant", "medium", "high"],
            "default": "medium",
            "native_prefix": "ChatGPT reasoning picker",
            "verified": True,
            "notes": "In Chat on Plus only Instant/Medium/High are included; Extra High and Pro "
                     "are plan-gated. In Codex/Work the model exposes more effort levels.",
        },
        "availability": {
            "status": "documented",
            "detail": "Plus Chat surface: GPT-5.6 Sol with Medium/High reasoning. Also available in "
                      "Work and Codex during the GPT-6 rollout.",
        },
        "evidence": {
            "agentic_tool_use": "Terminal-Bench 4.0 39.9; Terminal-Bench 2.1 91.9 (#2).",
            "frontend_ui": "Code Arena WebDev 1617 Elo (xhigh, codex harness, 2026-09-11).",
            "speed": "Fast for a frontier-class model; good interactive turnaround.",
        },
        "sources": ["openai_models", "openai_56", "openai_pricing", "tb4_aa", "tb21", "webdev_arena"],
    },
    # ------------------------- OpenCode Go -------------------------
    # Go exposes a curated catalog; the live ID list is refreshed at runtime
    # from https://opencode.ai/zen/go/v1/models and intersected with this
    # registry. Thinking is controlled through OpenCode model variants /
    # provider options; levels marked unverified fall back to "automatic".
    "kimi-k3": {
        "surface": "opencode_go",
        "model_id": "kimi-k3",
        "display": "Kimi K3 (Go)",
        "context_tokens": 1_048_576,
        "vision": False,
        "usage_pressure": 1.00,
        "scores": vec(
            9.2, 9.1, 9.2, 9.1, 9.2, 9.0, 9.1, 9.6, 9.0, 9.0,
            9.0, 9.2, 9.0, 8.8, 8.8, 8.8, 9.0, 9.0, 9.0, 8.8,
            6.5, 1.5,
        ),
        "score_confidence": 0.80,
        "thinking": {
            "control": "opencode_variant",
            "levels": ["low", "high", "max"],
            "default": "automatic",
            "native_prefix": "OpenCode Go variant / reasoning option",
            "verified": False,
            "notes": "Independent runs label Kimi K3 at low and max effort; exact variant names "
                     "on the Go endpoint must be confirmed in the model picker.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime).",
        },
        "price_per_mtok": {"input": 3.00, "output": 15.00},
        "evidence": {
            "agentic_tool_use": "Terminal-Bench 2.1 88.3 (KimiCode at max reasoning); TB4.0 12.6.",
            "frontend_ui": "Code Arena WebDev overall #5 (1674 Elo, max).",
            "long_context": "1M-token context; strong long-document handling.",
            "usage_efficiency": "Most expensive Go model per token; burns the $60/mo allowance fastest.",
        },
        "sources": ["opencode_go_docs", "models_dev_go", "tb21", "tb4_aa", "webdev_arena"],
    },
    "kimi-k2.7-code": {
        "surface": "opencode_go",
        "model_id": "kimi-k2.7-code",
        "display": "Kimi K2.7 Code (Go)",
        "context_tokens": 262_144,
        "vision": False,
        "usage_pressure": 0.36,
        "scores": vec(
            8.8, 8.5, 8.4, 8.6, 8.8, 8.7, 8.5, 8.5, 8.3, 8.4,
            8.6, 8.4, 8.0, 8.0, 8.0, 8.0, 8.5, 7.8, 8.2, 8.6,
            8.0, 6.0,
        ),
        "score_confidence": 0.70,
        "thinking": {
            "control": "opencode_variant",
            "levels": ["low", "high"],
            "default": "automatic",
            "native_prefix": "OpenCode Go variant / reasoning option",
            "verified": False,
            "notes": "Code-specialized Kimi. Variant names not documented for the Go endpoint.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime).",
        },
        "price_per_mtok": {"input": 0.95, "output": 4.00},
        "evidence": {
            "direct_implementation": "Kimi code-specialized lineage; positioned for agentic coding.",
            "agentic_tool_use": "Kimi family strong on terminal-agent leaderboards (K3 class).",
            "usage_efficiency": "Mid-tier Go cost; cheaper than K3 by 4x on output.",
        },
        "sources": ["opencode_go_docs", "models_dev_go", "tb21"],
    },
    "glm-5.3": {
        "surface": "opencode_go",
        "model_id": "glm-5.3",
        "display": "GLM-5.3 (Go)",
        "context_tokens": 1_000_000,
        "vision": False,
        "usage_pressure": 0.36,
        "scores": vec(
            9.0, 8.9, 9.0, 8.9, 9.0, 8.9, 8.9, 9.3, 8.8, 8.8,
            8.8, 8.8, 8.5, 8.5, 8.5, 8.5, 8.9, 8.6, 8.7, 8.7,
            7.5, 5.5,
        ),
        "score_confidence": 0.80,
        "thinking": {
            "control": "opencode_variant",
            "levels": ["low", "high", "max"],
            "default": "automatic",
            "native_prefix": "OpenCode Go variant / reasoning option",
            "verified": False,
            "notes": "Leaderboards label GLM-5.3 at max and default efforts; variant names on Go unverified.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime).",
        },
        "price_per_mtok": {"input": 1.40, "output": 4.40},
        "evidence": {
            "agentic_tool_use": "Terminal-Bench 4.0 41.9 (best non-frontier group); Terminal-Bench 2.1 88.2.",
            "frontend_ui": "Code Arena WebDev 1614 Elo.",
            "usage_efficiency": "Reasonably priced for its capability class within Go.",
        },
        "sources": ["opencode_go_docs", "models_dev_go", "tb4_aa", "tb21", "webdev_arena"],
    },
    "glm-5.3-flash": {
        "surface": "opencode_go",
        "model_id": "glm-5.3-flash",
        "display": "GLM-5.3-Flash (Go)",
        "context_tokens": 1_000_000,
        "vision": False,
        "usage_pressure": 0.13,
        "scores": vec(
            8.4, 8.1, 7.8, 8.1, 8.3, 8.4, 8.2, 9.2, 8.0, 8.1,
            8.3, 8.3, 7.8, 7.7, 7.8, 7.8, 8.4, 7.8, 7.9, 8.3,
            9.0, 9.5,
        ),
        "score_confidence": 0.75,
        "thinking": {
            "control": "opencode_variant",
            "levels": ["low", "high"],
            "default": "automatic",
            "native_prefix": "OpenCode Go variant / reasoning option",
            "verified": False,
            "notes": "Flash tier; variant names on Go unverified.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime).",
        },
        "price_per_mtok": {"input": 0.15, "output": 0.50},
        "evidence": {
            "agentic_tool_use": "Terminal-Bench 4.0 32.8 and TB2.1 84.3, unusually strong for flash-tier pricing.",
            "usage_efficiency": "Among the cheapest viable coding models in Go.",
        },
        "sources": ["opencode_go_docs", "models_dev_go", "tb4_aa", "tb21"],
    },
    "deepseek-v4-pro": {
        "surface": "opencode_go",
        "model_id": "deepseek-v4-pro",
        "display": "DeepSeek V4 Pro (Go)",
        "context_tokens": 1_000_000,
        "vision": False,
        "usage_pressure": 0.60,
        "scores": vec(
            9.0, 8.9, 9.0, 9.0, 8.9, 8.7, 8.8, 9.4, 8.7, 8.8,
            8.8, 8.4, 8.2, 8.3, 8.6, 8.6, 8.8, 8.4, 8.5, 8.5,
            7.0, 4.0,
        ),
        "score_confidence": 0.75,
        "thinking": {
            "control": "opencode_variant",
            "levels": ["low", "high", "max"],
            "default": "automatic",
            "native_prefix": "OpenCode Go variant / reasoning option",
            "verified": False,
            "notes": "Benchmark runs label V4 Pro at max effort; variant names on Go unverified.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime).",
        },
        "price_per_mtok": {"input": 0.66, "output": 1.98},
        "evidence": {
            "agentic_tool_use": "Terminal-Bench 2.1 87.9; TB4.0 harness result lower at 14.6 (harness-sensitive).",
            "deep_debugging": "DeepSeek reasoning lineage; strong at methodical analysis.",
            "usage_efficiency": "Mid-cost within Go; better value than Kimi K3.",
        },
        "sources": ["opencode_go_docs", "models_dev_go", "tb4_aa", "tb21"],
    },
    "deepseek-v4.1-flash": {
        "surface": "opencode_go",
        "model_id": "deepseek-v4.1-flash",
        "display": "DeepSeek V4.1 Flash (Go)",
        "context_tokens": 1_000_000,
        "vision": False,
        "usage_pressure": 0.14,
        "scores": vec(
            8.5, 8.2, 8.0, 8.3, 8.6, 8.5, 8.4, 9.3, 8.1, 8.2,
            8.5, 8.2, 8.0, 8.0, 8.2, 8.2, 8.6, 7.9, 8.1, 8.4,
            8.8, 9.5,
        ),
        "score_confidence": 0.75,
        "thinking": {
            "control": "opencode_variant",
            "levels": ["low", "high", "max"],
            "default": "automatic",
            "native_prefix": "OpenCode Go variant / reasoning option",
            "verified": False,
            "notes": "Terminal-Bench runs label this model at max effort; variant names on Go unverified.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime).",
        },
        "price_per_mtok": {"input": 0.15, "output": 0.60},
        "evidence": {
            "agentic_tool_use": "Terminal-Bench 2.1 #1 at 90.6 (mini-SWE 90.3, Claude Code 88.0) at flash pricing.",
            "usage_efficiency": "MIT-licensed, $0.15/$0.60; excellent quality-per-quota in Go.",
        },
        "sources": ["opencode_go_docs", "models_dev_go", "tb21", "tb4_aa"],
    },
    "deepseek-v4-flash-vision-exp": {
        "surface": "opencode_go",
        "model_id": "deepseek-v4-flash-vision-exp",
        "display": "DeepSeek V4 Flash Vision Exp (Go)",
        "context_tokens": 1_000_000,
        "vision": True,
        "usage_pressure": 0.14,
        "scores": vec(
            8.0, 7.7, 7.4, 7.6, 7.8, 7.8, 7.8, 9.2, 7.5, 7.6,
            7.8, 7.6, 8.8, 7.6, 8.2, 7.5, 8.0, 7.6, 7.4, 7.8,
            8.6, 9.3,
        ),
        "score_confidence": 0.60,
        "thinking": {
            "control": "opencode_variant",
            "levels": ["low", "high", "max"],
            "default": "automatic",
            "native_prefix": "OpenCode Go variant / reasoning option",
            "verified": False,
            "notes": "Experimental vision variant; thinking controls undocumented for Go.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime); experimental.",
        },
        "price_per_mtok": {"input": 0.15, "output": 0.60},
        "evidence": {
            "visual_reasoning": "Vision-capable DeepSeek variant; useful for screenshot/UI and scene work when Claude/GPT vision is unavailable.",
            "usage_efficiency": "Cheap vision option inside Go.",
        },
        "sources": ["opencode_go_docs", "models_dev_go", "tb4_aa"],
    },
    "qwen3.8-max": {
        "surface": "opencode_go",
        "model_id": "qwen3.8-max",
        "display": "Qwen3.8 Max (Go)",
        "context_tokens": 1_000_000,
        "vision": False,
        "usage_pressure": 0.50,
        "scores": vec(
            9.1, 9.0, 9.1, 9.0, 9.0, 8.9, 9.0, 9.3, 8.9, 8.9,
            8.8, 9.4, 9.2, 9.0, 8.8, 8.8, 8.9, 8.7, 8.8, 8.7,
            6.8, 3.5,
        ),
        "score_confidence": 0.80,
        "thinking": {
            "control": "opencode_variant",
            "levels": ["low", "high", "max"],
            "default": "automatic",
            "native_prefix": "OpenCode Go variant / reasoning option",
            "verified": False,
            "notes": "Qwen thinking controls are provider-shaped; variant names on Go unverified.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime).",
        },
        "price_per_mtok": {"input": 2.00, "output": 6.00},
        "evidence": {
            "frontend_ui": "Code Arena WebDev overall #4 (1681 Elo) and #1 non-OpenAI family on several arenas.",
            "agentic_tool_use": "Terminal-Bench 4.0 38.9; Terminal-Bench 2.1 86.6.",
            "visual_reasoning": "Consistently top-5 in visual arenas.",
            "usage_efficiency": "One of the pricier Go models; use where visual quality matters.",
        },
        "sources": ["opencode_go_docs", "models_dev_go", "tb4_aa", "tb21", "webdev_arena"],
    },
    "qwen3.8-flash": {
        "surface": "opencode_go",
        "model_id": "qwen3.8-flash",
        "display": "Qwen3.8 Flash (Go)",
        "context_tokens": 1_000_000,
        "vision": False,
        "usage_pressure": 0.14,
        "scores": vec(
            8.2, 7.9, 7.6, 7.9, 8.1, 8.2, 8.1, 9.2, 7.8, 7.9,
            8.1, 8.6, 8.2, 7.8, 7.7, 7.7, 8.2, 7.6, 7.7, 8.1,
            8.9, 9.3,
        ),
        "score_confidence": 0.65,
        "thinking": {
            "control": "opencode_variant",
            "levels": ["low", "high"],
            "default": "automatic",
            "native_prefix": "OpenCode Go variant / reasoning option",
            "verified": False,
            "notes": "Flash tier; variants undocumented for Go.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime).",
        },
        "price_per_mtok": {"input": 0.15, "output": 0.47},
        "evidence": {
            "usage_efficiency": "Cheapest Qwen tier in Go; good for bulk scoped implementation.",
        },
        "sources": ["opencode_go_docs", "models_dev_go", "webdev_arena"],
    },
    "minimax-m3": {
        "surface": "opencode_go",
        "model_id": "minimax-m3",
        "display": "MiniMax M3 (Go)",
        "context_tokens": 1_000_000,
        "vision": False,
        "usage_pressure": 0.20,
        "scores": vec(
            8.4, 8.2, 8.2, 8.2, 8.6, 8.3, 8.3, 9.2, 8.0, 8.1,
            8.3, 8.2, 8.0, 7.8, 7.8, 7.8, 8.3, 7.8, 8.0, 8.1,
            8.0, 6.5,
        ),
        "score_confidence": 0.65,
        "thinking": {
            "control": "opencode_variant",
            "levels": ["low", "high", "max"],
            "default": "automatic",
            "native_prefix": "OpenCode Go variant / reasoning option",
            "verified": False,
            "notes": "MiniMax models are served through the Anthropic-compatible endpoint; thinking may be budget-based.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime).",
        },
        "price_per_mtok": {"input": 0.30, "output": 1.20},
        "evidence": {
            "agentic_tool_use": "Positioned as an agentic-workhorse model; Terminal-Bench 2.1 66.0 (older harness).",
            "usage_efficiency": "Cheap mid-tier; good default when Claude/GPT usage must be preserved.",
        },
        "sources": ["opencode_go_docs", "models_dev_go", "tb21"],
    },
    "mimo-v2.6-pro": {
        "surface": "opencode_go",
        "model_id": "mimo-v2.6-pro",
        "display": "MiMo-V2.6-Pro (Go)",
        "context_tokens": 1_048_576,
        "vision": False,
        "usage_pressure": 0.20,
        "scores": vec(
            8.8, 8.5, 8.4, 8.6, 8.7, 8.6, 8.5, 9.3, 8.4, 8.5,
            8.6, 8.4, 8.2, 8.2, 8.4, 8.2, 8.7, 8.0, 8.3, 8.5,
            8.0, 6.0,
        ),
        "score_confidence": 0.70,
        "thinking": {
            "control": "opencode_variant",
            "levels": ["low", "high", "max"],
            "default": "automatic",
            "native_prefix": "OpenCode Go variant / reasoning option",
            "verified": False,
            "notes": "Variant names undocumented for Go.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime).",
        },
        "price_per_mtok": {"input": 0.43, "output": 0.87},
        "evidence": {
            "agentic_tool_use": "Terminal-Bench 2.1 89.9 (#4); Terminal-Bench 4.0 34.8.",
            "usage_efficiency": "Cheap for its agentic benchmark position.",
        },
        "sources": ["opencode_go_docs", "models_dev_go", "tb21", "tb4_aa"],
    },
    "mimo-v2.5-pro": {
        "surface": "opencode_go",
        "model_id": "mimo-v2.5-pro",
        "display": "MiMo-V2.5-Pro (Go)",
        "context_tokens": 1_048_576,
        "vision": False,
        "usage_pressure": 0.16,
        "scores": vec(
            8.3, 8.0, 7.8, 8.0, 8.2, 8.2, 8.1, 9.3, 7.9, 8.0,
            8.2, 8.0, 7.8, 7.7, 8.0, 7.7, 8.3, 7.7, 7.8, 8.2,
            8.5, 8.0,
        ),
        "score_confidence": 0.60,
        "thinking": {
            "control": "opencode_variant",
            "levels": ["low", "high"],
            "default": "automatic",
            "native_prefix": "OpenCode Go variant / reasoning option",
            "verified": False,
            "notes": "Previous-generation MiMo; variants undocumented for Go.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime).",
        },
        "price_per_mtok": {"input": 0.43, "output": 0.87},
        "evidence": {
            "usage_efficiency": "Cheap, long-context generalist.",
        },
        "sources": ["opencode_go_docs", "models_dev_go", "tb21"],
    },
    "grok-4.6": {
        "surface": "opencode_go",
        "model_id": "grok-4.6",
        "display": "Grok 4.6 (Go)",
        "context_tokens": 500_000,
        "vision": False,
        "usage_pressure": 0.46,
        "scores": vec(
            8.7, 8.4, 8.4, 8.4, 8.7, 8.4, 8.3, 8.3, 8.3, 8.3,
            8.4, 8.9, 8.6, 8.4, 8.2, 8.2, 8.3, 8.5, 8.4, 8.3,
            7.8, 4.5,
        ),
        "score_confidence": 0.70,
        "thinking": {
            "control": "opencode_variant",
            "levels": ["low", "medium", "high", "xhigh"],
            "default": "automatic",
            "native_prefix": "OpenCode Go variant / reasoning option",
            "verified": False,
            "notes": "xAI reasoning-effort style labels seen in public runs; Go variant names unverified.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime).",
        },
        "price_per_mtok": {"input": 2.00, "output": 6.00},
        "evidence": {
            "frontend_ui": "Code Arena WebDev 1618 Elo (high).",
            "agentic_tool_use": "Terminal-Bench 2.1 84.3; TB4.0 21.2.",
            "research": "xAI models show broad generalist strength.",
        },
        "sources": ["opencode_go_docs", "models_dev_go", "tb21", "tb4_aa", "webdev_arena"],
    },
    "grok-4.7": {
        "surface": "opencode_go",
        "model_id": "grok-4.7",
        "display": "Grok 4.7 (Go)",
        "context_tokens": 500_000,
        "vision": False,
        "usage_pressure": 0.46,
        "scores": vec(
            8.8, 8.5, 8.4, 8.5, 8.5, 8.6, 8.5, 8.3, 8.5, 8.5,
            8.5, 9.0, 8.8, 8.6, 8.3, 8.3, 8.5, 8.6, 8.6, 8.5,
            7.6, 4.3,
        ),
        "score_confidence": 0.70,
        "thinking": {
            "control": "opencode_variant",
            "levels": ["low", "medium", "high", "xhigh"],
            "default": "automatic",
            "native_prefix": "OpenCode Go variant / reasoning option",
            "verified": False,
            "notes": "Same control shape as Grok 4.6; unverified on Go.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime).",
        },
        "price_per_mtok": {"input": 2.00, "output": 6.00},
        "evidence": {
            "frontend_ui": "Code Arena WebDev React 1646 Elo (xhigh).",
            "agentic_tool_use": "Terminal-Bench 4.0 25.8; newer Grok generation.",
        },
        "sources": ["opencode_go_docs", "models_dev_go", "tb4_aa", "webdev_arena"],
    },
    "gpt-6-luna-go": {
        "surface": "opencode_go",
        "model_id": "gpt-6-luna",
        "display": "GPT-6 Luna (Go)",
        "context_tokens": 1_050_000,
        "vision": False,
        "usage_pressure": 0.12,
        "scores": vec(
            8.0, 7.6, 7.0, 7.4, 7.5, 8.4, 7.8, 9.0, 7.6, 7.6,
            8.0, 8.2, 7.6, 7.1, 7.2, 7.4, 7.8, 7.4, 7.3, 8.1,
            9.3, 9.0,
        ),
        "score_confidence": 0.65,
        "thinking": {
            "control": "effort",
            "levels": ["low", "medium", "high", "xhigh", "max"],
            "default": "high",
            "native_prefix": "reasoningEffort (OpenAI-compatible on Go)",
            "verified": True,
            "notes": "OpenAI-compatible reasoningEffort applies; OpenAI recommends High for Luna.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime).",
        },
        "price_per_mtok": {"input": 0.10, "output": 0.50},
        "evidence": {
            "speed": "High-volume efficiency model.",
            "usage_efficiency": "Among the very cheapest per output token in Go.",
        },
        "sources": ["opencode_go_docs", "models_dev_go", "openai_models", "opencode_models_docs"],
    },
    "hy4-preview": {
        "surface": "opencode_go",
        "model_id": "hy4-preview",
        "display": "Hy4 preview (Go)",
        "context_tokens": 1_024_000,
        "vision": False,
        "usage_pressure": 0.56,
        "scores": vec(
            8.5, 8.2, 8.1, 8.2, 8.3, 8.3, 8.3, 9.3, 8.1, 8.1,
            8.3, 8.9, 8.5, 8.2, 8.2, 8.2, 8.4, 8.2, 8.1, 8.2,
            7.8, 6.5,
        ),
        "score_confidence": 0.60,
        "thinking": {
            "control": "opencode_variant",
            "levels": ["low", "high"],
            "default": "automatic",
            "native_prefix": "OpenCode Go variant / reasoning option",
            "verified": False,
            "notes": "Preview model; variants undocumented for Go.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime); preview stability not guaranteed.",
        },
        "price_per_mtok": {"input": 0.83, "output": 2.50},
        "evidence": {
            "frontend_ui": "Code Arena WebDev 1624 Elo as a preview model.",
            "agentic_tool_use": "Terminal-Bench 2.1 85.4.",
        },
        "sources": ["opencode_go_docs", "models_dev_go", "tb21", "webdev_arena"],
    },
    "longcat-2.0": {
        "surface": "opencode_go",
        "model_id": "longcat-2.0",
        "display": "LongCat-2.0 (Go)",
        "context_tokens": 1_000_000,
        "vision": False,
        "usage_pressure": 0.22,
        "scores": vec(
            8.0, 7.7, 7.5, 7.7, 7.9, 7.9, 7.9, 9.2, 7.6, 7.7,
            7.9, 7.8, 7.5, 7.4, 7.5, 7.5, 8.0, 7.4, 7.5, 7.8,
            8.6, 8.8,
        ),
        "score_confidence": 0.55,
        "thinking": {
            "control": "opencode_variant",
            "levels": ["low", "high"],
            "default": "automatic",
            "native_prefix": "OpenCode Go variant / reasoning option",
            "verified": False,
            "notes": "Variant names undocumented for Go.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime).",
        },
        "price_per_mtok": {"input": 0.30, "output": 1.20},
        "evidence": {
            "long_context": "1M context at low cost.",
            "usage_efficiency": "Cheap generalist.",
        },
        "sources": ["opencode_go_docs", "models_dev_go"],
    },
    "kimi-k2.6": {
        "surface": "opencode_go",
        "model_id": "kimi-k2.6",
        "display": "Kimi K2.6 (Go)",
        "context_tokens": 262_144,
        "vision": False,
        "usage_pressure": 0.38,
        "scores": vec(
            8.4, 8.2, 8.0, 8.2, 8.4, 8.3, 8.3, 8.4, 8.0, 8.1,
            8.2, 8.2, 8.0, 7.8, 7.8, 7.8, 8.2, 7.8, 8.0, 8.2,
            8.2, 6.5,
        ),
        "score_confidence": 0.60,
        "thinking": {
            "control": "opencode_variant",
            "levels": ["low", "high"],
            "default": "automatic",
            "native_prefix": "OpenCode Go variant / reasoning option",
            "verified": False,
            "notes": "Previous Kimi generation; variants undocumented for Go.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime).",
        },
        "price_per_mtok": {"input": 0.95, "output": 4.00},
        "evidence": {
            "agentic_tool_use": "Kimi agentic lineage one generation back.",
        },
        "sources": ["opencode_go_docs", "models_dev_go", "tb21"],
    },
    "minimax-m2.7": {
        "surface": "opencode_go",
        "model_id": "minimax-m2.7",
        "display": "MiniMax M2.7 (Go)",
        "context_tokens": 204_800,
        "vision": False,
        "usage_pressure": 0.20,
        "scores": vec(
            8.0, 7.8, 7.7, 7.8, 8.1, 8.0, 7.9, 8.2, 7.7, 7.8,
            7.9, 7.9, 7.7, 7.5, 7.5, 7.5, 7.9, 7.5, 7.7, 7.9,
            8.4, 7.5,
        ),
        "score_confidence": 0.55,
        "thinking": {
            "control": "opencode_variant",
            "levels": ["low", "high"],
            "default": "automatic",
            "native_prefix": "OpenCode Go variant / reasoning option",
            "verified": False,
            "notes": "Anthropic-compatible endpoint; budget-style thinking possible.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime).",
        },
        "price_per_mtok": {"input": 0.30, "output": 1.20},
        "evidence": {
            "usage_efficiency": "Cheap agentic generalist.",
        },
        "sources": ["opencode_go_docs", "models_dev_go"],
    },
    "mimo-v2.6-flash": {
        "surface": "opencode_go",
        "model_id": "mimo-v2.6-flash",
        "display": "MiMo-V2.6-Flash (Go)",
        "context_tokens": 1_048_576,
        "vision": False,
        "usage_pressure": 0.13,
        "scores": vec(
            8.2, 7.9, 7.6, 7.9, 8.1, 8.2, 8.0, 9.3, 7.8, 7.9,
            8.1, 8.0, 7.8, 7.6, 7.8, 7.6, 8.2, 7.6, 7.7, 8.1,
            8.9, 9.5,
        ),
        "score_confidence": 0.60,
        "thinking": {
            "control": "opencode_variant",
            "levels": ["low", "high"],
            "default": "automatic",
            "native_prefix": "OpenCode Go variant / reasoning option",
            "verified": False,
            "notes": "Variant names undocumented for Go.",
        },
        "availability": {
            "status": "live_check",
            "detail": "Present in the live OpenCode Go catalog (checked at runtime).",
        },
        "price_per_mtok": {"input": 0.14, "output": 0.28},
        "evidence": {
            "agentic_tool_use": "TB2.1 87.6 for the flash tier of the family.",
            "usage_efficiency": "One of the cheapest models in Go per token.",
        },
        "sources": ["opencode_go_docs", "models_dev_go", "tb21"],
    },
}

# Surfaces: how a route is executed. None of this automates ChatGPT or Claude;
# the report tells the operator where to paste/run each phase prompt.
SURFACES: dict[str, dict[str, Any]] = {
    "claude_team": {
        "label": "Claude Team / Claude Code",
        "execution": "Open a Claude Code session signed in with the Team account and paste the phase prompt.",
        "usage_model": "Shared 5-hour and weekly seat pool across Claude chat and Claude Code; "
                       "Opus-family usage is metered separately from Sonnet/Haiku.",
        "thinking_control": "/effort <level> (persists per model), --effort, CLAUDE_CODE_EFFORT_LEVEL.",
        "verification": "Run /model and /effort to confirm the selected model and effort before pasting.",
    },
    "chatgpt_plus": {
        "label": "ChatGPT Plus (Work / Codex)",
        "execution": "Use Codex CLI (`codex --model <id>`) or the ChatGPT desktop Work/Codex picker; "
                     "paste the phase prompt there. The plain Chat surface only gets GPT-5.6 Sol.",
        "usage_model": "Work/Codex usage is metered separately from Chat on Plus; GPT-6 Pro allowances "
                       "are Pro/Business/Enterprise only.",
        "thinking_control": "Reasoning-effort control under the composer, or /model in Codex CLI.",
        "verification": "Confirm the model and reasoning level in the picker; staged rollouts can "
                        "differ per account.",
    },
    "opencode_go": {
        "label": "OpenCode Go",
        "execution": "Run OpenCode connected with Go (`/connect`), select `opencode-go/<model-id>` "
                     "with `#variant` if published, and paste the phase prompt.",
        "usage_model": "$10/month with approx. $12 / 5h rolling, $30 / week, $60 / month of usage; "
                       "expensive models consume the allowance faster.",
        "thinking_control": "OpenCode model variants and provider options (reasoningEffort for "
                            "OpenAI-compatible models; thinking budgets for Anthropic-compatible ones).",
        "verification": "Variant names come from current catalog metadata; unknown variants error out. "
                        "Verify with the model picker or the live models endpoint.",
    },
}


# ---------------------------------------------------------------------------
# Cost model
#
# Every model carries an absolute API list price (`price_per_mtok`) gathered
# during the same research pass as the capability scores. The router then uses
# `cost_pressure`, a 0-1 effective-cost estimate:
#
#   weighted_price  = 0.30 * input + 0.70 * output     (output-heavy coding)
#   global_norm     = weighted_price / max over registry
#   surface_norm    = weighted_price / max within the model's own surface
#   cost_pressure   = 0.60 * global_norm + 0.40 * surface_norm
#
# The global term makes honestly expensive models (Astra at $10/$50) expensive
# everywhere. The surface term keeps the ranking meaningful inside each
# subscription: on Claude Team, Opus is the heaviest draw of the three; on
# OpenCode Go, Kimi K3 is. Team and Plus are flat subscriptions, so the price
# is not billed per token there - it is used as the relative allowance-burn
# proxy, while Go limits are dollar-denominated and match price directly.
# ---------------------------------------------------------------------------

def derive_cost_pressures() -> None:
    weighted: dict[str, float] = {}
    for key, model in MODEL_REGISTRY.items():
        price = model.get("price_per_mtok")
        if not price:
            raise AssertionError(f"registry model {key} has no price_per_mtok")
        weighted[key] = 0.30 * float(price["input"]) + 0.70 * float(price["output"])
    global_max = max(weighted.values())
    surface_max: dict[str, float] = {}
    for key, model in MODEL_REGISTRY.items():
        surface = model["surface"]
        surface_max[surface] = max(surface_max.get(surface, 0.0), weighted[key])
    for key, model in MODEL_REGISTRY.items():
        global_norm = weighted[key] / global_max if global_max else 0.0
        surface_norm = weighted[key] / surface_max[model["surface"]] if surface_max.get(model["surface"]) else 0.0
        model["price_weighted"] = round(weighted[key], 3)
        model["cost_pressure"] = round(0.60 * global_norm + 0.40 * surface_norm, 3)


derive_cost_pressures()

MAX_REGISTRY_PRICE_WEIGHTED = max(m["price_weighted"] for m in MODEL_REGISTRY.values())


# ---------------------------------------------------------------------------
# PHASES.md parsing
# ---------------------------------------------------------------------------

PHASE_HEADING_RE = re.compile(
    r"^(?P<hashes>#{2,4})[ \t]+(?P<pid>P\d{2})[ \t]*[\u2014\u2013\-:][ \t]*(?P<title>.+?)[ \t]*$"
)
FENCE_RE = re.compile(r"^[ \t]*```[ \t]*(?P<lang>[A-Za-z0-9_+\-]*)[ \t]*$")
STATUS_SUFFIX_RE = re.compile(r"\s*\((?:done|completed|in progress|wip)[^)]*\)\s*$", re.IGNORECASE)
TRAILING_MARKER = "<!-- route_phases.py:generated -->"


class PhaseParseError(RuntimeError):
    pass


def resolve_input_path(raw: str) -> Path:
    """Resolve phases.md even when the on-disk name differs in case (macOS)."""
    p = Path(raw).expanduser()
    if p.exists():
        return p
    if p.parent.exists():
        target = p.name.lower()
        for child in p.parent.iterdir():
            if child.name.lower() == target and child.is_file():
                return child
    raise PhaseParseError(f"phase file not found: {raw}")


def parse_phases(md_text: str, source_name: str = "PHASES.md") -> list[dict[str, Any]]:
    """Extract the real phase prompts from the phase-prompts section.

    Structure used by this repository:
      * section '## 7. Phase prompts' contains one '### Pxx - Title' heading per phase;
      * each heading is followed by exactly one fenced ```text block holding the
        actual agent prompt, ending with the shared 'Close the phase:' block;
      * later '## 8./## 9.' sections contain tables only and are not prompts.

    The parser scans for phase headings, bounds each heading's section at the
    next heading of equal-or-higher level, and takes the fenced text block(s)
    inside that section. Surrounding document commentary is not included.
    """
    lines = md_text.split("\n")
    headings: list[tuple[int, int, str, str]] = []  # (line_idx, level, pid, title)
    for idx, line in enumerate(lines):
        m = PHASE_HEADING_RE.match(line)
        if m:
            headings.append((idx, len(m.group("hashes")), m.group("pid"), m.group("title")))

    if not headings:
        raise PhaseParseError("no phase headings found; expected lines like '### P07 - Title'")

    phases: list[dict[str, Any]] = []
    for order, (h_idx, h_level, pid, raw_title) in enumerate(headings):
        section_end = len(lines)
        for n_idx, n_level, _, _ in headings[order + 1:]:
            if n_level <= h_level:
                section_end = n_idx
                break
        else:
            for scan in range(h_idx + 1, len(lines)):
                if re.match(r"^#{1,3}[ \t]", lines[scan]) and not PHASE_HEADING_RE.match(lines[scan]):
                    section_end = scan
                    break

        blocks: list[dict[str, Any]] = []
        i = h_idx + 1
        while i < section_end:
            fm = FENCE_RE.match(lines[i])
            if fm:
                lang = fm.group("lang").lower()
                j = i + 1
                while j < section_end and not FENCE_RE.match(lines[j]):
                    j += 1
                if j >= section_end:
                    raise PhaseParseError(f"unterminated code fence after line {i + 1} in {pid}")
                body = lines[i + 1:j]
                blocks.append({
                    "lang": lang,
                    "start": i + 1,          # 0-based index of first body line
                    "end": j,                # 0-based index of closing fence
                    "body": "\n".join(body),
                })
                i = j + 1
                continue
            i += 1

        text_blocks = [b for b in blocks if b["lang"] in ("text", "txt", "markdown", "md", "")]
        if not text_blocks:
            # A phase heading with no fenced prompt is not an actual prompt.
            continue
        chosen = text_blocks[0]
        prompt = chosen["body"]
        if not prompt.strip():
            continue

        clean_title = STATUS_SUFFIX_RE.sub("", raw_title).strip()
        status_note = raw_title[len(clean_title):].strip(" ()") if raw_title != clean_title else None
        phases.append({
            "phase_id": pid,
            "phase_index": int(pid[1:]),
            "phase_title": clean_title,
            "phase_title_raw": raw_title,
            "status_note": status_note,
            "heading_line": h_idx + 1,
            "source_start_line": chosen["start"] + 1,
            "source_end_line": chosen["end"],       # last prompt line (closing fence - 1 + 1)
            "fence_lang": chosen["lang"],
            "extra_text_blocks": max(0, len(text_blocks) - 1),
            "prompt": prompt,
            "prompt_sha256": hashlib.sha256(prompt.encode("utf-8")).hexdigest(),
            "source_file": source_name,
        })

    phases.sort(key=lambda p: p["phase_index"])
    phases = _validate_phases(phases)
    return phases


def _validate_phases(phases: list[dict[str, Any]]) -> list[dict[str, Any]]:
    seen: set[str] = set()
    for ph in phases:
        pid = ph["phase_id"]
        if pid in seen:
            raise PhaseParseError(f"duplicate phase id {pid}")
        seen.add(pid)
        if not ph["prompt"].strip():
            raise PhaseParseError(f"phase {pid} has an empty prompt")
    expected_ids = [f"P{i:02d}" for i in range(EXPECTED_FIRST_PHASE, EXPECTED_LAST_PHASE + 1)]
    got_ids = [p["phase_id"] for p in phases]
    if len(phases) != EXPECTED_PROMPT_COUNT:
        raise PhaseParseError(
            f"found {len(phases)} actual prompts, expected {EXPECTED_PROMPT_COUNT}. "
            f"PHASES.md in this repo contains P00..P40 (41 prompts, P00 is an audit "
            f"re-run). If the document genuinely changed, update EXPECTED_PROMPT_COUNT "
            f"and the report note. Found: {got_ids}"
        )
    if got_ids != expected_ids:
        raise PhaseParseError(f"phase ids are not a clean P00..P40 sequence: {got_ids}")
    return phases


# ---------------------------------------------------------------------------
# HTTP helpers (stdlib only), retries and OpenCode Go catalog refresh
# ---------------------------------------------------------------------------

USER_AGENT = f"route-phases/{SCRIPT_VERSION} (+local analysis)"


class HttpError(RuntimeError):
    def __init__(self, status: int, body: str):
        super().__init__(f"HTTP {status}: {body[:400]}")
        self.status = status
        self.body = body


def sanitize_text(text: str) -> str:
    """Defensively strip anything that looks like a bearer token before it is
    ever written to an output or cache file."""
    text = re.sub(r"(?i)(authorization\s*[:=]\s*)bearer\s+\S+", r"\1Bearer <redacted>", text)
    text = re.sub(r"\bsk-[A-Za-z0-9_\-]{8,}\b", "sk-<redacted>", text)
    return text


def http_post_json(
    url: str,
    payload: dict[str, Any],
    headers: dict[str, str],
    *,
    timeout: float = 60.0,
    retries: int = 3,
    backoff_base: float = 1.5,
    verbose: bool = False,
) -> dict[str, Any]:
    data = json.dumps(payload).encode("utf-8")
    last_err: Optional[Exception] = None
    for attempt in range(retries + 1):
        req = urllib.request.Request(url, data=data, method="POST")
        req.add_header("Content-Type", "application/json")
        req.add_header("User-Agent", USER_AGENT)
        for k, v in headers.items():
            req.add_header(k, v)
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                body = resp.read().decode("utf-8", errors="replace")
            return json.loads(body)
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace") if exc.fp else ""
            last_err = HttpError(exc.code, sanitize_text(body))
            if exc.code in (400, 401, 403, 422):
                raise last_err  # not retryable: bad request / auth / unknown model
            if verbose:
                print(f"  [http] {exc.code}, retrying ({attempt + 1}/{retries})", file=sys.stderr)
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError) as exc:
            last_err = exc
            if verbose:
                print(f"  [http] {exc}, retrying ({attempt + 1}/{retries})", file=sys.stderr)
        if attempt < retries:
            time.sleep(backoff_base ** attempt)
    raise RuntimeError(f"request failed after {retries} retries: {last_err}")


def http_get_json(url: str, *, timeout: float = 10.0) -> dict[str, Any]:
    req = urllib.request.Request(url, method="GET")
    req.add_header("User-Agent", USER_AGENT)
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8", errors="replace"))


def refresh_opencode_go_catalog(
    cache_dir: Path,
    *,
    force: bool = False,
    offline: bool = False,
    verbose: bool = False,
) -> dict[str, Any]:
    """Fetch the live OpenCode Go model ID list; fall back to the cached copy.

    The registry stays authoritative for capabilities, but availability is
    intersected with this live list so a delisted model is never recommended.
    """
    cache_file = cache_dir / "opencode_go_models.json"
    cached: Optional[dict[str, Any]] = None
    if cache_file.exists():
        try:
            cached = json.loads(cache_file.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            cached = None

    if offline and cached:
        cached["source"] = "cache_offline"
        return cached
    if cached and not force:
        try:
            fetched = datetime.fromisoformat(cached["fetched_at"])
            age_h = (datetime.now(timezone.utc) - fetched).total_seconds() / 3600.0
            if age_h < OPENCODE_GO_CATALOG_TTL_HOURS:
                cached["source"] = "cache_fresh"
                return cached
        except (KeyError, ValueError):
            pass

    try:
        live = http_get_json(OPENCODE_GO_MODELS_URL, timeout=8.0)
        ids = sorted({m.get("id", "") for m in live.get("data", []) if m.get("id")})
        result = {
            "source": "live",
            "source_url": OPENCODE_GO_MODELS_URL,
            "fetched_at": datetime.now(timezone.utc).isoformat(),
            "model_ids": ids,
            "count": len(ids),
        }
        cache_dir.mkdir(parents=True, exist_ok=True)
        cache_file.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
        if verbose:
            print(f"  [catalog] refreshed OpenCode Go: {len(ids)} models", file=sys.stderr)
        return result
    except Exception as exc:  # noqa: BLE001 - availability must never be fatal
        fallback = cached or {"model_ids": [], "fetched_at": None}
        fallback["source"] = "embedded_or_stale_cache"
        fallback["error"] = sanitize_text(str(exc))
        fallback["source_url"] = OPENCODE_GO_MODELS_URL
        if verbose:
            print(f"  [catalog] refresh failed ({exc}); using fallback", file=sys.stderr)
        return fallback


# ---------------------------------------------------------------------------
# Jev task profiler (TypeSafe System One API)
# ---------------------------------------------------------------------------

DOMINANT_TASKS = {
    "implementation_feature": "Write new, well-scoped functionality (feature, widget, screen, integration).",
    "bugfix_debugging": "Find and fix a defect, regression or hard runtime failure.",
    "refactor_migration": "Restructure, rename, prune or migrate existing code without changing behaviour.",
    "architecture_design": "Design system structure, interfaces, data models or a multi-component plan.",
    "ui_visual_design": "Design or improve visual/interaction quality of a Flutter UI.",
    "graphics_3d_engineering": "Real-time 3D, shaders, rendering, geometry or graphics performance work.",
    "ml_cv_engineering": "Machine learning or computer vision: model choice, training, ONNX, evaluation.",
    "data_pipeline_tooling": "Python/data tooling: scripts, validators, ETL, asset generation, mesh building.",
    "content_research": "Factual research and writing of sourced cultural/historical content.",
    "performance_optimization": "Measure and improve performance, memory, size or frame rate.",
    "testing_ci": "Build tests, test automation, CI or device-matrix verification.",
    "release_ops": "Release engineering, signing, Play submission, store assets or rollout.",
    "localization_content_ops": "Bilingual/i18n consistency, ARB coverage, terminology and copy rules.",
    "platform_integration": "Android platform work: permissions, lifecycle, MediaStore, Kotlin channels.",
    "accessibility": "Accessibility, TalkBack, reduced motion, contrast and focus order.",
    "audio_dsp": "Audio recording, DSP, convolution, soundscapes or narration.",
    "map_geodata": "Map rendering and geospatial data: GeoJSON, OSM, projections, routes.",
    "security_privacy": "Security, privacy, permissions hygiene, malicious-input validation.",
}

LEVEL_DESCRIPTIONS_5 = [
    "None - this does not matter for the phase.",
    "Slight - a minor factor at most.",
    "Moderate - a real requirement but not dominant.",
    "High - clearly needed for reliable completion.",
    "Critical - the phase fails without it.",
]

# Jev question schema (one request per phase, all questions evaluated in parallel).
JEV_QUESTIONS: dict[str, dict[str, Any]] = {
    "dominant_task": {
        "type": "choice",
        "instructions": "What is the single dominant kind of engineering or production work in this phase prompt?",
        "criteria": DOMINANT_TASKS,
    },
    "is_audit_or_verification": {
        "type": "noul",
        "instructions": "Is the phase primarily a verification/audit of already-working functionality rather than new construction?",
    },
    "implementation_complexity": {
        "type": "score",
        "instructions": "How complex is the implementation work described (size, moving parts, new code volume)?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
    "reasoning_depth": {
        "type": "score",
        "instructions": "How much deep reasoning (planning, trade-offs, correctness analysis) does reliable completion require?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
    "architecture_need": {
        "type": "score",
        "instructions": "Does reliable completion require substantial architectural or system-level design (interfaces, data models, cross-phase structure)?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
    "repo_context_need": {
        "type": "score",
        "instructions": "Does this task require understanding several interacting parts of the existing repository before editing?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
    "debugging_need": {
        "type": "score",
        "instructions": "Is diagnosing failures (rendering, performance, async, platform quirks) a significant part of the work?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
    "ambiguity": {
        "type": "score",
        "instructions": "How much is left under-specified or open to interpretation, so the model must make judgment calls?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
    "execution_risk": {
        "type": "score",
        "instructions": "How damaging would a wrong implementation approach be (data loss, broken core flows, wasted later phases, platform rejection)?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
    "instruction_precision": {
        "type": "score",
        "instructions": "How exact and checklist-like are the instructions (explicit acceptance criteria, numbered steps, named files)?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
    "tool_use_need": {
        "type": "score",
        "instructions": "How much sustained agentic tool use is needed (many edits, commands, builds, tests in sequence)?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
    "research_need": {
        "type": "score",
        "instructions": "How much external factual research and source verification is required (history, benchmarks, library docs)?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
    "frontend_ui_need": {
        "type": "score",
        "instructions": "How much Flutter UI/layout/interaction implementation quality matters for acceptance?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
    "visual_reasoning_need": {
        "type": "score",
        "instructions": "Does the phase require visual/aesthetic judgment or interpreting images/renders?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
    "graphics_3d_need": {
        "type": "score",
        "instructions": "Does the phase require real-time 3D, shader, geometry or rendering-math work?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
    "ml_cv_need": {
        "type": "score",
        "instructions": "Does the phase require machine learning or computer vision engineering (model choice, training, ONNX, embeddings, evaluation)?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
    "audio_dsp_need": {
        "type": "score",
        "instructions": "Does the phase require audio recording, DSP, acoustics, soundscapes, TTS or narration work?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
    "multimodal_need": {
        "type": "score",
        "instructions": "Does the phase need image input understanding (screenshots, mosaics, tiles, photos)?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
    "test_verification_need": {
        "type": "score",
        "instructions": "How much test design, edge-case analysis or verification harness work is required?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
    "cross_component_need": {
        "type": "score",
        "instructions": "How many separate subsystems, layers or phases must be coordinated for this to work?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
    "long_context_need": {
        "type": "score",
        "instructions": "How much does the work depend on large inputs (full corpus, long spec, many files at once)?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
    "factual_accuracy_need": {
        "type": "score",
        "instructions": "How critical is factual/cultural accuracy with citations (history dates, QIDs, honest labels, no invented heritage)?",
        "criteria": LEVEL_DESCRIPTIONS_5,
    },
}

PROJECT_CONTEXT = (
    "Milion is an Android-only Flutter app (package milion, application id app.milion) that turns "
    "Istanbul heritage into a collectible, instrument-like experience: a 2.5D plate engine with "
    "shaders and gyroscope parallax, a 3D 'space' runtime in a drawing style, an offline Atlas with "
    "time layers, Python asset pipelines (segmentation, depth, meshes), an on-device ONNX recognition "
    "feature, bilingual EN/TR content with strict sourcing and honesty labels, audio acoustics, "
    "accessibility, and a Google Play release. Reference device: Samsung Galaxy A52s 5G, Android 14. "
    "A phase prompt is a work order for one development phase; classify the work it asks for."
)


def build_jev_state(phase: dict[str, Any]) -> dict[str, Any]:
    return {
        "phase_id": phase["phase_id"],
        "phase_title": phase["phase_title"],
        "project_context": PROJECT_CONTEXT,
        "phase_prompt": phase["prompt"],
    }


def _answer_confidence(val: dict[str, Any]) -> float:
    if val.get("type") == "noul":
        return float(val.get("noul", 0.5))
    try:
        return float(val.get("confidence", 0.5))
    except (TypeError, ValueError):
        return 0.5


def validate_jev_response(payload: dict[str, Any]) -> list[str]:
    """Return a list of shape errors; empty means the response is usable."""
    errors: list[str] = []
    if not isinstance(payload, dict):
        return ["response is not a JSON object"]
    answers = payload.get("answers")
    if not isinstance(answers, dict):
        return ["missing 'answers' object"]
    for qid, spec in JEV_QUESTIONS.items():
        val = answers.get(qid)
        if not isinstance(val, dict):
            errors.append(f"missing answer for {qid}")
            continue
        if val.get("type") != spec["type"]:
            errors.append(f"{qid}: type {val.get('type')!r} != {spec['type']!r}")
            continue
        if spec["type"] == "choice":
            choice = val.get("choice")
            if choice not in spec["criteria"]:
                errors.append(f"{qid}: choice {choice!r} not in criteria")
            probs = val.get("probabilities")
            if not isinstance(probs, dict):
                errors.append(f"{qid}: missing probabilities")
        elif spec["type"] == "score":
            try:
                score = float(val.get("score"))
            except (TypeError, ValueError):
                errors.append(f"{qid}: score not numeric")
                continue
            if not (0.0 <= score <= 5.0):
                errors.append(f"{qid}: score {score} out of range")
        elif spec["type"] == "noul":
            try:
                p = float(val.get("noul"))
            except (TypeError, ValueError):
                errors.append(f"{qid}: noul not numeric")
                continue
            if not (0.0 <= p <= 1.0):
                errors.append(f"{qid}: noul {p} out of range")
    return errors


class JevClient:
    def __init__(self, api_key: str, *, verbose: bool = False):
        self.api_key = api_key
        self.verbose = verbose
        self.resolved_model: Optional[str] = None

    def _post(self, payload: dict[str, Any]) -> dict[str, Any]:
        return http_post_json(
            JEV_ENDPOINT,
            payload,
            {"Authorization": f"Bearer {self.api_key}"},
            timeout=60.0,
            retries=3,
            verbose=self.verbose,
        )

    def system_one(self, state: dict[str, Any], questions: dict[str, Any]) -> tuple[dict[str, Any], str]:
        payload = {"model": JEV_MODEL_PRIMARY, "state": state, "questions": questions}
        try:
            response = self._post(payload)
        except HttpError as exc:
            if exc.status == 422 and "model" in exc.body.lower():
                payload["model"] = JEV_MODEL_FALLBACK
                response = self._post(payload)
            else:
                raise
        self.resolved_model = response.get("model", payload["model"])
        return response, payload["model"]

    def check(self) -> dict[str, Any]:
        state = {
            "note": "route_phases.py minimal API sanity check; no project data.",
            "sample": "A phase requires rewriting an authentication flow and adding tests.",
        }
        questions = {
            "implementation_heavy": {
                "type": "noul",
                "instructions": "Does the sample describe implementation work?",
            }
        }
        response, requested = self.system_one(state, questions)
        return {
            "requested_model": requested,
            "resolved_model": response.get("model"),
            "answer": response.get("answers", {}).get("implementation_heavy"),
            "usage": response.get("usage"),
        }


# ---------------------------------------------------------------------------
# Task profile -> capability requirements
# ---------------------------------------------------------------------------

TASK_DIM_BASE: dict[str, dict[str, float]] = {
    "implementation_feature": {"direct_implementation": 1.0, "instruction_following": 0.5,
                               "repo_wide_reasoning": 0.4, "test_reasoning": 0.3},
    "bugfix_debugging": {"deep_debugging": 1.0, "repo_wide_reasoning": 0.6,
                         "test_reasoning": 0.4, "direct_implementation": 0.4},
    "refactor_migration": {"refactoring": 1.0, "repo_wide_reasoning": 0.8,
                           "architecture": 0.5, "test_reasoning": 0.4, "precision": 0.4},
    "architecture_design": {"architecture": 1.0, "repo_wide_reasoning": 0.7,
                            "long_spec_adherence": 0.5, "precision": 0.4},
    "ui_visual_design": {"frontend_ui": 1.0, "visual_reasoning": 0.9, "precision": 0.4},
    "graphics_3d_engineering": {"graphics_3d": 1.0, "deep_debugging": 0.6,
                                "visual_reasoning": 0.5, "direct_implementation": 0.5},
    "ml_cv_engineering": {"ml_cv": 1.0, "data_pipeline": 0.6, "test_reasoning": 0.4,
                          "research": 0.4},
    "data_pipeline_tooling": {"data_pipeline": 1.0, "direct_implementation": 0.5,
                              "test_reasoning": 0.4},
    "content_research": {"research": 1.0, "precision": 0.6, "long_context": 0.4},
    "performance_optimization": {"deep_debugging": 0.9, "graphics_3d": 0.5,
                                 "direct_implementation": 0.4, "test_reasoning": 0.4},
    "testing_ci": {"test_reasoning": 1.0, "instruction_following": 0.5,
                   "direct_implementation": 0.5},
    "release_ops": {"instruction_following": 0.9, "precision": 0.6, "direct_implementation": 0.4},
    "localization_content_ops": {"precision": 1.0, "instruction_following": 0.6,
                                 "long_spec_adherence": 0.5},
    "platform_integration": {"direct_implementation": 0.8, "repo_wide_reasoning": 0.6,
                             "instruction_following": 0.5, "deep_debugging": 0.4},
    "accessibility": {"frontend_ui": 0.7, "instruction_following": 0.7,
                      "precision": 0.5, "test_reasoning": 0.4},
    "audio_dsp": {"audio_dsp": 1.0, "direct_implementation": 0.6, "deep_debugging": 0.3},
    "map_geodata": {"data_pipeline": 0.8, "frontend_ui": 0.6, "graphics_3d": 0.4,
                    "direct_implementation": 0.4},
    "security_privacy": {"precision": 0.9, "deep_debugging": 0.5, "test_reasoning": 0.5},
}

QUESTION_DIM_WEIGHTS: dict[str, dict[str, float]] = {
    "implementation_complexity": {"direct_implementation": 0.35, "agentic_tool_use": 0.15},
    "reasoning_depth": {"architecture": 0.20, "deep_debugging": 0.15, "long_spec_adherence": 0.10},
    "architecture_need": {"architecture": 0.50, "repo_wide_reasoning": 0.20},
    "repo_context_need": {"repo_wide_reasoning": 0.50, "long_context": 0.10},
    "debugging_need": {"deep_debugging": 0.50, "test_reasoning": 0.15},
    "ambiguity": {"ambiguity_handling": 0.50},
    "execution_risk": {"precision": 0.25, "architecture": 0.15, "test_reasoning": 0.15,
                       "deep_debugging": 0.10},
    "instruction_precision": {"instruction_following": 0.40, "long_spec_adherence": 0.30},
    "tool_use_need": {"agentic_tool_use": 0.50},
    "research_need": {"research": 0.50, "long_context": 0.15},
    "frontend_ui_need": {"frontend_ui": 0.50, "visual_reasoning": 0.20},
    "visual_reasoning_need": {"visual_reasoning": 0.50, "frontend_ui": 0.15},
    "graphics_3d_need": {"graphics_3d": 0.60, "visual_reasoning": 0.15, "deep_debugging": 0.10},
    "ml_cv_need": {"ml_cv": 0.55, "data_pipeline": 0.15},
    "audio_dsp_need": {"audio_dsp": 0.55, "direct_implementation": 0.10},
    "multimodal_need": {"visual_reasoning": 0.40, "long_context": 0.10},
    "test_verification_need": {"test_reasoning": 0.50, "precision": 0.10},
    "cross_component_need": {"repo_wide_reasoning": 0.30, "architecture": 0.30,
                             "long_spec_adherence": 0.15},
    "long_context_need": {"long_context": 0.50},
    "factual_accuracy_need": {"research": 0.30, "precision": 0.40},
}

REASONING_DIMS = {"architecture", "deep_debugging", "repo_wide_reasoning",
                  "long_spec_adherence", "ambiguity_handling", "precision"}
NON_REQUIREMENT_DIMS = {"speed", "usage_efficiency"}

_THINKING_BIAS: dict[str, float] = {
    "claude-opus-5-5": -0.15,
    "claude-haiku-4-5": -0.20,
    "gpt-6-astra": -0.15,
    "gpt-6-luna": +0.25,
    "gpt-6-luna-go": +0.25,
    "gpt-5-6-sol": 0.0,
    "deepseek-v4.1-flash": +0.15,
    "glm-5.3-flash": +0.20,
    "qwen3.8-flash": +0.20,
    "mimo-v2.6-flash": +0.20,
    "longcat-2.0": +0.25,
    "minimax-m2.7": +0.15,
    "kimi-k2.6": +0.10,
    "minimax-m3": +0.05,
}


def _score_answer(answers: dict[str, Any], qid: str) -> tuple[float, float]:
    val = answers.get(qid) or {}
    try:
        raw = float(val.get("score", 0.0))
    except (TypeError, ValueError):
        raw = 0.0
    return max(0.0, min(4.0, raw)), _answer_confidence(val)


def _noul_answer(answers: dict[str, Any], qid: str) -> float:
    val = answers.get(qid) or {}
    try:
        return max(0.0, min(1.0, float(val.get("noul", 0.5))))
    except (TypeError, ValueError):
        return 0.5


def profile_to_requirements(answers: dict[str, Any]) -> dict[str, Any]:
    """Deterministically turn a Jev task profile into weighted capability needs."""
    choice = (answers.get("dominant_task") or {}).get("choice", "implementation_feature")
    if choice not in DOMINANT_TASKS:
        choice = "implementation_feature"
    dominant_conf = _answer_confidence(answers.get("dominant_task") or {})

    raw: dict[str, float] = {d: 0.0 for d in DIMS}
    for dim, val in TASK_DIM_BASE.get(choice, {}).items():
        raw[dim] += val

    for qid, per_dim in QUESTION_DIM_WEIGHTS.items():
        value, conf = _score_answer(answers, qid)
        strength = (value / 4.0) * (0.55 + 0.45 * conf)
        for dim, w in per_dim.items():
            raw[dim] += w * strength

    complexity, _ = _score_answer(answers, "implementation_complexity")
    reasoning, _ = _score_answer(answers, "reasoning_depth")
    architecture, _ = _score_answer(answers, "architecture_need")
    repo_ctx, _ = _score_answer(answers, "repo_context_need")
    debugging, _ = _score_answer(answers, "debugging_need")
    ambiguity, _ = _score_answer(answers, "ambiguity")
    risk, _ = _score_answer(answers, "execution_risk")
    precision_instr, _ = _score_answer(answers, "instruction_precision")
    tool_use, _ = _score_answer(answers, "tool_use_need")
    research, _ = _score_answer(answers, "research_need")
    frontend, _ = _score_answer(answers, "frontend_ui_need")
    visual, _ = _score_answer(answers, "visual_reasoning_need")
    graphics, _ = _score_answer(answers, "graphics_3d_need")
    ml_cv, _ = _score_answer(answers, "ml_cv_need")
    audio, _ = _score_answer(answers, "audio_dsp_need")
    multimodal, _ = _score_answer(answers, "multimodal_need")
    tests, _ = _score_answer(answers, "test_verification_need")
    cross, _ = _score_answer(answers, "cross_component_need")
    long_ctx, _ = _score_answer(answers, "long_context_need")
    factual, _ = _score_answer(answers, "factual_accuracy_need")
    audit = _noul_answer(answers, "is_audit_or_verification")

    confidences = [
        _answer_confidence(a)
        for a in answers.values()
        if isinstance(a, dict) and a.get("type") != "noul"
    ]
    profile_conf = sum(confidences) / len(confidences) if confidences else 0.5
    uncertainty = max(0.0, min(1.0, 1.0 - profile_conf))

    risk_f = risk / 4.0
    ambiguity_f = ambiguity / 4.0
    reasoning_multiplier = 1.0 + 0.30 * risk_f + 0.20 * uncertainty + 0.25 * ambiguity_f * risk_f
    for dim in REASONING_DIMS:
        raw[dim] *= reasoning_multiplier

    # Long-context inputs raise the long_context requirement modestly on their own.
    raw["long_context"] += 0.25 * (long_ctx / 4.0)

    max_raw = max(raw.values()) or 1.0
    weights = {d: raw[d] / max_raw for d in DIMS}
    weights = {d: (0.0 if d in NON_REQUIREMENT_DIMS else round(w, 4)) for d, w in weights.items()}

    crit_cut = 0.55 * max(weights.values())
    critical: dict[str, float] = {}
    for dim, w in weights.items():
        if dim in NON_REQUIREMENT_DIMS or w <= 0:
            continue
        if w >= crit_cut:
            critical[dim] = round(5.2 + 1.8 * w, 2)

    ctx_need_tokens = _context_need_tokens(long_ctx)

    return {
        "dominant_task": choice,
        "dominant_task_confidence": round(dominant_conf, 3),
        "weights": weights,
        "critical_dims": critical,
        "profile_confidence": round(profile_conf, 3),
        "uncertainty": round(uncertainty, 3),
        "risk": risk_f,
        "ambiguity": ambiguity_f,
        "complexity": complexity / 4.0,
        "reasoning_depth": reasoning / 4.0,
        "architecture_need": architecture / 4.0,
        "repo_context_need": repo_ctx / 4.0,
        "debugging_need": debugging / 4.0,
        "instruction_precision": precision_instr / 4.0,
        "tool_use_need": tool_use / 4.0,
        "research_need": research / 4.0,
        "frontend_ui_need": frontend / 4.0,
        "visual_reasoning_need": visual / 4.0,
        "graphics_3d_need": graphics / 4.0,
        "multimodal_need": multimodal / 4.0,
        "test_verification_need": tests / 4.0,
        "cross_component_need": cross / 4.0,
        "long_context_need": long_ctx / 4.0,
        "factual_accuracy_need": factual / 4.0,
        "is_audit_or_verification": round(audit, 3),
        "required_context_tokens": ctx_need_tokens,
        "raw_scores": {
            "implementation_complexity": complexity,
            "reasoning_depth": reasoning,
            "architecture_need": architecture,
            "repo_context_need": repo_ctx,
            "debugging_need": debugging,
            "ambiguity": ambiguity,
            "execution_risk": risk,
            "instruction_precision": precision_instr,
            "tool_use_need": tool_use,
            "research_need": research,
            "frontend_ui_need": frontend,
            "visual_reasoning_need": visual,
        "graphics_3d_need": graphics,
        "ml_cv_need": ml_cv,
        "audio_dsp_need": audio,
        "multimodal_need": multimodal,
            "test_verification_need": tests,
            "cross_component_need": cross,
            "long_context_need": long_ctx,
            "factual_accuracy_need": factual,
        },
    }


def _context_need_tokens(long_ctx_score: float) -> int:
    if long_ctx_score <= 1.0:
        return 128_000
    if long_ctx_score <= 2.0:
        return 200_000
    if long_ctx_score <= 3.0:
        return 400_000
    return 900_000


# ---------------------------------------------------------------------------
# Deterministic routing engine
# ---------------------------------------------------------------------------

def efficiency_weight_for(requirements: dict[str, Any]) -> float:
    """Multiplier that shows how much quota cost is allowed to discount quality.

    Low-risk, well-scoped phases get a large discount so a cheap-but-competent
    model can win. High-risk phases get a small discount so correctness
    dominates. Uncertainty on risky work pushes back toward capability.
    """
    risk = requirements["risk"]
    complexity = requirements["complexity"]
    if risk >= 0.75:
        alpha = 0.10
    elif risk >= 0.5:
        alpha = 0.18
    elif complexity <= 0.4 and risk <= 0.4:
        alpha = 0.40
    else:
        alpha = 0.28
    if requirements["is_audit_or_verification"] >= 0.5:
        alpha = max(alpha, 0.40)
    alpha *= 1.0 - 0.35 * requirements["uncertainty"] * risk
    return round(alpha, 4)


def score_candidate(
    key: str,
    model: dict[str, Any],
    requirements: dict[str, Any],
    *,
    available: bool,
) -> dict[str, Any]:
    weights = requirements["weights"]
    total_w = sum(weights.values()) or 1.0
    weighted_fit = sum(weights[d] * model["scores"][d] for d in DIMS) / total_w
    critical_vals = [model["scores"][d] for d in requirements["critical_dims"]]
    bottleneck = min(critical_vals) if critical_vals else weighted_fit
    fit = 0.75 * weighted_fit + 0.25 * bottleneck

    reasons_blocked: list[str] = []
    if not available:
        reasons_blocked.append("not present in the live catalog for its surface")

    for dim, floor in requirements["critical_dims"].items():
        if model["scores"][dim] < floor:
            reasons_blocked.append(
                f"{dim}={model['scores'][dim]:.1f} below floor {floor:.1f}"
            )

    if requirements["required_context_tokens"] >= 900_000 and model["context_tokens"] < 300_000:
        reasons_blocked.append(
            f"context {model['context_tokens']:,} too small for a corpus-scale phase"
        )

    if requirements["multimodal_need"] >= 0.75 and not model["vision"]:
        reasons_blocked.append("no image input for a vision-heavy phase")

    eff_alpha = efficiency_weight_for(requirements)
    cost_penalty = fit * eff_alpha * model["cost_pressure"]
    ctx_penalty = 0.0
    if model["context_tokens"] < requirements["required_context_tokens"]:
        gap = (requirements["required_context_tokens"] - model["context_tokens"]) / requirements["required_context_tokens"]
        ctx_penalty = 0.45 * gap * requirements["long_context_need"]
    total = fit - cost_penalty - ctx_penalty

    return {
        "registry_key": key,
        "surface": model["surface"],
        "model_id": model["model_id"],
        "display": model["display"],
        "eligible": not reasons_blocked,
        "blocked_by": reasons_blocked,
        "capability_fit": round(fit, 3),
        "weighted_fit": round(weighted_fit, 3),
        "critical_bottleneck": round(bottleneck, 3),
        "cost_penalty": round(cost_penalty, 3),
        "context_penalty": round(ctx_penalty, 3),
        "total": round(total, 3),
        "cost_pressure": model["cost_pressure"],
        "surface_burn": model["usage_pressure"],
        "price_per_mtok": model["price_per_mtok"],
        "context_tokens": model["context_tokens"],
    }


def select_primary_candidate(
    eligible: list[dict[str, Any]],
    requirements: dict[str, Any],
    cost_aversion: str,
) -> tuple[dict[str, Any], dict[str, Any], float, list[dict[str, Any]]]:
    """Least-cost selection subject to a capability bar.

    The bar is anchored to the best available capability fit but relaxes as
    execution risk falls: an easy phase does not pay for frontier headroom,
    while a risky phase keeps only models near the best. Among models clearing
    the bar, the cheapest effective-cost model wins.
    """
    best_fit_candidate = max(eligible, key=lambda c: c["capability_fit"])
    best_fit = best_fit_candidate["capability_fit"]
    mult = {"low": 0.6, "medium": 1.0, "high": 1.5}.get(cost_aversion, 1.0)
    risk = requirements["risk"]
    complexity = requirements["complexity"]
    uncertainty = requirements["uncertainty"]
    tolerance = max(0.08, (0.25 + 1.10 * (1.0 - risk) - 0.15 * uncertainty) * mult)
    min_fit = min(9.0, 6.4 + 2.4 * risk + 0.9 * complexity)
    threshold = max(min_fit, best_fit - tolerance)
    within = [c for c in eligible if c["capability_fit"] >= threshold]
    if not within:
        within = [best_fit_candidate]
        threshold = best_fit
    primary = min(
        within,
        key=lambda c: (c["cost_pressure"], -c["capability_fit"], -c["total"]),
    )
    return primary, best_fit_candidate, threshold, within


def route_phase(
    requirements: dict[str, Any],
    catalog: dict[str, Any],
    *,
    top_n: int = 6,
    cost_aversion: str = "medium",
) -> dict[str, Any]:
    live_ids = set(catalog.get("model_ids") or [])
    go_checked_live = bool(live_ids)
    candidates: list[dict[str, Any]] = []
    for key, model in MODEL_REGISTRY.items():
        if model["surface"] == "opencode_go":
            available = (model["model_id"] in live_ids) if go_checked_live else True
        else:
            available = True
        candidates.append(score_candidate(key, model, requirements, available=available))

    candidates.sort(key=lambda c: (c["eligible"], c["total"]), reverse=True)
    eligible = [c for c in candidates if c["eligible"]]
    if not eligible:
        # Should not happen: relax and report honestly instead of inventing a model.
        eligible = sorted(candidates, key=lambda c: c["total"], reverse=True)
        for c in eligible:
            c["eligibility_relaxed"] = True

    primary, best_fit_candidate, threshold, within = select_primary_candidate(
        eligible, requirements, cost_aversion
    )

    availability_fallback = None
    unfiltered_best = max(candidates, key=lambda c: c["capability_fit"])
    if (
        unfiltered_best["registry_key"] != primary["registry_key"]
        and not unfiltered_best["eligible"]
        and any("not present in the live catalog" in reason
                for reason in unfiltered_best["blocked_by"])
    ):
        availability_fallback = {
            "would_have_been": unfiltered_best["model_id"],
            "surface": unfiltered_best["surface"],
            "reason": "registry entry is not present in the live OpenCode Go catalog",
        }

    others = [c for c in eligible if c["registry_key"] != primary["registry_key"]]
    alternative = None
    for cand in others:
        if cand["surface"] != primary["surface"]:
            alternative = cand
            break
    if alternative is None and others:
        alternative = others[0]

    fit_margin = max(0.0, primary["capability_fit"] - threshold)
    margin_conf = 1.0 - pow(2.718281828, -(fit_margin + 0.15) / 0.35)
    best_conf_model = MODEL_REGISTRY[primary["registry_key"]]["score_confidence"]
    availability_conf = 0.95 if primary["surface"] != "opencode_go" else (0.9 if go_checked_live else 0.7)
    conf = (
        0.42 * requirements["profile_confidence"]
        + 0.30 * margin_conf
        + 0.13 * best_conf_model
        + 0.15 * availability_conf
    )
    conf -= 0.15 * requirements["uncertainty"] * requirements["risk"]
    conf = max(0.30, min(0.97, conf))

    selection_basis = {
        "cost_model": COST_MODEL_VERSION,
        "cost_aversion": cost_aversion,
        "capability_threshold": round(threshold, 3),
        "best_fit_model": best_fit_candidate["model_id"],
        "best_fit": round(best_fit_candidate["capability_fit"], 3),
        "best_fit_cost_pressure": best_fit_candidate["cost_pressure"],
        "candidates_within_threshold": len(within),
        "fit_margin_over_threshold": round(fit_margin, 3),
        "selected_cost_pressure": primary["cost_pressure"],
    }

    thinking = choose_thinking_level(requirements, MODEL_REGISTRY[primary["registry_key"]])
    alt_thinking = None
    if alternative is not None:
        alt_think = choose_thinking_level(requirements, MODEL_REGISTRY[alternative["registry_key"]])
        alt_thinking = native_thinking_for(
            MODEL_REGISTRY[alternative["registry_key"]], alt_think["level"], requirements
        )
        alt_thinking["level"] = alt_think["level"]
    return {
        "primary": primary,
        "alternative": alternative,
        "candidates": candidates[:top_n],
        "all_candidates": candidates,
        "confidence": round(conf, 3),
        "margin": round(fit_margin, 3),
        "selection_basis": selection_basis,
        "thinking": thinking,
        "alternative_thinking": alt_thinking,
        "fallback_used": bool(primary.get("eligibility_relaxed")),
        "availability_fallback": availability_fallback,
    }


# ---------------------------------------------------------------------------
# Thinking / reasoning-budget policy
# ---------------------------------------------------------------------------

THINKING_LEVELS = ["low", "medium", "high", "very_high"]
_LEVEL_RANK = {"low": 0, "medium": 1, "high": 2, "xhigh": 3, "max": 4, "ultra": 5,
               "instant": -1}


def choose_thinking_level(requirements: dict[str, Any], model: dict[str, Any]) -> dict[str, Any]:
    """Pick a normalized reasoning budget from task needs, then explain it.

    Task side: complexity, ambiguity, architecture, debugging, execution risk,
    cross-component coupling, repo context and long-spec adherence.
    Model side: a small bias plus ceilings, because models spend reasoning
    differently (Opus 5.5 already thinks more per turn; flash models need an
    explicit step up to be safe).
    """
    r = requirements
    weighted = (
        0.30 * r["complexity"]
        + 0.18 * r["ambiguity"]
        + 0.18 * r["architecture_need"]
        + 0.16 * r["debugging_need"]
        + 0.22 * r["risk"]
        + 0.12 * r["cross_component_need"]
        + 0.10 * r["repo_context_need"]
        + 0.08 * (r["raw_scores"]["long_context_need"] / 4.0)
    ) / 1.34
    idx = weighted + _THINKING_BIAS.get(_registry_key_for(model), 0.0)
    idx = max(0.0, min(1.0, idx))

    drivers: list[str] = []
    for label, value in (
        ("execution risk", r["risk"]),
        ("implementation complexity", r["complexity"]),
        ("architecture need", r["architecture_need"]),
        ("debugging need", r["debugging_need"]),
        ("ambiguity", r["ambiguity"]),
        ("cross-component coupling", r["cross_component_need"]),
        ("repo context", r["repo_context_need"]),
    ):
        if value >= 0.6:
            drivers.append(f"{label} {value:.2f}")

    if r["is_audit_or_verification"] >= 0.5:
        idx = min(idx, 0.45)
        drivers.append("audit-style phase caps reasoning")
    if r["risk"] >= 0.75:
        idx = max(idx, 0.60)
    if r["risk"] >= 0.80 and r["complexity"] >= 0.70:
        idx = max(idx, 0.80)
    if r["risk"] >= 0.95 and r["complexity"] >= 0.90 and r["architecture_need"] >= 0.80:
        idx = max(idx, 0.90)

    if idx < 0.28:
        level = "low"
    elif idx < 0.52:
        level = "medium"
    elif idx < 0.74:
        level = "high"
    else:
        level = "very_high"

    ceiling = model["thinking"].get("ceiling")
    if ceiling and THINKING_LEVELS.index(level) > THINKING_LEVELS.index(ceiling):
        level = ceiling
        drivers.append(f"capped at {ceiling} for this model")

    return {
        "level": level,
        "score": round(idx, 3),
        "drivers": drivers[:5],
        "model_bias": _THINKING_BIAS.get(_registry_key_for(model), 0.0),
    }


def _registry_key_for(model: dict[str, Any]) -> str:
    for key, reg in MODEL_REGISTRY.items():
        if reg is model:
            return key
        if reg["surface"] == model["surface"] and reg["model_id"] == model["model_id"]:
            return key
    return model.get("model_id", "")


_LEVEL_LABEL = {
    "low": "Low",
    "medium": "Medium",
    "high": "High",
    "xhigh": "Extra High",
    "max": "Max",
    "ultra": "Ultra",
    "instant": "Instant",
}


def _nearest_level(target: str, allowed: list[str]) -> Optional[str]:
    if target in allowed:
        return target
    if not allowed:
        return None
    rank = _LEVEL_RANK.get(target, 2)
    return min(allowed, key=lambda lv: (abs(_LEVEL_RANK.get(lv, 2) - rank), _LEVEL_RANK.get(lv, 2)))


def native_thinking_for(model: dict[str, Any], level: str, requirements: dict[str, Any]) -> dict[str, Any]:
    """Map the normalized level to the real control on the execution surface.

    Never invents parameters: when a model exposes no verified selectable
    control, the native setting is reported as automatic.
    """
    surface = model["surface"]
    think = model["thinking"]

    if surface == "claude_team":
        if think["control"] == "automatic" or not think["levels"]:
            return {
                "native_setting": "automatic",
                "detail": "This model exposes no effort parameter in Claude Code; "
                          "extended thinking is on/off only.",
            }
        target = level
        if level == "very_high":
            if requirements["risk"] >= 0.95 and requirements["complexity"] >= 0.85:
                target = "max"
            else:
                target = "xhigh"
        native = _nearest_level(target, think["levels"])
        return {
            "native_setting": f"{think['native_prefix']} {native}",
            "detail": f"Effort levels supported: {', '.join(think['levels'])}. "
                      f"Model default: {think['default']}.",
        }

    if surface == "chatgpt_plus":
        if think["control"] == "automatic" or not think["levels"]:
            return {"native_setting": "automatic", "detail": "No selectable reasoning control."}
        allowed = list(think["levels"])
        target = level
        if level == "very_high":
            if requirements["risk"] >= 0.90 and requirements["complexity"] >= 0.85:
                target = "max" if "max" in allowed else "xhigh"
            else:
                target = "xhigh" if "xhigh" in allowed else ("max" if "max" in allowed else "high")
        native = _nearest_level(target, allowed)
        if model["model_id"] == "gpt-5.6-sol" and native == "instant":
            native = "medium"
        label = _LEVEL_LABEL.get(native, native)
        return {
            "native_setting": f"{think['native_prefix']}: {label}",
            "detail": f"Picker values: {', '.join(allowed)}. {think['notes']}",
        }

    # OpenCode Go
    if think["control"] == "automatic" or not think["levels"]:
        return {
            "native_setting": "automatic",
            "detail": "No verified selectable reasoning control for this model on OpenCode Go; "
                      "the provider default applies.",
        }
    target = level
    if level == "very_high":
        target = "max" if "max" in think["levels"] else ("xhigh" if "xhigh" in think["levels"] else "high")
    native = _nearest_level(target, think["levels"])
    if think.get("verified"):
        setting = f"reasoningEffort: {native} (OpenCode Go)"
        detail = f"Verified control. Levels: {', '.join(think['levels'])}."
    else:
        setting = "automatic (provider default)"
        detail = (
            f"Desired normalized level is {level}; if the model exposes a variant in the Go "
            f"catalog, use '{native}'. Level names are not verified for this model, so the "
            f"safe instruction is to leave the provider default."
        )
    return {
        "native_setting": setting,
        "desired_variant": native if not think.get("verified") else None,
        "detail": detail,
    }


def build_reason(
    phase: dict[str, Any],
    requirements: dict[str, Any],
    route: dict[str, Any],
) -> str:
    primary = route["primary"]
    model = MODEL_REGISTRY[primary["registry_key"]]
    task = requirements["dominant_task"].replace("_", " ")
    top_dims = sorted(
        ((d, w) for d, w in requirements["weights"].items() if w > 0.05),
        key=lambda kv: kv[1],
        reverse=True,
    )[:3]
    dim_txt = ", ".join(f"{d.replace('_', ' ')} ({w:.2f})" for d, w in top_dims)
    basis = route.get("selection_basis", {})
    eff_w = efficiency_weight_for(requirements)
    efficiency_note = (
        "quota efficiency was allowed to matter" if eff_w >= 0.35
        else "quality was weighted above quota cost" if eff_w <= 0.15
        else "a balanced capability/cost weighting was used"
    )
    price = model["price_per_mtok"]
    bits = [
        f"Task reads as {task} with top needs {dim_txt}.",
        f"{model['display']} clears the phase's capability bar "
        f"({primary['capability_fit']:.2f}/10 vs threshold {basis.get('capability_threshold', 0):.2f}) "
        f"at effective cost pressure {primary['cost_pressure']:.2f} "
        f"(${price['input']:.2f} in / ${price['output']:.2f} out per MTok); "
        f"the strongest-fit option was {basis.get('best_fit_model', '-')} at "
        f"{basis.get('best_fit_cost_pressure', 0):.2f} cost pressure, and {efficiency_note}.",
    ]
    if requirements["risk"] >= 0.75:
        bits.append("High execution risk, so the capability bar was kept tight "
                    "(cost still decides only among models that clear it).")
    if requirements["ambiguity"] >= 0.6:
        bits.append("The prompt leaves room for judgment, which favors a stronger model.")
    if route["fallback_used"]:
        bits.append("No fully eligible candidate met every critical floor; the best available was chosen and flagged.")
    return " ".join(bits)


# ---------------------------------------------------------------------------
# Selftest profiler (synthetic; used ONLY by --selftest / --dry-run checks)
# ---------------------------------------------------------------------------


def synthetic_profile(phase: dict[str, Any]) -> dict[str, Any]:
    """Deterministic keyword-based pseudo-profile for pipeline testing.

    This is deliberately simple and is never used in a real routing run; it
    exists so the parser, router, thinking policy and reports can be exercised
    without spending Jev credits. Real profiles always come from Jev.
    """
    text = phase["prompt"].lower()
    weighted_patterns: dict[str, list[tuple[str, int]]] = {
        "ml_cv_engineering": [(r"\bonnx\b", 3), (r"sam2", 3), (r"embedding", 3),
                              (r"dinov2", 3), (r"classifier", 3), (r"recognition", 2),
                              (r"depth anything", 3), (r"segmentation", 3), (r"inpainting", 3),
                              (r"\bknn\b", 2)],
        "graphics_3d_engineering": [(r"shader", 3), (r"fragmentprogram", 3),
                                    (r"drawvertices", 3), (r"gltf", 3), (r"trimesh", 3),
                                    (r"renderer", 3), (r"filament", 3), (r"thermion", 3),
                                    (r"choisy", 2), (r"3d runtime", 3), (r"spaceplayer", 3),
                                    (r"dome assemblies|domes? assembl", 2), (r"turntable", 1)],
        "audio_dsp": [(r"acoustic", 3), (r"impulse response", 3), (r"fft", 3), (r"audio", 2),
                      (r"tts", 3), (r"soundscape", 3), (r"narration", 2), (r"microphone", 2)],
        "map_geodata": [(r"geojson", 3), (r"openstreetmap", 3), (r"\bosm\b", 3),
                        (r"\batlas\b", 2), (r"time slider", 3), (r"coastline", 2),
                        (r"elevation", 2), (r"\broute\b", 1)],
        "release_ops": [(r"play app signing", 3), (r"upload key", 3), (r"store listing", 3),
                        (r"release engineering", 3), (r"aab", 2), (r"rollout", 2),
                        (r"keystore", 2)],
        "accessibility": [(r"talkback", 3), (r"reduced.motion", 3), (r"wcag", 3),
                          (r"font scale", 3), (r"focus order", 3), (r"accessib", 2),
                          (r"switch.access", 2)],
        "security_privacy": [(r"zip-slip", 3), (r"data safety", 3), (r"privacy", 2),
                             (r"permission", 2), (r"secrets", 2), (r"monkey", 1)],
        "localization_content_ops": [(r"\barb\b", 3), (r"localisation|localization", 2),
                                     (r"bilingual", 2), (r"language switch", 3),
                                     (r"turkish", 1), (r"pseudo.localisation", 3)],
        "performance_optimization": [(r"cold start", 3), (r"\bfps\b", 3), (r"\bjank", 3),
                                     (r"thermal", 3), (r"performance", 2), (r"memory", 2),
                                     (r"asset delivery", 2)],
        "testing_ci": [(r"integration_test", 3), (r"github actions", 3), (r"test pyramid", 3),
                       (r"device matrix", 3), (r"\bcoverage\b", 2), (r"\bci\b", 2)],
        "content_research": [(r"wikidata", 3), (r"\bqid\b", 3), (r"research", 2),
                             (r"histor", 2), (r"sources", 1), (r"verified and cited", 3),
                             (r"cite", 2)],
        "ui_visual_design": [(r"design language", 3), (r"palette", 3), (r"typography", 3),
                             (r"anti-slop", 3), (r"planicon", 3), (r"tokens", 2),
                             (r"golden test", 2), (r"design system", 3)],
        "refactor_migration": [(r"clean slate", 3), (r"prune", 3), (r"migrat", 2),
                               (r"rename", 2), (r"\bdelete\b", 2), (r"remove", 1)],
        "bugfix_debugging": [(r"\bdebug", 3), (r"regression", 3), (r"crash", 3),
                             (r"\bflake", 3), (r"investigate", 2)],
        "platform_integration": [(r"methodchannel", 3), (r"minSdk", 2), (r"gradle", 2),
                                 (r"lifecycle", 2), (r"mediastore", 3), (r"sharesheet", 2)],
        "data_pipeline_tooling": [(r"validator", 3), (r"schema version", 2),
                                  (r"assets/content", 2), (r"pipeline", 2),
                                  (r"\bcli\b", 2), (r"docstring", 2)],
        "implementation_feature": [(r"acceptance", 1), (r"build", 1), (r"implement", 1)],
    }
    task_scores: dict[str, int] = {}
    for task, patterns in weighted_patterns.items():
        score = sum(weight for pat, weight in patterns if re.search(pat, text))
        if score:
            task_scores[task] = score
    dom = max(task_scores, key=lambda k: task_scores[k]) if task_scores else "implementation_feature"

    def s(v: float) -> dict[str, Any]:
        return {"type": "score", "score": v, "confidence": 0.8,
                "legend": {str(i): LEVEL_DESCRIPTIONS_5[i] for i in range(5)},
                "probabilities": {str(i): (1.0 if i == int(round(v)) else 0.0) for i in range(5)}}

    def has(pat: str) -> bool:
        return bool(re.search(pat, text))

    long_context = 3.0 if len(phase["prompt"]) > 4500 else 1.5
    graphics = 3.5 if has(r"shader|3d|gltf|trimesh|dome|mesh") else 0.5
    ml = 3.5 if has(r"onnx|sam2|embedding|dinov2|knn|classifier|segmentation|depth|inpainting") else 0.5
    visual = 3.0 if has(r"design|palette|golden|screenshot|capture|typography|plate|artwork") else 1.0
    research = 3.0 if has(r"research|verify|cited|sources|history|histor|wikidata") else 0.5
    risk = 3.0 if has(r"delete|remove|prune|migrat|security|release|architecture|engine|runtime") else 1.5
    ambiguity = 2.5 if has(r"decide|choose|pick|direction|spike|evaluate|reproduce") else 1.5
    tests = 3.0 if has(r"test|acceptance|golden|validator|ci\b") else 1.5

    d = {
        "dominant_task": {"type": "choice", "choice": dom, "confidence": 0.8,
                          "probabilities": {k: (1.0 if k == dom else 0.0) for k in DOMINANT_TASKS}},
        "is_audit_or_verification": {"type": "noul", "noul": 0.8 if has(r"re-run|audit|verify, never redo") else 0.1},
        "implementation_complexity": s(3.0 if len(phase["prompt"]) > 4000 else 2.0),
        "reasoning_depth": s(3.0 if has(r"architecture|engine|runtime|design|pipeline") else 2.0),
        "architecture_need": s(3.0 if has(r"architecture|engine|runtime|registry|design language|system|pipeline") else 1.5),
        "repo_context_need": s(3.0 if has(r"repo|existing|depends on|codebase|lib/|migrate") else 2.0),
        "debugging_need": s(2.5 if has(r"debug|performance|fps|regression|jank") else 1.0),
        "ambiguity": s(ambiguity),
        "execution_risk": s(risk),
        "instruction_precision": s(3.0 if has(r"acceptance|must |exactly|do not|never ") else 2.0),
        "tool_use_need": s(3.5 if has(r"build|run|test|flutter analyze|cup|adb|tool/") else 2.0),
        "research_need": s(research),
        "frontend_ui_need": s(3.0 if has(r"ui|screen|page|widget|layout|today|tab|sheet") else 1.5),
        "visual_reasoning_need": s(visual),
        "graphics_3d_need": s(graphics),
        "ml_cv_need": s(ml),
        "audio_dsp_need": s(3.5 if has(r"acoustic|impulse|fft|audio|tts|soundscape|narration") else 0.2),
        "multimodal_need": s(2.5 if has(r"screenshot|photo|image|render|golden|capture") else 0.5),
        "test_verification_need": s(tests),
        "cross_component_need": s(3.0 if has(r"pipeline|engine|route|migrat|integration|registry") else 1.5),
        "long_context_need": s(long_context),
        "factual_accuracy_need": s(3.0 if has(r"cite|sources|verify|history|histor|wikidata|qid|honesty") else 0.5),
    }
    return d


# ---------------------------------------------------------------------------
# Output: phase_routing.json and PHASE_MODEL_ROUTING.md
# ---------------------------------------------------------------------------

def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def build_phase_record(
    phase: dict[str, Any],
    profile: dict[str, Any],
    requirements: dict[str, Any],
    route: dict[str, Any],
    *,
    profile_source: str,
) -> dict[str, Any]:
    primary_model = MODEL_REGISTRY[route["primary"]["registry_key"]]
    native = route["thinking"]["native"]
    record: dict[str, Any] = {
        "phase_id": phase["phase_id"],
        "phase_title": phase["phase_title"],
        "source_lines": [phase["source_start_line"], phase["source_end_line"]],
        "source_file": phase["source_file"],
        "prompt_sha256": phase["prompt_sha256"],
        "task_profile": {
            "source": profile_source,
            "dominant_task": requirements["dominant_task"],
            "dominant_task_confidence": requirements["dominant_task_confidence"],
            "signals": requirements["raw_scores"],
            "is_audit_or_verification": requirements["is_audit_or_verification"],
            "profile_confidence": requirements["profile_confidence"],
            "uncertainty": requirements["uncertainty"],
            "critical_dims": requirements["critical_dims"],
        },
        "route": {
            "surface": primary_model["surface"],
            "model": primary_model["model_id"],
            "model_display": primary_model["display"],
            "thinking_level": route["thinking"]["level"],
            "native_thinking_setting": native["native_setting"],
            "native_thinking_detail": native["detail"],
            "confidence": route["confidence"],
            "capability_fit": route["primary"]["capability_fit"],
            "price_per_mtok": primary_model["price_per_mtok"],
            "cost_pressure": primary_model["cost_pressure"],
            "selection_margin_over_threshold": route["margin"],
            "selection_basis": route.get("selection_basis"),
            "availability_fallback": route.get("availability_fallback"),
        },
        "reason": build_reason(phase, requirements, route),
        "candidate_scores": route["candidates"],
        "thinking_policy": {
            "score": route["thinking"]["score"],
            "drivers": route["thinking"]["drivers"],
            "model_bias": route["thinking"]["model_bias"],
        },
    }
    alt = route["alternative"]
    if alt is not None:
        record["alternative"] = {
            "surface": alt["surface"],
            "model": alt["model_id"],
            "model_display": alt["display"],
            "thinking_level": route["alternative_thinking"]["level"],
            "native_thinking_setting": route["alternative_thinking"]["native_setting"],
            "capability_fit": alt["capability_fit"],
            "total": alt["total"],
        }
    else:
        record["alternative"] = None
    if profile_source == "jev":
        record["jev_raw_response"] = profile.get("_raw")
        record["jev_cache"] = profile.get("_cache", "miss")
    return record


def failed_phase_record(phase: dict[str, Any], error: str, profile_source: str) -> dict[str, Any]:
    return {
        "phase_id": phase["phase_id"],
        "phase_title": phase["phase_title"],
        "source_lines": [phase["source_start_line"], phase["source_end_line"]],
        "source_file": phase["source_file"],
        "prompt_sha256": phase["prompt_sha256"],
        "status": "jev_failed",
        "task_profile": {"source": profile_source, "error": sanitize_text(error)},
        "route": None,
        "alternative": None,
        "reason": "Jev evaluation failed for this phase after retries; no model was assigned. "
                  "Re-run with the same command (cached successes are reused).",
        "candidate_scores": [],
    }


def distribution_check(records: list[dict[str, Any]]) -> dict[str, Any]:
    counts: dict[str, int] = {}
    for rec in records:
        route = rec.get("route")
        if not route:
            continue
        key = f"{route['surface']}/{route['model']}"
        counts[key] = counts.get(key, 0) + 1
    total = sum(counts.values())
    worst = max(counts.items(), key=lambda kv: kv[1]) if counts else ("none", 0)
    share = worst[1] / total if total else 0.0
    warnings: list[str] = []
    if total >= 5 and share > 0.60:
        warnings.append(
            f"{worst[0]} received {worst[1]}/{total} phases ({share:.0%}). That can be legitimate "
            f"(one model genuinely best) but check critical-dim floors and efficiency weighting."
        )
    if total >= 5 and len(counts) == 1:
        warnings.append("Only one model was selected across all routed phases.")
    return {
        "counts": dict(sorted(counts.items(), key=lambda kv: kv[1], reverse=True)),
        "routed_phases": total,
        "top_model": worst[0],
        "top_share": round(share, 3),
        "warnings": warnings,
    }


def write_json_output(
    out_dir: Path,
    filename: str,
    records: list[dict[str, Any]],
    meta: dict[str, Any],
) -> Path:
    payload = {
        "schema": "phase-routing/1",
        "generated_at": now_iso(),
        "script_version": SCRIPT_VERSION,
        "jev_schema_version": JEV_SCHEMA_VERSION,
        "meta": meta,
        "phases": records,
    }
    path = out_dir / filename
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return path


def summarize_task_profile(record: dict[str, Any]) -> list[str]:
    prof = record.get("task_profile", {})
    signals = prof.get("signals", {})
    order = [
        ("implementation_complexity", "implementation complexity"),
        ("reasoning_depth", "reasoning depth"),
        ("architecture_need", "architecture need"),
        ("repo_context_need", "repo context need"),
        ("debugging_need", "debugging need"),
        ("ambiguity", "ambiguity"),
        ("execution_risk", "execution risk"),
        ("research_need", "research need"),
        ("frontend_ui_need", "frontend/UI need"),
        ("visual_reasoning_need", "visual reasoning need"),
        ("graphics_3d_need", "3D/graphics need"),
        ("ml_cv_need", "ml/cv need"),
        ("audio_dsp_need", "audio/dsp need"),
        ("test_verification_need", "test/verification need"),
        ("cross_component_need", "cross-component need"),
        ("long_context_need", "long-context need"),
        ("factual_accuracy_need", "factual accuracy need"),
    ]
    lines: list[str] = []
    if prof.get("dominant_task"):
        lines.append(f"dominant task: {prof['dominant_task']} "
                     f"(p={prof.get('dominant_task_confidence', 0):.2f})")
    for key, label in order:
        val = signals.get(key)
        if val is None:
            continue
        if val >= 2.5 or (key in ("execution_risk", "ambiguity") and val >= 2.0):
            lines.append(f"{label}: {val:.4g}/4")
    if not lines:
        lines.append("no strong signals")
    return lines


def render_markdown(
    records: list[dict[str, Any]],
    meta: dict[str, Any],
) -> str:
    lines: list[str] = []
    lines.append("# Phase Model Routing")
    lines.append("")
    lines.append(f"Generated: {meta['generated_at']}  ")
    lines.append(f"Phases file: `{meta['phases_file']}` ({meta['phase_count']} prompts, "
                 f"P{meta['first_phase']:02d}-P{meta['last_phase']:02d})  ")
    lines.append(f"Catalog researched: {meta['catalog_researched_at']}  ")
    if meta.get("catalog_fetched_at"):
        lines.append(f"OpenCode Go catalog checked: {meta['catalog_fetched_at']} "
                     f"({meta['catalog_source']}, {meta.get('catalog_count', 0)} models)  ")
    lines.append(f"Jev schema: {JEV_SCHEMA_VERSION}; profiles source: {meta['profile_source']}  ")
    lines.append(f"Cost model: {meta.get('cost_model_version', COST_MODEL_VERSION)}; "
                 f"cost aversion: {meta.get('cost_aversion', 'medium')}  ")
    lines.append("")
    lines.append("> One primary model + thinking level per phase. The router uses Jev only for "
                 "task understanding; model choice comes from the researched capability registry. "
                 "Among models that clear the phase's capability bar, the cheapest is chosen; the "
                 "bar tightens as execution risk rises. Confidence is an estimate, not a guarantee.")
    lines.append("")
    if meta.get("phase_count_note"):
        lines.append(meta["phase_count_note"])
        lines.append("")

    lines.append("## Routing table")
    lines.append("")
    lines.append("| Phase | Phase title | Surface | Model | Thinking | Cost | Confidence | Alternative |")
    lines.append("| --- | --- | --- | --- | --- | --- | --- | --- |")
    for rec in records:
        route = rec.get("route")
        if not route:
            lines.append(f"| {rec['phase_id']} | {_md_escape(rec['phase_title'])} | - | **JEV FAILED** | - | - | - | - |")
            continue
        alt = rec.get("alternative") or {}
        alt_txt = f"{alt.get('surface', '-')} / {alt.get('model_display', '-')}" if alt else "-"
        lines.append(
            f"| {rec['phase_id']} | {_md_escape(rec['phase_title'])} | {route['surface']} | "
            f"`{route['model']}` | {route['thinking_level']} | {route.get('cost_pressure', 0):.2f} | "
            f"{route['confidence']:.2f} | {_md_escape(alt_txt)} |"
        )
    lines.append("")

    for rec in records:
        route = rec.get("route")
        lines.append(f"## {rec['phase_id']} - {rec['phase_title']}")
        lines.append("")
        if not route:
            lines.append("Primary: **JEV FAILED** - no model assigned. See task profile error.")
            lines.append("")
            lines.append(f"Source: {rec['source_file']} lines {rec['source_lines'][0]}-{rec['source_lines'][1]}, "
                         f"hash `{rec['prompt_sha256'][:12]}`")
            lines.append("")
            continue
        lines.append("Primary:")
        lines.append(f"{route['surface']} / `{route['model']}` ({route['model_display']})")
        lines.append("")
        lines.append("Thinking:")
        lines.append(route["thinking_level"])
        if route.get("native_thinking_setting"):
            lines.append(f"native setting: {route['native_thinking_setting']}")
            if route.get("native_thinking_detail"):
                lines.append(route["native_thinking_detail"])
        lines.append("")
        price = route.get("price_per_mtok") or {}
        basis = route.get("selection_basis") or {}
        if price:
            lines.append("Cost:")
            lines.append(f"${price['input']:.2f} in / ${price['output']:.2f} out per MTok "
                         f"(API list); effective cost pressure {route.get('cost_pressure', 0):.2f} "
                         f"(0 = cheapest registry model, 1 = most expensive).")
            if basis:
                lines.append(f"capability bar {basis.get('capability_threshold', 0):.2f}, "
                             f"best-fit model `{basis.get('best_fit_model', '-')}` at cost pressure "
                             f"{basis.get('best_fit_cost_pressure', 0):.2f}; "
                             f"{basis.get('candidates_within_threshold', 0)} candidate(s) cleared the bar.")
        lines.append("")
        lines.append("Why:")
        lines.append(rec["reason"])
        lines.append("")
        lines.append("Task profile:")
        for tl in summarize_task_profile(rec):
            lines.append(f"- {tl}")
        prof = rec.get("task_profile", {})
        lines.append(f"- profile confidence: {prof.get('profile_confidence', 0):.2f}; "
                     f"uncertainty: {prof.get('uncertainty', 0):.2f}")
        lines.append("")
        alt = rec.get("alternative")
        if alt:
            lines.append("Alternative:")
            lines.append(f"{alt['surface']} / `{alt['model']}` ({alt['model_display']}) - "
                         f"thinking {alt['thinking_level']} ({alt.get('native_thinking_setting', '-')})")
            lines.append("")
        lines.append(f"Routing confidence: {route['confidence']:.2f} "
                     f"(fit margin over bar {route.get('selection_margin_over_threshold', 0):+.3f}, "
                     f"capability fit {route.get('capability_fit', 0):.2f}/10)")
        if route.get("availability_fallback"):
            fb = route["availability_fallback"]
            lines.append(f"Availability fallback: `{fb['would_have_been']}` would have ranked "
                         f"first but is {fb['reason']}.")
        lines.append("")
        lines.append("Top candidates:")
        for cand in rec.get("candidate_scores", []):
            status = "ok" if cand["eligible"] else "blocked: " + "; ".join(cand["blocked_by"])
            lines.append(f"- {cand['surface']} / `{cand['model_id']}`: fit {cand['capability_fit']:.2f}, "
                         f"cost {cand['cost_pressure']:.2f} "
                         f"(${cand['price_per_mtok']['input']:.2f}/${cand['price_per_mtok']['output']:.2f}), "
                         f"penalties {cand['cost_penalty']:.2f}/{cand['context_penalty']:.2f}, "
                         f"total {cand['total']:.2f} ({status})")
        lines.append("")
        lines.append(f"Source: {rec['source_file']} lines {rec['source_lines'][0]}-{rec['source_lines'][1]}, "
                     f"hash `{rec['prompt_sha256'][:12]}`")
        lines.append("")

    dist = meta["distribution"]
    lines.append("## Distribution sanity check")
    lines.append("")
    if not dist["counts"]:
        lines.append("No routed phases.")
    else:
        for model_key, count in dist["counts"].items():
            lines.append(f"- {model_key}: {count}")
        lines.append("")
        if dist["warnings"]:
            for warning in dist["warnings"]:
                lines.append(f"Warning: {warning}")
        else:
            lines.append("Distribution looks differentiated; no single model dominates above the "
                         "60% alert threshold.")
        lines.append("")
    if meta.get("distribution_explanation"):
        lines.append(meta["distribution_explanation"])
        lines.append("")

    lines.append("## Model capability summary")
    lines.append("")
    lines.append("Models that participated in routing (primary or alternative), with the "
                 "project-specific reasons the engine distinguishes them.")
    lines.append("")
    participants = _participants(records)
    for key in participants:
        model = MODEL_REGISTRY[key]
        top = sorted(model["scores"].items(), key=lambda kv: kv[1], reverse=True)[:4]
        low = sorted(model["scores"].items(), key=lambda kv: kv[1])[:3]
        think = model["thinking"]
        lines.append(f"### {model['display']} (`{model['model_id']}`)")
        lines.append("")
        lines.append(f"- Surface: {SURFACES[model['surface']]['label']}")
        lines.append(f"- Strengths: " + ", ".join(f"{d.replace('_', ' ')} {v:.1f}" for d, v in top))
        lines.append(f"- Weaker: " + ", ".join(f"{d.replace('_', ' ')} {v:.1f}" for d, v in low))
        lines.append(f"- Context: {model['context_tokens']:,} tokens; vision input: "
                     f"{'yes' if model['vision'] else 'no'}")
        p = model["price_per_mtok"]
        lines.append(f"- API list price: ${p['input']:.2f} in / ${p['output']:.2f} out per MTok "
                     f"({p.get('basis', '')})")
        lines.append(f"- Effective cost pressure (0-1, global price + surface burn): "
                     f"{model['cost_pressure']:.2f}; surface allowance burn: {model['usage_pressure']:.2f}")
        if think["control"] == "automatic" or not think["levels"]:
            lines.append("- Reasoning control: automatic (no selectable effort parameter)")
        else:
            lines.append(f"- Reasoning control: {think['control'].replace('_', ' ')}; "
                         f"levels: {', '.join(think['levels'])}; default: {think['default']}"
                         f"{' (verified)' if think.get('verified') else ' (variant names unverified on this surface)'}")
        if model.get("evidence"):
            for dim, note in list(model["evidence"].items())[:4]:
                lines.append(f"- Evidence ({dim.replace('_', ' ')}): {note}")
        lines.append(f"- Availability: {model['availability']['detail']}")
        lines.append("")

    lines.append("## Cost model and price reference")
    lines.append("")
    lines.append("Prices are API list prices from the same research pass as the capability scores. "
                 "Subscriptions (Claude Team, ChatGPT Plus) are flat, so price is used as the "
                 "relative allowance-burn proxy there; OpenCode Go limits are dollar-denominated, "
                 "so price maps directly to quota burn.")
    lines.append("")
    lines.append("Effective cost pressure = 0.60 * global price norm + 0.40 * within-surface norm, "
                 "where price is weighted 30% input / 70% output and normalized against the most "
                 "expensive registry model (GPT-6 Astra). The router picks the cheapest model whose "
                 "capability fit clears the phase's bar: `bar = max(min_fit, best_fit - tolerance)`, "
                 "with `tolerance` widening as risk and complexity fall, scaled by "
                 f"`--cost-aversion` ({meta.get('cost_aversion', 'medium')}).")
    lines.append("")
    lines.append("| Model | Surface | In $/MTok | Out $/MTok | Cost pressure |")
    lines.append("| --- | --- | --- | --- | --- |")
    for key, model in sorted(MODEL_REGISTRY.items(),
                             key=lambda kv: kv[1]["price_per_mtok"]["output"], reverse=True):
        p = model["price_per_mtok"]
        lines.append(f"| `{model['model_id']}` | {model['surface']} | {p['input']:.2f} | "
                     f"{p['output']:.2f} | {model['cost_pressure']:.2f} |")
    lines.append("")

    lines.append("## Surface usage notes")
    lines.append("")
    for sid, surface in SURFACES.items():
        lines.append(f"### {surface['label']} (`{sid}`)")
        lines.append("")
        lines.append(f"- How to run: {surface['execution']}")
        lines.append(f"- Usage economics: {surface['usage_model']}")
        lines.append(f"- Thinking control: {surface['thinking_control']}")
        lines.append(f"- Verification: {surface['verification']}")
        lines.append("")

    lines.append("## Research snapshot")
    lines.append("")
    lines.append(f"- Catalog researched at: {meta['catalog_researched_at']}. "
                 f"OpenCode Go IDs are re-checked live at run time; Claude and ChatGPT availability "
                 f"is a documented snapshot and can lag staged rollouts.")
    lines.append(f"- Registered models: {len(MODEL_REGISTRY)}. "
                 f"Phases reference this registry; new models are added here, never in Jev.")
    if meta.get("unavailable_registry_models"):
        lines.append("- Registry entries not present in the live OpenCode Go catalog this run "
                     "(excluded from routing): " +
                     ", ".join(f"`{m}`" for m in meta["unavailable_registry_models"]))
    lines.append("- Benchmark scores are not compared across incompatible harnesses; "
                 "they are used directionally with vendor claims marked as vendor claims.")
    lines.append("")
    for sid, src in SOURCES.items():
        lines.append(f"- [{src['title']}]({src['url']}) - accessed {src['accessed']}. {src['supports']}")
    lines.append("")
    if meta.get("phase_count_note"):
        lines.append(meta["phase_count_note"])
        lines.append("")
    lines.append(TRAILING_MARKER)
    lines.append("")
    return "\n".join(lines)


def _participants(records: list[dict[str, Any]]) -> list[str]:
    keys: list[str] = []
    for rec in records:
        for entry in (rec.get("route"), rec.get("alternative")):
            if not entry:
                continue
            for key, model in MODEL_REGISTRY.items():
                if model["surface"] == entry["surface"] and model["model_id"] == entry["model"]:
                    if key not in keys:
                        keys.append(key)
    return keys


def _md_escape(text: str) -> str:
    return str(text).replace("|", "\\|")


# ---------------------------------------------------------------------------
# Jev profile cache
# ---------------------------------------------------------------------------

def jev_cache_path(cache_dir: Path, prompt_sha256: str) -> Path:
    return cache_dir / "jev" / f"{prompt_sha256}.{JEV_SCHEMA_VERSION}.json"


def load_cached_profile(cache_dir: Path, prompt_sha256: str) -> Optional[dict[str, Any]]:
    path = jev_cache_path(cache_dir, prompt_sha256)
    if not path.exists():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return None
    if data.get("prompt_sha256") != prompt_sha256 or data.get("schema_version") != JEV_SCHEMA_VERSION:
        return None
    return data


def save_cached_profile(cache_dir: Path, prompt_sha256: str, response: dict[str, Any],
                        requested_model: str) -> None:
    path = jev_cache_path(cache_dir, prompt_sha256)
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "prompt_sha256": prompt_sha256,
        "schema_version": JEV_SCHEMA_VERSION,
        "saved_at": now_iso(),
        "requested_model": requested_model,
        "resolved_model": response.get("model"),
        "response": response,
    }
    path.write_text(sanitize_text(json.dumps(payload, indent=2, ensure_ascii=False)) + "\n",
                    encoding="utf-8")


def get_profile(
    phase: dict[str, Any],
    client: Optional[JevClient],
    cache_dir: Path,
    *,
    force: bool,
    verbose: bool,
) -> dict[str, Any]:
    """Return a Jev profile (cached or fresh) with raw response for audit."""
    cached = None if force else load_cached_profile(cache_dir, phase["prompt_sha256"])
    if cached is not None:
        return {"answers": cached["response"].get("answers", {}), "_raw": cached["response"],
                "_cache": "hit", "_model": cached.get("resolved_model")}
    if client is None:
        raise RuntimeError("Jev client unavailable")

    state = build_jev_state(phase)
    response, requested = client.system_one(state, JEV_QUESTIONS)
    errors = validate_jev_response(response)
    if errors:
        if verbose:
            print(f"  [jev] invalid response for {phase['phase_id']}: {errors}", file=sys.stderr)
        response2, requested2 = client.system_one(state, JEV_QUESTIONS)
        errors2 = validate_jev_response(response2)
        if errors2:
            raise RuntimeError(f"Jev response failed validation twice: {errors2}")
        response, requested = response2, requested2
    save_cached_profile(cache_dir, phase["prompt_sha256"], response, requested)
    return {"answers": response.get("answers", {}), "_raw": response, "_cache": "miss",
            "_model": response.get("model")}


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

PHASE_COUNT_NOTE = (
    "**Phase count note.** The brief expected approximately 40 prompts. This PHASES.md "
    "genuinely contains 41 actual prompts (P00-P40): P00 ('Milion identity and plan') is "
    "marked done in the file but is kept as a re-runnable audit prompt, so it counts and is "
    "routed. The parser asserts 41 rather than forcing 40; it fails loudly if the document "
    "changes structurally."
)


def parse_args(argv: Optional[list[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="route_phases.py",
        description="Evidence-based model + thinking-level routing for PHASES.md phase prompts.",
        epilog=(
            "Examples:\n"
            "  python route_phases.py PHASES.md\n"
            "  python route_phases.py PHASES.md --dry-run\n"
            "  python route_phases.py PHASES.md --refresh --force-jev\n"
            "  python route_phases.py PHASES.md --offline\n"
            "  python route_phases.py --jev-check\n"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("phases_file", nargs="?", default="PHASES.md",
                        help="path to the phases document (default: PHASES.md)")
    parser.add_argument("--dry-run", action="store_true",
                        help="parse and validate only; no network calls, no outputs written")
    parser.add_argument("--refresh", action="store_true",
                        help="force a refresh of the OpenCode Go model catalog")
    parser.add_argument("--force-jev", action="store_true",
                        help="ignore cached Jev profiles and call the API again")
    parser.add_argument("--offline", action="store_true",
                        help="never touch the network; use cached catalog/profiles only")
    parser.add_argument("--jev-check", action="store_true",
                        help="make one minimal Jev API call to verify key and endpoint, then exit")
    parser.add_argument("--selftest", action="store_true",
                        help="run the full pipeline with synthetic task profiles (no Jev, no network); "
                             "writes *.selftest.* outputs")
    parser.add_argument("--only", default=None,
                        help="comma-separated phase ids to process, e.g. --only P06,P07")
    parser.add_argument("--limit", type=int, default=None, help="process only the first N phases")
    parser.add_argument("--cost-aversion", choices=["low", "medium", "high"], default="medium",
                        help="how strongly to favor cheaper models: low keeps the capability bar "
                             "tight (quality first), high widens it (cost first); default medium")
    parser.add_argument("--cache-dir", default=DEFAULT_CACHE_DIR,
                        help=f"cache directory (default: {DEFAULT_CACHE_DIR})")
    parser.add_argument("--out-dir", default=".",
                        help="directory for phase_routing.json and PHASE_MODEL_ROUTING.md (default: .)")
    parser.add_argument("--verbose", action="store_true", help="more console detail")
    return parser.parse_args(argv)


def print_parse_summary(phases: list[dict[str, Any]]) -> None:
    print(f"Parsed {len(phases)} actual phase prompts "
          f"(P{phases[0]['phase_index']:02d}-P{phases[-1]['phase_index']:02d}).")
    total_chars = sum(len(p["prompt"]) for p in phases)
    print(f"Prompt bytes: {total_chars:,}; hash algorithm: sha256.")
    for ph in phases:
        note = f"  [{ph['status_note']}]" if ph["status_note"] else ""
        extra = f"  (+{ph['extra_text_blocks']} extra text block(s))" if ph["extra_text_blocks"] else ""
        print(f"  {ph['phase_id']}  lines {ph['source_start_line']:>4}-{ph['source_end_line']:<4} "
              f"{len(ph['prompt']):>5} chars  {ph['prompt_sha256'][:10]}  {ph['phase_title']}{note}{extra}")


def distribution_explanation(records: list[dict[str, Any]], dist: dict[str, Any]) -> str:
    tasks: dict[str, int] = {}
    for rec in records:
        t = (rec.get("task_profile") or {}).get("dominant_task")
        if t:
            tasks[t] = tasks.get(t, 0) + 1
    if not tasks:
        return ""
    top_tasks = sorted(tasks.items(), key=lambda kv: kv[1], reverse=True)[:4]
    task_txt = ", ".join(f"{k.replace('_', ' ')} x{v}" for k, v in top_tasks)
    if dist["warnings"]:
        return (f"The distribution is not uniform because the task mix is not uniform ({task_txt}). "
                f"Re-check the flagged model's critical-dim scores before treating it as bias; "
                f"forcing variety across subscriptions is not a goal.")
    return (f"Task mix driving the distribution: {task_txt}. The router selects the cheapest "
            f"effective-cost model that clears each phase's capability bar; the bar tightens as "
            f"execution risk rises, which is why cheap models win routine phases and frontier "
            f"models are kept for risky ones.")


def run(args: argparse.Namespace) -> int:
    cache_dir = Path(args.cache_dir).expanduser()
    out_dir = Path(args.out_dir).expanduser()
    cache_dir.mkdir(parents=True, exist_ok=True)
    out_dir.mkdir(parents=True, exist_ok=True)

    if args.jev_check:
        key = os.environ.get("TYPESAFE_API_KEY")
        if not key:
            print("ERROR: TYPESAFE_API_KEY is not set in the environment.", file=sys.stderr)
            return 3
        client = JevClient(key, verbose=args.verbose)
        try:
            result = client.check()
        except Exception as exc:  # noqa: BLE001
            print(f"Jev check failed: {sanitize_text(str(exc))}", file=sys.stderr)
            return 3
        print("Jev check OK")
        print(f"  requested model: {result['requested_model']}")
        print(f"  resolved model:  {result['resolved_model']}")
        print(f"  answer:          {result['answer']}")
        print(f"  usage:           {result['usage']}")
        return 0

    phases_path = resolve_input_path(args.phases_file)
    md_text = phases_path.read_text(encoding="utf-8")
    try:
        phases = parse_phases(md_text, source_name=phases_path.name)
    except PhaseParseError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    print_parse_summary(phases)
    if args.dry_run and not args.selftest:
        print("Dry run complete: parsing validated, no Jev calls, no outputs written.")
        return 0

    if args.only:
        wanted = {p.strip().upper() for p in args.only.split(",") if p.strip()}
        phases = [p for p in phases if p["phase_id"] in wanted]
        if not phases:
            print(f"ERROR: --only matched no phases ({sorted(wanted)})", file=sys.stderr)
            return 2
    if args.limit is not None:
        phases = phases[: max(0, args.limit)]

    if args.selftest:
        catalog = {"model_ids": [], "source": "selftest_embedded", "fetched_at": None, "count": 0}
        profile_source = "selftest_synthetic"
        client = None
    else:
        catalog = refresh_opencode_go_catalog(
            cache_dir, force=args.refresh, offline=args.offline, verbose=args.verbose
        )
        profile_source = "jev"
        key = os.environ.get("TYPESAFE_API_KEY")
        if not key:
            print("ERROR: TYPESAFE_API_KEY is not set. Set it or use --dry-run/--selftest.",
                  file=sys.stderr)
            return 3
        client = JevClient(key, verbose=args.verbose)

    records: list[dict[str, Any]] = []
    partial_path = cache_dir / "phase_routing.partial.json"
    for phase in phases:
        print(f"  profiling {phase['phase_id']} ...", end="", flush=True)
        try:
            if profile_source == "jev":
                profile = get_profile(phase, client, cache_dir, force=args.force_jev,
                                      verbose=args.verbose)
                answers = profile["answers"]
            else:
                answers = synthetic_profile(phase)
                profile = {"answers": answers, "_raw": None, "_cache": "n/a", "_model": "synthetic"}
            requirements = profile_to_requirements(answers)
            route = route_phase(requirements, catalog, cost_aversion=args.cost_aversion)
            native = native_thinking_for(
                MODEL_REGISTRY[route["primary"]["registry_key"]],
                route["thinking"]["level"],
                requirements,
            )
            route["thinking"]["native"] = native
            record = build_phase_record(phase, profile, requirements, route,
                                        profile_source=profile_source)
            records.append(record)
            print(f" -> {record['route']['surface']}/{record['route']['model']} "
                  f"({record['route']['thinking_level']})")
        except Exception as exc:  # noqa: BLE001 - never lose prior results
            failed = failed_phase_record(phase, str(exc), profile_source)
            records.append(failed)
            print(f" -> FAILED ({sanitize_text(str(exc))[:120]})")
        partial_path.write_text(
            json.dumps({"updated_at": now_iso(), "phases": records}, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )

    live_ids = set(catalog.get("model_ids") or [])
    unavailable_go = sorted(
        m["model_id"]
        for m in MODEL_REGISTRY.values()
        if m["surface"] == "opencode_go" and live_ids and m["model_id"] not in live_ids
    )

    dist = distribution_check(records)
    meta = {
        "generated_at": now_iso(),
        "script_version": SCRIPT_VERSION,
        "phases_file": str(phases_path),
        "phase_count": len(records),
        "first_phase": phases[0]["phase_index"] if phases else None,
        "last_phase": phases[-1]["phase_index"] if phases else None,
        "catalog_researched_at": CATALOG_RESEARCHED_AT,
        "catalog_fetched_at": catalog.get("fetched_at"),
        "catalog_source": catalog.get("source"),
        "catalog_count": catalog.get("count", len(catalog.get("model_ids") or [])),
        "catalog_url": OPENCODE_GO_MODELS_URL,
        "profile_source": profile_source,
        "jev_model": client.resolved_model if client is not None else None,
        "jev_schema_version": JEV_SCHEMA_VERSION,
        "cost_model_version": COST_MODEL_VERSION,
        "cost_aversion": args.cost_aversion,
        "registry_models": len(MODEL_REGISTRY),
        "unavailable_registry_models": unavailable_go,
        "distribution": dist,
        "phase_count_note": PHASE_COUNT_NOTE,
        "sources": SOURCES,
    }
    meta["distribution_explanation"] = distribution_explanation(records, dist)

    suffix = ".selftest" if args.selftest else ""
    json_path = write_json_output(out_dir, f"phase_routing{suffix}.json", records, meta)
    md_path = out_dir / f"PHASE_MODEL_ROUTING{suffix}.md"
    md_path.write_text(render_markdown(records, meta), encoding="utf-8")

    print("")
    print(f"Routed {dist['routed_phases']}/{len(records)} phases "
          f"({len(records) - dist['routed_phases']} failed).")
    for model_key, count in dist["counts"].items():
        print(f"  {model_key}: {count}")
    for warning in dist["warnings"]:
        print(f"  WARNING: {warning}")
    print(f"Wrote {json_path}")
    print(f"Wrote {md_path}")
    if suffix:
        print("These are SELFTEST outputs produced from synthetic profiles, not Jev.")
    return 0 if dist["routed_phases"] == len(records) else 4


def main(argv: Optional[list[str]] = None) -> int:
    args = parse_args(argv)
    try:
        return run(args)
    except KeyboardInterrupt:
        print("\nInterrupted. Cached profiles are preserved; re-run to continue.", file=sys.stderr)
        return 130


if __name__ == "__main__":
    raise SystemExit(main())










