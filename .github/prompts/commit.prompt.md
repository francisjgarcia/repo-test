---
agent: 'agent'
tools: ['web/githubRepo']
description: 'Conventional commit + auto-branch + push + PR from template'
---

You are an expert git workflow assistant. Execute the following steps **in order and autonomously**, without asking the user questions unless strictly necessary.

---

## STEP 1 — Read the repository state

Run these commands one by one and memorize the results:

```bash
git branch --show-current
git status --porcelain
git diff --staged
git diff
```

> ⚠️ Save the **current branch** as `BASE_BRANCH`. This will be the base of the PR.

If there are no changes (neither staged nor unstaged), inform the user and stop.

If there are **unstaged changes** (unstaged or untracked files), stage them first:
```bash
git add -A
```

---

## STEP 2 — Generate the commit message

Analyze the modified files and the diff content to pick the correct type:

| Type | When to use |
|------|-------------|
| `feat` | New functionality visible to the user |
| `fix` | Bug fix or incorrect behaviour |
| `chore` | Maintenance, dependencies, internal config |
| `docs` | Documentation or comment changes only |
| `style` | Formatting, whitespace, semicolons (no logic changes) |
| `refactor` | Code restructuring without new feature or bug fix |
| `test` | New or updated tests |
| `perf` | Performance improvement |
| `ci` | GitHub Actions, pipelines, CI/CD scripts |
| `build` | Bundlers, compilers, build system |
| `revert` | Revert a previous commit |

**Required format:**
```
<type>(<scope>): <description in imperative mood and lowercase>
```

**Writing rules:**
- `scope` = main module or area affected, in camelCase or kebab-case (auth, userApi, checkout, db…). **Omit it** if the change is global or spans multiple modules without a dominant one.
- Description: **present imperative** verb ("add" not "added", "fix" not "fixed"), **lowercase**, no trailing period, max **72 characters** on the first line.
- For breaking changes: use `<type>!: <description>` and add `BREAKING CHANGE: <explanation>` in the commit body.

**Valid examples:**
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

## STEP 3 — Generate the branch name

Create the branch name starting from `BASE_BRANCH`.

**Format:** `<type>/<description-in-kebab-case>`

**Rules:**
- Lowercase letters, numbers, and hyphens (`-`) only. No underscores or dots.
- Max **50 characters** total.
- Must be descriptive and readable at a glance.
- Derived from the key words of the commit description.

**Examples:**
```
feat/jwt-refresh-token-rotation
fix/payment-gateway-null-response
chore/upgrade-react-18-3
docs/docker-setup
ci/automated-release-workflow
```

---

## STEP 4 — Execute the git operations

```bash
# Create the new branch from the current branch (BASE_BRANCH)
git checkout -b <BRANCH_NAME>

# Commit with the generated message
git commit -m "<COMMIT_MESSAGE>"

# Push and link to remote
git push -u origin <BRANCH_NAME>
```

If any step fails, analyse the error, fix it, and continue.

---

## STEP 5 — Create the Pull Request

**5a. Read the PR template:**
```bash
cat .github/PULL_REQUEST_TEMPLATE.md
```

**5b. Fill in the template** with real, concrete information extracted from the changes analysed in STEP 1:
- Do not leave any section empty or with generic placeholder text.
- Base descriptions on what actually changes in the diff.
- If the template has change-type checkboxes, tick the correct one based on the commit type.
- If the template asks for context, screenshots, or testing steps, include what is relevant.

**5c. Create the PR:**
```bash
gh pr create \
  --title "<COMMIT_MESSAGE>" \
  --body "<FULLY_FILLED_TEMPLATE>" \
  --base <BASE_BRANCH> \
  --assignee "@me"
```

If `.github/PULL_REQUEST_TEMPLATE.md` does not exist, generate a basic body with: change description, commit type, and list of modified files.

---

## FINAL SUMMARY

When done, display this summary block:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅  Workflow completed

📝  Commit : <type>(<scope>): <description>
🌿  Branch : <branch-name>  →  <BASE_BRANCH>
🔗  PR     : <pull-request-url>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
