#!/usr/bin/env bash
#
# lint.sh — Static checks for the repository.
#
# Runs every check that is available in the current environment and skips the
# rest, so it is safe to run locally and in CI. Exits non-zero if any check
# that did run reported a failure.
#
# Checks:
#   shell  — bash -n on every script, shellcheck when installed
#   sass   — compilation of profile/scss/main.scss
#   html   — presence of required landmarks in profile/index.html
#   links  — no obviously malformed local asset references
#
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 1
readonly ROOT
failures=0
skipped=0

pass() { printf '\033[38;5;77m  PASS \033[0m %s\n' "$*"; }
fail() { printf '\033[38;5;196m  FAIL \033[0m %s\n' "$*"; failures=$((failures + 1)); }
skip() { printf '\033[38;5;245m  SKIP \033[0m %s\n' "$*"; skipped=$((skipped + 1)); }
head_() { printf '\n\033[1m%s\033[0m\n' "$*"; }

# --- shell --------------------------------------------------------------------
check_shell() {
  head_ "shell"
  local script
  while IFS= read -r script; do
    if bash -n "$script" 2>/dev/null; then
      pass "syntax: ${script#"$ROOT"/}"
    else
      fail "syntax: ${script#"$ROOT"/}"
    fi
  done < <(find "$ROOT/scripts" -name '*.sh' -type f | sort)

  if command -v shellcheck >/dev/null 2>&1; then
    if shellcheck --severity=warning "$ROOT"/scripts/*.sh; then
      pass "shellcheck"
    else
      fail "shellcheck"
    fi
  else
    skip "shellcheck (not installed)"
  fi
}

# --- sass ---------------------------------------------------------------------
check_sass() {
  head_ "sass"
  if command -v sass >/dev/null 2>&1; then
    if sass --no-source-map --style=compressed \
         "$ROOT/profile/scss/main.scss" /dev/null 2>&1; then
      pass "compiles: profile/scss/main.scss"
    else
      fail "compiles: profile/scss/main.scss"
      sass --no-source-map "$ROOT/profile/scss/main.scss" /dev/null || true
    fi
  else
    skip "sass compile (Dart Sass not installed)"
  fi

  if [[ -f "$ROOT/profile/css/main.css" ]]; then
    pass "compiled stylesheet is committed"
  else
    fail "profile/css/main.css is missing — run ./scripts/build.sh"
  fi
}

# --- html ---------------------------------------------------------------------
check_html() {
  head_ "html"
  local file="$ROOT/profile/index.html"
  if [[ ! -f "$file" ]]; then
    fail "profile/index.html is missing"
    return
  fi

  local -a required=(
    '<!DOCTYPE html>'
    '<html lang='
    'name="viewport"'
    'name="description"'
    '<main id="main">'
    'class="skip-link"'
    'css/main.css'
  )
  local needle
  for needle in "${required[@]}"; do
    if grep -qF -- "$needle" "$file"; then
      pass "contains: ${needle}"
    else
      fail "missing: ${needle}"
    fi
  done

  # Every <img> should carry an alt attribute.
  if grep -o '<img[^>]*>' "$file" | grep -qv 'alt='; then
    fail "an <img> element has no alt attribute"
  else
    pass "all images have alt text"
  fi
}

# --- local asset references ---------------------------------------------------
check_links() {
  head_ "assets"
  local file="$ROOT/profile/index.html"
  local ref missing=0
  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    if [[ ! -e "$ROOT/profile/$ref" ]]; then
      fail "referenced file not found: profile/${ref}"
      missing=1
    fi
  done < <(grep -oE '(href|src)="(css|js|assets)/[^"]+"' "$file" | sed -E 's/.*="([^"]+)"/\1/' | sort -u)
  (( missing == 0 )) && pass "all local asset references resolve"
}

# --- profile card -------------------------------------------------------------
check_card() {
  head_ "card"
  local card
  local found=0
  for card in "$ROOT"/profile/card/card-*.svg; do
    [[ -e "$card" ]] || continue
    found=1
    if python3 -c "import sys,xml.etree.ElementTree as E; E.parse(sys.argv[1])" "$card" 2>/dev/null; then
      pass "well-formed XML: ${card#"$ROOT"/}"
    else
      fail "malformed SVG: ${card#"$ROOT"/}"
    fi
  done
  (( found )) || fail "no rendered cards in profile/card — run ./scripts/build-card.sh"

  if [[ -f "$ROOT/profile/card/stats.json" ]]; then
    if python3 -c "import json,sys; json.load(open(sys.argv[1]))" \
         "$ROOT/profile/card/stats.json" 2>/dev/null; then
      pass "stats cache is valid JSON"
    else
      fail "profile/card/stats.json is not valid JSON"
    fi
  else
    fail "profile/card/stats.json is missing"
  fi

  # The card is generated; a stale commit would show wrong figures. Re-render
  # from the cache and compare, which needs no network.
  local tmp
  tmp="$(mktemp -d)"
  if "$ROOT/scripts/gen_card.py" --offline --theme matrix \
       --out "$tmp/card-matrix.svg" >/dev/null 2>&1; then
    if diff -q "$tmp/card-matrix.svg" "$ROOT/profile/card/card-matrix.svg" >/dev/null 2>&1; then
      pass "committed card matches its generator"
    else
      fail "profile/card/card-matrix.svg is stale — run ./scripts/build-card.sh --offline"
    fi
  else
    fail "gen_card.py failed to render"
  fi
  rm -rf "$tmp"
}

main() {
  printf '\033[1mlint.sh — repository checks\033[0m\n'
  check_shell
  check_sass
  check_html
  check_links
  check_card

  printf '\n'
  if (( failures > 0 )); then
    printf '\033[38;5;196m%d check(s) failed\033[0m (%d skipped)\n' "$failures" "$skipped"
    return 1
  fi
  printf '\033[38;5;77mall checks passed\033[0m (%d skipped)\n' "$skipped"
}

main "$@"
