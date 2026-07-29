# dev-with-ai

Ma configuration de développement avec agents IA — **une seule source de vérité**, partagée entre Claude Code et Codex.

Écrire une règle ou une commande une fois, et l'avoir dans les deux outils. C'est tout l'objet de ce repo.

## Comment ça marche

Les règles sont partagées par liens symboliques. Les commandes restent la source de vérité :
Claude Code les lit directement et le script d'installation génère les skills Codex correspondants.

```
AI-rules/me.md       ──┬──→  ~/.claude/CLAUDE.md
                       └──→  ~/.codex/AGENTS.md

AI-rules/commands/   ──────→  ~/.claude/commands/
         └── install.sh ──→  ~/.codex/skills/<nom>/SKILL.md
```

Conséquence : une nouvelle commande reste écrite une seule fois. Elle est immédiatement
disponible dans Claude Code ; il faut relancer `install.sh` puis redémarrer Codex pour
regénérer et recharger le skill.

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
| `verify` | Quand l'agent dit « c'est fini » | Lance les vraies gates du projet et rapporte la sortie brute |
| `clean-commit` | Avant de commiter | Nettoyage, secrets, gates, message conventionnel |
| `context` | Blocage ou changement d'outil | Point de situation dans `ai/context/`, pour reprendre à froid |

Dans Claude Code, une commande s'invoque avec `/nom`. Dans Codex, le skill
correspondant s'invoque avec `$nom` ou depuis le sélecteur de skills.

### Le bon dosage

Le workflow complet ne se déroule pas pour tout. C'est même la moitié du gain de temps :

| Tâche | Ce qu'on lance |
|---|---|
| Correction, ajustement, petit fix | Rien, puis `/clean-commit` |
| Feature réelle, refacto structurant | `/spec` → travail → `/verify` → `/clean-commit` |
| Nouveau projet | `/rules`, une fois |
| Blocage ou passage Claude ↔ Codex | `/context` |
| Code repris, hérité ou surprenant | `/explain` |

## Les deux niveaux de règles

| Niveau | Fichier | Contenu |
|---|---|---|
| **Global** | `AI-rules/me.md` | Qui je suis, comment je veux qu'on travaille. Stable, vrai partout. |
| **Projet** | `CLAUDE.md` à la racine du projet | Stack, arborescence, vraies commandes, pièges. Généré par `/rules`. |

Les deux se cumulent automatiquement, et le niveau projet prime.
Le fichier projet ne se symlinke pas vers ce repo : chaque projet a le sien, avec ses spécificités. Côté projet, `/rules` fait pointer `AGENTS.md` vers `CLAUDE.md` pour la même raison qu'ici — un seul fichier à maintenir.

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

## Structure

```
dev-with-ai/
├── README.md
└── AI-rules/
    ├── me.md              # règles globales
    ├── commands/          # les commandes, partagées
    ├── install.sh         # pose les liens et génère les skills Codex
    └── ARCHIVES/          # version OpenCode, pour référence
```

## À personnaliser

`me.md` a été écrit à partir de ce qui était connu (stack TypeScript/React + Node, travail en français). Deux choses valent d'y être ajoutées quand l'occasion se présente :

- ton contexte de travail — freelance, clients, types de projets récurrents ;
- les corrections que tu te surprends à répéter à l'IA. C'est le meilleur indicateur d'une règle manquante.
