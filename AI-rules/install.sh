#!/usr/bin/env bash
#
# Installe les règles et commandes partagées dans Claude Code et Codex.
# Idempotent : relançable sans risque.
#
#   ./install.sh

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1" dest="$2"

  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    if [ -s "$dest" ] || [ -d "$dest" ]; then
      echo "⚠️  $dest existe déjà et n'est pas un lien — ignoré."
      echo "    Sauvegarde-le puis supprime-le pour que le lien soit posé."
      return
    fi
    rm "$dest" # fichier vide : rien à perdre
  fi

  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest"
  echo "✅ $dest → $src"
}

echo "Source de vérité : $REPO"
echo

# Règles globales — qui je suis, comment je travaille
link "$REPO/me.md" "$HOME/.claude/CLAUDE.md"
link "$REPO/me.md" "$HOME/.codex/AGENTS.md"

# Commandes — un seul dossier pour les deux outils
link "$REPO/commands" "$HOME/.claude/commands"
link "$REPO/commands" "$HOME/.codex/prompts"

echo
echo "Terminé. Vérifie en tapant /clean-commit dans Claude Code, puis dans Codex."
echo "Si Codex affiche le bloc '---' comme du texte, dis-le : on retirera le frontmatter."
