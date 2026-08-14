---
description: Audite les dépendances du lockfile — CVE, scripts non approuvés, signaux de typosquat
argument-hint: [périmètre, optionnel — par défaut toutes les dépendances]
allowed-tools: Read, Glob, Grep, Bash(pnpm audit:*), Bash(npm audit:*), Bash(yarn audit:*), Bash(pnpm approve-builds --list), Bash(npm view:*), Bash(npm ls:*), Bash(pnpm list:*), Bash(cat package.json), Bash(ls:*)
---

Audite les dépendances de ce projet : "$ARGUMENTS"

**Lecture seule stricte.** Tu ne mets à jour aucun paquet, tu ne modifies ni `package.json` ni le lockfile, tu n'installes rien. La décision de mettre à jour n'est pas la tienne.

## 0. Identifie le gestionnaire

Depuis le lockfile présent : `pnpm-lock.yaml` → pnpm, `package-lock.json` → npm, `yarn.lock` → yarn. N'en mélange pas deux. Si aucun lockfile n'existe, dis-le et arrête-toi : il n'y a rien à auditer de fiable.

## 1. CVE connues — le socle

```
pnpm audit --json      npm audit --json      yarn audit --json
```

Groupe par sévérité, et pour chaque vulnérabilité donne **le chemin de dépendance qui l'introduit** — c'est ce qui dit si tu peux agir ou si tu subis une transitive.

Distingue ce qui est corrigeable par une montée de version de ce qui ne l'est pas. Une CVE critique sans correctif disponible est une décision, pas une tâche.

## 2. Paquets à scripts non approuvés

Sur pnpm 10, les scripts de cycle de vie des dépendances ne s'exécutent plus par défaut :

```
pnpm approve-builds --list
```

Cette liste est **ce qui aurait tourné sur la machine sans cette protection**. Chaque entrée mérite un regard : un paquet de build natif qui demande à compiler est normal ; un paquet de test ou un utilitaire qui demande un `postinstall` l'est beaucoup moins.

Sur npm et yarn, il n'y a pas d'équivalent : signale-le et rappelle que l'installation doit passer par `--ignore-scripts`.

## 3. Fraîcheur de publication

Pour chaque dépendance **directe**, la date de publication de la version exacte installée :

```
npm view <paquet>@<version> time --json
```

Un paquet publié il y a moins d'une semaine dans un projet stable est le **signal numéro un** d'une compromission de chaîne d'approvisionnement. Signale tout ce qui a moins de trente jours, avec la date.

## 4. Signaux de typosquat

Pour chaque dépendance directe : téléchargements hebdomadaires, âge du paquet, présence d'un dépôt Git déclaré, nombre de mainteneurs.

```
npm view <paquet> repository.url maintainers time.created
```

Ce qui doit sauter aux yeux : un paquet à quelques dizaines de téléchargements par semaine à côté d'un homonyme à plusieurs millions, un paquet sans dépôt public, un paquet créé il y a trois semaines.

Regarde aussi les **noms voisins** : un caractère de différence avec un paquet très connu, un tiret en plus, un scope manquant (`testing-library/react` au lieu de `@testing-library/react`).

## 5. Écart lockfile ↔ `package.json`

Un paquet présent dans le lockfile que personne ne déclare, ou une version qui ne correspond pas à la plage demandée. Signale l'écart sans le corriger.

## Format

```markdown
## Périmètre
Gestionnaire : <pnpm|npm|yarn> — N dépendances directes, N transitives

## CVE
| Sévérité | Paquet | Version | Via | Correctif |
|---|---|---|---|---|
Sortie brute pour les critiques et les élevées.

## Scripts non approuvés
Un par ligne, avec ce que le paquet prétend faire.
« Aucun » ou « non applicable (npm/yarn) ».

## Publiés récemment
Paquet, version, date. Tout ce qui a moins de 30 jours.

## Signaux faibles
Ce qui mérite un œil : téléchargements anormalement bas, pas de dépôt,
nom voisin d'un paquet connu.

## Écarts lockfile
« Aucun » si aucun.

## Les trois d'abord
Si tu ne devais traiter que trois choses, lesquelles et pourquoi.
```

## Ce que cette commande ne fait pas

À écrire en fin de rapport, systématiquement :

> Cet audit ne détecte ni le code malveillant dans un paquet légitime, ni une CVE non encore publiée. Un rapport sans constat veut dire « rien de connu », pas « sûr ».

C'est important : un vert qui se prend pour une certification est plus dangereux qu'un rouge.

## Règles

- **N'exécute aucune commande qui écrit.** Pas de `pnpm update`, pas de `npm audit fix`, pas de `pnpm approve-builds` — seulement sa variante `--list`.
- Si une commande d'audit n'existe pas pour le gestionnaire en place, marque la section « non disponible » plutôt que de l'inventer.
- Les appels à `npm view` sont réseau : s'ils échouent, dis-le, ne devine pas les valeurs.
- Le rapport va dans ta réponse. **N'écris aucun fichier.**
