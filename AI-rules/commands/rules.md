---
description: Génère ou met à jour les règles du projet (CLAUDE.md + AGENTS.md)
argument-hint: [précisions sur le projet, optionnel]
---

Génère les règles du projet courant, pour que n'importe quel agent IA travaille correctement dessus sans avoir à tout redécouvrir à chaque session.

Précisions : "$ARGUMENTS"

## 1. Analyse le projet réel

Ne déduis rien du nom du dossier. Va lire :

- `package.json` — dépendances, et surtout les `scripts` réels
- La configuration : TypeScript, linter, formateur, tests, build
- L'arborescence : comment le code est réellement organisé
- 3-4 fichiers représentatifs : le style effectif, pas le style théorique
- `git log --oneline -30` : la convention de commit réellement pratiquée
- Un fichier de test existant : framework et patterns en place

## 2. Rédige les règles

```markdown
# [Nom du projet]

## Ce que fait ce projet
2-3 phrases : à quoi il sert, et pour qui.

## Stack
Langages, frameworks, versions qui comptent.

## Commandes
| But | Commande |
|---|---|
Uniquement des commandes qui existent vraiment dans le projet, vérifiées.

## Architecture
Comment le code est organisé, et surtout : **où placer un nouveau fichier**.
Les dossiers qui comptent et ce qu'on y met.

## Conventions
Nommage, structure des fichiers, gestion des erreurs, style de test.
Décris ce que fait le code existant, pas ce qu'il devrait faire.

## Pièges
Ce qui n'est pas devinable et fait perdre du temps : contournements, dépendances fragiles, zones à ne pas toucher, effets de bord connus.

## À ne pas faire
Les interdits spécifiques à ce projet.
```

## 3. Installe

Écris le contenu dans `CLAUDE.md` à la racine du projet.

Fais ensuite pointer `AGENTS.md` dessus, pour que Claude Code et Codex lisent le même fichier — une seule chose à maintenir. **Vérifie l'état de `AGENTS.md` avant d'y toucher, ne l'écrase jamais** :

```bash
if [ -L AGENTS.md ]; then
  if [ "$(readlink AGENTS.md)" = "CLAUDE.md" ]; then
    echo "OK — AGENTS.md pointe déjà sur CLAUDE.md"
  else
    echo "STOP — AGENTS.md est un lien vers $(readlink AGENTS.md)"
  fi
elif [ -e AGENTS.md ]; then
  echo "STOP — AGENTS.md est un fichier régulier, contenu à préserver"
else
  ln -s CLAUDE.md AGENTS.md && echo "OK — lien créé"
fi
```

Sur `STOP`, n'exécute rien : montre-moi le contenu existant de `AGENTS.md` et demande. S'il contient des règles qui ne sont pas dans `CLAUDE.md`, propose-moi la fusion avant tout remplacement.

N'utilise jamais `ln -sf` ici : le `-f` supprime la cible sans avertissement, y compris un fichier de règles écrit à la main.

Le dossier `ai/` est **versionné** : cahier des charges, cahier de dev, specs et rapports d'agents suivent le code. S'il figure dans le `.gitignore`, signale-le — c'est une ligne à retirer, pas à ajouter.

## Règles

- **Constate, ne prescris pas.** Ce fichier décrit le projet tel qu'il est. Si le code est incohérent, signale-le-moi plutôt que d'inventer une convention idéale.
- Une commande que tu n'as pas vue dans le projet ne va pas dans le tableau.
- **Court et dense** : ce fichier est chargé à chaque session. Tout ce qui ne change pas le comportement d'un agent est du bruit à supprimer.
- Si un `CLAUDE.md` existe déjà, mets-le à jour au lieu de l'écraser, et dis-moi ce que tu as changé.
