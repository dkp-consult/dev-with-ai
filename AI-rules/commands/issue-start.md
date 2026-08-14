---
description: Démarre ou reprend un chantier — analyse l'état réel, propose un plan de session
argument-hint: "[numéro d'issue]"
allowed-tools: Read, Grep, Glob, Write, Bash(git status:*), Bash(git branch:*), Bash(git log:*), Bash(git switch:*), Bash(git worktree:*), Bash(gh issue view:*), Bash(gh issue list:*), Bash(gh issue edit:*), Bash(gh label create:*), Bash(gh pr list:*)
---

# Démarrage de chantier

## 0. Sans argument

Si `$ARGUMENTS` est vide, liste les issues ouvertes du repo courant, la `next` en premier :

```
gh issue list --state open --assignee @me --json number,title,labels,updatedAt \
  --template '{{range .}}{{.number}}  {{.title}}{{"\n"}}{{end}}'
```

Affiche-les et demande-moi laquelle. N'en choisis pas une toi-même.

## 1. Vérifier le terrain

```
git status --short
git branch --show-current
```

Si l'arbre de travail n'est pas propre, **arrête-toi et signale-le**. Ne démarre pas un chantier par-dessus des modifications non commitées d'un autre : c'est le meilleur moyen de mélanger deux sujets dans un diff.

## 2. Lire tout ce qui existe

```
gh issue view <N> --comments
gh pr list --search "<N>" --state all --json number,state,isDraft,headRefName
git log --oneline --all --grep "#<N>" -20
```

## 2 bis. Vérifier les dépendances

Un chantier peut en attendre un autre. Avant d'aller plus loin, cherche ce qui bloque :

- dans le corps de l'issue, une mention `Bloqué par #<N>` ou une sous-issue non close ;
- dans `ai/cdd.md` si le projet en a un, la ligne de l'étape correspondante et sa mention `BLOQUÉ` ou `dépend de` ;
- l'état réel des issues citées : `gh issue view <N> --json state`.

```
gh issue view <N> --json body,title
gh issue list --search "linked:<N>" --state open --json number,title
```

**Si un prérequis est encore ouvert, arrête-toi** et dis lequel. Ne démarre pas un chantier dont la base n'existe pas : le travail sera à refaire quand le prérequis atterrira, et la relecture mélangera les deux sujets.

Si l'issue porte le label `blocked` et que ses prérequis sont désormais clos, propose de le retirer.

## 3. Vérifier le contrat

Si l'issue n'a pas de section « Fait quand » avec des critères **vérifiables** (pas « ça marche »), c'est le moment de l'écrire — pas plus tard. Propose-moi :

```markdown
## Pourquoi
[Le problème réel, pas la solution. 2 lignes.]

## Fait quand
- [ ] critère vérifiable
- [ ] critère vérifiable

## Contexte
Fichiers pressentis : [chemins réels, vérifiés dans le repo]
Décisions déjà prises : [ce qui est arrêté et ne doit pas être rediscuté]
Écarté : [option + raison]
```

Attends ma validation, puis `gh issue edit <N> --body-file <tmp>`.

Interdits dans un contrat : estimations en heures, priorités numériques, listes de plus de 5 critères.

## 4. Synthèse — le cœur de la commande

Ne code rien. Remets-moi dans le sujet :

- **Objectif** : une phrase, tirée du contrat
- **Déjà fait** : d'après les commits et le dernier commentaire de session, pas d'après le contrat
- **Reste à faire** : l'écart entre les deux
- **Incohérences** : ce que le code contredit dans l'issue, ou une décision du dernier commentaire qui n'apparaît nulle part dans le diff. **C'est la section la plus utile** — dis-le explicitement s'il n'y en a aucune.
- **Plan de session** : 2 à 4 étapes, pas plus

## 5. Branche et worktree

S'il existe déjà une branche `*/<N>-*`, bascule dessus. Sinon propose :

```
git worktree add ../$(basename "$PWD")-<N> -b <type>/<N>-<slug>
```

Type cohérent avec le scope Conventional Commits à venir (`feat`, `fix`, `refactor`, `chore`). Slug : minuscules, tirets, 3-4 mots.

Marque ensuite l'issue comme chantier courant du dépôt — un seul `next` à la fois, c'est ce qui permet à une session de retrouver le sujet quand la branche ne dit rien :

```
gh label create next --color 0E8A16 --description "Chantier en cours" 2>/dev/null || true
gh issue list --label next --state open --json number --jq '.[].number'
gh issue edit <chaque autre N trouvé> --remove-label next
gh issue edit <N> --add-label next --remove-label inbox
```

`inbox` saute au passage : le contrat est écrit, l'idée n'est plus une idée.

## 6. Stop

Termine par le plan et attends mes instructions. **Ne commence pas à implémenter.** Cette commande sert à recharger le contexte, pas à produire du code.
