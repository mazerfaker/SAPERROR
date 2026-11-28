# SAPERROR Analytics — deployment
Private dashboard (green CRT style), Cloudflare Workers + D1. No production endpoint is committed; ingestion defaults OFF. No account credentials or passwords belong in Git.

## Data and consent
Only schema version, cryptographically random session ID (new per mode/difficulty segment, not persisted), game version, mode, difficulty, approximate focused gameplay seconds, wins/losses and highest sector. No name, account, stable device ID, seed, save files, chat, location or raw actions. IP is used transiently by Cloudflare rate limiting; not written to D1. Cloudflare may process network metadata independently. No persistent client queue. Heartbeats every 60 seconds, best-effort outcome updates; offline/short sessions may be missing. A session is not a unique player. Counts are approximate and client-reported, not suitable for billing or authoritative leaderboards. No collection before v3 consent AND a configured HTTPS endpoint. Revocation cancels local pending request and clears counters; already accepted data remains until expiry. Raw records expire 30 days after last update via daily cron; provider backup retention may differ. See [bilingual privacy notice](../PRIVACY.md); owner review of applicable laws is still required before public release.

## Deploy (owner action)
Install Node.js 22+ and run from the analytics directory:
1. npx wrangler@4 login
2. npx wrangler@4 d1 create saperror-analytics
3. Copy the actual database_id into wrangler.toml (do not share API tokens). Ensure rate-limit namespace IDs are unique within your account.
4. npx wrangler@4 d1 migrations apply DB --remote
5. npx wrangler@4 secret put DASHBOARD_PASSWORD — choose a unique random password of at least 32 characters. Username admin.
6. npx wrangler@4 deploy (ingestion remains disabled).
7. Open the returned HTTPS URL, verify /health and the authenticated dashboard; run node --test test/worker.test.mjs with Node 24 for local SQLite/API tests.
8. Once privacy notice and deployment checks are accepted, set INGEST_ENABLED = "true" in wrangler.toml and redeploy. Add the exact HTTPS worker origin (no slash/path) to project.godot [saperror] analytics/endpoint and rebuild game. Existing v1/v2 consent is not used; player must opt in under new conditions.
9. Test opt-out, opt-in, revocation, offline gameplay, dashboard auth and retention in the actual deployment. Do not publish until passed. Review Cloudflare plan quotas; public ingestion has approximate edge rate limits but cannot guarantee prevention of fabricated submissions or distributed abuse.

The dashboard updates every 60s. /api/summary also requires authentication. No credentials embedded in game. Disable ingestion via variable or clear game endpoint and redeploy/rebuild. No telemetry on headless QA.

## GitHub deployment (preferred)
The D1 database is already configured. In repository Settings > Secrets and variables > Actions, create repository secrets CLOUDFLARE_ACCOUNT_ID, CLOUDFLARE_API_TOKEN and SAPERROR_DASHBOARD_PASSWORD (random 32+ characters). Restrict the token to the target account, with Workers Scripts Edit, D1 Edit and Account Settings Read as needed. Do not grant zone permissions or use the global API key. The repository is public, so never commit secret values. Deploys are deliberately triggered only by an explicit update to analytics/deploy.request on visual-foundation (or workflow_dispatch if available from the default branch). Ordinary gameplay commits do not deploy. First deployment keeps INGEST_ENABLED=false and the game endpoint empty. No production ingestion until separately approved and tested.
