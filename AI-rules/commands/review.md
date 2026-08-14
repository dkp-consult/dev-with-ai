---
description: Relit un diff contre la spec et les conventions — constate, ne corrige pas
argument-hint: [périmètre : jalon, étape, branche ou plage de commits]
allowed-tools: Read, Glob, Grep, Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(git status:*), Bash(npm run:*), Bash(pnpm:*), Bash(yarn:*), Bash(npx:*)
---

Relis le code du périmètre : "$ARGUMENTS"

Tu es en lecture seule. **Tu ne corriges rien de ce que tu signales.** Un relecteur qui répare devient l'auteur, et plus personne ne relit.

## 1. Établis le périmètre

| Ce qui est fourni | Ce que tu relis |
|---|---|
| Un numéro de jalon | Le diff de toutes les étapes du jalon |
| Un numéro d'étape | Le diff de cette étape seule |
| Une branche ou une plage | Ce qui est demandé |
| Rien | `git diff origin/HEAD...HEAD`, et dis-le |

Annonce en tête : nombre de fichiers, lignes ajoutées et retirées. Si le périmètre dépasse une trentaine de fichiers, dis-le et propose de le découper — au-delà, une relecture devient un survol.

## 2. Lis le contrat d'abord

`ai/cdd.md` pour un jalon, `ai/specs/*.spec.md` pour une étape, `CLAUDE.md` pour les conventions du projet.

**Tu ne peux pas juger un écart sans connaître la cible.** Si aucun contrat n'existe, dis-le et relis contre les conventions du projet seulement — en précisant que tu ne peux vérifier aucun critère fonctionnel.

## 3. Lance les gates

Applique la procédure de `/verify` : ordre typecheck → lint → format → test → build, uniquement des commandes lues dans le projet, nombre de tests exécutés, sortie brute en cas d'échec.

Une gate rouge change la lecture de tout le reste. Elle passe en tête du rapport.

## 4. Cherche, dans cet ordre de gravité

- **Régressions** — un comportement qui marchait et ne marche plus. Le plus coûteux, le plus difficile à voir dans un diff.
- **Effets de bord** — une modification qui change le comportement d'un appelant hors périmètre. Remonte aux appelants avec `Grep`, ne te fie pas au diff seul.
- **Écarts au contrat** — un critère de la spec non couvert, ou couvert autrement que décrit sans que ce soit dit.
- **Cas d'erreur non traités** — le chemin heureux écrit, le reste absent. `catch` vide, erreur avalée, promesse non gérée, `null` non testé.
- **Couplages introduits** — deux modules qui ne se connaissaient pas et se connaissent maintenant, sans que la spec l'ait prévu.
- **Hors périmètre** — ce qui a été modifié sans appartenir à l'étape. Le plus fréquent, et le plus pénible en revue.
- **Restes de travail** — `console.log`, `debugger`, `TODO`/`FIXME` ajoutés, code mort, code commenté.
- **Secrets** — clé, token, mot de passe, chaîne de connexion, contenu de `.env`. En cas de doute, signale.
- **Tests affaiblis** — un test existant modifié dans le même commit que le code qu'il vérifie. Regarde l'assertion, jamais le nom du test.

Trie par **coût de l'erreur**, jamais par ordre d'apparition dans le diff.

## 5. Sépare ce que tu sais de ce que tu crois

Pour chaque constat, tu dois pouvoir répondre à « comment ça casse ? » par un scénario concret : telle entrée, tel état, tel résultat faux.

Si tu n'y arrives pas, le constat va dans « À vérifier », pas dans les constats. Un défaut plausible mais non démontré fait perdre du temps et décrédibilise les vrais.

## Format

```markdown
## Périmètre
<commits, branche ou plage> — N fichiers, +N/-N lignes
Contrat lu : <chemins>

## Gates
| Gate | Commande | Résultat |
|---|---|---|
Avec le nombre de tests exécutés. Une suite vide se marque NON COUVERT.

## Constats

### [CRITIQUE] <titre en une ligne>
`chemin/fichier.ts:42`
**Ce qui ne va pas** : une phrase.
**Comment ça casse** : entrée ou état concret → résultat faux.
**Ce que je ferais** : une ou deux phrases, non appliquées.

Niveaux : CRITIQUE · ÉLEVÉ · MODÉRÉ · FAIBLE.

## Hors périmètre
Fichier par fichier. « Aucun » si aucun.

## À vérifier
Ce qui semble suspect sans que tu puisses le démontrer.

## Vérifié sans rien trouver
La liste, pour que l'absence de constat ne passe pas pour une absence de relecture.
```

## Règles

- **Pas de revue de style.** Nommage, ordre des imports, préférences syntaxiques : le linter s'en charge, ou personne. Tu ne relèves une convention que si elle est écrite dans le `CLAUDE.md` et enfreinte.
- **Pas de réécriture complète proposée.** Un extrait de quelques lignes suffit à montrer le problème.
- **Dix constats classés valent mieux que quarante en vrac.** Si tu en as plus de quinze, le périmètre est trop gros : dis-le.
- **Pas de complaisance.** « Le code est propre » sans avoir rien cherché est un faux vert. Si tu ne trouves rien de sérieux, dis-le en une ligne et liste ce que tu as vérifié pour arriver là.
- **N'écris aucun fichier.** Le rapport va dans ta réponse.
