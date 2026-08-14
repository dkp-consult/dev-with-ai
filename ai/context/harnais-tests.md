# Harnais — brique test : point de reprise

Session du 2026-07-31. Intégration du dossier `harnais/` dans `AI-rules/`.
Commits `d041d46` et `0b2d3e2`, poussés sur `origin/main`.

---

## Référence — tout ce qui est disponible

### Commandes

Claude Code : `/nom`. Codex : `$nom`, ou depuis le sélecteur de skills.
Source unique : `AI-rules/commands/<nom>.md`.

| Commande | Quand | Ce qu'elle fait |
|---|---|---|
| `rules` | Une fois par projet | Analyse le code réel, génère le `CLAUDE.md` + `AGENTS.md` du projet |
| `test-setup` | Une fois par projet | Runner de test + premier filet. Point d'arrêt avant toute installation |
| `spec` | Avant une vraie feature | Produit `ai/specs/<feature>.spec.md`. Sa section Tests nourrit `test-write` |
| `test-write` | Avant ou après le code d'un module | Conçoit les cas, me les fait valider, puis les écrit |
| `verify` | Quand l'agent dit « c'est fini » | Gates réelles, sortie brute, comptage des tests |
| `clean-commit` | Avant de commiter | Nettoyage, secrets, gates, staging, message conventionnel |
| `explain` | Code inconnu ou surprenant | Explique un fichier ou un extrait, lecture seule |
| `context` | Blocage ou changement d'outil | Point de situation dans `ai/context/` |

### Sous-agents — Claude Code uniquement

Source : `AI-rules/agents/`. Tous en `Read, Grep, Glob`, aucun n'écrit.

| Sous-agent | Rôle | Déclenchement |
|---|---|---|
| `test-designer` | Conçoit les cas de test à partir de la spec, jamais du code | Appelé par `/test-write` |
| `test-gap` | Audite la couverture, trie les trous par coût de l'erreur | À la demande, avant une mise en production |
| `Explore` | Cartographie de codebase (intégré à Claude Code) | Appelé par `/spec` |

Codex n'a pas de sous-agents. `install.sh` injecte la méthode de `test-designer`
dans le skill `test-write` généré, via le marqueur `<!-- fallback:agents/test-designer.md -->`.

### Hook — Claude Code uniquement

`AI-rules/hooks/protect-tests.sh` — posé et lié, **volontairement non déclaré**. Voir plus bas.

### La chaîne

```
/rules  +  /test-setup     une fois par projet
/spec  →  /test-write  →  [ code ]  →  /verify  →  /clean-commit
```

Dosage : un petit fix ne mérite que `/clean-commit`. `/test-write` sur de la
présentation pure ne vaut pas son coût, la commande le dira elle-même.

---

## Ce qu'il me reste à faire

- [ ] **Redémarrer Claude Code**, puis `/agents` — doit lister `test-designer` et `test-gap`.
      Sans redémarrage, le watcher ne voit pas `~/.claude/agents`, créé après le début de session.
- [ ] **Redémarrer Codex**, puis vérifier que `$test-write` apparaît dans le sélecteur.
- [ ] `rm -rf harnais` — le paquet source, absorbé dans `AI-rules/`. Non versionné, laissé exprès.
- [ ] **Premier passage réel** sur un projet à logique métier pure (calcul, validation, parsing),
      de préférence avec un cahier des charges — sinon `test-designer` produira du `[DESCRIPTIF]` :
      ```
      /test-setup
      /test-write src/<module>.ts — <chemin de la spec>
      /verify
      ```
- [ ] Après ce premier passage : ajuster la granularité de `test-designer`. Trop de cas ou pas assez
      se corrige dans la contrainte de nombre de son prompt (`AI-rules/agents/test-designer.md`,
      section Contraintes), pas en reformulant les invocations.

### À vérifier au premier usage — deux incertitudes assumées

1. **`allowed-tools`** — `spec.md` et `test-write.md` déclarent `Task, Agent`, le nom de l'outil
   d'invocation de sous-agent ayant changé selon les versions de Claude Code. Si la délégation
   échoue silencieusement, retirer la ligne `allowed-tools` de la commande concernée.
2. **Le symlink `~/.claude/agents`** — les commandes fonctionnent déjà par symlink, le mécanisme
   devrait être identique, non confirmé sans redémarrage.

---

## Décisions prises, et pourquoi

**Le hook n'est pas activé.** Il protège des fichiers de test existants ; la plupart des projets
n'en ont pas encore. Verrou sur un coffre vide. En attendant, la règle est dans `me.md` et
`/clean-commit` isole les modifications de tests dans un commit `test:` séparé — visible en
relecture. Ce qui reste non couvert : la dérive statistique d'un agent en boucle longue sur
« fais passer les tests ».

Moment de l'activer : quand deux ou trois projets ont une vraie suite, ou quand je commence à
laisser tourner l'agent en autonomie longue.

**`explorateur` écarté.** L'agent `Explore` intégré à Claude Code fait la même chose. `/spec`
le mentionne, sans créer de fichier.

**`test-setup` a un point d'arrêt** avant toute installation. La version d'origine installait
Vitest et modifiait `package.json` sans rien demander, contre mes propres limites.

**Le bloc `permissions` du harnais a été écarté.** Il avait un trou : `Read(**/.env)` en `deny`
mais `Bash(cat:*)` en `allow` — les règles sont par outil, `cat .env` passe. À retravailler
séparément si je veux des permissions.

---

## Activer le hook plus tard

Le fichier est déjà posé et lié. Il ne manque que la déclaration dans `~/.claude/settings.json`,
tableau `hooks.PreToolUse`, en deuxième entrée après vibe-island :

```json
  {
    "matcher": "Edit|Write|NotebookEdit|Bash",
    "hooks": [
      { "type": "command", "command": "$HOME/.claude/hooks/protect-tests.sh" }
    ]
  }
```

Contrôles, dans l'ordre :

```bash
jq -e '.hooks.PreToolUse | length' ~/.claude/settings.json    # doit répondre 2

touch /tmp/x.test.ts
printf %s '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/x.test.ts"}}' \
  | ~/.claude/hooks/protect-tests.sh ; echo "exit=$?"          # message + exit=2
```

Puis, après redémarrage, le seul contrôle qui prouve le câblage : demander en session
« ajoute un commentaire dans `<un fichier>.test.ts` » sur un projet qui a des tests.
Le blocage doit remonter. Si l'agent écrit sans broncher, `/hooks` dira ce qui a été chargé.

Le hook couvre `Edit`, `Write`, `NotebookEdit` et `Bash` — ce dernier par heuristique
(`sed -i`, redirection, `rm`, `mv`, `git restore`). Ce n'est pas une frontière de sécurité.
Levée du verrou, humaine seulement : `touch .claude/.allow-test-edits`, puis `rm`.
Toute commande contenant `allow-test-edits` est bloquée, pour que l'agent ne lève pas
sa propre contrainte.

---

## Ce qui reste ouvert

**La review.** Seul maillon de la chaîne sans commande. Claude Code a `/code-review` et
`/security-review` intégrés, Codex n'a pas d'équivalent — une commande `/review` partagée
aurait du sens. Hors périmètre de cette session, à décider.

**Les gates de ce repo.** `dev-with-ai` n'a ni `package.json`, ni `Makefile`, ni CI. Les
vérifications lancées pendant la session étaient ad hoc et ont disparu avec elle :
`bash -n` sur les deux scripts, 14 cas de test du hook, install à blanc dans un `HOME`
isolé, contrôle du frontmatter des 8 commandes. Les figer dans un `Makefile` ou un
workflow GitHub Actions est le prolongement naturel.

**Bootstrap.** Une fois `/test-setup` rodé sur trois projets, figer le résultat dans un
template de départ. La meilleure brique de harnais est celle qu'on n'a jamais besoin d'invoquer.

---

## Où vit quoi

```
AI-rules/
├── me.md              règles globales    → ~/.claude/CLAUDE.md, ~/.codex/AGENTS.md
├── commands/          8 commandes        → ~/.claude/commands/, skills Codex générés
├── agents/            2 sous-agents      → ~/.claude/agents/          Claude Code seul
├── hooks/             protect-tests.sh   → ~/.claude/hooks/           Claude Code seul
└── install.sh         idempotent, relançable sans risque
```

Tout est en symlink sauf les skills Codex, qui sont générés : éditer un fichier dans
`AI-rules/` suffit pour Claude Code, mais il faut relancer `install.sh` et redémarrer
Codex pour que le skill correspondant soit à jour.
