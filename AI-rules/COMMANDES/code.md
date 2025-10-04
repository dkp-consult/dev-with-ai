---
description: Implement feature according to specification
agent: build
---

Implémente la feature selon la spécification fournie :

1. Lecture de la spec
   - Charge et analyse la spec depuis ai/specs/[featureName].spec.md
   - Ou utilise la spec fournie dans "$ARGUMENTS"
   - Valide que tous les éléments requis sont définis

2. Implémentation
   - Crée EXACTEMENT les fichiers listés dans "Related Files"
   - Respecte la structure src/features/[group]/[featureName]/
   - Implémente les fonctions décrites dans "Descriptions"
   - Suit les conventions React-Redux modulaires du projet

3. Code généré
   - Utilise les patterns établis (reducer, usecase, selector, events)
   - Respecte les conventions de nommage et structure
   - Ajoute les types TypeScript appropriés
   - Inclut la gestion d'erreurs si spécifiée

4. Tests
   - Génère les fichiers *.usecase.spec.ts selon la spec
   - Implémente les test cases listés dans la section "Tests"
   - Utilise les patterns de test du projet (store mock, fake gateways)

5. Validation
   - Vérifie que l'implémentation correspond à la spec
   - S'assure de la cohérence avec l'architecture existante
   - Ne génère RIEN au-delà de ce qui est spécifié

Si la spec est incomplète ou manquante → signaler les éléments manquants avant l'implémentation.