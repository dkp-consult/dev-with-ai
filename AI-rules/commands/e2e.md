---
description: Écrit et lance les tests de bout en bout d'un parcours — Playwright
argument-hint: <parcours à couvrir> — [chemin de la spec] | --setup
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(ls:*), Bash(npm run:*), Bash(pnpm:*), Bash(yarn:*), Bash(npx playwright:*), Bash(git status:*), Bash(git diff:*)
---

Couvre en bout en bout : "$ARGUMENTS"

Un test E2E vérifie qu'un **parcours utilisateur** fonctionne dans un vrai navigateur. Ce n'est pas un test unitaire déguisé : si ce que tu veux vérifier peut l'être par une fonction appelée directement, c'est `/test-write` qu'il faut, pas cette commande.

## Mode `--setup` — une fois par projet

Si `$ARGUMENTS` contient `--setup`, tu installes l'outillage au lieu d'écrire un parcours.

1. **Reconnaissance** : lockfile présent (il détermine le gestionnaire), framework, comment l'application se lance en local, sur quel port, avec quelles variables d'environnement.
2. **Installation** — commande imposée selon le lockfile :

   ```
   pnpm add -D @playwright/test
   npm install --save-dev --ignore-scripts @playwright/test
   yarn add -D --ignore-scripts @playwright/test
   ```

   Puis `npx playwright install chromium` pour le navigateur — **un seul navigateur au départ**. Trois navigateurs multiplient par trois le temps de CI pour un bénéfice nul tant qu'aucun bug spécifique n'est apparu.

   Aucun paquet hors `@playwright/test` sans validation explicite.

3. **Configuration** — `playwright.config.ts` : `baseURL`, `webServer` pour que la suite démarre l'application elle-même, `testDir` séparé des tests unitaires (`e2e/`), `reporter: 'list'`, et `retries: 0` en local.

   `webServer` est le point qui compte : sans lui, la suite dépend d'un serveur lancé à la main et échoue en CI sans dire pourquoi.

4. **Script** : `test:e2e` non interactif (`playwright test`, jamais `--ui` par défaut).
5. **Un seul parcours** pour valider l'installation : celui qui prouve que l'application démarre et répond. Pas dix.

## Mode normal — un parcours

## 1. Identifie le parcours

Un parcours est une **suite d'actions qui produit un résultat observable** : « un visiteur ajoute un article au panier, se connecte, et retrouve son panier ». Pas « le bouton est bleu ».

La source de vérité est la spec de l'étape ou la section « Fait quand » du jalon. Si aucune ne décrit de parcours, demande lequel couvrir plutôt que d'en inventer un.

## 2. Écris

- **Un test par parcours**, pas un par bouton. Un test E2E qui vérifie quinze choses ne t'apprend rien quand il casse.
- Le nom énonce le parcours en français, lisible sans lire le corps.
- **Sélecteurs par rôle et par texte accessible** (`getByRole`, `getByLabel`, `getByText`), jamais par classe CSS ni par chemin dans le DOM. Un sélecteur CSS casse au premier changement de style et transforme la suite E2E en dette.
- **Aucun `waitForTimeout`.** Les attentes sont sur un état observable (`toBeVisible`, `toHaveURL`, `toHaveText`). Une attente en dur est la première cause de test instable.
- Chaque test part d'un état propre et ne dépend d'aucun autre. Si deux tests doivent s'enchaîner, c'est un seul test.
- Les données de test sont créées par le test lui-même, pas supposées présentes en base.

## 3. Vérification anti-faux-vert

Un test E2E qui passe du premier coup sans avoir jamais échoué ne prouve rien : il peut ne rien vérifier du tout.

Pour chaque test écrit, **vérifie qu'il échoue quand il doit échouer**. Casse temporairement l'attente (change le texte attendu), constate le rouge, rétablis. Rapporte que tu l'as fait.

C'est la seule façon de distinguer un test qui vérifie d'un test qui passe.

## 4. Exécution

Lance uniquement les tests écrits, en mode non interactif.

**Un rouge n'est pas à corriger tout de suite.** Trois lectures, et ce n'est pas à toi de choisir : l'application est cassée, le test est faux, ou la spec est ambiguë. Rapporte la sortie brute et arrête-toi.

**Ne modifie aucun code source.** Tu écris des tests. Si le parcours échoue parce que l'application a un bug, c'est exactement ce que le test devait révéler.

## Rapport final

1. Les parcours couverts, un par ligne, avec le fichier et le nom du test.
2. Pour chacun : la vérification anti-faux-vert a-t-elle été faite, et qu'a-t-elle donné.
3. Le résultat réel de l'exécution : **N tests, N verts, N rouges**, sortie brute pour les rouges.
4. Pour chaque échec, les trois lectures possibles, sans trancher.
5. Les parcours de la spec **volontairement non couverts**, et pourquoi.

## Règles

- **N'écris aucun fichier hors `e2e/`, sa configuration et le `package.json` en mode setup.**
- Pas de commit. Le commit passe par `/clean-commit`.
- Si le projet n'a pas d'interface — bibliothèque, script, API sans front — dis-le en deux lignes et arrête-toi. `/test-write` est l'outil adapté.
- Un parcours qui exige des données de production ou un compte tiers réel ne se teste pas en E2E automatique : signale-le comme test manuel.
