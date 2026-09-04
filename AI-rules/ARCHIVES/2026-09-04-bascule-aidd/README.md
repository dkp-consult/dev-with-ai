# Bascule vers AIDD — 4 septembre 2026

Le harnais de ce dépôt a été désinstallé de la configuration globale au profit
du framework [AIDD](https://github.com/ai-driven-dev/framework), installé en
plugins Claude Code.

**Rien n'est perdu.** `AI-rules/` reste versionné et intact : commandes, agents,
hooks, `me.md`, `install.sh`. Seule l'installation — les liens symboliques dans
`~/.claude` et `~/.codex` — a été retirée. `claude-harness-20260904-170518.tar.gz`
est un instantané de l'état vécu juste avant le retrait, pour ce que le dépôt ne
contient pas : le `settings.json` global et les skills Codex générés.

## Pourquoi

Quinze des dix-huit commandes doublonnaient un skill AIDD :

| Ici | AIDD |
|---|---|
| `cdc`, `cdd`, `spec` | `aidd-pm` 03-prd, 04-spec, 07-epic, 10-task |
| `review` | `aidd-dev` 05-review |
| `test-write`, `test-gap`, `test-setup` | `aidd-dev` 06-test, 03-assert |
| `verify` | `aidd-dev` 09-for-sure |
| `clean-commit` | `aidd-vcs` 01-commit |
| `issue-capture` | `aidd-vcs` 04-issue-create |
| `context` | `aidd-context` 02-project-memory |
| `explain` | `aidd-context` 10-learn, 11-explore |
| `e2e` | `aidd-dev` 11-browser-qa |
| `rules` | `aidd-context` 05-rule-generate |

Les skills se déclenchent aussi sur leur description, pas seulement à
l'invocation. Deux candidats pour « écris la spec », c'est une sélection non
déterministe qu'on ne voit pas passer. C'est ça qui a tranché, pas la qualité
respective des deux jeux.

Sans équivalent AIDD, donc perdus par cette bascule : `issue-start`,
`issue-pause`, `issue-finish` (la boucle issue-GitHub-comme-contrat, avec
`session-start.sh`) et `deps-audit`. Ainsi que les frontières d'écriture par
agent de `scope-guard.sh` — elles dispatchent sur `agent_type ∈ {analyst, dev,
tester, reviewer}`, et les agents AIDD sont `checker` et `executor`.

## Ce qui a été retiré

| Quoi | Détail |
|---|---|
| 5 liens symboliques | `~/.claude/{CLAUDE.md,commands,agents,hooks}`, `~/.codex/AGENTS.md` |
| 18 skills Codex | ceux portant le marqueur `managed by dev-with-ai/AI-rules/install.sh` |
| 2 déclarations de hooks | `scope-guard.sh` (PreToolUse) et `session-start.sh` (SessionStart) dans `~/.claude/settings.json` |
| 4 copies de settings | `settings.json.bak-*`, `settings.local.json.avant-*` |

Laissés intacts dans `~/.claude/settings.json` : vibe-island, `statusLine`,
`theme`, `tui`, `alwaysThinkingEnabled`, et toute la politique de permissions
(33 `allow`, 14 `deny`, `additionalDirectories`).

## Ce qui l'a remplacé

Dans `~/.claude/settings.json`, marketplace local et six plugins — `aidd-ui` est
exclu, marqué ALPHA et `recommended: false` :

```json
"extraKnownMarketplaces": {
  "aidd-framework": {
    "source": { "source": "directory", "path": "/Users/dkp/dev/framework" }
  }
},
"enabledPlugins": {
  "aidd-context@aidd-framework": true,
  "aidd-dev@aidd-framework": true,
  "aidd-vcs@aidd-framework": true,
  "aidd-pm@aidd-framework": true,
  "aidd-orchestrator@aidd-framework": true,
  "aidd-refine@aidd-framework": true
}
```

## Contenu de l'archive

```
claude-harness-20260904-170518/
├── MANIFEST.md              ce document, version courte
├── symlinks-avant.txt       la carte des liens avant retrait
├── claude/
│   ├── settings.json        le global vécu, AVANT retrait des hooks
│   ├── settings.local.json
│   ├── settings.json.bak-*  les copies antérieures
│   ├── CLAUDE.md            contenu résolu (= AI-rules/me.md)
│   ├── commands/            contenu résolu (18 fichiers)
│   ├── agents/              contenu résolu (4 fichiers)
│   └── hooks/               contenu résolu (4 fichiers)
├── codex/
│   ├── AGENTS.md            contenu résolu (= AI-rules/me.md)
│   └── skills/              les 18 skills générés
└── repo/
    ├── HEAD.txt             le commit de base
    ├── uncommitted.patch    le travail non committé au moment du retrait
    └── untracked/           les fichiers non suivis au moment du retrait
```

Aucun secret : `~/.codex/auth.json` et tout fichier porteur d'identifiant sont
exclus par construction. Vérifié avant archivage.

## Réinstallation

### Tout remettre

```bash
tar -xzf AI-rules/ARCHIVES/2026-09-04-bascule-aidd/claude-harness-20260904-170518.tar.gz  # optionnel, pour comparer
./AI-rules/install.sh
```

`install.sh` est idempotent : il repose les liens, régénère les skills Codex, et
refuse d'écraser un fichier existant non vide. Il **n'écrit jamais** dans
`settings.json` — il affiche les deux blocs de hooks à coller.

Puis, dans `~/.claude/settings.json`, ajouter au tableau `hooks.PreToolUse` :

```json
{
  "matcher": "Edit|Write|NotebookEdit|Bash",
  "hooks": [
    { "type": "command", "command": "$HOME/.claude/hooks/scope-guard.sh" }
  ]
}
```

et au tableau `hooks.SessionStart` :

```json
{
  "hooks": [
    { "type": "command", "command": "$HOME/.claude/hooks/session-start.sh", "timeout": 15 }
  ]
}
```

Vérifier que le hook bloque réellement — un hook qui laisse tout passer est pire
que pas de hook :

```bash
printf %s '{"agent_type":"dev","tool_name":"Write","tool_input":{"file_path":"a.test.ts"}}' \
  | ~/.claude/hooks/scope-guard.sh ; echo "exit=$?"
# attendu : blocage hors périmètre, exit=2
```

Redémarrer Claude Code : le watcher ne voit pas un répertoire créé après le
démarrage de la session. Vérifier avec `/agents` et `/hooks`.

### Remettre une pièce seulement

Les règles globales — français, contexte belge, limites strictes (demander avant
de committer, avant d'installer une dépendance, avant de toucher à l'infra),
règle sur les secrets. AIDD ne couvre rien de ça, et son `CLAUDE.md` est au
niveau projet :

```bash
ln -s ~/dev/dev-with-ai/AI-rules/me.md ~/.claude/CLAUDE.md
```

Le plancher push seul. Le `deny` de `settings.json` raisonne sur un préfixe :
`git push --force` est bloqué, `git push origin main --force` ne l'est pas. Et un
hook s'exécute même sous `--dangerously-skip-permissions`, le mode des runs
async AIDD :

```bash
ln -s ~/dev/dev-with-ai/AI-rules/hooks ~/.claude/hooks
# puis la déclaration PreToolUse ci-dessus
```

Les commandes sans doublon AIDD, sans réinstaller les quinze autres :

```bash
mkdir -p ~/.claude/commands
for c in issue-start issue-pause issue-finish deps-audit; do
  ln -s ~/dev/dev-with-ai/AI-rules/commands/$c.md ~/.claude/commands/$c.md
done
```

### Restaurer le `settings.json` global tel quel

Écrase aussi ce qui a changé depuis — vibe-island, permissions, plugins AIDD.
À comparer avant, jamais à appliquer à l'aveugle :

```bash
tar -xzf claude-harness-20260904-170518.tar.gz
diff <(jq -S . claude-harness-20260904-170518/claude/settings.json) <(jq -S . ~/.claude/settings.json)
```
