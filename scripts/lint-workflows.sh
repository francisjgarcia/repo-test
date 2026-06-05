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

missing=0

run_actionlint() {
  if command -v actionlint >/dev/null 2>&1; then
    echo "Running actionlint..."
    actionlint .github/workflows/*.yml
  else
    echo "WARNING: actionlint not found."
    echo "  Install with one of these commands:"
    echo "    go install github.com/rhysd/actionlint/cmd/actionlint@v1.7.12"
    echo "    brew install actionlint"
    echo "    scoop install actionlint"
    echo "    choco install actionlint"
    missing=1
  fi
}

run_yamllint() {
  if command -v yamllint >/dev/null 2>&1; then
    echo "Running yamllint..."
    # Prefer repository config if present, otherwise use a safe temporary config
    if [[ -f .yamllint.yml ]]; then
      yamllint -c .yamllint.yml .github/workflows
    else
      echo "No .yamllint.yml found in repo — creating files/.yamllint.yml and using it."
      mkdir -p files
      FALLBACK_FILE="files/.yamllint.yml"
      cat > "$FALLBACK_FILE" <<'YAML'
extends: default

rules:
  line-length:
    max: 180
    level: warning
  indentation:
    spaces: 2
  trailing-spaces:
    level: error
YAML
      yamllint -c "$FALLBACK_FILE" .github/workflows
    fi
  else
    echo "WARNING: yamllint not found."
    echo "  Install with: python3 -m pip install --user yamllint"
    missing=1
  fi
}

run_actionlint
run_yamllint

if [[ "$missing" -ne 0 ]]; then
  echo
  echo "One or more tools are missing. Install them and rerun this script."
  exit 2
fi

echo
printf 'Workflow linting complete.\n'
