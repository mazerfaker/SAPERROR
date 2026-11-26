# SAPERROR — 0.1.0-alpha (Core candidate)
The numbers don't lie. Usually. / Числа не брешуть. Зазвичай.

Windows x64, offline, Godot 4.7.2 stable + matching templates. This is an internal Core candidate, not the finished game and not a verified binary. Master specification: [GDD](docs/SAPERROR_GDD.md). See [roadmap](docs/ROADMAP.md) and [QA](docs/QA.md).

## Run source
Open project.godot in Godot 4.7.2 stable; import, run F6/F5 (F5 for main scene). Left click to reveal, right click to flag, middle click or Space on an open cell to chord. First click creates an 8×8 certified board with 10 mines and three HP. Seed is a signed integer. Restart to change seed. UA/EN switches immediately. This deliberately uses a diagnostic UI; production art is v0.2.

## CI
Push to the authorized private GitHub repository; Windows workflow imports, executes 1000 seed cases and unit checks, exports and packages. Download only after success. Portable archive contains EXE/PCK together. No engine installation required for that archive. The first source snapshot is the patch baseline. Do not call any build stable before CI and manual verification.

## License
Project source/art rights retained; third-party Godot licensing information in LICENSES.md.
