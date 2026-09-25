#!/usr/bin/env bash
#
# profile.sh — Render the engineering profile of krishanth7 in the terminal.
#
# Usage:
#   ./scripts/profile.sh              # full profile
#   ./scripts/profile.sh --summary    # compact key/value summary
#   ./scripts/profile.sh --stack      # technology stack only
#   ./scripts/profile.sh --cretes     # the Cretes language card
#   ./scripts/profile.sh --no-color   # disable ANSI colour
#   ./scripts/profile.sh --help
#
set -euo pipefail

readonly NAME="Krishanth"
readonly HANDLE="krishanth7"
readonly ROLE="Full Stack & AI/ML Engineer"
readonly CRETES_URL="https://github.com/Cretes-lang"
readonly GITHUB_URL="https://github.com/krishanth7"

# --- Colour -------------------------------------------------------------------
use_color=1
[[ -t 1 ]] || use_color=0
[[ -n "${NO_COLOR:-}" ]] && use_color=0

setup_colors() {
  if (( use_color )); then
    BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
    BLUE=$'\033[38;5;39m'; PURPLE=$'\033[38;5;141m'
    GREEN=$'\033[38;5;77m'
    CYAN=$'\033[38;5;80m'; GREY=$'\033[38;5;245m'
  else
    BOLD=""; DIM=""; RESET=""
    BLUE=""; PURPLE=""; GREEN=""; CYAN=""; GREY=""
  fi
}

# --- Output helpers -----------------------------------------------------------
rule() {
  local width="${1:-72}"
  printf '%s' "$GREY"
  printf '─%.0s' $(seq 1 "$width")
  printf '%s\n' "$RESET"
}

heading() {
  printf '\n%s%s %s%s\n' "$BOLD" "$BLUE" "$1" "$RESET"
  rule 72
}

field() {
  printf '  %s%-12s%s %s\n' "$GREY" "$1" "$RESET" "$2"
}

bullet() {
  printf '  %s▸%s %s\n' "$GREEN" "$RESET" "$1"
}

# --- Sections -----------------------------------------------------------------
banner() {
  printf '%s%s' "$BOLD" "$BLUE"
  cat <<'ASCII'
 ██╗  ██╗██████╗ ██╗███████╗██╗  ██╗ █████╗ ███╗   ██╗████████╗██╗  ██╗
 ██║ ██╔╝██╔══██╗██║██╔════╝██║  ██║██╔══██╗████╗  ██║╚══██╔══╝██║  ██║
 █████╔╝ ██████╔╝██║███████╗███████║███████║██╔██╗ ██║   ██║   ███████║
 ██╔═██╗ ██╔══██╗██║╚════██║██╔══██║██╔══██║██║╚██╗██║   ██║   ██╔══██║
 ██║  ██╗██║  ██║██║███████║██║  ██║██║  ██║██║ ╚████║   ██║   ██║  ██║
 ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝
ASCII
  printf '%s' "$RESET"
  printf '  %s%s%s  ·  %s@%s%s\n\n' "$PURPLE" "$ROLE" "$RESET" "$DIM" "$HANDLE" "$RESET"
}

summary() {
  printf '%s%s%s\n' "$BOLD" "PROFILE SUMMARY" "$RESET"
  rule 72
  field "engineer"  "$NAME"
  field "role"      "$ROLE"
  field "focus"     "Full Stack · AI/ML · Compilers · Mobile"
  field "languages" "Kotlin, Python, TypeScript, Shell, SQL"
  field "building"  "Cretes — ${CRETES_URL#https://}"
  field "github"    "${GITHUB_URL#https://}"
  field "status"    "${GREEN}open to collaboration${RESET}"
  printf '\n'
}

stack() {
  heading "TECHNOLOGY STACK"
  printf '\n  %s%sBackend & Platform%s\n' "$BOLD" "$CYAN" "$RESET"
  bullet "Kotlin · Ktor · Spring Boot · Coroutines"
  bullet "Python · FastAPI · Django · Celery"
  bullet "PostgreSQL · Redis · Kafka · gRPC"
  bullet "Docker · Kubernetes · GitHub Actions"

  printf '\n  %s%sFrontend & Interface%s\n' "$BOLD" "$CYAN" "$RESET"
  bullet "TypeScript · React · Next.js"
  bullet "HTML5 · Sass/SCSS · CSS Grid · design tokens"
  bullet "Accessibility (WCAG) · responsive systems"

  printf '\n  %s%sAI / Machine Learning%s\n' "$BOLD" "$CYAN" "$RESET"
  bullet "PyTorch · TensorFlow · scikit-learn"
  bullet "Transformers · LLM orchestration · RAG"
  bullet "Vector retrieval · embeddings · evaluation"
  bullet "MLOps · experiment tracking · model serving"

  printf '\n  %s%sMobile & Systems%s\n' "$BOLD" "$CYAN" "$RESET"
  bullet "Kotlin Multiplatform · Jetpack Compose"
  bullet "Compiler front ends · lexers · parsers · type checkers"
  bullet "Bash · POSIX shell · build automation"
  printf '\n'
}

cretes() {
  heading "CRETES — A LANGUAGE FOR AI-NATIVE SOFTWARE"
  printf '%s' "$PURPLE"
  cat <<'ASCII'

   ██████╗██████╗ ███████╗████████╗███████╗███████╗
  ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔════╝
  ██║     ██████╔╝█████╗     ██║   █████╗  ███████╗
  ██║     ██╔══██╗██╔══╝     ██║   ██╔══╝  ╚════██║
  ╚██████╗██║  ██║███████╗   ██║   ███████╗███████║
   ╚═════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚══════╝
ASCII
  printf '%s\n' "$RESET"
  bullet "Readable by default — clear syntax over clever syntax"
  bullet "Types that help — inference first, annotations where they pay"
  bullet "AI as a primitive — models and prompts in the type system"
  bullet "Concurrency built in — structured, cancellable tasks"
  bullet "Interoperable — bridges to the JVM and Python ecosystems"
  printf '\n  %srepository:%s %s%s%s\n\n' "$GREY" "$RESET" "$BLUE" "$CRETES_URL" "$RESET"
}

expertise() {
  heading "PROFICIENCY"
  local -a rows=(
    "Full Stack Engineering:95"
    "Python:94"
    "Kotlin:92"
    "HTML / Sass / CSS:90"
    "AI / ML Engineering:88"
    "Shell / DevOps:85"
  )
  printf '\n'
  local row label value filled empty
  for row in "${rows[@]}"; do
    label="${row%%:*}"
    value="${row##*:}"
    filled=$(( value / 4 ))
    empty=$(( 25 - filled ))
    printf '  %-24s %s' "$label" "$PURPLE"
    printf '█%.0s' $(seq 1 "$filled")
    printf '%s' "$GREY"
    (( empty > 0 )) && printf '░%.0s' $(seq 1 "$empty")
    printf '%s %s%3d%%%s\n' "$RESET" "$DIM" "$value" "$RESET"
  done
  printf '\n'
}

contact() {
  heading "CONTACT"
  field "github"  "$GITHUB_URL"
  field "cretes"  "$CRETES_URL"
  printf '\n'
}

usage() {
  cat <<EOF
profile.sh — render the engineering profile of ${HANDLE}.

Usage:
  ./scripts/profile.sh [OPTION]

Options:
  (none)        Print the full profile
  --summary     Compact key/value summary
  --stack       Technology stack only
  --expertise   Proficiency meters only
  --cretes      The Cretes language card
  --no-color    Disable ANSI colour output
  -h, --help    Show this help
EOF
}

main() {
  local mode="full"
  while (( $# )); do
    case "$1" in
      --summary)   mode="summary" ;;
      --stack)     mode="stack" ;;
      --expertise) mode="expertise" ;;
      --cretes)    mode="cretes" ;;
      --no-color)  use_color=0 ;;
      -h|--help)   usage; return 0 ;;
      *)           printf 'profile.sh: unknown option %s\n\n' "$1" >&2; usage >&2; return 2 ;;
    esac
    shift
  done

  setup_colors

  case "$mode" in
    summary)   summary ;;
    stack)     stack ;;
    expertise) expertise ;;
    cretes)    cretes ;;
    full)
      banner
      summary
      stack
      expertise
      cretes
      contact
      ;;
  esac
}

main "$@"
