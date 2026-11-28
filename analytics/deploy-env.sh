# Source from a Bash deployment step. Never print credential values.
set +x
export CLOUDFLARE_API_TOKEN="$(node -p '(process.env.CLOUDFLARE_API_TOKEN || "").trim()')"
export CLOUDFLARE_ACCOUNT_ID="$(node -p '(process.env.CLOUDFLARE_ACCOUNT_ID || "").trim()')"
if [[ ! "$CLOUDFLARE_API_TOKEN" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo 'CLOUDFLARE_API_TOKEN is missing or malformed. Copy only the token value into GitHub Secrets.'
  exit 1
fi
printf '::add-mask::%s\n' "$CLOUDFLARE_API_TOKEN"
if [[ ! "$CLOUDFLARE_ACCOUNT_ID" =~ ^[0-9a-fA-F]{32}$ ]]; then
  echo 'CLOUDFLARE_ACCOUNT_ID must be a 32-character hexadecimal account ID.'
  exit 1
fi
printf '::add-mask::%s\n' "$CLOUDFLARE_ACCOUNT_ID"
