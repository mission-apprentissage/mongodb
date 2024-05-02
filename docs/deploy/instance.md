# Création d'une instance et d'un volume externe associé

Cette page décrit comment provisionner un serveur pouvant être utiliser dans le cadre de la mise en place d'un cluster.

Il est nécessaire d'utiliser [Public Cloud Compute](https://www.ovhcloud.com/fr/public-cloud/compute/) pour le serveur et non pas un Virtual Private Server (VPS).

En effet les VPS présentent plusieurs limitations:
- Pas de support pour les volumes additionnels
- Le volume principal est limité à 500Go
- Pas de support pour les snapshots

## Création de l'instance

1. Se connecter à l'interface d'OVH
2. Aller dans le menu `Public Cloud` > `Compute` > `Instances`
3. Cliquer sur `Créer une instance`
   1. Sélectionner un modèle
   2. Sélectionner une région (par exemple `GRA11`)
   3. Sélectionner l'image `Ubuntu 22.04` avec la clé SSH `Github User`
   4. Utiliser une instance flexible; Nommer l'instance suivant le format `mongodb-<environnement>-<n>`
   5. Configurer le réseau en mode `Public`
   6. Cliquer sur `Créer une instance`

## Création du volume

1. Aller dans le menu `Public Cloud` > `Storage` > `Block Storage`
2. Cliquer sur `Créer un volume`
   1. Sélectionner une région identique à l'instance précédente (par exemple `GRA11`)
   2. Choisir le type de volume `high-speed-gen2`
   3. Choisir la taille du volume (par exemple `200Go`)
   4. Nommer le volume suivant le format `mongodb-<environnement>-<n>`
   5. Cliquer sur `Créer le volume`

## Attachement du volume

1. Aller dans le menu `Public Cloud` > `Compute` > `Instances`
2. Cliquer sur l'instance créée précédemment
3. Dans la section `Volumes`, cliquer sur `Ajouter un volume`
4. Sélectionner le volume créé précédemment et cliquer sur `Ajouter le volume`

## Setup Infra

Veuillez suivre la procédure du [dépot infra](https://github.com/mission-apprentissage/infra/blob/main/docs/provisionning.md) pour la configuration du serveur avec les ajustements suivants:

- Déclaration de l'envrionnement
  - Nommer l'environnement suivant la convention `mongodb-<environnement>-<n>`
  - Les variables `dns_name` & `host_name` doivent être nommées suivant la convention `mongodb-<environnement>-<n>.apprentissage.beta.gouv.fr`
  - La variable `env_type` doit être `mongodb-<environnement>`
- Création du nom de domaine
  - Créer un enregistrement DNS de type `A` pour le nom de domaine `mongodb-<environnement>-<n>.apprentissage.beta.gouv.fr` pointant vers l'adresse IP de l'instance.
- La connexion SSH se fera via `ssh mongodb-<environnement>-<n>.apprentissage.beta.gouv.fr`

> [!CAUTION]
> Pensez bien à modifier les règles de firewall dans le fichier `.bin/scripts/ovh/ovh-nodejs-client/firewall.js` sur le dépôt `infra` pour autoriser l'accès à la base de données.

## Formatage du volume

1. Se connecter à l'instance `ssh mongodb-<environnement>-<n>.apprentissage.beta.gouv.fr`
2. Passer en mode super utilisateur `sudo -i`
3. Utiliser la commande `lsblk` pour identifier le volume à formater
4. Formater le volume avec la commande `mkfs -t xfs -L MONGO_DATA /dev/<device-name>` (remplacer `<device-name>` par le nom du volume identifié par `lsblk`)

### Définition des variables d'environnement

Ajouter l'environnement dans le fichier `.infra/env.ini`:

```ini
[mongodb-<environnement>-<n>]
<ip>
[mongodb-<environnement>-<n>:vars]
dns_name=mongodb-<environnement>-<n>.apprentissage.beta.gouv.fr
host_name=mongodb-<environnement>-<n>
env_type=mongodb-<environnement>
```

Avec:

- `<environnement>`: Nom de l'environnement
- `<n>`: Numéro du noeud
- `<ip>`: Adresse IP de l'instance
