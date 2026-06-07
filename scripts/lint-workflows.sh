#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Use repository root (script is in scripts/)
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

if [[ ! -d .github/workflows ]]; then
  echo "No .github/workflows directory found."
  exit 1
fi

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

status() {
  local color="$1"; shift
  printf "%b%b%b\n" "$color" "$*" "$RESET"
}

section() {
  local title="$1"
  printf "\n%b%s%b\n" "$CYAN" "$(printf '%*s' 60 '' | tr ' ' '-')" "$RESET"
  status "$BOLD$BLUE" "== $title =="
  printf "%b%s%b\n\n" "$CYAN" "$(printf '%*s' 60 '' | tr ' ' '-')" "$RESET"
}

maybe_add_go_bin_to_path() {
  if command -v actionlint >/dev/null 2>&1; then
    return
  fi

  if ! command -v go >/dev/null 2>&1; then
    return
  fi

  local go_bin
  go_bin="$(go env GOBIN 2>/dev/null || true)"
  if [[ -z "$go_bin" ]]; then
    go_bin="$(go env GOPATH 2>/dev/null || true)"
    if [[ -n "$go_bin" ]]; then
      go_bin="$go_bin/bin"
    fi
  fi

  if [[ -n "$go_bin" && -d "$go_bin" ]]; then
    case ":$PATH:" in
      *":$go_bin:"*) ;;
      *) PATH="$PATH:$go_bin"; export PATH ;;
    esac
  fi
}

missing=0

run_actionlint() {
  section "ACTIONLINT"
  maybe_add_go_bin_to_path

  if command -v actionlint >/dev/null 2>&1; then
    status "$BOLD$GREEN" "Running actionlint against .github/workflows and actions"
    local -a actionlint_targets=()
    shopt -s globstar nullglob
    actionlint_targets+=( .github/workflows/*.{yml,yaml} )
    if [[ -d actions ]]; then
      actionlint_targets+=( actions/**/*.{yml,yaml} )
    fi
    shopt -u globstar nullglob

    if [[ ${#actionlint_targets[@]} -eq 0 ]]; then
      status "$YELLOW" "No actionlint targets found in .github/workflows or actions."
    else
      actionlint "${actionlint_targets[@]}"
      status "$GREEN" "actionlint passed successfully."
    fi
  else
    status "$BOLD$YELLOW" "WARNING: actionlint not found."
    echo "  Install with one of these commands:"
    echo "    go install github.com/rhysd/actionlint/cmd/actionlint@latest"
    echo "    brew install actionlint"
    echo "    scoop install actionlint"
    echo "    choco install actionlint"
    echo
    status "$YELLOW" "  If you installed via go, add your Go bin path to PATH:"
    echo "    export PATH=\"\$PATH:\\$HOME/go/bin\""
    echo "    export PATH=\"\$PATH:\$(go env GOPATH)/bin\""
    missing=1
  fi
}

run_yamllint() {
  section "YAMLLINT"

  if command -v yamllint >/dev/null 2>&1; then
    status "$BOLD$GREEN" "Running yamllint against .github/workflows and actions"
    YAML_CONFIG="$SCRIPT_DIR/files/.yamllint.yml"
    local -a yamllint_targets=( "$ROOT/.github/workflows" )
    if [[ -d "$ROOT/actions" ]]; then
      yamllint_targets+=( "$ROOT/actions" )
    fi

    if [[ ! -f "$YAML_CONFIG" ]]; then
      status "$YELLOW" "No yamllint config found at $YAML_CONFIG — creating it."
      mkdir -p "$SCRIPT_DIR/files"
      cat > "$YAML_CONFIG" <<'EOF'
extends: default
EOF
      status "$GREEN" "Created fallback config at $YAML_CONFIG"
    fi

    yamllint -c "$YAML_CONFIG" "${yamllint_targets[@]}"
    status "$GREEN" "yamllint completed successfully."
  else
    status "$BOLD$YELLOW" "WARNING: yamllint not found."
    echo "  Install with: python3 -m pip install --user yamllint"
    missing=1
  fi
}

run_actionlint
run_yamllint

if [[ "$missing" -ne 0 ]]; then
  echo
  status "$BOLD$RED" "One or more tools are missing. Install them and rerun this script."
  exit 2
fi

section "RESULT"
status "$BOLD$GREEN" "Workflow linting complete."
