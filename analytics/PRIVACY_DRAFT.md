# SAPERROR — privacy notice draft (not approved for public release)

## Українська
Ігрова аналітика добровільна, вимкнена за замовчуванням і не потрібна для гри. Мета — зрозуміти складність, тривалість ігрових сесій та покращити баланс. За згодою гра передає версію, режим, складність, приблизний активний час, сектор, перемоги/поразки та випадковий ідентифікатор сесії. Ідентифікатор не зберігається на пристрої та не визначає унікального гравця. Не передаються імена, облікові записи, файли збережень, чат, координати чи ідентифікатор пристрою. Запити обробляє Cloudflare; IP використовується для обмеження частоти запитів і не записується до D1. Cloudflare може окремо обробляти мережеві метадані. Записи видаляються щоденним завданням після 30 днів від останнього оновлення; резервні копії провайдера можуть мати інший строк. Згоду можна відкликати у Налаштуваннях > Приватність; це зупиняє нові надсилання, але не видаляє вже прийняті записи негайно.

## English
Optional gameplay analytics are off by default and not required to play. The purpose is to understand difficulty, play duration and improve game balance. With consent, the game sends its version, mode, difficulty, approximate active play time, sector, wins/losses and a random session identifier. The identifier is not stored on the device and is not a unique player identifier. Names, accounts, saves, chat, coordinates and device IDs are not sent. Cloudflare processes requests; IP addresses are used for rate limiting and not stored in D1. Cloudflare may separately process network metadata. Records are removed by a daily task after 30 days since the last update; provider backups may have different retention. Consent can be withdrawn in Settings > Privacy; new sends stop, but accepted records are not immediately removed.

## Release gate
- Owner must supply an accurate controller identity/contact and review applicable privacy obligations, provider terms and international transfers before release.
- Confirm final bilingual notice accessible before consent; check installer and in-game layout manually.
- Keep production ingestion disabled and client endpoint empty until owner approval.
- Pass isolated runtime integration, then controlled real-client deployment tests; no public release before opt-in, opt-out, revocation and offline checks.
- No claims of unique players or guaranteed anonymous data. Public endpoint accepts client-reported data; distributed abuse remains possible.
