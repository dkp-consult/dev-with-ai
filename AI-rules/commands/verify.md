---
description: Lance les vraies gates du projet et rapporte le résultat brut
argument-hint: [périmètre à vérifier, optionnel]
allowed-tools: Read, Glob, Grep, Bash
---

Vérifie l'état réel du code. Ton rôle ici est de **constater**, pas de rassurer.
Tu n'as aucun droit d'écriture sur les fichiers : cette commande ne répare rien.

Périmètre demandé : "$ARGUMENTS"

## 1. Identifie les gates réelles

Lis les `scripts` du `package.json` (ou l'équivalent : Makefile, configuration CI). Repère ce qui existe parmi :

| Gate | Ce qu'on cherche |
|---|---|
| typecheck | `tsc --noEmit`, `typecheck`, `check-types` |
| lint | `lint`, `eslint` — **sans** `--fix` |
| format | `format:check`, `prettier --check` — **jamais** la variante qui réécrit |
| test | `test`, `test:run`, `vitest run`, `jest --ci` |
| build | `build` |

N'invente aucune commande. Si tu n'en trouves aucune, dis-le et demande.

**Aucune commande lancée ici ne doit modifier un fichier.** Si le projet n'expose que `format` en mode écriture et aucune variante `--check`, ne le lance pas : marque la gate « non lançable en lecture seule ». Idem pour un `lint` qui applique `--fix` par défaut.

Si le projet expose un mode watch par défaut (`vitest`, `jest` sans `--ci`), utilise la variante non interactive. Ne lance jamais une commande qui ne rend pas la main.

## 2. Exécute

Lance chaque gate trouvée, dans cet ordre : **typecheck → lint → format → test → build**.
Ne t'arrête pas à la première erreur — lance tout, je veux la vue complète.

## 3. Rapporte

Pour chaque gate : le résultat et la commande exacte utilisée.
En cas d'échec, colle la **sortie brute** de l'erreur, sans la reformuler ni la résumer. Si elle est très longue, garde les premières erreurs entières plutôt qu'un résumé de toutes.

Termine par un tableau :

| Gate | Commande | Résultat |
|---|---|---|

Résultats possibles : `OK` · `ÉCHEC` · `non lancée` · `absente du projet` · `non lançable en lecture seule`.

## Règles absolues

- **Une gate non lancée n'est pas une gate passée.** Marque-la « non lancée » et dis pourquoi.
- Ne dis jamais que ça marche sans avoir vu la commande réussir.
- Ne corrige rien de ta propre initiative : cette commande constate, elle ne répare pas. Si tu vois quoi corriger, propose-le à la fin sans l'appliquer.
- N'utilise aucune commande shell qui écrit sur le disque (`sed -i`, redirection, `git checkout`, `--fix`, `--write`).