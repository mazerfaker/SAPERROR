# Roadmap — GDD §12 is authoritative
| Version | Scope | Gate |
|---|---|---|
|0.1 Core|Board, solver, CLASSIC, diagnostics UI, first portable EXE|Unit + 1000 seeds, Windows CI, win/loss, smoke|
|0.2 Visual Foundation|Immutable approved terminal PNG, masked live CRT SubViewport, cells, main menu, UA/EN|Imported art screenshots 720p/1080p, verified EXE|
|0.3 Onboarding|Boot, 9 tutorial stages, Classic, 4 difficulties, settings, saves|Novice tutorial and persistence tests|
|0.4 Run & Builds|Economy, shop, 15 modules, 5 tools, 4+ rules|Effects and solver regression, no exploits|
|0.5 Anomalies|PHANTOM, PARASITE, PORTAL, LOOP, DOUBLE; routes; WATCHER/LIAR|Certified authored challenges|
|0.6 Campaign|4 acts, 10 sectors, LOOP/ADMIN, 3 endings, credits|All routes and endings pass|
|0.7 Content & Art|Remaining certified rules and anomalies, final graphics/audio, gallery, Free Run|No placeholders, complete content|
|0.8 Beta|Balance, accessibility, localization, resolution, performance|Regression QA and human playtests|
|0.9 RC|Feature freeze, clean Windows and release packaging|No blockers, manual acceptance|
|1.0 Release|Finished offline Windows game, release docs|GDD §11 Definition of Done, portable EXE/source/patch and tests|

All milestones unapproved until their gates pass. No multiplayer or online for 1.0. Preserve the GDD and verified code, split milestones when needed. Core CI passed 45842971602. Visual Foundation uses the approved original PNG without repainting. See VISUAL_FOUNDATION.md. The visual candidate remains unapproved until runtime and manual QA gates pass.

Visual milestone split: v0.2.1 screenshot-driven refinement, v0.2.2 audio foundation, v0.2.3 CRT boot/outcome presentation. This does not reorder the authoritative GDD milestones from v0.3 onward.

Onboarding split: alpha.1 provides four bounded CLASSIC profiles, persistent settings and active-sector resume, first five guided exercises. Full nine-stage tutorial remains incomplete: rewind, alternate-rule teaching, shop/modules and anomaly mechanics require their proper implementation. The GDD remains authoritative.

Alpha.3: scanner, nonfatal charged rewind, three free cartridges, lessons 6–7. GDD tools/economy integrations and terminal outcome rollback remain future scope. Training is 7 of 9 stages, not complete.
