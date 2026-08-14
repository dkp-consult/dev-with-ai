---
description: Convertit le cahier des charges en cahier de dev — jalons, étapes, dépendances
argument-hint: [précisions sur le découpage, optionnel]
allowed-tools: Read, Glob, Grep, Write, Task, Agent, Bash(git log:*), Bash(ls:*), Bash(mkdir:*)
---

Convertis le cahier des charges en programme de développement.

Précisions : "$ARGUMENTS"

Ce document répond à **dans quel ordre, en combien de jalons, et quoi dépend de quoi**. Il ne contient pas le détail d'implémentation — c'est le travail de `/spec`, qui vient après, étape par étape.

## 1. Lis avant de découper

- `ai/cdc.md`. **S'il n'existe pas, arrête-toi** et propose de lancer `/cdc` d'abord. Un découpage sans cahier des charges découpe une intention floue en morceaux flous.
- Le `CLAUDE.md` du projet s'il existe, et le code réel : le découpage doit tenir compte de ce qui est déjà là.
- La section « Hors périmètre » du cahier des charges. Une étape qui la contredit ne doit pas exister.

## 2. Découpe

**Un jalon** est un ensemble cohérent qui livre quelque chose d'observable. À la fin d'un jalon, on peut montrer un résultat, pas un morceau de plomberie.

**Une étape** est une unité de travail qui produit un diff relisible — de l'ordre de cinquante à cent cinquante lignes. C'est la mesure qui compte : une étape dont le diff ne se relit pas en trois minutes est deux étapes.

Règles de découpe :

- Cinq à dix étapes par jalon. Au-delà, le jalon en cache deux.
- Une étape ne dépend jamais d'une étape d'un jalon **ultérieur**. Si c'est le cas, l'ordre des jalons est faux, ou l'étape appartient au jalon suivant.
- Une étape peut dépendre d'une autre étape du même jalon : indique-le.
- **Une étape bloquée par un jalon ultérieur reste dans le document**, marquée `BLOQUÉ`, avec ce qu'elle attend. C'est un cas normal et fréquent : un jalon de dix étapes dont six sont faisables aujourd'hui est un jalon bien décrit, pas un jalon raté.

## 3. Les critères de fin

Chaque jalon a une section « Fait quand » : des critères **vérifiables**, pas « ça marche ». Trois à cinq, pas plus.

Un critère vérifiable se teste ou s'observe : « un utilisateur non authentifié qui ouvre /panier est redirigé vers /connexion », pas « l'authentification est en place ».

Interdits : estimations en heures, priorités numériques, listes de plus de cinq critères.

## Fichier de sortie

`ai/cdd.md`, avec `mkdir -p ai`. **S'il existe, mets-le à jour** au lieu de l'écraser, et dis ce que tu as changé — en particulier si tu déplaces une étape d'un jalon à un autre.

## Format

```markdown
# Cahier de dev — [Projet]

## Vue d'ensemble
| Jalon | Livre | Dépend de |
|---|---|---|
| 1 | ... | — |
| 2 | ... | jalon 1 |

---

## Jalon 3 — [titre]

Dépend de : jalon 1 (auth), jalon 2 (catalogue)

### Étapes
- [ ] 3.1  [titre court, à l'infinitif]
- [ ] 3.2  [titre]                        dépend de 3.1
- [ ] 3.3  [titre]                        dépend de 3.1
- [ ] 3.7  [titre]                        BLOQUÉ — attend jalon 5 (facturation)

### Fait quand
- [ ] critère vérifiable
- [ ] critère vérifiable

### Décisions déjà prises
Ce qui est arrêté et ne doit pas être rediscuté à chaque session.
« Aucune pour l'instant » est une réponse valide.

### Risques
Ce qui peut faire déraper ce jalon. Concret.
```

## Règles

- **Le découpage est une proposition, pas une décision.** Présente-le et attends validation avant de considérer le document comme arrêté.
- **N'invente pas d'étapes** qui ne découlent pas du cahier des charges. Si une étape te semble nécessaire mais absente du CDC, signale-la à part : c'est peut-être le CDC qui est incomplet.
- Une étape dont tu ne sais pas dire ce qu'elle produit est mal découpée. Reprends-la.
- Les cases à cocher sont l'état d'avancement : elles se cochent au fil des étapes terminées. C'est ce document qui porte la progression, pas la conversation.
- À la fin, donne le chemin du fichier, le nombre de jalons et d'étapes, **et la liste des étapes bloquées avec ce qu'elles attendent**.
