# QA — 0.1.0-alpha candidate
- GDD reviewed and copied unchanged.
- Runtime GDScript/headless import: passed on Windows CI run 45837724510; local Godot unavailable.
- Windows CI: run 45837724510 passed import/tests/export/headless smoke; overall failed at packaging.
- Automated suite defined: topology incl. edge cases, INVERT zero, flags/flood, chord/neutralization, HP/win/loss, subset, 1000 seeds and certificate replay, deterministic sample.
- No claims of verified gameplay, performance, GUI or Windows executable. Manual launch, input, localization, win/loss, visual review pending.
- Production UI/art, other generation profiles and full campaign are future gates; CLASSIC only in this build. No speculative enablement of other modes.
- Fallback is a deterministic edge-pattern family accepted only after certification, not individually authored narrative boards.
- No previous stable tag: no patch against a previous release. Full source is the initial baseline.

## Local evidence
- `python tests/reference_model.py`: 1000/1000 independently generated Python-model cases, 64/64 first-click locations with certifiable fallback, no unsound deductions; Python RNG differs from Godot. See REFERENCE_QA.txt. This does not verify GDScript parsing or runtime correctness.
- Static checks: workflow YAML parse, CSV column/key consistency, referenced preload paths, GDD byte-for-byte equality. No actual Windows or Godot runtime run.

## Repository initialization
Private repository created by owner. Core CI status pending; earlier repository-access blocker resolved.

## CI run 45834974390 — failed
- Windows runner and checksum-verified Godot 4.7.2 editor/templates installed successfully.
- Cold import failed because project.godot referenced CSV-generated translation resources before their creation. No tests or export executed.
- Fix: use source-controlled gettext PO catalogs; test runtime UA/EN switching. Retain strict import error gate.
- Retest pending; no Windows package verified.

## CI run 45837724510
- CORE_QA checks=4060 failures=0 seeds=1000 fallback=0.
- Windows release export and headless smoke passed; manual GUI QA not performed.
- Packaging exited with code 1 without a more specific visible diagnostic. Likely cause: git describe returned failure for absent prior tag and PowerShell propagated the exit status.
- Fix: enumerate reachable release tags successfully even when none exist; verify portable/source ZIP required entries and SHA-256 hashes before publication. Retest pending.

- Run 45842898342 failed before job creation: malformed workflow introduced by replacement-string interpolation. Repaired regex line and removed duplicated tail; retest pending.

## Visual Foundation candidate
- Baseline 0.1 Core CI run 45842971602 succeeded. 0.2 candidate retains the verified board, solver and generator unchanged.
- Original PNG transferred byte-identically via verified reconstruction; CI rejects mismatched SHA-256. Native contour manually traced; runtime geometry tests added.
- Visual shader compilation, actual rendered pixels, cursor interaction, window scaling, localization layout and manual Windows screenshots still require confirmation.
