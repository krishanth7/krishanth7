#!/usr/bin/env bash
#
# serve.sh — Serve the profile site locally for development.
#
# Usage:
#   ./scripts/serve.sh            # serve on port 8000
#   ./scripts/serve.sh 3000       # serve on a custom port
#
set -euo pipefail

readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly DOCROOT="${ROOT}/profile"
PORT="${1:-8000}"

log() { printf '\033[38;5;39m[serve]\033[0m %s\n' "$*"; }
die() { printf '\033[38;5;196m[error]\033[0m %s\n' "$*" >&2; exit 1; }

[[ "$PORT" =~ ^[0-9]+$ ]] || die "port must be numeric, got: ${PORT}"
[[ -f "${DOCROOT}/index.html" ]] || die "missing ${DOCROOT}/index.html"

# Build the stylesheet first when a compiler is available; never block serving.
if [[ ! -f "${DOCROOT}/css/main.css" ]]; then
  log "stylesheet missing — attempting a build"
  "${ROOT}/scripts/build.sh" --dev || log "build skipped (no Sass compiler)"
fi

log "document root : ${DOCROOT}"
log "listening on  : http://localhost:${PORT}"

if command -v python3 >/dev/null 2>&1; then
  exec python3 -m http.server "$PORT" --directory "$DOCROOT"
elif command -v php >/dev/null 2>&1; then
  exec php -S "localhost:${PORT}" -t "$DOCROOT"
elif command -v npx >/dev/null 2>&1; then
  exec npx --yes serve --listen "$PORT" "$DOCROOT"
else
  die "no static server available (need python3, php or npx)"
fi
