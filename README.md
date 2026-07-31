# dev-with-ai

Ma configuration de développement avec agents IA — **une seule source de vérité**, partagée entre Claude Code et Codex.

Écrire une règle ou une commande une fois, et l'avoir dans les deux outils. C'est tout l'objet de ce repo.

## Comment ça marche

Les règles sont partagées par liens symboliques. Les commandes restent la source de vérité :
Claude Code les lit directement et le script d'installation génère les skills Codex correspondants.

```
AI-rules/me.md       ──┬──→  ~/.claude/CLAUDE.md
                       └──→  ~/.codex/AGENTS.md

AI-rules/commands/   ──┬──→  ~/.claude/commands/
                       └──→  ~/.codex/skills/<nom>/SKILL.md   (généré par install.sh)

AI-rules/agents/     ──────→  ~/.claude/agents/                Claude Code uniquement
AI-rules/hooks/      ──────→  ~/.claude/hooks/                 Claude Code uniquement
```

Conséquence : une nouvelle commande reste écrite une seule fois. Elle est immédiatement
disponible dans Claude Code ; il faut relancer `install.sh` puis redémarrer Codex pour
regénérer et recharger le skill.

Les sous-agents et les hooks n'ont pas d'équivalent Codex. Une commande qui délègue à un
sous-agent reste donc utilisable dans les deux outils : `install.sh` injecte la méthode du
sous-agent dans le skill Codex, qui l'applique lui-même. Voir « Déléguer sans casser Codex ».

## Installation

```bash
cd AI-rules && ./install.sh
```

Le script est idempotent et refuse d'écraser un fichier existant non vide.

## Les commandes

| Commande | Quand | Ce qu'elle fait |
|---|---|---|
| `rules` | Une fois par projet | Analyse le code réel et génère le `CLAUDE.md` + `AGENTS.md` du projet |
| `explain` | Code inconnu ou surprenant | Explique un fichier, une fonction ou un extrait, en lecture seule |
| `spec` | Avant une vraie feature | Cadre l'implémentation, produit `ai/specs/<feature>.spec.md` |
| `test-setup` | Une fois par projet | Met en place le runner et le premier filet, après validation |
| `test-write` | Avant ou après le code d'un module | Conçoit les cas depuis la spec, me les fait valider, puis les écrit |
| `verify` | Quand l'agent dit « c'est fini » | Lance les vraies gates du projet et rapporte la sortie brute |
| `clean-commit` | Avant de commiter | Nettoyage, secrets, gates, message conventionnel |
| `context` | Blocage ou changement d'outil | Point de situation dans `ai/context/`, pour reprendre à froid |

Dans Claude Code, une commande s'invoque avec `/nom`. Dans Codex, le skill
correspondant s'invoque avec `$nom` ou depuis le sélecteur de skills.

### La chaîne

```
/rules        une fois par projet — les conventions réelles, écrites
/test-setup   une fois par projet — de quoi faire échouer une régression

/spec         la règle métier, en français, avant le code
  ↓           sa section « Tests » est la source de vérité de l'étape suivante
/test-write   conception des cas → ⏸ je relis 20 lignes → écriture → exécution
  ↓
[ code ]      l'implémentation, en session normale
  ↓
/verify       typecheck → lint → format → test → build, résultat brut
  ↓           la gate test compte les tests : une suite vide n'est plus un vert
/clean-commit secrets, gates, staging fichier par fichier, message conventionnel
```

Le point d'arrêt de `/test-write` est le seul endroit où la relecture humaine est vraiment
rentable : vingt lignes de cas en français plutôt que trois cents lignes de code de test.

Hors chaîne, à la demande : le sous-agent `test-gap` avant une mise en production,
`/explain` sur du code hérité, `/context` en cas de blocage.

### Le bon dosage

Le workflow complet ne se déroule pas pour tout. C'est même la moitié du gain de temps :

| Tâche | Ce qu'on lance |
|---|---|
| Correction, ajustement, petit fix | Rien, puis `/clean-commit` |
| Feature réelle, refacto structurant | `/spec` → `/test-write` → travail → `/verify` → `/clean-commit` |
| Feature sans logique métier (UI, contenu) | `/spec` → travail → `/verify` → `/clean-commit` |
| Nouveau projet | `/rules` puis `/test-setup`, une fois |
| Avant une mise en production | sous-agent `test-gap` |
| Blocage ou passage Claude ↔ Codex | `/context` |
| Code repris, hérité ou surprenant | `/explain` |

`/test-write` sur un composant d'affichage ou une page statique ne vaut pas son coût :
la commande te le dira elle-même plutôt que de produire des tests de remplissage.

## Les deux niveaux de règles

| Niveau | Fichier | Contenu |
|---|---|---|
| **Global** | `AI-rules/me.md` | Qui je suis, comment je veux qu'on travaille. Stable, vrai partout. |
| **Projet** | `CLAUDE.md` à la racine du projet | Stack, arborescence, vraies commandes, pièges. Généré par `/rules`. |

Les deux se cumulent automatiquement, et le niveau projet prime.
Le fichier projet ne se symlinke pas vers ce repo : chaque projet a le sien, avec ses spécificités. Côté projet, `/rules` fait pointer `AGENTS.md` vers `CLAUDE.md` pour la même raison qu'ici — un seul fichier à maintenir.

## Les sous-agents

Claude Code uniquement. Un sous-agent travaille dans sa propre fenêtre de contexte :
ce qu'il lit ne remonte pas dans la conversation principale, seul son rapport revient.

| Sous-agent | Rôle | Déclenchement |
|---|---|---|
| `test-designer` | Conçoit les cas de test **à partir de la spec**, jamais du code | Appelé par `/test-write` |
| `test-gap` | Audite la couverture, trie les trous par coût de l'erreur | À la demande, avant une mise en production |

Les deux sont en `Read, Grep, Glob` strictement : aucun n'écrit. Ils n'imposent pas de modèle,
ils héritent de celui de la session.

Vérifie leur présence avec `/agents` **après avoir redémarré Claude Code** : le watcher ne
surveille que les répertoires existant au démarrage de la session, un répertoire créé après
reste invisible.

Pourquoi les cas viennent de la spec et pas du code : un agent qui déduit quoi tester en
lisant l'implémentation encode le comportement actuel, bugs compris. Il produit des tests
verts qui certifient le bug. Sans spec, `test-designer` le dit et marque ses cas
`[DESCRIPTIF]` — filet de régression, pas vérification.

## Le hook

`hooks/protect-tests.sh` empêche l'agent de modifier, réécrire ou supprimer un fichier de
test existant. Créer un nouveau test reste autorisé.

Mis en boucle sur « fais passer les tests », un agent finit statistiquement par affaiblir
l'assertion plutôt que corriger le code. Une règle en langage naturel est une incitation ;
un hook est une contrainte.

Il couvre `Edit`, `Write`, `NotebookEdit` et `Bash` — ce dernier par heuristique
(`sed -i`, redirection, `rm`, `mv`, `git restore`). Ce n'est pas une frontière de sécurité :
une commande suffisamment tordue passe. C'est un garde-fou contre la dérive ordinaire.

Le verrou se lève à la main, jamais par l'agent :

```bash
touch .claude/.allow-test-edits    # puis rm quand c'est fini
```

Toute commande contenant `allow-test-edits` est bloquée, pour que l'agent ne puisse pas
lever sa propre contrainte.

`install.sh` pose le fichier mais ne modifie pas ton `settings.json` : il affiche le bloc à
coller, et la commande pour vérifier que le hook bloque réellement. Un hook de gating qui
semble marcher sans rien bloquer est le pire des deux mondes. Il dépend de `jq` ; sans lui
il se désactive en le signalant.

## Ajouter une commande

1. Créer `AI-rules/commands/<nom>.md`
2. Frontmatter minimal, compatible avec les deux outils :

```markdown
---
description: Ce que fait la commande
argument-hint: [ce qu'on peut passer après]
---

Les instructions. "$ARGUMENTS" reçoit ce qui est tapé après la commande.
```

Elle est immédiatement disponible via `/<nom>` dans Claude Code. Relancer ensuite
`AI-rules/install.sh` et redémarrer Codex pour disposer de `$nom`.

Une commande mérite d'exister si elle encode une checklist qu'on oublierait, impose un format, ou contraint l'agent. Si elle se résume à « fais le travail correctement », c'est un prompt normal.

## Commande ou skill ?

- **Commande Claude Code** : déclenchement explicite via `/nom`.
- **Skill Codex** : déclenchement explicite via `$nom`, ou implicite selon la description.

Le contenu métier reste commun, mais les mécanismes d'intégration diffèrent. Le script
convertit le frontmatter Claude Code vers le frontmatter minimal attendu par Codex et
retire le placeholder `$ARGUMENTS`, qui n'existe pas dans les skills.

## Déléguer sans casser Codex

Codex n'a pas de sous-agents. Une commande qui délègue serait donc inutilisable — ou il
faudrait dupliquer la méthode du sous-agent dans la commande, et maintenir deux textes.

À la place, un marqueur en fin de commande :

```markdown
<!-- fallback:agents/test-designer.md -->
```

Claude Code n'y voit qu'un commentaire HTML et délègue au vrai sous-agent. `install.sh`, en
générant le skill Codex, remplace la ligne par le contenu du sous-agent, sous un titre
d'annexe. Le skill reste autonome, et la méthode n'existe qu'à un seul endroit.

Le fichier référencé est relatif à `AI-rules/`. S'il est introuvable, la génération le
signale sur stderr au lieu de produire un skill amputé en silence.

## Structure

```
dev-with-ai/
├── README.md
└── AI-rules/
    ├── me.md              # règles globales
    ├── commands/          # les commandes, partagées Claude Code + Codex
    ├── agents/            # sous-agents, Claude Code uniquement
    ├── hooks/             # contraintes mécaniques, Claude Code uniquement
    ├── install.sh         # pose les liens et génère les skills Codex
    └── ARCHIVES/          # version OpenCode, pour référence
```

## À personnaliser

`me.md` a été écrit à partir de ce qui était connu (stack TypeScript/React + Node, travail en français). Deux choses valent d'y être ajoutées quand l'occasion se présente :

- ton contexte de travail — freelance, clients, types de projets récurrents ;
- les corrections que tu te surprends à répéter à l'IA. C'est le meilleur indicateur d'une règle manquante.
