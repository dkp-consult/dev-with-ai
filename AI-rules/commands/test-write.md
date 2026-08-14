---
description: Conçoit puis écrit les tests d'un module, à partir de la spec
argument-hint: <fichier ou module cible> — [chemin de la spec]
allowed-tools: Read, Glob, Grep, Write, Edit, Task, Agent, Bash(ls:*), Bash(npm run:*), Bash(pnpm run:*), Bash(npx vitest:*), Bash(git status:*), Bash(git diff:*)
---

Écris les tests pour : "$ARGUMENTS"

## 1. Conception des cas

**Si ton outil dispose de sous-agents**, délègue toute la commande au sous-agent `tester` : la conception des cas est sa phase 1. Passe-lui explicitement dans le prompt d'invocation :

- le fichier ou module cible, chemin exact ;
- le chemin de la spec si je t'en ai donné un ;
- la racine du projet.

**Son contexte démarre vide** : il ne voit rien de notre conversation, tout ce dont il a besoin doit figurer dans le prompt.

**Sinon**, applique toi-même la méthode donnée en annexe de cette commande et produis le même livrable.

Dans les deux cas, la règle qui prime : **les cas se déduisent de la spec, pas de l'implémentation**. Des cas dérivés du code encodent le comportement actuel, bugs compris — ils produisent des tests verts qui certifient le bug.

## 2. Point d'arrêt — obligatoire

Affiche-moi la liste de cas **telle quelle** et **arrête-toi**.

C'est mon point de relecture : je valide la spec des tests, pas leur code. Tu n'écris pas une ligne avant mon accord. Vingt lignes de français se relisent ; trois cents lignes de test, non.

- Si la section « Zones d'ombre » contient des questions, pose-les-moi maintenant. Ne tranche pas à ma place.
- Si les cas sont marqués `[DESCRIPTIF]` (aucune spec trouvée), dis-le clairement : je dois savoir que ces tests figent le comportement actuel au lieu de le vérifier. Si la feature mérite mieux, propose-moi de lancer `/spec` d'abord.
- **Si le fichier de test cible existe déjà**, dis-le ici. Tu ne le modifieras pas sans que je lève le verrou : je choisis entre un nouveau fichier et l'autorisation explicite d'éditer l'existant.

## 3. Écriture

Une fois les cas validés :

- **Un cas validé = un test.** Ni plus, ni moins. Tu n'ajoutes pas de cas de ta propre initiative ; si tu en vois un manquant, signale-le, je décide.
- Le nom du test **énonce la règle métier**, lisible sans lire le corps : `refuse une grille contenant une case orpheline`, pas `test grid validation 3`.
- Respecte les conventions du projet relevées à l'étape 1 : emplacement, nommage, style des fixtures.
- Pas de mock de ce que tu peux exécuter réellement. Un mock qui teste le mock est un faux vert.
- Pas d'assertion tautologique. `expect(x).toBeDefined()` sur une valeur toujours définie ne prouve rien.
- Une seule règle par test. Si un test vérifie trois choses, son échec ne t'apprend rien.

### Interdits

- **Ne modifie aucun test existant** sans mon autorisation explicite. Le hook `protect-tests.sh` te bloquera de toute façon ; ne cherche pas à le contourner, ne supprime pas un fichier pour le recréer, ne lève pas le verrou toi-même.
- **Ne modifie aucun fichier source.** Tu écris des tests, pas du code de production.

## 4. Exécution

Lance uniquement les tests que tu viens d'écrire, en mode non interactif.

**Un test qui échoue n'est pas un problème à régler tout de suite.** Trois lectures possibles, et ce n'est pas à toi de choisir :

1. le code est faux → c'est précisément ce que le test devait révéler ;
2. le test est faux → à corriger, après ma validation ;
3. la spec était ambiguë → décision à prendre.

Rapporte la sortie brute et **arrête-toi**. Tu ne touches ni au code ni au test pour faire passer la gate.

Si on est en TDD et que le code n'existe pas encore, un échec est le résultat attendu : dis-le, et n'implémente rien.

## 5. Pas de commit

Le commit passe par `/clean-commit`. Ne stage rien, ne commit rien.

## Rapport final

1. Les cas validés, et le test correspondant à chacun (fichier + nom).
2. Le résultat réel de l'exécution : **N tests, N verts, N rouges**, sortie brute pour les rouges.
3. Pour chaque échec, ta lecture des trois hypothèses ci-dessus — sans agir dessus.
4. Ce qui figurait en « volontairement non couvert », rappelé ici pour que la liste ne passe pas pour exhaustive.

Si une étape n'a pas pu être menée à bien, dis-le au lieu de le passer sous silence.

<!-- fallback:methods/test-design.md -->
