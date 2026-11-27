# Changelog
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
