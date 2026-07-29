---
description: Explique un fichier, une fonction ou un extrait de code
argument-hint: <chemin[:lignes] | symbole | code collé> [+ question précise]
allowed-tools: Read, Glob, Grep, Bash(git log:*), Bash(git blame:*), Bash(ls:*)
---

Explique le code désigné par : "$ARGUMENTS"

Tu es en lecture seule. Tu ne modifies rien et tu ne proposes pas de correctif, sauf si je le demande.

## 1. Identifie la cible

| Ce que je fournis | Ce que tu fais |
|---|---|
| Un chemin de fichier | Lis le fichier entier |
| Un chemin + plage (`src/a.ts:40-80`) | Lis la plage, et le reste du fichier pour le contexte |
| Un nom de symbole | Trouve-le au `Grep`, lis sa définition |
| Du code collé | Travaille dessus tel quel, et signale que tu n'as pas le contexte du projet |
| Rien | Demande ce que je veux voir expliqué |

**Si une question précise accompagne la cible, c'est elle qui pilote.** Réponds-y d'abord et concentre l'explication dessus. Ne déroule pas une visite guidée complète quand je demande pourquoi une ligne échoue.

## 2. Va chercher le contexte

Lire le fichier ne suffit pas. Avant d'expliquer :

- **Qui l'appelle** — `Grep` sur les symboles exportés ou le nom du module.
- **Ce qu'il appelle** — les imports internes qui portent la logique réelle.
- **Les types** — remonte aux définitions plutôt que de deviner la forme des données.
- **Les libs externes** — vérifie la version dans le `package.json` avant d'expliquer un comportement qui en dépend.
- **L'histoire, si le code surprend** — `git log -5 --oneline <fichier>` ou `git blame` sur la zone concernée. Un contournement bizarre s'explique souvent par son commit.

## 3. Explique

Structure la réponse ainsi, en supprimant les sections sans matière :

**Rôle** — à quoi ça sert dans ce projet et pourquoi ça existe. Deux ou trois phrases.

**Fonctionnement** — le flow réel, les décisions structurantes, les cas gérés. Suis la logique, pas l'ordre des lignes.

**Ce qui n'est pas évident** — la partie qui a de la valeur : couplages implicites, effets de bord, conditions non triviales, contournements, hypothèses non écrites, ce qui casse si on y touche.

**Zones douteuses** — bugs possibles, code mort, gestion d'erreur absente. Tu signales, tu ne corriges pas, et tu n'en fais pas une review complète : deux ou trois points maximum, les plus sérieux.

**Non vérifié** — ce que tu supposes sans avoir pu le confirmer.

## Règles

- **Pas de paraphrase ligne à ligne.** « Cette ligne déclare une constante » n'apporte rien. Si un passage se comprend à la lecture, ne le commente pas.
- **Pas de cours sur le langage ou le framework.** Je connais TypeScript, React, Node, SQL et Git. Explique ce que fait *ce* code, pas ce qu'est une promesse ou un `useEffect`. Si un mécanisme vraiment pointu est en jeu, une phrase suffit.
- **Distingue ce que tu as lu de ce que tu supposes.** Si tu n'as pas ouvert un fichier appelé, dis-le au lieu d'inventer son comportement.
- **Cite les emplacements** sous la forme `chemin/fichier.ts:42`, pour que je saute directement au bon endroit.
- **Si le code est trivial et se lit tout seul, dis-le en une ligne** plutôt que de fabriquer de l'explication.
- Longueur proportionnelle à la cible : une fonction de dix lignes ne mérite pas trois écrans.
- **N'écris aucun fichier.** L'explication va dans ta réponse, pas sur le disque.
