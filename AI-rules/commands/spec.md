---
description: Rédige la spec technique d'une feature avant implémentation
argument-hint: <nom de la feature> — <description>
allowed-tools: Read, Glob, Grep, Write, Task, Agent, Bash(git log:*), Bash(mkdir:*), Bash(ls:*)
---

Rédige une spécification technique pour : "$ARGUMENTS"

## Avant d'écrire

1. Lis le `CLAUDE.md` / `AGENTS.md` du projet s'il existe.
2. Explore le code réel pour relever les conventions en vigueur : structure des dossiers, nommage, découpage des fichiers, style des tests. **La spec suit les conventions du projet, pas un modèle générique.**
   Si ton outil dispose d'un sous-agent d'exploration en lecture seule (`Explore` dans Claude Code), délègue-lui cette étape : vingt lectures de fichiers n'ont pas à occuper la fenêtre où la spec va s'écrire. Passe-lui le nom de la feature, sa description et la racine du projet — **son contexte démarre vide**, il ne voit rien de notre conversation.
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
Les règles métier que la feature doit garantir, énoncées comme des affirmations vérifiables.
Inclut les cas limites et les erreurs, pas seulement le chemin heureux.
Cette section est la source de vérité de `/test-write` : ce qui n'y figure pas donnera un test dérivé du code, donc un test qui certifie le comportement au lieu de le vérifier.

## Risques et points ouverts
Ce qui peut casser ailleurs, les décisions que je dois trancher, les inconnues.
```

## Règles

- Décris **quoi** et **pourquoi**, pas le code ligne à ligne.
- Ne propose que des fichiers qui ont leur place dans l'arborescence existante.
- La section « Risques » ne doit pas être vide par confort. S'il n'y a vraiment aucun risque, la feature est sans doute triviale et n'a pas besoin de spec — dis-le-moi plutôt que de remplir.
- **N'implémente rien.** Cette commande produit un document ; on code après validation. Le seul fichier que tu écris est la spec.
- À la fin, donne-moi le chemin du fichier et les points ouverts qui attendent une décision de ma part.