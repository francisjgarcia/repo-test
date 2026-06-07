#!/usr/bin/env bash
# =============================================================================
#  smart-commit.sh — Conventional Commits + auto-branch + push + GitHub PR
#
#  Uso    : bash scripts/smart-commit.sh
#  Requiere: git, gh (GitHub CLI autenticado)
#  Instala gh: https://cli.github.com
# =============================================================================
set -euo pipefail

# ── Colores ───────────────────────────────────────────────────────────────────
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
B='\033[0;34m' C='\033[0;36m' W='\033[1m'   N='\033[0m'

header() { printf "\n${C}${W}▶  %s${N}\n" "$*"; }
ok()     { printf "   ${G}✓  %s${N}\n" "$*"; }
warn()   { printf "   ${Y}⚠  %s${N}\n" "$*"; }
die()    { printf "   ${R}✗  %s${N}\n" "$*"; exit 1; }
ask()    { printf "   ${Y}%s${N}  " "$*"; }
info()   { printf "   ${B}%s${N}\n" "$*"; }

# ── Pre-flight checks ─────────────────────────────────────────────────────────
command -v git &>/dev/null      || die "git no encontrado"
command -v gh  &>/dev/null      || die "GitHub CLI no encontrado → https://cli.github.com"
gh auth status &>/dev/null 2>&1 || die "gh no autenticado → ejecuta: gh auth login"
[ -d ".git" ]                   || die "No es un repositorio git. Ejecuta desde la raíz del repo."

printf "\n${C}${W}════════════════════════════════════════════════${N}\n"
printf "${C}${W}   🚀  Smart Commit Workflow${N}\n"
printf "${C}${W}════════════════════════════════════════════════${N}\n"

# ── Estado del repositorio ────────────────────────────────────────────────────
header "Estado del repositorio"

BASE=$(git branch --show-current)
ok "Rama actual (base de la PR): ${W}$BASE${N}"

UNSTAGED=$(git diff --name-only; git ls-files --others --exclude-standard)
STAGED=$(git diff --cached --name-only)

if [ -z "$UNSTAGED" ] && [ -z "$STAGED" ]; then
    warn "Sin cambios detectados. Nada que commitear."
    exit 0
fi

if [ -n "$UNSTAGED" ]; then
    echo ""
    git status --short
    echo ""
    ask "¿Añadir todos los cambios al staging? [S/n]:"; read -r r
    if [[ "${r:-S}" =~ ^[Ss]$ ]]; then
        git add -A
        ok "git add -A completado"
    fi
fi

git diff --cached --quiet && die "Staging vacío. Añade cambios con 'git add' primero."

echo ""
git diff --cached --stat | sed 's/^/   /'

# ── Tipo de commit ────────────────────────────────────────────────────────────
header "Tipo de commit"

TYPES=( feat  fix  chore  docs  style  refactor  test  perf  ci  build )
DESCS=(
    "Nueva funcionalidad"
    "Corrección de bug"
    "Mantenimiento / dependencias"
    "Documentación"
    "Formato (sin cambios de lógica)"
    "Refactorización"
    "Tests"
    "Rendimiento"
    "CI/CD / GitHub Actions"
    "Sistema de build"
)

# Auto-detección basada en ficheros modificados
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
ask "Selecciona [1-10] (Enter = $AUTO):"; read -r n
n=${n:-$AUTO}
[[ "$n" =~ ^[1-9]$|^10$ ]] || n=$AUTO
COMMIT_TYPE="${TYPES[$((n-1))]}"
ok "Tipo: ${W}$COMMIT_TYPE${N}"

# ── Scope ─────────────────────────────────────────────────────────────────────
header "Scope (módulo afectado)"

# Auto-detectar directorio más frecuente en los cambios
AUTO_SCOPE=$(git diff --cached --name-only \
    | awk -F'/' 'NF>1{print $1}' \
    | sort | uniq -c | sort -rn \
    | awk 'NR==1{print $2}')
# Ignorar directorios genéricos
[[ "$AUTO_SCOPE" =~ ^(src|lib|app|\.)$ ]] && AUTO_SCOPE=""

HINT=""
[ -n "$AUTO_SCOPE" ] && HINT=" — Enter = ${W}$AUTO_SCOPE${N}" || HINT=" — Enter para omitir"
ask "Módulo (ej: auth, api, ui, db${HINT}):"; read -r SCOPE
[ -z "$SCOPE" ] && SCOPE="${AUTO_SCOPE:-}"
ok "Scope: ${W}${SCOPE:-ninguno}${N}"

# ── Descripción ───────────────────────────────────────────────────────────────
header "Descripción del commit"
info "Usa el imperativo: 'add feature' no 'added feature'. Minúsculas, sin punto al final."
ask "Descripción:"; read -r DESC
[ -z "$DESC" ] && die "La descripción no puede estar vacía"

# Normalizar: minúsculas, trim, sin punto final
DESC=$(printf '%s' "$DESC" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/\.$//')

# Construir mensaje de commit
if [ -n "$SCOPE" ]; then
    MSG="${COMMIT_TYPE}(${SCOPE}): ${DESC}"
else
    MSG="${COMMIT_TYPE}: ${DESC}"
fi

echo ""
ok "Mensaje generado: ${W}$MSG${N}"

# ── Nombre de la rama ─────────────────────────────────────────────────────────
header "Nombre de la rama"

# Generar slug desde la descripción
SLUG=$(printf '%s' "$DESC" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[áàäâ]/a/g;s/[éèëê]/e/g;s/[íìïî]/i/g;s/[óòöô]/o/g;s/[úùüû]/u/g;s/[ñ]/n/g' \
    | sed 's/[^a-z0-9 -]//g' \
    | tr ' ' '-' \
    | sed 's/--*/-/g;s/^-//;s/-$//' \
    | cut -c1-42)

SUGGESTED="${COMMIT_TYPE}/${SLUG}"
ok "Sugerida: ${W}$SUGGESTED${N}"
ask "Enter para aceptar, o escribe otro nombre:"; read -r BRANCH
BRANCH="${BRANCH:-$SUGGESTED}"

# Comprobar que la rama no existe ya
if git show-ref --verify --quiet "refs/heads/$BRANCH" 2>/dev/null; then
    warn "La rama '${W}$BRANCH${N}' ya existe localmente."
    ask "Escribe un nombre diferente:"; read -r BRANCH
    [ -z "$BRANCH" ] && die "Nombre de rama requerido"
fi

# ── Operaciones git ───────────────────────────────────────────────────────────
header "Ejecutando git"

info "Creando rama ${W}$BRANCH${N}..."
git checkout -b "$BRANCH"

info "Commiteando: ${W}$MSG${N}"
git commit -m "$MSG"

info "Push → origin/${W}$BRANCH${N}"
git push -u origin "$BRANCH"
ok "Push completado ✓"

# ── Pull Request ──────────────────────────────────────────────────────────────
header "Pull Request"

ask "¿Crear PR automáticamente? [S/n]:"; read -r cpr
if [[ "${cpr:-S}" =~ ^[Ss]$ ]]; then

    # Leer template si existe
    if [ -f ".github/PULL_REQUEST_TEMPLATE.md" ]; then
        ok "Template encontrado: .github/PULL_REQUEST_TEMPLATE.md"
        BODY=$(cat ".github/PULL_REQUEST_TEMPLATE.md")
    else
        warn "No se encontró .github/PULL_REQUEST_TEMPLATE.md — usando body básico"
        CHANGED_FILES=$(git diff --name-only "origin/$BASE...$BRANCH" 2>/dev/null \
            || git diff --cached --name-only)
        BODY="## Descripción

${MSG}

## Tipo de cambio

- [x] \`${COMMIT_TYPE}\`

## Ficheros modificados

\`\`\`
${CHANGED_FILES}
\`\`\`"
    fi

    info "Creando PR en GitHub..."
    PR_URL=$(gh pr create \
        --title   "$MSG" \
        --body    "$BODY" \
        --base    "$BASE" \
        --assignee "@me")

    # ── Resumen final ─────────────────────────────────────────────────────────
    printf "\n${G}${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}\n"
    printf "${G}${W}   ✅  Workflow completado con éxito${N}\n"
    printf "${G}${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}\n"
    printf "\n   📝  Commit : ${W}%s${N}\n" "$MSG"
    printf "   🌿  Rama   : ${W}%s${N}  →  ${W}%s${N}\n" "$BRANCH" "$BASE"
    printf "   🔗  PR     : ${W}%s${N}\n" "$PR_URL"
    printf "\n${G}${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}\n\n"

else
    echo ""
    warn "Para crear la PR manualmente:"
    printf "   gh pr create --title \"%s\" --base \"%s\" --assignee \"@me\"\n" "$MSG" "$BASE"
    echo ""
fi
