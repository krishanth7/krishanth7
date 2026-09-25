#!/usr/bin/env bash
#
# build.sh — Compile the Sass sources for the profile site.
#
# Resolution order for a Sass compiler:
#   1. `sass`            (Dart Sass — preferred)
#   2. `npx sass`        (local or fetched Dart Sass)
#   3. `sassc`           (libsass)
#
# Usage:
#   ./scripts/build.sh              # compressed production build
#   ./scripts/build.sh --dev        # expanded build with source maps
#   ./scripts/build.sh --watch      # rebuild on change
#   ./scripts/build.sh --check      # verify the build toolchain only
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 1
readonly ROOT
readonly SRC="${ROOT}/profile/scss/main.scss"
readonly OUT="${ROOT}/profile/css/main.css"

log()  { printf '\033[38;5;39m[build]\033[0m %s\n' "$*"; }
warn() { printf '\033[38;5;179m[warn ]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[38;5;196m[error]\033[0m %s\n' "$*" >&2; exit 1; }

# Echoes the compiler command to use, or fails.
detect_compiler() {
  if command -v sass >/dev/null 2>&1; then
    printf 'sass'
  elif command -v npx >/dev/null 2>&1 && npx --no-install sass --version >/dev/null 2>&1; then
    printf 'npx sass'
  elif command -v sassc >/dev/null 2>&1; then
    printf 'sassc'
  else
    return 1
  fi
}

compile() {
  local mode="$1"
  local compiler
  compiler="$(detect_compiler)" || die "no Sass compiler found. Install Dart Sass: npm i -g sass"

  log "compiler : ${compiler}"
  log "source   : ${SRC#"$ROOT"/}"
  log "output   : ${OUT#"$ROOT"/}"

  mkdir -p "$(dirname "$OUT")"

  if [[ "$compiler" == "sassc" ]]; then
    warn "libsass is deprecated; @use support may be incomplete. Prefer Dart Sass."
    case "$mode" in
      dev)  sassc --style expanded --sourcemap "$SRC" "$OUT" ;;
      *)    sassc --style compressed "$SRC" "$OUT" ;;
    esac
  else
    case "$mode" in
      dev)   $compiler --style=expanded   --source-map            "$SRC" "$OUT" ;;
      watch) log "watching for changes (Ctrl-C to stop)"
             $compiler --style=expanded   --source-map --watch    "$SRC" "$OUT" ;;
      *)     $compiler --style=compressed --no-source-map         "$SRC" "$OUT" ;;
    esac
  fi

  if [[ -f "$OUT" ]]; then
    log "done — $(wc -c < "$OUT" | tr -d ' ') bytes"
  fi
}

check() {
  local compiler
  if compiler="$(detect_compiler)"; then
    log "Sass compiler available: ${compiler}"
  else
    die "no Sass compiler on PATH"
  fi
  [[ -f "$SRC" ]] || die "missing source: ${SRC}"
  log "toolchain OK"
}

main() {
  case "${1:-}" in
    --dev)        compile dev ;;
    --watch)      compile watch ;;
    --check)      check ;;
    ""|--prod)    compile prod ;;
    -h|--help)    sed -n '3,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' ;;
    *)            die "unknown option: $1" ;;
  esac
}

main "$@"
