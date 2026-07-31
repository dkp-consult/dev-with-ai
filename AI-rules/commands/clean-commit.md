---
description: Vérifie, nettoie et prépare un commit — sans le créer
argument-hint: [précisions ou message souhaité]
allowed-tools: Read, Glob, Grep, Edit, Write, Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git restore:*), Bash(git log:*), Bash(npm run:*), Bash(pnpm:*), Bash(yarn:*)
---

Prépare un commit propre. **Tu ne le crées pas.**
Tu vas jusqu'au staging et à la proposition du message, puis tu t'arrêtes : je relis et je commit moi-même.

Interdits pour cette commande : `git commit`, `git push`, `git commit --amend`, `--no-verify`.

## 1. État des lieux

- `git status`, `git diff` et `git diff --staged` pour voir exactement ce qui partirait.
- Si des changements sans rapport avec la tâche sont présents, signale-les et demande s'il faut les inclure ou les laisser de côté. Ne tranche pas seul.

## 2. Nettoyage

- Supprime les `console.log`, `debugger`, code commenté et fichiers temporaires introduits pendant le travail.
- Ne supprime pas les logs volontaires (logger applicatif, warnings utiles).
- Vérifie qu'aucun fichier généré ou dossier de dépendances ne part par erreur ; complète le `.gitignore` si besoin et dis-moi ce que tu y as ajouté.

Le nettoyage se limite à ça. Pas de refacto, pas de renommage, pas d'amélioration au passage.

## 3. Secrets

Relis le diff à la recherche de clés API, tokens, mots de passe, URLs de base de données, contenu de `.env`.
En cas de doute : **arrête-toi et signale-le.**

## 4. Qualité

Applique la procédure de `/verify` : ordre **typecheck → lint → format → test → build**, uniquement des commandes lues dans le projet, sortie brute en cas d'échec, et une gate non lancée n'est jamais une gate passée.

Pour la gate `test`, donne le **nombre de tests exécutés**. Une suite vide n'est pas une suite verte : marque-la `NON COUVERT`.

**Si une gate échoue, arrête-toi et rapporte.** Tu ne corriges pas de ta propre initiative : tu me montres l'erreur brute et tu proposes le correctif. Je décide si tu l'appliques.

## 5. Tests

Si le diff contient des modifications de fichiers de test **existants**, signale-le explicitement et **isole-les** : un commit `test:` distinct du `fix:` ou du `feat:` correspondant.

Un test modifié dans le même commit que le code qu'il vérifie est invisible en relecture. C'est exactement là que se cache une assertion affaiblie pour faire passer une gate.

Ajouter de nouveaux tests dans le même commit que la feature : normal et souhaitable. Modifier ou supprimer un test existant : à isoler, et à me justifier en une phrase par fichier.

## 6. Documentation

- Si le changement modifie l'usage (API publique, configuration, commande, comportement visible) : mets à jour le README ou le CHANGELOG.
- Sinon, ne crée pas de documentation inutile.

## 7. Staging

Stage **explicitement, fichier par fichier** : `git add chemin/du/fichier`.
Jamais `git add .`, jamais `git add -A`, jamais `git add -u`. Un fichier non lié à la tâche ne se retrouve pas dans l'index par accident.

Termine par `git diff --staged` pour confirmer que l'index correspond exactement à ce que tu annonces.

## 8. Message proposé

- Conventional Commits, en anglais, à l'impératif présent.
- Le sujet décrit l'intention, pas la mécanique : `fix(auth): prevent session loss on refresh`, pas `update auth.ts`.
- Corps uniquement si le « pourquoi » n'est pas évident à la lecture du diff.
- **Aucun trailer généré** : pas de `Co-Authored-By`, pas de mention d'un assistant ou d'un outil de génération, pas d'emoji. L'historique ne dit pas comment le code a été écrit.
- Si le diff couvre plusieurs sujets distincts, propose un découpage en plusieurs commits plutôt qu'un fourre-tout, avec le staging correspondant.

Précisions éventuelles : "$ARGUMENTS"

## Rapport final

Donne-moi :

1. les fichiers stagés, et ceux volontairement laissés de côté ;
2. les gates lancées **avec leur résultat réel** et la commande exacte, nombre de tests inclus ;
3. les fichiers de test existants modifiés, s'il y en a, et le commit `test:` séparé proposé ;
4. le message proposé, dans un bloc de code prêt à copier ;
5. la commande à lancer pour committer.

Si quelque chose n'a pas pu être vérifié, dis-le au lieu de le passer sous silence.