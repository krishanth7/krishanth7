#!/usr/bin/env bash
#
# build-card.sh — Render the profile status cards.
#
# Wraps gen_card.py so the card builds the same way as the rest of the
# repository's tooling. Live GitHub data is used when reachable; otherwise the
# cached figures in profile/card/stats.json are reused, so the card never
# invents numbers and the build never fails offline.
#
# Usage:
#   ./scripts/build-card.sh              # both themes, live data if reachable
#   ./scripts/build-card.sh --offline    # cached figures only, no network
#   ./scripts/build-card.sh --theme matrix
#
# Environment:
#   GITHUB_TOKEN  Optional. Raises the GitHub API rate limit.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 1
readonly ROOT
readonly OUT_DIR="${ROOT}/profile/card"

log() { printf '\033[38;5;77m[card ]\033[0m %s\n' "$*"; }
die() { printf '\033[38;5;196m[error]\033[0m %s\n' "$*" >&2; exit 1; }

themes=(matrix cyber)
offline=()

while (( $# )); do
  case "$1" in
    --offline) offline=(--offline) ;;
    --theme)
      [[ $# -ge 2 ]] || die "--theme needs a value"
      themes=("$2")
      shift
      ;;
    -h|--help)
      sed -n '3,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

command -v python3 >/dev/null 2>&1 || die "python3 is required to render the card"
mkdir -p "$OUT_DIR"

token=()
[[ -n "${GITHUB_TOKEN:-}" ]] && token=(--token "${GITHUB_TOKEN}")

for theme in "${themes[@]}"; do
  log "rendering theme: ${theme}"
  "${ROOT}/scripts/gen_card.py" \
    --theme "$theme" \
    --out "${OUT_DIR}/card-${theme}.svg" \
    "${offline[@]}" "${token[@]}"
done

log "cards written to ${OUT_DIR#"$ROOT"/}"
