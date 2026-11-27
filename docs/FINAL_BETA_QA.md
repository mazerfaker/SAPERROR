# Final Product Beta — 0.8.0-beta.8

Previous verified baseline: 852a89c, CI 46046217846, 686103 assertions, 566 synergy assertions, no failures. Candidate CI not yet verified.

## Automated acceptance
- All previous regression suites remain enabled; derive counts from actual QA markers, not estimates.
- Actual isolated UI session write/reload: hardcore combined anomaly state, economy, settings, collection, proof-only win, no duplicate credits, next sector, corrupt-primary backup recovery and mandatory boss gate. Uses same production serialization with an explicit test-only file path.
- Persist last sector reward readout across reload; legacy missing field defaults to zero.
- Native rendering and 72-second playback smoke must both be confirmed before packaging; actual 72-hour hardware soak is not performed by the accelerated test.
- Portable, source and patch ZIP entry verification; approved artwork, icon, audio and all live resource gates. Include README, license inventory and this QA checklist in portable ZIP.

## Manual release gates (NOT completed)
- Clean Windows install and upgrade from prior beta; launch EXE with PCK, resume active save, backup/recovery, native fullscreen.
- Test 720p, 1080p, 1440p, 4K and ultrawide on real hardware; both locales; menu, tutorials, campaign, shop, boss and ending screens; keyboard and mouse.
- Listen to all original and new sound events, mixer, lamp, ADMIN and loop seams. Measure actual FPS, frame time, memory and extended hardware soak.
- Human novice and experienced player runs, balance and comprehension; all four difficulties and three endings.
- Audit third-party audio rights, Steam capsule assets, store page and release distribution. Installer and opt-in telemetry remain deferred to release preparation.
- Full text scaling, screen reader integration, first-launch warning, general anomaly combinations beyond three normal-field types remain open.

No merge into main or 1.0 release authorization implied.
