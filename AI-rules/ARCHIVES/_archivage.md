# Archives

Contenu de la version précédente de ce repo, conservé pour référence.
Archivé le **29 juillet 2026**, lors du passage d'OpenCode à Claude Code + Codex.

## Ce qu'il y a ici

| Fichier | Ce que c'était |
|---|---|
| `COMMANDES/` | Les 7 commandes au format OpenCode (frontmatter `agent: build`) |
| `agents.md` | Le guide complet — règles et commandes mélangées |
| `readme.md` | Documentation du repo |
| `readme-racine.md` | Copie strictement identique de `readme.md`, qui se trouvait à la racine |

## Pourquoi ça a été remplacé

- **Frontmatter OpenCode** (`agent: build`) — métadonnée morte pour Claude Code et Codex.
- **`spec.md` et `code.md` codaient React-Redux en dur** (`*.reducer.ts`, `*.usecase.ts`, `src/features/[group]/`) alors que le guide se présentait comme agnostique. Sur un projet d'une autre stack, ces commandes inventaient une architecture inexistante.
- **Trois fichiers de documentation** dont deux strictement identiques — le problème de duplication que ce repo devait résoudre existait à l'intérieur du repo.
- **Doublons avec le natif** : `/plan` (mode Plan), `/review` (`/code-review`), `/code` (sans substance) ont été abandonnés.
- **Règles et commandes mélangées** dans `agents.md`, ce qui empêchait d'utiliser la partie « règles » comme configuration globale.

Rien n'est perdu : l'historique git conserve tout, et `git log --follow <fichier>` suit les fichiers à travers le déplacement.
