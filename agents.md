# Guide de Développement avec Agents AI

## 📘 Introduction

Ce guide définit un ensemble de règles et bonnes pratiques pour développer efficacement avec des agents AI de codage (Claude Code, OpenCode, Aider, etc.). Il se concentre sur un workflow structuré et des conventions de projet robustes, indépendamment du modèle ou de l'agent utilisé.

## 🎯 Philosophie et Approche

### Principes Fondamentaux
- **Spec-driven development** : Toujours planifier avant d'implémenter
- **Architecture feature-first** : Organiser le code par fonctionnalité métier
- **Conventions strictes** : Maintenir la cohérence du codebase
- **Context management** : Optimiser les interactions avec les agents AI

### Pourquoi cette Approche ?
- **Reproductibilité** : Résultats cohérents entre différents modèles/sessions
- **Maintenabilité** : Structure claire et prévisible du code
- **Collaboration** : Règles communes pour équipes et agents AI
- **Scalabilité** : Architecture qui grandit avec le projet

## 🚀 Workflow Universel : Plan → Spec → Code

Ce workflow entièrement automatisé garantit des résultats de qualité avec n'importe quel agent AI.

### Phase 1: Plan
**Commande disponible :** `/plan`

Utilise `/plan [description de la feature]` qui décompose automatiquement la feature en étapes claires, propose la structure de fichiers et identifie les dépendances.

### Phase 2: Spec  
**Commande disponible :** `/spec`

Utilise `/spec [feature] dans le groupe [groupe]. [description]` qui génère automatiquement la spécification technique complète dans `ai/specs/[feature].spec.md`.

### Phase 3: Code
**Commande disponible :** `/code`

Utilise `/code [spec file]` qui implémente exactement selon la spécification : fichiers, structure, tests et conventions du projet.

### Bonnes Pratiques du Workflow

#### ✅ À Faire
- Utiliser `/plan` pour la phase de planification
- Terminer une phase avant de passer à la suivante
- Réviser et valider chaque spec avant implémentation
- Utiliser `/review` avant de committer
- Maintenir le contexte entre Plan et Spec

#### ❌ À Éviter
- Passer directement de l'idée au code sans `/plan`
- Modifier la spec en cours d'implémentation
- Committer sans passer par `/review` et `/clean-commit`
- Mélanger plusieurs features dans une conversation

## 🏗️ Architecture et Organisation du Code

### Principes Généraux

- **Feature-first** : Organiser le code par fonctionnalité métier
- **Isolation** : Chaque feature vit dans son propre module
- **Groupement** : Rassembler les features liées en groupes logiques
- **Partage** : Utiliser des modules communs pour le code partagé
- **Structure** : Maintenir une hiérarchie claire et prévisible
- **Propreté** : Supprimer les éléments inutiles et obsolètes

### Structure Organisationnelle Recommandée

```
[racine]/
  [features_ou_modules]/
    [groupeFonctionnel]/     # ex: authentication, messaging, reporting
      [nomFeature]/
        [feature].[type].[ext]
        [feature].test.[ext]
        [feature].spec.[ext]   # optionnel
    [shared_ou_common]/
      [interfaces]/
      [services]/
      [entities]/
      [utils]/
```

### Avantages de cette Architecture

- **Maintenabilité** : Code organisé et prévisible
- **Testabilité** : Isolation des responsabilités
- **Réutilisabilité** : Composants et logique partagés
- **Scalabilité** : Structure qui grandit naturellement
- **Collaboration** : Équipes peuvent travailler sur des modules séparés

### Conventions de Nommage

- **Fichiers** : Noms explicites et cohérents avec le contenu
- **Dossiers** : Représentent des concepts métier ou techniques clairs
- **Extensions** : Suivent les conventions du langage/framework
- **Tests** : Colocalisation avec le code testé
- **Documentation** : Fichiers README ou doc par module si nécessaire

## 📋 Spécifications et Templates

### Génération Automatique avec `/spec`

La commande `/spec` génère automatiquement des spécifications selon le format standardisé :

**Structure standard :**
1. **Overview** - Description concise de la feature
2. **Sequence** - Flow d'exécution avec flèches  
3. **Flow Description** - Étapes numérotées détaillées
4. **Related Files** - Liste des fichiers à créer/modifier
5. **Descriptions** - Interfaces et fonctions de chaque fichier
6. **Tests** - Cases de test à implémenter

**Éléments adaptés au projet :**
- Respecte les conventions de nommage du langage
- Suit la structure de dossiers établie
- Inclut les types de fichiers appropriés (logique, tests, configuration)
- Définit les interfaces et contrats selon les standards du projet

### Conseils pour Différents Types d'Agents

**Agents qui suivent les instructions précisément :**
- Utilisez des prompts directs et structurés
- Spécifiez exactement le format attendu
- Listez les contraintes clairement
- Référencez les conventions du projet

**Agents plus conversationnels :**
- Utilisez `/to-ia` pour donner le contexte projet
- Expliquez l'objectif de la feature via `/plan`
- Demandez confirmation de l'approche
- Engagez le dialogue pour clarifier les ambiguïtés

**Agents avec tendance à "sur-penser" :**
- Soyez très spécifique sur ce que vous voulez
- Limitez le scope explicitement  
- Utilisez `/review` pour recadrer si nécessaire
- Rappelez les contraintes fréquemment

### Structure Standard des Specs

```markdown
# [FeatureName] Specification

## Overview
[Description concise de la feature]

## Sequence
[Flow d'exécution adapté au contexte du projet]

## Flow Description
1. [Étape 1]
2. [Étape 2]
3. [...]

## Related Files
- [Chemin vers fichier 1]
- [Chemin vers fichier 2]
- [Chemin vers tests]

## Descriptions

### [nomFichier]
- **[functionName]**
  - Description: [description]
  - Parameters: [description des paramètres]
  - Return: [description du retour]

[... autres fichiers]

## Tests
- [fichier de test]
  - Should [test case 1]
  - Should [test case 2]
```

## 🎯 Optimisation des Interactions avec les Agents

### Gestion du Contexte

**Règles universelles :**
- **Charger les règles** au début de chaque session
- **Limiter à ~50k tokens** pour maintenir la performance
- **Reset entre features majeures** pour éviter la contamination
- **Documenter les décisions** importantes pour la suite

**Stratégies selon le type d'agent :**

#### Agents "Conversationnels"
- Maintenez un contexte riche
- Engagez la discussion pour clarifier
- Utilisez des exemples concrets
- Reformulez si incompris

#### Agents "Instruction-Following"
- Soyez direct et précis
- Structurez vos demandes clairement
- Évitez les ambiguïtés
- Spécifiez les contraintes

#### Agents "Créatifs"
- Cadrez bien le scope
- Rappelez les conventions fréquemment
- Validez avant implémentation
- Limitez les "améliorations" non demandées

### Prompts Efficaces

**Structure recommandée :**
```
CONTEXTE: [Information sur le projet/architecture]
OBJECTIF: [Ce que vous voulez accomplir]
CONTRAINTES: [Limites et règles à respecter]
FORMAT: [Structure attendue de la réponse]
```

**Exemples de formulations :**
- ✅ "Génère uniquement le code pour..."
- ✅ "Suis exactement cette structure..."
- ✅ "N'ajoute aucune fonctionnalité supplémentaire..."
- ❌ "Fais quelque chose avec..."
- ❌ "Améliore ce code..."

## 💡 Exemples Pratiques

### Exemple Complet : Feature "processPayment"

**Workflow complet automatisé :**
```bash
# 1. Planification
/plan Feature processPayment dans le module Payments. 
Elle doit traiter les paiements via l'API externe et mettre à jour le statut.

# 2. Spécification  
/spec processPayment dans le module Payments. 
Traite les paiements et gère les réponses de l'API.

# 3. Implémentation
/code ai/specs/processPayment.spec.md

# 4. Validation et commit
/review
/clean-commit "feat(payments): add payment processing with status management"
```

### Exemple de Debugging avec Commandes

**Workflow de debugging :**
```bash
# 1. Contextualisation du problème
/to-ia La feature processPayment échoue silencieusement. 
Les erreurs ne sont pas remontées correctement.

# 2. Review et correction
/review
# [Appliquer les corrections suggérées]

# 3. Commit de la correction
/clean-commit "fix(payments): improve error handling in payment processing"
```

### Workflow Complet Optimisé

**Développement d'une nouvelle feature :**
```
/plan → /spec → /code → /review → /clean-commit
```

**Maintenance et debugging :**
```
/to-ia → /review → [corrections] → /clean-commit
```

**Documentation :**
```
/doc → /clean-commit
```

**Refactoring :**
```
/plan → /review → [modifications] → /review → /clean-commit
```

## 🔧 Commandes Personnalisées Disponibles

Votre environnement dispose de commandes spécialisées dans `COMMANDES/` qui génèrent des fichiers de traçabilité :

### `/plan` - Planification de Features
- Décompose la feature en étapes claires
- Propose la structure de fichiers
- Identifie les dépendances et risques
- **Sortie :** `ai/plans/[feature].plan.md`
- **Usage :** `/plan [description de la feature]`

### `/spec` - Génération de Spécifications
- Génère la spécification technique complète
- Définit structure, interfaces et tests
- **Sortie :** `ai/specs/[feature].spec.md`
- **Usage :** `/spec [feature] dans le groupe [groupe]. [description]`

### `/code` - Implémentation selon Spec
- Implémente exactement selon la spécification
- Crée tous les fichiers requis avec les conventions
- Génère les tests unitaires
- **Usage :** `/code [spec file]` ou `/code` (utilise la dernière spec générée)

### `/review` - Review de Code
- Vérifie qualité, lisibilité et performance
- Signale risques de bugs ou sécurité
- Valide le respect du style projet
- **Sortie :** `ai/reviews/[feature]-[timestamp].review.md`
- **Conclusion :** "✅ OK pour commit" ou "⚠️ Changements à faire"

### `/clean-commit` - Commit Propre
- Nettoie les artefacts temporaires
- Formate le code (Prettier, ESLint)
- Vérifie l'absence de secrets
- Génère message de commit conforme

### `/doc` - Documentation
- Crée/met à jour la documentation nécessaire
- Met à jour README.md ou CHANGELOG.md
- Structure : But → Usage → Exemple

### `/to-ia` - Contextualisation
- Résume l'objectif global du projet
- Identifie le problème ou blocage actuel
- Liste les tentatives déjà explorées
- **Sortie :** `ai/context/[timestamp].context.md`
- Aide à clarifier le contexte pour l'IA

## 🎓 Bonnes Pratiques et Anti-Patterns

### ✅ Bonnes Pratiques

1. **Workflow complet** - Utiliser `/plan` → `/spec` → `/code` → `/review` → `/clean-commit`
2. **Commandes dédiées** - Toujours utiliser les commandes spécialisées
3. **Spécifications obligatoires** - Jamais de `/code` sans `/spec`
4. **Validation systématique** - Toujours `/review` avant `/clean-commit`
5. **Reset intelligent** - Nouveau contexte pour nouvelles features majeures

### ❌ Anti-Patterns

1. **Bypass du workflow** - Implémenter sans `/plan` et `/spec`
2. **Ignorer `/review`** - Committer sans validation qualité
3. **Commits manuels** - Ne pas utiliser `/clean-commit`
4. **Specs manuelles** - Ne pas utiliser `/spec`
5. **Context overflow** - Conversations trop longues sans reset

### Résolution de Problèmes Courants

**Problème : Direction floue**
- ✅ Utiliser `/to-ia` pour clarifier le contexte
- ✅ Utiliser `/plan` pour structurer l'approche

**Problème : Qualité douteuse**
- ✅ Systématiquement utiliser `/review` avant commit
- ✅ Appliquer les recommandations suggérées

**Problème : Commits désordonnés**
- ✅ Toujours passer par `/clean-commit`
- ✅ Laisser la commande gérer le formatage et les messages

### Métriques de Qualité

**Indicateurs d'un bon workflow :**
- Utilisation systématique de `/plan` → `/spec` → `/code` → `/review` → `/clean-commit`
- Fichiers de traçabilité générés à chaque étape (ai/plans/, ai/specs/, ai/reviews/)
- Code conforme à l'architecture définie après `/review`
- Messages de commit conformes via `/clean-commit`
- Historique complet des décisions et analyses dans ai/

---

Ce guide fournit une base solide pour développer efficacement avec des agents AI, quelle que soit la technologie utilisée. L'accent est mis sur la structure, la cohérence et les bonnes pratiques plutôt que sur des configurations techniques spécifiques.