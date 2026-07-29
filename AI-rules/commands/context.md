---
description: Fait le point sur le travail en cours — déblocage ou passation entre outils
argument-hint: [le blocage ou le contexte à capturer]
allowed-tools: Read, Glob, Grep, Write, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(date:*), Bash(mkdir:*), Bash(ls:*)
---

Fais le point sur l'état réel du travail en cours.
Deux usages : me débloquer, ou permettre de reprendre ailleurs (autre session, autre outil IA) sans tout réexpliquer.

Élément fourni : "$ARGUMENTS"

## 1. Constate

- `git status`, `git diff`, `git log --oneline -10` pour situer le travail.
- Lis les fichiers réellement touchés. Ne suppose pas leur contenu.
- Repère la dernière spec ou le dernier point de situation dans `ai/` s'ils existent.

## 2. Écris le point

Crée le dossier si besoin (`mkdir -p ai/context`), récupère l'horodatage avec `date +%Y-%m-%d-%H%M%S` — **ne l'invente pas** — puis écris dans `ai/context/[timestamp].context.md` :

```markdown
# Point de situation — [date]

## Objectif
Ce qu'on cherche à faire, et pourquoi.

## Où on en est
Ce qui est fait et vérifié / fait mais non vérifié / pas commencé.
Sois rigoureux sur cette distinction : c'est tout l'intérêt du document.

## Blocage
Le symptôme exact (message d'erreur brut, comportement observé), pas ton interprétation.
« Aucun blocage » est une réponse valide.

## Déjà tenté
Ce qui a été essayé et pourquoi ça n'a pas marché, pour éviter de refaire la même impasse.

## Fichiers concernés
Chemins, et à quoi ils servent dans cette tâche.

## Pistes
2-3 hypothèses priorisées, avec ce qui permettrait de trancher chacune.

## Pour reprendre
Ce qu'il faut savoir pour continuer à froid, dans une autre session ou un autre outil.
```

## Règles

- Distingue ce que tu as **vérifié** de ce que tu **supposes**. Un point de situation faux est pire que pas de point du tout.
- Cite les erreurs brutes, ne les paraphrase pas.
- **Masque les secrets.** Ce document est fait pour être relu ailleurs, potentiellement collé dans un autre outil. Remplace par `[REDACTED]` toute clé d'API, token, mot de passe, chaîne de connexion, en-tête d'authentification ou identifiant client apparaissant dans une trace d'erreur ou un extrait de code. Garde la structure de l'erreur, retire la valeur.
- **Une page maximum.** Un point de situation qu'on ne relit pas ne sert à rien. Si le contexte déborde, coupe dans « Déjà tenté » et « Fichiers concernés », jamais dans « Blocage ».
- **Ne corrige rien ici** : cette commande fait le point, elle ne répare pas. Le seul fichier que tu écris est le point de situation lui-même.
- À la fin, donne-moi le chemin du fichier écrit et un résumé en trois lignes.