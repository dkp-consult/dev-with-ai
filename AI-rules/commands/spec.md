---
description: Rédige la spec technique d'une feature avant implémentation
argument-hint: <nom de la feature> — <description>
allowed-tools: Read, Glob, Grep, Write, Bash(git log:*), Bash(mkdir:*), Bash(ls:*)
---

Rédige une spécification technique pour : "$ARGUMENTS"

## Avant d'écrire

1. Lis le `CLAUDE.md` / `AGENTS.md` du projet s'il existe.
2. Explore le code réel pour relever les conventions en vigueur : structure des dossiers, nommage, découpage des fichiers, style des tests. **La spec suit les conventions du projet, pas un modèle générique.**
3. Repère les modules existants que la feature va toucher ou réutiliser.
4. Vérifie si une spec existe déjà pour cette feature (`ls ai/specs/`).

Si le nom de la feature ou son périmètre est ambigu, demande avant d'écrire. Une spec partie sur une mauvaise hypothèse coûte plus cher que la question.

## Fichier de sortie

`ai/specs/[nom-feature].spec.md`, avec `mkdir -p ai/specs` si le dossier n'existe pas.

Le nom du fichier est en kebab-case ASCII : minuscules, sans accent, espaces remplacés par des tirets, aucun caractère spécial. « Gestion des utilisateurs » donne `gestion-des-utilisateurs.spec.md`.

**Si la spec existe déjà, mets-la à jour au lieu de l'écraser**, et dis-moi ce que tu as changé.

## Format

```markdown
# [Feature]

## Objectif
Ce que ça résout, en 2-3 phrases. Le problème, pas la solution.

## Comportement attendu
Le flow étape par étape. Cas nominal d'abord, puis cas d'erreur.

## Fichiers
| Fichier | Action | Rôle |
|---|---|---|
Créé ou modifié. Chemins réels, cohérents avec l'arborescence existante.

## Interfaces
Signatures des fonctions, types et contrats introduits. Pas d'implémentation.

## Tests
Cas à couvrir, formulés en « should … ».
Inclut les cas limites et les erreurs, pas seulement le chemin heureux.

## Risques et points ouverts
Ce qui peut casser ailleurs, les décisions que je dois trancher, les inconnues.
```

## Règles

- Décris **quoi** et **pourquoi**, pas le code ligne à ligne.
- Ne propose que des fichiers qui ont leur place dans l'arborescence existante.
- La section « Risques » ne doit pas être vide par confort. S'il n'y a vraiment aucun risque, la feature est sans doute triviale et n'a pas besoin de spec — dis-le-moi plutôt que de remplir.
- **N'implémente rien.** Cette commande produit un document ; on code après validation. Le seul fichier que tu écris est la spec.
- À la fin, donne-moi le chemin du fichier et les points ouverts qui attendent une décision de ma part.