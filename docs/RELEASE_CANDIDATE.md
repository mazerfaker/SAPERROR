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

## RC.8 — Final Release Validation
Baseline RC.7 commit 64abdbfc6ccb1e59deb9fb2f71f4b05cc2aca9ca. Analytics unit, isolated D1 integration, production read-only smoke and Windows package workflows passed. RC.8 adds automated privacy settings/restart and simulated transport failure checks; pending CI. Existing production analytics uses explicit v4 consent and schema 2. No synthetic production session is inserted.

### Manual release acceptance (not yet confirmed)
- [ ] Install the new Retro98 package on a real Windows PC; default unchecked; launch and play without internet, then test the portable package.
- [ ] With explicit consent, play Classic or Campaign actively for at least 65 seconds; verify the RC.8 version/mode in the authenticated dashboard. This is a real voluntary session, not an automated production write.
- [ ] Withdraw consent in Settings > Privacy; play again and confirm no new session or updates from that client; accepted records are retained according to PRIVACY.md.
- [ ] Restart after withdrawal, confirm Off; opt in again and verify a fresh session. Disconnect internet while opted in and ensure gameplay continues.
- [ ] Review clean install/upgrade/uninstall, both locales, accessibility and physical display/audio performance.
- [ ] Obtain documented redistribution rights for all external audio identified in LICENSES.md, including the ballast recording; review source-package rights.
- [ ] Obtain explicit public release approval. CI is not manual acceptance. No public release or main merge in RC.8.

## RC.9 — automated native release validation
RC8 c4194f5: Windows run 46152288064, analytics run 46152288079; passed. Server commit b011257: D1 run 46152115391, deploy run 46152115476; passed. Installer handoff allow and deny passed. Owner opted to skip their own manual test; record this as not performed, not as passed. RC9 adds a required native game-window active clock and offline gameplay check (20 seconds real elapsed, menu exclusion, resume, revoke; transport removed before consent; no production writes). Full physical hardware and actual end-to-end real-client delivery remain unverified. Private candidate only; no public release until remaining redistribution and release authorization gates are resolved.

## 1.0.0 — private-use preparation (owner approved)
RC9 commit e30cbfa passed Windows CI 46153280062 and Analytics QA 46153280076 including mandatory native analytics clock/offline gate and installer allow/deny handoff. The owner approved proceeding to the private-use 1.0.0 build, without personal manual testing. This does not waive public redistribution rights or constitute hardware acceptance. Version and packaging only; no gameplay or approved assets altered. All final archives and SHA256 manifest required. CI pending. The repository was public at preparation time; final archive and image-bearing QA artifact uploads are gated on private repository visibility. No public release, tag or main merge.

## 1.0.1 stability hotfix
Based on 1.0.0 preparation c2fd175 (its Windows CI was still running when development began). RC9 is the last confirmed full Windows baseline at that point. Add RAM-only bounded final summary buffering and native close save. Final release CI pending, no claim of real production delivery. Owner requested keeping repository public until hotfix completion; do not publish archives while public.
