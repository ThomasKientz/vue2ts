# Boomerang

## Configuration

Il y a 2 variables d'environnement configurées avec une valeur par défaut dans le fichier `.env`.

VUE_APP_SUITE_NAME : nom de la suite iOS à utiliser pour les préferences utilisateurs.

VUE_APP_API_URL : adresse du serveur.

Il faut rebuilder le projet node.js (cf étape 4 ci dessous) après avoir modifié les variables d'environement ou pour mettre à jour l'app (par exemple après un pull).

## Setup

1. Installer Node.js (version 12 recommandée)
   https://nodejs.org/en/

2. Se placer à la racine du projet.

3. Installer les dépendances du projet.

   > `npm install`

4. Builder l'application Node.js

   > `npm run build-{platform}` (ex : `npm run build-ios`)

5. Synchroniser Capacitor
   > `npx cap sync`



### Serveurs

Il y a 2 serveurs disponibles :

#### 1- Développement

http://api.dev.boomerang-app.io/

Les emails ne sont pas envoyés. 
Le code de vérification pour vérifier l'email est retourné en réponse (visible dans la console.)


#### 2- Production

https://api.boomerang-app.io/

A utiliser le moins possible en dev. Juste pour validation finale.

## Projet Xcode

Nécessite Xcode (11.2.1 min) et CocoaPods.

Ouvrir le projet avec la commande :

> `npx cap open ios`

Ou ouvrir avec Xcode le fichier suivant :

> /ios/App/App.xcworkspace


