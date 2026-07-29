# dev-with-ai

Ma configuration de développement avec agents IA — **une seule source de vérité**, partagée entre Claude Code et Codex.

Écrire une règle ou une commande une fois, et l'avoir dans les deux outils. C'est tout l'objet de ce repo.

## Comment ça marche

Quatre liens symboliques, posés une fois. Les deux outils lisent les mêmes fichiers.

```
AI-rules/me.md       ──┬──→  ~/.claude/CLAUDE.md
                       └──→  ~/.codex/AGENTS.md

AI-rules/commands/   ──┬──→  ~/.claude/commands/
                       └──→  ~/.codex/prompts/
```

Conséquence : une nouvelle commande = **un fichier écrit une fois**, immédiatement disponible des deux côtés. Une correction = un fichier modifié. Plus de synchronisation manuelle.

## Installation

```bash
cd AI-rules && ./install.sh
```

Le script est idempotent et refuse d'écraser un fichier existant non vide.

## Les commandes

| Commande | Quand | Ce qu'elle fait |
|---|---|---|
| `/rules` | Une fois par projet | Analyse le code réel et génère le `CLAUDE.md` + `AGENTS.md` du projet |
| `/explain` | Code inconnu ou surprenant | Explique un fichier, une fonction ou un extrait, en lecture seule |
| `/spec` | Avant une vraie feature | Cadre l'implémentation, produit `ai/specs/<feature>.spec.md` |
| `/verify` | Quand l'agent dit « c'est fini » | Lance les vraies gates du projet et rapporte la sortie brute |
| `/clean-commit` | Avant de commiter | Nettoyage, secrets, gates, message conventionnel |
| `/context` | Blocage ou changement d'outil | Point de situation dans `ai/context/`, pour reprendre à froid |

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

Elle est immédiatement disponible via `/<nom>` dans Claude Code et dans Codex. Rien à réinstaller.

Une commande mérite d'exister si elle encode une checklist qu'on oublierait, impose un format, ou contraint l'agent. Si elle se résume à « fais le travail correctement », c'est un prompt normal.

## Commande ou skill ?

- **Commande** : *toi* qui déclenches en tapant `/nom`. Portable entre les deux outils.
- **Skill** : *l'agent* qui la charge quand il juge le sujet pertinent. Format Claude Code, pas d'équivalent direct côté Codex.

Le test : *« est-ce que je saurai, moi, quand j'en ai besoin ? »* Oui → commande. Non, mais l'agent devrait le savoir → règle projet ou skill.

## Structure

```
dev-with-ai/
├── README.md
└── AI-rules/
    ├── me.md              # règles globales
    ├── commands/          # les commandes, partagées
    ├── install.sh         # pose les 4 liens
    └── ARCHIVES/          # version OpenCode, pour référence
```

## À personnaliser

`me.md` a été écrit à partir de ce qui était connu (stack TypeScript/React + Node, travail en français). Deux choses valent d'y être ajoutées quand l'occasion se présente :

- ton contexte de travail — freelance, clients, types de projets récurrents ;
- les corrections que tu te surprends à répéter à l'IA. C'est le meilleur indicateur d'une règle manquante.
