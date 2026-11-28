# SAPERROR — 1.0.0 (Private build)
The numbers don't lie. Usually. / Числа не брешуть. Зазвичай.

Offline Windows x64 analog-horror minesweeper roguelite. Godot 4.7.2 stable. This is the feature-frozen 1.0.0 private-use build based on RC9. It is not a public release or a manually accepted hardware build. Do not redistribute packages or source assets without rights clearance.

## Play
Extract the whole Windows x64 ZIP into one folder and run SAPERROR.exe. Keep SAPERROR.pck next to it. No Godot installation needed. Campaign: four acts, ten sectors, four difficulties and three endings. Anomaly Lab and Classic are separate modes; finite Free Run unlocks after an ending. Endless mode is also available. Settings include Ukrainian/English, audio mixer, CRT and accessibility. Local save is in Godot user:// (normally %APPDATA%/Godot/app_userdata/SAPERROR/ on Windows); back up the session files before upgrading. Optional session analytics are off by default; opt in or revoke in Settings > Privacy. The installer also offers an unchecked opt-in. No internet connection is required for play. See [PRIVACY.md](PRIVACY.md).

Controls: left click reveal, right click or physical F flag, middle click or Space on open cell chord, arrows move focus, Tab changes control, Enter/Space activates, Escape goes back, F11 toggles fullscreen when CRT has focus. Horror, sudden audio and flashing light: adjust audio and accessibility options. The first-launch warning offers a reduced-effects and mute preset; room lamp flicker can be switched off separately.

## Source
Open project.godot with Godot 4.7.2 stable, import and press F5. Matching export templates required for a Windows build. Original approved room PNG, live assets and icon must not be replaced. [GDD](docs/SAPERROR_GDD.md) | [Roadmap](docs/ROADMAP.md) | [Final beta QA](docs/FINAL_BETA_QA.md).

## CI
Development branch visual-foundation. Download packages only from a successful workflow. Source ZIP and cumulative binary patch against the baseline named in patch-base.txt are separate from the portable game. Native smoke gates, certified boards, regression suites, ZIP entries and asset hashes are checked. Hardware acceptance and rights clearance remain open before public distribution. Version 1.0.0 archives and image-bearing QA artifacts are uploaded only when the repository is private. See [release notes](docs/RELEASE_NOTES_100.md).

## License
Project rights retained. See LICENSES.md. Third-party audio provenance/redistribution clearance must be completed before public release.
