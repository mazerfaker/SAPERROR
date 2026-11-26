# Changelog
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
