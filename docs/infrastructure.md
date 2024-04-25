# Infrastucture MongoDB

Cette documentation vise à expliquer l'infrastructure d'un cluster et non pas à l'installation et la gestion des serveurs.

> [!WARNING]
> Ce guide peut être utile pour résoudre des problèmes de maintenance manuellement.

Les clusters sont composés de noeuds (serveurs) MongoDB. Par convention les clusters sont nommés `mongodb-<environnement>` et leurs noeuds `mongodb-<environnement>-<n>`.

## Noeud MongoDB

### Volume externe

Un volume externe est monté sur le serveur sur `/mnt/data` pour le stockage des données. Il est possible de lister les volumes montés avec la commande `df -h`.

Le volume contient donc:
- `/mnt/data/db` pour les données MongoDB
- `/mnt/data/mongodb.pem` le certificat TLS utilisé
- `/mnt/data/keyfile` le keyfile pour l'authentification des membres du cluster

Le volume est monté automatiquement au démarrage du serveur, via le fichier `/etc/fstab`.

### Configuration

La configuration de MongoDB est faite dans le fichier `/etc/mongod.conf`. Pour plus d'information quant à la configuration de MongoDB, se référer à la [documentation officielle](https://www.mongodb.com/docs/manual/reference/configuration-options/).

**Authentification**

- L'authentification est activée dans le fichier de configuration, tous les accès à la base de données doivent être authentifiés.
- Les membres du cluster sont authentifiés avec le keyfile `/mnt/data/keyfile`. Le keyfile provient du vault et est spécifique à chaque cluster.

**Chiffrement des connexions**

- Le chiffrement des connexions est activé dans le fichier de configuration, tous les accès à la base de données doivent être chiffrés.
- Le certificat utilisé est `/mnt/data/mongodb.pem` 
- Les clients ne doivent pas fournir de certificat pour se connecter.
- Les protocoles `TLSv1.0` et `TLSv1.1` sont désactivés.

**Stockage des données**

- Les données sont stockées dans le volume externe `/mnt/data/db`.
- Les données des differentes bases sont stockées dans des sous-répertoires distincts.

### Utilisateurs

Les utilisateurs ne sont pas créés au niveau des noeuds mais au niveau du cluster car ils sont partagés entre les différents noeuds.

### Nom de domaine

Chaque noeud dispose de son propre nom de dommaine suivant la convention `mongodb-<environnement>-<n>.apprentissage.beta.gouv.fr`. Le noeud est donc accessible directement via son propre nom de domaine.

Cependant ce nom de domaine ne doit pas être utilisé directement pour se connecter au cluster. Il est recommandé d'utiliser le nom de domaine du cluster.

**Gestion du certificat**

Le certificat est renouvelé automatiquement par la configuration contenue dans le dépot [infra](https://github.com/mission-apprentissage/infra).

Cependant les certificats générés par certbot ne peuvent pas être utilisés directement par MongoDB. Il est nécessaire de créer un fichier PEM contenant la clé privée et la chaine de certificat complète. Pour plus d'information sur la création de ce fichier, se référer à la [documentation officielle](https://www.mongodb.com/docs/manual/tutorial/configure-ssl/).

Ainsi sur le serveur se trouve 2 scripts pour la gestion du certificat:
- `/opt/app/scripts/update_cert.sh`: crée le fichier `/mnt/data/mongodb.pem` à partir des certificats générés par certbot.
- `/opt/app/scripts/rotate_cert.sh`: met à jour le certificat via le script `update_cert.sh` et envoie le signal de rotation des certificats à MongoDB [db.rotateCertificate()](https://www.mongodb.com/docs/manual/reference/method/db.rotateCertificates/).

**Enregistement DNS**

Les noms de domaine sont enregistrés dans le DNS de la zone `apprentissage.beta.gouv.fr` via un entregistrement de type `A` pour chaque noeud.

La gestion du DNS est faite via [alwaydata](https://www.alwaysdata.com/).

**Hostname**

Le hostname du serveur est configuré pour correspondre au nom de domaine du serveur. Il est possible de le vérifier avec la commande `hostname`, le résultat doit correspondre au nom de domaine du serveur.

### Backup

> [!IMPORTANT]
> À ce stade aucun backup n'est configuré.

### Connexion directe au noeud

Il est parfois nécessaire de se connecter directement au noeud pour réaliser certaines opérations de maintenance. 

Mais conmpte tenu de la configuration du serveur, il est assez complexe de se connecter correctement:
- l'authentification est requise, il est nécessaire de fournir le keyfile pour se connecter.
- l'utilisation du keyfile nécessite de se connecter via l'utilisateur `__system` sur la base `local`
- le mode TLS est requis, ce qui nécessite d'utiliser le nom de domaine du serveur pour se connecter.

Ainsi nous avons créé 2 scripts pour faciliter la connexion au serveur: 
- `/opt/app/scripts/mongo_local.sh`: pour se connecter directement au serveur avec les paramètres nécessaires.
- `/opt/app/scripts/mongo.sh`: pour se connecter au cluster avec les paramètres nécessaires via l'utilisateur `root`.

## Cluster MongoDB

Les clusters MongoDB sont constitués de plusieurs noeuds. La configuration de chaque noeud est identique, à l'exception du nom de domaine et de l'adresse IP.

Pour chaque cluster il existe un noeud principal (`master`), les autres noeuds sont des membres secondaires (`secondary`). Le noeud principal est le seul noeud acceptant les écritures, les autres noeuds sont en lecture seule. Le noeud principal peut changer, le noeud principal est élu automatiquement par les membres du cluster. Pour le bon fonctionnement de l'algorithme d'élection, il est nécessaire d'avoir un nombre impair de noeuds. Pour plus de détails sur l'élection du noeud principal, se référer à la [documentation officielle](https://www.mongodb.com/docs/manual/core/replica-set-elections/).

Dans notre cas d'usage, nous n'utilisons pas intensivement les noeuds secondaires. Ils sont principalement utilisés pour la redondance et la tolérance aux pannes. Ainsi le cluster est constitué d'un serveur principal disposant de resources (CPU & RAM) plus importantes que les noeuds secondaires. Afin d'assurer que ce serveur soit élu comme noeud principal, il est configuré avec une priorité plus élevée que les autres noeuds.

### Gestion du Replica Set

Une fois connecté à un des noeuds du cluster (`/opt/app/scripts/mongo.sh`), il est possible de gérer le replica set via la commande `rs`.

Vous pouvez consulter la [Deploy a Replica Set](https://www.mongodb.com/docs/manual/tutorial/deploy-replica-set/#std-label-server-replica-set-deploy) pour plus de détails.

**Initialisation**

Un noeud qui n'appartient à aucun replica set peut initialiser un nouveau replica set avec la commande `rs.initiate()`.

> [!WARNING]
> Cette commande est spécifique pour la création initiale d'un nouveau replica set. Ne pas utiliser cette commande si le noeud doit rejoindre un replica set existant.

**Statut**

Il est possible de consulter le statut du replica set avec la commande `rs.status()`. Cette commande permet de voir les membres du replica set, le noeud principal, les secondaires, les états de synchronisation, etc.

**Ajout d'un membre**

À partir du noeud principal, il est possible d'ajouter un autre noeud au replica set avec la commande `rs.add()`. Veuillez consulter [Add Members to a Replica Set](https://www.mongodb.com/docs/manual/tutorial/expand-replica-set/) pour plus de détails.

**Suppression d'un membre**

Il est possible de supprimer un membre du replica set avec la commande `rs.remove()`. Veuillez consulter [Remove Members from Replica Set](https://www.mongodb.com/docs/manual/tutorial/remove-replica-set-member/) pour plus de détails.

### Enregistrement SRV

L'enregistrement SRV permet de simplifier la connexion au cluster en fournissant un nom de domaine unique pour le cluster. Il s'agit d'un enregistrement DNS spécifiant la liste des noeuds du cluster, il permet aux clients de se connecter au cluster sans avoir à spécifier les noeuds individuellement. Pour plus d'informations sur l'enregistrement SRV, se référer à la [documentation officielle](https://www.mongodb.com/docs/manual/reference/connection-string/#srv-connection-format).

L'enregistrement SRV est configuré dans le DNS de la zone `apprentissage.beta.gouv.fr` via un enregistrement de type `SRV` sur [alwaysdata](https://www.alwaysdata.com/). L'enregistrement SRV est de la forme `_mongodb._tcp.<cluster>.apprentissage.beta.gouv.fr`. Chaque noeud du cluster doit être enregistré dans l'enregistrement SRV avec la valeur `0 5 27017 mongodb-<environnement>-<n>.apprentissage.beta.gouv.fr`.

### Gestion des utilisateurs

La liste des utilisateurs est définie dans le vault sous la clé `vault.<environnement>.users`, la configuration de chaque utilisateur est la suivante:
- `username`: le nom d'utilisateur
- `password`: le mot de passe
- `roles`: la liste des rôles de l'utilisateur séparés par des virgules. Veuillez consulter la [Built-In Roles](https://www.mongodb.com/docs/manual/reference/built-in-roles/) pour la liste des roles par defaut.
- `database`: la base de données sur laquelle l'utilisateur est créé.

Pour se connecter à la base de donnée l'utilisateur devra utiliser la chaine de connexion `mongodb+srv://<username>:<password>@mongodb-<environnement>.apprentissage.beta.gouv.fr/<database>?tsl=true`.

Pour gérer certains utilisateurs manuellement, veuillez consulter la [Manage Users and Roles](https://www.mongodb.com/docs/manual/tutorial/manage-users-and-roles/).

