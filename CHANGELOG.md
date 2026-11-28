# Changelog
### RC.6 approved Glitch Plus pointer
Replace the original 32px custom arrow with the user-supplied SAPERROR Cursor 06 Glitch Plus PNG, resampled to 40px preserving transparency and artwork. Hotspot (8,2) at the arrow tip. Existing native cursor integration and hit mapping remain unchanged.

### RC.6 DOS startup transcript
Use the approved screenshot-inspired MS-DOS 7.10 startup transcript verbatim with Vergil and KONAMI lines. English console text in both locales. Remove progress bar and static BIOS heading; begin with | after the CRT fully opens, type the transcript for five seconds, hold C:\\>_ for 0.5 seconds, then show menu. Shutdown unchanged.

### RC.6 BIOS terminal typing
Keep the aperture animation free of all text and progress elements. On full opening, show only the input caret, then type the localized BIOS transcript character by character. Meter appears later, complete transcript and 100% hold before menu. BIOS duration 2.8 seconds. Shutdown unchanged.

### RC.6 synchronized CRT aperture and BIOS
Replace full-screen fade with vertically compressed raster expanding from the central phosphor line and collapsing back on shutdown. BIOS exclusively visible from first illumination, starts at 0%, runs after opening and holds at 100% before menu. Reduced motion and clear display retain geometry with dimmer line. Native framebuffer checks cover spatial aperture, BIOS ordering and shutdown line.

### RC.6 custom mouse pointer
Original in-game 32px CRT-green outlined arrow with dark fill and transparent background, using native custom mouse cursors for the client UI. Exact tip hotspot; no software pointer delay or change to CRT input coordinates. Asset and hotspot regression checks; physical Windows appearance still requires manual review.

### RC.6 boss header alignment
Center all mounted boss emblems on the CRT raster midpoint (x=713), raise the slot 10 raster pixels, preserve the existing 110×88 area and aspect ratio. Reserve title space and verify actual emblem geometry across text scales. Native QA captures the boss header.

### RC.6 visible cursor correction
Header cursor blinks independently of CRT filter and accessibility preferences; reduced-motion/clear-display use a gentle local fade, initial safety notice remains static. Native raster samples check actual cursor contrast and stable title in all three modes. Also align Final Polish fixture with the permanent three-module shop limit.

### RC.6 permanent loadout and economy tuning
All shops limited to three permanent modules, no replacements. Purchases disabled and grey once full; repair remains available. Legacy four-module saves retain owned items but cannot buy more. Sector reward 12 + opened/8 + 6 for clean, bosses 24, archives 8 (+5 Archivist). Prices and starting credits unchanged. Regression checks updated.

### RC.6 visible CRT power and tutorial correction
Dedicated final CRT power mask independent of all grading and filter settings; visible 2.4s boot, 1.10s shutdown with black-frame hold. Reduced motion uses gentle fade, no beam. Native screenshot/pixel acceptance gate. Tutorial action label names the next rule and final DIAGONAL state.

### RC.6 power lifecycle hotfix
Direct autosave and power-off, no confirmation screen. CRT startup and shutdown independent of filter strength; first normal startup after safety acknowledgement. Preserve reduced-motion and clear-display exceptions.

### RC.6 authored challenge readability hotfix
Replace raw cell addresses and engineering shorthand with localized explanations, matching board labels and action-based controls in all authored encounters. LIAR uses A/B/C row sensors and explicit true totals. Existing puzzle state, proof routes and K-30 unchanged.

### RC.6 interface cleanup and shared click hotfix
Use the approved menu MP3 on non-cell buttons, including embedded tutorial/classic/encounter controls, with a dedicated restartable playback voice. Keep gameplay event sounds and audio settings. Remove player-facing briefing and diagnostics entry points while retaining internal QA. Separate header cursor visibility from title text; honor reduced-motion/clear-display settings.

### RC.6 tutorial navigation hotfix
Always reopen at lesson 1, Previous/Repeat reset exercises, distinct Finish action, correction to deduction and current shop module, wrong-action guidance and localized navigation. Historical progress retained.

## 0.9.0-rc.6 — Immersion candidate
15 procedural audio cues, event-driven anomaly pulses, distinct CRT patterns and brief ADMIN/ECHO signal tones. Preserve approved MP3s, original art, CRT geometry, boot/shutdown and campaign mechanics. Respect reduced motion, high contrast, glitch and effects settings. Automated QA added; manual sound/visual review pending.

## 0.9.0-rc.5.2 — Balance & Playtest candidate
Compact campaign tuning: guaranteed coverage of all six modules across four shops, lower Story/Standard repair prices, reserve charge on genuine sector transitions, two Standard free hints, fixed boss-sector reward. Legacy economy untouched. Added automated balance checks; human playtest pending.

## 0.9.0-rc.5.1 — Campaign Refinement candidate
New compact campaigns enter boss sectors directly, optional memory records replace repeat puzzles, four shop visits, contextual boss coaching, and direct progression. Original campaign routes remain supported for old saves. Full campaign and manual QA pending.


### RC.5 ending cleanup
Removed the in-game credits page and buttons. Endings now link directly to the main menu or ending gallery; replay returns to the gallery. License inventory remains in the release files. CRT lifecycle unchanged.
## 0.9.0-rc.5 — Gameplay Simplification candidate
New campaigns use six shop modules, three slots, two rotating offers, repair, simpler HUD and rules, single scheduled anomaly at a time on Story/Standard. Existing campaigns and free modes retain their original systems. Campaign field-count restructuring is deferred pending progression/save QA.

## 0.9.0-rc.4 — Narrative Overhaul candidate
Live campaign transmissions for all ten sectors, responsive damage and anomaly lines, typewriter presentation, revised act/optional archive/final dialogue and clearer boss instructions. No save or gameplay rule changes. Manual narrative pacing and visual review pending.

## 0.9.0-rc.3 — First Experience candidate
Guided story recommendation, contextual early-field coach, simplified controls, revised opening hook and optional upgrade messaging. Other difficulties and save format unchanged. Manual novice acceptance pending.

## 0.9.0-rc.2 — Final Polish candidate
Cancel-first exit and replacement confirmation, persisted preferred text size with fixed CRT fit, locale parity and 4000 certified profile seed QA. Manual graphics/audio/hardware acceptance still required.

## 0.9.0-rc.1 — Release Candidate
Feature freeze baseline 6826dcd. First-run bilingual warning, persisted reduced-effects/mute choice, separate room lamp toggle, official matching Godot license files and corrected third-party audio inventory, new RC regression gate. Manual acceptance and audio rights pending; no installer/analytics yet.

## 0.8.0-beta.8 — Final Integration candidate
End-to-end isolated real save/reload and recovery QA, persistent last reward readout, strict native smoke packaging gate, verified patch ZIP entries, updated player README and manual release checklist in portable ZIP. No telemetry, installer, new art or main merge. CI pending.

## 0.8.0-beta.7 — Anomaly Synergy candidate
Persisted sector anomaly plans; Story single, Standard/Expert pairs after sector 5, Hardcore triple after sector 5. Separate free journal records, shared Hotfix limit, emergency blocked-cell cleanse, portal-independent Phantom clue selection, combined save validation and public-proof replay. Existing active saves retain legacy schedule. Authored challenge mechanics remain separate. CI pending.

## 0.8.0-beta.6 — Accessibility & UI Polish candidate
Persistent high-contrast palette, larger cell symbols, clear CRT mode without altering stored CRT preferences, keyboard-focused grid navigation and layout-independent flag shortcut across all field UIs, visible transparent focus outline, Escape navigation and F11 fullscreen in CRT focus. Localized accessibility settings and content warning; unchanged original composition and mapped input. Automated checks added; manual readability, physical display testing and whole-UI text scaling pending.

## 0.8.0-beta.5 — Audio Ultimate candidate
13 original one-shot procedural signals for tools, shop, anomalies and story progression; 27 one-shot event types including exact approved MP3s (lamp separate). Persistent Master gain, independent channels, score and lamp routing, priority-aware bounded six-voice pool. Existing hum/score samples and approved MP3/WAV unchanged. Headless waveform/routing/voice QA and existing native loop smoke required; listening acceptance pending.

## 0.8.0-beta.4 — profile balance candidate
Story 40 CR/3 stock, 20 CR repair and sector-start checkpoint including selected seed and pre-move purchases. Standard unchanged. Expert 25 CR, Hardcore 20 CR; Hardcore Profit bonus 25% instead of 50% since minimum HP already one. Campaign encounters use profile HP on each independent authored layer; Lab remains 3. 64 certified generation/replay samples, all 4 difficulties in full campaign integration, profile economy and checkpoint regression. Values provisional pending real playtests.

## 0.8.0-beta.3 — long-run stability candidate
72h virtual clock ×100 with checkpoints at 5/10/24/48/72h, 60 actual protocol-driven sector advances and repeated UI disposal checks, unchanged texture/player identity, bounded UI/PCM caches and save validation. Separate 72s native playback-head wrap smoke with frame/memory reports. No claims of actual 72h rendering/audio or measured absence of all leaks before testing.

## 0.8.0-beta.2 — performance QA parser repair
CI 46037036515 passed every prior test suite (217226 checks), but the new test script could not parse because its preload alias Panel shadowed a native Godot class. Rename the alias to PerformanceReadout, retain all assertions. Rerun full CI before accepting performance changes.

## 0.8.0-beta.2 — conservative performance candidate
Bounded shared tile/mark styles for all field UIs; unchanged main-grid styles/text/tooltip not rewritten; Classic timer samples on integer seconds; idle CRT and audio mixer writes suppressed; zero-strength grade hidden and inactive chromatic distortion sampling skipped. Local diagnostics under Help. No changes to assets, raster dimensions, CRT contour/bulge or score samples. Actual FPS/RAM/GPU gains not measured; new regression and native QA pending.

## 0.8.0-beta.1 — save resilience candidate
Staged checksum-sealed version-1 config, verified previous-generation backup, primary/backup/staged recovery, visible recovery warning, legacy migration and failure-path tests. No board schema or approved art/audio changes. Full CI required; not a guarantee against physical disk failure or simultaneous writers.

## 0.7.0-beta.1 — MAGNET certification repair
CI 46034527457 rejected post-exchange board (13/21 safe cells reached by independent reproduction). Use swap of closed indices 1 and 2 instead, both states solvable in independent direct/subset simulation with identical initial visibility. Keep native Godot certification mandatory, assert exactly two announced endpoints change. Full CI rerun pending.

## 0.7.0-beta.1 — combined Content & Art candidate
First CI after all seven alpha stages. Existing regression plus extended authored anomalies, Classic/finite run, imported boss/act/ending art, original narrative audio, and collection. Package must retain eleven narrative SVG resources and approved audio/live assets. Candidate, not a completed release: actual visual/audio acceptance, GDD 25 SFX target, broader anomaly interactions, and balance remain open.

## 0.7.0-alpha.7 — collection and polish (CI deferred)
Persistent read-only recovered archive collection (three new bilingual story records), unlocked ending thumbnails, locked states, credits link, and lab completion marks. Collection data validated and migrated from current campaign records; never grants run keys or rewards. Tests authored; full Beta QA next.

## 0.7.0-alpha.6 — narrative audio (CI deferred)
Eleven original procedural quiet atmospheric cues: four act pads, four boss variations, three ending themes. 48 kHz native 32-second loops from phase-matched eight-second periods, fade-out/switch/fade-in, bounded three-stream cache, independent persistent Music slider and preview. Original hum synthesis, supplied MP3s and lamp audio unchanged. QA authored, listening and CI pending.

## 0.7.0-alpha.5 — illustrated endings (CI deferred)
Three original imported SVG illustrations for SHUTDOWN, CONTAINMENT and REWRITE, localized result status and short distinct nonblocking transitions. Reduced Motion keeps illustrations static. Gallery replay returns to gallery and does not mutate story progress. Existing audio preserved for the next dedicated audio stage. QA authored, not executed.

## 0.7.0-alpha.4 — act illustrations (CI deferred)
Four original imported vector plates: BOOT signal, CORRUPTION damaged grid, ECHO duplicated memory, ADMIN sealed root-access eye. Live UA/EN dialogue, sector range and status, brief optional nonblocking fade and static Reduced Motion. Existing navigation and story unchanged. Art/layout tests authored; actual render acceptance pending.

## 0.7.0-alpha.3 — boss identity art (CI deferred)
Four original SVG emblems in the approved phosphor palette, dedicated accent and low-opacity slow scan. Static with Reduced Motion. Boss header reserves art area above board; ADMIN identity retained in all three phases and on introduction. No room background or board logic changes. Import/layout tests authored; visual acceptance pending.

## 0.7.0-alpha.2 — Classic and Free Run (CI deferred)
Independent Classic 6/8/10 square fields, one HP, optional timer, seed and retry; no anomalies, economy or modules. Finite Free Run ten sectors unlocked after any ending. Preserve legacy Endless and campaign save. Classic session is in-memory only. Tests deferred.

## 0.7.0-alpha.1 — extended anomaly lab (CI deferred)
MIMIC cosmetic closed-cell distortion, NULL voluntary scanner restriction, INSTABILITY announced third-action CROSS shift and free classic fallback, MAGNET explicit one-shot closed-cell exchange with both states gated by classic certification. Four authored lab trials, no campaign topology change. New tests authored; CI deferred.

## 0.6.0-beta.1 — complete campaign candidate
First combined CI: all three endings via actual UI and public-deduction normal sectors and trials, route metadata, checkpoint retry, Hardcore restart, gallery and credits. Require exact approved ADMIN MP3. No intermediate CI. Candidate until CI and manual QA pass.

## 0.6.0-alpha.4–7 — campaign finale (CI deferred)
Two LOOP temporal stages, three ADMIN phases (PORTAL topology, DOUBLE, LIAR), one-shot approved intro event, optional REWRITE trial, three gated endings, terminal ending scenes and credits/gallery. Phase transitions and ending metadata persist. Existing art and menu audio unchanged. No full campaign certification yet; manual presentation and asset licensing pending.

## 0.6.0-alpha.2–3 — routes, Archivist, checkpoints (CI deferred)
Optional archive gates at sectors 2/5/8, 15 CR plus Archivist 10 CR once, key records only from recovered archives, act checkpoints and Hardcore restart. ADMIN one-shot source path and exact hash registered; missing asset remains silent until upload. Tests deferred.

## 0.6.0-alpha.1 — campaign foundation (CI deferred)
Campaign and Free Run modes, four act intros, ten-sector bound, mandatory WATCHER/LIAR/LOOP gates, three memory records and saved metadata. Boss retries use local HP. ADMIN is an explicit unfinished gate, not an ending. Routes, checkpoints, final boss and endings remain upcoming. No intermediate CI.

## 0.5.0-beta.1 — combined Anomaly QA candidate
- First combined CI after all five deferred alpha commits. Full previous regression, exact audio/live resources, portal topology, four authored trials and public-deduction replay through each trial, real UI creation/retry/controls. Candidate, not accepted release. Campaign routes/rewards, persistent lab completion, remaining Archivist, full anomaly combinations, balance and manual QA remain open.

## 0.5.0-alpha.7 — LIAR (CI deferred)
Three distinct marked row sensors, exactly one false reading, three true pair sums. Identifying the corrupted sensor and clearing the authored field are both required. Ordinary tile clues unchanged. Retry and feedback. Campaign encounter and reward deferred.

## 0.5.0-alpha.6 — WATCHER (CI deferred)
Three marked groups of clues hidden after five actions, free journal preserves exact data, retry and victory. Boss authored trial, campaign integration deferred.

## 0.5.0-alpha.5 — DOUBLE (CI deferred)
Two authored boards, visible paired clues, A/B switch, independent health and dual victory gate. PARALLEL scoped to trial, campaign integration deferred.

## 0.5.0-alpha.4 — LOOP authored trial (CI deferred)
- Anomaly Lab entry from main menu; isolated 5x5 authored board with runtime classic certificate gate. One marked local checkpoint reset after three actions; restores cell states but not neutralized mines, HP or run resources. Retry and completion presentation. No campaign reward or persisted trial in this draft. Tests queued for v0.5 Beta.

## 0.5.0-alpha.3 — PORTAL draft (CI deferred)
- Bidirectional, deduplicated visible link on sectors 5,8,11,...; after initial certified reveal. Board clues, solver observation, hover, analyzer, chord and flood share the same linked topology. Free ON/OFF control preserves original certified proof route. Saves and rewind persist topology. No simultaneous anomalies in this draft. Tests added but not executed until v0.5 Beta by request.

## 0.5.0-alpha.2 — PARASITE candidate
- Alternate PHANTOM and PARASITE in sectors 3+; one logically proven safe target, three successful actions before lock, stabilizer +2. If opened early infection resolves. Direct reveal, flags, chord/flood cannot bypass lock; cleanse restores access, including no-resource emergency purge after lock. No mine/clue changes. Persist and validate state, preserve old saves and K30; Hotfix shared across anomalies. Provisional pacing and emergency fallback, CI/manual QA pending.

## 0.5.0-alpha.1-audio.1 — terminal hum loop and menu click
- Preserve the hum timbre while expanding its native phase-locked PCM loop to 60 seconds at 48 kHz. Test wrap slope and all internal joins. Menu-only one-shot MP3 path with original byte hash and existing SFX volume; original procedural fallback until supplied asset is uploaded. All other sounds and live lamp audio unchanged. Manual listening pending.

## 0.5.0-alpha.1-ui.1 — language settings
- English is the default for new settings; saved language selections remain respected. The only language toggle is Settings, with localized current-language label and instant update. Remove menu and board language shortcuts, reclaim board footer space. K-30, PHANTOM and approved live assets unchanged. Add default, toggle, screen visibility and preference regression tests. Manual layout verification pending.

## 0.5.0-alpha.1-k30.1 — physical input hotfix
- Recognize K-30 once in root Window input before GUI focus/CRT forwarding, reset partial sequence when window loses focus, preserve physical key precedence. Regression uses root.push_input with different focus targets and Ukrainian logical keycodes; no change to board or environment. Requires a generated unfinished field, after first reveal. Actual physical Windows keyboard verification still pending.

## 0.5.0-alpha.1 — PHANTOM foundation candidate
- One deterministic PHANTOM episode from sector 3, after three successful board actions; temporarily hides one previously visible clue for three further actions. Free journal preserves exact value and topology; other cartridges remain truthful. Scanner restores the hidden clue using an available hint, Cleanse uses one scanner stock or free Hotfix. Shielding prevents the first PHANTOM episode. Prices and activation cadence are provisional. Save and rewind preserve anomaly state; spent cleansing clears previous rewind. K-30 remains unchanged.
- Ninth authored tutorial demonstrates journal and cleansing. Existing approved live environment, original art, CRT, board generator and solver unchanged. PARASITE/PORTAL/LOOP/DOUBLE, remaining modules, bosses, NULL and campaign deferred; do not claim full v0.5 milestone. CI and manual UI QA pending.

## 0.4.0-alpha.3-live.1 — approved live environment integration
- Native 1920x1080 draw list ports approved HTML scheduler; original base, lamp overlay, six segment states and exact High post layers. No browser/test UI; one preloaded audio player with nominal 0.1 gain multiplied by current game SFX and mute; lamp follows playback head. Freeze when minimized and clamp frame delta as in HTML. No generated art or audio.
- Keep approved legacy PNG as fallback, map CRT contour onto native canvas; preserve raster, shader, input mapping, fullscreen and gameplay. Existing optional scene grade is limited to CRT on live composition to preserve original keyboard and High device. CI verifies 23 exact asset hashes and prevents fallback release packaging; tests compare JS fixtures, 24h x100 logical stress, fixed resource counts, and attempt separate real renderer/audio checks. Manual art/actual audio latency and real long-run GPU/RAM acceptance remain pending.

## 0.4.0-alpha.3 — advanced builds candidate
- Three new modules: Resonance (+4 CR per three matching nonzero clean action clues; flood counts once), Profit Parasite (+50% rounded down; max HP -1, no free healing on removal), Third Eye (one bounded 3x3 count per sector). Analyzer spends stocked scanner charge for an alternate clue on an open tile. Selection does not reveal tiles. Tool expenditure invalidates previous rewind to avoid refunds; move rewards/counters rewind together.
- Enable INVERT, RANGE II, WRAP using existing topology, preserve classic generation certificate and saves. Persist earned/spent credits for future statistics UI. Additional regression tests. Prices provisional. Remaining anomaly-dependent modules, cleansing, ninth lesson and full statistics presentation deferred. Manual playtest pending.

## 0.4.0-alpha.2 — survival and upgrades candidate
- Carry HP across sectors, 30 CR repair, one purchased/armed shield (18 CR provisional), Second Life, Fuse and Auditor. Protection uses the existing board reveal and chord topology; protected hits still count as hits for clean reward. Sector start HP and protected hit count validated in saves, with legacy defaults.
- Confirm module replacement (no refund); rollback move rewards and protection state with nonfatal rewind. Eight of nine guided lessons, isolated practice shop. Old alpha.1 pending runs without persisted HP migrate to full profile HP. Prices and limits provisional. Remaining seven modules, anomaly tools, analyzer, terminal rewind and campaign deferred. Core board/solver, icon, CRT and original PNG unchanged.

## 0.4.0-alpha.1 — Run & Builds foundation
- Persistent credits, bounded scanner inventory, once-per-sector reward, deterministic intersector shop, five passive modules and charge purchases. Standard starts with 30 CR and 2 stocked scanner charges in addition to the existing free hint allowance. Other profiles start with 30 CR and no stock (provisional balance).
- Module effects and earned scanner charges are restored on a nonfatal move rewind; spent hints invalidate rewind to avoid refunds. K-30 uses the same reward path and auto-advances; shop remains available before the next first click. No per-move module rewards from K-30.
- Deferred: HP carry/repair, module replacement, other 10 modules, remaining active tools, anomaly and campaign interactions. No change to original art, icon, fullscreen, BoardState or solver. CI and manual QA pending.

## 0.3.0-alpha.3 — tools and cartridges candidate
- Public-constraint safe scanner (3/1/0/0), free CLASSIC/CROSS/DIAGONAL switching on the same certified board, hover/focus adjacency highlights. No charge without proof.
- Temporary one nonfatal move rewind per Story/Standard sector, 0 for Expert/Hardcore; previous state and remaining charges persisted. No economy or final-outcome rollback yet. Lessons 6–7 use real damage, rewind and topology; remaining shop/anomaly lessons deferred.
- Preserve K-30, official icon, fullscreen, immutable PNG and existing BoardState. New automated tests; manual UI acceptance pending.

### 0.3.0-alpha.2-k30 — fullscreen and approved icon follow-up
- Start in fullscreen by default (Godot window mode 3), retaining the settings toggle to switch to windowed mode during the session. Preserve the existing aspect-ratio handling. Match the uploaded ICO filename exactly; both icon assets are mandatory in CI.

## 0.3.0-alpha.2-k30 — icon integration, secret protocol and CRT signal candidate
- Fixed approved 25% legacy bulge coefficient 0.04 independent of CRT strength; matched click mapping. Subtle flicker and infrequent short video faults with separate toggle and reduced-motion suppression.
- Hidden physical-key sequence, staged administrator reveal/flag animation, localized CRT log and synthetic confirmation tone. Shared classic sector completion/advance path, persisted sector index and pending transition, one win per activation. No rewrite of BoardState or solver.
- Windows icon settings and CI verification; approved PNG/ICO binaries must be uploaded before icon-certified build. Missing assets explicitly produce provisional build. Full campaign/final sector/anomalies not implemented yet; no claims of their testing. Manual Windows rendering/audio/icon QA pending.

## 0.3.0-alpha.1-crt.2 — fixed-projection CRT
- Remove geometric distortion from both shader and input mapping. Intensity is now color-only post-processing inside the approved glass contour; no enlargement, shrinking or warping of the UI. Replace curvature setting with optional glass shading; legacy setting ignored.
- Preserve scanlines, phosphor bloom, dither and electronic effects; soften scanline modulation and fix glass reflection math. Keep boot/shutdown luminance masks without spatial transforms. Regression tests verify fixed raster mapping and invariant display bounds at all intensities. Manual Windows visual acceptance pending.

## 0.3.0-alpha.1-crt.1 — screenshot-driven CRT correction
- Normalized strength-dependent barrel warp with shared input mapping; no out-of-range sample strip. Stronger antialiased scanlines, subtle phosphor grille, two-radius halo, ordered 4x4 dither, vignette and soft glass reflection. Exact zero-strength bypass in ready state.
- Live 0–100% CRT slider, power-off animation bypass when CRT disabled, increased geometry and material-binding checks. Original PNG untouched. Windows graphical acceptance still pending; headless cannot certify shader appearance.

## 0.3.0-alpha.1 — Onboarding Foundation candidate
- Four certified CLASSIC difficulty profiles, local active-sector resume, persistent graphics/audio/language, session statistics and first five guided exercises. Original PNG and core BoardState unchanged.
- Profile generator retains legacy Standard and independently certifies every new profile; fail closed. Save validates mask, cell states, HP and certificate. No campaign checkpoints, hints, rewind, modules or anomaly tutorial yet.
- Base: successful v0.2.3 run 45858799859. New CI and manual QA pending.

## 0.2.3-alpha — CRT Immersion candidate
- Skippable 2.4s CRT power-on and localized boot panel, beam warm-up and power-off collapse with synthetic shutdown sound and hum fade.
- Transient sector win/loss banner and additive CRT outcome tint; input blocked during boot/shutdown; reduced-motion mode bypasses shutdown and outcome motion. Headless boot skipped.
- Lifecycle and scene integration QA gate. Original artwork, board core and stable main unchanged. Manual rendered/audio QA pending.
- Base: successful v0.2.2 CI 45858022124.

## 0.2.2-alpha — Audio Foundation candidate
- CI fix: use fposmod instead of fract; explicit packed float note arrays prevent runtime type mismatch; guard null synth output and add audio test watchdog. Previous run 45851679941 passed 4060 core checks / 1000 seeds and 62 visual checks but audio test failed and timed out.
- Original procedural PCM: mechanical key, reveal, flood, flag/unflag, fault, win/loss, invalid, boot and continuous industrial hum. Six bounded SFX voices.
- Real board-state-driven feedback, separate effects/hum sliders and mute, localized audio page. Settings are session-only for now.
- Audio PCM regression tests and Windows CI gate. Human listening and new visual review pending. Approved original PNG and board core unchanged.
- Base: successful v0.2.1 CI run 45848165101.

## 0.2.1-alpha — Visual Refinement candidate
- Screenshot-driven larger grid, clearer cells and labels, live recovery meter, real control hints and seed preservation.
- CRT edge feather, ordered dither, subtle phosphor halo and reduced-motion-aware cell flash. Approved artwork and core unchanged.
- Geometry regression checks; new Windows CI and manual screenshot pending.

## 0.2.0-alpha — Visual Foundation candidate
- Immutable approved original PNG, masked live CRT SubViewport, native aspect letterboxing, shared shader/input transform.
- Custom terminal controls, menu, instructions, settings, live 8×8 certified CLASSIC board and HUD, UA/EN. CRT and optional whole-scene filter foundation.
- Visual geometry tests and asset integrity check. No campaign, modules, bosses, saves or finished visual acceptance claimed.
- Baseline: successful 0.1 CI run 45842971602.

## 0.1.0-alpha — candidate, not released
- Independent board, immutable mask, classic reveal/flood/chord/flags/neutralization, win/loss.
- Pure topology helpers for six single-layer rules; only CLASSIC enabled in gameplay.
- Public-observation solver with direct and subset deduction, separate truth validator, replayable certificate.
- Deterministic bounded generation and validated fallback patterns; one supported 8×8/10 profile.
- Core diagnostic UI, UA/EN live switch, tests and Windows workflow.
- First GitHub CI attempt reached engine import; blocked by cold-checkout localization. Replaced generated CSV translations with source-controlled PO catalogs and added locale regression checks. No verified EXE or production art yet.

- Second CI run: 4060 checks passed, 1000 certified seeds, Windows export and headless smoke passed; packaging failed. Fixed no-prior-tag handling and added ZIP entry verification; awaiting CI confirmation.
