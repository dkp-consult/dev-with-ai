---
description: Clôture un chantier — vérifie les critères, passe les gates, ouvre la PR
argument-hint: [précisions, optionnel]
allowed-tools: Read, Grep, Glob, Write, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(gh issue view:*), Bash(gh issue edit:*), Bash(gh pr create:*), Bash(npm run:*), Bash(pnpm:*), Bash(yarn:*), Bash(npx:*)
---

# Clôture de chantier

## 1. Relire le contrat

`gh issue view <N>`. Reprends **chaque** critère de « Fait quand » et dis pour chacun : couvert par quoi (fichier, test), ou non couvert. Pas de verdict global.

S'il en reste un seul non couvert, **arrête-toi** et dis-le. Ne propose pas de PR partielle sans que je le demande explicitement.

## 2. Gates, dans l'ordre

Lis le `CLAUDE.md` du repo pour les commandes exactes. Ordre : format → lint → types → tests → build. **Arrête-toi à la première qui casse**, ne lance pas les suivantes, ne « corrige » rien sans me le dire.

## 3. Inspecter le diff

`git diff origin/HEAD...HEAD`. Cherche : logs de debug oubliés, `TODO`/`FIXME` ajoutés, code mort, secrets ou clés en dur, et **changements hors périmètre** — ce dernier point est le plus fréquent et le plus pénible en review.

## 4. Commits

Propose un découpage en commits Conventional Commits, avec staging **fichier par fichier** (jamais `git add .`). Attends ma validation avant chaque commit.

Ne mets **jamais** `Closes #<N>` dans un message de commit : l'issue se fermerait au premier merge intermédiaire.

## 5. PR

```
gh pr create --draft --title "<type>(<scope>): <résumé>" --body-file <tmp>
```

Corps :

```markdown
## Résumé
[2-3 lignes, le pourquoi avant le comment]

## Vérifications
- [x] <gate> : <résultat>
- [x] <gate> : <résultat>

## Comment tester
[étapes concrètes]

Closes #<N>
```

`Closes #<N>` va **ici et uniquement ici**.

Crée-la en **draft**. Le passage en ready est mon geste, pas le tien. Ne pousse pas, ne merge pas, ne ferme pas l'issue à la main.

Retire enfin le label de chantier courant — la PR ouverte, le sujet n'est plus celui sur lequel une session doit reprendre :

```
gh issue edit <N> --remove-label next
```
