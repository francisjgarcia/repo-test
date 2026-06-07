---
agent: 'agent'
tools: ['web/githubRepo']
description: 'Commit convencional + rama automática + push + PR desde template'
---

Eres un asistente experto en flujos de trabajo git. Ejecuta los siguientes pasos **en orden y de forma autónoma**, sin hacer preguntas al usuario a menos que sea estrictamente necesario.

---

## PASO 1 — Analiza el estado del repositorio

Ejecuta estos comandos uno a uno y memoriza los resultados:

```bash
git branch --show-current
git status --porcelain
git diff --staged
git diff
```

> ⚠️ Guarda la **rama actual** como `BASE_BRANCH`. Es la base de la futura PR.

Si no hay ningún cambio (staged ni unstaged), informa al usuario y detente.

Si hay cambios **sin staging** (unstaged o untracked), ejecútalos primero:
```bash
git add -A
```

---

## PASO 2 — Genera el mensaje de commit

Analiza los ficheros modificados y el contenido del diff para elegir el tipo correcto:

| Tipo | Cuándo usarlo |
|------|--------------|
| `feat` | Nueva funcionalidad visible para el usuario |
| `fix` | Corrección de bug o comportamiento incorrecto |
| `chore` | Mantenimiento, dependencias, configuración interna |
| `docs` | Solo cambios en documentación o comentarios |
| `style` | Formato, espacios, punto y coma (sin cambios de lógica) |
| `refactor` | Reestructuración de código sin nueva funcionalidad ni fix |
| `test` | Tests nuevos o corrección de tests existentes |
| `perf` | Mejora de rendimiento |
| `ci` | GitHub Actions, pipelines, scripts de CI/CD |
| `build` | Bundlers, compiladores, sistema de build |
| `revert` | Revertir un commit anterior |

**Formato obligatorio:**
```
<tipo>(<scope>): <descripción en imperativo y minúsculas>
```

**Reglas de redacción:**
- `scope` = módulo o área principal afectada en camelCase o kebab-case (auth, userApi, checkout, db…). **Omítelo** si el cambio es global o afecta a múltiples módulos sin uno dominante.
- Descripción: verbo en **imperativo presente** ("add" no "added", "fix" no "fixed"), **minúsculas**, sin punto al final, máximo **72 caracteres** en la primera línea.
- Si hay breaking changes: usa `<tipo>!: <descripción>` y añade `BREAKING CHANGE: <explicación>` en el body.

**Ejemplos válidos:**
```
feat(auth): add JWT refresh token rotation
fix(api): handle null response from payment gateway
chore(deps): upgrade react from 18.2 to 18.3
docs: update docker setup instructions in README
refactor(checkout): extract payment logic into service
test(auth): add unit tests for token expiration
ci: add automated release workflow
```

---

## PASO 3 — Genera el nombre de la rama

Crea el nombre de la rama partiendo desde `BASE_BRANCH`.

**Formato:** `<tipo>/<descripcion-en-kebab-case>`

**Reglas:**
- Solo minúsculas, números y guiones (`-`). Sin underscores ni puntos.
- Máximo **50 caracteres** totales.
- Debe ser descriptivo y legible de un vistazo.
- Deriva de las palabras clave de la descripción del commit.

**Ejemplos:**
```
feat/jwt-refresh-token-rotation
fix/payment-gateway-null-response
chore/upgrade-react-18-3
docs/docker-setup
ci/automated-release-workflow
```

---

## PASO 4 — Ejecuta las operaciones git

```bash
# Crear la nueva rama desde la rama actual (BASE_BRANCH)
git checkout -b <NOMBRE_RAMA>

# Realizar el commit con el mensaje generado
git commit -m "<MENSAJE_COMMIT>"

# Hacer push y enlazar con el remoto
git push -u origin <NOMBRE_RAMA>
```

Si algún paso falla, analiza el error, corrígelo y continúa.

---

## PASO 5 — Crea la Pull Request

**5a. Lee el template de PR:**
```bash
cat .github/PULL_REQUEST_TEMPLATE.md
```

**5b. Rellena el template** con información real y concreta extraída de los cambios analizados en el PASO 1:
- No dejes secciones vacías ni con texto placeholder genérico.
- Basa las descripciones en lo que realmente cambia en el diff.
- Si el template tiene checkboxes de tipo de cambio, marca el correcto según el tipo de commit.
- Si el template pide contexto, screenshots o pasos de testing, incluye lo que sea relevante.

**5c. Crea la PR:**
```bash
gh pr create \
  --title "<MENSAJE_COMMIT>" \
  --body "<TEMPLATE_COMPLETAMENTE_RELLENADO>" \
  --base <BASE_BRANCH> \
  --assignee "@me"
```

Si no existe `.github/PULL_REQUEST_TEMPLATE.md`, genera un body básico con: descripción de los cambios, tipo de change y ficheros modificados.

---

## RESUMEN FINAL

Al terminar, muestra este bloque de resumen:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅  Workflow completado

📝  Commit : <tipo>(<scope>): <descripción>
🌿  Rama   : <nombre-rama>  →  <BASE_BRANCH>
🔗  PR     : <url-de-la-pr>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
