#!/usr/bin/env bash
#
# Installe les règles partagées, les commandes Claude Code et les skills Codex.
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

install_codex_skill() {
  local command_file="$1"
  local name description skill_dir skill_file tmp_file

  name="$(basename "$command_file" .md)"
  description="$(
    awk '
      NR == 1 && $0 == "---" { in_frontmatter = 1; next }
      in_frontmatter && $0 == "---" { exit }
      in_frontmatter && /^description:[[:space:]]*/ {
        sub(/^description:[[:space:]]*/, "")
        print
        exit
      }
    ' "$command_file"
  )"

  if [ -z "$description" ]; then
    echo "ERREUR : $command_file n'a pas de description dans son frontmatter." >&2
    return 1
  fi

  skill_dir="$HOME/.codex/skills/$name"
  skill_file="$skill_dir/SKILL.md"

  if [ -e "$skill_dir" ] && [ ! -d "$skill_dir" ]; then
    echo "ATTENTION : $skill_dir existe et n'est pas un dossier — skill ignoré."
    return
  fi

  if [ -f "$skill_file" ] && ! grep -qF '<!-- managed by dev-with-ai/AI-rules/install.sh -->' "$skill_file"; then
    echo "ATTENTION : $skill_file existe et n'est pas géré par ce script — skill ignoré."
    return
  fi

  mkdir -p "$skill_dir"
  tmp_file="$skill_dir/.SKILL.md.tmp"

  {
    printf '%s\n' '---'
    printf 'name: %s\n' "$name"
    printf 'description: %s\n' "$description"
    printf '%s\n\n' '---'
    printf '%s\n\n' '<!-- managed by dev-with-ai/AI-rules/install.sh -->'
    awk '
      NR == 1 && $0 == "---" { in_frontmatter = 1; next }
      in_frontmatter && $0 == "---" { in_frontmatter = 0; next }
      !in_frontmatter {
        gsub(/\$ARGUMENTS/, "la demande utilisateur qui invoque ce skill")
        print
      }
    ' "$command_file"
  } > "$tmp_file"

  mv "$tmp_file" "$skill_file"
  echo "OK $skill_file (généré depuis $command_file)"
}

echo "Source de vérité : $REPO"
echo

# Règles globales — qui je suis, comment je travaille
link "$REPO/me.md" "$HOME/.claude/CLAUDE.md"
link "$REPO/me.md" "$HOME/.codex/AGENTS.md"

# Commandes Claude Code
link "$REPO/commands" "$HOME/.claude/commands"

# Skills Codex — générés car les custom prompts sont dépréciés
for command_file in "$REPO"/commands/*.md; do
  install_codex_skill "$command_file"
done

echo
echo "Installation terminée."
echo "Claude Code : /clean-commit"
echo "Codex : redémarre Codex, puis invoque \$clean-commit ou sélectionne le skill."
