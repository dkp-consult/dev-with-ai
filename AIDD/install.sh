#!/usr/bin/env bash
#
# Installe le framework AI-Driven Dev en global sur la machine, depuis un clone
# local unique, pour les quatre CLI utilisées ici : Claude Code, Codex, Kimi, AGY.
#
# Le principe est celui du repo : une source de vérité, plusieurs destinations.
# Ici la source n'est pas ce dépôt mais un clone du framework — on ne versionne
# pas son contenu, on versionne la façon de le déployer.
#
#   ./install.sh [--source <clone>] [--pull] [--dry-run]
#
# Idempotent : relançable sans risque.
#
# Ce que le script écrit (et rien d'autre) :
#   - les skills et agents dont le nom commence par « aidd- »
#   - le hook update_memory.js
#
# Ce que le script ne touche JAMAIS :
#   - ~/.claude/settings.json et ~/.codex/hooks.json. Ils portent déjà d'autres
#     hooks (vibe-island, scope-guard, session-start). Une fusion automatique
#     sur un fichier de configuration personnel se paie cher — même raison que
#     dans AI-rules/install.sh. Le script vérifie et affiche le bloc à coller.

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────

SOURCE="${AIDD_SOURCE:-$HOME/dev/aidd-framework}"
DRY_RUN=0
DO_PULL=0

# Tout ce que ce script gère porte ce préfixe. C'est la garantie qu'un nettoyage
# ne peut pas emporter une skill écrite à la main dans le même répertoire.
PREFIX="aidd-"

# Les quatre racines de skills, vérifiées une à une en lançant réellement
# chaque CLI : les quatre chargent le même format de bundle <nom>/SKILL.md.
SKILL_DIRS=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.kimi-code/skills"
  "$HOME/.gemini/config/skills"
)

CLAUDE_AGENTS="$HOME/.claude/agents"
CODEX_AGENTS="$HOME/.codex/agents"
# Le hook est partagé par Claude Code et Codex. Le loger sous ~/.claude/ ferait
# pointer la configuration de Codex dans le répertoire d'un autre outil ; il a
# donc sa propre racine, neutre, comme le clone source.
HOOK_DIR="$HOME/.aidd/hooks"
HOOK_PATH="$HOOK_DIR/update_memory.js"

CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CODEX_HOOKS="$HOME/.codex/hooks.json"
CODEX_CONFIG="$HOME/.codex/config.toml"

AIDD_CLI="@ai-driven-dev/cli@latest"

# ── Sortie ────────────────────────────────────────────────────────

TODO_COUNT=0

say()  { printf '%s\n' "$*"; }
ok()   { printf 'OK %s\n' "$*"; }
warn() { printf 'ATTENTION : %s\n' "$*" >&2; }
todo() { TODO_COUNT=$((TODO_COUNT + 1)); printf '\nÀ FAIRE — %s\n' "$*"; }
die()  { printf 'ERREUR : %s\n' "$*" >&2; exit 1; }

# Tout ce qui écrit passe par l'un des deux.
#
# « run » annonce le geste : réservé aux opérations uniques et notables.
# « apply » est muet : les boucles de copie en produiraient des centaines de
# lignes, or leur bilan chiffré par destination dit déjà tout.
run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '   [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

apply() {
  [ "$DRY_RUN" -eq 1 ] && return 0
  "$@"
}

# ── Arguments ─────────────────────────────────────────────────────

while [ $# -gt 0 ]; do
  case "$1" in
    --source)  SOURCE="${2:?--source attend un chemin}"; shift 2 ;;
    --pull)    DO_PULL=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) die "argument inconnu : $1" ;;
  esac
done

# ── Prérequis ─────────────────────────────────────────────────────

command -v node >/dev/null 2>&1 || die "node est absent du PATH."
command -v npx  >/dev/null 2>&1 || die "npx est absent du PATH."

if [ ! -d "$SOURCE" ]; then
  die "clone introuvable : $SOURCE
    git clone https://github.com/ai-driven-dev/framework \"$SOURCE\"
    ou passe un autre chemin avec --source."
fi

[ -d "$SOURCE/plugins" ] || die "$SOURCE ne ressemble pas au framework (pas de plugins/)."

say "Source   : $SOURCE"
[ "$DRY_RUN" -eq 1 ] && say "Mode     : dry-run, aucune écriture"

if [ "$DO_PULL" -eq 1 ]; then
  say
  say "Mise à jour du clone..."
  run git -C "$SOURCE" pull --ff-only
fi

# Le dépôt porte aussi des tags par plugin (aidd-context-v2.7.0), que
# « git describe » attrape en premier, et un package.json racine resté en 0.0.0.
# La version du framework est le dernier tag « v* ».
VERSION="$(git -C "$SOURCE" describe --tags --match 'v*' --abbrev=0 2>/dev/null || echo 'inconnue')"
say "Version  : $VERSION"
say

# ── Construction ──────────────────────────────────────────────────
#
# Le traducteur officiel produit l'arborescence native de chaque outil depuis
# la source au format Claude. On ne construit que deux cibles : « claude »
# fournit les skills (identiques pour les quatre outils), le hook et les agents
# Markdown ; « codex » ne sert qu'à récupérer les agents au format TOML.

STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT

build() {
  local target="$1"
  say "Construction de la cible $target..."
  # Le traducteur refuse de construire si --out n'existe pas encore.
  mkdir -p "$STAGING/$target"
  npx --yes "$AIDD_CLI" framework build \
    --source "$SOURCE" --target "$target" --flat --out "$STAGING/$target" \
    | sed 's/^/   /'
}

build claude
build codex
say

SRC_SKILLS="$STAGING/claude/.claude/skills"
SRC_AGENTS_MD="$STAGING/claude/.claude/agents"
SRC_AGENTS_TOML="$STAGING/codex/.codex/agents"
SRC_HOOK="$STAGING/claude/.claude/hooks/aidd-context/update_memory.js"

[ -d "$SRC_SKILLS" ] || die "la construction n'a produit aucune skill."
[ -f "$SRC_HOOK" ]   || die "la construction n'a produit aucun hook."

# ── Skills ────────────────────────────────────────────────────────
#
# Un bundle disparu en amont doit disparaître ici : sans ça une skill renommée
# resterait en double, l'ancienne version continuant d'être proposée à l'agent.
# Le nettoyage ne cible que le préfixe géré.

install_skills() {
  local dest="$1" name kept=0 added=0 removed=0

  apply mkdir -p "$dest"

  # Retrait de ce qui n'existe plus en amont.
  if [ -d "$dest" ]; then
    for existing in "$dest"/"$PREFIX"*; do
      [ -d "$existing" ] || continue
      name="$(basename "$existing")"
      if [ ! -d "$SRC_SKILLS/$name" ]; then
        apply rm -r "$existing"
        removed=$((removed + 1))
      fi
    done
  fi

  for bundle in "$SRC_SKILLS"/*; do
    [ -d "$bundle" ] || continue
    name="$(basename "$bundle")"

    case "$name" in
      "$PREFIX"*) ;;
      *) warn "skill hors préfixe ignorée : $name"; continue ;;
    esac

    if [ -d "$dest/$name" ]; then
      apply rm -r "$dest/$name"
      kept=$((kept + 1))
    else
      added=$((added + 1))
    fi
    apply cp -R "$bundle" "$dest/"
  done

  printf '   %-32s %s skills' "$(printf '%s' "$dest" | sed "s|^$HOME|~|")" "$((kept + added))"
  [ "$added"   -gt 0 ] && printf ' (+%s)' "$added"
  [ "$removed" -gt 0 ] && printf ' (-%s)' "$removed"
  printf '\n'
}

say "Skills"
for dir in "${SKILL_DIRS[@]}"; do
  install_skills "$dir"
done
say

# ── Agents ────────────────────────────────────────────────────────
#
# Seuls Claude Code et Codex ont des sous-agents, et pas dans le même format.
# Kimi et AGY n'en reçoivent pas : leurs skills restent autonomes.

install_agents() {
  local src="$1" dest="$2" ext="$3" name count=0

  [ -d "$src" ] || { warn "aucun agent produit dans $src"; return; }
  apply mkdir -p "$dest"

  for existing in "$dest"/"$PREFIX"*."$ext"; do
    [ -f "$existing" ] || continue
    name="$(basename "$existing")"
    [ -f "$src/$name" ] || apply rm "$existing"
  done

  for agent in "$src"/*."$ext"; do
    [ -f "$agent" ] || continue
    name="$(basename "$agent")"
    case "$name" in
      "$PREFIX"*) ;;
      *) warn "agent hors préfixe ignoré : $name"; continue ;;
    esac
    apply cp "$agent" "$dest/$name"
    count=$((count + 1))
  done

  printf '   %-32s %s agents (.%s)\n' "$(printf '%s' "$dest" | sed "s|^$HOME|~|")" "$count" "$ext"
}

say "Agents"
install_agents "$SRC_AGENTS_MD"   "$CLAUDE_AGENTS" md
install_agents "$SRC_AGENTS_TOML" "$CODEX_AGENTS"  toml
say

# ── Hook ──────────────────────────────────────────────────────────
#
# update_memory.js remplit le bloc mémoire de CLAUDE.md / AGENTS.md à partir de
# aidd_docs/memory/. Il se cale sur $CLAUDE_PROJECT_DIR sinon sur le répertoire
# courant, et sort en 0 sans rien faire si aidd_docs/ est absent — donc inerte
# dans tous les projets qui n'utilisent pas AIDD. C'est ce qui rend l'install
# globale possible : le script vit à un endroit fixe, il agit sur le projet ouvert.

say "Hook"
run mkdir -p "$HOOK_DIR"
run cp "$SRC_HOOK" "$HOOK_PATH"
printf '   %s\n' "$(printf '%s' "$HOOK_PATH" | sed "s|^$HOME|~|")"
say

# ── Déclarations ──────────────────────────────────────────────────
#
# Volontairement non automatisées. Mais un hook posé et non déclaré ne produit
# aucune erreur : il ne tourne simplement jamais. On vérifie donc deux choses —
# la déclaration existe, et le chemin qu'elle contient pointe sur un fichier
# réel. Le second cas attrape la déclaration devenue obsolète.

declared_in() {
  local file="$1"
  [ -f "$file" ] || return 1
  grep -qF "$HOOK_PATH" "$file"
}

check_declaration() {
  local file="$1" label="$2"
  local short; short="$(printf '%s' "$file" | sed "s|^$HOME|~|")"

  if [ ! -f "$file" ]; then
    todo "$label — $short n'existe pas encore. Crée-le avec ce contenu :"
    return 1
  fi

  if declared_in "$file"; then
    ok "$label — hook déclaré dans $short, chemin valide"
    return 0
  fi

  if grep -q 'update_memory\.js' "$file"; then
    todo "$label — une déclaration existe dans $short mais pointe ailleurs.
Remplace son chemin par : $HOOK_PATH"
    return 1
  fi

  todo "$label — hook non déclaré dans $short. Ajoute cette entrée dans hooks.SessionStart :"
  return 1
}

hook_block() {
  cat <<JSON
    {
      "hooks": [
        { "type": "command", "command": "node $HOOK_PATH" }
      ]
    }
JSON
}

say "Déclarations"

check_declaration "$CLAUDE_SETTINGS" "Claude Code" || { say; hook_block; }
check_declaration "$CODEX_HOOKS"     "Codex"       || { say; hook_block; }

# Codex n'exécute ses hooks que si la fonctionnalité est activée. Une déclaration
# correcte dans un Codex où hooks = false ne sert à rien, et ne dit rien non plus.
if [ -f "$CODEX_CONFIG" ]; then
  if awk '/^\[features\]/ { in_f = 1; next } /^\[/ { in_f = 0 } in_f && /^[[:space:]]*hooks[[:space:]]*=[[:space:]]*true/ { found = 1 } END { exit !found }' "$CODEX_CONFIG"; then
    ok "Codex — hooks activés dans ~/.codex/config.toml"
  else
    todo "Codex — les hooks ne sont pas activés. Ajoute sous [features] de ~/.codex/config.toml :

    hooks = true"
  fi
fi

# ── Bilan ─────────────────────────────────────────────────────────

say
say "─────────────────────────────────────────────"
say "AIDD $VERSION déployé."
say
say "Kimi et AGY reçoivent les skills, pas les agents ni le hook :"
say "la synchronisation de la mémoire projet ne tourne que dans Claude Code et Codex."
say

if [ "$TODO_COUNT" -gt 0 ]; then
  say "$TODO_COUNT point(s) à traiter à la main, voir plus haut."
else
  say "Rien à faire à la main."
fi

say
say "Redémarre les CLI concernées pour qu'elles rechargent les skills."
