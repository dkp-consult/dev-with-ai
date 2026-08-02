#!/usr/bin/env bash
# SessionStart hook — injecte les faits bruts du chantier en cours.
# Ne fait AUCUNE analyse : c'est le rôle de /issue-start.
# Sort silencieusement (exit 0) hors convention. Convention : <type>/<numero>-<slug>

set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-$PWD}" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
command -v gh >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

BRANCH="$(git branch --show-current 2>/dev/null || true)"
[ -n "$BRANCH" ] || exit 0

ISSUE="$(printf '%s' "$BRANCH" | sed -nE 's#^[a-zA-Z]+/([0-9]+)-.*#\1#p')"
if [ -z "$ISSUE" ]; then
  ISSUE="$(gh issue list --label next --assignee @me --state open \
            --limit 1 --json number --jq '.[0].number' 2>/dev/null || true)"
fi
[ -n "$ISSUE" ] && [ "$ISSUE" != "null" ] || exit 0

DATA="$(gh issue view "$ISSUE" --json number,title,state,url,body,comments 2>/dev/null || true)"
[ -n "$DATA" ] || exit 0

{
  echo "## Chantier en cours"
  echo
  printf '%s' "$DATA" | jq -r '
    "**#\(.number) — \(.title)** (\(.state))",
    .url,
    "",
    "### Contrat",
    (if ((.body // "") | length) == 0 then "_Aucun contrat écrit — à cadrer avec /issue-start._" else .body end),
    "",
    "### Dernier checkpoint",
    (if (.comments | length) == 0
     then "_Aucun. Premier passage sur ce chantier._"
     else (.comments[-1] | "_\(.createdAt)_\n\n\(.body)")
     end)
  '

  echo
  echo "### État actuel du worktree"
  echo '```'
  echo "branche : $BRANCH"
  git status --short | head -20
  echo "--- derniers commits ---"
  git log --oneline -5
  echo '```'

  PR="$(gh pr list --head "$BRANCH" --state open --limit 1 \
        --json number,isDraft,url --jq '.[0] | "PR #\(.number) (draft: \(.isDraft)) \(.url)"' 2>/dev/null || true)"
  if [ -n "$PR" ] && [ "$PR" != "null" ]; then
    echo
    echo "### PR liée"
    echo "$PR"
  fi

  echo
  echo "> Contexte injecté automatiquement. Ne recommence pas l'analyse depuis zéro :"
  echo "> les décisions déjà prises sont dans le contrat et le dernier checkpoint."
  echo "> Pour une synthèse complète avec plan de session, lance /issue-start."
} 2>/dev/null

exit 0
