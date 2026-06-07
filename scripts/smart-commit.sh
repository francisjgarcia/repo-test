#!/usr/bin/env bash
# =============================================================================
#  smart-commit.sh — Conventional Commits + auto-branch + push + GitHub PR
#
#  Usage   : bash scripts/smart-commit.sh
#  Requires: git, gh (GitHub CLI, authenticated)
#  Install : https://cli.github.com
# =============================================================================
set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
B='\033[0;34m' C='\033[0;36m' W='\033[1m'   N='\033[0m'

header() { printf "\n${C}${W}▶  %s${N}\n" "$*"; }
ok()     { printf "   ${G}✓  %s${N}\n" "$*"; }
warn()   { printf "   ${Y}⚠  %s${N}\n" "$*"; }
die()    { printf "   ${R}✗  %s${N}\n" "$*"; exit 1; }
ask()    { printf "   ${Y}%s${N}  " "$*"; }
info()   { printf "   ${B}%s${N}\n" "$*"; }

# ── Pre-flight checks ─────────────────────────────────────────────────────────
command -v git &>/dev/null      || die "git not found"
command -v gh  &>/dev/null      || die "GitHub CLI not found → https://cli.github.com"
gh auth status &>/dev/null 2>&1 || die "gh not authenticated → run: gh auth login"
[ -d ".git" ]                   || die "Not a git repository. Run from the repo root."

printf "\n${C}${W}════════════════════════════════════════════════${N}\n"
printf "${C}${W}   🚀  Smart Commit Workflow${N}\n"
printf "${C}${W}════════════════════════════════════════════════${N}\n"

# ── Repository state ──────────────────────────────────────────────────────────
header "Repository state"

BASE=$(git branch --show-current)
ok "Current branch (PR base): ${W}$BASE${N}"

UNSTAGED=$(git diff --name-only; git ls-files --others --exclude-standard)
STAGED=$(git diff --cached --name-only)

if [ -z "$UNSTAGED" ] && [ -z "$STAGED" ]; then
    warn "No changes detected. Nothing to commit."; exit 0
fi

if [ -n "$UNSTAGED" ]; then
    echo ""
    git status --short
    echo ""
    ask "Stage all changes? [Y/n]:"; read -r r
    if [[ "${r:-Y}" =~ ^[Yy]$ ]]; then
        git add -A
        ok "git add -A done"
    fi
fi

git diff --cached --quiet && die "Staging area is empty. Run 'git add' first."

echo ""
git diff --cached --stat | sed 's/^/   /'

# ── Commit type ───────────────────────────────────────────────────────────────
header "Commit type"

TYPES=( feat  fix  chore  docs  style  refactor  test  perf  ci  build )
DESCS=(
    "New feature"
    "Bug fix"
    "Maintenance / dependencies"
    "Documentation"
    "Formatting (no logic changes)"
    "Refactoring"
    "Tests"
    "Performance"
    "CI/CD / GitHub Actions"
    "Build system"
)

# Auto-detect based on staged files
FILES=$(git diff --cached --name-only)
AUTO=3  # default: chore
echo "$FILES" | grep -qE '\.(test|spec)\.(ts|tsx|js|jsx|py)$|__tests__/|/test_' && AUTO=7
echo "$FILES" | grep -qE '^\.github/workflows/|^\.circleci/|^Jenkinsfile'        && AUTO=9
echo "$FILES" | grep -qE '(^README|^docs?/|\.md$)'                               && AUTO=4
echo "$FILES" | grep -qE 'package(-lock)?\.json$|yarn\.lock$|requirements\.txt$|go\.(sum|mod)$|Pipfile(\.lock)?$' && AUTO=3

echo ""
for i in "${!TYPES[@]}"; do
    n=$((i+1))
    if [ "$n" -eq "$AUTO" ]; then
        printf "   ${G}${W}%2d)  %-12s—  %s  ← auto${N}\n" "$n" "${TYPES[$i]}" "${DESCS[$i]}"
    else
        printf "   %2d)  %-12s—  %s\n" "$n" "${TYPES[$i]}" "${DESCS[$i]}"
    fi
done

echo ""
ask "Select [1-10] (Enter = $AUTO):"; read -r n
n=${n:-$AUTO}
[[ "$n" =~ ^[1-9]$|^10$ ]] || n=$AUTO
COMMIT_TYPE="${TYPES[$((n-1))]}"
ok "Type: ${W}$COMMIT_TYPE${N}"

# ── Scope ─────────────────────────────────────────────────────────────────────
header "Scope (affected module)"

# Auto-detect most frequent top-level directory in staged changes
AUTO_SCOPE=$(git diff --cached --name-only \
    | awk -F'/' 'NF>1{print $1}' \
    | sort | uniq -c | sort -rn \
    | awk 'NR==1{print $2}')
[[ "$AUTO_SCOPE" =~ ^(src|lib|app|\.)$ ]] && AUTO_SCOPE=""

HINT=""
[ -n "$AUTO_SCOPE" ] && HINT=" — Enter = ${W}$AUTO_SCOPE${N}" || HINT=" — Enter to skip"
ask "Module (e.g. auth, api, ui, db${HINT}):"; read -r SCOPE
[ -z "$SCOPE" ] && SCOPE="${AUTO_SCOPE:-}"
ok "Scope: ${W}${SCOPE:-none}${N}"

# ── Description ───────────────────────────────────────────────────────────────
header "Commit description"
info "Use imperative mood: 'add feature' not 'added feature'. Lowercase, no trailing period."
ask "Description:"; read -r DESC
[ -z "$DESC" ] && die "Description cannot be empty"

# Normalise: lowercase, trim, strip trailing period
DESC=$(printf '%s' "$DESC" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/\.$//')

# Build commit message
if [ -n "$SCOPE" ]; then
    MSG="${COMMIT_TYPE}(${SCOPE}): ${DESC}"
else
    MSG="${COMMIT_TYPE}: ${DESC}"
fi

echo ""
ok "Commit message: ${W}$MSG${N}"

# ── Branch name ───────────────────────────────────────────────────────────────
header "Branch name"

SLUG=$(printf '%s' "$DESC" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9 -]//g' \
    | tr ' ' '-' \
    | sed 's/--*/-/g;s/^-//;s/-$//' \
    | cut -c1-42)

SUGGESTED="${COMMIT_TYPE}/${SLUG}"
ok "Suggested: ${W}$SUGGESTED${N}"
ask "Press Enter to accept or type a different name:"; read -r BRANCH
BRANCH="${BRANCH:-$SUGGESTED}"

# Check for local name collision
if git show-ref --verify --quiet "refs/heads/$BRANCH" 2>/dev/null; then
    warn "Branch '${W}$BRANCH${N}' already exists locally."
    ask "Type a different name:"; read -r BRANCH
    [ -z "$BRANCH" ] && die "Branch name is required"
fi

# ── Git operations ────────────────────────────────────────────────────────────
header "Running git"

info "Creating branch ${W}$BRANCH${N}..."
git checkout -b "$BRANCH"

info "Committing: ${W}$MSG${N}"
git commit -m "$MSG"

info "Pushing → origin/${W}$BRANCH${N}"
git push -u origin "$BRANCH"
ok "Push complete ✓"

# ── Pull Request ──────────────────────────────────────────────────────────────
header "Pull Request"

ask "Create PR now? [Y/n]:"; read -r cpr
if [[ "${cpr:-Y}" =~ ^[Yy]$ ]]; then

    if [ -f ".github/PULL_REQUEST_TEMPLATE.md" ]; then
        ok "Using template: .github/PULL_REQUEST_TEMPLATE.md"
        BODY=$(cat ".github/PULL_REQUEST_TEMPLATE.md")
    else
        warn ".github/PULL_REQUEST_TEMPLATE.md not found — using basic body"
        CHANGED_FILES=$(git diff --name-only "origin/$BASE...$BRANCH" 2>/dev/null \
            || git diff --cached --name-only)
        BODY="## Description

${MSG}

## Type of change

- [x] \`${COMMIT_TYPE}\`

## Modified files

\`\`\`
${CHANGED_FILES}
\`\`\`"
    fi

    info "Opening PR on GitHub..."
    PR_URL=$(gh pr create \
        --title    "$MSG" \
        --body     "$BODY" \
        --base     "$BASE" \
        --assignee "@me")

    # ── Final summary ─────────────────────────────────────────────────────────
    printf "\n${G}${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}\n"
    printf "${G}${W}   ✅  Workflow completed successfully${N}\n"
    printf "${G}${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}\n"
    printf "\n   📝  Commit : ${W}%s${N}\n" "$MSG"
    printf "   🌿  Branch : ${W}%s${N}  →  ${W}%s${N}\n" "$BRANCH" "$BASE"
    printf "   🔗  PR     : ${W}%s${N}\n" "$PR_URL"
    printf "\n${G}${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}\n\n"

else
    echo ""
    warn "To create the PR manually:"
    printf "   gh pr create --title \"%s\" --base \"%s\" --assignee \"@me\"\n" "$MSG" "$BASE"
    echo ""
fi
