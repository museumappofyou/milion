# Milion — Phases

**Milion** — *Istanbul from mile zero.* Android app (Flutter). Dart package `milion` · application ID `app.milion` · workspace `/Users/memre/Desktop/milion`.

The Milion (Turkish: *Milyon Taşı*) was the zero-mile stone of Constantinople: every road distance in the empire was measured from it. A fragment still stands on Divanyolu beside the Basilica Cistern. The app measures the whole city from that point: distance outward in Roman miles, depth downward through time.

**How to use this file.** Run the phases in order, respecting the dependencies. Open a new coding session in the workspace, copy one phase's code block and paste it. Every phase finishes by updating this file (Decisions, Open issues) and `PROGRESS.md` (scores, counters, ledger). These are the two authoritative product tracking files; the separate phase-routing notes are auxiliary. The earlier İzvoya-era documents are archived in `archive/izvoya-era-docs-2026-09-26.tar.gz`.

**Current checkpoint — P08 implemented locally; device acceptance open (2026-10-13).** P08 spiked three 3D backends with one 50k-triangle model, measured on the A52s, and built the SpacePlayer on candidate (a), a CPU Canvas renderer: Choisy's worm's-eye axonometric, orbit/pan/zoom with limits, a draggable section plane with poché, an assembly timeline, an exploded view, a time scrubber, Drawing/Stone/Night styles, reduced-motion stills, TalkBack actions and P17 capture hooks. The first study, "How a dome stands" (a 31 m bay to a dome on 40 windows, then Hagia Sophia's two semi-domes against the Şehzade Mosque's four), opens from Hagia Sophia's 537 layer. On the phone the study reaches 54–57 fps in its default view but 30–50 fps in others, so the ≥ 50 fps acceptance stays open (Decisions, 2026-10-13). P05–P07 remain implemented with acceptance open; P09–P40 are not started. An implementation date does not close device, field, native-copy or owner checks.

**Next work.** When the A52s is connected (O01): reinstall the release app (the P08 benchmark build replaced it), run `studio/cache/spikes/milion-space-canvas-bench-profile.apk` (Dart on its own pinned UI thread) to settle P08's frame rate, then validate P03–P07 (gyro and rotation-vector feel, TalkBack, GPU memory, 60 fps). Then P09, the procedural kit, within the drawing-style budget of about 20k triangles per building. O08, O15, O17, O22 and release rights/signing remain open.

**Current evidence.** `studio/captures/P08/`: analyzer clean; 242 app tests against 129 golden baselines; 7 pipeline, 5 study and 3 content Python tests; a valid registry with five plate manifests and one study; a byte-identical content, plate and study rebuild (37 files, twice); release APKs/AAB (arm64 97,051,400 B). `device-bench.json` holds every A52s run of the three backends; `studio/spikes/p08/{canvas,flutter_scene,thermion}/result.json` the spike records; `dome-assembling-choisy-8s.mp4` (1080×1920, 192 frames, 8.00 s) the hook; 41 stills cover 360/390/430 dp EN/TR at 100/200%, the panels, the styles and the reduced-motion story. Earlier evidence remains in `studio/captures/P07/`, `P06/` and `AUDIT-2026-10-08/`. See `PROGRESS.md` for scores and remaining acceptance.

---

## 1. What we are building

**Promise.** Open the app and within ten seconds you see something in Istanbul you had never noticed. Understand why it matters, collect it, share it, then go and stand in front of it.

**Why people will come (the hook ladder).** Each rung has a phase that builds it.
1. **The reveal:** a detail you would never have noticed, shown in motion and light (Milestones, P06–P31).
2. **The collection:** each discovery sets a tessera into your personal mosaic, and the empty slots pull you on (P19).
3. **The share:** a 9:16 loop that looks like nothing else in a feed, e.g. gold that shimmers as the phone tilts, or a dome assembling itself (P17).
4. **The visit:** "2.4 mil from mile zero" leads to a route, a hunt, or a then/now ghost lens held at the exact spot (P20, P21).
5. **The return:** the Daily Tessera, On-this-day entries and new Milestones each chapter (P18).

**Content order.** Byzantine first, then mosques, then museums, then the rest of the city (all 39 districts). One place can belong to several eras. Ayasofya, Kariye and Fethiye are single layered records, never duplicated.

**Platform.** Android only. Reference device: Samsung Galaxy A52s 5G (SM-A528B, Android 14), per the owner's chora-ar notes. No iOS work. The `web/` folder exists only for local previews.

## 2. Design doctrine (how Milion avoids looking AI-made)

**The idea.** The interface is a measuring instrument for a layered city: distance from mile zero, depth through time, and light across gold.

**Six signatures.** Build these once and reuse them everywhere; they are what make the app recognisable with the name hidden.
1. **Mile Zero dial.** A circular instrument on astrolabe logic: a rotating rete over a fixed plate, centred on the Milion. Rings are Roman miles and ticks are places by bearing. Rotate it with a thumb, with a haptic detent at each place. It appears on Today, in the Atlas and on share cards.
2. **The dig.** On a place page, scrolling down goes back in time through dated strata. A depth gauge on the edge shows the year under your thumb, and the hero image morphs between eras.
3. **Plates with leader lines.** Artworks appear full-bleed like catalogue plates. Details are annotated with hairline leader lines to margin captions, never with floating numbered bubbles.
4. **Light you hold.** Tilt the phone and the gold tesserae catch the light. Drag a candle or a grazing light across a relief. The sun crosses Süleymaniye at the real hour.
5. **Drawing-style space.** 3D is drawn like Choisy's axonometrics: hairline edges, poché cuts, hatching, worm's-eye views. It should read as a measured drawing come alive, not a game engine.
6. **Tesserae.** Progress, loading, rewards and collections are all made of tesserae that set into a real mosaic. Unfilled slots are outlined tesserae.

Other conventions: Milestones are numbered in Roman numerals, every place shows its distance as `IV mil · 5,9 km`, and non-original states carry honesty labels (§3).

**Palette.** Porphyry `#4E1B2B` (imperial stone and the brand colour), tessera gold `#C9A04C` (reserved for gold, collected items and rewards), Proconnesian marble `#EEE7DB`, lamp black `#151314`, İznik cobalt, İznik bole red, turquoise and verdigris. Each wave has its own colour code: Byzantine is gold on porphyry, mosques cobalt and turquoise, museums verdigris and bronze.

**Type roles.** Inscriptional capitals for display, a humanist text face with full Turkish and Greek glyphs, and tabular numerals. P03 selects Cinzel with Noto Serif Display for Greek fallback, Noto Sans for text and tabular measurements; all three are bundled offline with OFLs (Decisions).

**Banned (the anti-slop list).** P03 enforces this list and every later phase re-checks it.
- The hero formula of eyebrow, big serif headline, paragraph and two buttons (the former "Stories beyond the surface." home).
- Rounded-card grids and equal-card carousels, pill-chip rows as main navigation, glassmorphism, decorative gradients, shadows used for hierarchy.
- Arched image frames, crescent, cross or tulip clip-art, skyline silhouettes, fake paper, grain or aged textures, marble-photo backgrounds.
- Material icons standing in for cultural concepts, and emoji in the UI.
- The default "AI fonts": Cormorant, Playfair, DM Sans, Inter, Poppins, Montserrat, Fraunces.
- Filler words: discover, journey, timeless, step into, magic, hidden gems, rich history, beyond the surface.
- Motion for its own sake: parallax on text, bouncing buttons, looping figure puppetry.

**Copy rule.** Every line carries a checkable name, number, date or observation. Turkish is written natively, not translated. For example, *"Discover the magic of Chora"* fails the rule, while *"Christ grabs Adam and Eve by the wrist, not the hand."* passes it.

## 3. Motion doctrine and the Milestone collection

**Honesty labels**, shown on every non-original state:
- **ORIGINAL:** the photograph, untouched.
- **DEPTH:** the same pixels, given depth, light or camera movement.
- **RECONSTRUCTION:** added or replaced pixels or geometry, based on cited evidence.
- **IMAGINED:** plausible invention for storytelling (legends, lost faces, animal motion).

**Rules**
1. Start from the original, and keep every other state one tap away from it.
2. Sacred figures are not puppets. No looping deformation of holy figures' bodies or faces. A gesture may appear only as a single story-motivated beat at gentle strength, labelled IMAGINED.
3. Move what actually moves: light, water, fire, cloud, fabric in wind, animals in secular scenes, the camera, and the user's own hand (wipe, candle).
4. Every Milestone has three parts: a 10-second reveal (the moment people share), a 20–40 s story, and free exploration.
5. Every Milestone has a still-sequence equivalent for reduced motion and a TalkBack description.
6. Mosques are about architecture, light, geometry, writing and craft. Never animate worshippers and never invent sacred imagery.
7. Budgets:

| Kind | Geometry | Textures | Frame rate |
| --- | --- | --- | --- |
| 2.5D plate | ≤ 60k vertices | ≤ 150 MB | 60 fps |
| 3D, drawing style | ≤ 20k triangles per study (P08: the Canvas renderer is CPU-bound on the A52s) | — | ≥ 50 fps |
| 3D, immersive | — | — | ≥ 30 fps |

**Verdict on the current animations** (examined 2026-09-26 from renders and 6-frame contact sheets of each v2 preview)

| Current piece | Verdict | What to do |
| --- | --- | --- |
| Relief v5 depth, with the original/relief comparison | Strongest asset | Keep it as the base of the Plate engine. |
| Figure puppetry v2: 48-pose ARAP loops at "Bold", up to 51 px travel | Weakest asset | Hands and faces slide against their painted outlines, the loop reads as puppetry, and it animates sacred figures for no story reason. Demote it to an optional "Gesture study" (IMAGINED) and reuse the rigs only for single gentle beats. |
| 4K "Restored" AI repaint, the default Restored view | Misleading as a default | It replaces the fresco's worn surface with a glossy new icon. Use it only as a local wipe in damaged zones, labelled RECONSTRUCTION. |
| Explorer controls: Pose, Movement and Restoration sliders, a 3-way toggle and a chip row | Poor layout | They take about 45% of a phone screen. Replace them with three icons: Story, Light, Layers. |

**Technique codes**

| Code | Technique | Best for |
| --- | --- | --- |
| DP | Depth parallax (gyroscope or drag) | Frescoes and mosaics with figures |
| GL | Gilded light: specular tesserae follow the tilt | Gold grounds, glazed tiles |
| RL | Raking light or candle | Reliefs, carving, graffiti, sarcophagi |
| PU | Pop-up diorama layers | Miniatures, sections, crowded scenes |
| WR | Wipe to reconstruction | Damage, lost polychromy |
| SB | Story beats: guided camera plus captions | Narrative cycles, long friezes |
| MM | Micro-motion: flow maps inside masks | Fire, water, sky, animals |
| SR | Stroke or construction reveal | Calligraphy, girih, tile outlines, inscriptions |
| LU | Look-up: the dome or panorama mapped around you | Domes, vaults, panoramas |
| CA | Choisy assembly (3D) | Buildings |
| CS | Cutaway section plane (3D) | Domes, complexes |
| WK | Walkable space (3D) | Cisterns, interiors |
| TT | Turntable object (3D) | Museum objects, reconstructions |
| TM | Time model (3D or map) | Sites and the city through the eras |
| SK | Sky simulation: real sun and moon | Light, legends |
| VO | Voices: convolution acoustics | Domes, cisterns |

**The Milestone register** (the collection). Ship target: at least 40 of these 48 approved, including every flagship (★).

| No. | Milestone | Place | Codes | The hook | Phase |
| --- | --- | --- | --- | --- | --- |
| 0 ★ | The Milion | Divanyolu | CA TM | Every distance in the empire was measured from this stone. | P04 (lite), P13 |
| I ★ | Anastasis | Chora | DP GL SB WR | Christ grabs Adam and Eve by the wrist, not the hand. | P06 |
| II | The Last Judgment | Chora | DP MM GL SB | An angel rolls up the sky like a scroll; the river of fire flows. | P06 |
| III | Metochites offers Chora | Chora | GL SB | The man who paid for it all, in a hat wider than his shoulders. | P07 |
| IV | The Genealogy dome | Chora | LU GL | Hold your phone up and Christ's ancestors surround you. | P07 |
| V | The Enrollment for Taxation | Chora | SB | A Roman census, set in mosaic 1,300 years later. | P07 |
| VI | Chora through time | Chora | CA | Four building campaigns in one small church. | P11 |
| VII ★ | The Deesis | Hagia Sophia | GL WR SB | Tilt the phone: the gold does what it did by candlelight around 1261. | P12 |
| VIII | Zoe's changing emperor | Hagia Sophia | SB WR | Three husbands, one face slot. | P12 |
| IX ★ | The dome that fell | Hagia Sophia | CA CS | 558: the dome falls; the new one is built higher. | P12 |
| X | Halvdan was here | Hagia Sophia | RL | A Viking carved his name into the gallery parapet. | P12 |
| XI | Sing in Hagia Sophia | Hagia Sophia | VO | Hear your own voice ring for about ten seconds. | P22 |
| XII | The Hippodrome through time | Sultanahmet Square | TM | Chariot races for up to 100,000 people, under today's park. | P13 |
| XIII | The Obelisk base | Hippodrome | RL | The emperor watches the races, carved in 390. | P13 |
| XIV | The Serpent Column | Hippodrome | TT WR | From Delphi, 479 BC; one head is in a museum across the street. | P13 |
| XV | Great Palace animals | Great Palace Mosaic Museum | MM DP | An eagle fights a snake on the emperor's floor. | P13 |
| XVI ★ | The Basilica Cistern | Yerebatan | WK | 336 columns under the street; Medusa upside down. | P14 |
| XVII | The harbour under the metro | Yenikapı | PU SB | Digging a metro found 37 shipwrecks and 8,000-year-old footprints. | P14 |
| XVIII ★ | The Land Walls | Theodosian Walls | PU SB | Scroll the whole wall, Marmara to Golden Horn. | P15 |
| XIX | 1453 in 53 days | Walls / Golden Horn | TM SB | Ships dragged over a hill to get past the chain. | P15 |
| XX | Küçük Ayasofya | Küçük Ayasofya | CA SR | Justinian and Theodora's names still circle the cornice. | P16 |
| XXI | The Pammakaristos chapel | Fethiye | GL | A small gold chapel most visitors never find. | P16 |
| XXII | Valens Aqueduct | Bozdoğan Kemeri | CA TM | Water crossed this valley for fifteen centuries. | P16 |
| XXIII ★ | The Süleymaniye külliye | Süleymaniye | CA CS | A mosque with a hospital, soup kitchen, schools and a hamam. | P25 |
| XXIV | Light at this hour | Süleymaniye | SK CS | The sun inside Süleymaniye right now. | P25 |
| XXV | The soot room | Süleymaniye | PU SB | Lamp smoke caught and turned into ink. | P25 |
| XXVI | Rüstem Paşa's tile garden | Rüstem Paşa | GL SR | Name the flowers on 16th-century walls. | P26 |
| XXVII | Mihrimah's equinox | Mihrimah Sultan ×2 | SK | Sun behind one minaret, moon between two (legend). | P26 |
| XXVIII | Şehzade's symmetry | Şehzade | CA | The building Sinan called his apprentice work. | P26 |
| XXIX | Muqarnas | Craft kit | CA | A stone honeycomb assembles cell by cell. | P24 |
| XXX | Girih | Craft kit | SR | Draw one star with a compass; it tiles forever. | P24 |
| XXXI | Making an İznik tile | Craft kit | PU GL | Pounce, outline, cobalt, bole red, fire. | P24 |
| XXXII | 20,000 tiles | Sultanahmet | SB | Zoom from the skyline to a single tulip. | P27 |
| XXXIII ★ | Evolution of the dome | Cross-city | CA TM | 1,475 years of Istanbul domes at the same scale. | P27 |
| XXXIV | Mahya | Cross-city | SR | Write your message in lights between two minarets. | P27 |
| XXXV | Calligraphy, stroke by stroke | Hagia Sophia / Süleymaniye | SR | A 7.5 m roundel written with a reed pen. | P24 |
| XXXVI ★ | Alexander Sarcophagus in colour | Archaeology Museums | RL WR | It was painted; see it the way Sidon did. | P28 |
| XXXVII | The Kadesh treaty | Archaeology Museums | SR | The earliest known peace-treaty text, line by line. | P28 |
| XXXVIII | The Topkapı dagger | Topkapı | TT | Emeralds, a watch in the hilt and a heist film. | P29 |
| XXXIX | The Harem maze | Topkapı | CA CS | Hundreds of rooms revealed as you walk. | P29 |
| XL | The carpet weaves itself | Turkish & Islamic Arts | SR | Knot by knot, the carpet Holbein painted. | P30 |
| XLI | The Tortoise Trainer | Pera Museum | MM | Turkey's most famous painting, gently alive. | P30 |
| XLII | Panorama 1453 | Panorama 1453 Museum | LU | Stand inside the siege painting. | P29 |
| XLIII | The sultan's caique | Naval Museum | TT MM | The rowing boats of the Bosphorus court. | P30 |
| XLIV | Mehter | Military Museum | VO MM | The band behind Mozart's "Rondo alla Turca". | P30 |
| XLV | The Golden Horn chain | Military Museum | TT TM | The chain that closed the Golden Horn. | P30 |
| XLVI | The Horses of San Marco | Venice (from the Hippodrome) | TT TM | Taken from the Hippodrome in 1204. | P31 |
| XLVII | The Tetrarchs' foot | Venice / Archaeology Museums | WR TM | The statue is in Venice; its foot is in Istanbul. | P31 |

Every hook is a claim that must be verified and sourced in its phase before approval. A Milestone is **approved** only when all of the following hold:
- It plays from its manifest, and its reveal, story and exploration all work.
- Its honesty labels are correct, and EN+TR captions and sources are present.
- The reduced-motion and TalkBack equivalents work.
- It meets its budget on the reference device.
- It has a share export (P17 onward).

## 4. Ship scope (what 100% means in numbers)

| Area | Ship target |
| --- | --- |
| Reviewed places | ≥ 110: ≥ 30 Byzantine, ≥ 30 mosques, ≥ 25 museums/palaces, the rest other heritage; every one of the 39 districts has ≥ 1 |
| Milestones | ≥ 40 of the 48 approved, all ★ included |
| Chora | 103/103 artworks complete (title, cues, story, inscription where present, sources, EN+TR) |
| Routes / hunts / ghost-lens viewpoints | 12 / 6 / 30 |
| Daily Tessera pool / On-this-day entries | 365 / 120 |
| Languages | Turkish and English at 100%, UI and content |
| Performance and size | P36 budgets met on the reference device; base download ≤ 60 MB |
| Recognition | P23 gates met, or the feature ships labelled Beta |
| Field | P39 trial run and every P0/P1 finding fixed |
| Release | Signed AAB accepted by Play; store listing live in TR and EN |

## 5. Standing rules (apply to every phase)

1. **Start by reading.** Read PHASES.md and PROGRESS.md first. Inspect the code you will touch before editing it. The workspace is `/Users/memre/Desktop/milion`.
2. **Show the result.** Every phase ends with something visible. Save screenshots and clips to `studio/captures/<phase>/`. Use `adb shell screenrecord` when a device is connected (O01); otherwise use golden or integration-test frames, and mark on-device checks as *unverified*.
3. **Quality gate.** Before finishing:
   - `flutter analyze` is clean.
   - `flutter test` is green, with new logic tested.
   - A release build succeeds.
   - Content validation passes (from P02 on).
4. **Bilingual from P03 on.** Every new UI string goes through ARB (EN+TR), and every content text is `{en, tr}`. Turkish casing must be correct (İ/ı).
5. **Honesty.** Apply the labels in §3 and cite sources on every factual record (Wikidata QID for places). Keep uncertain claims, legends and scholarly debates marked as such. Never alter source originals, and keep their hashes.
6. **Anti-slop gate.** Check every new screen against §2's banned list and copy rule before finishing.
7. **Attraction.** Every content phase adds at least one shareable moment (saved as a vertical clip or still) and at least three stop-scrolling facts to the Daily and On-this-day pools.
8. **Rights.** Copyright is deferred by owner decision during private development. Still record every image, model or audio source URL, so rights can be cleared before public release (O11).
9. **Scope discipline.** Do not build a later phase's feature early. If a phase reveals that the plan is wrong, change the plan in this file and explain the change in Decisions.
10. **Commit.** Commit at the end with `Pxx: <summary>`. Never commit keystores, `key.properties` or secrets.

## 6. Phase map

| Stage | Phases | Visible at the end of the stage |
| --- | --- | --- |
| A Foundation | P00–P05 | New identity, lean codebase, content registry, design system, new shell with Today, Chora dig page |
| B Engines | P06–P10 | Plate engine with remastered I–II, the plate pipeline with III–V, 3D runtime, procedural kit, offline era Atlas |
| C Byzantine | P11–P16 | Chora complete, Hagia Sophia, Hippodrome and Milion, cisterns, walls, 30 Byzantine places |
| D Attraction | P17–P23 | Share studio, Daily Tessera, Mosaic, ghost lens, routes and hunts, voices, point-and-reveal |
| E Mosques | P24–P27 | Craft kit and visiting layer, Süleymaniye, Sinan's city, 30 mosques, evolution of the dome, mahya |
| F Museums | P28–P31 | Museum kit, Archaeology Museums, Topkapı and palaces, city collections, Istanbul abroad |
| G Whole city | P32–P33 | All 39 districts, search and discovery at scale |
| H Ship | P34–P40 | Full TR/EN, accessibility, performance and packs, reliability, CI, field trial, store launch |

---

## 7. Phase prompts

### P00 — Milion identity and plan — IMPLEMENTED LOCALLY (2026-09-26)

```text
Phase P00 — Milion identity and plan (re-run = audit only). Workspace: /Users/memre/Desktop/milion. Android-only Flutter app.
Read PHASES.md and PROGRESS.md first.

This phase is complete. Re-running it must verify, never redo:
- App label "Milion"; Dart package milion; applicationId/namespace app.milion; MainActivity at android/app/src/main/kotlin/app/milion/; theme at lib/theme/milion_theme.dart (MilionTheme, MilionMark, MilionWordmark); milion.iml and android/milion_android.iml.
- Mark = an inscriptional M holding the gilded zero of the Milion stone in its vertex (M + 0, mile zero; porphyry, marble, tessera gold). tool/build_milion_identity.py regenerates assets/brand/milion-mark.svg, milion-icon.png, the five launcher densities, the adaptive/themed icon (milion_foreground / milion_monochrome), the Android 12+ splash and the web icons. Its geometry must match MilionMark.
- No "izvoya" identifier left in lib/, test/, tool/, android/, web/ or pubspec.yaml (history mentions in the two .md files and archive/ are expected). Only PHASES.md and PROGRESS.md exist as Markdown.
- flutter analyze clean, flutter test green, release APK builds, aapt shows package app.milion and label Milion.
Report any drift and fix only that drift.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P01 — Clean slate — IMPLEMENTED LOCALLY (2026-09-27)

```text
Phase P01 — Clean slate: version control, pruning, reproducible tooling. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md (sections 2–5) and PROGRESS.md first. Depends on P00.

Goal: a lean, reproducible codebase the next 39 phases can build on.
1. Git: `git init` if absent; .gitignore for build/, .dart_tool/, android/.gradle, android/.kotlin, local.properties, key.properties, *.jks, studio/cache/, tool/**/__pycache__. Commit "P01 baseline" BEFORE deleting anything. Use Git LFS for *.jpg *.png *.bin *.onnx *.glb *.mp4 if git-lfs is installed; otherwise add an Open issue.
2. Prune the runtime. Keep only the current explorer path for Anastasis (F02) and Last Judgment (F05). Remove the archived v3 conch relief (anastasis_relief.dart, conch_geometry.dart, anastasis_dome_view.dart and their tests), the "Classic v5 viewer" screens, v1 figure data, the earlier restoration studies duplicated by the 4K ones, and assets/anastasis/relief + relief_v3 (~26 MB). grep before each deletion to prove nothing still references it. Keep every source photograph.
3. Studio: move anastasis_25d/, last_judgment_25d/, figure_animation/, restoration_studies/, ui_refresh/ under studio/ (same inner structure); move capture/screenshot tests from tool/ to tool/captures/; create studio/captures/. Fix every script and test path.
4. Path independence: replace the hard-coded /Users/memre/Desktop/chora-ar/... defaults with env var MILION_CAPTURES (default: ../chora-ar/captures relative to the repo); fail with a clear message if it is missing.
5. Check upstream flutter_onnxruntime: if a release newer than 1.8.5 drops `apply plugin: "kotlin-android"`, delete third_party/flutter_onnxruntime and the dependency_overrides entry, then rebuild without the KGP warning (O19).
6. Python: tool/requirements.txt pinned from the imports actually used; a one-line usage docstring at the top of each script (no README files).
7. Android: set minSdk 26 (record the reason in Decisions). Enable R8 and resource shrinking for release, with keep rules proven by a working release build of camera + ONNX. Release signing reads android/key.properties when present and falls back to debug with a loud Gradle warning. Remove unneeded merged permissions (RECORD_AUDIO, legacy storage) with tools:node="remove", verified with `aapt dump permissions`. Configure per-ABI APKs for local installs; AAB stays the release artifact.
8. Measure and record: arm64 APK size, AAB size, lib/ Dart line count, test count.
Acceptance: analyzer clean, tests green; both Milestones still open with Original/Relief/Restored; arm64 release APK at least 25% smaller than the 203.8 MB universal baseline; git log has the baseline and phase commits.
Demo: a before/after size table in PROGRESS.md.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P02 — Content registry and mile-zero geography — IMPLEMENTED LOCALLY (2026-09-27)

```text
Phase P02 — Content registry and mile-zero geography. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md (sections 1–5) and PROGRESS.md first. Depends on P01.

Goal: one typed, validated content model that can hold all of Istanbul, with Chora migrated into it and a seed registry placed by distance from the Milion.
1. Models in lib/content/:
   - Place: global kebab id; current TR and EN names; historical names with eras and Greek where relevant; category set (byzantine, mosque, museum, palace, fortification, cistern, tower, bazaar, bath, other); district (enum of all 39); lat/lng plus entrance lat/lng; current function; status (open/closed/restoration/ruin/unknown) with checkedAt; Wikidata QID; tags.
   - Stratum: from/to years, era key, title, body, media, sources.
   - Artwork: place, room/position, kind.
   - Milestone: numeral, technique codes from §3, honesty labels, status planned/prototype/approved, manifest path, pack id.
   - Also Route, Hunt, Source (title, url, author, accessed date, licence if known) and Media (path, kind, credit, source, era, historical photo flag).
   - Every user-facing text is Localized {en, tr}.
2. Storage and validation:
   - JSON under assets/content/ (places/, milestones/, sources.json), loaded through a repository with a schema version.
   - Strict validation: unique ids; known district; coordinates inside the Istanbul province bounding box (bonus places outside must be flagged); EN required; missing TR counted.
   - A `dart run tool/content/validate.dart` CLI that prints counts per category, district, era and wave, and exits non-zero on errors.
   - Valid and invalid fixture tests.
3. Milion geometry: research and cite the Milion fragment's coordinates. Compute great-circle distance and bearing to every place, in km and Roman miles (1 mille passuum ≈ 1,480 m; cite the value). Provide a formatter for "IV mil · 5,9 km" with TR/EN number formats.
4. Migrate Chora: the 103 scenes become Artworks of place "chora", keeping the ids M03, F02… F02 and F05 become Milestones I and II. Existing scene notes must keep working (migration test).
5. Seed registry: create a draft record for every place named anywhere in PHASES.md (Milestone register and phase prompts), with category, district, coordinates and QID verified via Wikidata/OSM, and a one-line EN+TR hook. Drafts stay hidden from users until their wave phase reviews them.
6. Decouple: the catalogue no longer comes from the classifier; the classifier only maps predictions to artwork ids.
Acceptance: validator passes; the 103 Chora artworks load with no ONNX session; at least 90 draft places with QIDs; distance/bearing tests against two independently computed references; notes survive.
Demo: a debug "Registry" screen (long-press the version in About) listing places by mil distance, with counts per category and district.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P03 — Design language "Porphyry & Tessera" — IMPLEMENTED LOCALLY (2026-09-28)

```text
Phase P03 — Design language "Porphyry & Tessera". Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md (section 2 is the brief) and PROGRESS.md first. Depends on P01.

Goal: a design system that could only belong to Istanbul, which every later screen is built from. No generic editorial template.
1. Tokens (lib/design/):
   - Two schemes: "marble" (light) and "lamp" (dark). Artwork views are always lamp.
   - Colours: the palette in §2 plus the wave colours; tessera gold is reserved for gold, collected items and rewards.
   - A 4-dp spacing grid.
   - Shapes squared, radius ≤ 2 dp. Tessera chips have a 1-px irregular edge. No elevation: separation comes from hairlines, dimension lines and poché.
2. Typography: render specimen screens, then choose.
   - Display, inscriptional caps: test Cinzel, Forum, Marcellus, GFS Neohellenic, Noto Serif Display.
   - Text: test Literata, Source Serif 4, Alegreya, Noto Serif/Sans, IBM Plex Sans.
   - Test string: "İstanbul Ayasofya Süleymaniye Eyüpsultan Kılıç Ali Paşa Şehzadebaşı ığüşöçİĞÜŞÖÇ · Η ΑΝΑϹΤΑϹΙϹ ΙϹ ΧϹ · XLVII · 3,4 mil".
   - Bundle the fonts offline with OFL licences registered. Remove Cormorant Garamond and DM Sans.
3. Components, each with a golden test in both schemes:
   - MilestoneNumeral, MilDistance, HonestyLabel (Original/Depth/Reconstruction/Imagined), StrataBand, DepthGauge.
   - LeaderLineCallout: annotations drawn as hairlines to margin captions.
   - PlanIcon set: a custom 24-dp icon family drawn as architectural plan symbols (dome on square, minaret, column, gate, cistern grid, vitrine, route, tessera, camera-eye, sound, light, layers, story).
   - ScaleBar, NorthArrow, TesseraLoader, Empty/Error states with specific copy, and a bottom sheet with a dimension-line handle.
4. Motion and haptics: tokens for settle (tessera snap), dig and sweep, with durations, curves and reduced-motion variants. Haptic ticks: light for detents, medium for collecting.
5. Localization: flutter_localizations plus app_en.arb and app_tr.arb, and an in-app language override. From now on every UI string goes through ARB.
6. Design sheet: a hidden /design route showing every token and component in both schemes at 100% and 200% text.
7. Two directions: mock the Today composition as working screens in direction A (lamp-first) and direction B (marble-first with porphyry). Pick one, give the rationale in Decisions, and add an owner taste check to Open issues (non-blocking).
8. Reskin the existing screens with the tokens; the layout redesign is P04/P05. Strip the banned hero formula from the current home.
Acceptance:
- Every §2 banned pattern is absent from shipped screens.
- Contrast ≥ 4.5:1 for body text.
- Turkish and Greek glyphs render correctly.
- Goldens pass.
- Screenshots at 360, 390 and 430 dp are saved to studio/captures/P03/.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P04 — Shell, Today and the first ten seconds — IMPLEMENTED LOCALLY (2026-10-01)

```text
Phase P04 — Shell, Today and the first ten seconds. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P02, P03.

Goal: open the app and within ten seconds be looking at something astonishing, with no permission, account or visible loading.
Build on P03 direction B (marble with porphyry; artwork views always lamp), `lib/design/` and EN/TR ARB. The A/B screens under `/design` are composition trials, not the real dial, first-run flow or daily pool.
1. Navigation: four destinations, Today/Bugün, City/Şehir, Milestones/Taşlar, Mosaic/Mozaik, drawn with PlanIcons.
   - Scan leaves the tab bar. It returns as a camera-eye action only on places and artworks with recognition support.
   - Predictive back (Android 14) works, tab and scroll state are restored, and the layout is edge-to-edge with correct insets.
2. First run (once, replayable from About): Milestone 0 lite, a 12-second sequence.
   - Black screen, then one gold tessera, then the camera pulls back to the Milion on Divanyolu, drawn in our own line style.
   - Roman-mile rings then spread over a minimal peninsula map and five places light up.
   - One line, "Every road started here.", then land on Today.
   - Skippable after 2 s. Reduced motion shows three stills; TalkBack reads a one-sentence version.
3. Today (a composition, not a feed):
   - (a) Detail of the day: a full-bleed crop of an artwork detail, one checkable sentence and its Milestone numeral. Tapping opens that Milestone at that exact detail via a shared-element transition.
   - (b) The Mile Zero dial: rings in Roman miles, reviewed places as ticks by bearing. Rotate with a thumb, with haptic detents; tap a tick to open the place. Include a list alternative.
   - (c) A mosaic progress strip.
   - (d) The current chapter (Byzantine) and its next Milestones.
4. Milestones tab: the numbered register from §3.
   - Numeral, technique PlanIcons, honesty label, place and mil distance.
   - Planned pieces appear as outlined tessera slots, so the empty slots create the urge to collect.
5. City tab: reviewed places by mil distance until P10 delivers the Atlas. Mosaic tab: a placeholder showing notes until P19.
6. Detail-of-the-day pool: at least 14 curated Chora details, rotated deterministically by date, EN+TR.
Acceptance:
- Profile-mode cold start to an interactive Today in under 2 s on the emulator, or on the device if O01 is resolved.
- No permission prompt on first run; back behaviour correct.
- Layout holds at 200% text; TalkBack completes the first-run sequence and Today.
Hook: save the first-run clip and three Detail-of-the-day stills to studio/captures/P04/.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P05 — Place page: the dig — IMPLEMENTED; ACCEPTANCE OPEN (audited 2026-10-08; repaired 2026-10-12)

The 2026-10-12 audit repaired: the oldest layer was unreachable by scrolling on every page (the page end now selects it; Chora and Hagia Sophia regression tests fail without the fix), interrupted gauge animations forced the wrong layer, the 200% title clipped, and Go was announced only as "Go". Four content claims were corrected with official sources, and the validator now requires Turkish strata. Still open: a present-day photo in the header (the 2020– hero is the Anastasis fresco), finer periods than the coarse `Era` (1321, 1077 and 330 all read "Byzantine"), the 2020– layer repeating the visit card, adjacent unlabelled Sources toggles, a testable "Report a change" address (O17), and the shared source-lookup duplication in `lib/city/`.

```text
Phase P05 — Place page: the dig. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P04.

Goal: every place is a vertical archaeological section; scrolling down goes back in time.
Use the P02 registry. Replace the temporary `sceneForArtwork` adapter as artwork widgets become typed; do not reintroduce catalogue data into the classifier.
Grow the P04 present-day header (`lib/city/place_screen.dart`) into the dig. Per the P05 Decisions, individually sourced strata can render on an explicitly labelled draft; drafts without authored strata show only their checked name, position and sources (P04 Decisions). Place-level approval remains with the wave reviews.
1. Composition:
   - The top is the present: today's photo, current name and function, status with its checked date, mil distance, and "Go", which opens Google Maps walking directions by intent.
   - Scrolling down passes through only the relevant strata: Republic, Late Ottoman, Classical Ottoman, Late Byzantine, Middle Byzantine, Early Byzantine, Roman/Byzantion, Prehistory.
   - A DepthGauge on the edge shows the year under the thumb and snaps to strata, e.g. 2026 → 1945 → 1511 → 1321 → 1077.
   - The hero crossfades to each era's image or line illustration as its band passes.
2. Each stratum holds a dated title, 2–4 short fact-dense paragraphs, media, that layer's artworks, that layer's Milestones (as the big entry point) and collapsible sources.
3. Visit card (present layer):
   - Opening-hours text with its checkedAt date, entry notes, and dress/etiquette for mosques.
   - Accessibility notes, and the nearest tram/metro/ferry stop with walking minutes.
   - "Report a change": a mailto link to the owner's address (O17).
4. Build Chora as the first full page, from data only. Its layers, each verified and cited:
   - The Byzantine foundation tradition "in the country" outside Constantine's walls, distinguished from the excavated sixth-century foundations.
   - The Komnenian rebuilding (Maria Doukaina, then Isaac Komnenos); surviving fourteenth-century mosaics belong to the Metochites layer.
   - Theodore Metochites, 1315–21.
   - Mosque in 1511.
   - Byzantine Institute restoration and the museum years.
   - Mosque status again in 2020, the postponed October opening, and the 2024 reopening.
5. No place-specific widgets: add a draft Hagia Sophia page with two strata purely from JSON to prove it.
Acceptance:
- Chora complete in EN+TR with sources.
- Smooth scrolling in profile mode.
- DepthGauge announces years to TalkBack.
- Reduced motion swaps morphs for cuts.
Hook: a 9-second vertical recording of digging through Chora's layers.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P06 — Plate engine and remastered Milestones I–II — IMPLEMENTED LOCALLY; ACCEPTANCE OPEN (2026-10-08)

Repaired 2026-10-12 (Decisions): one-beat wrist without a texture pop, filtered samplers, lit and seamless masked effects, the scroll pivot on its mask, gyro decay, story camera that respects the user's zoom, TalkBack descriptions and actions, honest IMAGINED labels for moving paint, and no reconstruction wipe for II. Originally implemented in `lib/plate/` with two manifests, eight maps and `shaders/plate.frag`. Catalogue-based routing replaces `explorerFor`/`ExplorableScene` across Today, the register, artworks and Scan. All 17 P04 windows/anchors/sentences are preserved. Both plates have original-first controls, opt-in tilt, GL/RL/Candle, a damage-only 4K wipe, 10 s reveals, 32 s stories and reduced-motion manual stills. Anastasis has one scoped 1.2 s IMAGINED wrist beat; Judgment uses masked river/scroll effects. Advanced studies are debug-only. Local parsing/timeline/touch/still/dispose/pixel tests, all light goldens and the three 8 s clips pass. Decoded texture and vertex counts are below the local caps; total device GPU memory, A52s 60 fps, physical gyro/TalkBack and human content/image acceptance remain open (O01/O08/O11/O22). I–II remain prototypes.

```text
Phase P06 — Plate engine (2.5D v2) and remastered Milestones I–II. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md (section 3 is the brief, including the verdict on the current animations) and PROGRESS.md first. Depends on P03, P04.

Goal: one data-driven 2.5D player for every Milestone, and the two Chora pieces remastered under the motion doctrine.
1. Generalise interactive_relief_surface / figure_rig into lib/plate/: a PlateManifest (layers; depth, normal, specular and flow maps; mesh; details with leader-line anchors; beats; labels) and a PlatePlayer widget.
   - The P04 `details` records (window, anchor, sentence) become the manifest's leader-line details, and Today's shared element must keep landing on the same pixels. Replace the `explorerFor` / `ExplorableScene` adapter.
2. Capabilities:
   - DP: depth parallax from the gyroscope (sensors_plus, low-pass filtered, ±6°, recentres on touch), with drag as the fallback.
   - Light modes as FragmentProgram shaders: GL gilded (specular gold follows the tilt), RL raking (drag the light), Candle (a dark screen with a warm point light under the finger; flicker below 3 Hz).
   - WR wipe with the finger to a RECONSTRUCTION layer; long-press peeks at the ORIGINAL.
   - SB beats: a scripted camera path with captions, 20–40 s, pausable and scrubbable.
   - MM micro-motion: flow-map UV scrolling inside masks only.
3. Controls: the main UI is the full-bleed artwork, three PlanIcons (Story, Light, Layers) and the honesty label. The Pose, Movement and Restoration sliders move to a debug panel.
4. Remaster I (Anastasis):
   - GL on the mandorla, stars and halos.
   - One SB gesture beat, the wrist-grip pull of Adam and Eve, using the existing rig at gentle strength for about 1.2 s and then settling.
   - WR to the 4K reconstruction only in the damaged zones.
5. Remaster II (Last Judgment):
   - MM for the river of fire flowing.
   - The scroll of heaven rolling as a UV spiral inside its mask (not a body warp).
   - SB through the Deesis, plus GL.
6. Preserve P03’s original-first, default-off IMAGINED Gesture study (one gentle 6-second playback, never a loop) until the story-motivated beat replaces it. Move its advanced sliders to the debug panel with the other legacy controls; keep one-tap ORIGINAL and the reduced-motion manual/still alternative.
7. Performance and memory:
   - Plates are disposed on exit.
   - Textures stay ≤ 150 MB per plate.
   - Target 60 fps on the A52s. If the device is not connected, profile on the emulator and mark the result unverified.
Acceptance:
- Both Milestones run purely from manifests.
- Tests cover manifest parsing, the beat timeline, reduced motion (a still sequence) and dispose.
- Goldens exist for every light mode.
Hook: three 8-second vertical clips (gold tilt, the river of fire, the wrist-grip beat) in studio/captures/P06/.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P07 — Plate production line and Chora Milestones III–V — IMPLEMENTED LOCALLY; ACCEPTANCE OPEN (2026-10-12)

`python3.11 tool/plate/build.py studio/plates/<id>/plate.yaml` runs stages (a)–(f) from `tool/plate/stages/`; `--all` rebuilds every plate and `tool/content/rebuild.py` includes it. I and II reproduce P06 on every shared field from yaml alone (a test compares them with frozen P06 fixtures). III (Metochites), IV (the Genealogy dome, LU) and V (the Enrollment) come from single sourced Kültür Envanteri photographs, with 7/6/8 page-cited details, 34–35 s stories, reveal moments and validation reports. LU maps the dome photograph through a rectilinear lens model with a measured rim ellipse and uses Android's game rotation vector after an opt-in, with a flat pan fallback. Manual minutes are agent estimates (25/35/25); a human authoring run has not been timed. Device feel, GPU memory and 60 fps remain O01; native review O08.

```text
Phase P07 — Plate production line and Chora Milestones III–V. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P06.

Goal: turn one good photograph into an approvable Plate in hours, not days.
1. Pipeline, run as one command: `python3.11 tool/plate/build.py studio/plates/<id>/plate.yaml`. Stages:
   - (a) Ingest: sRGB, ≤ 4096 px, EXIF stripped, hash recorded.
   - (b) Segmentation: SAM2 or the existing SAM tooling with prompts from the yaml; manual mask PNGs override it.
   - (c) Depth: monocular depth (Depth Anything V2 or Marigold, whichever runs locally; measure both) blended with per-segment planar or bulge priors for flat walls. Normals come from the depth; a gold/specular mask comes from colour heuristics plus a hand mask.
   - (d) Optional pop-up layer split, with inpainting (LaMa or OpenCV) behind the lifted layers.
   - (e) Adaptive mesh with triangle-flip and tear validation, ≤ 60k vertices.
   - (f) Outputs: the manifest, WebP/KTX2 textures, a validation report JSON and a 6-second preview MP4 rendered by a headless Flutter test.
   - Document each stage's inputs and outputs in its docstring.
2. Prove it reproduces I and II from their inputs with no scene-specific code.
3. From the local corpus (MILION_CAPTURES → chora-scenes) produce:
   - III, Metochites offers Chora: GL and SB, with a beat on the skiadion hat.
   - IV, the Genealogy dome: LU. The dome photo is mapped onto a hemisphere; hold the phone overhead and look around with the rotation-vector sensor, with a flat-pan fallback.
   - V, the Enrollment for Taxation: SB across the register.
4. Each plate gets at least 5 leader-line details with EN+TR captions and sources, plus a marked "reveal moment" timestamp for sharing.
Acceptance: all three plates pass validation and play in the PlatePlayer; manual minutes per plate are logged in the PROGRESS counters.
Hook: the Genealogy look-up clip, filmed on the device if O01 is resolved.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P08 — 3D runtime and "How a dome stands" — IMPLEMENTED LOCALLY; DEVICE ACCEPTANCE OPEN (2026-10-13)

`lib/space/` loads glTF 2.0 studies (`assets/space/<id>/model.glb` + `study.json`) into the SpacePlayer. Candidate (a), a Canvas renderer (one `drawVertices` call, a painter's depth sort, poché from the inside faces of cut solids, hatching as a line-screen texture), was chosen for the drawing style. Both GPU candidates draw 50k triangles at 58–60 fps on the A52s and wait for P14's immersive decision. The study "How a dome stands" (20,144 triangles, 8 steps, 35 s story, 8 s reveal) is hand-written in `tool/space/how_a_dome_stands.py` and opens from Hagia Sophia's 537 layer. Open: ≥ 50 fps in every drawing view on the A52s (54–57 fps in the default Choisy view; 41–50 without the cut; 30 in Night), and the separate-UI-thread run (O01).

```text
Phase P08 — 3D runtime and the study "How a dome stands". Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P03.

Goal: real-time 3D on Android that looks like an architectural drawing come alive, not a game.
1. Spike, at most one day per candidate, measured on the reference device (or the emulator, marked unverified):
   - Candidates:
     - (a) A custom Canvas renderer: projected triangles via drawVertices, depth-sorted, flat-shaded, with edge lines and a clipping plane. This extends the existing relief renderer.
     - (b) flutter_scene / Flutter GPU.
     - (c) thermion (Filament).
   - Criteria: fps at 50k triangles, glTF load time, APK size delta, line rendering, Impeller/Vulkan and GLES stability, and maintenance activity.
   - Record the numbers and the decision in Decisions. Drawing-style exhibits and immersive ones (the cistern walk) may use different backends.
2. lib/space/ SpacePlayer:
   - Orbit, pan and zoom with limits, and a Choisy worm's-eye axonometric preset.
   - A draggable section plane, an assembly timeline (parts appear in order, labelled), an exploded view and a time scrubber.
   - Honesty label; a reduced-motion step-through of stills; dispose on exit.
3. Styles: Drawing (hairline edges, poché on cut faces, hatch shading), Stone (flat-shaded marble and brick with baked AO) and Night (warm lamp light).
4. First study, "How a dome stands": square bay → four arches → pendentives → ring → dome with a window row. Then the Ottoman cascade: the same bay with semi-domes. Hand-written geometry is fine here; P09 builds the generators.
5. Hooks for the P17 share studio: a PNG still and offscreen frame capture.
Acceptance: the study runs at ≥ 50 fps in Drawing style on the target device; the section plane and assembly scrubbing work; tests cover the camera limits and the timeline.
Hook: an 8-second vertical clip of the dome assembling in Choisy view.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P09 — Procedural architecture kit

P08 fixed the runtime contract (Decisions, 2026-10-13): glTF 2.0 binary, one named node per part, closed solids (the validator refuses open ones because poché needs them), at most 256 parts, an optional `_AO` attribute and a `material` extra; steps, labels and sources live in `study.json`. `lib/space/model.dart` does not decode `EXT_meshopt_compression` yet: add the decoder here or ship uncompressed. Keep each building near 20k triangles and faces about 2 m or smaller (the painter's sort slivers on large interpenetrating faces). `tool/space/glb.py` and `solid.py` (writer, closed-solid checks, baked AO) are the starting point.

```text
Phase P09 — Procedural architecture kit. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P08.

Goal: build Istanbul's buildings from a few lines of YAML.
1. Generators in tool/space/ (Python with numpy/trimesh; output glTF 2.0 with named parts and meshopt compression):
   - Domes and supports: dome (ribs, window count, drum), semi-dome, exedra, pendentive, squinch, arch and arcade.
   - Columns: column with capital types (Corinthian, impost, basket, muqarnas, lozenge), pier, buttress.
   - Ottoman elements: minaret (polygonal or round shaft, 1–3 şerefe on muqarnas corbels, conical cap), portico with domed bays, courtyard with şadırvan.
   - Infrastructure: cistern bay grid, wall curtain with square or polygonal towers, gate, stairs, simple terrain.
2. Spec format in studio/space/<id>.yaml:
   - A plan grid, parts with parameters, the assembly order and EN/TR labels.
   - Era tags, and the dimensions with their sources.
3. Validation:
   - Metric scale, north orientation and the triangle budget (≤ 150k).
   - Watertight where required.
   - Unit tests, e.g. the şerefe count and the window count.
4. Prove the kit with three specs:
   - Küçük Ayasofya: an octagon inside an irregular square.
   - Myrelaion / Bodrum Camii: a cross-in-square church on its substructure.
   - Şehzade Mosque: a square with four semi-domes and two minarets.
Acceptance: the three glTFs load in the SpacePlayer with assembly timelines; key dimensions are within 5% of the cited values.
Hook: three buildings assembling side by side, a 10-second clip.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P10 — The Atlas

```text
Phase P10 — The Atlas. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P02, P03.

Goal: a map of Istanbul that looks like it belongs to the city's own cartographic tradition, works offline and moves through time.
The Atlas replaces P04's City list in the City tab. Extend the pinned-Overpass approach of `tool/first_run/build_peninsula.py` rather than starting a second OSM pipeline.
1. Data, built by a tool/atlas/ script into compact assets (≤ 12 MB):
   - From OpenStreetMap: the province coastline and water, major roads, rail/tram/metro/ferry lines and stops, district boundaries, parks, and building footprints (historic peninsula only).
   - Hand-authored historic GeoJSON with sources: the Constantinian and Theodosian land walls, the sea walls, the old harbour coastlines (Theodosian, Julian/Sophia), the Mese and forums, the seven hills, the Galata walls, and the 1453 siege features.
2. Rendering:
   - A custom painter with projection, pinch and rotate, and level of detail.
   - A time slider (330 · 537 · 1200 · 1453 · 1560 · 1900 · today) that changes both the data and the drawing style:
     - Byzantine layers in a Buondelmonti-like manuscript manner.
     - Ottoman layers in a Matrakçı Nasuh-inspired bird's-eye manner, with coloured building glyphs and stylised water.
     - Today as a precise modern line map.
   - Styles blend between eras, and the coastline morphs where harbours were filled.
3. Milion rings: Roman-mile rings from the Milion. "From me" appears only after the user taps it and grants location (geolocator); everything works without location.
4. Below layer: a toggle or pull-down shows cisterns, palace substructures, the Yenikapı excavation and tunnels.
5. Places:
   - PlanIcon markers by category, with clustering. Tapping opens a sheet, then the dig page.
   - A list mode with identical filters (wave, era, category, district, open now, has Milestone) and full TalkBack support.
6. Directions: "Go" opens Google Maps walking directions by intent. No in-app navigation.
Acceptance:
- Works fully in airplane mode.
- Pans at 60 fps over the peninsula on the target device.
- The era slider animates; tests prove map/list parity.
Hook: a time-lapse clip of the peninsula from 330 to today, with walls and harbours appearing and vanishing.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P11 — Chora, complete

```text
Phase P11 — Chora, complete (the Byzantine flagship chapter). Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P05, P07, P09.

Goal: the most complete Chora guide that exists on a phone.
1. An interactive plan of Chora (a kit model or a plan drawing): the naos, inner and outer narthex, and parekklesion. Tapping a room shows its artworks on their walls, vaults and domes.
2. Complete the 103 typed Artworks from `assets/content/artworks/chora.json`, retaining every ID (including M49_1–M49_4) and resolving the 863 missing TR fields recorded in P02. Each needs:
   - EN+TR title and three things to look for.
   - A story, and inscriptions (Greek, transliteration, translation) where present.
   - Condition notes and sources.
   - Use the corpus and KULTUR_ENVANTERI_SOURCES.json and WEB_SOURCES.json under MILION_CAPTURES. Write your own text; do not copy prose.
3. Guided cycles: the Life of the Virgin, the Infancy of Christ, the Ministry of Christ, and the parekklesion programme, each a walk order with your position animating on the plan.
4. Milestone VI, Chora through time (CA): the kit model assembles the Komnenian core, the 14th-century additions, then the Ottoman minaret and buttresses.
5. Scanner: the camera-eye action on Chora pages. A confident match flies from the camera frame to the matching artwork (the full reveal arrives in P23).
6. The Chora hunt: 8 real curiosities to find in the building (research them), stored as a Hunt for P21.
Acceptance: Chora status "reviewed" in EN+TR; counter shows 103/103 artworks complete; Milestones I–VI all meet the approval definition in §3, or their gaps are listed.
Hook: "103 scenes, one small church" — a clip that zooms from the plan into a single detail.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P12 — Hagia Sophia

P05's two-layer JSON draft compresses everything after 1453 into one layer (mosque, museum, mosque again); split it into dated layers when the page is reviewed.

```text
Phase P12 — Hagia Sophia. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P11 (the pipelines are proven there).

Goal: the city's most famous building told through things people have never looked at closely.
1. Dig page, every date verified and cited:
   - Constantius II's church (360).
   - The Theodosian basilica (415), including its surviving lamb frieze in the courtyard.
   - Justinian's church by Anthemius and Isidore (532–537).
   - The 558 dome collapse and the higher rebuilding of 562.
   - The 1204 sack and Enrico Dandolo's floor marker.
   - 1453, the minarets, the Fossati restoration (1847–49), the museum (1934/35) and the mosque (2020).
2. Milestone VII, the Deesis: GL on the gold ground, an SB through the three faces, and a WR reconstruction of the lost lower half labelled RECONSTRUCTION.
3. Milestone VIII, Zoe's changing emperor: SB through the altered head and inscription, following the recorded sequence of husbands and citing the scholarly debate. Faces of earlier husbands are labelled IMAGINED.
4. Milestone IX, the dome that fell: Choisy CA and CS covering the 537 dome, the 558 collapse (respectful, dust not drama), the 562 dome, the buttresses and minarets, and the ring of windows lighting.
5. Milestone X, Halvdan was here: an RL/Candle macro plate of the runic graffiti in the gallery.
6. Also add: the Omphalion, the "weeping" column, the Loggia of the Empress and the eight great calligraphic roundels (Kazasker Mustafa İzzet Efendi). The roundels are a still plus a story now; their stroke reveal comes with the P24 craft kit.
7. Visiting: current access rules (verify the upper-gallery ticketing and the prayer-time closures), etiquette and a checkedAt date.
Acceptance: VII–X approved; the page is reviewed in EN+TR.
Hook: "tilt your phone" — the Deesis gold clip.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P13 — Hippodrome, Great Palace and the Milion

```text
Phase P13 — Hippodrome, Great Palace and the Milion. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P12.

Goal: the imperial core, and the stone the app is named after.
1. Milestone 0, the Milion, in full:
   - A 3D reconstruction of the domed tetrapylon from cited descriptions, placed on its Divanyolu fragment.
   - Roads radiate out with their historical distances (e.g. the Via Egnatia westward).
   - Replace the P04 lite intro with it, keeping the same 12-second structure, its three reduced-motion stills and its one-sentence TalkBack version (`lib/first_run/`). The register record `milestone-0` stays planned until then.
2. Milestone XII, the Hippodrome through time (TM):
   - The track and the spina (Obelisk of Theodosius, Serpent Column with its heads, the Walled Obelisk), the Quadriga (now in Venice; link to XLVI), the kathisma and the sphendone.
   - Scrub from 330 to 1200, to the Ottoman festivals, to today's square.
3. Milestone XIII, the Obelisk base: RL on the reliefs of Theodosius at the races and the raising of the obelisk.
4. Milestone XIV, the Serpent Column: a TT reconstruction of the three heads. It came from Delphi (479 BC); one upper jaw is in the Archaeological Museums (link to P28).
5. Milestone XV, Great Palace animals: MM and DP on the secular floor mosaics (eagle and snake, the child feeding a donkey, hunters, the griffin).
   - Animals may move; loops stay short and are labelled IMAGINED.
   - This is the collection's most playful piece.
6. Places: the Hippodrome, the Great Palace Mosaic Museum, the Column of Constantine (porphyry drums), the Milion fragment and the Boukoleon.
Acceptance: 0 and XII–XV approved; places reviewed in EN+TR.
Hook: "Every road started here" — the new Milestone 0 clip.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P14 — Underground Constantinople

The immersive backend is decided at the start of this phase. On the A52s, flutter_scene 0.24.3 (Flutter GPU, +3.5 MB) drew the 50k-triangle spike model at 58 fps and thermion 0.5.0 (Filament, +6.8 MB, OpenGL ES only, binary download blocked here) at 60 fps; the Canvas renderer reached 27 fps. Rebuild the spike apps from `studio/spikes/p08/*` and re-run them with a cistern-sized model first.

P07's pipeline already writes pop-up (PU) layers with OpenCV inpainting and a flip-free adaptive mesh to `studio/plates/<id>/build/`; XVII's PU runtime renders them instead of building a second split.

```text
Phase P14 — Underground Constantinople. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P10, P13.

Goal: the city beneath the city.
1. Milestone XVI, the Basilica Cistern walk (WK, using the immersive backend chosen in P08):
   - 336 columns in 12 rows over a water plane with reflections, fog and fish.
   - The two Medusa heads (inverted and sideways) and the "weeping" peacock-eye column.
   - Spolia capitals, called out with leader lines.
   - Move with a thumb or with tilt; lighting as in today's installation.
   - Stills for reduced motion.
2. Milestone XVII, the harbour under the metro (PU, SB): an excavation section. Dig from today's Yenikapı station through Ottoman fill and the Theodosian Harbour with its 37 shipwrecks (tap a ship for its type) down to the Neolithic footprints. Tell the Marmaray discovery story.
3. Places: the Basilica, Theodosius/Şerefiye and Binbirdirek cisterns; the open cisterns of Aetius, Aspar and Mocius (now parks or stadiums); Nakilbent. All of them go into the Atlas Below layer.
4. Ambient placeholders (drips, echo) for P22.
Acceptance: XVI and XVII approved; the cistern walk meets the immersive budget on the device (or is marked unverified).
Hook: the upside-down Medusa emerging from the dark, an 8-second clip.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P15 — The Walls and 1453

```text
Phase P15 — The Walls and 1453. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P10, P13.

Goal: the land walls as one continuous object, and the siege told fairly.
1. Milestone XVIII, the Land Walls strip: a horizontally scrolling wall from the Golden Gate / Yedikule on the Marmara to Blachernae on the Golden Horn.
   - A layered cross-section in Drawing style: moat, outer wall, peribolos, inner wall, towers.
   - The gates as stops: Golden Gate, Belgrade, Silivri, Mevlanakapı, Topkapı/St Romanus, Edirnekapı, Tekfur/Blachernae, and the Kerkoporta legend.
   - Survey the actual gate/entrance points: P02 quarter QIDs are draft context, not gate entrances. Kerkoporta is a mapped marker with a disputed historical location; preserve that distinction (O21).
   - Strip position ↔ Atlas position ↔ GPS: on site, the strip scrolls to where you stand.
2. Milestone XIX, 1453 in 53 days (TM, SB): an animated map sequence covering the camp, Orban's cannon, the chain, the ships hauled overland on 22 April and the 29 May assault.
   - Neutral and sourced, with Byzantine, Venetian and Ottoman accounts attributed.
   - Labelled RECONSTRUCTION.
3. Places: the sea walls, Yedikule, Tekfur Palace (and its Tekfur Saray ceramics), the Anemas prisons, and Rumeli and Anadolu Hisarı as the prelude.
4. A "Walk the walls" route seed in three sections for P21.
Acceptance: XVIII and XIX approved; places reviewed.
Hook: "scroll the whole wall", a clip of one continuous fling.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P16 — Byzantine city beyond the core

```text
Phase P16 — Byzantine city beyond the core. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P09, P14, P15.

Goal: reach at least 30 reviewed Byzantine places across both shores and the outer province.
1. Churches that became mosques, each a single layered page:
   - Küçük Ayasofya, Milestone XX (CA plus SR of the Greek dedication frieze naming Justinian and Theodora).
   - Pammakaristos/Fethiye, Milestone XXI (GL on the chapel mosaics).
   - Pantokrator/Zeyrek, Kalenderhane, Gül, Vefa Kilise, Myrelaion/Bodrum (kit model), Lips/Fenari İsa, Stoudios/İmrahor, and Hagia Irene.
2. Infrastructure and the Genoese city: Milestone XXII, the Valens Aqueduct (CA plus TM: 4th century to Ottoman repairs); the Boukoleon; Galata Tower (1348) and the Genoese walls.
3. Asian side and outer province:
   - Chalcedon/Kadıköy (the Council of 451 and the "city of the blind" story), Chrysopolis/Üsküdar and the Maiden's Tower.
   - The Princes' Islands monasteries and imperial exiles, and Hieron/Yoros castle.
   - Bathonea, Selymbria/Silivri, the Anastasian Wall (Çatalca) and Küçükyalı Arkeopark.
4. Each place gets a full dig page in EN+TR, at least 3 images (today and historical), sources and a visit card.
Acceptance: the counter shows ≥ 30 reviewed Byzantine places; Byzantine Milestones 0 and I–XXII are approved except XI (P22), or their remaining gaps are listed.
Hook: "the gold chapel nobody finds" (XXI).

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P17 — Share studio and deep links

P08's SpacePlayer already renders offscreen (`renderSpaceStill`, `spaceFrames` in `lib/space/capture.dart`); its 8 s hook was made that way.

Every plate manifest carries `revealMoment` (seconds into its 10 s reveal) and the pipeline renders a 6 s preview; exports start from these.

```text
Phase P17 — Share studio and deep links. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P06, P08.

Goal: every Milestone moment becomes something people want to post, and every post leads back into the app.
1. Export formats:
   - (a) 1080×1920 stills from composition templates: the crop, a one-line fact, the Milestone numeral, the mil distance and a small mark.
   - (b) 6–10 s vertical MP4 loops of the current beat: offscreen frames at 30 fps, encoded with Android MediaCodec/MediaMuxer through a small Kotlin MethodChannel (no ffmpeg-kit; it is retired).
   - (c) Animated WebP as the fallback.
   - Non-original states carry their honesty label.
2. Output: the Android Sharesheet with a preview, and save to gallery via MediaStore with no storage permission.
3. Links:
   - Custom scheme milion://m/<milestone>/<detail> and milion://p/<place> now.
   - https App Links once a domain exists (O06).
   - Cold and warm start routing, with a graceful fallback when content is missing.
4. An export gallery in the Mosaic tab listing past exports.
Acceptance:
- Exports work on the device (or emulator, marked).
- A 10-second clip is under 8 MB.
- Tests cover deep-link parsing and routing.
Hook: the launch kit starts here. Store the best five exports in studio/captures/P17/.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P18 — Daily Tessera and On this day

```text
Phase P18 — Daily Tessera and On this day. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P04, P17.

Goal: a reason to open Milion every day that never nags.
The Daily Tessera is a separate game from Today's Detail of the day (P04); it may reuse the `details` records and the `detailOfDay` date rotation.
1. The daily game (Günün Taşı):
   - One extreme close-up per day. Guess the place from 4 choices, then earn a bonus by pinning it on the Atlas.
   - The reveal zooms out to the full artwork and its story.
   - A shareable result card made of drawn tesserae, with text sharing via Unicode squares.
   - Offline and deterministic by date.
   - Pool: ≥ 60 now; the counter targets 365.
2. No streak pressure: show a calendar mosaic of the days you played, and missed days leave no penalty.
3. On this day in Istanbul: ≥ 120 dated entries (e.g. 13 Jan 532 the Nika riots, 27 Dec 537, 29 May 1453, 14 Sep 1509 the "Little Apocalypse" earthquake) with sources, EN+TR. Verify every date.
4. Optional local notification at a user-chosen hour: off by default, and it asks for POST_NOTIFICATIONS on Android 13+ only when enabled.
Acceptance: tests cover schedule determinism and scoring; the result share works; the pool counters are updated.
Hook: the daily result card is the most-shared format.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P19 — Personal mosaic and Milestone book

```text
Phase P19 — Personal mosaic and Milestone book. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P04, P18.

Goal: collecting that turns into a real artwork.
Replace P04's provisional strip and grid (a tessera per opened Milestone) and import its `milion_opened_milestones` key.
1. Earning tesserae:
   - Sources: a Milestone reaching its reveal beat, a finished Daily, a visited place (geofence within 150 m after the user opts in, or a recognition match), and a completed hunt.
   - Each earns tesserae in that piece's colours.
2. The Mosaic assembles into a real artwork, with tesserae snapping in with haptics and the image revealed only as you progress:
   - Season 1 (Byzantine): the Deesis Christ.
   - Season 2 (Mosques): a Rüstem Paşa tile panel.
   - Season 3 (Museums): the Alexander Sarcophagus hunt scene.
3. Milestone book (passport): one page per Milestone with a stamp (date, place, mil distance), your notes (migrate the existing scene notes) and optional photos.
4. Storage: local only, drift/SQLite with schema migrations. Import P02 notes schema v1 (and unstamped v0) from the unchanged `scene_note_<artworkId>` keys, preserving all 103 legacy IDs and text. Export and import a zip (JSON plus images); "Delete everything".
Acceptance: tests cover the progress maths, the SharedPreferences migration and the export/import round trip; the Mosaic renders 1,000+ tesserae at 60 fps.
Hook: a time-lapse of a season's mosaic filling in.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P20 — Ghost lens (then/now)

```text
Phase P20 — Ghost lens (then/now rephotography). Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P10, P17.

Goal: stand where a 19th-century photographer stood and see both cities at once.
1. At least 30 viewpoints, 12 in this phase, each with:
   - A historical photograph or engraving (Abdullah Frères, Sébah & Joaillier, Robertson, Berggren, Allom/Bartlett).
   - The exact standing point and bearing on the Atlas.
   - The year and author, a "what changed" fact and sources.
   Research examples: Galata from Karaköy; Hagia Sophia from the Hippodrome; Yeni Cami from the Galata Bridge; Rumeli Hisarı from the water; Mihrimah Üsküdar from the pier; the Grand Bazaar gates; Edirnekapı walls.
2. Lens:
   - The camera plugin with the image as a semi-transparent overlay, plus alignment guides (horizon line and two anchor points).
   - Capture a then/now diptych, a swipe video or a crossfade.
   - Raw frames are saved only when the user captures.
3. Works without location: choose a viewpoint from the list or the map. With location, it suggests the nearest one.
Acceptance: the lens works on the device (or emulator camera, marked); exports go through the P17 share studio.
Hook: the then/now swipe clip is the residents' favourite, so make it beautiful.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P21 — Routes and hunts

```text
Phase P21 — Routes and hunts. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P10, P16.

Goal: turn the collection into walks.
1. Four routes now (12 at ship):
   - "The Mese: from mile zero to the Golden Gate", the signature walk along the ancient avenue (research its course).
   - "Along the walls" in three sections.
   - "Chora and the Golden Horn churches".
   - "Byzantium in Asia: Kadıköy–Üsküdar".
   Each route has:
   - Stops linked to places and Milestones.
   - Real walking distance and time, precomputed offline from OSM paths, plus elevation.
   - Water, toilets and rest points; a rain alternative; a lower-exertion variant.
   - Warnings where opening hours or prayer times clash.
2. Route mode: a Route strip (horizontal stops plus a mini-map). Each leg opens Google Maps walking directions; arrival (geofence, opt-in) triggers that stop's reveal.
3. Two hunts now (6 at ship): the Chora hunt (P11) and the Spolia hunt, finding Byzantine columns, capitals and inscriptions reused in Ottoman buildings. Confirmation is honour-based or by photo recognition.
Acceptance:
- Routes are reviewed and their times checked against a mapping service.
- Route mode works offline.
- Hunt completion feeds the Mosaic.
Hook: "a whole empire's main street in 90 minutes", the Mese route card.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P22 — Voices: acoustics, soundscapes, narration

```text
Phase P22 — Voices: acoustics, soundscapes, narration. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P12, P17.

Goal: hear the buildings.
1. Milestone XI, Sing in Hagia Sophia (VO):
   - Record 5 s; microphone permission is requested only on tap.
   - Convolve in an isolate (FFT) with an impulse response: use published measurements if obtainable (O14), otherwise a physically based synthetic IR with RT60 ≈ 10 s labelled RECONSTRUCTION.
   - Play the result back and share it as a video over the dome.
   - Prepare Süleymaniye and the Basilica Cistern as further voices for later.
2. Soundscapes: seamless ambient loops (≤ 30 s) per place, e.g. water, gulls, ferry horns, the bazaar. Off when the device is silent.
3. Narration: optional narration of story beats. The baseline is Android TTS (flutter_tts) in TR and EN, tuned; it can be replaced by human recordings (O09). Captions are always on screen.
4. Audio focus, ducking, Bluetooth and interruptions are handled (audio_session).
Acceptance: XI approved; interruption tests pass; captions exist for all narration.
Hook: "my voice in Hagia Sophia", a shareable audio clip.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P23 — Point and reveal (recognition v2)

```text
Phase P23 — Point and reveal (recognition v2). Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P11, P12, P13.

Goal: point the phone at the real wall and the artwork comes alive in your hands, with no false certainty.
1. Model: replace the closed 103-class head with open-set retrieval.
   - A compact embedding network (distilled DINOv2-S or EfficientNet-lite/MobileNetV3 with metric learning), exported to ONNX.
   - Per-place reference-embedding packs, matched by kNN with a calibrated rejection threshold.
2. Data:
   - The local Chora corpus.
   - Wikimedia Commons photos of the Hagia Sophia mosaics, the Great Palace mosaics and the Rüstem Paşa tiles, collected by a script with their URLs recorded.
   - On-site photos when available (O03).
3. Evaluation and gates:
   - Hold out data by capture session.
   - Report top-1/top-3 and the false-accept rate on ≥ 300 negatives (other buildings, street scenes).
   - Gates: top-3 ≥ 90% and FAR ≤ 3%; otherwise the feature is labelled Beta.
4. The reveal:
   - On a confident lock the frame freezes and aligns to the reference (feature-match homography), then dissolves into the Plate at the same framing.
   - Low confidence shows "Did you mean…" with 3 thumbnails.
5. Privacy: frames never leave the device.
Acceptance: evaluation report in studio/recognition/; gates met or Beta label applied; the About screen's model claims are replaced by reproduced numbers.
Hook: film the lock-and-reveal in front of a real mosaic (needs O03/O10).

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P24 — Mosque layer and craft kit

```text
Phase P24 — Mosque layer and craft kit. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md (especially motion rule 6) and PROGRESS.md first. Depends on P06, P09.

Goal: the tools every mosque chapter needs, built once, respectfully.
1. Visiting layer for every mosque:
   - Prayer times computed offline (the adhan package with the Turkey/Diyanet method).
   - Tourist visiting windows (closed around each prayer and at Friday noon; verify the typical window lengths).
   - Dress and etiquette, entrances, shoe bags and photography norms; bilingual, respectful, with checkedAt dates.
2. Craft-kit Milestones:
   - XXIX Muqarnas: a 3D honeycomb vault assembling cell by cell from a 2D projection, procedural via the P09 kit.
   - XXX Girih: construct a star pattern with compass and straightedge steps (the user drags the compass), then tile the plane.
   - XXXI Making an İznik tile: pounce, outline, cobalt, turquoise, bole red, glaze and firing as PU layers, with GL on the glaze.
   - XXXV Calligraphy, stroke by stroke: SR of celî sülüs compositions using vector strokes traced from high-resolution images with reed-pen width modulation, plus transliteration and meaning. Apply it now to the Hagia Sophia roundels.
3. Respect rules: no worshippers animated, no invented sacred imagery. Architecture, light, geometry, writing and craft are the subjects.
Acceptance: XXIX–XXXI and XXXV approved; prayer-time tests against Diyanet's published table for 3 dates.
Hook: the girih construction clip (hypnotic, universal).

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P25 — Süleymaniye

```text
Phase P25 — Süleymaniye (the mosque flagship). Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P24.

Goal: a mosque understood as a whole city block and as an instrument of light and sound.
1. The külliye page, as a dig plus a plan:
   - The mosque, madrasas, medical school and darüşşifa, imaret, caravanserai and hamam.
   - The tombs of Süleyman and Hürrem, and Sinan's own tomb at the corner.
   - The site on the third hill.
2. Milestone XXIII, the külliye assembles (CA, CS): a kit model in which each building lights up with its function and one fact about daily life there.
3. Milestone XXIV, Light at this hour (SK, CS):
   - The interior with the real sun position for Istanbul now; light through the window tiers.
   - Scrub the day and the year; night view with oil lamps.
4. Milestone XXV, the soot room (PU, SB): lamp smoke channelled to a room over the entrance and collected for ink. Verify and cite the details.
5. Also:
   - The acoustics story, including the resonator jars (a Voices entry via P22).
   - The four minarets and ten şerefe (the tenth sultan).
   - Dome calligraphy through the craft kit; the terrace view over the Golden Horn.
Acceptance: XXIII–XXV approved; place reviewed; the visiting layer is live.
Hook: "the sun inside Süleymaniye right now", a live share card.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P26 — Sinan's Istanbul

```text
Phase P26 — Sinan's Istanbul. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P25.

Goal: the architect as the thread through the city.
1. Frame the chapter with Sinan's own words: apprentice (Şehzade), journeyman (Süleymaniye), master (Selimiye in Edirne, a flagged bonus page outside the province).
2. Milestones:
   - XXVIII, Şehzade's symmetry (CA).
   - XXVII, Mihrimah's equinox (SK): both Mihrimah Sultan mosques, Edirnekapı and Üsküdar, with real sun and moon positions for 21 March and any chosen date. Labelled as legend.
   - XXVI, Rüstem Paşa's tile garden (GL, SR): macro glaze light plus "name the flowers" (tulip, carnation, hyacinth, rose, saz leaf, pomegranate).
3. Places:
   - Mosques: Mihrimah Edirnekapı and Üsküdar, Rüstem Paşa, Sokollu Mehmed Paşa (its Kaaba fragments and tiles), Kılıç Ali Paşa, Atik Valide, Şemsi Paşa, Molla Çelebi, Kara Ahmed Paşa, Piyale Paşa, Zal Mahmud Paşa.
   - Other works: a Sinan hamam (Haseki Hürrem), the Moglova (Mağlova) aqueduct and the Büyükçekmece bridge.
4. The "Sinan in a day" route.
Acceptance: XXVI–XXVIII approved; ≥ 15 reviewed mosques total.
Hook: the sun-and-moon equinox clip.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P27 — Imperial to contemporary mosques, the dome's evolution, mahya

```text
Phase P27 — Imperial to contemporary mosques, the evolution of the dome, mahya. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P26.

Goal: complete the mosque wave, reaching ≥ 30 reviewed mosques.
1. Places:
   - Imperial and Ottoman: Sultanahmet (20,000+ İznik tiles, six minarets), Yeni Cami with the Spice Bazaar, Fatih, Eyüp Sultan (a pilgrimage site; extra care), Nuruosmaniye (Ottoman Baroque), Laleli, Nusretiye.
   - 19th century: Ortaköy/Büyük Mecidiye (Balyan), Dolmabahçe/Bezmialem Valide, Pertevniyal Valide, Yeni Valide (Üsküdar).
   - Contemporary: Şakirin (interior by Zeynep Fadıllıoğlu), Sancaklar (Emre Arolat), Büyük Çamlıca.
2. Milestones:
   - XXXII, 20,000 tiles: a continuous zoom from the skyline to the building to a single tulip.
   - XXXIII, Evolution of the dome (CA, TM): the same scale and camera, morphing Hagia Sophia 537 → Şehzade → Süleymaniye → Sultanahmet → Nuruosmaniye → Ortaköy → Sancaklar.
   - XXXIV, Mahya: write your own mahya between two minarets within real mahya constraints. Night render and share; highlighted automatically during Ramadan (dates computed).
3. The "Tiles of Istanbul" route and one mosque curiosity hunt.
Acceptance: XXXII–XXXIV approved; ≥ 30 reviewed mosques.
Hook: the evolution-of-the-dome morph, the collection's best educational clip.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P28 — Museum kit and the Istanbul Archaeology Museums

```text
Phase P28 — Museum kit and the Istanbul Archaeology Museums. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P06, P08.

Goal: objects as characters with journeys.
1. Model: Institution, Gallery and Object. An Object has an inventory number when known, material, date, findspot, dimensions, and display status with checkedAt.
2. Object experiences:
   - Vitrine: a TT turntable from photogrammetry or kit geometry, with a scale reference.
   - Polychromy wipe: WR to the researched original paint.
   - Journey map: from the findspot to the museum.
3. Milestones:
   - XXXVI, the Alexander Sarcophagus in colour (RL, WR): based on published paint traces, labelled RECONSTRUCTION. Tell the story of its 1887 Sidon discovery.
   - XXXVII, the Kadesh treaty (SR): the cuneiform glows line by line with a translation.
4. Other highlights and links:
   - The Serpent Column jaw (link XIV) and the Tetrarchs' foot (link XLVII).
   - The Siloam inscription, the Sidon sarcophagi, the Çinili Köşk tiles, the Ancient Orient Museum and the Gezer calendar.
   - Osman Hamdi Bey as the founder (link to P30).
5. At least 25 objects with pages.
Acceptance: XXXVI and XXXVII approved; the museum reviewed; objects counted.
Hook: "it was painted", the sarcophagus colour wipe.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P29 — Topkapı and the palaces

```text
Phase P29 — Topkapı and the palaces. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P28.

Goal: palaces as sequences of thresholds.
1. Topkapı:
   - The courts in order: the Gate of Salutation, the Divan, the Harem, the privy chambers, the Treasury, the kitchens, and the Baghdad and Revan kiosks.
   - Milestone XXXIX, the Harem maze (CA, CS): a plan that reveals rooms as you walk it.
   - Milestone XXXVIII, the Topkapı dagger (TT, with light and caustics) plus the Spoonmaker's Diamond legend, labelled as legend.
   - The Sacred Relics chamber gets respectful text only, with no playful interaction.
2. Palaces and palace-era sites:
   - Dolmabahçe (the great chandelier, and Atatürk's room with its clocks, respectfully), Beylerbeyi, Yıldız, Küçüksu, Aynalıkavak, Ihlamur.
   - Hagia Irene as a museum.
3. Milestone XLII, Panorama 1453: a 360° LU viewer of the panoramic painting, with the gyroscope.
Acceptance: XXXVIII, XXXIX and XLII approved; the palaces reviewed.
Hook: "a watch hidden in the hilt".

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P30 — Collections of the city

```text
Phase P30 — Collections of the city. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P28.

Goal: the museum wave reaches ≥ 25 reviewed museums or palaces, well beyond the obvious.
1. Milestones:
   - XL, the carpet weaves itself (SR): a knot-by-knot reveal of a "Holbein"/"Lotto" carpet at Turkish and Islamic Arts, linked to the Renaissance paintings that show them.
   - XLI, the Tortoise Trainer (MM, Pera Museum): the tortoises edge towards the leaves, gently. Include the painting's story and its 2004 sale.
   - XLIII, the sultan's caique (TT, MM, Naval Museum).
   - XLIV, Mehter (VO, MM, Military Museum): the band and its echo in Mozart.
   - XLV, the Golden Horn chain (TT, TM; verify where its links are displayed), linked to XIX.
2. Places: Istanbul Modern, Sakıp Sabancı (calligraphy), Rahmi M. Koç (mechanisms), the Museum of Innocence, Arter, the Hisart diorama museum, the Istanbul Toy Museum, Aşiyan, Sait Faik (Burgaz), the Adalar Museum and the Florence Nightingale Museum. Verify each one's opening status.
Acceptance: XL, XLI and XLIII–XLV approved; ≥ 25 reviewed museums or palaces total.
Hook: "Turkey's most famous painting, gently alive".

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P31 — Scattered: Istanbul abroad

```text
Phase P31 — Scattered: Istanbul abroad. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P13, P28.

Goal: the city's pieces around the world, and the world's pieces in the city.
1. A world-map chapter drawn in the Atlas style, with journey lines, dates, how each piece moved (1204, 1797, 1815…), where to see it now, and sources.
   - Outbound: Milestone XLVI, the Horses of San Marco; Milestone XLVII, the Tetrarchs (Venice) and their foot (Istanbul); the Pala d'Oro enamels; the Vienna Dioscurides; Bellini's portrait of Mehmed II.
   - Inbound: the Obelisk from Karnak and the Serpent Column from Delphi.
2. A "Pieces of Istanbul are in N cities" share card, with N computed from the data.
Acceptance: XLVI and XLVII approved; at least 12 journeys with sources.
Hook: "the statue is in Venice; its foot is in Istanbul".

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P32 — Every district has a layer

```text
Phase P32 — Every district has a layer. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P16, P27, P30.

Goal: all 39 districts of Istanbul are on the map with real content, and there are ≥ 110 reviewed places.
1. Research every district and publish at least one reviewed place per district.
   - Leads for the edges: Şile (the lighthouse and castle), Riva, Beykoz (çeşm-i bülbül glass, Yoros), Sarıyer (Rumeli Feneri, the Belgrad Forest bents), Çatalca (the Anastasian Wall, İnceğiz), Silivri, Büyükçekmece, Küçükçekmece, Kağıthane (Sadabad), Adalar, Tuzla, Pendik, Kartal, Maltepe and Eyüpsultan.
   - Never fabricate heritage. Where a district's layer is modern (industry, a cemetery, a waterside, a district museum), say so honestly.
2. A Bosphorus chapter (yalıs, Kuleli, Küçüksu, the fortresses) with a ferry-based route.
3. Coverage audit: the content validator fails if any district has zero reviewed places, and the Atlas shows a district heat layer.
   - P02 has drafts in 22/39 districts; retain one identity for multi-district walls/waterways and add segment/shore access geometry. A representative coordinate and chapter-anchor district do not describe the whole feature (O21).
Acceptance: 39/39 districts and ≥ 110 reviewed places in the counters.
Hook: "every district has a layer", a district-by-district flip clip.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P33 — Discovery at scale

```text
Phase P33 — Discovery at scale. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P32.

Goal: a large catalogue stays easy and surprising to explore.
1. Search:
   - Scope: places, artworks, objects, people, terms and Milestones.
   - Turkish-aware normalisation (ı/İ/i, ş/s, ğ/g, diacritics), aliases (Ayasofya/Hagia Sophia/Megale Ekklesia, Kariye/Chora, Yerebatan/Basilica Cistern) and typo tolerance.
   - An offline index built at content-build time.
2. Filters: wave, era, category, district, open now, has Milestone, rain-friendly, accessible, near me (opt-in).
3. People pages: Constantine, Justinian, Theodora, Metochites, Mehmed II, Sinan, Mihrimah, Osman Hamdi Bey and others, linked to their works.
4. "Surprise me": a weighted pick among the unseen items of the current chapter or nearby.
5. On-device recommendations with visible reasons ("because you collected XX") and a reset.
Acceptance: search relevance tests (≥ 40 queries with expected top-3); results under 50 ms on the device.
Hook: "Surprise me" as a Today action.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P34 — Turkish and English, complete

```text
Phase P34 — Turkish and English, complete. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P33.

Goal: both languages feel native, everywhere.
1. UI:
   - 100% ARB coverage, enforced by a script that fails on missing or unused keys.
   - ICU plurals, correct Turkish upper/lower casing in caps styles, and TR/EN number and date formats.
   - An in-app language switch.
2. Content: every reviewed place, Milestone, story, route, Daily entry and On-this-day entry exists in TR and EN. Run a consistency pass on names (current vs historical) and terminology (a glossary: naos, narthex, şerefe, mihrap, mahya…).
3. Pseudo-localisation and a 30%-longer-text test, with screenshots for both languages.
4. Reviews: the owner reviews the Turkish (O08); a native English reader reviews the English (O08).
Acceptance: the coverage script passes; review notes are resolved.
Hook: none; this phase is about quality.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P35 — Accessibility and reduced-motion equivalence

```text
Phase P35 — Accessibility and reduced-motion equivalence. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P33.

Goal: every experience in Milion is available to everyone.
1. TalkBack: every flow is usable (Today, dial list, dig, PlatePlayer, SpacePlayer, Atlas list, Daily, Mosaic, share, routes).
   - The PlatePlayer describes its details in order.
   - The SpacePlayer offers a step list.
   - The dial has a list alternative.
2. Visual and motor: 200% font scale, 48-dp targets, WCAG AA contrast and a sensible focus order; basic switch-access check.
3. Motion: the system "Remove animations" setting plus an in-app toggle. Every Milestone has an equivalent still sequence with the same information. Gyroscope motion is opt-in; no flashing above 3 Hz.
4. Audio: captions and transcripts for all audio.
5. Layouts: tablet, landscape and foldable layouts for the main screens.
Acceptance: a manual TalkBack script passes on the device (O01); accessibility-guideline tests (textContrastGuideline, tap targets) pass in widget tests.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P36 — Performance, size and asset delivery

```text
Phase P36 — Performance, size and asset delivery. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P33.

Goal: fast on a mid-range phone, and small to install.
1. Budgets on the reference device:
   - Cold start ≤ 2.0 s to Today (release build).
   - 2.5D ≥ 55 fps at p90 with ≤ 1% janky frames.
   - 3D ≥ 50 fps (drawing) and ≥ 30 fps (immersive).
   - PSS ≤ 400 MB, no memory growth over 20 open/close cycles, no thermal throttling in 10 minutes.
2. Size:
   - The AAB base download is ≤ 60 MB.
   - Milestone packs go through Play Asset Delivery (install-time starter, fast-follow for the current chapter, on-demand for the rest) via a small Kotlin AssetPackManager bridge.
   - Progress, cancel, retry, a storage check and pack deletion; tested with `bundletool --local-testing`.
3. Textures: KTX2/ASTC versus WebP decided by measurement, with mipmaps and image-cache limits.
4. Startup: deferred initialisation (ONNX, content index, fonts) and baseline profiles if supported.
Acceptance: a measurement table in PROGRESS with device, build and method; all budgets met, or regressions listed with fixes.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P37 — Reliability, permissions and privacy

```text
Phase P37 — Reliability, permissions and privacy. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P36.

Goal: nothing breaks, nothing surprises, nothing leaks.
1. Permissions: camera, microphone, location and notifications are requested in context with an explanation first. Handle denial, "don't ask again", revocation, and process death while in Settings.
2. Lifecycle: camera and audio pause and resume correctly, and process death restores the current Milestone, place or route.
3. Crash and ANR reporting: use the provider chosen in O12, opt-in, with no PII; upload release symbols and the R8 mapping.
4. Privacy:
   - No analytics by default. Any opt-in analytics has a documented, minimal event list.
   - Draft the Play Data Safety answers, and write privacy-policy text in EN and TR.
   - In-app export and "delete all my data".
5. Security: validate deep-link parameters and imported zips (zip-slip, size limits). No secrets in the repo; networking only for packs and mailto.
Acceptance: an adb-driven permission and lifecycle test script passes; zero crashes in a 1-hour monkey run (`adb shell monkey`) on the device.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P38 — Test automation, CI and device matrix

```text
Phase P38 — Test automation, CI and device matrix. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P37.

Goal: regressions are caught before a human sees them.
1. Test pyramid:
   - Unit: content, distance, astronomy, prayer times, search, progress.
   - Widget and golden: design components and key screens in EN/TR and light/dark.
   - integration_test flows: first run, playing a Milestone, the dig, the Atlas offline, share export, the Daily, Mosaic persistence, pack download.
2. CI: GitHub Actions (needs O06) running analyze, tests, `dart run tool/content/validate.dart`, `python3 tool/content/audit_evidence.py`, the ARB check and the APK/AAB build, with cached Flutter and Gradle and artifacts retained. Include the invalid content fixture as an expected non-zero check.
3. Device matrix:
   - The Samsung A52s (Android 14).
   - An API 26 low-RAM emulator and an API 35 large-screen emulator.
   - A Pixel-class device if available, or Firebase Test Lab (optional, O12).
4. A coverage report and a flaky-test policy.
Acceptance: CI is green on main; a deliberately broken commit fails CI.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P39 — Field trial in Istanbul and polish

```text
Phase P39 — Field trial in Istanbul and polish. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P38.

Goal: the app survives real streets, real light and real people.
1. Build: a signed internal-test build on the Play internal track if O04 is ready; otherwise a sideloaded APK.
2. Protocol for the owner plus 5–10 friends (O10):
   - Three on-site sessions: (a) Hagia Sophia, the Hippodrome and the Basilica Cistern; (b) Chora plus the walls; (c) Süleymaniye, Rüstem Paşa and the Spice Bazaar.
   - Two remote users at home.
   - Write a short observation form that lives in this phase's section of PROGRESS.md.
3. Measure:
   - Time to first reveal, recognition success in real light and route-time accuracy.
   - Battery drain per hour, data use and crashes.
   - Confusion points, and answers to "would you share this?" and "would you come back tomorrow?".
4. Triage the findings into P0, P1 and P2. Fix all P0 and P1 issues, and correct content found wrong on site (hours, entrances, rules).
Acceptance: all P0 and P1 findings closed; results recorded as counters; content corrections have checkedAt dates.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

### P40 — Store launch kit and release

```text
Phase P40 — Store launch kit and release. Workspace: /Users/memre/Desktop/milion. Android-only Flutter app "Milion".
Read PHASES.md and PROGRESS.md first. Depends on P39.

Goal: ship, and make the launch itself attractive.
1. Release engineering:
   - The upload key and Play App Signing (O05); a versioning scheme; R8 mapping upload.
   - The AAB with asset packs, a clean pre-launch report, and the current Play target-SDK requirement met.
2. Store listing in EN and TR:
   - Title "Milion — Istanbul from mile zero", with specific, filler-free descriptions.
   - 8 real screenshots: Deesis gold, the dig, the Atlas era slider, the cistern walk, the Daily, the Mosaic, the ghost lens, the evolution of the dome.
   - A feature graphic and a 30-second promo cut from Milestone exports.
3. Launch kit:
   - 20 vertical clips (the best Milestone reveals) with EN and TR captions.
   - A 30-day posting calendar and a weekly "Milestone of the week" format.
   - A short press note and the story of the Milion stone as the brand narrative.
4. Rights pass (O11): images, fonts, 3D references, audio, the Panorama 1453 painting and trademarks. Replace or license anything flagged.
5. Decide whether unreviewed draft points (P04 plan change) stay visible on the dial and City list in the public release, or only reviewed places.
6. Ship decision: every PROGRESS.md dimension is at 100% and there are no open release-blocking issues. Then run a staged production rollout (10% → 50% → 100%) with crash monitoring.
Acceptance: the app is live on Google Play in TR and EN.

Close the phase:
1. PROGRESS.md — rescore every dimension this phase touched (old → new, with evidence: paths, commands, capture files), update Counters and the Phase ledger row, add one Changelog line, recompute the overall %.
2. PHASES.md — record decisions under Decisions; update Open issues (add anything that needs the owner or the outside world, close what got resolved) and adjust later phases if scope changed.
3. No other .md files. Commit "Pxx: <summary>".
```

---

## 8. Open issues (need the owner or the outside world)

Every phase re-reads this table, adds new needs and closes what it resolved.

| ID | What is needed from you (or outside) | Why / what it blocks | Needed by | Status |
| --- | --- | --- | --- | --- |
| O01 | Connect the Samsung Galaxy A52s over USB with USB debugging on, and keep it unlocked while a phase runs device checks. | Every performance, gyroscope, camera and TalkBack claim stays *unverified* without a physical device. | P05 acceptance / P06 | Open again, checked 2026-10-08: no Android device is connected and no Android emulator/AVD is installed on this machine (`studio/captures/AUDIT-2026-10-08/devices.txt`). The SM-A528B release run recorded on 2026-09-26 and P04's Android 14/16 emulator checks are historical evidence, not validation of the current build. Physical typography, haptics, TalkBack, camera/ONNX, cold start, dig scrolling and the Go intent remain unverified; P06 is now implemented locally, with fake-stream and native-renderer tests plus measured decoded texture/vertex counts; physical gyro feel, plate TalkBack, total GPU memory and 60 fps still need this device (`studio/captures/P06/`). Rechecked 2026-10-12: still no device or emulator. P07 adds the rotation-vector look-up (`milion/rotation` EventChannel), a portrait lock while a sensor steers, and gyro decay; their axes, sign and feel are unverified on hardware. Connected on 2026-10-12 evening: the P07 release APK was installed (the 26 Sep build had to be uninstalled first, a debug-key change) and cold-started in 1.2 s to the first run without a crash; P08's three 3D backends were measured on it (`studio/captures/P08/device-bench.json`). Then it disconnected. **The phone now holds the P08 benchmark build under `app.milion` and two spike apps (`app.milion.spike.*`): reinstall the release APK and uninstall the spikes at the next connection.** The separate-UI-thread benchmark (`studio/cache/spikes/milion-space-canvas-bench-profile.apk`) is waiting to run. |
| O02 | Decide whether the 5.3 GB Chora capture corpus (`~/Desktop/chora-ar/captures`) stays outside the repo (via `MILION_CAPTURES`) or is copied in with LFS. | Reproducible plate and recognition builds. | P01 | Resolved 2026-09-27: stays outside the repo; `MILION_CAPTURES` replaces the hard-coded paths (default: `../chora-ar/captures` next to the repo) and the three preparation scripts fail with a clear message when it is missing. |
| O03 | On-site photos: current-day photos of each ghost-lens viewpoint, and real-light photos of key mosaics and tiles for recognition. Also (2026-10-12): a present-day photo of Chora's exterior for the dig header, and a photo taken from directly under the axis of each narthex dome. | The P20 lens and P23 recognition quality; the P05 header has no present-day image; IV's look-up uses an off-axis photograph and a rim elevation derived from Underwood's dimensions (75°), not a measurement. | P11 / P20 | Open |
| O04 | A Google Play Console developer account and ownership of the listing. | Internal testing (P39) and release (P40). | P39 | Open |
| O05 | Create the upload keystore, store it safely outside the repo, and fill in `android/key.properties`. | Signed release builds. | P39 | Open (P01: release builds read `android/key.properties` when present and otherwise print a loud Gradle warning and fall back to the debug key; no change until the keystore exists). |
| O06 | A private GitHub repository (for CI), and optionally a domain (e.g. milion.app) for App Links. | P38 CI and P17 https deep links (a custom scheme works meanwhile). | P17 / P38 | Partly resolved 2026-09-27: `github.com/museumappofyou/milion` exists and `origin` pushes over SSH. CI (P38) and the optional domain remain open. |
| O07 | Taste check: compare [A, lamp first](studio/captures/P03/direction-A-390.png) and [B, marble/porphyry](studio/captures/P03/direction-B-390.png), or long-press the About wordmark in debug for `/design`. | Non-blocking; B is implemented as the default. | P03 / P04 | Open — P04 built the real Today on B (marble with porphyry, artwork panel in lamp); see `studio/captures/P04/today-390-en*.png`. Owner preference can still tune later phases. |
| O08 | Language review: you review the Turkish copy; a native English reader reviews the English. | P34 acceptance. | P34 | Open — P02 seeds have EN/TR names and hooks, all draft; 863 legacy Chora fields still need Turkish (P11). P03 completes 229 EN/TR UI ARB keys, including Registry, with a saved language override. P04 brings it to 313 keys plus 17 bilingual detail sentences and 48 register titles, all authored but unreviewed. P05 adds 36 UI keys and 8 dig layers (6 Chora, 2 Hagia Sophia) plus the visit card, all EN+TR; the Chora layer copy, including the 2026-10-08 corrections, is the next thing a native reader should review. P06 adds 31 UI keys (380 total) and reuses all 17 bilingual detail captions in its stories. Plate controls/captions and source/provenance wording join the review queue; owner/native-reader review is still pending. P07 adds 4 UI keys (384 total), 21 bilingual details, five TalkBack plate descriptions and the corrected Chora/Hagia Sophia layers (2026-10-12); these join the queue. P08 adds 27 UI keys (411 total) and the study's EN/TR title, description, 8 step labels and captions, two epoch labels and the reveal line; these join the queue. |
| O09 | Narration: accept Android TTS, or record human narration (you or a voice artist). | P22 quality level. | P22 | Open |
| O10 | Field trial: 5–10 people and 3 half-days in Istanbul. | P23 recognition footage and P39. | P39 | Open |
| O11 | Rights and licensing for images, fonts, 3D references, audio, Panorama 1453 and trademarks. Deferred by your decision. | Public release only. | P40 | Partly resolved P03: three selected fonts have official OFLs bundled and registered, with source/blob/hash evidence in `studio/design/fonts/sources.json`. Image/model/audio and other rights remain deferred. P04 uses OpenStreetMap data (ODbL; attribution in About, inputs and hashes in `studio/first_run/`). P07's III–V masters are Kültür Envanteri photographs (© Caner Cangül, watermarked); each manifest and `studio/plates/<id>/build/report.json` records the source URL and SHA-256. P08's study geometry is original; its claims cite Choisy (1883, 1899; public domain scans), Procopius (Loeb 1940), Britannica and two pinned Wikipedia revisions as text sources only. |
| O12 | Crash-reporting provider (Firebase Crashlytics needs a Firebase project; Sentry needs an account). Optionally Firebase Test Lab. | P37 and P38. | P37 | Open |
| O13 | Hosting for content packs, only if Play Asset Delivery proves insufficient. | P36 fallback. | P36 | Open (probably not needed) |
| O14 | Impulse responses: permission to use published Hagia Sophia measurements, or an on-site recording. | XI authenticity (a synthetic IR is the fallback). | P22 | Open |
| O15 | On-site verification of mosque visiting rules and museum hours shortly before release. | Freshness of the visit cards. | P39 | Open — drafts keep unknown status, null status checkedAt and null entrance until reviewed. Chora's visit card was rechecked remotely on 2026-10-08: the [Müze İstanbul visiting page](https://muze.gen.tr/muze-detay/kariye) says daily except Friday, 09:00–18:00, box office 17:55, €20 for foreign visitors and prayer closures. It describes curtained naos mosaics; their visibility outside prayers is not assumed. Accessibility, the entrance/walking route and current visiting practice still need field verification. Other places remain open. |
| O16 | Old installs of "chora_scene_finder" and "İzvoya" on your phone are separate apps with separate notes and cannot be migrated automatically. Export anything you need, then uninstall them. | Avoids confusion during device testing. | P01 | Open |
| O17 | A support or feedback email address for "Report a change" and the store listing. | P05 visit card and P40 listing. | P05 | Open — P05 ships the row and a tested `mailto` builder (`lib/city/external_links.dart`), but it stays hidden until an address is set; add the owner's address to reveal it (and fix the copy if the address changes the wording). |
| O18 | Business model: free, paid, tip jar or paid chapters (you said you will decide later). | P40 listing and any billing work. | P40 | Open |
| O19 | Review upstream `flutter_onnxruntime` before removing the local built-in-Kotlin patch. | The app uses `third_party/flutter_onnxruntime` until the P01 removal criterion is met and a replacement build passes. | P01 check / P38 | Open — rechecked 2026-10-08: [1.9.0 was released on 2026-10-06](https://pub.dev/packages/flutter_onnxruntime/changelog), but its [Android Gradle file](https://raw.githubusercontent.com/masicai/flutter_onnxruntime/v1.9.0/android/build.gradle) retains a conditional `apply plugin: "kotlin-android"` branch. The patched 1.8.5 override stays; no ONNX upgrade or device runtime validation is claimed. |
| O20 | Install git-lfs on this machine and migrate the large binaries (`*.jpg *.png *.bin *.onnx *.mp4`) when convenient, or keep the repository private and exclude it from CI caches. | The repo carries roughly 250 MB of binaries inside normal git objects; clone and CI costs grow every phase. P01 captured a plain baseline because git-lfs was not installed. | P38 | Open |
| O21 | Survey gate entrances and clarify conflicting/site-spanning geography: Kerkoporta marker versus disputed gate, quarter points at Silivri/Mevlana/Topkapı/Edirnekapı, Hisart’s Şişli description versus Kağıthane map point, and access points for walls/waterways. | Draft representative points are unsuitable as walking destinations; `tool/content/verification.json` records each exception. | P15 / P30 / P32 / P39 | Open — needs field observations or authoritative institutional confirmation. |
| O22 | Name the source of `assets/anastasis/conch_reference.jpg`. It is the Anastasis explorer master and, since P04, also Today's image for the nine Milestone I details. `studio/anastasis_25d/source_audit.csv` derives it from a 2026-09-23 web-viewer screenshot (`Screenshot 2026-09-23 at 17.18.48.png`) whose page URL was never recorded. | Standing rule 8 (record every image source URL) and O11 rights clearance before public release; Today's credits cannot name it yet. | P40 (before any public build) | Open — needs the owner to identify the viewer (for example a museum or Kültür Envanteri tour) or replace the master. |

## 9. Decisions

- **2026-09-26: the name is Milion.** It means the Byzantine zero-mile stone, and reads as a pun on "million" (details) in both English and Turkish ("Milyon Taşı"). It gives the app its organising idea: distance from mile zero and depth in time. It replaces İzvoya.
- **2026-09-26: the mark is an M holding the zero.** The inscriptional M of Milion holds the gilded zero of the Milion stone in its vertex, so the mark reads as the name and as mile zero at once. It replaces the P00 draft (a dome on pendentives from below, which read as a camera aperture). Porphyry, marble and tessera gold.
- **2026-09-26: identifiers.** Package `milion`, application ID `app.milion`, workspace `/Users/memre/Desktop/milion`. The new ID installs as a separate app (O16).
- **2026-09-26: two authoritative product tracking files.** The 14 İzvoya-era Markdown files (the old PHASES and PROGRESS plus 12 READMEs) are archived in `archive/izvoya-era-docs-2026-09-26.tar.gz`. PHASES and PROGRESS own product status; auxiliary routing notes do not override their ledger.
- **2026-09-26: figure puppetry is demoted** to an optional IMAGINED "Gesture study". The 4K AI repaint becomes a local wipe only. Rationale in §3.
- **2026-09-26: Android only; no iOS phases.** Copyright work is deferred until a public release.
- **2026-09-26: built-in Kotlin.** `android.builtInKotlin=true`: AGP 9 compiles Kotlin and no module applies KGP, so the build is ready for the Flutter version that makes KGP fatal. `flutter_onnxruntime` 1.8.5, still the latest release, keeps a literal `apply plugin: "kotlin-android"` that triggers Flutter's warning. It is therefore overridden with a patched local copy (`third_party/flutter_onnxruntime`, MIT) whose `android/build.gradle` has the KGP classpath and apply removed. The Dart and Kotlin sources are unchanged. Revert when upstream is fixed (O19).
- **2026-09-27: prune, do not archive, the superseded runtime.** Only the current explorer path survives for F02/F05: `SceneExplorerScreen` (Original/Relief/Restored, the 48-pose rig, six detail windows each), reached from the frontier cards, the collection and scan. The v3 conch artifact tab, the "Classic v5" viewers, v1 figure data, the earlier restoration studies and `assets/anastasis/relief` + `relief_v3` (~26 MB) are deleted; every source photograph is kept. Deletions happened only after grepping for references, and only after the `P01 baseline` commit. Rationale: P06's Plate engine supersedes these paths, and dead alternatives hide regressions.
- **2026-09-27: the capture corpus is external and path-independent.** Tools read it from `MILION_CAPTURES`, defaulting to `../chora-ar/captures` next to the repository. `tool/build_anastasis_relief.py`, `tool/prepare_last_judgment_assets.py` and `tool/prepare_anastasis_assets.dart` fail with a clear message when the corpus or a scene folder is missing. The 5.3 GB corpus is never copied into git.
- **2026-09-27: studio layout.** Authoring trees (`anastasis_25d/`, `last_judgment_25d/`, `figure_animation/`, `restoration_studies/`, `ui_refresh/`) live under `studio/`; visual capture tests live under `tool/captures/`; phase evidence goes to `studio/captures/<phase>/`.
- **2026-09-27: minSdk 26.** Android 8.0 is the practical baseline for CameraX/camera2, adaptive icons, notification channels and scoped storage, needs no legacy-storage path, and drops only API 24–25. The reference device runs Android 14.
- **2026-09-27: R8 and resource shrinking on for release.** `android/app/proguard-rules.pro` keeps `com.masicai.flutteronnxruntime.**` and `ai.onnxruntime.**` because the ONNX bridge crosses JNI; CameraX ships its own consumer rules. Proven by an arm64 release build on the Pixel Fold API 36 emulator: CameraX preview runs and ONNX infers (M03 · 47% on the virtual scene, capture in `studio/captures/P01/`).
- **2026-09-27: release signing rule.** Read `android/key.properties` when present; otherwise print a loud Gradle warning at configuration time and sign with the debug key so local release testing still works (O05 unchanged).
- **2026-09-27: local installs are per-ABI APKs; the AAB stays the release artifact.** `tool/build_android.sh` builds both.
- **2026-09-27: git without LFS for now.** `git-lfs` is not installed on this machine, so the baseline holds the binaries as ordinary objects (O20); the repository stays private.

- **2026-09-27, P02: one versioned content registry.** Schema 1 JSON under `assets/content/`, pure-Dart models/repository/validator in `lib/content/`, with injected loading for Flutter or CLI. IDs and references are globally validated; all 39 districts are enumerated, EN is required and missing TR counted. Drafts stay out of default public place queries. The existing Chora artwork preview continues; the temporary Scene adapter is UI compatibility, not a second catalogue. The classifier reads only the output-index → artwork-ID map when Scan opens.
- **2026-09-27, P02: preserve identity and notes.** All 103 legacy scene IDs and English text are migrated exactly, including M49_1–M49_4. F02 and F05 reference prototype Milestones I and II; neither is approved. Notes keep their `scene_note_<id>` keys and bytes, with an idempotent schema-v1 stamp; P19 imports v0/v1 into SQLite. The test suite checks every legacy note and protects future-version stores.
- **2026-09-27, P02: mile zero is the surviving Milion fragment.** Fixed origin **41.008043° N, 28.978066° E**, from [Wikidata Q1187329](https://www.wikidata.org/wiki/Q1187329); the exact source revision is pinned in the registry. A Roman mile uses **1,480 m**, the approximate ancient value in [Calderini, “Miglio”, Enciclopedia Italiana (1934)](https://www.treccani.it/enciclopedia/miglio_(Enciclopedia-Italiana)/). Distances are spherical great circles (mean radius 6,371.0088 km), not historical road or walking distances; bearings are initial true bearings. Roman miles round to the nearest integer, sub-half-mile distances display `< I`, and only the origin displays zero. TR/EN km formatting is shared. Two destinations are tested against GeographicLib 2.1 and independent 3D vector calculations.
- **2026-09-27, P02: verified draft geography is distinct from a visit review.** 155 places have canonical QIDs, coordinates, category, district (or explicit outside-province flag), EN/TR names/hooks and a review phase. Wikidata exports and hashes, OSM exceptions and phase-name coverage live in `tool/content/`. Redirected Sokollu Q18361069 was resolved to Q1572472; the Fatih mosque selection was corrected to Istanbul Q756189. The province bounding rectangle comes from [OSM relation 223474](https://www.openstreetmap.org/relation/223474); it is not a polygon test. Nine outside-province records have no fabricated Istanbul district. Entrances/current functions/status remain explicitly unverified, with null dates, until checked; promotion requires a verified entrance and dated status.
- **2026-09-27, P02: aliases, interiors and long features.** One layered identity covers each historic/current name pair; building rooms and ensemble components stay attached to their parent (`phase_place_coverage.json`). Land/sea walls share a record; Golden Gate belongs to Yedikule. Waterways, bridges, walls and Via Egnatia use tagged representative points; a single chapter-anchor district does not imply that their whole extent lies there. Gate quarters and the contested Kerkoporta marker are not surveyed gate entrances (O21). P15/P32 will add actual segment/access geometry.
- **2026-09-27, P02: keep review debt visible.** 863 legacy artwork fields lack TR; new seed place names/hooks are bilingual but still need O08 review. There are 201 sources and two credited Media references with original/derivative hashes. No place or Milestone gained reviewed/approved status. Three Daily and three On-this-day drafts are authoring inputs in `tool/content/editorial_seeds.json`; P18 owns publication and the runtime feature.
- **2026-09-27, P02: visible debug inspection.** Debug builds expose Registry by long-pressing the About version. Distance-sorted rows and expandable category/district counts work in EN/TR, with vertical widget captures in `studio/captures/P02/`. No new cards, chip navigation, decorative textures or gradients; existing theme fonts remain a P03 replacement. P03 moves Registry UI text into ARB. No device was attached for P02: physical performance, TalkBack and on-site accuracy remain unverified. Release APKs and AAB build with the existing O05 signing fallback.

- **2026-09-28, P03: direction B is the default.** Marble with porphyry gives the distance instrument a distinct stone datum and leaves the original artwork as the main visual evidence; lamp remains available in About and is mandatory in artwork/study views. Both working compositions are captured at `studio/captures/P03/direction-{A,B}-390.png`; their links open the real explorers. The dial is a drawn composition trial only; the reviewed-place dial, first-run reveal and new navigation remain P04. Owner taste check O07 is non-blocking.
- **2026-09-28, P03: choose from rendered type.** `type-display.png` and `type-text.png` render the complete supplied Turkish/Greek/Roman specimen for all 11 requested families. Cinzel supplies inscriptional capitals; Noto Serif Display supplies its missing Greek glyphs. Noto Sans supplies body text and tabular figures. Cinzel/Forum/Marcellus lack Greek; GFS Neohellenic/Literata/Source Serif 4/Alegreya/IBM Plex Sans lack Ϲ; the Noto candidates cover the whole string (`font-coverage.json`). Candidate TTFs/OFLs come from the [official Google Fonts repository](https://github.com/google/fonts/tree/main/ofl), with file URLs, git blobs and SHA-256s in `studio/design/fonts/sources.json`. `tool/design/audit_fonts.py` verifies glyphs, all recorded files and the three shipped font/licence copies. OFLs are registered in Flutter’s licence page. Cormorant Garamond and DM Sans are removed. Physical-device rendering and native reading review remain unverified.
- **2026-09-28, P03: one flat construction system.** `lib/design/` defines marble/lamp, four-dp spacing, two-dp maximum corner radius, one-physical-pixel irregular tessera edges, no elevation and all wave pigments. Gold marks gold material/collected states; body text uses measured foreground pairs. Thirteen 24-dp PlanIcons are drawn as plans in Canvas. Thirty specimens cover every requested component/state, with 60 separate marble/lamp goldens. Hidden `/design` shows all tokens/components at 100/200% text; debug About wordmark long-press opens it, while version long-press still opens Registry. Existing home, catalogue, scanner, notes and art views use the tokens. The large serif hero, pill navigation, rounded cards, gradients, decorative shadows and numbered floating detail bubbles are gone; cultural controls use PlanIcons. Full screen layouts remain P04/P05/P06.
- **2026-09-28, P03: labels and motion cannot wait for the engine rewrite.** To satisfy §2’s ban on looping puppetry, both explorers now start on ORIGINAL. Original resets any pose in one tap. The optional, collapsed IMAGINED Gesture study plays a single 6-second gesture at 0.25 strength, capped at 0.35; reduced motion keeps manual posing, and lifecycle changes stop playback. The prototype reconstruction is explicitly labelled and retains its source. P06 still owns the 1.2-second story beat, damaged-zone wipe, three-icon controls and full still-sequence/TalkBack equivalence. Shared settle/dig/sweep tokens use 160/360/520 ms, named curves and immediate reduced-motion variants; detents call light haptics, collection medium. No sacred figure loop remains in shipped code.
- **2026-09-28, P03: bilingual UI and measurable checks.** `flutter_localizations`, 229 EN/TR ARB keys and persisted language/scheme settings replace hard-coded UI copy; legacy content remains data and discloses English fallback until P11/P34. 99 app tests, including 60 goldens, pass; `contrast.json` reports a minimum 4.65:1 for body/action/collected text pairs. Phone captures at 360/390/430 dp include 100/200% EN/TR, settings, notes and artwork controls; regression frames also cover tablet/landscape widths. Analyzer, content CLI, font audit and APK/AAB release builds pass. Logs and frames live in `studio/captures/P03/`. No physical device is attached: real glyph rendering, haptics and TalkBack remain unverified, and O05 debug signing fallback remains. No place or Milestone changed review status; this phase adds no published content pool.

- **2026-10-01, P04: the shell is four instruments, not a feed.** Today/Bugün, City/Şehir, Milestones/Taşlar and Mosaic/Mozaik use drawn PlanIcons (dial, dome, milestone stele, tessera). Scan left the tab bar: it is a camera-eye action only where the bundled classifier covers artworks (`assets/model/classes.json` → Chora's place page, its catalogue and artwork sheets), so the camera and ONNX load only on that tap and no permission is asked before it. About moved to Today's header (with "Replay mile zero"); the Chora catalogue opens from the Chora place page. Tabs live in an `IndexedStack` (scroll state kept while switching) under `restorationScopeId` + `RestorationMixin`, so tab, scroll offsets, dial selection and list mode survive process death (`restartAndRestore` test). Back on City/Milestones/Mosaic returns to Today; back on Today leaves the app. Android 14 predictive back is opted in with `android:enableOnBackInvokedCallback="true"`, `PredictiveBackPageTransitionsBuilder` and `PopScope`. The app is edge-to-edge with transparent bars. A solid lamp strip sits under the status bar on Today and nav-bar icons follow the marble ground.
- **2026-10-01, P04: no visible loading.** `main()` defers the first frame until settings, the registry and today's detail image are ready, capped at 1.5 s, so the splash hands over straight to a complete Today. On first launch it hands over to the black first frame of Milestone 0 lite. The classifier class list loads alongside the registry and only gates camera-eye actions. Profile cold start to an interactive Today is 1,067 ms (trace median) and 1,276 ms (`am start -W` COLD median) on an Android 14 emulator at the A52s's dp size; the A52s figure remains unverified (O01).
- **2026-10-01, P04: plan change — draft geography may appear on the instruments.** The first reviewed place arrives with P11, so a reviewed-only City list and dial would have stayed empty for seven phases. The dial and the City list therefore plot *plottable* places: every reviewed place, plus drafts whose Wikidata identity and P625 point are pinned, lie inside the province and name a single point. For drafts they show only checked fields (name, district, category, mil distance, bearing, QID). Unreviewed hooks, current function and status stay hidden behind an outlined "Not reviewed yet" slot until the wave phase reviews them. Points that are not visitable points are excluded: 28 records gain an `area` tag (district anchors, quarters, streets, gate quarters, island groups, forest, ancient cities; via `tool/content/seed_overrides.json`, reproduced by `build_seed.py`). The land walls gain `representative-point`, matching P02's own rule for walls. Result: 111 plotted points, 0 reviewed. Dig pages (P05) still use the reviewed filter. P40 decides whether unreviewed points stay visible publicly.
- **2026-10-01, P04: the register is content.** All 48 §3 pieces are schema-1 Milestone records. `tool/content/build_register.py` writes 0 and III–XLVII as `planned`; I and II keep their prototype records. An additive, optional `flagship` field marks the nine ★ pieces (absent means false, so schema 1 stays valid). Planned honesty sets follow a stated technique rule: camera/light/playback DEPTH, added geometry/strokes/acoustics RECONSTRUCTION, animal motion and the Mihrimah legend IMAGINED. Pieces without one place (craft kit, the dome's evolution, mahya) cite pinned Wikidata concept items. Rows show numeral, title, place and mil, technique glyphs (15 new PlanIcons, one per §3 code without a symbol) and the honesty range ORIGINAL → furthest state. Planned pieces are outlined tessera slots that open a "planned" sheet. Milestone 0 stays planned (P13); its lite version is the first run. Turkish calls the pieces *taş* ("Taş I"), matching the tab name.
- **2026-10-01, P04: Detail of the day is a new `details` record kind.** Each record holds a crop window and leader-line anchor in the Milestone's explorer master photograph, a title, one checkable EN/TR sentence, an honesty label and sources. The validator checks references, window/anchor bounds, the artwork–Milestone link and Turkish. The pool has 17 details, 9 Anastasis (I) and 8 Last Judgment (II), alternating, rotated by local calendar date (days since 2026-01-01 mod 17). Every sentence was fact-checked against Underwood's Dumbarton Oaks restoration reports (1956, 1958), Ousterhout (2002), Smarthistory and the Kültür Envanteri parekklesion guide. The check corrected four candidate claims:
  - IC XC flank the mandorla's tip, not the halo.
  - The gate leaves are broken, not "crossed".
  - Hades lies across a gate leaf.
  - The lost band is filled with toned plaster, not bare.
- **2026-10-01, P04: the shared element lands on the same pixels.** Today's crop and the explorer's landing rect use one `DetailCrop` of the explorer master (`CropGeometry` cover-fit; the landing rect is the window under the explorer's own bounded focus matrix). The flying crop gives way to the interactive plate once the route settles. The explorer opens at the detail with its leader-line callout and sentence; P06's PlateManifest should absorb `details` and replace the `explorerFor` adapter.
- **2026-10-01, P04: the Mile Zero dial.** A fixed plate carries true bearings, logarithmic Roman-mile rings I, II, III, V, X, XX, L (0.35 km knee, every ring labelled with its true value) and the OSM coastline in the same projection. A rotating rete index detents at each place with a light haptic; release settles on the selected place, and tapping a tick opens it. Only tangential (circular) drags turn it, so radial and vertical swipes still scroll Today. TalkBack gets an adjustable node (increase/decrease = one place, tap = open) and a list alternative by bearing. It starts on the place of the day's detail.
- **2026-10-01, P04: Milestone 0 lite, drawn from data.** The 12 s sequence runs:
  - Black, then one gold tessera.
  - Pull back to the re-erected Milion pillar in schematic hairline elevation (no dimensions claimed).
  - The OSM street plan at mile zero: T1 tram, Divanyolu footways, the Hagia Sophia and Sultanahmet footprints.
  - The OSM peninsula coastline, then rings I–IV, then five places (Chora, Yedikule, Süleymaniye, Galata Tower, Maiden's Tower), then "Every road started here."

  Skip appears after 2 s. Reduced motion shows three hand-advanced stills, and TalkBack gets a one-sentence version plus "Open Today". `tool/first_run/build_peninsula.py` rebuilds the generated Dart from pinned Overpass responses in `studio/first_run/` (ODbL, attribution in About).
- **2026-10-01, P04: provisional mosaic progress.** Until P19 earns tesserae, a tessera is "set" when its Milestone is opened (`milion_opened_milestones`, imported unchanged by P19). The Today strip and the Mosaic placeholder draw all 48 slots: gold opened, poché playable, outlined planned. The Mosaic tab lists saved Chora notes.
- **2026-10-01, P04: glyph coverage and tests.** Bundled Noto Sans lacks ≈ and →: the "1 Roman mile ≈ 1,480 m" copy now reads "is about", and arrows are drawn. Widget tests build a file-backed repository per test, because a cached load from one test's fake-async zone never completes in the next. On the emulator, `uiautomator` toggled the accessibility state and flipped the first run between spoken and animated. Modes are now one-way within a run, and the sentence and controls occupy separate regions so TalkBack reaches the button.

- **2026-10-07, P05: the dig is one data-driven page.** The place page is a vertical section: the present header, then strata newest to oldest, each with a dated title, 2–4 sourced paragraphs, media, that layer's artworks (typed rows), that layer's Milestones and collapsible sources; the visit card lives in the present layer. A pinned plate crossfades to the layer under the reading line, and the edge depth gauge previews on drag, snaps on release and both scrolls and announces through one adjustable TalkBack node. No place-specific widgets: `StratumView`/`DigPlate`/`DigGauge`/`VisitCard` render any record, proven by the two-layer Hagia Sophia draft authored purely in JSON.
- **2026-10-07, P05: authored strata show on draft places; the place-level review stays with the waves.** Chora cannot be promoted yet (no field-checked entrance/status, O15), but P05 must build and demonstrate its dig. The layers and visit card are therefore individually sourced and rendered while the record keeps `review: draft` and its "Not reviewed yet" notice; drafts without authored strata keep the P04 header only (P04 Decisions still govern their hooks, function and status). P11/P12 review the content, promote the records and may correct any layer.
- **2026-10-07, P05: the scene adapter is gone.** The temporary `Scene` model, `sceneForArtwork`, `ScenesTab` and `SceneDetailSheet` are deleted; the catalogue (`ArtworksTab`), the Mosaic note list, the scanner and the dig all render typed `Artwork` records through `ArtworkSheet`, and the classifier returns `ArtworkMatch`. The classifier still only maps prediction indices to artwork ids; catalogue data never enters it. Note keys (`scene_note_<id>`) and their bytes are unchanged.
- **2026-10-07, P05: visit facts are dated and the report row waits for O17.** `visit` carries hours with their own `hoursCheckedAt`, entry, etiquette, accessibility, transit with walking minutes, sources and a whole-card `checkedAt`; the validator rejects undated hours. Chora's card was checked remotely against the Müze İstanbul visiting page and press sources on 2026-10-07 (corrected and rechecked 2026-10-08; accessibility honestly absent), and field verification remains O15/P39. "Report a change" and its testable `mailto` builder ship, but the row stays hidden until an address exists (`milionSupportEmail`, O17).

- **2026-10-08, earlier foundation audit: implementation and acceptance are separate.** Re-read P00–P06 requirements against code, prior commits and captures, then reran local gates. P00–P04 retain local implementation; P05's device acceptance remains open; P06 has preparation only; P07–P40 remain not started. Reopened O01 instead of treating the September device connection as current. No place or Milestone was promoted. The 56 scores remain 1,696/5,600 (30.3%): repairing regressions restores the existing scope and does not complete device, content-review or release gates.
- **2026-10-08, audit: repaired gestures and reproducibility.** The gauge commits taps on release, previews held drags, clears cancelled drags without committing and paints the preview detent. Obsolete scroll-animation completions cannot overwrite a newer selection. The seed builder merges the existing index instead of dropping the later register/details/source documents. `python3 tool/content/rebuild.py` runs the P02–P05 builders in order; all 13 registry JSON files reproduce byte-for-byte. Regression tests cover gestures, index retention/idempotence/schema rejection and the postponed-opening draft.
- **2026-10-08, audit: corrected Chora claims with dated sources.** Corrected visit hours and removed an assurance that curtained naos mosaics are visible outside prayers, using the [published visiting information](https://muze.gen.tr/muze-detay/kariye). Moved the surviving naos mosaics to the Metochites layer and corrected the vault location, foundation certainty and Ottoman concealment claims against [Ousterhout's architectural introduction](https://www.columbia.edu/cu/wallach/exhibitions/Byzantium/pdf/ousterhout_intro.pdf). Replaced the asserted 30 October 2020 first prayer with the [29 October postponement announcement](https://www.aa.com.tr/tr/turkiye/kariye-camisinin-acilisi-ertelendi/2023331), also reported by [TRT](https://www.trthaber.com/haber/turkiye/kariye-camiinin-acilisi-ertelendi-526971.html). Source dates change only for rechecked/new sources; remote research does not establish field review.
- **2026-10-08, audit: P06 preparation must build before it counts.** The uncommitted sensor dependency failed AGP 9 release compilation; `sensors_plus` 7.1.1 supports the [built-in-Kotlin path](https://pub.dev/packages/sensors_plus/changelog) and the release now passes. Added explicit plate subdirectories because [Flutter directory declarations exclude nested directories](https://docs.flutter.dev/ui/assets/assets-and-images). Fixed OpenCV BGR encoding so the river mask is in the shader's R channel; it covers about 5.4% of the plate instead of every pixel. All seven maps decode at the master dimensions and ship with the compiled shader in APKs/AAB. Source photographs and their hashes are unchanged. This verifies preparation, not a running PlatePlayer or gyroscope feature.

- **2026-10-08, P06: one manifest-driven player.** The separate plate catalogue parses strict schema-1 manifests and verifies ownership, citations and unchanged Today windows/anchors/sentences. Routing no longer hard-codes F02/F05 to a scene model. Controls are Story/Light/Layers around an original-first full-screen plate; the advanced six-second study/sliders are debug-only. Each plate has a 10 s reveal, a 32 s seekable/pausable story, free exploration and bilingual manual stills. Story camera movement is bounded; touch exploration stops a camera tween.
- **2026-10-08, P06: constrained light and motion.** `surface.png` packs normals in RGB/depth in A; authored gold masks replace broad pigment heuristics. A single scoped 1.2 s wrist beat uses the retained rig at 0.25 strength, labelled IMAGINED; faces/scenery outside the windows stay fixed. River and scroll are separate masked passes. Reconstruction draws the original first and overlays only damaged regions; pixel tests caught and fixed the earlier unmasked shader resampling. `FragmentProgram`/cached shader instances follow [Flutter runtime-shader guidance](https://docs.flutter.dev/ui/design/graphics/fragment-shaders); gyro integration uses the [documented radians-per-second samples](https://pub.dev/documentation/sensors_plus/latest/sensors_plus/GyroscopeEvent-class.html), low-pass output and ±6° bounds. Sampling is opt-in, re-centred by touch, and cancelled on background/exit. Reduced motion has manual stills and no automatic effects.
- **2026-10-08, P06: local resource limits and acceptance.** Owners dispose shaders, rig and decoded images, including loads finishing after exit. The 62,220-vertex Judgment rig is bilinearly resampled to 59,800; Anastasis remains 54,891. Decoded textures are 76,113,920 / 87,123,200 bytes, below 150 MB; these counts exclude total device GPU overhead. All three APKs/AAB contain the two manifests, eight maps and compiled shader; photo bytes are unchanged. Evidence: `studio/captures/P06/` and `test/goldens/P06/`: 197 app tests, 122 total golden baselines (12 new), 57 stills and three 8.00 s / 192-frame clips. Clips use native Flutter test frames with simulated drag/timeline, not a device recording; capture helpers repaint retained layers for complete output. No Android target is available, so physical gyro/TalkBack, total GPU memory/60 fps and human/native/image review stay open. I–II remain prototypes. P07 is the next implementation phase.

- **2026-10-12, audit: who implemented a phase does not change the bar.** P05 and P06 (implemented with another model) passed their own tests, yet the audit found defects those tests never exercised. Each repair below has a regression test or a measurement, and the scores in PROGRESS were rescored only where the evidence changed. P00–P04 were not re-audited beyond the gates (analyzer, 197 tests and the validator passed before any change).
- **2026-10-12, audit: P05 repairs.** The dig selected a layer only when its top reached the reading line, so no page could reach its oldest layer (Chora never showed 330). The page end now selects it; Chora and Hagia Sophia tests fail without the fix. An interrupted gauge animation no longer forces its target; the 200% title is one line with an ellipsis; Go carries its walking-directions tooltip for TalkBack. The validator requires Turkish layer titles and bodies (standing rule 4). Content, checked against official and press sources: the 29 August 1945 decision assigned Kariye to the Ministry of National Education as a museum, not a "national monument"; the case was brought in 2010 by an association (Sürekli Vakıflar Derneği), not in 2005 by a foundation; the Council of State's 10th Chamber annulled the allocation on 11 November 2019, and the presidential decision was published on 21 August 2020 ([Resmî Gazete](https://www.resmigazete.gov.tr/eskiler/2020/08/20200821-21.pdf), [Hürriyet](https://www.hurriyet.com.tr/yazarlar/sedat-ergin/danistay-kariye-ile-ayasofya-arasinda-sikisinca-41556934)). The Komnenian rebuilding loses an unsupported earthquake; Planudes worked here in the 1290s, not in the "last Byzantine century" ([Ousterhout](https://www.columbia.edu/cu/wallach/exhibitions/Byzantium/pdf/ousterhout_intro.pdf)). "Kommenos" is corrected to "Komnenos". Hagia Sophia's draft post-1453 layer now runs to the present, so its 2020 facts belong to it; the separate paid gallery route dates from 15 January 2024 ([AA](https://www.aa.com.tr/tr/gundem/ayasofyada-biletli-ziyaret-uygulamasi-basladi/3109415)), and Mehmed II reads "II. Mehmed" in Turkish.
- **2026-10-12, audit: P06 repairs.**
  - The wrist beat drew the original photograph while the story drew the relief, so it popped. It also played the rig's whole two-cycle loop, two reach-and-returns in 1.2 s. It now uses the story's texture, eases the tilt out around the gesture, and plays one reach and return.
  - Every shader sampler defaulted to nearest-neighbour (Flutter's `setImageSampler`), so DEPTH, light, flow and the wipe shimmered when zoomed. Textures are now medium-filtered and maps low-filtered.
  - Masked river and scroll passes were unlit, so they showed as darker patches. They are now lit like the plate around them, and flow is two-phase, so it never snaps.
  - The scroll pivots on its mask centroid (0.489, 0.460), not an edge point copied into Anastasis.
  - The gyro integrator relaxes to centre (2.5 s), smooths by time, and locks portrait while a sensor steers.
  - Pausing or peeking no longer resets the user's zoom (a story camera revision).
  - Plates carry a bilingual TalkBack description, Original/Next/Previous actions, and live captions.
  - The painter repaints on controller changes only, not on every pan frame.
  - One stale manifest removes its own plate, not the whole app, and Today shows only details whose Milestone can open.
  - Routing no longer names F02/F05, and the per-scene wrapper screens are gone.
- **2026-10-12: honest labels for moving paint.** §3 calls DEPTH "the same pixels"; flowing fire and a rolling scroll move painted pixels, so those states, and the whole beat that carries the wrist gesture (not just its 1.2 s), read IMAGINED. II drops its reconstruction wipe: WR is not one of II's techniques, and the "pale and differs" mask covered 52% of the fresco, including intact pale groups. Its 4K study moves to `studio/restoration_studies/v2/`, saving 3.5 MB of bundle, and II's honesty set no longer lists RECONSTRUCTION.
- **2026-10-12, P07: plate schema 2.** Only the ORIGINAL layer is required. The DEPTH layer, a reconstruction with its damage mask, `flow {mask, period, distance}`, `spiral {mask, center}`, the gesture `rig` (required exactly when a beat has a gesture) and `lookUp` are optional. A bilingual `description` and a `revealMoment` are required. The unused `mesh.geometry` load and `scrollCenter` are gone; rigs resample at their own aspect.
- **2026-10-12, P07: the production line.** One command (`tool/plate/build.py`) runs ingest → SAM 2.1 segmentation (manual masks override) → depth, normals and gold → optional pop-up split → adaptive mesh → WebP maps, the manifest, the Milestone record and a validation report, then a 6 s preview drawn by the real PlatePlayer in a headless Flutter test. There is no scene-specific code: a test fails if any stage names a plate, and I–II rebuild from yaml with P06's authored maps as provided inputs. Model revisions are pinned and their outputs cached; the content and plate rebuild is byte-identical. Choices:
  - **WebP lossless over KTX2.** Flutter decodes WebP on Android; KTX2 needs a GPU texture path Dart does not expose.
  - **OpenCV Telea over LaMa.** LaMa is not installed locally.
  - **Lossless ingest.** EXIF is stripped from JPEG segments, so the pixels stay bit-identical and ORIGINAL stays true.
  - **Fold-free mesh.** It is relaxed until no triangle folds at the player's largest parallax.
  - **The mesh does not ship.** The runtime parallax is per-pixel, so the mesh is validated for the PU layers (P14) and later 3D/export work.
- **2026-10-12, P07: depth models measured, then demoted.** Against P06's hand-built relief, Depth Anything V2 Small/Base and Marigold v1.1 correlate *negatively*: Spearman −0.50/−0.46/−0.44 on I and −0.52/−0.51/−0.27 on II. They measure the architecture (the concave apse), not pictorial depth; their high-pass detail correlates at about 0. Runtimes: DA-V2 Base ≈1.5 s on CPU, Marigold ≈4 s on MPS. The pipeline uses DA-V2 Base on CPU (deterministic) for fine detail only (weight 0.3, high-pass), and SAM-segmented figures get the relief from bulge/planar priors. The gold heuristic was measured on III–V: gold ground is saturated even in shadow (S 190–236, V 88–121), while bare plaster has S≈80 and almost no tesserae texture. It is now hue + saturation + local texture.
- **2026-10-12, P07: LU.** The dome photograph is read through an ordinary (rectilinear) lens, not a fisheye:
  - **Crown and rim.** The crown medallion is the zenith; the rim is an ellipse measured on the photograph, because the photographer stood slightly off the axis.
  - **Rim elevation.** 75° comes from Underwood's 3.74 m span and 10.54 m crown (hemispherical dome, 1.6 m eye). It is labelled DEPTH, as an approximation (O03).
  - **Sensor.** Android's game rotation vector (no magnetometer) arrives through `milion/rotation` after an explicit opt-in; the heading is re-centred to the photograph's top. A flat pan with pinch zoom is the fallback.
  - **View.** The field of view is 42° (a phone overhead), so you look around to meet the ancestors. The reveal tilts from the crown towards the ring while turning a third of the way round. Near the crown the azimuth eases to upright.
- **2026-10-12, P07: III–V content.** Details and captions cite Underwood's *The Kariye Djami* vol. 1 (1966) by printed page, Ousterhout (2002), Psalm 116:9 and Luke 2:1–5. Popular claims that were checked and avoided: Adam holds a tree, not a torch; the governor's white cylinder is "not a scroll"; Mary draws her maphorion rather than holding her belly; the title is Logothete of the Genikon, not Grand Logothete (1321). The Detail-of-the-day pool grows from 17 to 38, with P04's 17 byte-identical, and is interleaved so consecutive days change artwork. Windows were reshaped where Today's cover crop would have hidden the anchor; wide story views keep their own beat windows. III–V are `prototype`, not approved.
- **2026-10-12, P07: manual minutes.** The yaml `manualMinutes` (III 25, IV 35, V 25) are estimates of agent authoring time (prompts, windows, beats, rim measurement), excluding the shared literature research. No human has authored a plate with the pipeline yet; time the first one.
- **2026-10-13, P08: three backends, one model, measured on the A52s.** The spike model is the study's own bay at 49,864 triangles (`studio/spikes/p08/bench-50k.glb`, sha256 7b7622bb…). (a) The Canvas renderer adds no dependency, renders in tests, goldens and offscreen captures, and has hairlines, a section plane and poché; it drew the 50k model at 27–28 fps and the 20k study at 54–57 fps in its default view. (b) flutter_scene 0.24.3 (Flutter GPU, "early preview", one maintainer, +3.5 MB) drew 50k at 58 fps (build 6.5 ms, raster 2.4 ms); it has no section plane and only 1-px native lines. (c) thermion 0.5.0 (Filament v1.69.1, +6.8 MB, OpenGL ES only on Android, a build-time download from r2.dev blocked on this network, compileSdk 33) drew 50k at 60 fps. **Decision:** (a) for drawing-style studies up to about 20k triangles; the immersive backend (cistern walk) is chosen at the start of P14 between (b) and (c). Records: `studio/spikes/p08/*/result.json`.
- **2026-10-13, P08: the drawing-style budget is 20k triangles, not 150k.** §3 assumed a GPU renderer. The Canvas renderer is CPU-bound (about 0.3–0.5 µs per drawn triangle on the A52s), so §3's drawing-style row now reads ≤ 20k triangles per study; larger scenes need the P14 backend.
- **2026-10-13, P08: what the phone taught.** Impeller falls back from Vulkan to OpenGL ES for every app on this A52s. Flutter 3.47 runs Dart on the Android main thread (no `1.ui` thread), so the engine's fast-core pinning does not apply to frame building. Android performance hints are unavailable (`dumpsys performance_hint`: HAL Support false). The CPU governor settles at different clocks from run to run: a lighter 13.6k-triangle tessellation ran *slower* (32–38 fps) than the 20.1k one (54–57 fps), and Night (fewer triangles) ran at 30 fps with even its trivial sort loop 2.9× slower. The study therefore keeps 20,144 triangles. The renderer was rewritten from a staging copy to records, a 16k-bucket counting sort and one direct write: on the host a frame fell from 2.7 to 1.6 ms; on the phone the median stayed 10.5–10.9 ms while the default view's p90 fell from 34–41 to 12–16 ms (the governor may account for part of that). Next: the same benchmark with `io.flutter.embedding.android.DisableMergedPlatformUIThread`; if that is not enough, build frames in a background isolate. The flag is not committed until measured.
- **2026-10-13, P08: the study format.** A study is `assets/space/<id>/model.glb` (glTF 2.0, Y-up converted to Z-up on load, node transforms applied, one named node per part, closed solids, `_AO`, a `material` extra; required extensions refused) plus `study.json` (schema 1: epochs, steps with parts, labels, captions, seconds, epochs and sources; a reveal up to a step; Choisy's plan-cut height; citations). The validator parses both and refuses open solids. Places name studies on a layer (`studies` on a stratum); "How a dome stands" sits on Hagia Sophia's 532–537 layer.
- **2026-10-13, P08: honesty for 3D.** A study has no photograph, so it is never ORIGINAL; it reads RECONSTRUCTION throughout and says it is "a diagram, not a survey of either building". The 31 m bay follows Hagia Sophia's span (30.86–31.24 m); the cascade compares Hagia Sophia's two semi-domes (537) with the Şehzade Mosque's four over a 19 m dome (1548); the window ring follows Hagia Sophia's 40 windows and Procopius's "suspended from Heaven" (Buildings I.1.46).
- **2026-10-13, P08 audit: plate sheets under the marble app.** The plate control sheets drew a marble surface behind lamp controls, so their headings were marble on marble; P06/P07 captures hid this because they ran under a lamp root theme. Sheets now carry their own surface and text style; a regression test fails without the fix.
