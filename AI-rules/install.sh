#!/usr/bin/env bash
#
# Installe les règles partagées, les commandes Claude Code et les skills Codex,
# ainsi que les briques propres à Claude Code : sous-agents et hooks.
# Idempotent : relançable sans risque.
#
#   ./install.sh [--force]
#
# Refuse de s'installer par-dessus AIDD, sauf --force. Voir la garde plus bas.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "argument inconnu : $1" >&2; exit 1 ;;
  esac
done

# --- Garde : ce harnais et AIDD ne cohabitent pas -------------------------
#
# Les deux déploient des surfaces globales qui se recouvrent : quinze des
# dix-huit commandes d'ici doublonnent un skill AIDD. Or un skill se déclenche
# aussi sur sa description, pas seulement à l'invocation — deux candidats pour
# « écris la spec », c'est une sélection non déterministe qu'on ne voit pas
# passer. C'est ce qui avait motivé la bascule du 4 septembre, et c'est ce
# qu'une relance distraite de ce script réactive d'un coup.
#
# La garde ne regarde pas le nom de la branche courante : une branche ne dit
# rien de ce qui est réellement déployé dans ~/.claude. Elle lit l'état vécu.
AIDD_MARKER="$HOME/.claude/skills"

aidd_bundles() {
  find "$AIDD_MARKER" -maxdepth 1 -name 'aidd-*' -type d 2>/dev/null | wc -l | tr -d ' '
}

if [ "$FORCE" -eq 0 ] && [ "$(aidd_bundles)" -gt 0 ]; then
  cat >&2 <<MSG
REFUS — AIDD est installé globalement ($(aidd_bundles) skills dans ~/.claude/skills).

Ce script rétablirait les liens, les commandes et les skills Codex de ce
harnais par-dessus. Quinze des dix-huit commandes doublonnent un skill AIDD :
la sélection entre les deux devient non déterministe, et silencieuse.

Pour repasser à ce harnais, désinstaller AIDD d'abord. La marche à suivre et
l'instantané d'avant bascule sont dans :
  AI-rules/ARCHIVES/2026-09-04-bascule-aidd/README.md

Si tu sais ce que tu fais et veux vraiment les deux en même temps :
  ./install.sh --force
MSG
  exit 1
fi

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
    # Codex n'a pas de sous-agents : un marqueur `<!-- fallback:chemin -->`
    # dans une commande y injecte le contenu du sous-agent référencé, pour que
    # le skill reste autonome. Claude Code, lui, ignore le commentaire et
    # délègue au vrai sous-agent.
    awk -v repo="$REPO" '
      NR == 1 && $0 == "---" { in_frontmatter = 1; next }
      in_frontmatter && $0 == "---" { in_frontmatter = 0; next }
      in_frontmatter { next }

      /^<!-- fallback:.*-->[[:space:]]*$/ {
        path = $0
        sub(/^<!-- fallback:[[:space:]]*/, "", path)
        sub(/[[:space:]]*-->[[:space:]]*$/, "", path)
        src = repo "/" path

        n = 0
        body = ""
        fm = 0
        seen = 0
        while ((getline line < src) > 0) {
          if (!seen && line == "---") { fm = 1; seen = 1; continue }
          if (fm && line == "---") { fm = 0; continue }
          if (!fm) { body = body line "\n"; n++ }
        }
        close(src)

        if (n == 0) {
          print "ERREUR : fallback introuvable -> " src > "/dev/stderr"
          next
        }

        print "## Annexe — méthode de conception, pour un outil sans sous-agents"
        print ""
        print "Applique cette méthode toi-même, à la place de la délégation demandée en étape 1."
        print ""
        printf "%s", body
        next
      }

      {
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

# Sous-agents et hooks : Claude Code uniquement, Codex n'a pas d'équivalent
link "$REPO/agents" "$HOME/.claude/agents"
link "$REPO/hooks" "$HOME/.claude/hooks"
chmod +x "$REPO"/hooks/*.sh

# Skills Codex — générés car les custom prompts sont dépréciés
for command_file in "$REPO"/commands/*.md; do
  install_codex_skill "$command_file"
done

# --- Déclaration du hook -------------------------------------------------
# Volontairement non automatisée : settings.json peut contenir d'autres hooks,
# et une fusion à l'aveugle sur un fichier de configuration personnel se paie cher.
settings="$HOME/.claude/settings.json"

if ! command -v jq >/dev/null 2>&1; then
  echo
  echo "ATTENTION : jq est absent, les hooks protect-tests et session-start seront inactifs."
  echo "            brew install jq"
fi

# Les commandes issue-* pilotent GitHub par gh. Sans lui, elles ne tournent pas.
if ! command -v gh >/dev/null 2>&1; then
  echo
  echo "ATTENTION : gh est absent, les commandes issue-* ne fonctionneront pas."
  echo "            brew install gh && gh auth login"
elif ! gh auth status >/dev/null 2>&1; then
  echo
  echo "ATTENTION : gh n'est pas authentifié, les commandes issue-* échoueront."
  echo "            gh auth login"
fi

if [ -f "$settings" ] && grep -q 'scope-guard.sh' "$settings"; then
  echo
  echo "OK hook scope-guard déjà déclaré dans $settings"
else
  echo
  echo "À FAIRE — le hook est posé mais pas déclaré."
  echo "Ajoute cette entrée au tableau hooks.PreToolUse de $settings :"
  echo
  cat <<'JSON'
    {
      "matcher": "Edit|Write|NotebookEdit|Bash",
      "hooks": [
        { "type": "command", "command": "$HOME/.claude/hooks/scope-guard.sh" }
      ]
    }
JSON
  echo
  echo "Une seule déclaration suffit : scope-guard dispatche sur agent_type."
  echo "En global, un agent créé plus tard sans déclaration tombe dans le cas"
  echo "par défaut, donc protégé. Le frontmatter fait l'inverse."
  echo
  echo "Puis vérifie qu'il bloque réellement — un hook qui laisse tout passer"
  echo "est pire que pas de hook :"
  echo
  echo '  printf %s "{\"agent_type\":\"dev\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"a.test.ts\"}}" \'
  echo '    | ~/.claude/hooks/scope-guard.sh ; echo "exit=$?"'
  echo
  echo "  Attendu : blocage hors périmètre et exit=2."
fi

if [ -f "$settings" ] && grep -q 'session-start.sh' "$settings"; then
  echo
  echo "OK hook session-start déjà déclaré dans $settings"
else
  echo
  echo "À FAIRE — le hook session-start est posé mais pas déclaré."
  echo "Ajoute cette entrée au tableau hooks.SessionStart de $settings :"
  echo
  cat <<'JSON'
    {
      "hooks": [
        { "type": "command", "command": "$HOME/.claude/hooks/session-start.sh", "timeout": 15 }
      ]
    }
JSON
  echo
  echo "Vérifie-le depuis un worktree dont la branche suit <type>/<numero>-<slug> :"
  echo
  echo "  ~/.claude/hooks/session-start.sh ; echo \"exit=\$?\""
  echo
  echo "  Attendu : le contrat de l'issue et le dernier checkpoint, exit=0."
  echo "  Hors convention de branche, il sort en 0 sans rien afficher — c'est voulu."
fi

# --- Dérive de la politique de permissions -------------------------------
# settings.json n'est PAS un lien : il porte aussi ce qui n'est pas à moi
# (vibe-island, thème, répertoires supplémentaires), et une fusion à l'aveugle
# sur un fichier de configuration personnel se paie cher — même raison que
# pour la déclaration des hooks plus haut.
#
# Ce qui n'a de copie nulle part, c'est le bloc `permissions` : la liste allow,
# la liste deny. On le compare, on le signale, on n'écrit jamais.
# Le fichier complet reste versionné à côté, comme point de restauration.
reference="$REPO/settings.json"

if [ -f "$settings" ] && [ -f "$reference" ] && command -v jq >/dev/null 2>&1; then
  live_perms="$(jq -S '.permissions // {}' "$settings" 2>/dev/null || echo 'null')"
  ref_perms="$(jq -S '.permissions // {}' "$reference" 2>/dev/null || echo 'null')"

  if [ "$live_perms" = "$ref_perms" ]; then
    echo
    echo "OK politique de permissions identique à $reference"
  else
    echo
    echo "ATTENTION — la politique de permissions a dérivé."
    echo "  vécu     : $settings"
    echo "  versionné: $reference"
    echo
    diff <(printf '%s\n' "$ref_perms") <(printf '%s\n' "$live_perms") \
      | sed 's/^/  /' || true
    echo
    echo "  < versionné    > vécu"
    echo
    echo "Rien n'a été modifié. Choisis un sens :"
    echo "  adopter le vécu     : jq -S . \"$settings\" > \"$reference\""
    echo "  restaurer le dépôt  : édite \"$settings\" à la main, ou repars de"
    echo "                        \"$reference\" si tu acceptes d'écraser le reste."
  fi
fi

echo
echo "Installation terminée."
echo "Claude Code : redémarre-le — le watcher ne voit pas un répertoire créé"
echo "              après le démarrage de la session. Vérifie ensuite avec /agents."
echo "Codex : redémarre Codex, puis invoque \$clean-commit ou sélectionne le skill."
