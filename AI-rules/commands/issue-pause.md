---
description: Checkpoint de fin de session — poste l'état réel sur l'issue en cours
argument-hint: "[note libre à intégrer absolument]"
allowed-tools: Read, Grep, Glob, Write, Bash(date:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(gh issue view:*), Bash(gh issue list:*), Bash(gh issue comment:*)
---

# Checkpoint de session

Objectif : produire une note que **moi dans trois semaines**, sans aucun souvenir de cette session, pourra lire en 30 secondes pour reprendre immédiatement.

## 1. Identifier l'issue

Numéro extrait de la branche courante (`<type>/<N>-<slug>`). À défaut : `gh issue list --label next --assignee @me --state open`. Si rien ne sort, demande-moi le numéro et arrête-toi. **Ne crée jamais d'issue depuis cette commande.**

## 2. Lire l'état réel

Ne te fie pas à ta mémoire de la conversation, lis le dépôt :

```
git status --short
git diff --stat
git log --oneline origin/HEAD..HEAD
```

Note aussi quels tests ont réellement tourné pendant la session, et lesquels ne l'ont pas.

## 3. Rédiger

```markdown
## Session du <date>

### Terminé
- [ce qui marche maintenant et ne marchait pas ce matin, factuel]

### Reste à faire
- [l'écart avec les critères d'acceptation]

### Décisions et points d'attention
- [décision d'architecture prise, option écartée et pourquoi, bug repéré non traité]
- ["Rien" si rien — ne remplis pas pour remplir]

### Point de reprise
[UNE action, exécutable sans réfléchir. Pas "continuer le webhook" mais
"reproduire le 500 sur checkout.session.completed, log ligne 42 de stripe.ts".]

### État Git
Branche : <branche>
Non commité : <fichiers, ou "arbre propre">
Tests : <ce qui a tourné, ce qui n'a pas tourné>
```

L'**État Git** va dans le commentaire, pas seulement dans ton rapport à l'écran : c'est ce qui me dit dans trois semaines pourquoi le worktree est sale.

Le **Point de reprise** est la section la plus importante. Si elle est vague, tout le reste ne sert à rien.

Pas de résumé de la conversation. Pas de « nous avons ensuite ». Si `$ARGUMENTS` est fourni, intègre-le : c'est ce que je veux absolument voir noté.

## 4. Me le montrer avant de poster

Affiche le commentaire en entier, attends ma validation explicite. Je corrige souvent le point de reprise.

## 5. Poster

```
gh issue comment <N> --body-file <tmp>
```

Rien d'autre. Le commentaire est la source de vérité ; le board n'est qu'un index et se met à jour de lui-même — poster fait remonter l'issue dans les vues triées par activité.

## 6. Ne commite pas

Ne commite ni ne pousse rien de ta propre initiative. Si du travail non commité mérite un commit, **propose-le** et attends. Le checkpoint documente l'état, il ne le modifie pas.
