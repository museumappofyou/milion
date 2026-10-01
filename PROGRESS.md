# Milion — Progress

**Updated 2026-10-01, after P04. Overall readiness: 28.1%.** This is the mean of the 56 dimensions below: 1,576 points out of 5,600.

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

## Snapshot: what the app is today (updated 2026-10-01)

**Works**
- A four-instrument shell: **Today** (Detail of the day → its Milestone, the Mile Zero dial, mosaic strip, Byzantine chapter), **City** (111 checked points by mil distance), **Milestones** (the 48-piece register) and **Mosaic** (notes until P19). A 12-second Milestone 0 lite plays on first launch.
- A Flutter app with the **Chora preview** and a 155-place draft registry.
- A 103-artwork Chora catalogue with search and room filters, loaded independently of the classifier.
- An on-device ONNX recogniser (live, still and gallery input), reached from the camera-eye action on Chora and loaded only then.
- Per-scene notes.
- Two lamp-only 2.5D explorers, Anastasis (F02) and Last Judgment (F05): original first, 1–8× zoom, six details, localized honesty labels, depth/reconstruction comparisons and an optional single gentle IMAGINED gesture. No looping figure motion.
- Marble/lamp design system, three offline fonts, 13 plan symbols and EN/TR UI with a saved language override. Debug About: long-press the wordmark for `/design`, the version for Registry.
- `flutter analyze`, 166 app tests (105 goldens), 11 capture tests, content validation and release APK/AAB builds pass. Emulator checks cover startup, predictive back and TalkBack; physical checks remain unverified.

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

**Changed in P01 (this run)** — see the size table under Changelog.
- **Version control:** `git init` with the "P01 baseline" commit made before any deletion, then pushed to `origin` (`museumappofyou/milion`, SSH). `.gitignore` covers `build/`, `.dart_tool/`, `android/.gradle`, `android/.kotlin`, `local.properties`, `key.properties`, `*.jks`, `studio/cache/`, `tool/**/__pycache__/`.
- **Pruned runtime:** the v3 conch relief (service, geometry, dome view, tab, manifest), the Classic v5 viewers, v1 figure data, the earlier restoration studies and 26 MB of `relief`/`relief_v3` textures are gone; every source photograph is kept. One explorer path per Milestone remains, with Original/Relief/Restored.
- **Studio:** `anastasis_25d/`, `last_judgment_25d/`, `figure_animation/`, `restoration_studies/`, `ui_refresh/` moved under `studio/`; the three surviving capture tests moved to `tool/captures/`; all script and test paths fixed. `MILION_CAPTURES` replaces the hard-coded corpus paths.
- **Android:** minSdk 26; R8 and resource shrinking on for release with ONNX keep rules (camera + ONNX verified in a release build on the Pixel Fold API 36 emulator); release signing reads `android/key.properties` when present and otherwise warns loudly and falls back to debug; RECORD_AUDIO and legacy storage permissions removed and `aapt`-verified; per-ABI APKs via `tool/build_android.sh`.
- **Not changed yet:** the UI, content and engines; P02–P06 as planned.

**Changed in P02 (this run)**
- **Content:** one schema-versioned registry, 155 hidden draft places with QIDs and EN/TR hooks, 103 migrated Chora Artworks, and prototype Milestones I–II. Category and district counts include drafts; reviewed and approved counts remain zero.
- **Geography:** cited Milion origin, great-circle km/Roman miles and true bearing, checked against GeographicLib and independent vector geometry. Province bounds and outside flags are validated.
- **Demo:** in a debug build, long-press the version in About to open Registry. It lists places by distance and counts all categories and districts. EN/TR vertical stills are in `studio/captures/P02/`.
- **Preserved:** all existing scene IDs and note text. The 863 missing Turkish artwork fields remain explicit translation debt; new place hooks are bilingual. Device, entrances and current access checks remain unverified.

**Changed in P03 (this run)**
- **Design:** Porphyry & Tessera tokens and components; squared, flat screens; Original-first artwork views. Direction B (marble with porphyry) is the default, with lamp available in About and compulsory for artworks. Home’s old hero formula is removed.
- **Type:** rendered all 11 candidates before selecting Cinzel / Noto Serif Display Greek fallback and Noto Sans; OFLs, source hashes and glyph audit are recorded. Cormorant and DM Sans removed.
- **Language/accessibility:** 229 EN/TR ARB keys, persisted override, 4.65:1 minimum tested body/action contrast, 100/200% text captures at 360/390/430 dp. O07 taste check, O08 native review and device TalkBack/haptics remain open.
- **Evidence:** `studio/captures/P03/`, `test/goldens/P03/`, `test/design/`, `tool/design/`. No place was reviewed or Milestone approved; P04/P05/P06 own the layout and engine redesigns.

**Changed in P04 (this run)**
- **Shell:** Today/City/Milestones/Mosaic with PlanIcons. Scan became a camera-eye action. Predictive back, state restoration, edge-to-edge, and no visible loading (the first frame waits for content).
- **First ten seconds:** Milestone 0 lite (tessera → Milion pillar → OSM street plan → peninsula → Roman-mile rings → five places → “Every road started here.”), with stills and a TalkBack sentence. Today opens a sourced Chora detail straight into its Milestone.
- **Content:** a `details` kind (17 EN/TR details), the full 48-piece register, and 111 checked draft points plotted without their unreviewed claims (a plan change; see PHASES Decisions).
- **Evidence:** `studio/captures/P04/` (first-run clip, three Detail-of-the-day stills, phone layouts, emulator startup/back/TalkBack), `test/goldens/P04/`. The reference device was not connected.

## Dimensions

### A. Identity and design language

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D01 | Name and brand story | 70% | EN/TR Milion story in About, app title and the first run: Milestone 0 lite ends on “Every road started here.” and About replays it (`lib/first_run/`). Store/share watermark and human recall remain open. | The story and tagline are in TR/EN everywhere (About, first run, store, share watermark), and 5 people can explain the name after using the app. | P00, P04, P13, P40 |
| D02 | Logo, launcher icon and splash | 70% | The mark in SVG, PNG and a Flutter painter; 5 launcher densities; adaptive and themed icons; Android 12+ splash. Mask renders checked, not on a device. | Verified on the A52s launcher (themed icon on/off, light and dark), in the store icon and on share cards. | P00, P03, P40 |
| D03 | Design tokens and component library | 75% | Marble/lamp tokens, 4-dp grid, ≤2-dp shapes, wave pigments, 30 component specimens and 60 passing goldens in `lib/design/` and `test/goldens/P03/`. Hidden `/design` shows both schemes at 100/200%; every current screen reskinned. Device/taste check remains open. | P03 system complete, with golden tests and the design sheet, and every screen using it. | P03 |
| D04 | Signature interactions | 45% | The Mile Zero dial ships on Today (`lib/today/mile_zero_dial.dart`): a fixed plate of logarithmic Roman-mile rings and the OSM coastline, a rotating rete with light-haptic detents, turn-only-on-circular-drag, TalkBack adjustable actions and a list alternative. Today's detail carries a hairline leader line; the register, strip and Mosaic use outlined/set tessera slots. Dig, plates and light remain P05/P06. | The Mile Zero dial, the dig, leader-line plates, light you hold and tesserae are shipped and used consistently. | P03–P06, P19 |
| D05 | Typography | 75% | 11 rendered candidates in `studio/captures/P03/type-{display,text}.png`; Cinzel + Noto Serif Display Greek fallback, Noto Sans body/tabular numerals. Three offline fonts/OFLs registered; `tool/design/audit_fonts.py` verifies hashes and TR/Greek glyphs, including Ϲ. Physical rendering unverified. | Inscriptional display face plus text face with Turkish and Greek, bundled and licensed, with specimens verified. | P03 |
| D06 | Iconography and illustration | 60% | 28 custom PlanIcons: P03's 13, plus 15 in P04 (dial, milestone stele, one glyph per §3 technique code), all golden-tested in `test/goldens/P04/`. Navigation, register techniques and City categories use them. Generic back/search/zoom remain platform symbols; era map styles remain P10. | The PlanIcon set, era map styles and line illustrations; no generic cultural icons. | P03, P04, P10 |
| D07 | Copy voice | 50% | 17 Detail-of-the-day sentences, each a single checkable sentence fact-checked against Underwood (DOP 1956/1958), Ousterhout (2002), Smarthistory and the Kültür Envanteri guide; four candidate claims were corrected. EN+TR register titles; a P04 test scans the pool for the §2 filler words. Native review remains O08. | Every line is specific and checkable, native TR and EN, and passes the §2 copy rule. | P03, P34 |

### B. Product structure

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D08 | App shell and navigation | 75% | Four PlanIcon destinations (`lib/shell/app_shell.dart`); Scan is now a camera-eye action on the Chora place page, catalogue and artwork sheets. `IndexedStack` plus restoration of tab, scroll offsets and dial state across `restartAndRestore`. Back goes to Today, then exits. Predictive back (manifest opt-in + `PredictiveBackPageTransitionsBuilder`) previews pages on the Android 14 emulator (`studio/captures/P04/predictive-back-a14.mp4`). Edge-to-edge insets; 18 shell tests. A52s check open (O01). | Today, City, Milestones and Mosaic; predictive back; state restoration; edge-to-edge. | P04 |
| D09 | First run and Today | 75% | Milestone 0 lite first run: 12 s, skippable after 2 s, three reduced-motion stills, a TalkBack sentence; replay in About. Today: Detail of the day with a shared element into the Milestone, the Mile Zero dial and its list, the mosaic strip, the Byzantine chapter; the 17-detail pool rotates by date. Profile cold start to an interactive Today on the Android 14 emulator: median 1,067 ms (trace) / 1,276 ms (`am start -W`), in `startup.json`. Clip: `studio/captures/P04/first-run.mp4`. Reference device and human first-impression checks open. | A first reveal in ≤ 10 s with no permission; Milestone 0 intro; Detail of the day; the dial. | P04, P13 |
| D10 | Place pages (the dig) | 10% | A minimal present-day place page (`lib/city/place_screen.dart`): checked name, historical names, mil distance and bearing, review state, Milestones, artworks, sources and camera-eye. The data-driven dig remains P05. | Every reviewed place has a dig page with strata, a visit card and sources, built purely from data. | P05 |
| D11 | Atlas | 0% | None. | Offline era-styled map with a time slider, mile rings, the Below layer and map/list parity. | P10 |
| D12 | Search and discovery | 10% | Scene title and room search within Chora. | Turkish-aware search with aliases, filters, people pages, "Surprise me" and recommendations. | P33 |
| D13 | Routes and hunts | 0% | None. | 12 routes and 6 hunts, reviewed and working offline. | P21, P26, P27, P32 |

### C. Content

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D14 | Content model and registry | 75% | Schema 1 registry in `lib/content/` with the additive `details` kind and optional Milestone `flagship`; 48 register records, 17 details, 213 sources. `dart run tool/content/validate.dart` passes. The catalogue loads without ONNX. CI remains P38. | A typed, versioned, validated registry; the validator CLI runs in CI. | P02 |
| D15 | Byzantine coverage | 10% | 52 Byzantine-category drafts with pinned Wikidata/OSM evidence in `assets/content/places/istanbul.json`; 0 reviewed. Existing Chora preview retained. | ≥ 30 reviewed Byzantine places. | P11–P16 |
| D16 | Mosque coverage | 10% | 39 mosque-category drafts, including layered former churches; bilingual names/hooks and QIDs. No visiting layer or field review yet. | ≥ 30 reviewed mosques with the visiting layer. | P24–P27 |
| D17 | Museum coverage | 10% | 33 museum and 15 palace category assignments (overlap); QID-backed drafts only. Object extension remains P28. | ≥ 25 reviewed museums or palaces and ≥ 25 object pages. | P28–P31 |
| D18 | 39-district coverage | 10% | 155 drafts across 22/39 Istanbul districts plus 9 explicitly outside-province records; all 39 district enum values and zero counts tested. 0 reviewed districts. | 39/39 districts and ≥ 110 reviewed places. | P32 |
| D19 | Stories and writing | 18% | 155 seed hooks plus 17 sourced EN/TR Detail-of-the-day sentences; legacy Chora English text preserved. Full stories and native review remain open. | Every reviewed place and Milestone has a story in TR and EN with hooks. | P05, P11–P32, P34 |
| D20 | Accuracy, sources, honesty labels | 50% | P02 source/QID evidence retained. P04 adds 7 detail citations (Underwood DOP reports, Ousterhout 2002, Smarthistory, KE parekklesion guide, Revelation 6:14, Daniel 7:10). Today carries honesty labels, the register shows ORIGINAL → furthest-state ranges, and draft places show only checked fields. Wave claim review and approval remain open; the Anastasis master photo's source URL is unrecorded (O22). | Every claim is sourced, every place has a QID, labels are applied everywhere and debates are marked. | P02, all content phases |
| D21 | Practical visit information | 5% | Typed entrance, current function and dated visit status. Unverified drafts explicitly use null entrance and unknown status; validation prevents undated known status and incomplete reviewed records. | Hours, access, etiquette, prayer windows and transit for every place, each with a checkedAt date. | P05, P24, P39 |
| D22 | Media library | 15% | 2 typed, credited reference media with source URLs, original and bundled SHA-256 hashes in `tool/content/media_hashes.json`; originals unchanged. Full image library remains open. | ≥ 3 images per reviewed place (today and historical), all credited in the manifest. | P02, content phases |

### D. The Milestone collection (2.5D / 3D)

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D23 | 2.5D Plate engine | 35% | One maintained explorer path per scene (mesh/rig, 1–8× zoom, six details); P03 uses localized Original/Depth/Reconstruction controls and margin callouts. No manifest-driven PlatePlayer, gyroscope, shaders, local wipe or story beats yet. | PlatePlayer with DP, GL, RL, Candle, WR, SB, MM and LU running from manifests at budget on the device. | P06, P07 |
| D24 | 2.5D production pipeline | 20% | Scene-specific Python scripts and SAM masks. | One command turns a photo into a validated plate, reproducible from the repo. | P07 |
| D25 | 2.5D Milestones approved | 5% | 0 of the ~26 2.5D pieces approved; I and II are prototypes. | Every 2.5D Milestone the ship scope needs is approved (§3 definition). | P06–P31 |
| D26 | 3D runtime | 0% | Offline PLY exports only; no runtime 3D. | SpacePlayer with orbit, section, assembly and styles, at budget on the device. | P08 |
| D27 | Procedural architecture kit | 0% | None. | The generators and spec format build every 3D building in the register. | P09 |
| D28 | 3D Milestones approved | 0% | None. | Every 3D Milestone the ship scope needs is approved. | P08–P31 |
| D29 | Motion doctrine and honesty in motion | 50% | Original-first explorers as in P03. Milestone 0 lite has a still-sequence and a one-sentence TalkBack equivalent, and cannot flip back into motion mid-sequence. On Today no figure moves: a still crop and a camera-only shared element. P06 owns story beats and masked wipes. | Every Milestone follows §3: labels, the original one tap away, still-sequence equivalents, no sacred puppetry. | P06 onward |
| D30 | Light and sensors | 0% | Raking-light renders exist offline only. | Gyroscope, specular gold, candle and sun position work smoothly on the device, and gyroscope motion is opt-in. | P06, P25, P26 |

### E. Attraction and return

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D31 | Share studio and deep links | 0% | None. | Still, MP4 and WebP exports, Sharesheet, MediaStore, milion:// and https links. | P17 |
| D32 | Daily Tessera and On this day | 5% | A date-deterministic rotation (`detailOfDay`) and a 17-detail curated pool exist for Today. The Daily Tessera game, On-this-day entries and share card remain P18. | 365 Daily details and 120 dated entries; share card; optional notification. | P18 |
| D33 | Personal mosaic and Milestone book | 10% | Saved notes are listed in the Mosaic placeholder. A provisional 48-slot strip and grid sets a tessera per opened Milestone (`milion_opened_milestones`, imported by P19). Seasonal mosaics, passport and export remain P19. | Three seasonal mosaics, the passport, export/import and delete. | P19 |
| D34 | Ghost lens | 0% | None. | 30 viewpoints with alignment and diptych/swipe export. | P20 |
| D35 | Recognition (point and reveal) | 30% | 103-class ONNX works live, still and from the gallery. Rejection is weak (About admits ≤ 67% on negatives); numbers not reproduced; no reveal transition. | Open-set model meeting the P23 gates (or labelled Beta), the lock-and-reveal, multiple places. | P11, P23 |
| D36 | Audio | 0% | None. | Voices (XI and more), soundscapes, TR/EN narration with captions, interruption handling. | P22 |
| D37 | Seasonal and live moments | 0% | None. | Mahya in Ramadan, the equinox sky, live sun in Süleymaniye, prayer-aware visits. | P24–P27 |
| D38 | Launch and acquisition kit | 0% | None. | 20 clips, a 30-day calendar, a press note and a promo video, all built from real exports. | P17, P40 |

### F. Android quality

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D39 | Turkish and English localisation | 50% | 313/313 UI keys in EN/TR (84 added in P04, including the TR “Taş” numeral label). All new content is bilingual: 17 details, 48 register titles, sources. Content stands at 1,184/2,047 TR fields; the 863 missing are legacy Chora text. Native review O08. | 100% ARB and content coverage, reviewed by native readers (O08). | P03, P34 |
| D40 | Accessibility | 55% | TalkBack 16 on the Android 14 emulator completes the first run and opens Today's detail (`device-talkback-*.png`). The dial exposes adjustable increase/decrease/tap semantics and a list alternative (widget-tested). 200% EN/TR layouts at 360 dp hold for all four tabs; reduced motion shows three stills. Physical TalkBack, speech and haptics unverified (P35). | P35 passes on the device: TalkBack, 200% text, contrast, targets, still equivalents, captions. | P35 |
| D41 | Layouts and device classes | 55% | P04 captures at 360/390/430 dp, EN/TR, 100/200% for Today and every tab (`studio/captures/P04/`). Edge-to-edge checked on the Android 14 phone AVD (1080×2400) and the Pixel Fold folded posture. Physical devices, tablets and rotation unverified. | Phone, tablet, landscape and foldable layouts verified; edge-to-edge insets. | P03, P35 |
| D42 | Performance | 25% | Profile cold start to an interactive Today on the Android 14 emulator: trace median 1,067 ms, `am start -W` COLD median 1,276 ms (`studio/captures/P04/startup.json`). The first frame is deferred until content is ready; ONNX loads lazily. Nothing measured on the A52s. | All P36 budgets met on the A52s. | P06, P08, P36 |
| D43 | App size and asset delivery | 30% | P04: arm64 release APK 92,443,715 bytes, AAB 138,752,586 bytes (+0.40/+1.23 MB vs P03: OSM lines, register, details, glyphs). R8/resource shrinking on; base download still above the 60 MB target (P36). | Base download ≤ 60 MB; Play Asset Delivery packs with download management. | P01, P36 |
| D44 | Offline behaviour | 40% | All current content, textures, three selected fonts, UI translations and font licences are bundled. P03 has no network font dependency; download/pack failure paths remain P10/P36. | Starter plus packs work offline; downloads resume; low-storage and corruption recovery. | P10, P36 |
| D45 | Lifecycle and permissions | 40% | Release `aapt` permissions unchanged: CAMERA + ACCESS_NETWORK_STATE (`studio/captures/P04/release.txt`). The camera is reached only from the camera-eye action: after the first run and Today, emulator `dumpsys` shows CAMERA granted=false. The first-run clock pauses with the app lifecycle. P37 script open. | P37 script passes: in-context requests, denial, revocation, process death. | P01, P37 |
| D46 | Privacy and data safety | 30% | Fully local, no network, no analytics. No policy, export or delete. | Data Safety answers, TR/EN policy, export and delete, opt-in only. | P19, P37 |
| D47 | Persistence and migrations | 40% | Notes migration as in P02. P04 persists the first-run flag and the opened-Milestones set, and Flutter state restoration (tab, scroll, dial) is tested with `restartAndRestore`. SQLite/import/export remain P19. | Versioned local database with migrations tested across upgrades. | P02, P19 |
| D48 | Stability and crash reporting | 5% | No crash reporting; never run through monkey testing. | Opt-in crash and ANR reporting; a 1-hour monkey run clean; 0 crashes in the field trial. | P37, P39 |

### G. Engineering and release

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D49 | Codebase health | 65% | Feature folders `lib/{shell,today,city,milestones,mosaic,first_run}`; the old home/frontier pages are removed. Analyzer clean. 9,868 authored + 4,113 generated localization + 31 generated OSM lines (14,012 total). The 839-line explorer keeps one path until P06. | No dead code or assets, a feature-based structure, analyzer clean, no file over about 600 lines without reason. | P01, ongoing |
| D50 | Automated tests | 65% | 166 app tests pass, 105 of them goldens (60 P03 + 45 P04): shell, first-run modes, Today, dial gestures/haptics/semantics, back, restoration, 200% text, content pool/register/rotation. 11 opt-in capture tests in `tool/captures/` pass. Device integration and CI remain P38. | P38 pyramid with integration tests on the device; a deliberately broken build fails. | P38, ongoing |
| D51 | Version control, reproducibility, CI | 55% | Reproducible P04 builders with pinned inputs: `tool/first_run/build_peninsula.py` (Overpass responses + SHA-256 in `studio/first_run/`), `tool/content/build_register.py` and `tool/content/build_details.py`. `build_seed.py` still rebuilds the place data byte for byte. CI and LFS remain open. | Git with LFS, env-configured tools, pinned requirements, green CI. | P01, P38 |
| D52 | Physical device validation | 8% | The SM-A528B was not connected in P02–P04. An emulator matrix has begun: an Android 14 phone AVD (startup, first run, predictive back, TalkBack, permissions) and the Android 16 Pixel Fold (startup). All of it is unverified on the device. | Every flow is verified on the A52s, plus the emulator matrix. | P06 onward, P38 |
| D53 | Release engineering | 40% | P01: R8 + resource shrinking on with `proguard-rules.pro` keep rules, proven by a release build; minSdk 26; per-ABI APKs (`tool/build_android.sh`), P03 APK/AAB builds in `studio/captures/P03/release.txt`; signing reads `key.properties` or warns loudly and falls back to debug. No keystore yet (O05) and no staged rollout. | A signed AAB with asset packs, a clean pre-launch report, a versioning scheme and staged rollout. | P01, P40 |
| D54 | Store listing | 0% | None. | TR/EN listing, 8 screenshots, feature graphic, promo video, Data Safety. | P40 |
| D55 | Field trial | 0% | None. | P39 run, with all P0 and P1 findings fixed. | P39 |
| D56 | Feedback and corrections loop | 0% | None. | In-app "Report a change", a support address (O17) and triage in the phase workflow. | P05, P37, P40 |

## Counters

| Counter | Now | Ship target |
| --- | ---: | ---: |
| Reviewed places (Byzantine / mosque / museum / other) | 0 (0 / 0 / 0 / 0). Chora exists, not reviewed. | ≥ 110 (≥ 30 / ≥ 30 / ≥ 25 / rest) |
| Districts with ≥ 1 reviewed place | 0 / 39 (drafts in 22 / 39) | 39 / 39 |
| Draft places with verified QIDs | 155 / 155; 146 inside province, 9 flagged outside | reviewed by their wave phases |
| Chora artworks complete | 0 / 103 complete; 103 / 103 migrated (guide source linked; detailed stories, inscriptions and TR still missing) | 103 / 103 |
| Milestones approved (of 48) | 0 (prototypes: I, II; 46 planned; all 48 in the register, 9 ★) | ≥ 40, all ★ |
| Routes / hunts / ghost-lens viewpoints | 0 / 0 / 0 | 12 / 6 / 30 |
| Daily pool / On-this-day entries | 0 / 0 published; 3 / 3 authoring drafts | 365 / 120 |
| Detail-of-the-day pool | 17 (9 Anastasis, 8 Last Judgment), EN+TR, each sourced and date-rotated | ≥ 14 (P04), grows with each Milestone |
| Places plotted on the dial and City | 111 checked points (0 reviewed); 44 excluded: 28 area, 6 representative-point, 1 contested, 9 outside the province | every reviewed place |
| Turkish string coverage | UI: 313 / 313 ARB keys (native review pending). Content: 1,184 / 2,047 fields (57.8%); 155 / 155 place names/hooks; 17 / 17 details; 48 / 48 register titles | 100% reviewed |
| App tests | 166 pass, including 105 goldens; 11 capture tests pass | P38 pyramid |
| Design specimens / custom plan symbols / offline fonts | 50 × 2 schemes (P04 adds 15 symbols, 3 slot states, flagship, honesty range) / 28 / 3 | consistent on all screens |
| Dart lines in lib/ | 14,012 total = 9,868 authored + 4,113 generated localization + 31 generated OSM (P03: 9,189) | lean, no dead code |
| Release artifact size | 92,443,715 bytes arm64 APK; 138,752,586 bytes AAB. P03: 92,042,772 / 137,525,824 bytes | base download ≤ 60 MB |
| Manual minutes per plate | not measured | tracked from P07 |

## Phase ledger

| Phase | Status | Date | Visible result |
| --- | --- | --- | --- |
| P00 Milion identity and plan | Done | 2026-09-26 | New name, mark, launcher and splash; paths renamed; this plan. |
| P01 Clean slate | Done | 2026-09-27 | Git baseline + phase commits; runtime pruned (v3 conch, Classic v5, 26 MB relief, v1 data); `studio/` reorg; `MILION_CAPTURES`; R8 release verified with camera + ONNX; arm64 APK 89.7 MB (from 203.7 MB). |
| P02 Content registry and mile-zero geography | Done | 2026-09-27 | Debug About version long-press → Registry; 155 QID drafts sorted by mil distance, 103 Chora artworks, notes preserved. EN/TR and district captures: `studio/captures/P02/`. |
| P03 Design language | Done | 2026-09-28 | Porphyry & Tessera, offline Cinzel/Noto, 13 PlanIcons, 60 goldens, bilingual settings; hidden `/design`; A/B and 360/390/430-dp captures in `studio/captures/P03/`. |
| P04 Shell, Today and the first ten seconds | Done | 2026-10-01 | Four-instrument shell. Milestone 0 lite first run (`studio/captures/P04/first-run.mp4`). Today: Detail of the day (17-detail pool, shared element into the Milestone), Mile Zero dial and list, mosaic strip, chapter. 48-piece register. Profile cold start to Today 1.07 s on the Android 14 emulator. |
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

- **2026-10-01, P04 — Shell, Today and the first ten seconds.** The shell is Today/City/Milestones/Mosaic with PlanIcons; Scan became a camera-eye action. Predictive back, restoration and edge-to-edge are in, and the first frame waits for content. Milestone 0 lite: a 12 s first run with Skip after 2 s, three stills and a TalkBack sentence. Today: a 17-detail sourced Chora pool with a shared element into Milestone I/II, the Mile Zero dial plus list, the mosaic strip and the Byzantine chapter. Content: the 48-piece register and a `details` kind; 111 checked draft points are plotted (a plan change, PHASES Decisions); 15 new glyphs; 84 new EN/TR keys. Checks: `flutter analyze`; `flutter test` (166, incl. 105 goldens); 11 capture tests; `dart run tool/content/validate.dart`; `bash tool/build_android.sh`; release `aapt` (CAMERA + ACCESS_NETWORK_STATE). Emulator: Android 14 AVD, profile cold start to Today median 1,067 ms trace / 1,276 ms `am start -W`; first-run clip; predictive back; TalkBack completes the first run and opens Today's detail; CAMERA not granted after first run. Evidence: `studio/captures/P04/{analyze,tests,captures,validator,release,devices}.txt`, `startup.json`, `first-run.mp4`, `predictive-back-a14.mp4`, `detail-of-the-day-2026-10-0{1,2,3}.png`, `device-*.png`, phone layouts; `test/goldens/P04/`; OSM inputs in `studio/first_run/`. Scores: D01 65 → 70; D04 25 → 45; D06 50 → 60; D07 45 → 50; D08 25 → 75; D09 25 → 75; D10 5 → 10; D19 15 → 18; D20 45 → 50; D29 45 → 50; D32 0 → 5; D33 5 → 10; D39 45 → 50; D40 40 → 55; D41 45 → 55; D42 10 → 25; D45 35 → 40; D47 35 → 40; D50 60 → 65; D51 50 → 55; D52 5 → 8. Assessed unchanged: D14 75 (additive kinds; CI still open); D15–D18 and D25 (no review/approval); D22 15 (no new media; O22 provenance gap found); D23 35 (explorer opens at a window; no PlatePlayer); D35 30 (placement only); D43 30 (+0.4 MB arm64); D44 40 (still fully bundled); D49 65 (feature folders; explorer still 839 lines); D53 40 (no signing change). Overall **23.9% → 28.1%** (1,576/5,600). The SM-A528B was not connected: physical figures are **unverified**.

- **2026-09-28, P03 — Porphyry & Tessera.** Marble/lamp tokens, 13 plan symbols, 30 specimens with 60 passing goldens, 11 rendered font candidates → three licensed offline fonts, 229 EN/TR UI keys and saved language/scheme settings; flat reskin removes the hero, pill navigation and looping figure motion. Direction B selected; `/design` via About wordmark long-press. `flutter analyze`, `flutter test` (99), 10 capture tests, `dart run tool/content/validate.dart`, font audit and `bash tool/build_android.sh` pass. Evidence: `studio/captures/P03/{analyze,tests,captures,design-captures,type-motion-captures,validator,release,font-audit,devices}.txt`, `contrast.json` (minimum 4.65:1), `font-coverage.json`, `direction-{A,B}-390.png`, width/language/text-size captures, `test/goldens/P03/`; implementation in `lib/design/`, `lib/l10n/`, reskinned screens. Scores: D01 60 → 65; D03 10 → 75; D04 5 → 25; D05 15 → 75; D06 5 → 50; D07 15 → 45; D08 20 → 25; D09 20 → 25; D20 35 → 45; D29 20 → 45; D39 5 → 45; D40 15 → 40; D41 30 → 45; D47 30 → 35; D49 60 → 65; D50 45 → 60; D51 45 → 50. Assessed unchanged: D02 70 → 70 (same launcher/splash); D10 5 → 5, D12 10 → 10 (reskin, no dig/search expansion); D14 75 → 75, D19 15 → 15, D22 15 → 15, D25 5 → 5 (no content review/new media/approval); D23 35 → 35 (prototype controls, no PlatePlayer); D35 30 → 30 (no recognition-quality measurement); D42 10 → 10, D43 30 → 30, D44 40 → 40, D45 35 → 35, D52 5 → 5 and D53 40 → 40 (offline fonts and release verified; device, permissions, PAD and signing gates remain). Overall **17.1% → 23.9%** (1,340/5,600). O07 taste/O08 native review non-blocking for P03; no device connected, physical checks **unverified**; O05 debug signing fallback remains.

- **2026-09-27, P02 — content registry and mile-zero geography.** Schema 1, 155 QID-backed draft places (22 Istanbul districts + 9 outside), 103 Chora Artworks, I–II prototypes, independent catalogue, preserved notes and bilingual debug Registry. `flutter analyze`, `flutter test` (33), Registry capture, content CLI and APK/AAB release builds pass; invalid fixture exits 1. Evidence: `studio/captures/P02/{analyze,tests,capture,validator,fixture-valid,fixture-invalid,release,evidence-audit}.txt`, `registry-en.png`, `registry-tr.png`, `registry-districts.png`; data provenance and phase-name coverage in `tool/content/`. Scores: D14 10 → 75; D15 5 → 10; D16 0 → 10; D17 0 → 10; D18 3 → 10; D19 10 → 15; D20 20 → 35; D21 0 → 5; D22 10 → 15; D39 0 → 5; D47 15 → 30; D49 55 → 60; D50 35 → 45; D51 40 → 45. Overall **14.2% → 17.1%** (960/5,600). Assessed unchanged: D05 15 → 15 and D07 15 → 15 (legacy fonts/copy await P03); D08 20 → 20 (debug entry only); D13 0 → 0 (models only); D25 5 → 5 (no approvals); D32 0 → 0 (authoring drafts only); D33 5 → 5 (notes only); D35 30 → 30 (mapping change, no new recognition measurement); D41 30 → 30 (widget captures only); D42 10 → 10, D43 30 → 30, D44 40 → 40, D52 5 → 5 and D53 40 → 40 (no device/PAD/signing change). No physical device connected: on-device checks **unverified**; O05 debug signing fallback remains.

- **2026-09-27, P01 — clean slate.** Baseline commit `d219ca4` (made before any deletion) and the P01 commits; the runtime now has one explorer path per Milestone; `studio/` holds the authoring trees and `tool/captures/` the capture tests; `MILION_CAPTURES` replaces the hard-coded corpus paths; R8 + resource shrinking ship with proven ONNX keep rules; minSdk 26; signing falls back to debug with a loud Gradle warning; RECORD_AUDIO and legacy storage are gone (`aapt`-verified); analyzer clean and 20 + 3 tests green. Artifact sizes:

  | Artifact | Before (2026-09-26) | After P01 (2026-09-27) | Change |
  | --- | ---: | ---: | ---: |
  | Universal APK (release) | 203.7 MB / 203,742,562 B | not built (AAB is the release artifact) | — |
  | arm64 APK (release) | — | 89.7 MB / 89,695,631 B | **−56.0% vs the universal baseline** |
  | AAB (release) | — | 134.3 MB / 134,331,439 B | — |
  | Dart lines in lib/ | 14,012 total = 9,868 authored + 4,113 generated localization + 31 generated OSM (P03: 9,189) | lean, no dead code |

  Evidence: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`, `build/app/outputs/bundle/release/app-release.aab`, `aapt dump permissions` (CAMERA + ACCESS_NETWORK_STATE only), emulator release captures in `studio/captures/P01/`, `flutter analyze` clean, `flutter test` 20/20 + 3 capture tests. The placeholder `README.md` added with the GitHub repo was removed again (P00's two-Markdown rule).

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
