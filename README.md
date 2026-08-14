# dev-with-ai

Ma configuration de développement avec agents IA — **une seule source de vérité**, partagée entre Claude Code et Codex.

Écrire une règle, une commande ou un agent une fois, et l'avoir partout où c'est possible. C'est tout l'objet de ce repo.

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
AI-rules/methods/    ──────→  injecté dans les skills Codex     (voir « Déléguer sans casser Codex »)
```

Conséquence : une nouvelle commande reste écrite une seule fois. Elle est immédiatement
disponible dans Claude Code ; il faut relancer `install.sh` puis redémarrer Codex pour
regénérer et recharger le skill.

Les agents et les hooks n'ont pas d'équivalent Codex. Une commande qui délègue à un
agent reste donc utilisable dans les deux outils : `install.sh` injecte la méthode
correspondante dans le skill Codex, qui l'applique lui-même.

## Les deux couches

C'est la distinction qui structure tout le reste, et elle ne se remplace pas :

- **Une commande est un protocole.** Une séquence, des points d'arrêt, un format de sortie.
  Source de vérité unique, partagée Claude Code + Codex.
- **Un agent est un exécutant.** Un contexte isolé, une frontière d'écriture dure, un rapport
  de mission. Claude Code uniquement, surcouche pure.

Une commande sans agent reste utilisable. Un agent sans sa commande n'existe pas.

## Installation

```bash
cd AI-rules && ./install.sh
```

Le script est idempotent et refuse d'écraser un fichier existant non vide. Il affiche
ensuite le bloc de déclaration du hook à coller dans `~/.claude/settings.json`, et la
commande pour vérifier qu'il bloque réellement.

Redémarre Claude Code après : le watcher ne voit pas un répertoire créé après le
démarrage de la session. Vérifie ensuite avec `/agents` et `/hooks`.

## Les commandes

| Commande | Quand | Ce qu'elle fait |
|---|---|---|
| `cdc` | Au démarrage d'un projet | Le cahier des charges — le quoi et le pourquoi. POC optionnel |
| `cdd` | Après le cahier des charges | Le cahier de dev — jalons, étapes, dépendances |
| `rules` | Une fois par projet | Analyse le code réel et génère le `CLAUDE.md` + `AGENTS.md` du projet |
| `explain` | Code inconnu ou surprenant | Explique un fichier, une fonction ou un extrait, en lecture seule |
| `spec` | Avant une vraie feature | Cadre l'implémentation, produit `ai/specs/<feature>.spec.md` |
| `test-setup` | Une fois par projet | Met en place le runner et le premier filet, après validation |
| `test-write` | Avant ou après le code d'un module | Conçoit les cas depuis la spec, me les fait valider, puis les écrit |
| `test-gap` | Avant une mise en production | Audite la couverture réelle, trie les trous par coût de l'erreur |
| `e2e` | Feature avec un parcours utilisateur | Tests de bout en bout, Playwright |
| `verify` | Quand l'agent dit « c'est fini » | Lance les vraies gates du projet et rapporte la sortie brute |
| `review` | Fin d'étape ou de jalon | Relit le diff contre la spec et les conventions. Constate, ne corrige pas |
| `deps-audit` | Après une installation, avant une prod | CVE, scripts non approuvés, signaux de typosquat |
| `clean-commit` | Avant de commiter | Nettoyage, secrets, gates, message conventionnel |
| `context` | Blocage ou changement d'outil | Point de situation dans `ai/context/`, pour reprendre à froid |
| `issue-capture` | Une idée surgit pendant autre chose | Crée l'issue en vingt secondes et te renvoie au chantier |
| `issue-start` | Début ou reprise d'un chantier | Dépendances, écart contrat ↔ code réel, plan de session, branche |
| `issue-pause` | Fin de session | Poste le point de reprise sur l'issue |
| `issue-finish` | Le chantier est terminé | Critères un par un, gates, découpage en commits, PR en draft |

Dans Claude Code, une commande s'invoque avec `/nom`. Dans Codex, le skill
correspondant s'invoque avec `$nom` ou depuis le sélecteur de skills.

### Les trois niveaux de document

À ne pas confondre — c'est la confusion la plus fréquente et la plus coûteuse :

| Document | Répond à | Ne contient pas |
|---|---|---|
| `ai/cdc.md` | Où veut-on arriver, et pourquoi | Aucune techno, aucun fichier |
| `ai/cdd.md` | Dans quel ordre, en combien de jalons, quoi dépend de quoi | Le détail d'implémentation |
| `ai/specs/*.spec.md` | Comment on construit **cette** étape | Le code lui-même |

Si une spec se retrouve à décrire l'objectif du projet, ou un cahier des charges à citer
des fichiers, on est au mauvais niveau.

### La chaîne

```
/cdc          le problème, le périmètre, le HORS périmètre
  ↓
/cdd          jalons, étapes, dépendances — l'état d'avancement vit ici
  ↓
/rules        une fois par projet — les conventions réelles, écrites
/test-setup   une fois par projet — de quoi faire échouer une régression
  ↓
/spec         la règle métier, en français, avant le code
  ↓           sa section « Tests » est la source de vérité de l'étape suivante
/test-write   conception des cas → ⏸ je relis 20 lignes → écriture → exécution
  ↓
[ code ]      l'implémentation, en session normale ou déléguée à l'agent dev
  ↓
/verify       typecheck → lint → format → test → build, résultat brut
  ↓           la gate test compte les tests : une suite vide n'est pas un vert
/review       le diff contre son contrat — constate, ne corrige pas
  ↓
/clean-commit secrets, gates, staging fichier par fichier, message conventionnel
```

Le point d'arrêt de `/test-write` est le seul endroit où la relecture humaine est vraiment
rentable : vingt lignes de cas en français plutôt que trois cents lignes de code de test.

### Le bon dosage

Le workflow complet ne se déroule pas pour tout. C'est même la moitié du gain de temps :

| Tâche | Ce qu'on lance |
|---|---|
| Correction, ajustement, petit fix | Rien, puis `/clean-commit` |
| Feature réelle, refacto structurant | `/spec` → `/test-write` → travail → `/verify` → `/clean-commit` |
| Feature sans logique métier (UI, contenu) | `/spec` → travail → `/verify` → `/clean-commit` |
| Nouveau projet | `/cdc` → `/cdd`, puis `/rules` et `/test-setup` |
| Avant une mise en production | `/test-gap` puis `/deps-audit` |
| Blocage ou passage Claude ↔ Codex | `/context` |
| Code repris, hérité ou surprenant | `/explain` |
| Chantier sur plusieurs sessions | `/issue-start` → travail → `/issue-pause` → … → `/issue-finish` |

`/test-write` sur un composant d'affichage ou une page statique ne vaut pas son coût :
la commande te le dira elle-même plutôt que de produire des tests de remplissage.

## Les agents

Claude Code uniquement. Un agent travaille dans sa propre fenêtre de contexte :
ce qu'il lit ne remonte pas dans la conversation principale, seul son rapport revient.

| Agent | Rôle | Écrit | Mode |
|---|---|---|---|
| `analyst` | Cadre, challenge, rédige les documents | `ai/**` (hors rapports) · `*.md` | session `--agent` |
| `dev` | Implémente **une** étape d'une spec validée | code source · son rapport | sous-agent |
| `tester` | Conçoit, audite et écrit les tests | tests, configs de test · son rapport | sous-agent |
| `reviewer` | Relit un diff | son rapport seul | sous-agent |

**Aucun agent ne peut écrire là où un autre écrit, et aucun ne juge ce qu'il produit.**
`analyst` ne code pas ce qu'il spécifie. `dev` ne teste pas ce qu'il code. `tester` ne
corrige pas le code qu'il fait échouer. `reviewer` ne répare pas ce qu'il critique.

Tout ce qui traverse une frontière passe par moi, via un rapport de mission. C'est le
seul point de couplage du système, et il est volontaire.

### `analyst` se lance en session, pas en sous-agent

```bash
claude --agent analyst
```

`AskUserQuestion` est retiré de tout sous-agent : un sous-agent ne dialogue pas, il part
et rend un rapport. Comme l'intérêt de l'analyst est justement d'échanger — qu'il conteste
l'idée, qu'on en discute — il tourne comme session principale. Il y garde ses frontières
d'écriture, ses hooks et son prompt de challenger.

Sa fonction première est de **contredire**. S'il se contente de mettre en forme ce qu'on
lui dit, il ne sert à rien : on écrit plus vite que lui.

### Fin de mission

Tout sous-agent s'arrête et rapporte dans quatre cas : mission accomplie ; spec fausse,
contradictoire ou muette ; décision qui ne lui appartient pas ; gate en échec hors de son
périmètre.

**Un rapport « bloqué » est un succès.** Une mission terminée en ayant tranché à ma place
est un échec, même si le code marche.

### Les rapports

Chaque agent écrit dans son propre dossier, jamais dans celui d'un autre :

```
ai/reports/dev/jalon-3/2026-08-14-1530-etape-3-1.md
ai/reports/tester/jalon-3/2026-08-14-1605-etape-3-1.md
ai/reports/reviewer/jalon-3/2026-08-15-0930-revue.md
```

Agent → jalon → étape horodatée. L'horodatage vient de `date`, jamais de l'invention du
modèle. Le tri alphabétique donne le tri chronologique.

Le rapport complet va dans le fichier, un résumé de cinq lignes en sortie de conversation.
La boucle de retour devient un chemin plutôt qu'un copier-coller :

```bash
claude --agent analyst
# « lis ai/reports/dev/jalon-3/2026-08-14-1530-etape-3-1.md »
```

**`ai/` est versionné.** Contrats et rapports suivent le dépôt d'une machine à l'autre.
Conséquence directe : tout ce qui s'y écrit part dans un commit, donc les agents masquent
les secrets par `[REDACTED]`. Un secret dans un fichier local se supprime ; dans
l'historique Git, non.

Un jalon livré peut voir son dossier de rapports supprimé : l'information utile a déjà
rejoint les commits, les specs et la PR.

### Pourquoi les cas de test viennent de la spec

Un agent qui déduit quoi tester en lisant l'implémentation encode le comportement actuel,
bugs compris. Il produit des tests verts qui certifient le bug. Sans spec, `tester` le dit
et marque ses cas `[DESCRIPTIF]` — filet de régression, pas vérification.

C'est aussi pourquoi `tester` lit un rapport du `dev` pour savoir **ce qui** a été fait,
jamais **comment**.

## Les hooks

### `scope-guard.sh`

Le garde-fou central. Déclaré **une seule fois** en `PreToolUse` global, il dispatche sur
le champ `agent_type` que Claude Code place dans l'entrée du hook :

```
analyst   → docs-only       ai/** hors reports, *.md
dev       → code-only       code source, ai/reports/dev/
tester    → tests-only      tests, configs de test, package.json, ai/reports/tester/
reviewer  → reports-only    ai/reports/reviewer/ seulement
(autre)   → protect-tests   tout sauf les fichiers de test existants
```

**Pourquoi en global plutôt que dans le frontmatter de chaque agent** : un agent créé plus
tard sans déclaration tombe dans le cas par défaut, donc protégé. Le frontmatter fait
l'inverse — l'oubli ouvre. Un harnais dont l'oubli ferme est le seul qui tienne dans le temps.

Il applique aussi deux règles mécaniquement plutôt que par prompt : l'**allowlist des
paquets de test** (`pnpm add -D vitest-dom-helper` est refusé) et l'obligation
d'`--ignore-scripts` sur npm et yarn. Un nom de paquet plausible mais inconnu est le
vecteur principal de compromission d'une chaîne d'approvisionnement : quelqu'un publie
exactement le nom qu'un modèle est susceptible d'halluciner.

Le mode `protect-tests` reprend le hook historique : mis en boucle sur « fais passer les
tests », un agent finit statistiquement par affaiblir l'assertion plutôt que corriger le
code. Une règle en langage naturel est une incitation ; un hook est une contrainte.

Il couvre `Edit`, `Write`, `NotebookEdit` et `Bash` — ce dernier par heuristique.
Ce n'est pas une frontière de sécurité : une commande suffisamment tordue passe, un
script indirect aussi. C'est un garde-fou contre la dérive ordinaire.

Le verrou de test se lève à la main, jamais par l'agent :

```bash
touch .claude/.allow-test-edits    # puis rm quand c'est fini
```

Toute commande contenant `allow-test-edits` est bloquée, pour que l'agent ne puisse pas
lever sa propre contrainte. Le verrou ne desserre **que** la protection des tests en mode
par défaut : il n'ouvre aucune frontière d'agent.

`install.sh` pose le fichier mais ne modifie pas ton `settings.json` : il affiche le bloc à
coller, et la commande pour vérifier que le hook bloque réellement. Un hook de gating qui
semble marcher sans rien bloquer est le pire des deux mondes. Il dépend de `jq` ; sans lui
il se désactive en le signalant.

### `session-start.sh`

Hook `SessionStart`, lecture seule. Quand la branche courante suit la convention
`<type>/<numero>-<slug>`, il injecte au démarrage les faits bruts du chantier : le contrat de
l'issue, le dernier checkpoint, l'état du worktree, la PR liée s'il y en a une. À défaut de
branche conventionnelle, il retombe sur l'issue portant le label `next`.

Il n'analyse rien — c'est le travail de `/issue-start`. Il évite seulement de recommencer une
session en redécouvrant un sujet déjà cadré, ou pire, en rediscutant une décision déjà prise.

Hors convention, hors dépôt Git, sans `gh` ou sans `jq`, il sort en 0 sans rien afficher.

### Vérifier qu'un hook est vraiment actif

Trois moyens, différents, à utiliser dans cet ordre :

1. **`/hooks`** — liste tous les hooks configurés, par événement, **avec le fichier de
   settings d'où chacun vient**. Dit ce qui est *configuré*.
2. **Le test d'injection** — envoyer un faux appel d'outil au script et vérifier `exit=2`.
   Dit si le script *fonctionne*.
3. **Le test réel** — lancer l'agent `dev` et lui demander d'ajouter un test. Dit si
   l'ensemble *bloque vraiment*.

Le troisième est le seul qui compte. Les deux premiers peuvent être verts pendant que
rien ne bloque.

## Le suivi de chantier

Les commandes `issue-*` remplacent le fil de conversation par les issues GitHub comme mémoire
longue. Le fil disparaît à la fermeture de la fenêtre ; l'issue est encore là dans trois semaines,
et lisible depuis n'importe quel outil.

```
board « DKP - Works »   idée notée à la main, tous produits confondus
  ↓ Convert to issue     l'élément du board devient l'issue #42 d'un dépôt
/issue-start 42          dépendances, contrat, écart contrat ↔ code, plan, branche
  ↓
[ travail ]              /spec, /test-write, /verify, /clean-commit comme d'habitude
  ↓
/issue-pause             point de reprise posté sur l'issue, en fin de session
  ↓                      (autant de fois que de sessions)
/issue-finish            critères un par un, gates, commits, PR en draft
```

Sur un projet piloté par un cahier de dev plutôt que par des issues, c'est `ai/cdd.md` qui
porte le contrat et l'avancement. Les jalons peuvent être projetés en issues GitHub — issue
parente, étapes en sous-issues via `gh issue create --parent` — quand un suivi partagé est
utile. Le cahier de dev local reste la source de vérité ; GitHub est une projection, un jalon
à la fois, pour que le board ne devienne pas ingérable.

`/issue-start` refuse de démarrer une étape dont les prérequis sont encore ouverts, et dit
lesquels.

Hors de ce cycle, `/issue-capture` sort une idée de la tête sans quitter le chantier en cours :
elle crée l'issue et te renvoie au travail, sans l'analyser ni l'ouvrir.

**Aucune commande n'écrit sur le board.** Elles ne touchent qu'aux issues — corps, commentaires,
labels — et à Git. Le board se remplit par le workflow *Auto-add to project* de GitHub, qui ajoute
toute nouvelle issue des dépôts que tu sélectionnes. Deux raisons : ce que tu ranges à la main ne
peut pas être défait par une session, et une issue créée depuis le web ou un autre poste arrive
dans le board de la même façon. Un élément déjà présent n'est jamais dupliqué.

À régler une fois dans l'UI du board, il n'y a pas d'API pour ça :

- workflow *Auto-add to project*, un dépôt par ligne — vérifie la limite de dépôts, elle a bougé
  selon les versions de Projects ;
- workflows *Item added → Status Todo* et *Item closed → Status Done* ;
- vue **Next** filtrée sur `label:next`, vue **Inbox** filtrée sur `label:inbox`.

Deux labels portent l'état, et les commandes les gèrent seules : `inbox` marque une idée sans
contrat, posé par `/issue-capture` ; `next` marque le chantier courant du dépôt, posé par
`/issue-start` — un seul à la fois, retiré par `/issue-finish`. Rien à créer à la main, les
commandes créent le label s'il manque.

Les numéros d'issue sont propres à chaque dépôt : il y aura un #42 dans plusieurs de tes projets.
`/issue-start 42` travaille sur le dépôt courant, donc lance-la depuis le bon répertoire. Le board
affiche le dépôt à côté de chaque élément.

## Les deux niveaux de règles

| Niveau | Fichier | Contenu |
|---|---|---|
| **Global** | `AI-rules/me.md` | Qui je suis, comment je veux qu'on travaille. Stable, vrai partout. |
| **Projet** | `CLAUDE.md` à la racine du projet | Stack, arborescence, vraies commandes, pièges. Généré par `/rules`. |

Les deux se cumulent automatiquement, et le niveau projet prime.
Le fichier projet ne se symlinke pas vers ce repo : chaque projet a le sien, avec ses spécificités. Côté projet, `/rules` fait pointer `AGENTS.md` vers `CLAUDE.md` pour la même raison qu'ici — un seul fichier à maintenir.

## Les permissions

Le harnais repose sur trois niveaux, et il faut savoir lequel fait quoi :

| Niveau | Portée | Ce qu'il règle |
|---|---|---|
| `permissions.allow` / `deny` | **Session entière** | Ce qui passe sans demander, ce qui ne passe jamais |
| `permissionMode` | **Par agent** (frontmatter) | Comment l'agent traite une demande de permission |
| `scope-guard.sh` | **Par agent** (via `agent_type`) | Où l'agent a le droit d'écrire |

Une règle `deny` prime sur tout `allow` et sur n'importe quel `permissionMode`, y compris
`bypassPermissions`. C'est le seul niveau qui ne se contourne pas : `git push`,
`git reset --hard`, la lecture des `.env` y vivent.

Le critère pour décider ce qu'un agent peut toucher n'est pas la nature du fichier, c'est
la réversibilité : **`git checkout` annule ?** Alors l'agent le fait et le déclare. Sinon,
il propose et j'applique. Un `tsconfig` ou un `Dockerfile` est du texte versionné ; une
migration lancée sur une base et un volume Docker supprimé ne le sont pas.

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

## Ajouter un agent

1. Créer `AI-rules/agents/<nom>.md` avec `name`, `description`, `tools`, et les `skills`
   qu'il précharge.
2. **Ajouter son mode dans `scope-guard.sh`.** Sans ça il tombe dans le cas par défaut :
   protégé, mais avec le périmètre d'une session normale.
3. Redémarrer Claude Code, vérifier avec `/agents`.

Un agent mérite d'exister quand une mission entière peut lui être déléguée sans qu'on soit
dans la boucle pendant. Si tu dois valider trois choses en cours de route, c'est une
commande qu'il te faut, pas un agent.

`/agents` liste les agents mais n'ouvre plus d'assistant de création depuis la v2.1.198 :
les fichiers s'écrivent directement.

## Commande ou skill ?

- **Commande Claude Code** : déclenchement explicite via `/nom`.
- **Skill Codex** : déclenchement explicite via `$nom`, ou implicite selon la description.

Le contenu métier reste commun, mais les mécanismes d'intégration diffèrent. Le script
convertit le frontmatter Claude Code vers le frontmatter minimal attendu par Codex et
retire le placeholder `$ARGUMENTS`, qui n'existe pas dans les skills.

## Déléguer sans casser Codex

Codex n'a pas d'agents. Une commande qui délègue serait donc inutilisable — ou il
faudrait dupliquer la méthode dans la commande, et maintenir deux textes.

À la place, un marqueur en fin de commande :

```markdown
<!-- fallback:methods/test-design.md -->
```

Claude Code n'y voit qu'un commentaire HTML et délègue au vrai agent. `install.sh`, en
générant le skill Codex, remplace la ligne par le contenu du fichier référencé, sous un
titre d'annexe. Le skill reste autonome, et la méthode n'existe qu'à un seul endroit.

Le fichier référencé est relatif à `AI-rules/`. S'il est introuvable, la génération le
signale sur stderr au lieu de produire un skill amputé en silence.

## Structure

```
dev-with-ai/
├── README.md
├── ai/                   # cahier des charges, cahier de dev, specs, rapports — VERSIONNÉ
└── AI-rules/
    ├── me.md             # règles globales
    ├── commands/         # les commandes, partagées Claude Code + Codex
    ├── agents/           # les agents, Claude Code uniquement
    ├── methods/          # méthodes injectées dans les skills Codex par fallback
    ├── hooks/            # contraintes mécaniques, Claude Code uniquement
    ├── install.sh        # pose les liens et génère les skills Codex
    └── ARCHIVES/         # version OpenCode — OBSOLÈTE, ne pas appliquer
```

## À personnaliser

`me.md` décrit mon contexte de travail. Deux choses valent d'y être ajoutées quand
l'occasion se présente :

- ce qui change dans mon contexte — types de projets récurrents, contraintes clients ;
- les corrections que je me surprends à répéter à l'IA. C'est le meilleur indicateur d'une
  règle manquante.
