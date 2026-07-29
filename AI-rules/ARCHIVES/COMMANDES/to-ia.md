---
description: Summarize project objective and current problem
agent: build
---

Génère un résumé contextuel du projet et du problème actuel :

1. Analyse du contexte
   - Objectif global du projet
   - État actuel du développement
   - Problème ou blocage actuel (type, impact)
   - Tentatives ou hypothèses déjà explorées

2. Investigation
   - Intègre les infos supplémentaires fournies dans "$ARGUMENTS"
   - Analyse les fichiers et code pertinents
   - Identifie les patterns et dépendances
   - Formule des hypothèses si le problème est flou

3. Documentation
   - Crée le fichier ai/context/[timestamp].context.md
   - Structure : Objectif → État actuel → Problème → Tentatives → Hypothèses → Actions
   - Inclut des snippets de code pertinents (extraits utiles uniquement)
   - Liste les fichiers et sections de code concernés

4. Conclusion
   - Si aucun problème → "✅ Aucun problème en cours"
   - Sinon → liste 2-3 pistes d'investigation prioritaires
   - Propose des actions concrètes pour résoudre le blocage

Utilise un timestamp pour le nom du fichier : YYYY-MM-DD-HHMMSS.context.md