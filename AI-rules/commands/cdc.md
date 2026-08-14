---
description: Rédige le cahier des charges d'un projet — le quoi et le pourquoi, avant tout découpage
argument-hint: [nom du projet] — [ce que tu veux en faire, ou le chemin d'un POC/de notes]
allowed-tools: Read, Glob, Grep, Write, Task, Agent, Bash(git log:*), Bash(ls:*), Bash(mkdir:*), Bash(cat:*)
---

Rédige le cahier des charges de : "$ARGUMENTS"

Ce document répond à **où veut-on arriver, et pourquoi**. Pas à comment. Aucune techno n'y figure, aucun nom de fichier, aucun jalon — c'est le travail de `/cdd`, qui vient après.

## 1. Identifie ton point de départ

| Ce qu'on te fournit | Ce que tu fais |
|---|---|
| Un POC qui tourne | Lis le code réellement, pas le README. Constate ce qu'il fait **déjà** et distingue-le de ce qu'on veut atteindre. |
| Un chemin vers des notes, un fichier, du texte collé | Pars de là, structure, et relève les trous. |
| Rien, juste ce qu'on te raconte | **Pose tes questions avant d'écrire une ligne.** |

Le POC est **optionnel**. La plupart des projets démarrent sur une idée et trois notes ; c'est un cas normal, pas un cas dégradé.

## 2. Challenge avant d'écrire

C'est l'étape qui a de la valeur. Si tu te contentes de mettre en forme ce qu'on te dit, tu ne sers à rien.

Cherche :

- **ce qui ne tient pas** — une contradiction interne, un périmètre plus large que l'objectif annoncé ;
- **ce qui n'a pas été anticipé** — les cas d'erreur, la reprise sur incident, la migration de l'existant, deux utilisateurs qui font la même chose en même temps, ce qui se passe quand le prestataire tiers tombe ;
- **ce qui ne vaut pas le coup** — la fonctionnalité qui coûtera trois jours et servira deux fois ;
- **ce qui manque et qu'on ne voit pas** — authentification, sauvegarde, facturation, obligations légales.

Dis-le en une ou deux phrases par point, avec ce que tu proposes à la place. **Si l'idée ne tient pas, dis-le franchement.** Une validation de complaisance coûte plus cher qu'un désaccord argumenté.

## 3. Ne comble pas les trous

Sur une entrée pauvre, tu ne remplis pas. Un cahier des charges plein d'hypothèses inventées est pire qu'un document court avec cinq questions ouvertes : les hypothèses inventées se découvrent trois jalons plus tard, quand elles coûtent cher.

Tes questions vont dans la section « Questions ouvertes », numérotées, pour qu'on te réponde par numéro.

## Fichier de sortie

`ai/cdc.md`, avec `mkdir -p ai` si le dossier n'existe pas.

**S'il existe déjà, mets-le à jour au lieu de l'écraser**, et dis ce que tu as changé.

## Format

```markdown
# [Projet]

## Le problème
Ce qu'on cherche à résoudre, et pour qui. Deux ou trois phrases.
Le problème, pas la solution.

## Ce qui existe déjà
[Si POC] Ce que le prototype fait réellement, constaté dans le code.
[Sinon] « Rien — projet neuf. »

## Ce qu'on veut atteindre
En français, du point de vue de l'usage. Ce qu'un utilisateur pourra faire
qu'il ne peut pas faire aujourd'hui. Aucune techno ici.

## Hors périmètre
Ce qu'on ne fera pas, et pourquoi.
C'est la section qui évite la dérive, et celle qui permettra à /cdd
de refuser une étape qui déborde. Elle ne doit pas être vide.

## Contraintes
Techniques, réglementaires, budget, délai, hébergement, existant à préserver.

## Questions ouvertes
Numérotées. Ce qui doit être tranché avant d'écrire le cahier de dev.
```

## Règles

- **Décris le quoi, jamais le comment.** Si tu te surprends à citer un fichier ou un framework, tu es au mauvais niveau.
- **N'implémente rien.** Le seul fichier que tu écris est `ai/cdc.md`.
- La section « Hors périmètre » ne doit pas être vide par confort. Si tu n'arrives pas à la remplir, c'est que le périmètre n'est pas défini — dis-le.
- À la fin, donne le chemin du fichier et **les questions ouvertes en clair dans ta réponse**, pour qu'on puisse y répondre sans ouvrir le document.
