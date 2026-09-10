#!/usr/bin/env bash
#
# Vérifie que l'installation globale d'AIDD est intacte sur les quatre CLI.
#
#   ./check.sh          contrôles disque uniquement — instantané, gratuit
#   ./check.sh --live   ajoute une sonde réelle par CLI (un appel modèle chacun)
#
# Sort en 1 au premier écart, pour être utilisable dans un enchaînement.
#
# Deux niveaux, parce qu'ils ne prouvent pas la même chose :
#   - le disque dit que les fichiers sont là et identiques partout ;
#   - la sonde dit que la CLI les charge vraiment, fichiers annexes compris.
# Le premier ne remplace pas le second : une CLI non redémarrée après une mise
# à jour montre un disque parfait et ne voit toujours rien.

set -uo pipefail

PREFIX="aidd-"
HOOK_PATH="$HOME/.aidd/hooks/update_memory.js"
TELEMETRY_DIR="$HOME/.aidd/hooks/aidd-telemetry"
TELEMETRY_HOOK="$TELEMETRY_DIR/journal.cjs"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CODEX_HOOKS="$HOME/.codex/hooks.json"
CODEX_CONFIG="$HOME/.codex/config.toml"
KIMI_CONFIG="$HOME/.kimi-code/config.toml"
AGY_SETTINGS="$HOME/.gemini/settings.json"

SKILL_DIRS=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.kimi-code/skills"
  "$HOME/.gemini/config/skills"
)

# La sonde ouvre un bundle et lit son dossier actions/ : elle échoue donc aussi
# quand la skill est là mais amputée de ses fichiers annexes, ce qu'un simple
# « combien de skills vois-tu ? » laisserait passer.
PROBE_SKILL="aidd-vcs-01-commit"
PROBE_PROMPT="Ouvre la skill $PROBE_SKILL et liste les noms de fichiers de son dossier actions/. Rien d'autre."
PROBE_EXPECT="01-collect.md 02-message.md 03-commit.md"

LIVE=0
FAILED=0

case "${1:-}" in
  --live) LIVE=1 ;;
  -h|--help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  "") ;;
  *) printf 'ERREUR : argument inconnu : %s\n' "$1" >&2; exit 2 ;;
esac

short() { printf '%s' "$1" | sed "s|^$HOME|~|"; }
pass()  { printf '  OK   %s\n' "$*"; }
fail()  { FAILED=1; printf '  ÉCHEC %s\n' "$*"; }

# ── Skills ────────────────────────────────────────────────────────
#
# L'empreinte porte sur le contenu de tous les fichiers, pas sur le nombre de
# dossiers : une copie interrompue ou une racine restée sur l'ancienne version
# donne le même compte mais une empreinte différente.

printf 'Skills\n'

REFERENCE=""
for dir in "${SKILL_DIRS[@]}"; do
  label="$(short "$dir")"

  if [ ! -d "$dir" ]; then
    fail "$label — répertoire absent"
    continue
  fi

  count="$(find "$dir" -maxdepth 1 -type d -name "$PREFIX*" | wc -l | tr -d ' ')"
  fingerprint="$(cd "$dir" && find . -maxdepth 1 -type d -name "$PREFIX*" -exec find {} -type f \; \
    | sort | xargs shasum 2>/dev/null | shasum | cut -c1-12)"

  if [ "$count" -eq 0 ]; then
    fail "$label — aucune skill $PREFIX*"
    continue
  fi

  if [ -z "$REFERENCE" ]; then
    REFERENCE="$fingerprint"
    REF_LABEL="$label"
    REF_COUNT="$count"
    pass "$(printf '%-26s %2s bundles   %s (référence)' "$label" "$count" "$fingerprint")"
  elif [ "$fingerprint" = "$REFERENCE" ]; then
    pass "$(printf '%-26s %2s bundles   %s' "$label" "$count" "$fingerprint")"
  else
    fail "$(printf '%-26s %2s bundles   %s ≠ %s' "$label" "$count" "$fingerprint" "$REF_LABEL")"
  fi
done

# ── Agents ────────────────────────────────────────────────────────

printf '\nAgents\n'

check_agents() {
  local dir="$1" ext="$2" n
  n="$(find "$dir" -maxdepth 1 -type f -name "$PREFIX*.$ext" 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$n" -gt 0 ]; then
    pass "$(printf '%-26s %s agents (.%s)' "$(short "$dir")" "$n" "$ext")"
  else
    fail "$(printf '%-26s aucun agent .%s' "$(short "$dir")" "$ext")"
  fi
}

check_agents "$HOME/.claude/agents"    md
check_agents "$HOME/.codex/agents"     toml
check_agents "$HOME/.kimi-code/agents" md

# ── Hooks ─────────────────────────────────────────────────────────
#
# Trois conditions distinctes, qui échouent séparément : le fichier existe,
# il est déclaré, et Codex a le droit d'exécuter des hooks. Une seule qui
# manque suffit à ce que la mémoire projet ne se synchronise jamais — sans
# la moindre erreur affichée.

printf '\nHooks\n'

if [ -f "$HOOK_PATH" ]; then
  pass "$(short "$HOOK_PATH")"
else
  fail "$(short "$HOOK_PATH") — absent"
fi

# journal.cjs seul ne prouve rien : il charge hooks/lib/, et un lib/ manquant le
# fait sortir en silence comme le reste. Les deux sont donc vérifiés.
if [ -f "$TELEMETRY_HOOK" ] && [ -d "$TELEMETRY_DIR/lib" ]; then
  pass "$(short "$TELEMETRY_HOOK") (+ lib/)"
else
  fail "$(short "$TELEMETRY_HOOK") — absent ou amputé de lib/"
fi

check_declared() {
  local file="$1" label="$2" needle="$3"
  if [ ! -f "$file" ]; then
    fail "$label — $(short "$file") absent"
  # Antislashs retirés : JSON peut échapper les barres obliques (« \/ »), ce que
  # fait ~/.codex/hooks.json, et le chemin brut ne s'y retrouverait pas.
  elif tr -d '\\' < "$file" | grep -qF "$needle"; then
    pass "$label — déclaré dans $(short "$file")"
  else
    fail "$label — non déclaré dans $(short "$file")"
  fi
}

printf '\n  mémoire\n'
check_declared "$CLAUDE_SETTINGS" "Claude Code" "$HOOK_PATH"
check_declared "$CODEX_HOOKS"     "Codex"       "$HOOK_PATH"
check_declared "$AGY_SETTINGS"    "AGY"         "$HOOK_PATH"
check_declared "$KIMI_CONFIG"     "Kimi"        "$HOOK_PATH"

# Kimi et AGY sont absents volontairement : detectHost ne les reconnaît pas, une
# déclaration chez eux n'écrirait qu'un marqueur _unrecognised.jsonl.
printf '\n  télémétrie\n'
check_declared "$CLAUDE_SETTINGS" "Claude Code" "$TELEMETRY_HOOK"
check_declared "$CODEX_HOOKS"     "Codex"       "$TELEMETRY_HOOK"
printf '\n'

if awk '/^\[features\]/ { f = 1; next } /^\[/ { f = 0 } f && /^[[:space:]]*hooks[[:space:]]*=[[:space:]]*true/ { ok = 1 } END { exit !ok }' "$CODEX_CONFIG" 2>/dev/null; then
  pass "Codex — hooks activés dans $(short "$CODEX_CONFIG")"
else
  fail "Codex — hooks non activés dans $(short "$CODEX_CONFIG")"
fi

# ── Sonde ─────────────────────────────────────────────────────────
#
# Lancée depuis un répertoire quelconque : c'est justement ce qu'on vérifie,
# que l'installation est globale et pas liée à un projet.

if [ "$LIVE" -eq 1 ]; then
  printf '\nSonde (un appel modèle par CLI)\n'

  probe() {
    local label="$1"; shift
    local out
    if ! command -v "$1" >/dev/null 2>&1 && [ ! -x "$1" ]; then
      fail "$label — binaire introuvable"
      return
    fi
    out="$("$@" "$PROBE_PROMPT" 2>/dev/null | tr -d '`*[]()' )"
    local missing=""
    for f in $PROBE_EXPECT; do
      printf '%s' "$out" | grep -qF "$f" || missing="$missing $f"
    done
    if [ -z "$missing" ]; then
      pass "$label — les 3 actions retrouvées"
    else
      fail "$label — manquant :$missing"
    fi
  }

  probe "Claude Code" claude -p
  probe "Codex"       codex exec
  probe "Kimi"        "$HOME/.kimi-code/bin/kimi" -p
  probe "AGY"         "$HOME/.local/bin/agy" -p
else
  printf '\nSonde ignorée. Relance avec --live pour interroger réellement les quatre CLI.\n'
fi

# ── Bilan ─────────────────────────────────────────────────────────

printf '\n─────────────────────────────────────────────\n'
if [ "$FAILED" -eq 0 ]; then
  printf 'Installation cohérente.\n'
  [ "$LIVE" -eq 0 ] && printf 'Le disque est bon ; une CLI non redémarrée peut malgré tout ne rien voir.\n'
  exit 0
fi

printf 'Des écarts ont été relevés.\n\n'
printf '  empreintes divergentes ou skills manquantes  ->  ./install.sh\n'
printf '  hook non déclaré                             ->  ./install.sh affiche le bloc à coller\n'
printf '  disque correct mais sonde en échec           ->  redémarre la CLI concernée\n'
exit 1
