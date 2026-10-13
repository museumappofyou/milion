# Milion — Progress

**Updated 2026-10-13, after P08. Overall readiness: 36.1%.** This is the mean of the 56 dimensions below: 2,022 points out of 5,600. This is release readiness, not a count of completed phases.

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

## Current checkpoint: P08 implemented locally; device acceptance open (2026-10-13)

**Where we are.** Stage B (Engines) is under way: P00–P08 are implemented locally; device, field and human acceptance are still open. P08 added real-time 3D. The SpacePlayer draws Choisy-style studies with a CPU Canvas renderer chosen after a three-way spike measured on the A52s, and the first study, "How a dome stands", opens from Hagia Sophia's 537 layer. There are still **0 reviewed places and 0 approved Milestones**: I–V are prototypes and the study is not a Milestone. P09 is next; P09–P40 are not started.

| Phase | Status (2026-10-13) | Evidence and remaining acceptance |
| --- | --- | --- |
| P00–P04 | Gates re-run, not re-audited | Analyzer, tests and validator pass. On 2026-10-12 the P07 release build installed on the A52s and cold-started in 1.2 s to the first run without a crash. Other device/human checks unchanged. |
| P05 Dig | Implemented; repaired 2026-10-12; acceptance open | Open: present-day photo, finer periods, duplicated visit copy, O17, device scrolling/TalkBack. |
| P06 Plate engine | Implemented; repaired 2026-10-12; acceptance open | P08's audit found and fixed one more defect: plate sheets were marble on marble under the app's theme (headings invisible). Open: A52s gyro feel, TalkBack, GPU memory, 60 fps (O01). |
| P07 Pipeline and III–V | Implemented locally; acceptance open | Open: device feel/budgets (O01), native review (O08), a human-timed authoring run, an on-axis dome photo (O03). |
| P08 3D runtime | Implemented locally; device acceptance open | `lib/space/` SpacePlayer: orbit/pan/zoom with limits, Choisy's worm's-eye, a draggable section plane with poché, assembly timeline, exploded view, time scrubber, Drawing/Stone/Night, reduced-motion stills, TalkBack actions, P17 capture hooks. Spike: (a) Canvas 27 fps / (b) flutter_scene 58 fps / (c) thermion 60 fps at 50k triangles on the A52s; (a) chosen for drawing style up to ~20k triangles. Study on the phone: 54–57 fps in its default view, 41–50 fps without the cut, 30 fps in Night. Open: ≥ 50 fps in every drawing view (next: Dart on its own pinned UI thread), native review, P14's immersive backend. |
| P09–P40 | Not started | |

**Verified on 2026-10-13.** Analyzer clean. **242 app tests** pass against **129 golden baselines**, plus 7 pipeline, 5 study and 3 content Python tests. The validator passes on 48 Milestones, 38 details, 239 sources, 5 plate manifests and 1 study (its glTF parsed, every part a closed solid). The content, plate and study rebuild (37 files) is byte-identical across two runs. Three release APKs and the AAB build; arm64 APK **97,051,400 bytes**, AAB **143,893,114 bytes**; permissions unchanged. On the A52s (Impeller fell back to OpenGL ES; Dart runs on the main thread; no performance-hint support) the three 3D backends were measured (`studio/captures/P08/device-bench.json`). Evidence: [P08 folder](studio/captures/P08/), `studio/spikes/p08/`, `test/goldens/P08/`.

**Next implementation:** P09, the procedural kit, within about 20k triangles per building. First, at the next connection (O01): reinstall the release app (the benchmark build replaced it), uninstall the spike apps, and run the separate-UI-thread benchmark. O03/O08/O15/O17/O22 remain open.

## Snapshot: what the app is today (updated 2026-10-13)

**Works**
- A four-instrument shell: **Today** (Detail of the day → its Milestone, the Mile Zero dial, mosaic strip, Byzantine chapter), **City** (111 checked points by mil distance), **Milestones** (the 48-piece register) and **Mosaic** (notes until P19). A 12-second Milestone 0 lite plays on first launch.
- **The dig (new in P05):** every authored place page is a vertical section. A pinned plate crossfades to the layer under the reading line; the depth gauge on the edge shows the year and snaps to layers (TalkBack adjustable); Chora digs through six sourced layers from 2026 back to 330 (the page end now reaches the oldest layer), with the visit card, its artworks and Milestones I–V entered from the Metochites layer. Hagia Sophia proves the page is pure JSON with two draft layers. Drafts without layers keep the P04 header.
- A Flutter app with the **Chora preview** and a 155-place draft registry.
- A 103-artwork Chora catalogue with search and room filters, now rendered from typed registry records (the legacy scene adapter is gone), loaded independently of the classifier.
- An on-device ONNX recogniser (live, still and gallery input), reached from the camera-eye action on Chora and loaded only then.
- Per-scene notes.
- **Five manifest-driven plates (schema 2):** Anastasis, the Last Judgment, Metochites offers Chora (III), the Genealogy dome (IV) and the Enrollment for Taxation (V). Each is original-first and full screen, with 1–8× zoom, page-cited leader-line details, opt-in tilt and three lights, a 10 s reveal with a marked reveal moment, a 32–35 s story, manual stills and a TalkBack description. I keeps a damage-only wipe and one IMAGINED wrist beat (one reach and return); II has masked, lit river and scroll (labelled IMAGINED). **IV looks up:** the dome photograph mapped overhead, steered by the rotation sensor after an opt-in or by a finger. Advanced studies are in debug controls.
- **Drawing-style 3D (new in P08):** the SpacePlayer turns a glTF study into a measured drawing: Choisy's worm's-eye axonometric with the plan cut in porphyry poché, hairline and silhouette edges, coursing hatch, a draggable section plane, an assembly timeline with captions, an exploded view, a time scrubber between epochs, and Stone and Night styles. "How a dome stands" (20,144 triangles, eight sourced EN/TR steps, an 8 s reveal) opens from Hagia Sophia's 537 layer and reads RECONSTRUCTION throughout.
- **The plate production line (new in P07):** `python3.11 tool/plate/build.py studio/plates/<id>/plate.yaml` goes from one photograph to a validated plate (ingest, SAM 2.1, depth, gold, pop-up, adaptive mesh, WebP maps, manifest, report, 6 s preview), reproducing I–II and making III–V.
- Marble/lamp design system, three offline fonts, 28 plan symbols and EN/TR UI with a saved language override. Debug About: long-press the wordmark for `/design`, the version for Registry.
- Analyzer, 242 app tests against 129 goldens, P07/P08 capture and preview tests, 15 Python tests, content/manifest/study validation, a byte-identical rebuild and release APK/AAB builds pass. Earlier capture/emulator evidence is retained. The A52s ran the P07 release build and P08's 3D benchmarks; other physical acceptance remains unverified.

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

**Changed in P05 (this run)**
- **The dig:** `lib/city/place_screen.dart` grew into a data-driven section: a pinned plate that crossfades to the layer under the reading line, the edge depth gauge (that announces years to TalkBack; tests cover its adjustable semantics), strata with 2–4 sourced paragraphs, media credits, the layer's artworks as typed rows, its Milestones, and collapsible sources. Reduced motion swaps plates as cuts, not morphs.
- **Content:** Chora's six layers (2026 → 1948 → 1511 → 1321 → 1077 → 330) with 9 new pinned sources, a remotely checked visit card (hours, entry, etiquette, transit with walking minutes) and `anchorYear`/`artworks`/`visit` schema additions; the Hagia Sophia draft page is two layers from JSON alone. The validator now checks layer order, gauge years, paragraph counts, artwork ownership, hours dates and transit minutes.
- **Typed catalogue:** the `sceneForArtwork` adapter, `Scene`, `ScenesTab` and `SceneDetailSheet` are gone; the catalogue, Mosaic notes, scanner and dig all render typed `Artwork` records through `ArtworkSheet`/`ArtworksTab`, and the classifier returns `ArtworkMatch`.
- **Evidence:** `studio/captures/P05/` (12 layouts at 360/390/430 EN/TR 100/200%, the visit card, the Metochites layer, a reduced-motion still, `chora-dig-9s.mp4` exactly 9.00 s from 216 frames at 24 fps), `test/goldens/P05/` (5). `studio/captures/P05/devices.txt`: no device or emulator was available, so profile scrolling, TalkBack and the Go intent remain *unverified* on hardware.
- **2026-10-08 audit:** content/gesture corrections, build/rebuild fixes and fresh evidence are recorded in the changelog and `studio/captures/AUDIT-2026-10-08/`. P05 implementation is retained; acceptance is open.

**Audit of P05/P06 and P07 (2026-10-12)**
- **Audit:** two independent read-only reviews of P05 and P06, one fact-check of the disputed history, and a source review for III–V; every finding was reproduced before it was fixed. Details are in the checkpoint table above and the PHASES Decisions of 2026-10-12.
- **Pipeline:** `tool/plate/build.py` and `tool/plate/stages/` (each stage documents its inputs and outputs). Plate yamls and build reports are in `studio/plates/<id>/`. Model revisions are pinned (SAM 2.1 small, Depth Anything V2 Small/Base, Marigold v1.1); `tool/plate/test_build.py` proves the I–II reproduction, that no stage names a plate, lossless ingest, mesh flip/tear detection, inpainting and strict specs.
- **III–V:** three Kültür Envanteri photographs (credited, with source URLs and hashes) become plates with 7/6/8 details cited to Underwood (1966) by printed page. The Detail-of-the-day pool is 38. IV's look-up uses a measured rim ellipse and a 75° rim from Underwood's dimensions (an approximation, O03), plus a `GAME_ROTATION_VECTOR` channel.
- **Evidence:** `studio/captures/P07/` (63 stills, `genealogy-look-up-8s.mp4` at exactly 8.00 s / 192 frames, budgets, reports, tests, validator, release, release-artifacts.json) and `test/goldens/P07/` (4).

**Changed in P08 (this run)**
- **Spike:** one 49,864-triangle model (the study's bay, denser) in three backends, each recorded in `studio/spikes/p08/<candidate>/result.json`. On the A52s: (a) the Canvas renderer 27–28 fps, (b) flutter_scene 0.24.3 58 fps (+3.5 MB, Flutter GPU in preview), (c) thermion 0.5.0 60 fps (+6.8 MB, OpenGL ES only, a blocked build-time download). (a) wins for drawing style up to about 20k triangles: no dependency, it renders in tests and offscreen, and it already has hairlines, sections and poché. P14 picks the immersive backend.
- **Runtime (`lib/space/`):** a glTF 2.0 loader (node transforms, Z-up, closed-solid adjacency); an orbit camera with limits and Choisy's preset; a renderer that culls, clips at the section plane, keeps cut solids' inside faces as poché, sorts records by depth and writes one `drawVertices` call with hairline, silhouette and cut lines in the same sort; a seekable timeline with epochs; the player, its three sheets and a TalkBack step list; offscreen still and frame capture.
- **Study:** `tool/space/how_a_dome_stands.py` writes 25 closed parts with baked occlusion and the manifest. Eight steps cite Choisy (1883, 1899), Procopius, Britannica and pinned Wikipedia revisions; Hagia Sophia's 537 layer names it (`studies`).
- **Device:** the first A52s measurements of the app. Impeller falls back to OpenGL ES; Dart runs on the merged main thread; there is no performance-hint support. The CPU governor's clock, not the code, set most of the run-to-run spread. Details are in PHASES Decisions (2026-10-13).
- **Also fixed:** plate sheets under the app's marble theme (invisible headings), found while building the study's sheets.
- **Evidence:** `studio/captures/P08/` (41 stills, `dome-assembling-choisy-8s.mp4` 1080×1920 at 8.00 s / 192 frames, `budgets.json`, `device-bench.json`, tests, validator, release, rebuild) and `test/goldens/P08/` (4).

## Dimensions

### A. Identity and design language

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D01 | Name and brand story | 70% | EN/TR Milion story in About, app title and the first run: Milestone 0 lite ends on “Every road started here.” and About replays it (`lib/first_run/`). Store/share watermark and human recall remain open. | The story and tagline are in TR/EN everywhere (About, first run, store, share watermark), and 5 people can explain the name after using the app. | P00, P04, P13, P40 |
| D02 | Logo, launcher icon and splash | 70% | The mark in SVG, PNG and a Flutter painter; 5 launcher densities; adaptive and themed icons; Android 12+ splash. Mask renders checked, not on a device. | Verified on the A52s launcher (themed icon on/off, light and dark), in the store icon and on share cards. | P00, P03, P40 |
| D03 | Design tokens and component library | 75% | Marble/lamp tokens, 4-dp grid, ≤2-dp shapes, wave pigments, 30 component specimens and 60 passing goldens in `lib/design/` and `test/goldens/P03/`. Hidden `/design` shows both schemes at 100/200%; every current screen reskinned. Device/taste check remains open. | P03 system complete, with golden tests and the design sheet, and every screen using it. | P03 |
| D04 | Signature interactions | 63% | The Mile Zero dial and the repaired dig (oldest layer reachable, interrupted scrolls honoured) keep their tests. P06's held candle and raking light now stay hand-movable under reduced motion; P07 adds the look-up, held overhead or panned (`lib/plate/look_up.dart`). Touch is tested; hardware feel and P19 tesserae remain open. | The Mile Zero dial, the dig, leader-line plates, light you hold and tesserae are shipped and used consistently. | P03–P06, P19 |
| D05 | Typography | 75% | 11 rendered candidates in `studio/captures/P03/type-{display,text}.png`; Cinzel + Noto Serif Display Greek fallback, Noto Sans body/tabular numerals. Three offline fonts/OFLs registered; `tool/design/audit_fonts.py` verifies hashes and TR/Greek glyphs, including Ϲ. Physical rendering unverified. | Inscriptional display face plus text face with Turkish and Greek, bundled and licensed, with specimens verified. | P03 |
| D06 | Iconography and illustration | 60% | 28 custom PlanIcons: P03's 13, plus 15 in P04 (dial, milestone stele, one glyph per §3 technique code), all golden-tested in `test/goldens/P04/`. Navigation, register techniques and City categories use them. Generic back/search/zoom remain platform symbols; era map styles remain P10. | The PlanIcon set, era map styles and line illustrations; no generic cultural icons. | P03, P04, P10 |
| D07 | Copy voice | 58% | P08 adds the study's eight EN+TR step captions, two epoch labels, a reveal line and a TalkBack description, each naming a checkable measure, date or source. P07's 21 page-cited details and the corrected layers stand; a test still scans dig text and details for the §2 filler words. Native review remains O08. | Every line is specific and checkable, native TR and EN, and passes the §2 copy rule. | P03, P34 |

### B. Product structure

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D08 | App shell and navigation | 75% | Four PlanIcon destinations (`lib/shell/app_shell.dart`); Scan is now a camera-eye action on the Chora place page, catalogue and artwork sheets. `IndexedStack` plus restoration of tab, scroll offsets and dial state across `restartAndRestore`. Back goes to Today, then exits. Predictive back (manifest opt-in + `PredictiveBackPageTransitionsBuilder`) previews pages on the Android 14 emulator (`studio/captures/P04/predictive-back-a14.mp4`). Edge-to-edge insets; 18 shell tests. A52s check open (O01). | Today, City, Milestones and Mosaic; predictive back; state restoration; edge-to-edge. | P04 |
| D09 | First run and Today | 75% | Milestone 0 lite first run: 12 s, skippable after 2 s, three reduced-motion stills, a TalkBack sentence; replay in About. Today: Detail of the day with a shared element into the Milestone, the Mile Zero dial and its list, the mosaic strip, the Byzantine chapter; the 17-detail pool rotates by date. Profile cold start to an interactive Today on the Android 14 emulator: median 1,067 ms (trace) / 1,276 ms (`am start -W`), in `startup.json`. Clip: `studio/captures/P04/first-run.mp4`. Reference device and human first-impression checks open. | A first reveal in ≤ 10 s with no permission; Milestone 0 intro; Detail of the day; the dial. | P04, P13 |
| D10 | Place pages (the dig) | 73% | Data-driven dig in `lib/city/`, repaired 2026-10-12 (oldest layer, interrupted scrolls, 200% title, Go label). Layers can now name SpacePlayer studies (`studies`); Hagia Sophia's 532–537 layer opens "How a dome stands". Open: a present-day header photo, finer periods than `Era`, duplicated visit copy, profile scrolling, physical TalkBack/haptics, Go on a device. | Every reviewed place has a dig page with strata, a visit card and sources, built purely from data. | P05 |
| D11 | Atlas | 0% | None. | Offline era-styled map with a time slider, mile rings, the Below layer and map/list parity. | P10 |
| D12 | Search and discovery | 10% | Scene title and room search within Chora. | Turkish-aware search with aliases, filters, people pages, "Surprise me" and recommendations. | P33 |
| D13 | Routes and hunts | 0% | None. | 12 routes and 6 hunts, reviewed and working offline. | P21, P26, P27, P32 |

### C. Content

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D14 | Content model and registry | 78% | Schema 1 registry, plate schema 2 and now study schema 1 (`lib/space/study.dart`: epochs, steps, reveal, Choisy cut, citations) with glTF parts checked against steps. The validator parses every study and its model and refuses open solids; 48 Milestones, 38 details, 239 sources. CI remains P38. | A typed, versioned, validated registry; the validator CLI runs in CI. | P02, P05 |
| D15 | Byzantine coverage | 10% | 52 Byzantine-category drafts with pinned Wikidata/OSM evidence in `assets/content/places/istanbul.json`; 0 reviewed. Existing Chora preview retained. | ≥ 30 reviewed Byzantine places. | P11–P16 |
| D16 | Mosque coverage | 10% | 39 mosque-category drafts, including layered former churches; bilingual names/hooks and QIDs. No visiting layer or field review yet. | ≥ 30 reviewed mosques with the visiting layer. | P24–P27 |
| D17 | Museum coverage | 10% | 33 museum and 15 palace category assignments (overlap); QID-backed drafts only. Object extension remains P28. | ≥ 25 reviewed museums or palaces and ≥ 25 object pages. | P28–P31 |
| D18 | 39-district coverage | 10% | 155 drafts across 22/39 Istanbul districts plus 9 explicitly outside-province records; all 39 district enum values and zero counts tested. 0 reviewed districts. | 39/39 districts and ≥ 110 reviewed places. | P32 |
| D19 | Stories and writing | 26% | Chora's six layers, two Hagia Sophia layers, 155 seed hooks, 38 Detail-of-the-day sentences and the study's 35 s eight-step story (P08). Full stories for the remaining places and native review remain open. | Every reviewed place and Milestone has a story in TR and EN with hooks. | P05, P11–P32, P34 |
| D20 | Accuracy, sources, honesty labels | 61% | 239 sources. P08's study cites Choisy (1883, 1899), Procopius (Buildings I.1.46), Britannica (pendentive, Hagia Sophia, Sinan) and two pinned Wikipedia revisions; it states the 30.86–31.24 m span, the 40 windows and the 19 m Şehzade dome, and calls itself "a diagram, not a survey". O22 remains open. | Every claim is sourced, every place has a QID, labels are applied everywhere and debates are marked. | P02, all content phases |
| D21 | Practical visit information | 30% | Chora visit card has separately dated hours, entry, etiquette, transit/walking minutes and sources; checkedAt/hoursCheckedAt 2026-10-08. Published visiting information says daily except Friday, 09:00–18:00, €20 for foreign visitors and prayer closures. Source publisher is Müze İstanbul. Accessibility, entrance/walking route and mosaic visibility need field review; other places have no visit card yet (O15). | Hours, access, etiquette, prayer windows and transit for every place, each with a checkedAt date. | P05, P24, P39 |
| D22 | Media library | 17% | 2 typed media records plus three credited P07 plate masters (Kültür Envanteri URLs, source and output SHA-256 in each report); ingest strips EXIF without changing pixels. The full image library and a present-day photo per place remain open. | ≥ 3 images per reviewed place (today and historical), all credited in the manifest. | P02, content phases |

### D. The Milestone collection (2.5D / 3D)

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D23 | 2.5D Plate engine | 75% | Schema-2 manifests drive DP, GL, RL, Candle, WR, SB, MM and now LU for five plates; the audit fixed filtering, masked-pass lighting, two-phase flow, the scroll pivot, beat pop/twitch, gyro drift, repaint-per-pan and zoom loss. Tests: 215 app tests incl. LU projection, orientation, honesty, camera revision, lenient catalogue and widget look-up; 15 P06/P07 goldens. A52s budgets/fps remain O01. | PlatePlayer with DP, GL, RL, Candle, WR, SB, MM and LU running from manifests at budget on the device. | P06, P07 |
| D24 | 2.5D production pipeline | 70% | `python3.11 tool/plate/build.py studio/plates/<id>/plate.yaml` runs ingest, SAM 2.1, depth/normals/gold, pop-up, adaptive mesh and export with a report and 6 s preview; it reproduces I–II from yaml with no scene code and built III–V; the rebuild is byte-identical. Open: a human-timed authoring run (III–V minutes are agent estimates), LaMa/KTX2 (OpenCV/WebP chosen), CI. | One command turns a photo into a validated plate, reproducible from the repo. | P07 |
| D25 | 2.5D Milestones approved | 8% | 0 of the ~26 2.5D pieces approved; I–V are playable prototypes (III–V new in P07). Approval still needs device budgets, native review and a share export. | Every 2.5D Milestone the ship scope needs is approved (§3 definition). | P06–P31 |
| D26 | 3D runtime | 60% | `lib/space/` SpacePlayer with orbit/pan/zoom limits, Choisy's worm's-eye, section plane with poché, assembly timeline, exploded view, time scrubber, Drawing/Stone/Night, reduced-motion stills, TalkBack actions, offscreen capture; 26 tests and 4 goldens. On the A52s: 54–57 fps in the default view, 41–50 fps without the cut, 30 fps in Night; the 50k spike model 27 fps (`studio/captures/P08/device-bench.json`). Every drawing view at ≥ 50 fps and the immersive backend (P14) remain open. | SpacePlayer with orbit, section, assembly and styles, at budget on the device. | P08 |
| D27 | Procedural architecture kit | 5% | Foundations only: `tool/space/glb.py` (deterministic glTF writer and reader), `solid.py` (closed-solid construction and checks, baked AO) and the hand-written study. The YAML spec, generators and kit validation are P09. | The generators and spec format build every 3D building in the register. | P09 |
| D28 | 3D Milestones approved | 0% | None. | Every 3D Milestone the ship scope needs is approved. | P08–P31 |
| D29 | Motion doctrine and honesty in motion | 75% | All five plates start on ORIGINAL with one-tap return and long-press comparison, a 10 s reveal with a marked moment, a 32–35 s story, captions, manual stills and a TalkBack description. Moving paint (river, scroll) and the whole wrist beat now read IMAGINED; II lost a wipe that repainted 52% of the fresco. Human/device acceptance remains open. | Every Milestone follows §3: labels, the original one tap away, still-sequence equivalents, no sacred puppetry. | P06 onward |
| D30 | Light and sensors | 52% | Gyro tilt is opt-in, relaxes to centre (2.5 s), smooths by time and locks portrait while it steers; LU uses Android's game rotation vector through `milion/rotation` after an opt-in, with a pan fallback. GL/RL/Candle shaders, now filtered and lighting masked passes. Fake-stream tests pass; hardware feel and sun modes remain unverified. | Gyroscope, specular gold, candle and sun position work smoothly on the device, and gyroscope motion is opt-in. | P06, P25, P26 |

### E. Attraction and return

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D31 | Share studio and deep links | 3% | Offscreen hooks exist: `renderSpaceStill` and `spaceFrames` (`lib/space/capture.dart`) made P08's 1080×1920 hook. Exports, Sharesheet, MediaStore and links remain P17. | Still, MP4 and WebP exports, Sharesheet, MediaStore, milion:// and https links. | P17 |
| D32 | Daily Tessera and On this day | 6% | A date-deterministic rotation over a 38-detail curated pool (17 → 38 in P07), interleaved so consecutive days change artwork; only playable Milestones are shown. The Daily Tessera game, On-this-day entries and share card remain P18. | 365 Daily details and 120 dated entries; share card; optional notification. | P18 |
| D33 | Personal mosaic and Milestone book | 10% | Saved notes are listed in the Mosaic placeholder. A provisional 48-slot strip and grid sets a tessera per opened Milestone (`milion_opened_milestones`, imported by P19). Seasonal mosaics, passport and export remain P19. | Three seasonal mosaics, the passport, export/import and delete. | P19 |
| D34 | Ghost lens | 0% | None. | 30 viewpoints with alignment and diptych/swipe export. | P20 |
| D35 | Recognition (point and reveal) | 30% | 103-class ONNX works live, still and from the gallery. Rejection is weak (About admits ≤ 67% on negatives); numbers not reproduced; no reveal transition. | Open-set model meeting the P23 gates (or labelled Beta), the lock-and-reveal, multiple places. | P11, P23 |
| D36 | Audio | 0% | None. | Voices (XI and more), soundscapes, TR/EN narration with captions, interruption handling. | P22 |
| D37 | Seasonal and live moments | 0% | None. | Mahya in Ramadan, the equinox sky, live sun in Süleymaniye, prayer-aware visits. | P24–P27 |
| D38 | Launch and acquisition kit | 0% | None. | 20 clips, a 30-day calendar, a press note and a promo video, all built from real exports. | P17, P40 |

### F. Android quality

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D39 | Turkish and English localisation | 54% | 411/411 UI keys in EN/TR (P08 adds 27). Registry coverage 1,303/2,166 TR fields (60.2%); all new details, layers, plate descriptions and the study are bilingual. 863 legacy fields and native review remain open (O08). | 100% ARB and content coverage, reviewed by native readers (O08). | P03, P34 |
| D40 | Accessibility | 64% | Plates and now the study carry a bilingual TalkBack description and custom actions (Next/Previous still; Choisy's view), a live caption and a step list; the section handle is labelled. P08 fixed plate sheets whose headings were invisible under the app theme. 200% EN/TR captures for the study. Physical TalkBack/haptics and the full P35 matrix remain open. | P35 passes on the device: TalkBack, 200% text, contrast, targets, still equivalents, captions. | P35 |
| D41 | Layouts and device classes | 62% | P08 adds 41 study captures at 360/390/430 dp, EN/TR, 100/200% (the 200% sheet overflow and an overlapping label were fixed). Physical devices, tablets, landscape and rotation remain unverified; sensors lock portrait while they steer. | Phone, tablet, landscape and foldable layouts verified; edge-to-edge insets. | P03, P35 |
| D42 | Performance | 32% | First on-device frame timings (A52s, `studio/captures/P08/device-bench.json`): the study at 54–57 fps in its default view but 30–50 fps elsewhere, with the CPU governor's clock as the main variable; flutter_scene and thermion at 58–60 fps on 50k triangles. Host frame build 1.6 ms (`P08/budgets.json`). Plate GPU memory, fps and A52s startup remain O01. | All P36 budgets met on the A52s. | P06, P08, P36 |
| D43 | App size and asset delivery | 30% | Arm64 APK 96,744,286 B; AAB 143,167,365 B (`P07/release-artifacts.json`). III–V add about 6 MB as WebP/JPEG while II's dropped 3.5 MB study leaves the bundle. Sizes do not establish the ≤60 MB Play gate or asset delivery (P36). | Base download ≤ 60 MB; Play Asset Delivery packs with download management. | P01, P36 |
| D44 | Offline behaviour | 40% | All current content, textures, three selected fonts, UI translations and font licences are bundled. P03 has no network font dependency; download/pack failure paths remain P10/P36. | Starter plus packs work offline; downloads resume; low-storage and corruption recovery. | P10, P36 |
| D45 | Lifecycle and permissions | 42% | Plates stop story, gyro and the rotation sensor on background, unsubscribe on exit, release the portrait lock and dispose late loads; tested with fake streams. APK permissions unchanged (CAMERA, ACCESS_NETWORK_STATE). Device flows and the P37 script remain unverified. | P37 script passes: in-context requests, denial, revocation, process death. | P01, P37 |
| D46 | Privacy and data safety | 30% | Fully local, no network, no analytics. No policy, export or delete. | Data Safety answers, TR/EN policy, export and delete, opt-in only. | P19, P37 |
| D47 | Persistence and migrations | 40% | Notes migration as in P02. P04 persists the first-run flag and the opened-Milestones set, and Flutter state restoration (tab, scroll, dial) is tested with `restartAndRestore`. SQLite/import/export remain P19. | Versioned local database with migrations tested across upgrades. | P02, P19 |
| D48 | Stability and crash reporting | 5% | No crash reporting; never run through monkey testing. | Opt-in crash and ANR reporting; a 1-hour monkey run clean; 0 crashes in the field trial. | P37, P39 |

### G. Engineering and release

| ID | Dimension | Now | Evidence now | 100% means | Phases |
| --- | --- | ---: | --- | --- | --- |
| D49 | Codebase health | 75% | The audit removed the per-scene wrapper screens, F02/F05 routing, the unused geometry load and P06's scene-scripted manifest builder; plate modules stay under 400 lines; the pipeline has no scene code (tested). 17,959 Dart lines = 12,915 authored + 5,013 generated localisation + 31 OSM. `lib/design/components.dart` (715) remains the one long file. | No dead code or assets, a feature-based structure, analyzer clean, no file over about 600 lines without reason. | P01, ongoing |
| D50 | Automated tests | 75% | 242 app tests against 129 goldens (P08: glTF loading, camera limits, timeline and epochs, renderer culling/poché/cuts, capture hooks, manifest mutations, catalogue, eight player widget tests, a plate-sheet regression verified to fail without its fix). 15 Python tests (5 new for the study). Device integration and CI remain P38. | P38 pyramid with integration tests on the device; a deliberately broken build fails. | P38, ongoing |
| D51 | Version control, reproducibility, CI | 63% | `tool/content/rebuild.py` now includes the study; all 37 content/plate/study files rebuild byte-identically. Spike sources are kept in `studio/spikes/p08/` (excluded from analysis), their APKs reproducible from them. CI and LFS remain open. | Git with LFS, env-configured tools, pinned requirements, green CI. | P01, P38 |
| D52 | Physical device validation | 15% | 2026-10-12: the A52s ran the P07 release build (install, 1.2 s cold start to the first run, no crash) and P08's 3D benchmarks for all three backends; Impeller's OpenGL ES fallback and the merged Dart thread were found on it. Then it disconnected (O01). Sensors, TalkBack, plates' GPU memory and fps remain unverified. | Every flow is verified on the A52s, plus the emulator matrix. | P06 onward, P38 |
| D53 | Release engineering | 40% | All three per-ABI release APKs and the AAB pass for P07 with every plate and both shaders bundled (`P07/release.txt`, `release-artifacts.json`). R8/shrinking/minSdk 26 retained. Debug-signing fallback (O05) and staged rollout remain open. | A signed AAB with asset packs, a clean pre-launch report, a versioning scheme and staged rollout. | P01, P40 |
| D54 | Store listing | 0% | None. | TR/EN listing, 8 screenshots, feature graphic, promo video, Data Safety. | P40 |
| D55 | Field trial | 0% | None. | P39 run, with all P0 and P1 findings fixed. | P39 |
| D56 | Feedback and corrections loop | 5% | The "Report a change" row and a testable `mailto` builder ship in P05, but it stays hidden until O17 provides an address (`lib/city/external_links.dart`). Triage workflow remains P40. | In-app "Report a change", a support address (O17) and triage in the phase workflow. | P05, P37, P40 |

## Counters

| Counter | Now | Ship target |
| --- | ---: | ---: |
| Reviewed places (Byzantine / mosque / museum / other) | 0 (0 / 0 / 0 / 0). Chora exists, not reviewed. | ≥ 110 (≥ 30 / ≥ 30 / ≥ 25 / rest) |
| Districts with ≥ 1 reviewed place | 0 / 39 (drafts in 22 / 39) | 39 / 39 |
| Draft places with verified QIDs | 155 / 155; 146 inside province, 9 flagged outside | reviewed by their wave phases |
| Registry source records | 239 (P08 adds Choisy 1883 and 1899, Procopius, Britannica pendentive and Sinan, two pinned Wikipedia revisions); before P08 232 (16 dig sources, 10 detail sources; P07 adds Underwood 1966, Psalm 116:9, Luke 2:1–5, two Resmî Gazete decisions, Hürriyet, two AA reports); 155 pinned QID inputs and 5 plate masters hashed | every factual record cited |
| Chora artworks complete | 0 / 103 complete; 103 / 103 migrated (guide source linked; detailed stories, inscriptions and TR still missing) | 103 / 103 |
| Milestones approved (of 48) | 0 (prototypes: I–V; 43 planned; all 48 in the register, 9 ★) | ≥ 40, all ★ |
| Routes / hunts / ghost-lens viewpoints | 0 / 0 / 0 | 12 / 6 / 30 |
| Daily pool / On-this-day entries | 0 / 0 published; 6 / 6 authoring drafts (P05 adds three Chora facts and three dates) | 365 / 120 |
| Detail-of-the-day pool | 38 (9 I, 8 II, 7 III, 6 IV, 8 V), EN+TR, each sourced, interleaved and date-rotated; only playable Milestones shown | ≥ 14 (P04), grows with each Milestone |
| Places plotted on the dial and City | 111 checked points (0 reviewed); 44 excluded: 28 area, 6 representative-point, 1 contested, 9 outside the province | every reviewed place |
| Turkish string coverage | UI: 411 / 411 ARB keys (native review pending). Content: 1,303 / 2,166 fields (60.2%); 863 missing; study 1 / 1 bilingual; 155 / 155 place names/hooks; 38 / 38 details; 48 / 48 register titles; 8 / 8 dig layers; 5 / 5 plate descriptions | 100% reviewed |
| App tests | 242 pass against 129 golden baselines; P07/P08 capture + preview tests; 7 pipeline + 5 study + 3 content Python tests; earlier evidence retained | P38 pyramid |
| Design specimens / custom plan symbols / offline fonts | 50 × 2 schemes (P04 adds 15 symbols, 3 slot states, flagship, honesty range; P05 adds 5 goldens: gauge ×2, section diagram ×2, visit card) / 28 / 3 | consistent on all screens |
| Dart lines in lib/ | 21,436 total = 16,054 authored + 5,351 generated localization + 31 generated OSM (P08's `lib/space/` is 3,004 lines; no file over 602) | lean, no dead code |
| Release artifact size | 97,051,400 bytes arm64 APK; 143,893,114 bytes AAB (P08 adds 307 KB: the 300,700 B study model and code); debug signing fallback | base download ≤ 60 MB (P36 measurement open) |
| Implemented plate manifests / story stills / plate goldens | 5 (schema 2) / 9 P06 + 18 P07 reduced stills / 11 P06 + 4 P07 | every plate; ≤150 MB textures and ≤60k vertices |
| Manual minutes per plate | III 25, IV 35, V 25: agent authoring estimates (prompts, windows, beats, rim); I–II 0 (inherited). No human-timed run yet | tracked from P07 |
| 3D studies / triangles / approved | 1 ("How a dome stands", 25 parts, 8 steps) / 20,144 / 0 (studies are not Milestones; 3D Milestones start in P11–P13) | every 3D Milestone at ≤ 20k triangles and ≥ 50 fps on the A52s |

## Phase ledger

“Implemented locally” records working code and local evidence; it does not close the device, field, human or release checks listed above.

| Phase | Status | Date | Visible result |
| --- | --- | --- | --- |
| P00 Milion identity and plan | Implemented locally | 2026-09-26 | New name, mark, launcher and splash; paths renamed; this plan. |
| P01 Clean slate | Implemented locally | 2026-09-27 | Git baseline + phase commits; runtime pruned (v3 conch, Classic v5, 26 MB relief, v1 data); `studio/` reorg; `MILION_CAPTURES`; R8 release verified with camera + ONNX; arm64 APK 89.7 MB (from 203.7 MB). |
| P02 Content registry and mile-zero geography | Implemented locally | 2026-09-27 | Debug About version long-press → Registry; 155 QID drafts sorted by mil distance, 103 Chora artworks, notes preserved. EN/TR and district captures: `studio/captures/P02/`. |
| P03 Design language | Implemented locally | 2026-09-28 | Porphyry & Tessera, offline Cinzel/Noto, 13 PlanIcons, 60 goldens, bilingual settings; hidden `/design`; A/B and 360/390/430-dp captures in `studio/captures/P03/`. |
| P04 Shell, Today and the first ten seconds | Implemented locally | 2026-10-01 | Four-instrument shell. Milestone 0 lite first run (`studio/captures/P04/first-run.mp4`). Today: Detail of the day (17-detail pool, shared element into the Milestone), Mile Zero dial and list, mosaic strip, chapter. 48-piece register. Profile cold start to Today 1.07 s on the Android 14 emulator. |
| P05 Place page: the dig | Implemented; repaired; acceptance open | 2026-10-07; audits 2026-10-08, 2026-10-12 | Six-layer Chora dig and two-layer Hagia Sophia draft. 2026-10-12: oldest layer reachable, interrupted scrolls honoured, title and Go accessible, four claims corrected with official sources. Present-day photo, finer periods, profile scrolling, physical TalkBack/haptics, Go, native/field review and O17 remain open. |
| P06 Plate engine and remastered I–II | Implemented; repaired; acceptance open | 2026-10-08; audit 2026-10-12 | Manifest-driven player. 2026-10-12: one-beat wrist without a pop, filtered samplers, lit seamless river/scroll, scroll pivot, gyro decay, zoom kept on pause, TalkBack descriptions, IMAGINED moving paint, no wipe for II. A52s gyro/TalkBack/GPU memory/60 fps, native copy and provenance/rights remain open. |
| P07 Plate production line and III–V | Implemented locally; acceptance open | 2026-10-12 | One-command pipeline reproducing I–II and making III–V; schema 2; LU look-up with rotation vector; 21 page-cited details; five 6 s previews and the 8 s Genealogy hook (`studio/captures/P07/`). Device feel/budgets, native review, a human-timed run and an on-axis dome photo remain open. |
| P08 3D runtime and "How a dome stands" | Implemented locally; device acceptance open | 2026-10-13 | Three-backend spike measured on the A52s; SpacePlayer with Choisy's worm's-eye, section and poché, assembly, exploded view, time scrubber and three styles; "How a dome stands" from Hagia Sophia's 537 layer; 8 s hook (`studio/captures/P08/dome-assembling-choisy-8s.mp4`). Open: ≥ 50 fps in every drawing view, native review, P14's immersive backend. |
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

- **2026-10-13, P08 — 3D runtime and "How a dome stands".** Spiked a Canvas renderer, flutter_scene and thermion on one 50k-triangle model and measured them on the A52s (27 / 58 / 60 fps); chose the Canvas renderer for drawing style up to ~20k triangles and left the immersive backend to P14 (§3 budget changed). Built `lib/space/`, the study (eight sourced EN/TR steps, Hagia Sophia's two semi-domes against the Şehzade Mosque's four) and its link from Hagia Sophia's 537 layer. On the phone the study reaches 54–57 fps in its default view but 30–50 fps elsewhere; Impeller's GLES fallback, the merged Dart thread and the governor are recorded. Fixed invisible plate-sheet headings. Overall 34.5% → 36.1%.

- **2026-10-12, audit of P05/P06 and P07 — plate production line and Milestones III–V.** Audit: two read-only code reviews and a fact-check, every finding reproduced before fixing. P05: unreachable oldest layer, interrupted-scroll override, 200% title clip, unlabelled Go, Turkish strata unenforced, four wrong claims and a TR typo, all fixed (regression tests fail without the fix). P06: beat pop and double twitch, nearest sampling, unlit masked passes, river snap, scroll pivot, gyro drift, zoom loss on pause, no TalkBack description, moving paint labelled DEPTH, a 52% wipe on II, repaint per pan frame, whole-app failure on one bad plate, F02/F05 routing, all fixed. P07: plate schema 2; `tool/plate/build.py` stages (a)–(f) with pinned models, caching and validation; I–II reproduced from yaml; III–V from single photographs with 21 Underwood-cited details; LU look-up (rectilinear lens, measured rim ellipse, 75° rim from Underwood's dimensions, `GAME_ROTATION_VECTOR` channel, pan fallback); depth models measured (Spearman −0.27…−0.52 vs the hand relief; used for detail only); gold heuristic measured and fixed; Detail-of-the-day pool 17 → 38. Checks: `flutter analyze`; `flutter test` (215, 125 goldens); `python3.11 tool/plate/test_build.py` (7); `python3.11 -m unittest tool.content.test_build_seed` (3); `dart run tool/content/validate.dart`; byte-identical `python3.11 tool/content/rebuild.py` twice (34 files); `bash tool/build_android.sh` (arm64 APK 96,744,286 B; AAB 143,167,365 B). Evidence: `studio/captures/P07/`, `studio/plates/<id>/build/`, `test/goldens/P07/`. Scores: D04 60 → 63; D07 55 → 57; D10 70 → 72; D14 75 → 76; D19 22 → 25; D20 55 → 60; D22 15 → 17; D23 70 → 75; D24 30 → 70; D25 5 → 8; D29 70 → 75; D30 45 → 52; D32 5 → 6; D39 52 → 53; D40 60 → 63; D41 60 → 61; D42 25 → 27; D45 40 → 42; D49 72 → 75; D50 70 → 73; D51 58 → 62. Assessed unchanged: D43 30 (+1.2 MB, no PAD), D52 8 (no device), D53 40 (no signing change), D35 30 (routing only). Overall **32.7% → 34.5%** (1,930/5,600). No place promoted, no Milestone approved. Next: **P08**.

- **2026-10-08, P06 — Plate engine and remastered I–II.** Strict manifests/catalogue, full-screen PlatePlayer, opt-in bounded tilt, GL/RL/Candle, source-preserving masked 4K wipe, 10 s reveals and 32 s seekable stories. One scoped 1.2 s Anastasis wrist beat; masked Judgment river/scroll. All 17 Today details survive; the old explorer/adapter/asset loader/restoration screen are removed. Manual stills, background stops, late-load disposal and pixel isolation pass. Authored gold masks replace pigment heuristics; the Judgment rig is resampled from 62,220 to 59,800 vertices. Evidence: `studio/captures/P06/` (197 tests, 122 total goldens, 2 capture tests, 57 stills, three exact 8 s / 192-frame clips, 3 Python tests, validator, reproducible 15 JSON/8 maps, photo hashes, APKs/AAB); `test/goldens/P06/` (12). Textures: 76,113,920 / 87,123,200 B. Device fps/total GPU memory, gyro feel and physical TalkBack remain O01; native and provenance/rights remain O08/O22/O11. No place/Milestone promoted. Scores: D04 50 → 60; D23 35 → 70; D24 20 → 30; D29 50 → 70; D30 0 → 45; D40 55 → 60; D41 57 → 60; D49 68 → 72; D50 68 → 70; D51 56 → 58. Assessed unchanged: D07 55, D08/D09 75 (existing pool/Today retained), D14 75, D20 55, D22 15, D25 5 (no approval), D39 52 (same content/native debt), D42 25, D43 30, D44 40, D45 40, D52 8, D53 40 (local counts/builds do not establish device/Play/signing acceptance). Others unchanged. Overall **30.3% → 32.7%** (1,832/5,600). Next: **P07**.

- **2026-10-08, audit and repairs of P00–P06.** Compared phase requirements, code, commits, fixtures and historical captures. Fixed the AGP 9 sensor build, plate asset bundling, river RGB coverage, held/cancelled gauge gestures and stale scroll completions, seed-index loss on rebuild, and Chora visit/history/event claims; source attribution corrected without changing photographs. New evidence: `studio/captures/AUDIT-2026-10-08/` (187 app tests / 110 goldens, 3 capture tests, 3 Python tests, analyzer, validator, byte-identical 13-file rebuild, hashes, 37 stills, 9.00 s clip, all release APKs/AAB). P00–P04 are implemented locally; P05 acceptance open; P06 preparation only; P07–P40 not started. O01 reopened; O08/O15/O17/O19/O22 remain open. Scores reassessed with new evidence: D04 50 → 50; D10 70 → 70; D14 75 → 75; D20 55 → 55; D21 30 → 30; D23 35 → 35; D24 20 → 20; D29 50 → 50; D30 0 → 0; D39 52 → 52; D41 57 → 57; D42 25 → 25; D43 30 → 30; D45 40 → 40; D49 68 → 68; D50 68 → 68; D51 56 → 56; D52 8 → 8; D53 40 → 40; D56 5 → 5. Other dimensions unchanged. Overall **30.3% → 30.3%** (1,696/5,600): fixes restore counted scope; no new phase, reviewed place or approved Milestone.

- **2026-10-07, P05 — the dig (historical entry; corrected by the 2026-10-08 audit above).** The place page is a vertical section: a pinned plate crossfades to the layer under the reading line, the edge depth gauge previews and snaps with a light detent and announces years to TalkBack, and each stratum carries a dated title, 2–4 sourced paragraphs, media credits, its artworks as typed rows, its Milestones and collapsible sources. Chora ships six layers (2026 → 1948 → 1511 → 1321 → 1077 → 330) from nine new pinned sources (Müze İstanbul, Sözcü, Cumhuriyet, Daily Sabah, Hyperallergic, choramuseum.com, Smarthistory, Britannica, UNESCO) and a remotely checked visit card (initially recorded as Tue–Sun 09:00–18:00; corrected 2026-10-08 to daily except Friday, €20 entry, mosque etiquette, T4 + Metrobüs stops with walking minutes, checkedAt 2026-10-07); Milestones I–V enter from the Metochites layer. Hagia Sophia is a two-layer JSON draft; drafts without layers keep the P04 header. Schema additions: stratum `anchorYear`/`artworks` (2–4 paragraphs, newest-first, distinct gauge years) and place `visit`, with validator rules and fixtures. The scene compatibility layer is gone: typed `Artwork` everywhere (`ArtworksTab`, `ArtworkSheet`, classifier `ArtworkMatch`). Checks: `flutter analyze`; `flutter test` (182, incl. 110 goldens); 14 capture tests; `dart run tool/content/validate.dart`; `bash tool/build_android.sh` (arm64 APK 92,519,709; AAB 138,985,949); `aapt` (CAMERA + ACCESS_NETWORK_STATE only). Evidence: `studio/captures/P05/` (36 layouts, `chora-dig-9s.mp4` 9.00 s / 216 frames at 24 fps, reduced-motion still, analyze/tests/captures/validator/release/devices), `test/goldens/P05/` (5). No device or emulator was available: profile scrolling, hardware TalkBack and the Go intent are unverified. Scores: D04 45 → 50; D07 50 → 55; D10 10 → 70; D19 18 → 22; D20 50 → 55; D21 5 → 30; D39 50 → 52; D41 55 → 57; D49 65 → 68; D50 65 → 68; D51 55 → 56; D56 0 → 5. Assessed unchanged: D01 70, D02 70, D03 75, D05 75, D06 60, D08 75, D09 75, D11–D18, D22 15 (no new media), D23 35 (no PlatePlayer yet), D25 5, D26–D28 0, D29 50, D30 0, D31 0, D32 5 (P05 seeds are authoring drafts), D33 10, D34–D38 0, D40 55, D42 25 (no device), D43 30, D44 40, D45 40, D46 30, D47 40, D48 5, D52 8, D53 40, D54/D55 0. Overall **28.1% → 30.3%** (1,696/5,600). O17 keeps "Report a change" hidden; O08 native review grows; no place or Milestone was promoted.

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
