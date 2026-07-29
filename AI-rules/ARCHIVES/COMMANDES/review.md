---
description: Review code quality and risks
agent: build
---

Analyse le code modifié et génère un rapport de review :

1. Analyse
   - Examine tous les fichiers modifiés récemment
   - Vérifie la lisibilité, la cohérence et la performance
   - Signale tout risque (bug, sécurité, dette technique)
   - Vérifie si le code respecte le style du projet

2. Évaluation
   - Identifie les points forts et faibles
   - Propose des améliorations spécifiques si nécessaire
   - Évalue la conformité aux conventions du projet
   - Vérifie la couverture de tests

3. Documentation
   - Crée le fichier ai/reviews/[featureName]-[timestamp].review.md
   - Structure : Résumé → Analyse détaillée → Recommandations → Conclusion
   - Utilise un format markdown avec sections claires

4. Conclusion
   - État final clair : "✅ OK pour commit" ou "⚠️ Changements à faire"
   - Liste les actions requises si des changements sont nécessaires
   - Priorise les corrections par niveau d'importance

Si aucune feature spécifique n'est mentionnée dans "$ARGUMENTS" → analyse tous les changements récents.