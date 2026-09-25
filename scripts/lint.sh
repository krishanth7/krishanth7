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

main() {
  printf '\033[1mlint.sh — repository checks\033[0m\n'
  check_shell
  check_sass
  check_html
  check_links

  printf '\n'
  if (( failures > 0 )); then
    printf '\033[38;5;196m%d check(s) failed\033[0m (%d skipped)\n' "$failures" "$skipped"
    return 1
  fi
  printf '\033[38;5;77mall checks passed\033[0m (%d skipped)\n' "$skipped"
}

main "$@"
