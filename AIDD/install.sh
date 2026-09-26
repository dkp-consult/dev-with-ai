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
#   - les hooks : update_memory.js et le bundle aidd-telemetry/
#
# Ce que le script ne touche JAMAIS :
#   - les configurations des CLI : ~/.claude/settings.json, ~/.codex/hooks.json,
#     ~/.gemini/settings.json, ~/.kimi-code/config.toml. Elles portent déjà
#     d'autres hooks (vibe-island, scope-guard, session-start). Une fusion
#     automatique sur un fichier de configuration personnel se paie cher — même
#     raison que dans AI-rules/install.sh. Le script vérifie et affiche le bloc
#     à coller.

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────

SOURCE="${AIDD_SOURCE:-$HOME/dev/aidd-works/framework}"
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
# Kimi découvre les profils d'agent dans ce répertoire et lit du Markdown à
# frontmatter — le format produit pour Claude convient tel quel. Vérifié en
# lançant « kimi --agent aidd-dev-executor » : le rôle défini dans le .md est
# bien celui que Kimi adopte.
#
# AGY n'a pas d'équivalent : « agy --agent <nom> » ignore les profils déposés
# dans ~/.gemini/config/agents, ~/.gemini/agents et ~/.gemini/config/subagents,
# et « agy agents » ne liste rien. Ses sous-agents semblent internes plutôt que
# déclarés par fichier. Rien à déployer tant que ça n'a pas changé.
KIMI_AGENTS="$HOME/.kimi-code/agents"
# Le hook est partagé par Claude Code et Codex. Le loger sous ~/.claude/ ferait
# pointer la configuration de Codex dans le répertoire d'un autre outil ; il a
# donc sa propre racine, neutre, comme le clone source.
HOOK_DIR="$HOME/.aidd/hooks"
HOOK_PATH="$HOOK_DIR/update_memory.js"
# journal.cjs charge hooks/lib/ : c'est un bundle, pas un fichier. Il garde donc
# son propre répertoire, nommé comme le plugin qui le livre.
TELEMETRY_DIR="$HOOK_DIR/aidd-telemetry"
TELEMETRY_HOOK="$TELEMETRY_DIR/journal.cjs"

CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CODEX_HOOKS="$HOME/.codex/hooks.json"
CODEX_CONFIG="$HOME/.codex/config.toml"
# Kimi déclare ses hooks en TOML à plat ([[hooks]] / event / command), AGY dans
# un settings.json de forme identique à celui de Claude Code.
KIMI_CONFIG="$HOME/.kimi-code/config.toml"
AGY_SETTINGS="$HOME/.gemini/settings.json"

AIDD_CLI="@ai-driven-dev/cli@latest"

# ── Sortie ────────────────────────────────────────────────────────

TODO_COUNT=0

say()  { printf '%s\n' "$*"; }
short(){ printf '%s' "$1" | sed "s|^$HOME|~|"; }
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
      sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'
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
  # « framework build » a disparu de la CLI 5.x : la conversion sans trace
  # s'appelle maintenant « translate », et « framework » ne garde que le cycle
  # de vie (install/remove/update). Même arborescence produite, options
  # renommées : --source devient positionnel, --target devient --to, --flat
  # devient --as flat.
  npx --yes "$AIDD_CLI" translate "$SOURCE" \
    --to "$target" --as flat --out "$STAGING/$target" \
    | sed 's/^/   /'
}

build claude
build codex
say

SRC_SKILLS="$STAGING/claude/.claude/skills"
SRC_AGENTS_MD="$STAGING/claude/.claude/agents"
SRC_AGENTS_TOML="$STAGING/codex/.codex/agents"
SRC_HOOK="$STAGING/claude/.claude/hooks/aidd-context/update_memory.js"
SRC_TELEMETRY="$STAGING/claude/.claude/hooks/aidd-telemetry"

[ -d "$SRC_SKILLS" ] || die "la construction n'a produit aucune skill."
[ -f "$SRC_HOOK" ]   || die "la construction n'a produit aucun hook."
[ -d "$SRC_TELEMETRY" ] || die "la construction n'a produit aucun hook de télémétrie."

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
# Trois destinations, deux formats. Claude Code et Kimi lisent le même Markdown
# à frontmatter, Codex veut du TOML.
#
# Aucune skill n'appelle un agent par son nom (« aidd-dev-executor » n'apparaît
# nulle part dans les 47) : la délégation est écrite en termes de rôle. Un outil
# sans agent ne casse donc pas, il fait le travail dans son contexte principal —
# ce qui coûte l'isolation, pas les étapes. C'est ce qui rend AGY tenable en
# l'état, et ce qui rend le déploiement vers Kimi utile plutôt qu'obligatoire.

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
install_agents "$SRC_AGENTS_MD"   "$KIMI_AGENTS"   md
say

# ── Hooks ─────────────────────────────────────────────────────────
#
# update_memory.js remplit le bloc mémoire de CLAUDE.md / AGENTS.md à partir de
# aidd_docs/memory/. Il se cale sur $CLAUDE_PROJECT_DIR sinon sur le répertoire
# courant, et sort en 0 sans rien faire si aidd_docs/ est absent — donc inerte
# dans tous les projets qui n'utilisent pas AIDD. C'est ce qui rend l'install
# globale possible : le script vit à un endroit fixe, il agit sur le projet ouvert.
#
# journal.cjs (plugin aidd-telemetry, apparu en v5.10.0) enregistre ce qu'une
# session consomme. Deux différences avec le précédent :
#   - il charge hooks/lib/, donc c'est un répertoire entier qui se déplace ;
#   - il veut trois événements, pas un (SessionStart, Stop, PostToolUse), et
#     reçoit son nom d'événement en argument.
# Lui aussi est inerte par défaut : rien n'est mesuré tant que le projet ouvert
# ne porte pas un .aidd/config.json avec telemetry.enabled = true, et
# AIDD_TELEMETRY=0 dans l'environnement le neutralise partout, sans condition.

say "Hooks"
run mkdir -p "$HOOK_DIR"
run cp "$SRC_HOOK" "$HOOK_PATH"
printf '   %s\n' "$(short "$HOOK_PATH")"

# Remplacé et non fusionné : un fichier de lib/ retiré en amont doit disparaître
# ici aussi, sinon journal.cjs continue de charger du code mort.
apply rm -rf "$TELEMETRY_DIR"
apply cp -R "$SRC_TELEMETRY" "$TELEMETRY_DIR"
printf '   %s\n' "$(short "$TELEMETRY_DIR")"
say

# ── Déclarations ──────────────────────────────────────────────────
#
# Volontairement non automatisées. Mais un hook posé et non déclaré ne produit
# aucune erreur : il ne tourne simplement jamais. On vérifie donc deux choses —
# la déclaration existe, et le chemin qu'elle contient pointe sur un fichier
# réel. Le second cas attrape la déclaration devenue obsolète.

# JSON autorise « \/ » pour une barre oblique, et ~/.codex/hooks.json est écrit
# dans ce dialecte. Chercher le chemin tel quel y échoue sur une déclaration
# pourtant valide : on retire les antislashs avant de comparer.
declared_in() {
  local file="$1" needle="$2"
  [ -f "$file" ] || return 1
  tr -d '\\' < "$file" | grep -qF "$needle"
}

# $3 est le chemin attendu, $4 le motif qui reconnaît une déclaration du même
# hook pointant ailleurs — c'est ce qui distingue « jamais déclaré » de
# « déclaré, mais sur un chemin devenu faux ».
check_declaration() {
  local file="$1" label="$2" needle="$3" stale="$4"
  local short_file; short_file="$(short "$file")"

  if [ ! -f "$file" ]; then
    todo "$label — $short_file n'existe pas encore. Crée-le avec ce contenu :"
    return 1
  fi

  if declared_in "$file" "$needle"; then
    ok "$label — déclaré dans $short_file, chemin valide"
    return 0
  fi

  if grep -q "$stale" "$file"; then
    todo "$label — une déclaration existe dans $short_file mais pointe ailleurs.
Remplace son chemin par : $needle"
    return 1
  fi

  todo "$label — non déclaré dans $short_file. Ajoute ceci :"
  return 1
}

memory_block_json() {
  cat <<JSON
  Dans hooks.SessionStart :
    {
      "hooks": [
        { "type": "command", "command": "node $HOOK_PATH" }
      ]
    }
JSON
}

memory_block_toml() {
  cat <<TOML
  En dehors du bloc géré par vibe-island :
    [[hooks]]
    event = "SessionStart"
    command = "node $HOOK_PATH"
TOML
}

# Un événement par entrée, le nom canonique passé en argument : journal.cjs le
# lit dans argv avant de retomber sur hook_event_name, que tous les hôtes
# n'orthographient pas pareil.
telemetry_block_json() {
  cat <<JSON
  Dans hooks.SessionStart :
    { "hooks": [ { "type": "command", "command": "node $TELEMETRY_HOOK session-start" } ] }
  Dans hooks.Stop :
    { "hooks": [ { "type": "command", "command": "node $TELEMETRY_HOOK turn-end" } ] }
  Dans hooks.PostToolUse :
    { "hooks": [ { "type": "command", "command": "node $TELEMETRY_HOOK tool-used" } ] }
JSON
}

say "Déclarations — mémoire"

# Les quatre CLI, parce que update_memory.js ne dépend d'aucun hôte : il réécrit
# CLAUDE.md et AGENTS.md dans le projet ouvert, sans jamais lire qui l'appelle.
check_declaration "$CLAUDE_SETTINGS" "Claude Code" "$HOOK_PATH" 'update_memory\.js' || { say; memory_block_json; }
check_declaration "$CODEX_HOOKS"     "Codex"       "$HOOK_PATH" 'update_memory\.js' || { say; memory_block_json; }
check_declaration "$AGY_SETTINGS"    "AGY"         "$HOOK_PATH" 'update_memory\.js' || { say; memory_block_json; }
check_declaration "$KIMI_CONFIG"     "Kimi"        "$HOOK_PATH" 'update_memory\.js' || { say; memory_block_toml; }

say
say "Déclarations — télémétrie"

# Deux CLI seulement, et c'est une limite du hook, pas un choix de déploiement :
# detectHost ne connaît que claude-code, codex, copilot, cursor et opencode. Un
# hôte non reconnu n'échoue pas, il écrit une ligne _unrecognised.jsonl et rend
# la main — donc déclarer journal.cjs dans Kimi ou AGY produirait un marqueur,
# jamais une mesure. À rouvrir si detectHost apprend à les lire.
check_declaration "$CLAUDE_SETTINGS" "Claude Code" "$TELEMETRY_HOOK" 'journal\.cjs' || { say; telemetry_block_json; }
check_declaration "$CODEX_HOOKS"     "Codex"       "$TELEMETRY_HOOK" 'journal\.cjs' || { say; telemetry_block_json; }
say "Kimi, AGY — hors de portée du hook (hôtes inconnus de detectHost), rien à déclarer."

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
say "Claude Code, Codex et Kimi reçoivent les agents ; AGY non (pas de format cible)."
say "La mémoire projet se synchronise dans les quatre ; la télémétrie n'est"
say "lisible que par Claude Code et Codex."
say

if [ "$TODO_COUNT" -gt 0 ]; then
  say "$TODO_COUNT point(s) à traiter à la main, voir plus haut."
else
  say "Rien à faire à la main."
fi

say
say "Redémarre les CLI concernées pour qu'elles rechargent les skills."
