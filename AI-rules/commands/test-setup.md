---
description: Met en place l'outillage de test du projet, après validation
argument-hint: [zone à couvrir en priorité, optionnel]
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(ls:*), Bash(cat:*), Bash(git status:*), Bash(git diff:*), Bash(npm:*), Bash(pnpm:*), Bash(yarn:*), Bash(npx:*)
---

Mets en place l'outillage de test de ce projet.

Zone à couvrir en priorité, si je l'ai précisée : "$ARGUMENTS"

Cette commande se lance **une fois par projet**. Elle installe de quoi faire échouer une régression ; elle ne couvre pas le projet.

## 1. Reconnaissance — avant de toucher quoi que ce soit

1. Lis le `package.json` : scripts existants, dépendances, et le lockfile présent (`pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`) pour déduire le gestionnaire de paquets. N'en change pas, n'en mélange pas deux.
2. Lis le `CLAUDE.md` / `AGENTS.md` du projet s'il existe.
3. Identifie la stack réelle. Astro, Next, Vite, Svelte et un script Node nu ne se testent pas de la même façon.
4. Vérifie si un runner est **déjà** configuré.

**Si un runner existe déjà : ne le remplace pas.** Tu passes directement à l'étape 4.

## 2. Proposition — point d'arrêt obligatoire

Avant d'installer ou de modifier quoi que ce soit, présente-moi :

- ce que tu as trouvé (stack, gestionnaire de paquets, runner existant ou non) ;
- les paquets exacts que tu comptes ajouter, en `devDependencies`, avec la raison de chacun ;
- les fichiers de configuration que tu vas créer ou modifier ;
- les scripts que tu vas ajouter au `package.json`.

**Arrête-toi et attends mon accord.** Aucune installation, aucune écriture avant.

Une dépendance dont tu ne peux pas justifier la présence en une phrase ne fait pas partie de la proposition.

## 3. Installation

Une fois validé :

- Vitest par défaut si aucun runner n'est présent, sauf si la stack en impose un autre — dans ce cas, dis lequel et pourquoi à l'étape 2.
- Configuration minimale, alignée sur la config de build existante (alias de chemins, variables d'environnement, environnement `node` ou `jsdom` selon la cible).
- Ne touche à aucune configuration existante qui fonctionne.
- Ajoute un script `test` non interactif (`vitest run`, pas `vitest`), utilisable en CI.

Tu peux aussi ajouter un script agrégé `check` qui enchaîne `typecheck → lint → format → test → build`, **uniquement avec les étapes qui existent réellement**. Si une étape manque, ne l'invente pas et ne mets pas de commande factice : signale-la comme manquante dans le rapport. Un `check` qui renvoie vert parce qu'il ne lance rien est exactement le problème qu'on cherche à supprimer.

`check` est un raccourci, pas la vérité : `/verify` continue de lancer les gates une par une pour savoir laquelle échoue.

## 4. Premiers tests

Cible la **logique métier pure** : calcul, validation, transformation, parsing, génération. Ignore l'UI, les pages, les composants de présentation, le style.

Écris les tests des invariants les plus critiques. **3 à 5 tests, pas 50.** Un test qui décrit une règle métier vaut mieux que dix qui vérifient qu'une fonction renvoie bien un objet.

Chaque test énonce une règle lisible par un humain, pas une mécanique d'implémentation.

Si tu ne trouves pas de logique métier testable, dis-le au lieu d'inventer des tests de remplissage.

Pour couvrir vraiment un module, c'est `/test-write` qu'on lance ensuite — il part de la spec, pas du code.

## 5. Documentation

Si le projet a un `CLAUDE.md`, ajoute dans sa section « Commandes » : le runner utilisé, où vit sa configuration, et la commande de test exacte. Si le `CLAUDE.md` n'existe pas, ne le crée pas ici — signale-le, c'est le travail de `/rules`.

## Contraintes

- **N'exécute aucune commande de publication, de déploiement ou de migration.**
- Ne modifie aucun fichier source hors tests, configuration de test et `package.json`.
- Ne commit pas. Le commit passe par `/clean-commit`.

## Rapport final

1. Ce qui existait déjà et que tu n'as pas touché.
2. Ce que tu as installé, avec les versions réelles issues du lockfile.
3. La commande exacte à lancer, et **le résultat réel de son premier passage**.
4. Les tests écrits, un par ligne, avec la règle métier que chacun protège.
5. Les étapes de `check` déclarées manquantes, s'il y en a.
6. **Les zones de logique métier laissées sans couverture, triées par coût de l'erreur.** C'est la partie la plus utile du rapport : dis-moi ce qui reste exposé.

Si une étape n'a pas pu être menée à bien, dis-le au lieu de le passer sous silence.
