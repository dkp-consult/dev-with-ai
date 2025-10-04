---
description: Generate feature specification
agent: build
---

Génère une spécification technique pour la feature demandée :

1. Structure
   - Suit exactement le format : Overview, Sequence, Flow Description, Related Files, Descriptions, Tests
   - Utilise les types de fichiers requis : *.selector.ts, *.reducer.ts, *.events.ts, *.usecase.ts, *.usecase.spec.ts
   - Ajoute *.errors.ts si la feature gère des erreurs spécifiques

2. Contenu
   - Place la spec dans ai/specs/[featureName].spec.md
   - Définit clairement les interfaces et types
   - Spécifie les tests à implémenter
   - Respecte l'architecture React-Redux modulaire du projet

3. Paramètres
   - Feature name : extrait des arguments ou demandé
   - Group : extrait des arguments ou demandé  
   - Description : fournie dans "$ARGUMENTS"

4. Validation
   - Vérifie la cohérence avec l'architecture existante
   - Confirme la structure des fichiers proposée
   - S'assure que tous les éléments nécessaires sont définis

Si des informations manquent → les demander explicitement avant de générer la spec.