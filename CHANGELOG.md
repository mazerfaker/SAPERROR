# Changelog
## 0.1.0-alpha — candidate, not released
- Independent board, immutable mask, classic reveal/flood/chord/flags/neutralization, win/loss.
- Pure topology helpers for six single-layer rules; only CLASSIC enabled in gameplay.
- Public-observation solver with direct and subset deduction, separate truth validator, replayable certificate.
- Deterministic bounded generation and validated fallback patterns; one supported 8×8/10 profile.
- Core diagnostic UI, UA/EN live switch, tests and Windows workflow.
- First GitHub CI attempt reached engine import; blocked by cold-checkout localization. Replaced generated CSV translations with source-controlled PO catalogs and added locale regression checks. No verified EXE or production art yet.

- Second CI run: 4060 checks passed, 1000 certified seeds, Windows export and headless smoke passed; packaging failed. Fixed no-prior-tag handling and added ZIP entry verification; awaiting CI confirmation.
