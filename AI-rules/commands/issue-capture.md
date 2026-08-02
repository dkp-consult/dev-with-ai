---
description: Capture une idée en issue sans quitter le chantier en cours
argument-hint: "<l'idée, en langage naturel>"
allowed-tools: Grep, Glob, Bash(git status:*), Bash(git branch:*), Bash(gh issue list:*), Bash(gh issue create:*), Bash(gh issue comment:*), Bash(gh label create:*), Bash(gh project:*)
---

# Capture : $ARGUMENTS

Commande anti-bifurcation. Objectif : sortir l'idée de ma tête en moins de 20 secondes et **revenir immédiatement à ce que je faisais**.

## 1. Reformuler

Une phrase claire, sous forme de titre Conventional Commits (`refactor(stripe): centraliser la gestion des erreurs`). N'invente pas de contexte, ne développe pas — le contrat s'écrira au `/issue-start`.

## 2. Vérifier les doublons

```
gh issue list --state open --search "<mots-clés>" --json number,title
```

Si une issue proche existe, **propose de commenter dessus plutôt que d'en créer une** et attends ma réponse.

## 3. Créer

```
gh issue create --title "<titre>" --label inbox --assignee @me \
  --body "Capturé pendant le chantier #<N courant>.

$ARGUMENTS"
```

Le label `inbox` marque une issue sans contrat, à cadrer au démarrage. Crée-le s'il n'existe pas :
`gh label create inbox --color D4C5F9 --description "Idée capturée, contrat à écrire"`

**Ne touche pas au Project.** Le board « DKP - Works » récupère l'issue lui-même par son workflow *Auto-add to project*. Aucune commande n'écrit sur le board : c'est ce qui garantit qu'elle ne défera jamais un rangement fait à la main.

## 4. Sortir

Trois lignes maximum : numéro, titre, et « retour au chantier #<N> ». **N'analyse pas l'idée, n'ouvre aucun fichier, ne propose pas de l'implémenter maintenant.** C'est tout l'intérêt de la commande.
