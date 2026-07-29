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

## 🔧 Commandes Personnalisées Disponibles

### Configuration et Usage

**Approche universelle** qui fonctionne avec tous les agents AI :

1. **Au début de chaque session**, mentionnez à votre agent :
   ```
   J'ai des commandes personnalisées définies dans COMMANDES/. 
   Quand j'écris /plan, /spec, /code, etc., réfère-toi aux fichiers correspondants.
   ```

2. **Chargez le dossier** `COMMANDES/` dans le contexte de l'agent

3. **Utilisez naturellement** `/plan`, `/spec`, etc. dans vos prompts

> **Note :** Selon votre outil (OpenCode, Aider, etc.), vous pouvez aussi intégrer ces commandes directement dans votre système pour un accès global automatique. Consultez la documentation de votre agent pour les options de configuration avancées.

### Commandes Disponibles

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

## 📁 Structure du Projet

```
AI-rules/
├── COMMANDES/           # Commandes personnalisées
│   ├── plan.md         # Planification automatique
│   ├── spec.md         # Génération de spécifications
│   ├── code.md         # Implémentation selon spec
│   ├── review.md       # Review de code
│   ├── clean-commit.md # Commits propres
│   ├── doc.md          # Documentation
│   └── to-ia.md        # Contextualisation
├── ai/                 # Fichiers générés (gitignored)
│   ├── plans/          # Plans de features
│   ├── specs/          # Spécifications techniques
│   ├── reviews/        # Rapports de review
│   └── context/        # Résumés contextuels
├── agents.md           # Guide complet universel
└── README.md           # Ce fichier
```

## 🚀 Quick Start

1. **Chargez les règles** dans votre agent AI
2. **Commencez par `/plan`** pour toute nouvelle feature
3. **Suivez le workflow** : `/plan` → `/spec` → `/code` → `/review` → `/clean-commit`
4. **Utilisez `/to-ia`** en cas de blocage
5. **Documentez avec `/doc`** si nécessaire

---

Ce guide fournit une base solide pour développer efficacement avec des agents AI, quelle que soit la technologie utilisée. L'accent est mis sur la structure, la cohérence et les bonnes pratiques plutôt que sur des configurations techniques spécifiques.