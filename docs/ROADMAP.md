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

0.4 alpha.1 economy foundation: credits, shop, scanner stock, five real modules; provisional prices/capacity. Repair and HP carry, replacement, remaining modules and active tools planned in subsequent alpha versions. Shop tutorial not yet implemented.

0.4 alpha.2: HP carry, repair, shield, Second Life/Fuse/Auditor, confirmed replacement and lesson 8. Eight real modules of fifteen; balance and manual QA pending. Remaining systems split into later alpha releases.

0.4 alpha.3: 11/15 modules, 4/5 active tools, six cartridges, extended persistent counters. Four anomaly/archive-dependent modules and cleansing deferred until their mechanics exist; no fake effects. Statistics UI and balance pass pending.

Visual integration override: alpha.3-live.1 approved live background before v0.5 anomalies. Preserve full gameplay and original static fallback. Require exact assets, scheduler QA, native render/audio evidence and manual visual acceptance; no claim of real 24h rendering from accelerated logical stress.

0.5 alpha.1 PHANTOM, journal, cleansing, Shielding/Hotfix and lesson 9 candidate. One marked clue per sector from sector 3, temporary concealment only, classic proof remains available. PARASITE and PORTAL next after CI. Shielding/Hotfix currently support PHANTOM only; NULL and other anomaly interactions deferred. Prices/cadence provisional.

0.5 alpha.2 PARASITE candidate: 14/15 modules, one public proven-safe target, three-action countdown, five with Stabilizer, free emergency cleanse if no charge after lock; alternate anomaly types to avoid unsolved interactions. No mine movement. PORTAL next after passing tests and manual acceptance.

User-approved batch workflow: alpha.3–alpha.7 use [skip ci] commits, tests authored but deferred. Full v0.5 Beta regression and manual gates only after all five stages. PORTAL draft adds reversible linked topology; no claims of passing until Beta.

Alpha.4 LOOP implemented as independent Anomaly Lab authored challenge; campaign routes and persisted challenge progression remain separate. No intermediate CI.

Alpha.5 DOUBLE and PARALLEL trial, no intermediate CI.

Alpha.6 WATCHER authored boss trial, no intermediate CI.

Alpha.7 LIAR authored boss trial, no intermediate CI. Full combined v0.5 Beta gate next.

0.5 Beta.1: first combined Windows regression after [skip ci] alpha.3–alpha.7. The Anomaly Lab contains LOOP, DOUBLE/PARALLEL, WATCHER, LIAR. PHANTOM/PARASITE/PORTAL are in normal run sectors. No claim of full GDD milestone until tests and manual acceptance; persistent campaign encounters, routes/rewards, Archivist and full balance remain open. Scope is Anomaly Beta, not v0.8 product Beta.

0.5.0-beta.1 passed combined Windows CI (46027804129). 0.6 alpha.1 campaign foundation, separate mode, act intros and mandatory bosses. Preserve Anomaly Lab and Free Run; defer CI until Campaign Beta. Manual acceptance, route choices, checkpoints, full boss phases, ADMIN and endings pending.

0.6 alpha.2–3 routes/archives, Archivist, act checkpoints, ADMIN intro asset path. Optional challenge HP is independent. CI deferred.

0.6 alpha.4–7 LOOP temporal stages, ADMIN phases, ending gates, credits/gallery, combined authored-route tests. CI deferred pending original ADMIN MP3 and Beta gate.

0.6 Beta.1: first combined campaign regression, including all three routes and ending scenes, boss phases, retry and exact ADMIN asset. Human visual/audio acceptance and campaign balancing remain open. Existing background unchanged.
