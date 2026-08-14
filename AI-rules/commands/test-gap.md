---
description: Audite la couverture réelle et liste la logique métier exposée, triée par coût de l'erreur
argument-hint: [module ou zone à auditer, optionnel — par défaut tout le projet]
allowed-tools: Read, Glob, Grep, Bash(ls:*), Bash(npm run:*), Bash(pnpm:*), Bash(npx vitest run:*)
---

Audite la couverture de test : "$ARGUMENTS"

**Lecture seule stricte.** Tu n'écris aucun fichier, tu ne proposes aucun patch, tu n'écris aucun test. On te demande le diagnostic, pas le remède.

Ton livrable est une liste de risques hiérarchisée, pas un plan d'action.

## Méthode

1. **Inventorie les tests existants et ce qu'ils couvrent réellement** — pas ce que leur nom prétend couvrir. Ouvre-les, lis les assertions.
2. **Inventorie la logique métier** : calcul, validation, transformation, parsing, autorisation, manipulation d'argent, de dates, d'identités, d'états persistés.
3. **Croise les deux.**
4. **Trie ce qui reste par coût de l'erreur**, jamais par volume de code.

## Barème de coût

- **Critique** — corruption de données, perte d'argent, faille d'autorisation, envoi vers un tiers, irréversible sans intervention manuelle.
- **Élevé** — comportement faux et silencieux, dérive progressive, erreur découverte longtemps après.
- **Modéré** — casse visible immédiatement, corrigeable par un redéploiement.
- **Faible** — cosmétique, dégradé mais fonctionnel.

Un fichier de configuration se survole, un module de paiement se relit à plusieurs. Même principe ici : l'effort de couverture est proportionnel au coût de l'erreur, pas uniforme.

## Format

Pour chaque trou :

```
[CRITIQUE] chemin/du/fichier.ts : nomDeLaFonction
Ce qui n'est pas vérifié : <une phrase>
Ce qui casse si c'est faux : <une phrase, concrète>
```

Puis :

### Tests trompeurs

Tests existants qui passent sans rien vérifier de substantiel : assertion tautologique, mock qui teste le mock, `expect(x).toBeDefined()` sur une valeur toujours définie, test dont toutes les branches sont mockées.

**Un test vert qui ne prouve rien est pire qu'une absence de test** : il achète de la confiance sans la mériter. Signale-les nommément, avec le fichier et le nom.

### Suites vides

Un fichier de test sans test exécuté, un `describe` sans `it`, un runner configuré qui ne collecte rien. Zéro test lancé est un manque, jamais un succès.

### Les trois d'abord

Si on ne devait couvrir que trois choses, lesquelles et pourquoi.

## Contraintes

- **Maximum 50 lignes.** Un audit qu'on ne lit pas ne sert à rien.
- Pas de préambule, pas de « voici mon analyse ».
- **N'écris pas les tests.** Pour couvrir un module, c'est `/test-write` qu'on lance ensuite, et il part de la spec, pas du code.
- Si le projet n'a aucun test et aucune logique métier notable, dis-le en deux lignes et arrête-toi.
- Si tu peux lancer la suite pour obtenir un rapport de couverture réel, fais-le et cite les chiffres. Mais un pourcentage de couverture n'est pas un diagnostic : c'est le coût de l'erreur qui trie, pas le pourcentage.
