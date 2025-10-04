---
description: Clean and prepare commit
agent: build
---

Prépare un commit propre et structuré :

1. Nettoyage
   - Supprime tous les logs, fichiers temporaires, debugs, ou artefacts inutiles.
   - Mets à jour/ajoute un .gitignore si besoin.

2. Code hygiene
   - Formatte le code (Prettier, ESLint, Black…).
   - Vérifie l’absence de secrets (clés API, tokens…).

3. Documentation
   - Si une solution est complexe ou non triviale → ajoute un .md dans /docs.
   - Si la feature modifie l’usage → adapte README.md ou CHANGELOG.md.

4. Git
   - Utilise des messages conformes au style Conventional Commits.
   - Suis mes précisions, si fournies :

"$ARGUMENTS"

5. Si aucun argument n’est donné → procède directement au commit.