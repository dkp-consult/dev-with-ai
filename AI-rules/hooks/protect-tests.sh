#!/usr/bin/env bash
#
# protect-tests.sh — hook PreToolUse pour Claude Code.
#
# Empêche l'agent de modifier, réécrire ou supprimer un fichier de test EXISTANT.
# Créer un nouveau fichier de test reste autorisé.
#
# Pourquoi : mis en boucle sur « fais passer les tests », un agent finit
# statistiquement par affaiblir l'assertion plutôt que corriger le code.
# Une règle en langage naturel dans le CLAUDE.md est une incitation ;
# ce hook est une contrainte.
#
# Portée : Edit, Write, NotebookEdit (chemin exact) et Bash (heuristique sur
# la commande). Le volet Bash reconnaît les écritures courantes — sed -i,
# redirection, rm, mv, cp, git restore. Ce n'est pas une frontière de sécurité :
# une commande suffisamment tordue passe. C'est un garde-fou contre la dérive
# ordinaire, pas contre un contournement délibéré.
#
# Levée du verrou — humaine, jamais par l'agent :
#   touch .claude/.allow-test-edits     # puis rm quand c'est fini
#   ou : export ALLOW_TEST_EDITS=1 avant de lancer Claude Code
#
# Déclaration : voir AI-rules/install.sh (il affiche le bloc à coller).

set -uo pipefail

INPUT=$(cat)

# jq est requis. On ne bloque pas s'il manque — ce hook n'est pas une sécurité —
# mais on le signale bruyamment : un hook silencieux passerait pour un succès.
if ! command -v jq >/dev/null 2>&1; then
  echo "protect-tests.sh : jq introuvable, hook inactif. -> brew install jq" >&2
  exit 0
fi

TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
CMD=$(printf '%s'  "$INPUT" | jq -r '.tool_input.command  // empty')

FLAG=".claude/.allow-test-edits"

# Ce qui ressemble à un chemin de test, dans une chaîne quelconque.
TEST_PATH_RE='(\.test\.|\.spec\.|/__tests?__/|/tests?/|/e2e/|_test\.(py|go|rb)|(^|/)test_[A-Za-z0-9_]+\.py)'

refuse() {
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

# --- Le verrou ne se lève pas depuis un outil ---------------------------
case "$CMD" in
  *allow-test-edits*)
    refuse "tentative de lever le verrou de protection des tests.

  $CMD"
    ;;
esac

# --- Levée explicite, posée par un humain -------------------------------
if [ -n "${ALLOW_TEST_EDITS:-}" ] || [ -f "$FLAG" ]; then
  exit 0
fi

# --- Outils d'écriture ciblant un chemin --------------------------------
# Le matcher déclaré dans settings.json devrait déjà filtrer, mais le hook
# reste correct si on l'élargit : lire un test n'a jamais à être bloqué.
case "$TOOL" in
  Edit|Write|MultiEdit|NotebookEdit) ;;
  *) FILE="" ;;
esac

if [ -n "$FILE" ]; then
  if printf '%s' "$FILE" | grep -Eq "$TEST_PATH_RE"; then
    # Création d'un nouveau test : autorisé.
    [ -f "$FILE" ] || exit 0
    refuse "modification d'un test existant ($TOOL) :

  $FILE"
  fi
  exit 0
fi

# --- Bash : heuristique sur la commande ---------------------------------
if [ "$TOOL" = "Bash" ] && [ -n "$CMD" ]; then
  printf '%s' "$CMD" | grep -Eq "$TEST_PATH_RE" || exit 0

  # Redirection vers un fichier de test.
  if printf '%s' "$CMD" | grep -Eq ">>?[[:space:]]*[^[:space:]]*($TEST_PATH_RE)"; then
    refuse "écriture par redirection vers un fichier de test :

  $CMD"
  fi

  # Édition en place.
  if printf '%s' "$CMD" | grep -Eq '(^|[[:space:]])(sed|perl|ruby|python3?)[[:space:]]+(-[^[:space:]]+[[:space:]]+)*-i'; then
    refuse "édition en place d'un fichier de test :

  $CMD"
  fi

  # Déplacement, copie, suppression, restauration.
  if printf '%s' "$CMD" | grep -Eq '(^|[;&|][[:space:]]*|[[:space:]])(rm|mv|cp|truncate|dd|tee)[[:space:]]'; then
    refuse "suppression ou déplacement d'un fichier de test :

  $CMD"
  fi
  if printf '%s' "$CMD" | grep -Eq 'git[[:space:]]+(checkout|restore|clean)'; then
    refuse "restauration git portant sur un fichier de test :

  $CMD"
  fi
fi

exit 0
