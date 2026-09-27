# Milion — Progress

**Updated 2026-09-26, after P00. Overall readiness: 12.0%.** This is the mean of the 56 dimensions below: 673 points out of 5,600.

**Ship rule.** Milion is ready to ship when **every dimension is at 100%** and no release-blocking Open issue remains in PHASES.md §8. The average only shows direction; a high score in one area cannot compensate for a low score in another.

## How scoring works

| Score | Meaning |
| --- | --- |
| 0% | Nothing usable exists. A plan does not count. |
| 25% | A prototype or narrow subset works. |
| 50% | Works in the app for a real part of the scope, with tests. |
| 75% | The full scope is implemented and tested locally; device, field or human checks are still open. |
| 100% | The full scope is implemented and validated on the reference device, in the field or by people where applicable, with evidence linked. |

Values in between are allowed when the evidence justifies them. Scores go down when a regression or a scope change exposes a gap. Anything checked only on an emulator or in widget tests is marked *unverified* and cannot reach 100%.

## Snapshot: what the app is today (audit 2026-09-26)

**Works**
- A Flutter app for **one place (Chora)**.
- A 103-scene catalogue with search and room filters.
- An on-device ONNX recogniser (live, still and gallery input; loaded only when Scan opens).
- Per-scene notes.
- Two 2.5D explorers, Anastasis (F02) and Last Judgment (F05). They offer 1–8× zoom, focus on six details each, an Original/Relief/Restored comparison, a 48-pose figure loop and reduced motion.
- `flutter analyze` is clean and 37 app tests pass, plus 2 capture tests.

**Review of the previous (İzvoya) run**
- **Kept:** the prototype above, which is real and valuable. The rigs, relief meshes and tests are solid engineering.
- **The name** was a coined word with no Istanbul meaning, and its capital İ is awkward for English speakers.
- **The logo** was four parallelograms and a diamond, with no link to the city.
- **The UI** is still the generic editorial template: eyebrow text, a big serif headline ("Stories beyond the surface."), two buttons, rounded cards, and Cormorant Garamond with DM Sans. It is exactly what makes an app look AI-made.
- **The explorer** is a control panel. Sliders, toggles and chips take about 45% of the screen.
- **The motion:** the default "Bold" figure puppetry makes painted hands and faces slide, and the default "Restored" view is a glossy AI repaint rather than the fresco.
- **The plan** was 82 KB, heavy on governance (30-person studies, consent pipelines, KPI funnels) and thin on concrete UX invention. It had no specific animation collection, and its 100% gates were out of reach for a solo developer.
- **Engineering left over:**
  - A 203.8 MB universal APK that bundles three relief generations.
  - Hard-coded `chora-ar` paths.
  - No git repository.
  - Debug-signed release builds.
  - 14 scattered Markdown files.

**Changed in P00 (this run)**
- **Identity:** renamed to **Milion**, with a new mark (an inscriptional M holding the gilded zero, porphyry/marble/tessera gold) and all identifiers and paths changed.
- **Docs:** the İzvoya-era documents are archived.
- **Plan:** a new 41-phase plan with a 48-piece Milestone collection and a design doctrine.
- **Not changed yet:** no product features. The UI is still the old template until P03 and P04.

## Dimensions

### A. Identity and design language

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D01 | Name and brand story | 60% | "Milion" is applied to the label, title, wordmark, About (the Milion story), package and app ID. | The story and tagline are in TR/EN everywhere (About, first run, store, share watermark), and 5 people can explain the name after using the app. | P00, P04, P13, P40 |
| D02 | Logo, launcher icon and splash | 70% | The mark in SVG, PNG and a Flutter painter; 5 launcher densities; adaptive and themed icons; Android 12+ splash. Mask renders checked, not on a device. | Verified on the A52s launcher (themed icon on/off, light and dark), in the store icon and on share cards. | P00, P03, P40 |
| D03 | Design tokens and component library | 10% | The old generic theme; brand colours only in the mark. | P03 system complete, with golden tests and the design sheet, and every screen using it. | P03 |
| D04 | Signature interactions | 5% | Numbered-bubble detail focus only. | The Mile Zero dial, the dig, leader-line plates, light you hold and tesserae are shipped and used consistently. | P03–P06, P19 |
| D05 | Typography | 15% | Cormorant and DM Sans, both on the banned list; Turkish works; no Greek coverage. | Inscriptional display face plus text face with Turkish and Greek, bundled and licensed, with specimens verified. | P03 |
| D06 | Iconography and illustration | 5% | Only Material icons. | The PlanIcon set, era map styles and line illustrations; no generic cultural icons. | P03, P04, P10 |
| D07 | Copy voice | 15% | Several filler lines ("Stories beyond the surface", "Countless details"). | Every line is specific and checkable, native TR and EN, and passes the §2 copy rule. | P03, P34 |

### B. Product structure

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D08 | App shell and navigation | 20% | Home, Collection, Scan and About work; not the target structure. | Today, City, Milestones and Mosaic; predictive back; state restoration; edge-to-edge. | P04 |
| D09 | First run and Today | 20% | The home screen links directly to Anastasis. | A first reveal in ≤ 10 s with no permission; Milestone 0 intro; Detail of the day; the dial. | P04, P13 |
| D10 | Place pages (the dig) | 5% | A Chora scene detail sheet only. | Every reviewed place has a dig page with strata, a visit card and sources, built purely from data. | P05 |
| D11 | Atlas | 0% | None. | Offline era-styled map with a time slider, mile rings, the Below layer and map/list parity. | P10 |
| D12 | Search and discovery | 10% | Scene title and room search within Chora. | Turkish-aware search with aliases, filters, people pages, "Surprise me" and recommendations. | P33 |
| D13 | Routes and hunts | 0% | None. | 12 routes and 6 hunts, reviewed and working offline. | P21, P26, P27, P32 |

### C. Content

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D14 | Content model and registry | 10% | A hard-coded Scene and ExplorableScene; the catalogue follows the classifier's class order. | A typed, versioned, validated registry; the validator CLI runs in CI. | P02 |
| D15 | Byzantine coverage | 5% | 1 place (Chora), deep but not fully reviewed. | ≥ 30 reviewed Byzantine places. | P11–P16 |
| D16 | Mosque coverage | 0% | None. | ≥ 30 reviewed mosques with the visiting layer. | P24–P27 |
| D17 | Museum coverage | 0% | None. | ≥ 25 reviewed museums or palaces and ≥ 25 object pages. | P28–P31 |
| D18 | 39-district coverage | 3% | 1 of 39 districts (Fatih). | 39/39 districts and ≥ 110 reviewed places. | P32 |
| D19 | Stories and writing | 10% | 103 one-line summaries plus cues. | Every reviewed place and Milestone has a story in TR and EN with hooks. | P05, P11–P32, P34 |
| D20 | Accuracy, sources, honesty labels | 20% | Capture credits in captures.json; the restoration is called "interpretive"; no sources per claim. | Every claim is sourced, every place has a QID, labels are applied everywhere and debates are marked. | P02, all content phases |
| D21 | Practical visit information | 0% | Room positions only. | Hours, access, etiquette, prayer windows and transit for every place, each with a checkedAt date. | P05, P24, P39 |
| D22 | Media library | 10% | Chora photos, plus the 5.3 GB corpus outside the repo. | ≥ 3 images per reviewed place (today and historical), all credited in the manifest. | P02, content phases |

### D. The Milestone collection (2.5D / 3D)

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D23 | 2.5D Plate engine | 35% | A relief mesh via drawVertices, a pose rig, zoom and focus, but coded for two scenes; no gyroscope, shaders, wipe or beats. | PlatePlayer with DP, GL, RL, Candle, WR, SB, MM and LU running from manifests at budget on the device. | P06, P07 |
| D24 | 2.5D production pipeline | 20% | Scene-specific Python scripts and SAM masks. | One command turns a photo into a validated plate, reproducible from the repo. | P07 |
| D25 | 2.5D Milestones approved | 5% | 0 of the ~26 2.5D pieces approved; I and II are prototypes. | Every 2.5D Milestone the ship scope needs is approved (§3 definition). | P06–P31 |
| D26 | 3D runtime | 0% | Offline PLY exports only; no runtime 3D. | SpacePlayer with orbit, section, assembly and styles, at budget on the device. | P08 |
| D27 | Procedural architecture kit | 0% | None. | The generators and spec format build every 3D building in the register. | P09 |
| D28 | 3D Milestones approved | 0% | None. | Every 3D Milestone the ship scope needs is approved. | P08–P31 |
| D29 | Motion doctrine and honesty in motion | 20% | Reduced motion, a Still pose and an "interpretive" note exist, but the defaults (Bold puppetry, AI repaint) break the doctrine. | Every Milestone follows §3: labels, the original one tap away, still-sequence equivalents, no sacred puppetry. | P06 onward |
| D30 | Light and sensors | 0% | Raking-light renders exist offline only. | Gyroscope, specular gold, candle and sun position work smoothly on the device, and gyroscope motion is opt-in. | P06, P25, P26 |

### E. Attraction and return

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D31 | Share studio and deep links | 0% | None. | Still, MP4 and WebP exports, Sharesheet, MediaStore, milion:// and https links. | P17 |
| D32 | Daily Tessera and On this day | 0% | None. | 365 Daily details and 120 dated entries; share card; optional notification. | P18 |
| D33 | Personal mosaic and Milestone book | 5% | Per-scene notes only. | Three seasonal mosaics, the passport, export/import and delete. | P19 |
| D34 | Ghost lens | 0% | None. | 30 viewpoints with alignment and diptych/swipe export. | P20 |
| D35 | Recognition (point and reveal) | 30% | 103-class ONNX works live, still and from the gallery. Rejection is weak (About admits ≤ 67% on negatives); numbers not reproduced; no reveal transition. | Open-set model meeting the P23 gates (or labelled Beta), the lock-and-reveal, multiple places. | P11, P23 |
| D36 | Audio | 0% | None. | Voices (XI and more), soundscapes, TR/EN narration with captions, interruption handling. | P22 |
| D37 | Seasonal and live moments | 0% | None. | Mahya in Ramadan, the equinox sky, live sun in Süleymaniye, prayer-aware visits. | P24–P27 |
| D38 | Launch and acquisition kit | 0% | None. | 20 clips, a 30-day calendar, a press note and a promo video, all built from real exports. | P17, P40 |

### F. Android quality

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D39 | Turkish and English localisation | 0% | UI and content are English only, with hard-coded strings. | 100% ARB and content coverage, reviewed by native readers (O08). | P03, P34 |
| D40 | Accessibility | 15% | Some semantics, a reduced-motion path, a 150%-text capture. | P35 passes on the device: TalkBack, 200% text, contrast, targets, still equivalents, captions. | P35 |
| D41 | Layouts and device classes | 30% | Widget captures at 360, 390, 430, 768 and 1440 dp. | Phone, tablet, landscape and foldable layouts verified; edge-to-edge insets. | P03, P35 |
| D42 | Performance | 10% | Lazy ONNX loading; renderer-lifetime tests; nothing measured on a device. | All P36 budgets met on the A52s. | P06, P08, P36 |
| D43 | App size and asset delivery | 5% | 203.8 MB universal APK, three relief generations bundled. | Base download ≤ 60 MB; Play Asset Delivery packs with download management. | P01, P36 |
| D44 | Offline behaviour | 40% | Everything is bundled, so all current features work offline. | Starter plus packs work offline; downloads resume; low-storage and corruption recovery. | P10, P36 |
| D45 | Lifecycle and permissions | 25% | The camera has some error handling; the explorer pauses. The merged manifest includes RECORD_AUDIO and legacy storage, which are not needed. | P37 script passes: in-context requests, denial, revocation, process death. | P01, P37 |
| D46 | Privacy and data safety | 30% | Fully local, no network, no analytics. No policy, export or delete. | Data Safety answers, TR/EN policy, export and delete, opt-in only. | P19, P37 |
| D47 | Persistence and migrations | 15% | SharedPreferences notes with no schema version. | Versioned local database with migrations tested across upgrades. | P02, P19 |
| D48 | Stability and crash reporting | 5% | No crash reporting; never run through monkey testing. | Opt-in crash and ANR reporting; a 1-hour monkey run clean; 0 crashes in the field trial. | P37, P39 |

### G. Engineering and release

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D49 | Codebase health | 35% | 9,491 lines of Dart in lib/; legacy v3 and "Classic v5" screens; 1,145-line anastasis_tab; analyzer clean. | No dead code or assets, a feature-based structure, analyzer clean, no file over about 600 lines without reason. | P01, ongoing |
| D50 | Automated tests | 30% | 37 app tests plus 2 capture tests pass. | P38 pyramid with integration tests on the device; a deliberately broken build fails. | P38, ongoing |
| D51 | Version control, reproducibility, CI | 5% | No git; hard-coded external paths; no CI. The KGP deprecation warning is fixed (built-in Kotlin plus the patched ONNX plugin). | Git with LFS, env-configured tools, pinned requirements, green CI. | P01, P38 |
| D52 | Physical device validation | 5% | Release APK installed and launched on the SM-A528B (Android 14). Plugins register and the ONNX JNI library loads with no errors. Logcat shows Impeller trying Vulkan and then OpenGLES; confirm the backend in P08. Flows not yet verified. | Every flow is verified on the A52s, plus the emulator matrix. | P06 onward, P38 |
| D53 | Release engineering | 15% | The release APK builds but is debug-signed; R8 is off. | A signed AAB with asset packs, a clean pre-launch report, a versioning scheme and staged rollout. | P01, P40 |
| D54 | Store listing | 0% | None. | TR/EN listing, 8 screenshots, feature graphic, promo video, Data Safety. | P40 |
| D55 | Field trial | 0% | None. | P39 run, with all P0 and P1 findings fixed. | P39 |
| D56 | Feedback and corrections loop | 0% | None. | In-app "Report a change", a support address (O17) and triage in the phase workflow. | P05, P37, P40 |

## Counters

| Counter | Now | Ship target |
| --- | ---: | ---: |
| Reviewed places (Byzantine / mosque / museum / other) | 0 (0 / 0 / 0 / 0). Chora exists, not reviewed. | ≥ 110 (≥ 30 / ≥ 30 / ≥ 25 / rest) |
| Districts with ≥ 1 reviewed place | 0 / 39 | 39 / 39 |
| Chora artworks complete | 0 / 103 (summaries exist; inscriptions and sources missing) | 103 / 103 |
| Milestones approved (of 48) | 0 (prototypes: I, II) | ≥ 40, all ★ |
| Routes / hunts / ghost-lens viewpoints | 0 / 0 / 0 | 12 / 6 / 30 |
| Daily pool / On-this-day entries | 0 / 0 | 365 / 120 |
| Turkish string coverage | 0% | 100% |
| App tests | 37 (+2 capture) | P38 pyramid |
| Release artifact size | 203.7 MB universal APK (203,742,562 bytes; rebuilt after the rename) | base download ≤ 60 MB |
| Manual minutes per plate | not measured | tracked from P07 |

## Phase ledger

| Phase | Status | Date | Visible result |
| --- | --- | --- | --- |
| P00 Milion identity and plan | Done | 2026-09-26 | New name, mark, launcher and splash; paths renamed; this plan. |
| P01 Clean slate | Not started | | |
| P02 Content registry and mile-zero geography | Not started | | |
| P03 Design language | Not started | | |
| P04 Shell, Today and the first ten seconds | Not started | | |
| P05 Place page: the dig | Not started | | |
| P06 Plate engine and remastered I–II | Not started | | |
| P07 Plate production line and III–V | Not started | | |
| P08 3D runtime and "How a dome stands" | Not started | | |
| P09 Procedural architecture kit | Not started | | |
| P10 The Atlas | Not started | | |
| P11 Chora, complete | Not started | | |
| P12 Hagia Sophia | Not started | | |
| P13 Hippodrome, Great Palace and the Milion | Not started | | |
| P14 Underground Constantinople | Not started | | |
| P15 The Walls and 1453 | Not started | | |
| P16 Byzantine city beyond the core | Not started | | |
| P17 Share studio and deep links | Not started | | |
| P18 Daily Tessera and On this day | Not started | | |
| P19 Personal mosaic and Milestone book | Not started | | |
| P20 Ghost lens | Not started | | |
| P21 Routes and hunts | Not started | | |
| P22 Voices | Not started | | |
| P23 Point and reveal | Not started | | |
| P24 Mosque layer and craft kit | Not started | | |
| P25 Süleymaniye | Not started | | |
| P26 Sinan's Istanbul | Not started | | |
| P27 Imperial to contemporary mosques | Not started | | |
| P28 Museum kit and Archaeology Museums | Not started | | |
| P29 Topkapı and the palaces | Not started | | |
| P30 Collections of the city | Not started | | |
| P31 Scattered: Istanbul abroad | Not started | | |
| P32 Every district has a layer | Not started | | |
| P33 Discovery at scale | Not started | | |
| P34 Turkish and English, complete | Not started | | |
| P35 Accessibility | Not started | | |
| P36 Performance, size, asset delivery | Not started | | |
| P37 Reliability, permissions, privacy | Not started | | |
| P38 Tests, CI, device matrix | Not started | | |
| P39 Field trial | Not started | | |
| P40 Store launch and release | Not started | | |

## Changelog

- **2026-09-26, P00 follow-up: the mark.** The dome-on-pendentives mark read as a camera aperture, so it was replaced by an inscriptional M holding the gilded zero of the Milion stone (M + 0, mile zero). `tool/build_milion_identity.py` rebuilt the SVG, brand PNG, five launcher densities, adaptive/themed icons, splash and web icons; `MilionMark` in `lib/theme/milion_theme.dart` matches the same 64-unit geometry. Home previews refreshed in `ui_refresh/previews/`; analyzer clean and 37/37 tests pass.
- **2026-09-26, P00.**
  - **Identity:** İzvoya became **Milion**, with the new mark, launcher, themed icon and splash (`tool/build_milion_identity.py`). Identifiers moved to `app.milion` and package `milion`; the workspace moved to `/Users/memre/Desktop/milion`.
  - **Docs:** the old plan and READMEs were archived; the new PHASES.md (P00–P40, the 48-piece register, the doctrine, 18 open issues) and this file were written.
  - **Scores:** D01 → 60% and D02 → 70% from the implementation. All other dimensions set by the audit; the overall score starts at 11.9%.
  - **Verification:**
    - Analyzer clean and 37/37 tests passing, both in the new workspace.
    - Release APK rebuilt after a clean: 203.7 MB; `aapt` shows package `app.milion`, label `Milion`, min SDK 24 / target 36.
    - Merged permissions still include CAMERA, RECORD_AUDIO, legacy storage and ACCESS_NETWORK_STATE (P01 removes the unneeded ones).
    - Home wordmark rendered to `ui_refresh/previews/`; icon checked under circle, squircle and square masks.
  - **Next:** P01.
- **2026-09-26, P00 follow-up: Kotlin Gradle Plugin warning.**
  - **Fix:** `flutter run` warned that `flutter_onnxruntime` applies KGP, which future Flutter versions will reject. The plugin is already at its latest release (1.8.5), so the app now uses built-in Kotlin (`android.builtInKotlin=true`) and a patched local copy of the plugin without the KGP line (PHASES.md Decisions, O19).
  - **Verification:** release build with no warning; analyzer clean; 37/37 tests passing; installed and launched on the SM-A528B, with plugin registration and ONNX JNI load both OK.
  - **Scores:** O01 resolved; D52 0% → 5%; overall 11.9% → 12.0%.
  - **Still to check:** open Scan on the phone once to confirm inference; the phone was locked, so it could not be automated.
