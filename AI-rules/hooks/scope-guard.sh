#!/usr/bin/env bash
#
# scope-guard.sh — hook PreToolUse pour Claude Code.
#
# Frontière d'écriture par agent. Un seul script, déclaré UNE SEULE FOIS dans
# ~/.claude/settings.json, qui dispatche sur le champ `agent_type` que Claude
# Code place dans l'entrée du hook.
#
# Pourquoi en global plutôt que dans le frontmatter de chaque agent :
# un agent créé plus tard sans déclaration tombe dans le cas par défaut, donc
# PROTÉGÉ. Le frontmatter fait l'inverse — l'oubli ouvre. Un harnais dont
# l'oubli ferme est le seul qui tienne dans le temps.
#
#   agent_type   mode            peut écrire
#   ----------   -------------   ------------------------------------------
#   analyst      docs-only       ai/** sauf ai/reports/** · *.md
#   dev          code-only       code source · ai/reports/dev/**
#   tester       tests-only      tests, configs de test, package.json
#                                · ai/reports/tester/**
#   reviewer     reports-only    ai/reports/reviewer/** seulement
#   (autre)      main            tout sauf les tests existants
#
# Le mode `main` reproduit exactement protect-tests.sh, qu'il remplace :
# sessions normales, commandes lancées en direct, sous-agents intégrés.
#
# Portée : Edit, Write, NotebookEdit (chemin exact) et Bash (heuristique).
# Ce n'est PAS une frontière de sécurité — une commande suffisamment tordue
# passe, un script indirect aussi. C'est un garde-fou contre la dérive
# ordinaire, celle où un modèle sous pression élargit son périmètre pour
# terminer sa mission.
#
# Levée du verrou de test — humaine, jamais par l'agent :
#   touch .claude/.allow-test-edits     # puis rm quand c'est fini
#   ou : export ALLOW_TEST_EDITS=1 avant de lancer Claude Code
# Le verrou ne lève QUE la protection des tests en mode `main`. Il ne
# desserre aucune frontière d'agent : celles-là ne se lèvent pas.

set -uo pipefail

INPUT=$(cat)

# jq est requis. On ne bloque pas s'il manque — ce hook n'est pas une sécurité —
# mais on le signale bruyamment : un hook silencieux passerait pour un succès.
if ! command -v jq >/dev/null 2>&1; then
  echo "scope-guard.sh : jq introuvable, hook inactif. -> brew install jq" >&2
  exit 0
fi

TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name  // empty')
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
CMD=$(printf  '%s' "$INPUT" | jq -r '.tool_input.command   // empty')
AGENT=$(printf '%s' "$INPUT" | jq -r '.agent_type // empty')

FLAG=".claude/.allow-test-edits"

# --- Motifs de chemin ---------------------------------------------------
TEST_RE='(\.test\.|\.spec\.|/__tests?__/|/tests?/|/e2e/|_test\.(py|go|rb)|(^|/)test_[A-Za-z0-9_]+\.py)'
TESTCFG_RE='(vitest|vite|playwright|jest|cypress|karma)\.config\.|vitest\.setup\.|playwright\.setup\.|(^|/)setupTests\.'
REPORTS_RE='(^|/)ai/reports/'
AI_RE='(^|/)ai/'
MD_RE='\.(md|mdx)$'
PKG_RE='(^|/)(package\.json|pnpm-lock\.yaml|package-lock\.json|yarn\.lock|pnpm-workspace\.yaml)$'
# Ce qui n'est un fichier de spec QUE pour le tester : *.spec.ts est un test,
# mais ai/specs/*.spec.md est un contrat. On les sépare explicitement.
SPECDOC_RE='(^|/)ai/specs/'

# --- Paquets que le tester peut installer sans validation ---------------
# Parade mécanique au slopsquatting : un nom halluciné n'est pas dans la liste.
ALLOWED_PKGS='^(vitest|@vitest/[a-z-]+|jsdom|happy-dom|@testing-library/(react|dom|user-event|jest-dom)|playwright|@playwright/test|msw|supertest|c8|@vitest/coverage-v8)$'

# --- Sortie -------------------------------------------------------------
refuse() {
  printf 'BLOQUÉ — %s\n\n' "$1" >&2
  shift
  printf '%s\n' "$@" >&2
  exit 2
}

refuse_scope() {
  local what="$1" allowed="$2"
  cat >&2 <<EOF
BLOQUÉ — hors du périmètre de l'agent « $AGENT ».

  $what

Cet agent peut écrire : $allowed

Tu ne contournes pas cette frontière et tu ne la discutes pas.
Si ton travail exige d'écrire ailleurs, c'est le signe que la mission
déborde de ton rôle : ARRÊTE-TOI et rends ton rapport en l'expliquant.
Un rapport « bloqué » est un résultat valide ; élargir ton périmètre
soi-même n'en est pas un.
EOF
  exit 2
}

refuse_test() {
  cat >&2 <<EOF
BLOQUÉ — $1

Un test ne se modifie pas pour le faire passer. Trois cas :

1. Le code est faux    -> corrige le code, pas le test.
2. Le test est faux    -> ARRÊTE-TOI. Explique précisément en quoi
                          l'assertion est incorrecte. Je tranche.
3. La spec a changé    -> ARRÊTE-TOI. On met à jour la spec d'abord,
                          le test ensuite, et je valide le nouveau test.

Ajouter un nouveau fichier de test reste autorisé.

Ne contourne pas ce hook : ne supprime pas le fichier pour le recréer,
ne passe pas par une autre commande, ne lève pas le verrou toi-même.
Demande-moi de le lever, c'est une décision humaine.
EOF
  exit 2
}

# `--` avant le motif : sans lui, un motif commençant par `-` (« --force »)
# est lu par grep comme une option et le hook meurt en usage error.
matches() { printf '%s' "$1" | grep -Eq -- "$2"; }

# --- Le verrou ne se lève jamais depuis un outil -------------------------
case "$CMD" in
  *allow-test-edits*)
    refuse_test "tentative de lever le verrou de protection des tests.

  $CMD"
    ;;
esac

# --- Mode ---------------------------------------------------------------
case "$AGENT" in
  analyst)  MODE=docs-only    ;;
  dev)      MODE=code-only    ;;
  tester)   MODE=tests-only   ;;
  reviewer) MODE=reports-only ;;
  *)        MODE=main         ;;
esac

# Seuls les outils qui écrivent nous concernent. Lire n'est jamais bloqué.
case "$TOOL" in
  Edit|Write|MultiEdit|NotebookEdit) KIND=path ;;
  Bash|PowerShell)                   KIND=cmd  ;;
  *) exit 0 ;;
esac
[ "$KIND" = path ] && [ -z "$FILE" ] && exit 0
[ "$KIND" = cmd  ] && [ -z "$CMD"  ] && exit 0

# =========================================================================
#  PLANCHER PUSH — vaut pour TOUS les modes, agent comme session directe.
#
#  Le `deny` de settings.json raisonne sur un préfixe : « git push --force »
#  n'attrape pas « git push origin main --force ». Ici on lit la commande
#  entière. Et surtout, un hook s'exécute quel que soit le mode de permission,
#  y compris sous --dangerously-skip-permissions : c'est ce qui reste quand
#  un run autonome (AIDD async, poll local) a désactivé les permissions.
#
#  --force-with-lease n'est volontairement pas visé : il refuse d'écraser
#  un commit qu'on n'a pas vu.
# =========================================================================
# On ne vise qu'une INVOCATION : `git push` en début de ligne ou après un
# séparateur de commandes. Une commande qui *cite* git push — un grep sur la
# doc, un script de test — n'est pas un push. Même raisonnement que pour les
# cibles d'écriture plus bas : on lit ce qui s'exécute, pas ce qui se mentionne.
GIT_PUSH_RE='(^|[;&|(][[:space:]]*)git[[:space:]]+push([[:space:]]|$)'

if [ "$KIND" = cmd ] && matches "$CMD" "$GIT_PUSH_RE"; then
  PUSH_LINE=$(printf '%s' "$CMD" | grep -E -- "$GIT_PUSH_RE" | head -5)
  if matches "$PUSH_LINE" '--force([[:space:]]|$)' || matches "$PUSH_LINE" '[[:space:]]-f([[:space:]]|$)'; then
    refuse "push forcé : $CMD" \
      "  Réécrire l'historique d'une branche déjà poussée ne s'annule pas," \
      "  et ce que les autres ont tiré entre-temps ne se récupère pas." \
      "" \
      "  Si l'intention est de corriger la dernière poussée sans écraser le" \
      "  travail d'un autre : git push --force-with-lease, que ce hook laisse" \
      "  passer. Sinon, arrête-toi et explique ce que tu cherches à faire."
  fi
  if matches "$PUSH_LINE" 'git[[:space:]]+push[^;|&]*[[:space:]](main|master)([[:space:]]|$)'; then
    refuse "push direct sur une branche d'intégration : $CMD" \
      "  main se remplit par pull request, jamais en direct." \
      "" \
      "  Pousse ta branche de travail et ouvre la PR."
  fi
fi

# =========================================================================
#  MODE main — comportement historique de protect-tests.sh
# =========================================================================
if [ "$MODE" = main ]; then
  if [ -n "${ALLOW_TEST_EDITS:-}" ] || [ -f "$FLAG" ]; then exit 0; fi

  if [ "$KIND" = path ]; then
    matches "$FILE" "$TEST_RE" || exit 0
    matches "$FILE" "$SPECDOC_RE" && exit 0      # ai/specs/*.spec.md n'est pas un test
    [ -f "$FILE" ] || exit 0                      # création : autorisée
    refuse_test "modification d'un test existant ($TOOL) :

  $FILE"
  fi

  matches "$CMD" "$TEST_RE" || exit 0

  # On raisonne sur la CIBLE d'une écriture, jamais sur le texte complet de la
  # commande. Un document qui *parle* de tests n'écrit pas dans un test : le
  # chevron fermant de <module> passait pour une redirection.
  # Un `>` ne compte que précédé d'un espace ou d'un début de ligne.
  write_targets() {
    printf '%s' "$CMD" \
      | grep -oE '(^|[[:space:]])>>?[[:space:]]*[^[:space:];|&<>]+' \
      | grep -oE '[^[:space:]<>]+$'
    printf '%s' "$CMD" \
      | grep -oE '(^|[;&|][[:space:]]*|[[:space:]])(rm|mv|cp|truncate|dd|tee)[[:space:]]+[^;|&]*' \
      | tr '[:space:]' '\n' \
      | grep -vE '^(rm|mv|cp|truncate|dd|tee|-.*)$'
  }

  # Chemins cités n'importe où : pour les écritures qui ne passent pas par une
  # redirection shell (heredoc python, node -e), où la cible est dans le code.
  cited_paths() {
    printf '%s' "$CMD" | grep -oE "[^[:space:]'\"\`(),]+" | grep -E "$TEST_RE"
  }

  # Un test qui n'existe pas encore n'est pas protégé : en créer reste autorisé,
  # exactement comme pour Write et Edit plus haut.
  existing_test() {
    case "$1" in /dev/null|/tmp/*|/private/tmp/*) return 1 ;; esac
    matches "$1" "$TEST_RE" || return 1
    [ -f "$1" ] || return 1
    return 0
  }

  refuse_first_existing() {
    local reason="$1"; shift
    local p
    for p in "$@"; do
      if existing_test "$p"; then
        refuse_test "$reason :

  $p"
      fi
    done
  }

  # 1. Redirection, déplacement, suppression, troncature.
  refuse_first_existing "écriture vers un fichier de test existant" $(write_targets)

  # 2. Édition en place déclarée : sed -i, perl -i.
  if matches "$CMD" '(^|[[:space:]])(sed|perl|ruby|python3?)[[:space:]]+(-[^[:space:]]+[[:space:]]+)*-i'; then
    refuse_first_existing "édition en place d'un fichier de test existant" $(cited_paths)
  fi

  # 3. Interpréteur portant du code en ligne (heredoc, -e, -c). C'est par là
  #    qu'un script réécrivait un test sans jamais employer -i.
  if matches "$CMD" '(^|[[:space:]])(python3?|node|perl|ruby|deno|bun)([[:space:]]+-[^[:space:]]+)*[[:space:]]+(-e|-c|-)([[:space:]]|$)' \
     || matches "$CMD" '(^|[[:space:]])(python3?|node|perl|ruby|deno|bun)[[:space:]]+[^;|&]*<<'; then
    refuse_first_existing "réécriture d'un test existant par un interpréteur" $(cited_paths)
  fi

  # 4. Restauration git portant sur un test existant.
  if matches "$CMD" 'git[[:space:]]+(checkout|restore|clean)'; then
    refuse_first_existing "restauration git d'un fichier de test existant" $(cited_paths)
  fi

  exit 0
fi

# =========================================================================
#  MODES AGENT — périmètre d'écriture strict
# =========================================================================

# Un rapport ne peut être écrit que dans le dossier de SON auteur.
# ai/reports/dev/** pour dev, etc. La règle se déduit d'agent_type : rien
# à modifier quand un agent s'ajoute.
own_report() { matches "$1" "(^|/)ai/reports/${AGENT}/"; }
other_report() { matches "$1" "$REPORTS_RE" && ! own_report "$1"; }

allowed_path() {
  local p="$1"

  # Personne n'écrit dans le dossier de rapports d'un autre.
  other_report "$p" && return 1

  case "$MODE" in
    docs-only)
      own_report "$p" && return 1                 # l'analyst n'écrit aucun rapport
      matches "$p" "$REPORTS_RE" && return 1
      matches "$p" "$AI_RE" && return 0
      matches "$p" "$MD_RE" && return 0
      return 1
      ;;
    code-only)
      own_report "$p" && return 0
      matches "$p" "$TEST_RE"    && ! matches "$p" "$SPECDOC_RE" && return 1
      matches "$p" "$TESTCFG_RE" && return 1
      matches "$p" "$AI_RE"      && return 1      # les contrats appartiennent à l'analyst
      matches "$p" "$MD_RE"      && return 1
      return 0
      ;;
    tests-only)
      own_report "$p" && return 0
      matches "$p" "$SPECDOC_RE" && return 1      # ai/specs/*.spec.md est un contrat
      matches "$p" "$TEST_RE"    && return 0
      matches "$p" "$TESTCFG_RE" && return 0
      matches "$p" "$PKG_RE"     && return 0      # setup : pnpm add -D
      return 1
      ;;
    reports-only)
      own_report "$p" && return 0
      return 1
      ;;
  esac
  return 1
}

describe_scope() {
  case "$MODE" in
    docs-only)    echo "ai/** (hors ai/reports/) et les fichiers .md" ;;
    code-only)    echo "le code source et ai/reports/dev/" ;;
    tests-only)   echo "les fichiers de test, leurs configs, package.json et ai/reports/tester/" ;;
    reports-only) echo "ai/reports/reviewer/ uniquement" ;;
  esac
}

# --- Outils à chemin ----------------------------------------------------
if [ "$KIND" = path ]; then
  if ! allowed_path "$FILE"; then
    refuse_scope "$TOOL sur $FILE" "$(describe_scope)"
  fi
  # Un test existant reste protégé même pour le tester : il en crée,
  # il n'en réécrit pas sans que je lève le verrou.
  if [ "$MODE" = tests-only ] && matches "$FILE" "$TEST_RE" && [ -f "$FILE" ]; then
    if [ -z "${ALLOW_TEST_EDITS:-}" ] && [ ! -f "$FLAG" ]; then
      refuse_test "modification d'un test existant ($TOOL) :

  $FILE"
    fi
  fi
  exit 0
fi

# --- Bash ---------------------------------------------------------------
# Heuristique : on n'inspecte que les commandes qui écrivent réellement.
# Une commande de lecture (grep, cat, ls, git diff, node, pnpm run) passe.

# 1. Installation de dépendances — réservée au tester, allowlist stricte.
if matches "$CMD" '(^|[[:space:]])(pnpm|npm|yarn|bun)[[:space:]]+(add|install|i)([[:space:]]|$)'; then
  if [ "$MODE" != tests-only ]; then
    refuse_scope "installation de dépendance : $CMD" "$(describe_scope)
Les dépendances s'installent en mission de setup du tester, jamais ici."
  fi
  if matches "$CMD" '(--ignore-scripts)' || matches "$CMD" '^[[:space:]]*pnpm[[:space:]]'; then
    : # pnpm 10 bloque les scripts par défaut ; npm/yarn exigent --ignore-scripts
  else
    refuse "installation sans --ignore-scripts." \
      "  $CMD" "" \
      "Les scripts de cycle de vie d'une dépendance s'exécutent AU MOMENT de" \
      "l'installation, avec mes droits. Un compte rendu lu après arrive trop tard." \
      "" \
      "  npm install --save-dev --ignore-scripts <paquets>" \
      "  yarn add -D --ignore-scripts <paquets>"
  fi
  # Chaque paquet nommé doit figurer dans l'allowlist.
  for tok in $CMD; do
    case "$tok" in
      -*|pnpm|npm|yarn|bun|add|install|i|--save-dev) continue ;;
    esac
    pkg="${tok%@*}"; [ "${tok#@}" != "$tok" ] && pkg="@${tok#@}" && pkg="${pkg%@*}"
    [ -z "$pkg" ] && continue
    if ! printf '%s' "$pkg" | grep -Eq "$ALLOWED_PKGS"; then
      refuse "paquet hors allowlist : $pkg" \
        "  $CMD" "" \
        "ARRÊTE TA MISSION et propose ce paquet dans ton rapport, avec sa" \
        "justification en une phrase. Un nom de paquet plausible mais inconnu" \
        "est le vecteur n°1 de compromission d'une chaîne d'approvisionnement :" \
        "quelqu'un publie exactement le nom qu'un modèle est susceptible" \
        "d'halluciner." "" \
        "Allowlist : vitest, @vitest/*, jsdom, happy-dom, @testing-library/*," \
        "playwright, @playwright/test, msw, supertest."
    fi
  done
  exit 0
fi

# 2. pnpm approve-builds — jamais, quel que soit l'agent.
if matches "$CMD" 'approve-builds'; then
  refuse "réautorisation des scripts de dépendances." \
    "  $CMD" "" \
    "Les scripts de cycle de vie restent désactivés. Si un paquet en exige" \
    "un pour fonctionner, arrête-toi et signale-le."
fi

# 3. Écritures ciblant un chemin : redirection, édition en place, déplacement.
extract_targets() {
  printf '%s' "$CMD" \
    | grep -oE '>>?[[:space:]]*[^[:space:];|&]+|(^|[[:space:]])(rm|mv|cp|touch|tee|truncate|sed|dd)[[:space:]]+[^;|&]*' \
    | grep -oE '[^[:space:]<>]+' \
    | grep -vE '^(rm|mv|cp|touch|tee|truncate|sed|dd|-.*)$'
}

if matches "$CMD" '>|(^|[[:space:]])(rm|mv|cp|touch|tee|truncate|dd)[[:space:]]|[[:space:]]-i([[:space:]]|$)'; then
  for target in $(extract_targets); do
    case "$target" in
      /dev/null|/tmp/*|/private/tmp/*) continue ;;
    esac
    if ! allowed_path "$target"; then
      refuse_scope "écriture shell vers $target

  $CMD" "$(describe_scope)"
    fi
  done
fi

# 4. Git destructif : hors périmètre de tout agent.
if matches "$CMD" 'git[[:space:]]+(push|reset[[:space:]]+--hard|clean|checkout[[:space:]]+\.)'; then
  refuse_scope "commande git destructive ou distante : $CMD" \
    "$(describe_scope)
Le commit et le push sont des gestes humains. Prépare, rapporte, arrête-toi."
fi

exit 0
