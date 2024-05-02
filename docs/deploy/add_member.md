# Ajouter un membre à un cluster existant

Cette section décrit comment ajouter un membre à un cluster existant.

## Création de l'instance et du volume

Veuillez suivre la procédure sur [Création d'une instance et d'un volume externe associé](./instance.md) avant de poursuivre avec la documentation de déploiement.

## Installation du serveur

Veuillez lancer la commande `.bin/mna deploy:extra:node <environnement>_<n>` pour déployer le serveur.

## Vérification de l'installation

1. Connectez-vous au serveur via `ssh mongodb-<environnement>-<n>.apprentissage.beta.gouv.fr`
2. Passer en mode super utilisateur `sudo -i`
3. Vérifiez le status du replica set avec la commande `/opt/app/scripts/mongo.sh --eval 'db.adminCommand({replSetGetStatus: 1})'`. Vous devriez voir le nouveau noeud, et attendre que le status soit `PRIMARY` ou `SECONDARY`, si le status est 'STARTUP2' vous pouvez obtenir une estimation du temps restant avec la valeur `initialSyncStatus`
4. Redémarrer le serveur pour appliquer tous les changements: `sudo reboot`
5. Connectez-vous au VPN
6. La connection au serveur via: `mongodb+srv//root:<password>@mongodb-<environnement>.apprentissage.beta.gouv.fr/?tls` avec `<password>`: Le mot de passe root tel que défini dans le vault.
7. Vérifiez que le noeud a bien redémarré via la commande `rs.status()` dans le shell mongo.

## Enregistrement DNS SRV

Créer un enregistrement DNS de type `SRV` sur [alwaysdata](https://www.alwaysdata.com/). Cet enregistrement correspond à l'adresse du cluster MongoDB.

Il faut créer un enregistrement de type `SRV` tel que:

- Hostname: `_mongodb._tcp.mongodb-<environnement>`
- Type: `SRV`
- Value: `1 27017 mongodb-<environnement>-<n>.apprentissage.beta.gouv.fr`
- Priority: `1`

### Monitoring

Veuillez vous référer à la documentation sur [Monitoring](../monitoring.md) pour activer le monitoring du cluster.
