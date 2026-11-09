# Phase Model Routing

Generated: 2026-09-27T13:51:56+00:00  
Phases file: `PHASES.md` (41 prompts, P00-P40)  
Catalog researched: 2026-09-27  
OpenCode Go catalog checked: 2026-09-27T13:19:10.875001+00:00 (cache_fresh, 43 models)  
Jev schema: taskprof-v2; profiles source: jev  
Cost model: cost-v1; cost aversion: medium  

> One primary model + thinking level per phase. The router uses Jev only for task understanding; model choice comes from the researched capability registry. Among models that clear the phase's capability bar, the cheapest is chosen; the bar tightens as execution risk rises. Confidence is an estimate, not a guarantee.

**Phase count note.** The brief expected approximately 40 prompts. This PHASES.md genuinely contains 41 actual prompts (P00-P40): P00 ('Milion identity and plan') is marked done in the file but is kept as a re-runnable audit prompt, so it counts and is routed. The parser asserts 41 rather than forcing 40; it fails loudly if the document changes structurally.

## Routing table

| Phase | Phase title | Surface | Model | Thinking | Cost | Confidence | Alternative |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P00 | Milion identity and plan | chatgpt_plus | `gpt-6-sol` | medium | 0.20 | 0.54 | opencode_go / DeepSeek V4 Pro (Go) |
| P01 | Clean slate | claude_team | `claude-opus-5-5` | very_high | 0.64 | 0.66 | chatgpt_plus / GPT-6 Sol |
| P02 | Content registry and mile-zero geography | chatgpt_plus | `gpt-6-astra` | very_high | 1.00 | 0.76 | opencode_go / DeepSeek V4 Pro (Go) |
| P03 | Design language "Porphyry & Tessera" | chatgpt_plus | `gpt-6-sol` | very_high | 0.20 | 0.62 | opencode_go / Qwen3.8 Max (Go) |
| P04 | Shell, Today and the first ten seconds | claude_team | `claude-opus-5-5` | very_high | 0.64 | 0.66 | chatgpt_plus / GPT-6 Sol |
| P05 | Place page: the dig | chatgpt_plus | `gpt-6-sol` | very_high | 0.20 | 0.60 | opencode_go / Qwen3.8 Max (Go) |
| P06 | Plate engine and remastered Milestones I–II | claude_team | `claude-opus-5-5` | very_high | 0.64 | 0.68 | chatgpt_plus / GPT-6 Sol |
| P07 | Plate production line and Chora Milestones III–V | claude_team | `claude-opus-5-5` | very_high | 0.64 | 0.66 | chatgpt_plus / GPT-6 Sol |
| P08 | 3D runtime and "How a dome stands" | chatgpt_plus | `gpt-6-sol` | very_high | 0.20 | 0.63 | opencode_go / Qwen3.8 Max (Go) |
| P09 | Procedural architecture kit | claude_team | `claude-opus-5-5` | very_high | 0.64 | 0.68 | chatgpt_plus / GPT-6 Sol |
| P10 | The Atlas | chatgpt_plus | `gpt-6-astra` | very_high | 1.00 | 0.76 | opencode_go / Qwen3.8 Max (Go) |
| P11 | Chora, complete | chatgpt_plus | `gpt-6-sol` | very_high | 0.20 | 0.62 | opencode_go / Qwen3.8 Max (Go) |
| P12 | Hagia Sophia | chatgpt_plus | `gpt-6-sol` | high | 0.20 | 0.64 | claude_team / Claude Opus 5.5 |
| P13 | Hippodrome, Great Palace and the Milion | claude_team | `claude-opus-5-5` | very_high | 0.64 | 0.65 | chatgpt_plus / GPT-6 Sol |
| P14 | Underground Constantinople | chatgpt_plus | `gpt-6-sol` | very_high | 0.20 | 0.62 | opencode_go / Qwen3.8 Max (Go) |
| P15 | The Walls and 1453 | claude_team | `claude-opus-5-5` | very_high | 0.64 | 0.69 | chatgpt_plus / GPT-6 Sol |
| P16 | Byzantine city beyond the core | chatgpt_plus | `gpt-6-sol` | high | 0.20 | 0.67 | opencode_go / DeepSeek V4 Pro (Go) |
| P17 | Share studio and deep links | claude_team | `claude-opus-5-5` | very_high | 0.64 | 0.67 | chatgpt_plus / GPT-6 Sol |
| P18 | Daily Tessera and On this day | chatgpt_plus | `gpt-6-sol` | very_high | 0.20 | 0.63 | opencode_go / DeepSeek V4 Pro (Go) |
| P19 | Personal mosaic and Milestone book | claude_team | `claude-opus-5-5` | very_high | 0.64 | 0.64 | chatgpt_plus / GPT-6 Sol |
| P20 | Ghost lens (then/now) | chatgpt_plus | `gpt-6-sol` | very_high | 0.20 | 0.63 | claude_team / Claude Opus 5.5 |
| P21 | Routes and hunts | chatgpt_plus | `gpt-6-sol` | very_high | 0.20 | 0.61 | opencode_go / Qwen3.8 Max (Go) |
| P22 | Voices: acoustics, soundscapes, narration | chatgpt_plus | `gpt-6-sol` | high | 0.20 | 0.65 | opencode_go / DeepSeek V4 Pro (Go) |
| P23 | Point and reveal (recognition v2) | chatgpt_plus | `gpt-6-astra` | very_high | 1.00 | 0.74 | opencode_go / DeepSeek V4 Flash Vision Exp (Go) |
| P24 | Mosque layer and craft kit | claude_team | `claude-opus-5-5` | very_high | 0.64 | 0.70 | chatgpt_plus / GPT-6 Sol |
| P25 | Süleymaniye | chatgpt_plus | `gpt-6-sol` | very_high | 0.20 | 0.60 | opencode_go / Qwen3.8 Max (Go) |
| P26 | Sinan's Istanbul | chatgpt_plus | `gpt-6-sol` | very_high | 0.20 | 0.62 | opencode_go / Qwen3.8 Max (Go) |
| P27 | Imperial to contemporary mosques, the dome's evolution, mahya | chatgpt_plus | `gpt-6-sol` | very_high | 0.20 | 0.63 | claude_team / Claude Opus 5.5 |
| P28 | Museum kit and the Istanbul Archaeology Museums | chatgpt_plus | `gpt-6-sol` | very_high | 0.20 | 0.60 | claude_team / Claude Opus 5.5 |
| P29 | Topkapı and the palaces | chatgpt_plus | `gpt-6-sol` | very_high | 0.20 | 0.58 | opencode_go / Qwen3.8 Max (Go) |
| P30 | Collections of the city | chatgpt_plus | `gpt-6-sol` | high | 0.20 | 0.60 | opencode_go / Qwen3.8 Max (Go) |
| P31 | Scattered: Istanbul abroad | chatgpt_plus | `gpt-6-sol` | high | 0.20 | 0.69 | opencode_go / Qwen3.8 Max (Go) |
| P32 | Every district has a layer | chatgpt_plus | `gpt-6-sol` | high | 0.20 | 0.60 | opencode_go / Qwen3.8 Max (Go) |
| P33 | Discovery at scale | chatgpt_plus | `gpt-6-astra` | very_high | 1.00 | 0.75 | opencode_go / DeepSeek V4 Pro (Go) |
| P34 | Turkish and English, complete | chatgpt_plus | `gpt-6-sol` | medium | 0.20 | 0.67 | opencode_go / DeepSeek V4 Pro (Go) |
| P35 | Accessibility and reduced-motion equivalence | claude_team | `claude-opus-5-5` | very_high | 0.64 | 0.61 | chatgpt_plus / GPT-6 Sol |
| P36 | Performance, size and asset delivery | claude_team | `claude-opus-5-5` | very_high | 0.64 | 0.70 | chatgpt_plus / GPT-6 Sol |
| P37 | Reliability, permissions and privacy | claude_team | `claude-opus-5-5` | very_high | 0.64 | 0.66 | chatgpt_plus / GPT-6 Sol |
| P38 | Test automation, CI and device matrix | chatgpt_plus | `gpt-6-sol` | high | 0.20 | 0.63 | opencode_go / DeepSeek V4 Pro (Go) |
| P39 | Field trial in Istanbul and polish | chatgpt_plus | `gpt-6-sol` | medium | 0.20 | 0.60 | opencode_go / DeepSeek V4 Pro (Go) |
| P40 | Store launch kit and release | chatgpt_plus | `gpt-6-astra` | high | 1.00 | 0.70 | opencode_go / DeepSeek V4 Flash Vision Exp (Go) |

## P00 - Milion identity and plan

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
medium
native setting: Codex reasoning effort: Medium
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.09, best-fit model `gpt-6-astra` at cost pressure 1.00; 4 candidate(s) cleared the bar.

Why:
Task reads as refactor migration with top needs repo wide reasoning (1.00), architecture (0.66), refactoring (0.50). GPT-6 Sol clears the phase's capability bar (9.15/10 vs threshold 9.09) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quota efficiency was allowed to matter.

Task profile:
- dominant task: refactor_migration (p=0.29)
- reasoning depth: 2.98/4
- repo context need: 3.69/4
- ambiguity: 2.07/4
- execution risk: 2.85/4
- visual reasoning need: 3.02/4
- test/verification need: 2.98/4
- cross-component need: 3.41/4
- profile confidence: 0.50; uncertainty: 0.50

Alternative:
opencode_go / `deepseek-v4-pro` (DeepSeek V4 Pro (Go)) - thinking medium (automatic (provider default))

Routing confidence: 0.54 (fit margin over bar +0.063, capability fit 9.15/10)

Top candidates:
- opencode_go / `deepseek-v4-pro`: fit 8.84, cost 0.08 ($0.66/$1.98), penalties 0.25/0.00, total 8.59 (ok)
- chatgpt_plus / `gpt-6-sol`: fit 9.15, cost 0.20 ($2.00/$10.00), penalties 0.64/0.00, total 8.51 (ok)
- opencode_go / `mimo-v2.6-pro`: fit 8.50, cost 0.04 ($0.43/$0.87), penalties 0.11/0.00, total 8.38 (ok)
- opencode_go / `glm-5.3`: fit 8.88, cost 0.18 ($1.40/$4.40), penalties 0.55/0.00, total 8.33 (ok)
- opencode_go / `qwen3.8-max`: fit 8.98, cost 0.24 ($2.00/$6.00), penalties 0.77/0.00, total 8.21 (ok)
- opencode_go / `deepseek-v4.1-flash`: fit 8.23, cost 0.02 ($0.15/$0.60), penalties 0.07/0.00, total 8.16 (ok)

Source: PHASES.md lines 220-233, hash `c49aecd72496`

## P01 - Clean slate

Primary:
claude_team / `claude-opus-5-5` (Claude Opus 5.5)

Thinking:
very_high
native setting: Claude Code /effort xhigh
Effort levels supported: low, medium, high, xhigh, max. Model default: medium.

Cost:
$4.00 in / $20.00 out per MTok (API list); effective cost pressure 0.64 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.34, best-fit model `gpt-6-astra` at cost pressure 1.00; 2 candidate(s) cleared the bar.

Why:
Task reads as refactor migration with top needs repo wide reasoning (1.00), architecture (0.80), precision (0.46). Claude Opus 5.5 clears the phase's capability bar (9.44/10 vs threshold 9.34) at effective cost pressure 0.64 ($4.00 in / $20.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: refactor_migration (p=0.98)
- implementation complexity: 3.19/4
- reasoning depth: 3.77/4
- repo context need: 3.85/4
- ambiguity: 2.42/4
- execution risk: 3.85/4
- test/verification need: 3.04/4
- cross-component need: 3.86/4
- long-context need: 2.88/4
- profile confidence: 0.70; uncertainty: 0.30

Alternative:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol) - thinking very_high (Codex reasoning effort: Extra High)

Routing confidence: 0.66 (fit margin over bar +0.106, capability fit 9.44/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.15, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 8.99 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.86, cost 0.08 ($0.66/$1.98), penalties 0.07/0.00, total 8.79 (ok)
- opencode_go / `qwen3.8-max`: fit 8.98, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.78 (ok)
- opencode_go / `glm-5.3`: fit 8.89, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.75 (ok)
- claude_team / `claude-opus-5-5`: fit 9.44, cost 0.64 ($4.00/$20.00), penalties 0.54/0.16, total 8.74 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.58, cost 1.00 ($10.00/$50.00), penalties 0.86/0.00, total 8.72 (ok)

Source: PHASES.md lines 239-257, hash `53e61d9d7d7d`

## P02 - Content registry and mile-zero geography

Primary:
chatgpt_plus / `gpt-6-astra` (GPT-6 Astra)

Thinking:
very_high
native setting: Codex reasoning effort: Max
Picker values: low, medium, high, xhigh, max. Light (low) is the recommended starting preset; Extra High may be omitted on some paid plans; Max appears only when enabled in settings.

Cost:
$10.00 in / $50.00 out per MTok (API list); effective cost pressure 1.00 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.32, best-fit model `gpt-6-astra` at cost pressure 1.00; 1 candidate(s) cleared the bar.

Why:
Task reads as architecture design with top needs architecture (1.00), repo wide reasoning (0.78), precision (0.54). GPT-6 Astra clears the phase's capability bar (9.60/10 vs threshold 9.32) at effective cost pressure 1.00 ($10.00 in / $50.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: architecture_design (p=0.80)
- implementation complexity: 3.76/4
- reasoning depth: 3.77/4
- architecture need: 3.93/4
- repo context need: 3.81/4
- ambiguity: 2.76/4
- execution risk: 3.79/4
- research need: 3.69/4
- test/verification need: 3.79/4
- cross-component need: 3.86/4
- long-context need: 3.44/4
- factual accuracy need: 3.98/4
- profile confidence: 0.78; uncertainty: 0.22

Alternative:
opencode_go / `deepseek-v4-pro` (DeepSeek V4 Pro (Go)) - thinking very_high (automatic (provider default))

Routing confidence: 0.76 (fit margin over bar +0.274, capability fit 9.60/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.16, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 8.99 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.85, cost 0.08 ($0.66/$1.98), penalties 0.07/0.00, total 8.78 (ok)
- opencode_go / `qwen3.8-max`: fit 8.98, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.78 (ok)
- opencode_go / `glm-5.3`: fit 8.89, cost 0.18 ($1.40/$4.40), penalties 0.15/0.00, total 8.75 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.60, cost 1.00 ($10.00/$50.00), penalties 0.89/0.00, total 8.71 (ok)
- opencode_go / `kimi-k3`: fit 9.10, cost 0.58 ($3.00/$15.00), penalties 0.49/0.00, total 8.61 (ok)

Source: PHASES.md lines 263-289, hash `9c394220885f`

## P03 - Design language "Porphyry & Tessera"

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
very_high
native setting: Codex reasoning effort: Extra High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.08, best-fit model `gpt-6-astra` at cost pressure 1.00; 3 candidate(s) cleared the bar.

Why:
Task reads as ui visual design with top needs visual reasoning (1.00), frontend ui (0.91), precision (0.66). GPT-6 Sol clears the phase's capability bar (9.13/10 vs threshold 9.08) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: ui_visual_design (p=0.82)
- implementation complexity: 3.64/4
- reasoning depth: 3.6/4
- architecture need: 2.51/4
- repo context need: 3.47/4
- ambiguity: 3.17/4
- execution risk: 3.08/4
- frontend/UI need: 3.63/4
- visual reasoning need: 3.98/4
- test/verification need: 3.26/4
- cross-component need: 3.69/4
- long-context need: 2.71/4
- profile confidence: 0.68; uncertainty: 0.32

Alternative:
opencode_go / `qwen3.8-max` (Qwen3.8 Max (Go)) - thinking very_high (automatic (provider default))

Routing confidence: 0.62 (fit margin over bar +0.049, capability fit 9.13/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.13, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 8.97 (ok)
- opencode_go / `qwen3.8-max`: fit 8.97, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.77 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.54, cost 1.00 ($10.00/$50.00), penalties 0.87/0.00, total 8.67 (ok)
- opencode_go / `glm-5.3`: fit 8.74, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.60 (ok)
- claude_team / `claude-opus-5-5`: fit 9.24, cost 0.64 ($4.00/$20.00), penalties 0.54/0.15, total 8.55 (ok)
- opencode_go / `kimi-k3`: fit 9.02, cost 0.58 ($3.00/$15.00), penalties 0.48/0.00, total 8.54 (ok)

Source: PHASES.md lines 295-329, hash `ef0766c814ff`

## P04 - Shell, Today and the first ten seconds

Primary:
claude_team / `claude-opus-5-5` (Claude Opus 5.5)

Thinking:
very_high
native setting: Claude Code /effort xhigh
Effort levels supported: low, medium, high, xhigh, max. Model default: medium.

Cost:
$4.00 in / $20.00 out per MTok (API list); effective cost pressure 0.64 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.23, best-fit model `gpt-6-astra` at cost pressure 1.00; 2 candidate(s) cleared the bar.

Why:
Task reads as implementation feature with top needs repo wide reasoning (1.00), architecture (0.71), direct implementation (0.70). Claude Opus 5.5 clears the phase's capability bar (9.43/10 vs threshold 9.23) at effective cost pressure 0.64 ($4.00 in / $20.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: implementation_feature (p=0.95)
- implementation complexity: 3.49/4
- reasoning depth: 3.55/4
- architecture need: 3.05/4
- repo context need: 3.66/4
- debugging need: 3.03/4
- ambiguity: 3.05/4
- execution risk: 3.39/4
- frontend/UI need: 3.98/4
- visual reasoning need: 3.64/4
- test/verification need: 2.87/4
- cross-component need: 3.84/4
- factual accuracy need: 3.05/4
- profile confidence: 0.63; uncertainty: 0.37

Alternative:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol) - thinking very_high (Codex reasoning effort: Extra High)

Routing confidence: 0.66 (fit margin over bar +0.199, capability fit 9.43/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.16, cost 0.20 ($2.00/$10.00), penalties 0.16/0.00, total 9.00 (ok)
- opencode_go / `qwen3.8-max`: fit 9.01, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.81 (ok)
- claude_team / `claude-opus-5-5`: fit 9.43, cost 0.64 ($4.00/$20.00), penalties 0.54/0.12, total 8.77 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.81, cost 0.08 ($0.66/$1.98), penalties 0.06/0.00, total 8.75 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.60, cost 1.00 ($10.00/$50.00), penalties 0.85/0.00, total 8.74 (ok)
- opencode_go / `glm-5.3`: fit 8.87, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.73 (ok)

Source: PHASES.md lines 335-366, hash `496366b0d96f`

## P05 - Place page: the dig

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
very_high
native setting: Codex reasoning effort: Extra High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.16, best-fit model `gpt-6-astra` at cost pressure 1.00; 3 candidate(s) cleared the bar.

Why:
Task reads as implementation feature with top needs repo wide reasoning (1.00), direct implementation (0.76), architecture (0.72). GPT-6 Sol clears the phase's capability bar (9.17/10 vs threshold 9.16) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: implementation_feature (p=1.00)
- implementation complexity: 3.36/4
- reasoning depth: 3.35/4
- architecture need: 3.05/4
- repo context need: 3.53/4
- ambiguity: 3.04/4
- execution risk: 3.15/4
- research need: 3.41/4
- frontend/UI need: 3.9/4
- visual reasoning need: 2.63/4
- cross-component need: 3.76/4
- long-context need: 2.62/4
- factual accuracy need: 3.99/4
- profile confidence: 0.68; uncertainty: 0.32

Alternative:
opencode_go / `qwen3.8-max` (Qwen3.8 Max (Go)) - thinking very_high (automatic (provider default))

Routing confidence: 0.60 (fit margin over bar +0.008, capability fit 9.17/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.17, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 9.00 (ok)
- opencode_go / `qwen3.8-max`: fit 9.00, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.80 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.81, cost 0.08 ($0.66/$1.98), penalties 0.07/0.00, total 8.75 (ok)
- opencode_go / `glm-5.3`: fit 8.88, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.73 (ok)
- claude_team / `claude-opus-5-5`: fit 9.42, cost 0.64 ($4.00/$20.00), penalties 0.55/0.15, total 8.72 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.59, cost 1.00 ($10.00/$50.00), penalties 0.88/0.00, total 8.72 (ok)

Source: PHASES.md lines 372-404, hash `4d4363540012`

## P06 - Plate engine and remastered Milestones I–II

Primary:
claude_team / `claude-opus-5-5` (Claude Opus 5.5)

Thinking:
very_high
native setting: Claude Code /effort xhigh
Effort levels supported: low, medium, high, xhigh, max. Model default: medium.

Cost:
$4.00 in / $20.00 out per MTok (API list); effective cost pressure 0.64 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.18, best-fit model `gpt-6-astra` at cost pressure 1.00; 2 candidate(s) cleared the bar.

Why:
Task reads as graphics 3d engineering with top needs deep debugging (1.00), graphics 3d (0.86), architecture (0.79). Claude Opus 5.5 clears the phase's capability bar (9.29/10 vs threshold 9.18) at effective cost pressure 0.64 ($4.00 in / $20.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: graphics_3d_engineering (p=0.99)
- implementation complexity: 3.63/4
- reasoning depth: 3.78/4
- architecture need: 3.73/4
- repo context need: 3.86/4
- debugging need: 3.05/4
- ambiguity: 2.93/4
- execution risk: 3.5/4
- frontend/UI need: 3.33/4
- visual reasoning need: 3.58/4
- 3D/graphics need: 3.99/4
- test/verification need: 3.22/4
- cross-component need: 3.91/4
- long-context need: 2.61/4
- profile confidence: 0.72; uncertainty: 0.28

Alternative:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol) - thinking very_high (Codex reasoning effort: Extra High)

Routing confidence: 0.68 (fit margin over bar +0.107, capability fit 9.29/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.12, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 8.96 (ok)
- opencode_go / `qwen3.8-max`: fit 9.02, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.82 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.53, cost 1.00 ($10.00/$50.00), penalties 0.87/0.00, total 8.66 (ok)
- claude_team / `claude-opus-5-5`: fit 9.29, cost 0.64 ($4.00/$20.00), penalties 0.54/0.15, total 8.60 (ok)
- opencode_go / `glm-5.3`: fit 8.74, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.60 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.60, cost 0.08 ($0.66/$1.98), penalties 0.06/0.00, total 8.54 (ok)

Source: PHASES.md lines 410-444, hash `5b77b0208e61`

## P07 - Plate production line and Chora Milestones III–V

Primary:
claude_team / `claude-opus-5-5` (Claude Opus 5.5)

Thinking:
very_high
native setting: Claude Code /effort xhigh
Effort levels supported: low, medium, high, xhigh, max. Model default: medium.

Cost:
$4.00 in / $20.00 out per MTok (API list); effective cost pressure 0.64 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.23, best-fit model `gpt-6-astra` at cost pressure 1.00; 2 candidate(s) cleared the bar.

Why:
Task reads as data pipeline tooling with top needs architecture (1.00), repo wide reasoning (0.95), data pipeline (0.79). Claude Opus 5.5 clears the phase's capability bar (9.26/10 vs threshold 9.23) at effective cost pressure 0.64 ($4.00 in / $20.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: data_pipeline_tooling (p=1.00)
- implementation complexity: 3.85/4
- reasoning depth: 3.93/4
- architecture need: 3.34/4
- repo context need: 3.9/4
- debugging need: 3.11/4
- ambiguity: 3.15/4
- execution risk: 3.69/4
- research need: 2.71/4
- visual reasoning need: 3.23/4
- 3D/graphics need: 3.08/4
- ml/cv need: 3.84/4
- test/verification need: 3.42/4
- cross-component need: 3.96/4
- long-context need: 2.82/4
- factual accuracy need: 3.26/4
- profile confidence: 0.76; uncertainty: 0.24

Alternative:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol) - thinking very_high (Codex reasoning effort: Max)

Routing confidence: 0.66 (fit margin over bar +0.029, capability fit 9.26/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.13, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 8.97 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.53, cost 1.00 ($10.00/$50.00), penalties 0.88/0.00, total 8.65 (ok)
- claude_team / `claude-opus-5-5`: fit 9.26, cost 0.64 ($4.00/$20.00), penalties 0.55/0.16, total 8.55 (ok)
- chatgpt_plus / `gpt-5.6-sol`: fit 8.81, cost 0.40 ($4.00/$20.00), penalties 0.33/0.11, total 8.37 (ok)
- claude_team / `claude-sonnet-5`: fit 8.20, cost 0.32 ($2.00/$10.00), penalties 0.24/0.16, total 7.80 (ok)
- opencode_go / `deepseek-v4-flash-vision-exp`: fit 7.77, cost 0.02 ($0.15/$0.60), penalties 0.02/0.00, total 7.75 (ok)

Source: PHASES.md lines 450-474, hash `3d9cedc35e5a`

## P08 - 3D runtime and "How a dome stands"

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
very_high
native setting: Codex reasoning effort: Extra High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.12, best-fit model `gpt-6-astra` at cost pressure 1.00; 3 candidate(s) cleared the bar.

Why:
Task reads as graphics 3d engineering with top needs deep debugging (1.00), graphics 3d (0.88), architecture (0.71). GPT-6 Sol clears the phase's capability bar (9.13/10 vs threshold 9.12) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: graphics_3d_engineering (p=1.00)
- implementation complexity: 3.64/4
- reasoning depth: 3.84/4
- architecture need: 3.16/4
- repo context need: 3.44/4
- debugging need: 3.4/4
- ambiguity: 2.81/4
- execution risk: 3.27/4
- research need: 2.79/4
- frontend/UI need: 3.02/4
- visual reasoning need: 3.21/4
- 3D/graphics need: 3.99/4
- test/verification need: 2.64/4
- cross-component need: 3.74/4
- profile confidence: 0.74; uncertainty: 0.26

Alternative:
opencode_go / `qwen3.8-max` (Qwen3.8 Max (Go)) - thinking very_high (automatic (provider default))

Routing confidence: 0.63 (fit margin over bar +0.009, capability fit 9.13/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.13, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 8.96 (ok)
- opencode_go / `qwen3.8-max`: fit 9.01, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.81 (ok)
- claude_team / `claude-opus-5-5`: fit 9.29, cost 0.64 ($4.00/$20.00), penalties 0.55/0.00, total 8.74 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.53, cost 1.00 ($10.00/$50.00), penalties 0.88/0.00, total 8.65 (ok)
- opencode_go / `glm-5.3`: fit 8.73, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.59 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.59, cost 0.08 ($0.66/$1.98), penalties 0.06/0.00, total 8.53 (ok)

Source: PHASES.md lines 480-504, hash `26fee92413f3`

## P09 - Procedural architecture kit

Primary:
claude_team / `claude-opus-5-5` (Claude Opus 5.5)

Thinking:
very_high
native setting: Claude Code /effort xhigh
Effort levels supported: low, medium, high, xhigh, max. Model default: medium.

Cost:
$4.00 in / $20.00 out per MTok (API list); effective cost pressure 0.64 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.19, best-fit model `gpt-6-astra` at cost pressure 1.00; 2 candidate(s) cleared the bar.

Why:
Task reads as data pipeline tooling with top needs architecture (1.00), repo wide reasoning (0.81), data pipeline (0.70). Claude Opus 5.5 clears the phase's capability bar (9.35/10 vs threshold 9.19) at effective cost pressure 0.64 ($4.00 in / $20.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: data_pipeline_tooling (p=0.98)
- implementation complexity: 3.73/4
- reasoning depth: 3.88/4
- architecture need: 3.69/4
- repo context need: 3.46/4
- ambiguity: 3.01/4
- execution risk: 3.47/4
- research need: 3.43/4
- test/verification need: 3.09/4
- cross-component need: 3.8/4
- factual accuracy need: 3.86/4
- profile confidence: 0.69; uncertainty: 0.30

Alternative:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol) - thinking very_high (Codex reasoning effort: Extra High)

Routing confidence: 0.68 (fit margin over bar +0.163, capability fit 9.35/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.16, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 9.00 (ok)
- claude_team / `claude-opus-5-5`: fit 9.35, cost 0.64 ($4.00/$20.00), penalties 0.54/0.00, total 8.81 (ok)
- opencode_go / `qwen3.8-max`: fit 8.89, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.70 (ok)
- opencode_go / `glm-5.3`: fit 8.83, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.69 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.54, cost 1.00 ($10.00/$50.00), penalties 0.86/0.00, total 8.67 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.72, cost 0.08 ($0.66/$1.98), penalties 0.06/0.00, total 8.66 (ok)

Source: PHASES.md lines 510-536, hash `b418af76f2d1`

## P10 - The Atlas

Primary:
chatgpt_plus / `gpt-6-astra` (GPT-6 Astra)

Thinking:
very_high
native setting: Codex reasoning effort: Extra High
Picker values: low, medium, high, xhigh, max. Light (low) is the recommended starting preset; Extra High may be omitted on some paid plans; Max appears only when enabled in settings.

Cost:
$10.00 in / $50.00 out per MTok (API list); effective cost pressure 1.00 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.21, best-fit model `gpt-6-astra` at cost pressure 1.00; 1 candidate(s) cleared the bar.

Why:
Task reads as map geodata with top needs architecture (1.00), repo wide reasoning (0.84), frontend ui (0.83). GPT-6 Astra clears the phase's capability bar (9.54/10 vs threshold 9.21) at effective cost pressure 1.00 ($10.00 in / $50.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: map_geodata (p=1.00)
- implementation complexity: 3.69/4
- reasoning depth: 3.81/4
- architecture need: 3.53/4
- repo context need: 3.44/4
- debugging need: 3.13/4
- ambiguity: 3.04/4
- execution risk: 3.57/4
- research need: 3.46/4
- frontend/UI need: 3.78/4
- visual reasoning need: 3.64/4
- 3D/graphics need: 2.6/4
- test/verification need: 2.99/4
- cross-component need: 3.91/4
- long-context need: 3.1/4
- factual accuracy need: 3.8/4
- profile confidence: 0.75; uncertainty: 0.25

Alternative:
opencode_go / `qwen3.8-max` (Qwen3.8 Max (Go)) - thinking very_high (automatic (provider default))

Routing confidence: 0.76 (fit margin over bar +0.330, capability fit 9.54/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.17, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 9.00 (ok)
- opencode_go / `qwen3.8-max`: fit 8.94, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.74 (ok)
- opencode_go / `glm-5.3`: fit 8.81, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.67 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.54, cost 1.00 ($10.00/$50.00), penalties 0.88/0.00, total 8.66 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.66, cost 0.08 ($0.66/$1.98), penalties 0.07/0.00, total 8.59 (ok)
- opencode_go / `kimi-k3`: fit 9.02, cost 0.58 ($3.00/$15.00), penalties 0.48/0.00, total 8.54 (ok)

Source: PHASES.md lines 542-571, hash `82ec8930af5d`

## P11 - Chora, complete

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
very_high
native setting: Codex reasoning effort: Extra High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.13, best-fit model `gpt-6-astra` at cost pressure 1.00; 2 candidate(s) cleared the bar.

Why:
Task reads as content research with top needs precision (1.00), research (0.98), long context (0.78). GPT-6 Sol clears the phase's capability bar (9.17/10 vs threshold 9.13) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: content_research (p=0.82)
- implementation complexity: 3.79/4
- reasoning depth: 3.81/4
- architecture need: 3/4
- repo context need: 3.78/4
- ambiguity: 3.44/4
- execution risk: 3.32/4
- research need: 3.86/4
- frontend/UI need: 3.23/4
- visual reasoning need: 3.58/4
- cross-component need: 3.9/4
- long-context need: 3.89/4
- factual accuracy need: 3.98/4
- profile confidence: 0.70; uncertainty: 0.30

Alternative:
opencode_go / `qwen3.8-max` (Qwen3.8 Max (Go)) - thinking very_high (automatic (provider default))

Routing confidence: 0.62 (fit margin over bar +0.035, capability fit 9.17/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.17, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 9.00 (ok)
- opencode_go / `qwen3.8-max`: fit 8.90, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.70 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.52, cost 1.00 ($10.00/$50.00), penalties 0.87/0.00, total 8.66 (ok)
- opencode_go / `glm-5.3`: fit 8.78, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.64 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.65, cost 0.08 ($0.66/$1.98), penalties 0.06/0.00, total 8.59 (ok)
- opencode_go / `kimi-k3`: fit 9.02, cost 0.58 ($3.00/$15.00), penalties 0.48/0.00, total 8.54 (ok)

Source: PHASES.md lines 577-597, hash `b9cf6ea44ad7`

## P12 - Hagia Sophia

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
high
native setting: Codex reasoning effort: High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.05, best-fit model `gpt-6-astra` at cost pressure 1.00; 3 candidate(s) cleared the bar.

Why:
Task reads as content research with top needs research (1.00), precision (0.95), long context (0.65). GPT-6 Sol clears the phase's capability bar (9.19/10 vs threshold 9.05) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: content_research (p=0.97)
- implementation complexity: 3.05/4
- reasoning depth: 3.57/4
- repo context need: 3.37/4
- ambiguity: 2.96/4
- execution risk: 3.01/4
- research need: 3.98/4
- frontend/UI need: 2.65/4
- visual reasoning need: 3.61/4
- cross-component need: 3.7/4
- long-context need: 2.91/4
- factual accuracy need: 4/4
- profile confidence: 0.64; uncertainty: 0.36

Alternative:
claude_team / `claude-opus-5-5` (Claude Opus 5.5) - thinking high (Claude Code /effort high)

Routing confidence: 0.64 (fit margin over bar +0.138, capability fit 9.19/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.19, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 9.03 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.52, cost 1.00 ($10.00/$50.00), penalties 0.86/0.00, total 8.66 (ok)
- claude_team / `claude-opus-5-5`: fit 9.08, cost 0.64 ($4.00/$20.00), penalties 0.53/0.16, total 8.39 (ok)
- chatgpt_plus / `gpt-5.6-sol`: fit 8.72, cost 0.40 ($4.00/$20.00), penalties 0.32/0.12, total 8.29 (ok)
- opencode_go / `deepseek-v4-flash-vision-exp`: fit 7.84, cost 0.02 ($0.15/$0.60), penalties 0.02/0.00, total 7.82 (ok)
- claude_team / `claude-sonnet-5`: fit 8.21, cost 0.32 ($2.00/$10.00), penalties 0.24/0.16, total 7.81 (ok)

Source: PHASES.md lines 603-626, hash `4ace12ff4569`

## P13 - Hippodrome, Great Palace and the Milion

Primary:
claude_team / `claude-opus-5-5` (Claude Opus 5.5)

Thinking:
very_high
native setting: Claude Code /effort xhigh
Effort levels supported: low, medium, high, xhigh, max. Model default: medium.

Cost:
$4.00 in / $20.00 out per MTok (API list); effective cost pressure 0.64 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.13, best-fit model `gpt-6-astra` at cost pressure 1.00; 2 candidate(s) cleared the bar.

Why:
Task reads as graphics 3d engineering with top needs deep debugging (1.00), graphics 3d (0.88), visual reasoning (0.82). Claude Opus 5.5 clears the phase's capability bar (9.26/10 vs threshold 9.13) at effective cost pressure 0.64 ($4.00 in / $20.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: graphics_3d_engineering (p=0.87)
- implementation complexity: 3.64/4
- reasoning depth: 3.68/4
- architecture need: 2.65/4
- repo context need: 3.65/4
- debugging need: 2.61/4
- ambiguity: 3.35/4
- execution risk: 3.27/4
- research need: 3.73/4
- visual reasoning need: 3.83/4
- 3D/graphics need: 3.74/4
- cross-component need: 3.87/4
- long-context need: 2.93/4
- factual accuracy need: 3.92/4
- profile confidence: 0.65; uncertainty: 0.35

Alternative:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol) - thinking very_high (Codex reasoning effort: Extra High)

Routing confidence: 0.65 (fit margin over bar +0.136, capability fit 9.26/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.13, cost 0.20 ($2.00/$10.00), penalties 0.16/0.00, total 8.96 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.52, cost 1.00 ($10.00/$50.00), penalties 0.86/0.00, total 8.67 (ok)
- claude_team / `claude-opus-5-5`: fit 9.26, cost 0.64 ($4.00/$20.00), penalties 0.53/0.17, total 8.56 (ok)
- chatgpt_plus / `gpt-5.6-sol`: fit 8.78, cost 0.40 ($4.00/$20.00), penalties 0.32/0.12, total 8.34 (ok)
- opencode_go / `deepseek-v4-flash-vision-exp`: fit 7.76, cost 0.02 ($0.15/$0.60), penalties 0.02/0.00, total 7.74 (ok)
- claude_team / `claude-sonnet-5`: fit 8.11, cost 0.32 ($2.00/$10.00), penalties 0.23/0.17, total 7.71 (ok)

Source: PHASES.md lines 632-655, hash `7beca6faf416`

## P14 - Underground Constantinople

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
very_high
native setting: Codex reasoning effort: Extra High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.12, best-fit model `gpt-6-astra` at cost pressure 1.00; 3 candidate(s) cleared the bar.

Why:
Task reads as graphics 3d engineering with top needs deep debugging (1.00), graphics 3d (0.88), visual reasoning (0.75). GPT-6 Sol clears the phase's capability bar (9.13/10 vs threshold 9.12) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: graphics_3d_engineering (p=0.98)
- implementation complexity: 3.67/4
- reasoning depth: 3.6/4
- architecture need: 2.76/4
- repo context need: 3.66/4
- debugging need: 2.94/4
- ambiguity: 3.19/4
- execution risk: 3.27/4
- research need: 2.99/4
- frontend/UI need: 3.24/4
- visual reasoning need: 3.79/4
- 3D/graphics need: 3.94/4
- cross-component need: 3.85/4
- long-context need: 2.76/4
- factual accuracy need: 3.51/4
- profile confidence: 0.71; uncertainty: 0.29

Alternative:
opencode_go / `qwen3.8-max` (Qwen3.8 Max (Go)) - thinking very_high (automatic (provider default))

Routing confidence: 0.62 (fit margin over bar +0.008, capability fit 9.13/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.13, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 8.96 (ok)
- opencode_go / `qwen3.8-max`: fit 9.01, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.81 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.53, cost 1.00 ($10.00/$50.00), penalties 0.87/0.00, total 8.65 (ok)
- opencode_go / `glm-5.3`: fit 8.73, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.59 (ok)
- claude_team / `claude-opus-5-5`: fit 9.27, cost 0.64 ($4.00/$20.00), penalties 0.54/0.15, total 8.57 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.59, cost 0.08 ($0.66/$1.98), penalties 0.06/0.00, total 8.52 (ok)

Source: PHASES.md lines 661-680, hash `bcf7c2484db1`

## P15 - The Walls and 1453

Primary:
claude_team / `claude-opus-5-5` (Claude Opus 5.5)

Thinking:
very_high
native setting: Claude Code /effort xhigh
Effort levels supported: low, medium, high, xhigh, max. Model default: medium.

Cost:
$4.00 in / $20.00 out per MTok (API list); effective cost pressure 0.64 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.20, best-fit model `gpt-6-astra` at cost pressure 1.00; 2 candidate(s) cleared the bar.

Why:
Task reads as implementation feature with top needs repo wide reasoning (1.00), architecture (0.73), direct implementation (0.72). Claude Opus 5.5 clears the phase's capability bar (9.42/10 vs threshold 9.20) at effective cost pressure 0.64 ($4.00 in / $20.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: implementation_feature (p=0.76)
- implementation complexity: 3.61/4
- reasoning depth: 3.59/4
- architecture need: 3.1/4
- repo context need: 3.6/4
- ambiguity: 3.17/4
- execution risk: 3.31/4
- research need: 3.63/4
- frontend/UI need: 3.53/4
- visual reasoning need: 3.53/4
- 3D/graphics need: 2.72/4
- cross-component need: 3.88/4
- long-context need: 2.71/4
- factual accuracy need: 3.96/4
- profile confidence: 0.67; uncertainty: 0.33

Alternative:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol) - thinking very_high (Codex reasoning effort: Extra High)

Routing confidence: 0.69 (fit margin over bar +0.214, capability fit 9.42/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.16, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 9.00 (ok)
- opencode_go / `qwen3.8-max`: fit 9.00, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.80 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.81, cost 0.08 ($0.66/$1.98), penalties 0.06/0.00, total 8.74 (ok)
- opencode_go / `glm-5.3`: fit 8.87, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.73 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.59, cost 1.00 ($10.00/$50.00), penalties 0.87/0.00, total 8.72 (ok)
- claude_team / `claude-opus-5-5`: fit 9.42, cost 0.64 ($4.00/$20.00), penalties 0.55/0.15, total 8.72 (ok)

Source: PHASES.md lines 686-705, hash `e99d6bcaa994`

## P16 - Byzantine city beyond the core

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
high
native setting: Codex reasoning effort: High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 8.90, best-fit model `gpt-6-astra` at cost pressure 1.00; 3 candidate(s) cleared the bar.

Why:
Task reads as content research with top needs research (1.00), precision (0.88), long context (0.67). GPT-6 Sol clears the phase's capability bar (9.20/10 vs threshold 8.90) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and a balanced capability/cost weighting was used. The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: content_research (p=0.98)
- implementation complexity: 2.85/4
- reasoning depth: 3.35/4
- repo context need: 3.38/4
- ambiguity: 2.98/4
- execution risk: 2.43/4
- research need: 3.9/4
- cross-component need: 3.38/4
- long-context need: 3.27/4
- factual accuracy need: 3.96/4
- profile confidence: 0.58; uncertainty: 0.42

Alternative:
opencode_go / `deepseek-v4-pro` (DeepSeek V4 Pro (Go)) - thinking high (automatic (provider default))

Routing confidence: 0.67 (fit margin over bar +0.295, capability fit 9.20/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.20, cost 0.20 ($2.00/$10.00), penalties 0.30/0.00, total 8.90 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.65, cost 0.08 ($0.66/$1.98), penalties 0.12/0.00, total 8.54 (ok)
- opencode_go / `glm-5.3`: fit 8.78, cost 0.18 ($1.40/$4.40), penalties 0.26/0.00, total 8.53 (ok)
- opencode_go / `qwen3.8-max`: fit 8.88, cost 0.24 ($2.00/$6.00), penalties 0.35/0.00, total 8.52 (ok)
- opencode_go / `mimo-v2.6-pro`: fit 8.37, cost 0.04 ($0.43/$0.87), penalties 0.05/0.00, total 8.32 (ok)
- opencode_go / `deepseek-v4.1-flash`: fit 8.23, cost 0.02 ($0.15/$0.60), penalties 0.03/0.00, total 8.20 (ok)

Source: PHASES.md lines 711-731, hash `8c7a030b1d9c`

## P17 - Share studio and deep links

Primary:
claude_team / `claude-opus-5-5` (Claude Opus 5.5)

Thinking:
very_high
native setting: Claude Code /effort xhigh
Effort levels supported: low, medium, high, xhigh, max. Model default: medium.

Cost:
$4.00 in / $20.00 out per MTok (API list); effective cost pressure 0.64 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.20, best-fit model `gpt-6-astra` at cost pressure 1.00; 2 candidate(s) cleared the bar.

Why:
Task reads as platform integration with top needs repo wide reasoning (1.00), deep debugging (0.66), architecture (0.62). Claude Opus 5.5 clears the phase's capability bar (9.46/10 vs threshold 9.20) at effective cost pressure 0.64 ($4.00 in / $20.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: platform_integration (p=0.55)
- implementation complexity: 3.52/4
- reasoning depth: 3.43/4
- architecture need: 3.19/4
- repo context need: 3.63/4
- debugging need: 2.87/4
- ambiguity: 2.9/4
- execution risk: 3.23/4
- test/verification need: 2.74/4
- cross-component need: 3.83/4
- factual accuracy need: 2.79/4
- profile confidence: 0.60; uncertainty: 0.40

Alternative:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol) - thinking very_high (Codex reasoning effort: Extra High)

Routing confidence: 0.67 (fit margin over bar +0.267, capability fit 9.46/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.16, cost 0.20 ($2.00/$10.00), penalties 0.16/0.00, total 8.99 (ok)
- claude_team / `claude-opus-5-5`: fit 9.46, cost 0.64 ($4.00/$20.00), penalties 0.54/0.00, total 8.92 (ok)
- opencode_go / `qwen3.8-max`: fit 9.00, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.80 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.84, cost 0.08 ($0.66/$1.98), penalties 0.06/0.00, total 8.77 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.60, cost 1.00 ($10.00/$50.00), penalties 0.85/0.00, total 8.74 (ok)
- opencode_go / `glm-5.3`: fit 8.88, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.74 (ok)

Source: PHASES.md lines 737-761, hash `cdce4d9df239`

## P18 - Daily Tessera and On this day

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
very_high
native setting: Codex reasoning effort: Extra High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.10, best-fit model `gpt-6-astra` at cost pressure 1.00; 3 candidate(s) cleared the bar.

Why:
Task reads as implementation feature with top needs repo wide reasoning (1.00), direct implementation (0.78), architecture (0.71). GPT-6 Sol clears the phase's capability bar (9.16/10 vs threshold 9.10) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and a balanced capability/cost weighting was used. The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: implementation_feature (p=1.00)
- implementation complexity: 3.2/4
- reasoning depth: 3.39/4
- architecture need: 2.96/4
- repo context need: 3.4/4
- ambiguity: 2.96/4
- execution risk: 2.96/4
- research need: 3.52/4
- frontend/UI need: 3.22/4
- visual reasoning need: 2.61/4
- test/verification need: 3.1/4
- cross-component need: 3.63/4
- long-context need: 2.58/4
- factual accuracy need: 3.96/4
- profile confidence: 0.68; uncertainty: 0.32

Alternative:
opencode_go / `deepseek-v4-pro` (DeepSeek V4 Pro (Go)) - thinking very_high (automatic (provider default))

Routing confidence: 0.63 (fit margin over bar +0.061, capability fit 9.16/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.16, cost 0.20 ($2.00/$10.00), penalties 0.30/0.00, total 8.86 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.82, cost 0.08 ($0.66/$1.98), penalties 0.12/0.00, total 8.70 (ok)
- opencode_go / `qwen3.8-max`: fit 8.99, cost 0.24 ($2.00/$6.00), penalties 0.36/0.00, total 8.63 (ok)
- opencode_go / `glm-5.3`: fit 8.88, cost 0.18 ($1.40/$4.40), penalties 0.26/0.00, total 8.62 (ok)
- opencode_go / `mimo-v2.6-pro`: fit 8.50, cost 0.04 ($0.43/$0.87), penalties 0.05/0.00, total 8.45 (ok)
- claude_team / `claude-opus-5-5`: fit 9.42, cost 0.64 ($4.00/$20.00), penalties 0.99/0.14, total 8.28 (ok)

Source: PHASES.md lines 767-786, hash `8713410ff367`

## P19 - Personal mosaic and Milestone book

Primary:
claude_team / `claude-opus-5-5` (Claude Opus 5.5)

Thinking:
very_high
native setting: Claude Code /effort xhigh
Effort levels supported: low, medium, high, xhigh, max. Model default: medium.

Cost:
$4.00 in / $20.00 out per MTok (API list); effective cost pressure 0.64 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.28, best-fit model `gpt-6-astra` at cost pressure 1.00; 2 candidate(s) cleared the bar.

Why:
Task reads as implementation feature with top needs repo wide reasoning (1.00), architecture (0.73), direct implementation (0.69). Claude Opus 5.5 clears the phase's capability bar (9.44/10 vs threshold 9.28) at effective cost pressure 0.64 ($4.00 in / $20.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: implementation_feature (p=0.98)
- implementation complexity: 3.56/4
- reasoning depth: 3.56/4
- architecture need: 3.48/4
- repo context need: 3.64/4
- debugging need: 2.86/4
- ambiguity: 3.13/4
- execution risk: 3.54/4
- frontend/UI need: 3.35/4
- visual reasoning need: 2.54/4
- 3D/graphics need: 3.21/4
- test/verification need: 3.26/4
- cross-component need: 3.82/4
- profile confidence: 0.61; uncertainty: 0.39

Alternative:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol) - thinking very_high (Codex reasoning effort: Extra High)

Routing confidence: 0.64 (fit margin over bar +0.167, capability fit 9.44/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.16, cost 0.20 ($2.00/$10.00), penalties 0.16/0.00, total 9.00 (ok)
- claude_team / `claude-opus-5-5`: fit 9.44, cost 0.64 ($4.00/$20.00), penalties 0.53/0.00, total 8.91 (ok)
- opencode_go / `qwen3.8-max`: fit 9.01, cost 0.24 ($2.00/$6.00), penalties 0.19/0.00, total 8.81 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.82, cost 0.08 ($0.66/$1.98), penalties 0.06/0.00, total 8.76 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.60, cost 1.00 ($10.00/$50.00), penalties 0.84/0.00, total 8.75 (ok)
- opencode_go / `glm-5.3`: fit 8.88, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.74 (ok)

Source: PHASES.md lines 792-811, hash `3d1aef13d971`

## P20 - Ghost lens (then/now)

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
very_high
native setting: Codex reasoning effort: Extra High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.11, best-fit model `gpt-6-astra` at cost pressure 1.00; 3 candidate(s) cleared the bar.

Why:
Task reads as implementation feature with top needs repo wide reasoning (1.00), direct implementation (0.75), architecture (0.69). GPT-6 Sol clears the phase's capability bar (9.14/10 vs threshold 9.11) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: implementation_feature (p=0.97)
- implementation complexity: 3.44/4
- reasoning depth: 3.33/4
- architecture need: 2.81/4
- repo context need: 3.61/4
- debugging need: 2.8/4
- ambiguity: 3.01/4
- execution risk: 3.09/4
- research need: 3.64/4
- frontend/UI need: 3.74/4
- visual reasoning need: 3.54/4
- cross-component need: 3.72/4
- long-context need: 2.78/4
- factual accuracy need: 3.85/4
- profile confidence: 0.70; uncertainty: 0.30

Alternative:
claude_team / `claude-opus-5-5` (Claude Opus 5.5) - thinking high (Claude Code /effort high)

Routing confidence: 0.63 (fit margin over bar +0.028, capability fit 9.14/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.14, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 8.97 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.56, cost 1.00 ($10.00/$50.00), penalties 0.88/0.00, total 8.69 (ok)
- claude_team / `claude-opus-5-5`: fit 9.28, cost 0.64 ($4.00/$20.00), penalties 0.55/0.16, total 8.58 (ok)
- chatgpt_plus / `gpt-5.6-sol`: fit 8.83, cost 0.40 ($4.00/$20.00), penalties 0.33/0.11, total 8.39 (ok)
- claude_team / `claude-sonnet-5`: fit 8.24, cost 0.32 ($2.00/$10.00), penalties 0.24/0.16, total 7.85 (ok)
- opencode_go / `deepseek-v4-flash-vision-exp`: fit 7.76, cost 0.02 ($0.15/$0.60), penalties 0.02/0.00, total 7.74 (ok)

Source: PHASES.md lines 817-837, hash `dc148dbf9aa8`

## P21 - Routes and hunts

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
very_high
native setting: Codex reasoning effort: Extra High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.13, best-fit model `gpt-6-astra` at cost pressure 1.00; 3 candidate(s) cleared the bar.

Why:
Task reads as implementation feature with top needs repo wide reasoning (1.00), direct implementation (0.76), architecture (0.73). GPT-6 Sol clears the phase's capability bar (9.17/10 vs threshold 9.13) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: implementation_feature (p=0.54)
- implementation complexity: 3.37/4
- reasoning depth: 3.36/4
- architecture need: 2.98/4
- repo context need: 3.46/4
- ambiguity: 3.05/4
- execution risk: 3.04/4
- research need: 3.28/4
- frontend/UI need: 3.07/4
- test/verification need: 2.63/4
- cross-component need: 3.71/4
- long-context need: 2.53/4
- factual accuracy need: 3.55/4
- profile confidence: 0.66; uncertainty: 0.34

Alternative:
opencode_go / `qwen3.8-max` (Qwen3.8 Max (Go)) - thinking very_high (automatic (provider default))

Routing confidence: 0.61 (fit margin over bar +0.036, capability fit 9.17/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.17, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 9.00 (ok)
- opencode_go / `qwen3.8-max`: fit 8.99, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.79 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.83, cost 0.08 ($0.66/$1.98), penalties 0.07/0.00, total 8.77 (ok)
- opencode_go / `glm-5.3`: fit 8.88, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.74 (ok)
- claude_team / `claude-opus-5-5`: fit 9.43, cost 0.64 ($4.00/$20.00), penalties 0.55/0.14, total 8.73 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.59, cost 1.00 ($10.00/$50.00), penalties 0.87/0.00, total 8.72 (ok)

Source: PHASES.md lines 843-868, hash `da00ec777766`

## P22 - Voices: acoustics, soundscapes, narration

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
high
native setting: Codex reasoning effort: High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.04, best-fit model `gpt-6-astra` at cost pressure 1.00; 3 candidate(s) cleared the bar.

Why:
Task reads as audio dsp with top needs audio dsp (1.00), architecture (0.67), deep debugging (0.66). GPT-6 Sol clears the phase's capability bar (9.16/10 vs threshold 9.04) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and a balanced capability/cost weighting was used. The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: audio_dsp (p=1.00)
- implementation complexity: 3.34/4
- reasoning depth: 3.33/4
- architecture need: 2.53/4
- repo context need: 3.26/4
- ambiguity: 2.93/4
- execution risk: 2.93/4
- research need: 2.55/4
- audio/dsp need: 3.99/4
- test/verification need: 2.83/4
- cross-component need: 3.7/4
- profile confidence: 0.66; uncertainty: 0.34

Alternative:
opencode_go / `deepseek-v4-pro` (DeepSeek V4 Pro (Go)) - thinking high (automatic (provider default))

Routing confidence: 0.65 (fit margin over bar +0.128, capability fit 9.16/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.16, cost 0.20 ($2.00/$10.00), penalties 0.30/0.00, total 8.86 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.75, cost 0.08 ($0.66/$1.98), penalties 0.12/0.00, total 8.63 (ok)
- opencode_go / `qwen3.8-max`: fit 8.92, cost 0.24 ($2.00/$6.00), penalties 0.36/0.00, total 8.56 (ok)
- opencode_go / `glm-5.3`: fit 8.75, cost 0.18 ($1.40/$4.40), penalties 0.26/0.00, total 8.49 (ok)
- opencode_go / `mimo-v2.6-pro`: fit 8.42, cost 0.04 ($0.43/$0.87), penalties 0.05/0.00, total 8.37 (ok)
- opencode_go / `deepseek-v4.1-flash`: fit 8.23, cost 0.02 ($0.15/$0.60), penalties 0.03/0.00, total 8.20 (ok)

Source: PHASES.md lines 874-892, hash `1225f195c456`

## P23 - Point and reveal (recognition v2)

Primary:
chatgpt_plus / `gpt-6-astra` (GPT-6 Astra)

Thinking:
very_high
native setting: Codex reasoning effort: Max
Picker values: low, medium, high, xhigh, max. Light (low) is the recommended starting preset; Extra High may be omitted on some paid plans; Max appears only when enabled in settings.

Cost:
$10.00 in / $50.00 out per MTok (API list); effective cost pressure 1.00 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.22, best-fit model `gpt-6-astra` at cost pressure 1.00; 1 candidate(s) cleared the bar.

Why:
Task reads as ml cv engineering with top needs ml cv (1.00), architecture (0.91), repo wide reasoning (0.77). GPT-6 Astra clears the phase's capability bar (9.52/10 vs threshold 9.22) at effective cost pressure 1.00 ($10.00 in / $50.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: ml_cv_engineering (p=1.00)
- implementation complexity: 3.71/4
- reasoning depth: 3.93/4
- architecture need: 3.45/4
- repo context need: 3.59/4
- debugging need: 2.5/4
- ambiguity: 2.96/4
- execution risk: 3.67/4
- research need: 2.68/4
- ml/cv need: 4/4
- test/verification need: 3.78/4
- cross-component need: 3.88/4
- long-context need: 3.45/4
- factual accuracy need: 2.92/4
- profile confidence: 0.73; uncertainty: 0.27

Alternative:
opencode_go / `deepseek-v4-flash-vision-exp` (DeepSeek V4 Flash Vision Exp (Go)) - thinking very_high (automatic (provider default))

Routing confidence: 0.74 (fit margin over bar +0.301, capability fit 9.52/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.16, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 9.00 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.52, cost 1.00 ($10.00/$50.00), penalties 0.87/0.00, total 8.65 (ok)
- opencode_go / `deepseek-v4-flash-vision-exp`: fit 7.78, cost 0.02 ($0.15/$0.60), penalties 0.02/0.00, total 7.76 (ok)
- chatgpt_plus / `gpt-6-luna`: fit 7.49, cost 0.01 ($0.10/$0.50), penalties 0.01/0.00, total 7.49 (ok)
- opencode_go / `qwen3.8-max`: fit 8.92, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.72 (blocked: no image input for a vision-heavy phase)
- opencode_go / `deepseek-v4-pro`: fit 8.72, cost 0.08 ($0.66/$1.98), penalties 0.07/0.00, total 8.65 (blocked: no image input for a vision-heavy phase)

Source: PHASES.md lines 898-923, hash `a31c0d242367`

## P24 - Mosque layer and craft kit

Primary:
claude_team / `claude-opus-5-5` (Claude Opus 5.5)

Thinking:
very_high
native setting: Claude Code /effort xhigh
Effort levels supported: low, medium, high, xhigh, max. Model default: medium.

Cost:
$4.00 in / $20.00 out per MTok (API list); effective cost pressure 0.64 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.22, best-fit model `gpt-6-astra` at cost pressure 1.00; 2 candidate(s) cleared the bar.

Why:
Task reads as implementation feature with top needs repo wide reasoning (1.00), architecture (0.74), direct implementation (0.72). Claude Opus 5.5 clears the phase's capability bar (9.42/10 vs threshold 9.22) at effective cost pressure 0.64 ($4.00 in / $20.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: implementation_feature (p=0.56)
- implementation complexity: 3.73/4
- reasoning depth: 3.82/4
- architecture need: 3.13/4
- repo context need: 3.68/4
- debugging need: 2.5/4
- ambiguity: 3.18/4
- execution risk: 3.4/4
- research need: 3.6/4
- frontend/UI need: 3.08/4
- visual reasoning need: 3.54/4
- 3D/graphics need: 3.66/4
- test/verification need: 2.64/4
- cross-component need: 3.87/4
- long-context need: 2.71/4
- factual accuracy need: 3.94/4
- profile confidence: 0.71; uncertainty: 0.29

Alternative:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol) - thinking very_high (Codex reasoning effort: Extra High)

Routing confidence: 0.70 (fit margin over bar +0.200, capability fit 9.42/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.16, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 8.99 (ok)
- claude_team / `claude-opus-5-5`: fit 9.42, cost 0.64 ($4.00/$20.00), penalties 0.55/0.15, total 8.71 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.59, cost 1.00 ($10.00/$50.00), penalties 0.88/0.00, total 8.71 (ok)
- chatgpt_plus / `gpt-5.6-sol`: fit 8.83, cost 0.40 ($4.00/$20.00), penalties 0.32/0.11, total 8.39 (ok)
- claude_team / `claude-sonnet-5`: fit 8.23, cost 0.32 ($2.00/$10.00), penalties 0.24/0.15, total 7.84 (ok)
- opencode_go / `deepseek-v4-flash-vision-exp`: fit 7.74, cost 0.02 ($0.15/$0.60), penalties 0.02/0.00, total 7.72 (ok)

Source: PHASES.md lines 929-949, hash `a0e648ccc3f5`

## P25 - Süleymaniye

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
very_high
native setting: Codex reasoning effort: Extra High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.10, best-fit model `gpt-6-astra` at cost pressure 1.00; 3 candidate(s) cleared the bar.

Why:
Task reads as graphics 3d engineering with top needs deep debugging (1.00), graphics 3d (0.91), visual reasoning (0.75). GPT-6 Sol clears the phase's capability bar (9.13/10 vs threshold 9.10) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: graphics_3d_engineering (p=0.42)
- implementation complexity: 3.55/4
- reasoning depth: 3.63/4
- architecture need: 2.8/4
- repo context need: 3.59/4
- debugging need: 2.54/4
- ambiguity: 3.2/4
- execution risk: 3.19/4
- research need: 3.63/4
- frontend/UI need: 3.35/4
- visual reasoning need: 3.49/4
- 3D/graphics need: 3.69/4
- cross-component need: 3.87/4
- long-context need: 2.85/4
- factual accuracy need: 3.89/4
- profile confidence: 0.66; uncertainty: 0.34

Alternative:
opencode_go / `qwen3.8-max` (Qwen3.8 Max (Go)) - thinking very_high (automatic (provider default))

Routing confidence: 0.60 (fit margin over bar +0.025, capability fit 9.13/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.13, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 8.96 (ok)
- opencode_go / `qwen3.8-max`: fit 9.01, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.81 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.53, cost 1.00 ($10.00/$50.00), penalties 0.86/0.00, total 8.66 (ok)
- opencode_go / `glm-5.3`: fit 8.73, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.59 (ok)
- claude_team / `claude-opus-5-5`: fit 9.26, cost 0.64 ($4.00/$20.00), penalties 0.54/0.16, total 8.56 (ok)
- opencode_go / `kimi-k3`: fit 9.00, cost 0.58 ($3.00/$15.00), penalties 0.47/0.00, total 8.53 (ok)

Source: PHASES.md lines 955-978, hash `1ff709d31f69`

## P26 - Sinan's Istanbul

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
very_high
native setting: Codex reasoning effort: Extra High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.06, best-fit model `gpt-6-astra` at cost pressure 1.00; 3 candidate(s) cleared the bar.

Why:
Task reads as content research with top needs precision (1.00), research (1.00), long context (0.69). GPT-6 Sol clears the phase's capability bar (9.17/10 vs threshold 9.06) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: content_research (p=0.82)
- implementation complexity: 3.5/4
- reasoning depth: 3.43/4
- repo context need: 3.49/4
- ambiguity: 3.1/4
- execution risk: 3.01/4
- research need: 3.66/4
- frontend/UI need: 2.73/4
- visual reasoning need: 3.27/4
- 3D/graphics need: 2.96/4
- cross-component need: 3.68/4
- long-context need: 2.98/4
- factual accuracy need: 3.88/4
- profile confidence: 0.62; uncertainty: 0.38

Alternative:
opencode_go / `qwen3.8-max` (Qwen3.8 Max (Go)) - thinking very_high (automatic (provider default))

Routing confidence: 0.62 (fit margin over bar +0.110, capability fit 9.17/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.17, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 9.00 (ok)
- opencode_go / `qwen3.8-max`: fit 8.89, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.70 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.52, cost 1.00 ($10.00/$50.00), penalties 0.86/0.00, total 8.66 (ok)
- opencode_go / `glm-5.3`: fit 8.77, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.63 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.64, cost 0.08 ($0.66/$1.98), penalties 0.06/0.00, total 8.58 (ok)
- opencode_go / `kimi-k3`: fit 9.01, cost 0.58 ($3.00/$15.00), penalties 0.47/0.00, total 8.54 (ok)

Source: PHASES.md lines 984-1003, hash `b5c2d3c5febd`

## P27 - Imperial to contemporary mosques, the dome's evolution, mahya

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
very_high
native setting: Codex reasoning effort: Extra High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.07, best-fit model `gpt-6-astra` at cost pressure 1.00; 3 candidate(s) cleared the bar.

Why:
Task reads as graphics 3d engineering with top needs deep debugging (1.00), graphics 3d (0.91), visual reasoning (0.88). GPT-6 Sol clears the phase's capability bar (9.13/10 vs threshold 9.07) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: graphics_3d_engineering (p=0.66)
- implementation complexity: 3.63/4
- reasoning depth: 3.56/4
- repo context need: 3.49/4
- debugging need: 2.7/4
- ambiguity: 3.07/4
- execution risk: 3.07/4
- research need: 3.4/4
- frontend/UI need: 3.42/4
- visual reasoning need: 3.83/4
- 3D/graphics need: 3.74/4
- cross-component need: 3.76/4
- long-context need: 2.83/4
- factual accuracy need: 3.71/4
- profile confidence: 0.68; uncertainty: 0.32

Alternative:
claude_team / `claude-opus-5-5` (Claude Opus 5.5) - thinking high (Claude Code /effort high)

Routing confidence: 0.63 (fit margin over bar +0.059, capability fit 9.13/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.13, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 8.96 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.53, cost 1.00 ($10.00/$50.00), penalties 0.87/0.00, total 8.65 (ok)
- claude_team / `claude-opus-5-5`: fit 9.26, cost 0.64 ($4.00/$20.00), penalties 0.54/0.16, total 8.56 (ok)
- chatgpt_plus / `gpt-5.6-sol`: fit 8.78, cost 0.40 ($4.00/$20.00), penalties 0.32/0.12, total 8.35 (ok)
- opencode_go / `deepseek-v4-flash-vision-exp`: fit 7.76, cost 0.02 ($0.15/$0.60), penalties 0.02/0.00, total 7.75 (ok)
- claude_team / `claude-sonnet-5`: fit 8.12, cost 0.32 ($2.00/$10.00), penalties 0.24/0.16, total 7.72 (ok)

Source: PHASES.md lines 1009-1028, hash `b15671df576b`

## P28 - Museum kit and the Istanbul Archaeology Museums

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
very_high
native setting: Codex reasoning effort: Extra High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.14, best-fit model `gpt-6-astra` at cost pressure 1.00; 3 candidate(s) cleared the bar.

Why:
Task reads as implementation feature with top needs repo wide reasoning (1.00), direct implementation (0.76), architecture (0.73). GPT-6 Sol clears the phase's capability bar (9.16/10 vs threshold 9.14) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: implementation_feature (p=0.51)
- implementation complexity: 3.49/4
- reasoning depth: 3.43/4
- architecture need: 3.2/4
- repo context need: 3.37/4
- ambiguity: 3.14/4
- execution risk: 3.07/4
- research need: 3.79/4
- frontend/UI need: 2.97/4
- visual reasoning need: 3.67/4
- 3D/graphics need: 3.02/4
- cross-component need: 3.63/4
- long-context need: 2.93/4
- factual accuracy need: 3.96/4
- profile confidence: 0.65; uncertainty: 0.35

Alternative:
claude_team / `claude-opus-5-5` (Claude Opus 5.5) - thinking high (Claude Code /effort high)

Routing confidence: 0.60 (fit margin over bar +0.027, capability fit 9.16/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.16, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 9.00 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.59, cost 1.00 ($10.00/$50.00), penalties 0.87/0.00, total 8.72 (ok)
- claude_team / `claude-opus-5-5`: fit 9.40, cost 0.64 ($4.00/$20.00), penalties 0.55/0.17, total 8.69 (ok)
- chatgpt_plus / `gpt-5.6-sol`: fit 8.82, cost 0.40 ($4.00/$20.00), penalties 0.32/0.12, total 8.39 (ok)
- claude_team / `claude-sonnet-5`: fit 8.24, cost 0.32 ($2.00/$10.00), penalties 0.24/0.17, total 7.83 (ok)
- opencode_go / `deepseek-v4-flash-vision-exp`: fit 7.76, cost 0.02 ($0.15/$0.60), penalties 0.02/0.00, total 7.74 (ok)

Source: PHASES.md lines 1034-1057, hash `548e3fc2883a`

## P29 - Topkapı and the palaces

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
very_high
native setting: Codex reasoning effort: Extra High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.11, best-fit model `gpt-6-astra` at cost pressure 1.00; 3 candidate(s) cleared the bar.

Why:
Task reads as graphics 3d engineering with top needs deep debugging (1.00), graphics 3d (0.92), visual reasoning (0.75). GPT-6 Sol clears the phase's capability bar (9.13/10 vs threshold 9.11) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: graphics_3d_engineering (p=0.57)
- implementation complexity: 3.52/4
- reasoning depth: 3.47/4
- architecture need: 2.55/4
- repo context need: 3.51/4
- debugging need: 2.54/4
- ambiguity: 3.3/4
- execution risk: 3.19/4
- research need: 2.94/4
- frontend/UI need: 3.51/4
- visual reasoning need: 3.51/4
- 3D/graphics need: 3.74/4
- cross-component need: 3.72/4
- long-context need: 2.55/4
- factual accuracy need: 3.62/4
- profile confidence: 0.62; uncertainty: 0.38

Alternative:
opencode_go / `qwen3.8-max` (Qwen3.8 Max (Go)) - thinking very_high (automatic (provider default))

Routing confidence: 0.58 (fit margin over bar +0.017, capability fit 9.13/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.13, cost 0.20 ($2.00/$10.00), penalties 0.16/0.00, total 8.96 (ok)
- opencode_go / `qwen3.8-max`: fit 9.01, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.81 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.53, cost 1.00 ($10.00/$50.00), penalties 0.85/0.00, total 8.67 (ok)
- claude_team / `claude-opus-5-5`: fit 9.27, cost 0.64 ($4.00/$20.00), penalties 0.53/0.14, total 8.60 (ok)
- opencode_go / `glm-5.3`: fit 8.73, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.59 (ok)
- opencode_go / `kimi-k3`: fit 9.00, cost 0.58 ($3.00/$15.00), penalties 0.47/0.00, total 8.53 (ok)

Source: PHASES.md lines 1063-1082, hash `07a70c71844a`

## P30 - Collections of the city

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
high
native setting: Codex reasoning effort: High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.00, best-fit model `gpt-6-astra` at cost pressure 1.00; 4 candidate(s) cleared the bar.

Why:
Task reads as content research with top needs research (1.00), precision (0.96), long context (0.65). GPT-6 Sol clears the phase's capability bar (9.17/10 vs threshold 9.00) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and a balanced capability/cost weighting was used. The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: content_research (p=0.66)
- implementation complexity: 3.27/4
- reasoning depth: 3.4/4
- repo context need: 3.52/4
- ambiguity: 3.2/4
- execution risk: 2.74/4
- research need: 3.65/4
- frontend/UI need: 2.87/4
- visual reasoning need: 3.57/4
- 3D/graphics need: 2.94/4
- cross-component need: 3.52/4
- long-context need: 2.72/4
- factual accuracy need: 3.75/4
- profile confidence: 0.52; uncertainty: 0.48

Alternative:
opencode_go / `qwen3.8-max` (Qwen3.8 Max (Go)) - thinking high (automatic (provider default))

Routing confidence: 0.60 (fit margin over bar +0.171, capability fit 9.17/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.17, cost 0.20 ($2.00/$10.00), penalties 0.29/0.00, total 8.88 (ok)
- opencode_go / `qwen3.8-max`: fit 8.89, cost 0.24 ($2.00/$6.00), penalties 0.35/0.00, total 8.54 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.63, cost 0.08 ($0.66/$1.98), penalties 0.11/0.00, total 8.52 (ok)
- opencode_go / `glm-5.3`: fit 8.77, cost 0.18 ($1.40/$4.40), penalties 0.25/0.00, total 8.52 (ok)
- opencode_go / `mimo-v2.6-pro`: fit 8.36, cost 0.04 ($0.43/$0.87), penalties 0.05/0.00, total 8.31 (ok)
- opencode_go / `hy4-preview`: fit 8.32, cost 0.10 ($0.83/$2.50), penalties 0.14/0.00, total 8.19 (ok)

Source: PHASES.md lines 1088-1105, hash `f4bd5fcb57a4`

## P31 - Scattered: Istanbul abroad

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
high
native setting: Codex reasoning effort: High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 8.94, best-fit model `gpt-6-astra` at cost pressure 1.00; 4 candidate(s) cleared the bar.

Why:
Task reads as content research with top needs research (1.00), precision (0.90), long context (0.60). GPT-6 Sol clears the phase's capability bar (9.20/10 vs threshold 8.94) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and a balanced capability/cost weighting was used. The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: content_research (p=0.71)
- implementation complexity: 2.98/4
- reasoning depth: 3.11/4
- repo context need: 3.26/4
- ambiguity: 3/4
- execution risk: 2.57/4
- research need: 3.89/4
- frontend/UI need: 2.62/4
- visual reasoning need: 2.95/4
- cross-component need: 3.34/4
- long-context need: 2.57/4
- factual accuracy need: 3.97/4
- profile confidence: 0.64; uncertainty: 0.36

Alternative:
opencode_go / `qwen3.8-max` (Qwen3.8 Max (Go)) - thinking high (automatic (provider default))

Routing confidence: 0.69 (fit margin over bar +0.259, capability fit 9.20/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.20, cost 0.20 ($2.00/$10.00), penalties 0.30/0.00, total 8.89 (ok)
- opencode_go / `qwen3.8-max`: fit 8.89, cost 0.24 ($2.00/$6.00), penalties 0.36/0.00, total 8.53 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.64, cost 0.08 ($0.66/$1.98), penalties 0.12/0.00, total 8.52 (ok)
- opencode_go / `glm-5.3`: fit 8.77, cost 0.18 ($1.40/$4.40), penalties 0.26/0.00, total 8.52 (ok)
- opencode_go / `mimo-v2.6-pro`: fit 8.36, cost 0.04 ($0.43/$0.87), penalties 0.05/0.00, total 8.31 (ok)
- opencode_go / `hy4-preview`: fit 8.32, cost 0.10 ($0.83/$2.50), penalties 0.14/0.00, total 8.18 (ok)

Source: PHASES.md lines 1111-1125, hash `9763c96e510e`

## P32 - Every district has a layer

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
high
native setting: Codex reasoning effort: High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.08, best-fit model `gpt-6-astra` at cost pressure 1.00; 2 candidate(s) cleared the bar.

Why:
Task reads as content research with top needs research (1.00), precision (0.96), long context (0.64). GPT-6 Sol clears the phase's capability bar (9.20/10 vs threshold 9.08) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: content_research (p=1.00)
- reasoning depth: 3.46/4
- repo context need: 3.45/4
- ambiguity: 3.13/4
- execution risk: 3.08/4
- research need: 3.97/4
- cross-component need: 3.7/4
- long-context need: 3.27/4
- factual accuracy need: 3.91/4
- profile confidence: 0.58; uncertainty: 0.41

Alternative:
opencode_go / `qwen3.8-max` (Qwen3.8 Max (Go)) - thinking high (automatic (provider default))

Routing confidence: 0.60 (fit margin over bar +0.118, capability fit 9.20/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.20, cost 0.20 ($2.00/$10.00), penalties 0.16/0.00, total 9.04 (ok)
- opencode_go / `qwen3.8-max`: fit 8.87, cost 0.24 ($2.00/$6.00), penalties 0.19/0.00, total 8.68 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.52, cost 1.00 ($10.00/$50.00), penalties 0.85/0.00, total 8.68 (ok)
- opencode_go / `glm-5.3`: fit 8.78, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.64 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.66, cost 0.08 ($0.66/$1.98), penalties 0.06/0.00, total 8.60 (ok)
- opencode_go / `kimi-k3`: fit 9.02, cost 0.58 ($3.00/$15.00), penalties 0.46/0.00, total 8.55 (ok)

Source: PHASES.md lines 1131-1146, hash `212e00b34a89`

## P33 - Discovery at scale

Primary:
chatgpt_plus / `gpt-6-astra` (GPT-6 Astra)

Thinking:
very_high
native setting: Codex reasoning effort: Extra High
Picker values: low, medium, high, xhigh, max. Light (low) is the recommended starting preset; Extra High may be omitted on some paid plans; Max appears only when enabled in settings.

Cost:
$10.00 in / $50.00 out per MTok (API list); effective cost pressure 1.00 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.19, best-fit model `gpt-6-astra` at cost pressure 1.00; 1 candidate(s) cleared the bar.

Why:
Task reads as implementation feature with top needs repo wide reasoning (1.00), architecture (0.74), direct implementation (0.74). GPT-6 Astra clears the phase's capability bar (9.60/10 vs threshold 9.19) at effective cost pressure 1.00 ($10.00 in / $50.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: implementation_feature (p=0.98)
- implementation complexity: 3.68/4
- reasoning depth: 3.71/4
- architecture need: 3.5/4
- repo context need: 3.63/4
- ambiguity: 3.05/4
- execution risk: 3.26/4
- test/verification need: 3.24/4
- cross-component need: 3.75/4
- long-context need: 3.62/4
- factual accuracy need: 3.05/4
- profile confidence: 0.70; uncertainty: 0.30

Alternative:
opencode_go / `deepseek-v4-pro` (DeepSeek V4 Pro (Go)) - thinking very_high (automatic (provider default))

Routing confidence: 0.75 (fit margin over bar +0.408, capability fit 9.60/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.17, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 9.00 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.86, cost 0.08 ($0.66/$1.98), penalties 0.07/0.00, total 8.79 (ok)
- opencode_go / `qwen3.8-max`: fit 8.99, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.79 (ok)
- opencode_go / `glm-5.3`: fit 8.90, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.76 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.60, cost 1.00 ($10.00/$50.00), penalties 0.88/0.00, total 8.72 (ok)
- opencode_go / `kimi-k3`: fit 9.11, cost 0.58 ($3.00/$15.00), penalties 0.48/0.00, total 8.63 (ok)

Source: PHASES.md lines 1152-1170, hash `793dca5dcac7`

## P34 - Turkish and English, complete

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
medium
native setting: Codex reasoning effort: Medium
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 8.96, best-fit model `gpt-6-astra` at cost pressure 1.00; 3 candidate(s) cleared the bar.

Why:
Task reads as localization content ops with top needs precision (1.00), long spec adherence (0.70), instruction following (0.51). GPT-6 Sol clears the phase's capability bar (9.20/10 vs threshold 8.96) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quota efficiency was allowed to matter. The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: localization_content_ops (p=1.00)
- implementation complexity: 3.06/4
- reasoning depth: 3.09/4
- repo context need: 3.38/4
- ambiguity: 2.51/4
- execution risk: 2.7/4
- frontend/UI need: 2.52/4
- test/verification need: 3.37/4
- cross-component need: 3.66/4
- long-context need: 3.36/4
- factual accuracy need: 2.83/4
- profile confidence: 0.63; uncertainty: 0.37

Alternative:
opencode_go / `deepseek-v4-pro` (DeepSeek V4 Pro (Go)) - thinking medium (automatic (provider default))

Routing confidence: 0.67 (fit margin over bar +0.235, capability fit 9.20/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.20, cost 0.20 ($2.00/$10.00), penalties 0.67/0.00, total 8.53 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.69, cost 0.08 ($0.66/$1.98), penalties 0.26/0.00, total 8.43 (ok)
- opencode_go / `mimo-v2.6-pro`: fit 8.53, cost 0.04 ($0.43/$0.87), penalties 0.12/0.00, total 8.41 (ok)
- opencode_go / `deepseek-v4.1-flash`: fit 8.39, cost 0.02 ($0.15/$0.60), penalties 0.07/0.00, total 8.32 (ok)
- opencode_go / `glm-5.3`: fit 8.82, cost 0.18 ($1.40/$4.40), penalties 0.57/0.00, total 8.25 (ok)
- opencode_go / `glm-5.3-flash`: fit 8.23, cost 0.02 ($0.15/$0.50), penalties 0.06/0.00, total 8.17 (ok)

Source: PHASES.md lines 1176-1193, hash `05dca9d5079b`

## P35 - Accessibility and reduced-motion equivalence

Primary:
claude_team / `claude-opus-5-5` (Claude Opus 5.5)

Thinking:
very_high
native setting: Claude Code /effort xhigh
Effort levels supported: low, medium, high, xhigh, max. Model default: medium.

Cost:
$4.00 in / $20.00 out per MTok (API list); effective cost pressure 0.64 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.21, best-fit model `gpt-6-astra` at cost pressure 1.00; 2 candidate(s) cleared the bar.

Why:
Task reads as accessibility with top needs precision (1.00), frontend ui (0.99), repo wide reasoning (0.94). Claude Opus 5.5 clears the phase's capability bar (9.34/10 vs threshold 9.21) at effective cost pressure 0.64 ($4.00 in / $20.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: accessibility (p=1.00)
- implementation complexity: 3.63/4
- reasoning depth: 3.57/4
- repo context need: 3.65/4
- debugging need: 2.51/4
- ambiguity: 2.97/4
- execution risk: 3.5/4
- frontend/UI need: 3.9/4
- test/verification need: 3.59/4
- cross-component need: 3.86/4
- long-context need: 2.55/4
- profile confidence: 0.59; uncertainty: 0.41

Alternative:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol) - thinking very_high (Codex reasoning effort: Extra High)

Routing confidence: 0.61 (fit margin over bar +0.130, capability fit 9.34/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.18, cost 0.20 ($2.00/$10.00), penalties 0.16/0.00, total 9.02 (ok)
- opencode_go / `qwen3.8-max`: fit 8.93, cost 0.24 ($2.00/$6.00), penalties 0.19/0.00, total 8.74 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.53, cost 1.00 ($10.00/$50.00), penalties 0.83/0.00, total 8.70 (ok)
- opencode_go / `glm-5.3`: fit 8.82, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.68 (ok)
- claude_team / `claude-opus-5-5`: fit 9.34, cost 0.64 ($4.00/$20.00), penalties 0.52/0.14, total 8.67 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.65, cost 0.08 ($0.66/$1.98), penalties 0.06/0.00, total 8.59 (ok)

Source: PHASES.md lines 1199-1216, hash `c1fe2d06ffe6`

## P36 - Performance, size and asset delivery

Primary:
claude_team / `claude-opus-5-5` (Claude Opus 5.5)

Thinking:
very_high
native setting: Claude Code /effort xhigh
Effort levels supported: low, medium, high, xhigh, max. Model default: medium.

Cost:
$4.00 in / $20.00 out per MTok (API list); effective cost pressure 0.64 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.24, best-fit model `gpt-6-astra` at cost pressure 1.00; 2 candidate(s) cleared the bar.

Why:
Task reads as performance optimization with top needs deep debugging (1.00), architecture (0.56), repo wide reasoning (0.51). Claude Opus 5.5 clears the phase's capability bar (9.47/10 vs threshold 9.24) at effective cost pressure 0.64 ($4.00 in / $20.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: performance_optimization (p=1.00)
- implementation complexity: 3.53/4
- reasoning depth: 3.91/4
- architecture need: 2.92/4
- repo context need: 3.65/4
- debugging need: 3.67/4
- ambiguity: 2.82/4
- execution risk: 3.47/4
- 3D/graphics need: 2.77/4
- test/verification need: 3.9/4
- cross-component need: 3.89/4
- profile confidence: 0.69; uncertainty: 0.32

Alternative:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol) - thinking very_high (Codex reasoning effort: Extra High)

Routing confidence: 0.70 (fit margin over bar +0.234, capability fit 9.47/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.15, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 8.99 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.87, cost 0.08 ($0.66/$1.98), penalties 0.07/0.00, total 8.80 (ok)
- opencode_go / `qwen3.8-max`: fit 8.99, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.79 (ok)
- claude_team / `claude-opus-5-5`: fit 9.47, cost 0.64 ($4.00/$20.00), penalties 0.55/0.14, total 8.79 (ok)
- opencode_go / `glm-5.3`: fit 8.87, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.73 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.59, cost 1.00 ($10.00/$50.00), penalties 0.87/0.00, total 8.72 (ok)

Source: PHASES.md lines 1222-1242, hash `3bb384a0dba5`

## P37 - Reliability, permissions and privacy

Primary:
claude_team / `claude-opus-5-5` (Claude Opus 5.5)

Thinking:
very_high
native setting: Claude Code /effort max
Effort levels supported: low, medium, high, xhigh, max. Model default: medium.

Cost:
$4.00 in / $20.00 out per MTok (API list); effective cost pressure 0.64 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.31, best-fit model `gpt-6-astra` at cost pressure 1.00; 2 candidate(s) cleared the bar.

Why:
Task reads as security privacy with top needs precision (1.00), deep debugging (0.79), architecture (0.71). Claude Opus 5.5 clears the phase's capability bar (9.41/10 vs threshold 9.31) at effective cost pressure 0.64 ($4.00 in / $20.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: security_privacy (p=0.98)
- implementation complexity: 3.51/4
- reasoning depth: 3.85/4
- architecture need: 2.88/4
- repo context need: 3.7/4
- debugging need: 2.75/4
- ambiguity: 3.05/4
- execution risk: 3.96/4
- test/verification need: 3.79/4
- cross-component need: 3.84/4
- profile confidence: 0.71; uncertainty: 0.29

Alternative:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol) - thinking very_high (Codex reasoning effort: Max)

Routing confidence: 0.66 (fit margin over bar +0.099, capability fit 9.41/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.16, cost 0.20 ($2.00/$10.00), penalties 0.17/0.00, total 9.00 (ok)
- claude_team / `claude-opus-5-5`: fit 9.41, cost 0.64 ($4.00/$20.00), penalties 0.54/0.12, total 8.75 (ok)
- opencode_go / `qwen3.8-max`: fit 8.88, cost 0.24 ($2.00/$6.00), penalties 0.20/0.00, total 8.68 (ok)
- opencode_go / `glm-5.3`: fit 8.82, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.68 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.53, cost 1.00 ($10.00/$50.00), penalties 0.86/0.00, total 8.67 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.73, cost 0.08 ($0.66/$1.98), penalties 0.06/0.00, total 8.67 (ok)

Source: PHASES.md lines 1248-1265, hash `5b7e9682a3a6`

## P38 - Test automation, CI and device matrix

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
high
native setting: Codex reasoning effort: High
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.10, best-fit model `gpt-6-astra` at cost pressure 1.00; 3 candidate(s) cleared the bar.

Why:
Task reads as testing ci with top needs test reasoning (1.00), repo wide reasoning (0.67), architecture (0.63). GPT-6 Sol clears the phase's capability bar (9.17/10 vs threshold 9.10) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quota efficiency was allowed to matter. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: testing_ci (p=1.00)
- implementation complexity: 3.63/4
- reasoning depth: 3.38/4
- repo context need: 3.69/4
- debugging need: 2.95/4
- ambiguity: 2.89/4
- execution risk: 3.04/4
- test/verification need: 3.95/4
- cross-component need: 3.9/4
- profile confidence: 0.67; uncertainty: 0.33

Alternative:
opencode_go / `deepseek-v4-pro` (DeepSeek V4 Pro (Go)) - thinking high (automatic (provider default))

Routing confidence: 0.63 (fit margin over bar +0.068, capability fit 9.17/10)

Top candidates:
- opencode_go / `deepseek-v4-pro`: fit 8.82, cost 0.08 ($0.66/$1.98), penalties 0.26/0.00, total 8.56 (ok)
- chatgpt_plus / `gpt-6-sol`: fit 9.17, cost 0.20 ($2.00/$10.00), penalties 0.67/0.00, total 8.50 (ok)
- opencode_go / `mimo-v2.6-pro`: fit 8.53, cost 0.04 ($0.43/$0.87), penalties 0.12/0.00, total 8.41 (ok)
- opencode_go / `glm-5.3`: fit 8.86, cost 0.18 ($1.40/$4.40), penalties 0.58/0.00, total 8.29 (ok)
- opencode_go / `deepseek-v4.1-flash`: fit 8.28, cost 0.02 ($0.15/$0.60), penalties 0.07/0.00, total 8.21 (ok)
- opencode_go / `qwen3.8-max`: fit 8.93, cost 0.24 ($2.00/$6.00), penalties 0.80/0.00, total 8.13 (ok)

Source: PHASES.md lines 1271-1290, hash `3ddf8a943da0`

## P39 - Field trial in Istanbul and polish

Primary:
chatgpt_plus / `gpt-6-sol` (GPT-6 Sol)

Thinking:
medium
native setting: Codex reasoning effort: Medium
Picker values: low, medium, high, xhigh, max, ultra. Low/Medium/High/Extra High/Max in the picker; Ultra runs subagents for decomposable tasks. OpenAI recommends Medium as the start.

Cost:
$2.00 in / $10.00 out per MTok (API list); effective cost pressure 0.20 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.07, best-fit model `gpt-6-astra` at cost pressure 1.00; 3 candidate(s) cleared the bar.

Why:
Task reads as testing ci with top needs test reasoning (1.00), repo wide reasoning (0.59), instruction following (0.58). GPT-6 Sol clears the phase's capability bar (9.17/10 vs threshold 9.07) at effective cost pressure 0.20 ($2.00 in / $10.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quota efficiency was allowed to matter. The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: testing_ci (p=0.84)
- reasoning depth: 3.23/4
- repo context need: 3.21/4
- debugging need: 3.27/4
- ambiguity: 2.89/4
- execution risk: 2.94/4
- test/verification need: 3.43/4
- cross-component need: 3.67/4
- factual accuracy need: 3.52/4
- profile confidence: 0.60; uncertainty: 0.40

Alternative:
opencode_go / `deepseek-v4-pro` (DeepSeek V4 Pro (Go)) - thinking medium (automatic (provider default))

Routing confidence: 0.60 (fit margin over bar +0.094, capability fit 9.17/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.17, cost 0.20 ($2.00/$10.00), penalties 0.66/0.00, total 8.51 (ok)
- opencode_go / `deepseek-v4-pro`: fit 8.76, cost 0.08 ($0.66/$1.98), penalties 0.25/0.00, total 8.51 (ok)
- opencode_go / `mimo-v2.6-pro`: fit 8.53, cost 0.04 ($0.43/$0.87), penalties 0.12/0.00, total 8.41 (ok)
- opencode_go / `glm-5.3`: fit 8.84, cost 0.18 ($1.40/$4.40), penalties 0.56/0.00, total 8.28 (ok)
- opencode_go / `deepseek-v4.1-flash`: fit 8.32, cost 0.02 ($0.15/$0.60), penalties 0.07/0.00, total 8.24 (ok)
- opencode_go / `qwen3.8-max`: fit 8.92, cost 0.24 ($2.00/$6.00), penalties 0.78/0.00, total 8.14 (ok)

Source: PHASES.md lines 1296-1315, hash `f6cc532ea705`

## P40 - Store launch kit and release

Primary:
chatgpt_plus / `gpt-6-astra` (GPT-6 Astra)

Thinking:
high
native setting: Codex reasoning effort: High
Picker values: low, medium, high, xhigh, max. Light (low) is the recommended starting preset; Extra High may be omitted on some paid plans; Max appears only when enabled in settings.

Cost:
$10.00 in / $50.00 out per MTok (API list); effective cost pressure 1.00 (0 = cheapest registry model, 1 = most expensive).
capability bar 9.26, best-fit model `gpt-6-astra` at cost pressure 1.00; 1 candidate(s) cleared the bar.

Why:
Task reads as release ops with top needs precision (1.00), instruction following (0.77), repo wide reasoning (0.64). GPT-6 Astra clears the phase's capability bar (9.52/10 vs threshold 9.26) at effective cost pressure 1.00 ($10.00 in / $50.00 out per MTok); the strongest-fit option was gpt-6-astra at 1.00 cost pressure, and quality was weighted above quota cost. High execution risk, so the capability bar was kept tight (cost still decides only among models that clear it). The prompt leaves room for judgment, which favors a stronger model.

Task profile:
- dominant task: release_ops (p=1.00)
- reasoning depth: 3.42/4
- repo context need: 3.62/4
- ambiguity: 3.01/4
- execution risk: 3.77/4
- research need: 2.64/4
- visual reasoning need: 3.4/4
- cross-component need: 3.93/4
- long-context need: 3.04/4
- factual accuracy need: 3.24/4
- profile confidence: 0.67; uncertainty: 0.33

Alternative:
opencode_go / `deepseek-v4-flash-vision-exp` (DeepSeek V4 Flash Vision Exp (Go)) - thinking high (automatic (provider default))

Routing confidence: 0.70 (fit margin over bar +0.264, capability fit 9.52/10)

Top candidates:
- chatgpt_plus / `gpt-6-sol`: fit 9.17, cost 0.20 ($2.00/$10.00), penalties 0.16/0.00, total 9.01 (ok)
- chatgpt_plus / `gpt-6-astra`: fit 9.52, cost 1.00 ($10.00/$50.00), penalties 0.85/0.00, total 8.67 (ok)
- opencode_go / `deepseek-v4-flash-vision-exp`: fit 7.76, cost 0.02 ($0.15/$0.60), penalties 0.02/0.00, total 7.74 (ok)
- chatgpt_plus / `gpt-6-luna`: fit 7.63, cost 0.01 ($0.10/$0.50), penalties 0.01/0.00, total 7.62 (ok)
- opencode_go / `qwen3.8-max`: fit 8.89, cost 0.24 ($2.00/$6.00), penalties 0.19/0.00, total 8.70 (blocked: no image input for a vision-heavy phase)
- opencode_go / `glm-5.3`: fit 8.82, cost 0.18 ($1.40/$4.40), penalties 0.14/0.00, total 8.68 (blocked: no image input for a vision-heavy phase)

Source: PHASES.md lines 1321-1343, hash `ac3c25ad8462`

## Distribution sanity check

- chatgpt_plus/gpt-6-sol: 23
- claude_team/claude-opus-5-5: 13
- chatgpt_plus/gpt-6-astra: 5

Distribution looks differentiated; no single model dominates above the 60% alert threshold.

Task mix driving the distribution: implementation feature x10, graphics 3d engineering x7, content research x7, refactor migration x2. The router selects the cheapest effective-cost model that clears each phase's capability bar; the bar tightens as execution risk rises, which is why cheap models win routine phases and frontier models are kept for risky ones.

## Model capability summary

Models that participated in routing (primary or alternative), with the project-specific reasons the engine distinguishes them.

### GPT-6 Sol (`gpt-6-sol`)

- Surface: ChatGPT Plus (Work / Codex)
- Strengths: instruction following 9.3, long context 9.3, frontend ui 9.3, direct implementation 9.2
- Weaker: usage efficiency 5.0, speed 7.5, visual reasoning 9.0
- Context: 1,100,000 tokens; vision input: yes
- API list price: $2.00 in / $10.00 out per MTok (OpenAI API list price shown for gpt-6-sol (Code Arena).)
- Effective cost pressure (0-1, global price + surface burn): 0.20; surface allowance burn: 0.50
- Reasoning control: effort; levels: low, medium, high, xhigh, max, ultra; default: medium (verified)
- Evidence (agentic tool use): Terminal-Bench 4.0 43.9 (max); the recommended Plus workhorse in Codex.
- Evidence (frontend ui): WebDev data-analytics #5 on GPT-6 Sol max (1611 Elo).
- Evidence (long context): 1.1M context window with Codex experimental context management on Plus.
- Availability: Included in ChatGPT Work and Codex on Plus; not in Chat. Use `codex --model gpt-6-sol` or the desktop model picker.

### DeepSeek V4 Pro (Go) (`deepseek-v4-pro`)

- Surface: OpenCode Go
- Strengths: long context 9.4, direct implementation 9.0, architecture 9.0, deep debugging 9.0
- Weaker: usage efficiency 4.0, speed 7.0, visual reasoning 8.2
- Context: 1,000,000 tokens; vision input: no
- API list price: $0.66 in / $1.98 out per MTok ()
- Effective cost pressure (0-1, global price + surface burn): 0.08; surface allowance burn: 0.60
- Reasoning control: opencode variant; levels: low, high, max; default: automatic (variant names unverified on this surface)
- Evidence (agentic tool use): Terminal-Bench 2.1 87.9; TB4.0 harness result lower at 14.6 (harness-sensitive).
- Evidence (deep debugging): DeepSeek reasoning lineage; strong at methodical analysis.
- Evidence (usage efficiency): Mid-cost within Go; better value than Kimi K3.
- Availability: Present in the live OpenCode Go catalog (checked at runtime).

### Claude Opus 5.5 (`claude-opus-5-5`)

- Surface: Claude Team / Claude Code
- Strengths: agentic tool use 9.7, direct implementation 9.6, architecture 9.6, deep debugging 9.6
- Weaker: usage efficiency 3.0, speed 7.5, long context 8.5
- Context: 200,000 tokens; vision input: yes
- API list price: $4.00 in / $20.00 out per MTok (Anthropic API list price at Opus 5.5 launch (fast mode $8/$40).)
- Effective cost pressure (0-1, global price + surface burn): 0.64; surface allowance burn: 0.90
- Reasoning control: adaptive effort; levels: low, medium, high, xhigh, max; default: medium (verified)
- Evidence (agentic tool use): Terminal-Bench 4.0 59.6 (AA, tied #1).
- Evidence (frontend ui): WebDev data-analytics arena #1 on Opus 5.5 max (2026-09-25).
- Evidence (architecture): Anthropic positions Opus for complex agentic coding; vendor reports best merge-rate per cost on FrontierCode (54.6 at default effort).
- Evidence (usage efficiency): Opus family is separately metered on Team; heaviest quota draw of the three Team models.
- Availability: Included on Team (Opus row = Yes). Default Opus on Team Standard since Claude Code 2.1.280 (2026-09-22).

### GPT-6 Astra (`gpt-6-astra`)

- Surface: ChatGPT Plus (Work / Codex)
- Strengths: direct implementation 9.7, architecture 9.7, agentic tool use 9.7, frontend ui 9.7
- Weaker: usage efficiency 2.5, speed 6.5, graphics 3d 9.4
- Context: 1,100,000 tokens; vision input: yes
- API list price: $10.00 in / $50.00 out per MTok (OpenAI API list price shown for gpt-6-astra (Code Arena).)
- Effective cost pressure (0-1, global price + surface burn): 1.00; surface allowance burn: 0.85
- Reasoning control: effort; levels: low, medium, high, xhigh, max; default: low (verified)
- Evidence (frontend ui): Code Arena WebDev overall #1 (1800 Elo, 2026-09-11).
- Evidence (agentic tool use): Terminal-Bench 4.0 59.6 (AA, tied #1 with Opus 5.5).
- Evidence (visual reasoning): Strongest WebDev visual results and OpenAI's top multi-step model.
- Evidence (usage efficiency): Metered separately in Work/Codex; heaviest draw on the Plus surface.
- Availability: Included in ChatGPT Work and Codex on Plus (rolling out from 2026-09-22). Not selectable in Chat on Plus; GPT-6 Pro (Astra) in Chat is Pro/Business/Enterprise.

### Qwen3.8 Max (Go) (`qwen3.8-max`)

- Surface: OpenCode Go
- Strengths: frontend ui 9.4, long context 9.3, visual reasoning 9.2, direct implementation 9.1
- Weaker: usage efficiency 3.5, speed 6.8, research 8.7
- Context: 1,000,000 tokens; vision input: no
- API list price: $2.00 in / $6.00 out per MTok ()
- Effective cost pressure (0-1, global price + surface burn): 0.24; surface allowance burn: 0.50
- Reasoning control: opencode variant; levels: low, high, max; default: automatic (variant names unverified on this surface)
- Evidence (frontend ui): Code Arena WebDev overall #4 (1681 Elo) and #1 non-OpenAI family on several arenas.
- Evidence (agentic tool use): Terminal-Bench 4.0 38.9; Terminal-Bench 2.1 86.6.
- Evidence (visual reasoning): Consistently top-5 in visual arenas.
- Evidence (usage efficiency): One of the pricier Go models; use where visual quality matters.
- Availability: Present in the live OpenCode Go catalog (checked at runtime).

### DeepSeek V4 Flash Vision Exp (Go) (`deepseek-v4-flash-vision-exp`)

- Surface: OpenCode Go
- Strengths: usage efficiency 9.3, long context 9.2, visual reasoning 8.8, speed 8.6
- Weaker: architecture 7.4, ambiguity handling 7.4, code review 7.5
- Context: 1,000,000 tokens; vision input: yes
- API list price: $0.15 in / $0.60 out per MTok ()
- Effective cost pressure (0-1, global price + surface burn): 0.02; surface allowance burn: 0.14
- Reasoning control: opencode variant; levels: low, high, max; default: automatic (variant names unverified on this surface)
- Evidence (visual reasoning): Vision-capable DeepSeek variant; useful for screenshot/UI and scene work when Claude/GPT vision is unavailable.
- Evidence (usage efficiency): Cheap vision option inside Go.
- Availability: Present in the live OpenCode Go catalog (checked at runtime); experimental.

## Cost model and price reference

Prices are API list prices from the same research pass as the capability scores. Subscriptions (Claude Team, ChatGPT Plus) are flat, so price is used as the relative allowance-burn proxy there; OpenCode Go limits are dollar-denominated, so price maps directly to quota burn.

Effective cost pressure = 0.60 * global price norm + 0.40 * within-surface norm, where price is weighted 30% input / 70% output and normalized against the most expensive registry model (GPT-6 Astra). The router picks the cheapest model whose capability fit clears the phase's bar: `bar = max(min_fit, best_fit - tolerance)`, with `tolerance` widening as risk and complexity fall, scaled by `--cost-aversion` (medium).

| Model | Surface | In $/MTok | Out $/MTok | Cost pressure |
| --- | --- | --- | --- | --- |
| `gpt-6-astra` | chatgpt_plus | 10.00 | 50.00 | 1.00 |
| `claude-opus-5-5` | claude_team | 4.00 | 20.00 | 0.64 |
| `gpt-5.6-sol` | chatgpt_plus | 4.00 | 20.00 | 0.40 |
| `kimi-k3` | opencode_go | 3.00 | 15.00 | 0.58 |
| `claude-sonnet-5` | claude_team | 2.00 | 10.00 | 0.32 |
| `gpt-6-sol` | chatgpt_plus | 2.00 | 10.00 | 0.20 |
| `qwen3.8-max` | opencode_go | 2.00 | 6.00 | 0.24 |
| `grok-4.6` | opencode_go | 2.00 | 6.00 | 0.24 |
| `grok-4.7` | opencode_go | 2.00 | 6.00 | 0.24 |
| `claude-haiku-4-5` | claude_team | 1.00 | 5.00 | 0.16 |
| `glm-5.3` | opencode_go | 1.40 | 4.40 | 0.18 |
| `kimi-k2.7-code` | opencode_go | 0.95 | 4.00 | 0.16 |
| `kimi-k2.6` | opencode_go | 0.95 | 4.00 | 0.16 |
| `hy4-preview` | opencode_go | 0.83 | 2.50 | 0.10 |
| `deepseek-v4-pro` | opencode_go | 0.66 | 1.98 | 0.08 |
| `minimax-m3` | opencode_go | 0.30 | 1.20 | 0.05 |
| `longcat-2.0` | opencode_go | 0.30 | 1.20 | 0.05 |
| `minimax-m2.7` | opencode_go | 0.30 | 1.20 | 0.05 |
| `mimo-v2.6-pro` | opencode_go | 0.43 | 0.87 | 0.04 |
| `mimo-v2.5-pro` | opencode_go | 0.43 | 0.87 | 0.04 |
| `deepseek-v4.1-flash` | opencode_go | 0.15 | 0.60 | 0.02 |
| `deepseek-v4-flash-vision-exp` | opencode_go | 0.15 | 0.60 | 0.02 |
| `gpt-6-luna` | chatgpt_plus | 0.10 | 0.50 | 0.01 |
| `glm-5.3-flash` | opencode_go | 0.15 | 0.50 | 0.02 |
| `gpt-6-luna` | opencode_go | 0.10 | 0.50 | 0.02 |
| `qwen3.8-flash` | opencode_go | 0.15 | 0.47 | 0.02 |
| `mimo-v2.6-flash` | opencode_go | 0.14 | 0.28 | 0.01 |

## Surface usage notes

### Claude Team / Claude Code (`claude_team`)

- How to run: Open a Claude Code session signed in with the Team account and paste the phase prompt.
- Usage economics: Shared 5-hour and weekly seat pool across Claude chat and Claude Code; Opus-family usage is metered separately from Sonnet/Haiku.
- Thinking control: /effort <level> (persists per model), --effort, CLAUDE_CODE_EFFORT_LEVEL.
- Verification: Run /model and /effort to confirm the selected model and effort before pasting.

### ChatGPT Plus (Work / Codex) (`chatgpt_plus`)

- How to run: Use Codex CLI (`codex --model <id>`) or the ChatGPT desktop Work/Codex picker; paste the phase prompt there. The plain Chat surface only gets GPT-5.6 Sol.
- Usage economics: Work/Codex usage is metered separately from Chat on Plus; GPT-6 Pro allowances are Pro/Business/Enterprise only.
- Thinking control: Reasoning-effort control under the composer, or /model in Codex CLI.
- Verification: Confirm the model and reasoning level in the picker; staged rollouts can differ per account.

### OpenCode Go (`opencode_go`)

- How to run: Run OpenCode connected with Go (`/connect`), select `opencode-go/<model-id>` with `#variant` if published, and paste the phase prompt.
- Usage economics: $10/month with approx. $12 / 5h rolling, $30 / week, $60 / month of usage; expensive models consume the allowance faster.
- Thinking control: OpenCode model variants and provider options (reasoningEffort for OpenAI-compatible models; thinking budgets for Anthropic-compatible ones).
- Verification: Variant names come from current catalog metadata; unknown variants error out. Verify with the model picker or the live models endpoint.

## Research snapshot

- Catalog researched at: 2026-09-27. OpenCode Go IDs are re-checked live at run time; Claude and ChatGPT availability is a documented snapshot and can lag staged rollouts.
- Registered models: 27. Phases reference this registry; new models are added here, never in Jev.
- Benchmark scores are not compared across incompatible harnesses; they are used directionally with vendor claims marked as vendor claims.

- [Anthropic - Models overview](https://docs.anthropic.com/en/docs/about-claude/models) - accessed 2026-09-27. Current Claude lineup (Fable 5.1, Opus 5, Sonnet 5, Haiku 4.5), thinking modes, context and pricing.
- [Claude - Plans & Pricing (Team)](https://claude.com/pricing) - accessed 2026-09-27. Team plan includes Opus/Sonnet/Haiku, no Fable; 200k context on Team; seat usage model.
- [Anthropic Help - What is the Team plan?](https://support.claude.com/en/articles/9266767-what-is-the-team-plan) - accessed 2026-09-27. Team Standard 1.25x Pro per-session, Premium 6.25x; Claude Code included; shared pool.
- [Anthropic - Introducing Claude Opus 5.5 / What's new in Opus 5.5](https://www.anthropic.com/claude-opus-5-5) - accessed 2026-09-27. Opus 5.5 default effort medium, adaptive thinking always on, Terminal-Bench 4.0 / FrontierCode / CursorBench results.
- [Claude Platform Docs - Effort](https://platform.claude.com/docs/en/build-with-claude/effort) - accessed 2026-09-27. low/medium/high/xhigh/max effort, per-model defaults, recommendation for coding/agentic work.
- [Claude Academy - Choosing the right effort level in Claude Code](https://academy.claude.com/tutorials/choosing-the-right-effort-level-in-claude-code) - accessed 2026-09-27. /effort control, --effort flag, CLAUDE_CODE_EFFORT_LEVEL, ultracode is not an effort level.
- [Claude Code 2.1.280 coverage (Opus 5.5 default)](https://www.buildthisnow.com/fr/blog/guide/mechanics/claude-opus-5-5-in-claude-code) - accessed 2026-09-27. Opus 5.5 default on Pro/Team Standard, medium default effort, 1M context on Claude Code.
- [OpenAI / ChatGPT Learn - Models (Work + Codex)](https://learn.chatgpt.com/docs/models) - accessed 2026-09-27. GPT-6 Astra/Sol/Luna availability, reasoning efforts (low..max, ultra), Ultra subagents, Plus access via Work/Codex.
- [OpenAI Help Center - GPT-5.6 in ChatGPT](https://help.openai.com/en/articles/20001354-gpt-5-6-in-chatgpt) - accessed 2026-09-27. Plus gets Medium/High reasoning in Chat; Extra High/Pro are plan-gated; Codex/Work model split.
- [OpenAI - GPT-6 Astra announcement](https://openai.com/index/gpt-6-astra/) - accessed 2026-09-27. Astra availability across plans, ARC-AGI results, agentic positioning.
- [ChatGPT Pricing - Plus](https://chatgpt.com/pricing/) - accessed 2026-09-27. Plus reasoning context 256K, GPT Reasoning input maximum ~320 pages.
- [OpenCode - Go](https://opencode.ai/docs/go/) - accessed 2026-09-27. OpenCode Go model list, exact model IDs, endpoints, $10/month subscription.
- [OpenCode Go live models endpoint](https://opencode.ai/zen/go/v1/models) - accessed 2026-09-27. Runtime availability refresh; authoritative current ID list.
- [Models.dev - OpenCode Go provider metadata](https://models.opencode.ai/providers/opencode-go/) - accessed 2026-09-27. Per-model context, output, price, reasoning/tool/structured flags.
- [OpenCode - Models / variants](https://opencode.ai/docs/models/) - accessed 2026-09-27. reasoningEffort, thinking budgetTokens, built-in variants for Anthropic/OpenAI/Google families.
- [OpenCode Go usage limits (provider integration docs)](https://docs.docker.com/ai/docker-agent/providers/opencode-go/) - accessed 2026-09-27. Go limits: $12 / 5h rolling, $30 / week, $60 / month; more expensive models consume more.
- [Artificial Analysis - Terminal-Bench 4.0 leaderboard](https://artificialanalysis.ai/evaluations/terminalbench-4-0) - accessed 2026-09-27. Agentic terminal benchmark: Opus 5.5 59.6, GPT-6 Astra 59.6, Fable 5.1 55.1, GPT-6 Sol 43.9, GLM-5.3 41.9, GPT-5.6 Sol 39.9, Qwen3.8 Max 38.9, MiMo-V2.6-Pro 34.8, GLM-5.3 Flash 32.8, DeepSeek V4.1 Flash 26.8, Grok 4.7 25.8.
- [Terminal-Bench 2.1 leaderboards (BenchLM / CodingFleet aggregate)](https://benchlm.ai/benchmarks/terminalbench21) - accessed 2026-09-27. DeepSeek V4.1 Flash 90.6, MiMo-V2.6-Pro 89.9, Muse Spark 1.3 88.8, Kimi K3 88.3, GLM-5.3 88.2, DeepSeek V4 Pro 87.9, Qwen3.8 Max 86.6, Hy4 85.4, GPT-5.6 Sol 91.9. Harness differs from TB4.0; use directionally.
- [Code Arena - WebDev leaderboard](https://arena.ai/leaderboard/code/webdev/overall) - accessed 2026-09-27. Front-end/visual arena: GPT-6 Astra #1, Fable 5.1 #2, Opus 5 #3, Qwen3.8 Max #4, Kimi K3 #5, Muse Spark 1.3 #8, Grok 4.6/4.7, GPT-5.6 Sol, GLM-5.3, Hy4.
- [TypeSafe AI - Jev documentation](https://docs.typesafe.ai/) - accessed 2026-09-27. System One API: POST /v1/systemone, model jev-latest, choice/score/noul primitives, calibrated probabilities.
- [TypeSafe AI - Introducing System One Models & Jev](https://typesafe.ai/blog/introducing-system-one-models-and-jev) - accessed 2026-09-27. Jev positioning: task-shaped decisions, calibrated confidence, $0.042/MTok input, 70-500ms latency.

**Phase count note.** The brief expected approximately 40 prompts. This PHASES.md genuinely contains 41 actual prompts (P00-P40): P00 ('Milion identity and plan') is marked done in the file but is kept as a re-runnable audit prompt, so it counts and is routed. The parser asserts 41 rather than forcing 40; it fails loudly if the document changes structurally.

<!-- route_phases.py:generated -->
