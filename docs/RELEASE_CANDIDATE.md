# SAPERROR Release Candidate — 0.9.0-rc.1
Verified beta baseline: 6826dcd / CI 46047792977 (30 suites, 686123 assertions, zero failures). RC.1 freezes gameplay features; only release blockers, accessibility completion, QA and packaging changes. No main merge or public release.
## RC.1
- Localized first-launch warning before screen effects and boot audio; normal or reduced effects + mute. Persist acknowledgement and independent lamp toggle. Default lamp cadence and exact approved assets remain unchanged for normal play.
- Engine LICENSE.txt and COPYRIGHT.txt from the pinned upstream tag, bundled with portable game. Correct license inventory; external audio provenance is still a blocker, not cleared by filename.
- New isolated warning/setting and lamp tests; full prior regression and native smoke gates retained. CI pending.
## RC.2 (proposed)
- Manual Windows acceptance and fixes: clean install/upgrade, fullscreen/windowed, physical displays, audio listening, actual hardware performance, novice and experienced players, all difficulty profiles, screenshots, both locales.
- Review remaining GDD gaps, especially text scale and first-run flow. No unapproved mechanic expansion.
## RC.3 (proposed)
- Installer and opt-in analytics only as separately reviewed release preparation, preserve offline gameplay, no credentials in repo, no analytics activated without consent. Audit asset license evidence and Steam package/capsules; release notes and checksums.
## Release gate
No 1.0 until confirmed manual acceptance, unresolved critical/high issues closed, audio redistribution rights documented, verified Windows/source/patch, and explicit approval. Existing GitHub runner Node 20 warning is noncritical. Native smoke is not a real 72-hour hardware run.
