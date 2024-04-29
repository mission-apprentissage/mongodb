# Créer un nouveau cluster

Cette section décrit comment créer un nouveau cluster, pour un nouvel environnement.

## Architecture Conseillée

Pour un environnement de production, il est recommandé d'avoir une architecture similaire à celle-ci:
- Un réseau privé dédié
- Un cluster de base de données sur plusieurs régions (au moins 2)
- Un cluster composé d'au moins 3 noeuds
- Un noeud principal sur la meme région que l'application
- Des noeuds secondaires de plus faible capacité

## Noeud principal

### Création de l'instance et du volume

Veuillez suivre la procédure sur [Création d'une instance et d'un volume externe associé](./instance.md) avant de poursuivre avec la documentation de déploiement.

### Définition de des variables

**vault.yml**

Ajouter les secrets liés à l'environnement dans le vault via `.bin/mna vault:edit`:

```yml
vault:
    <environnement>:
        KEYFILE: <string>
        root: <string>
        backup: <string>
        pmm: <string>
        users:
            - name: <string>
                password: <string>
                database: <string>
                roles: <string>
```

Avec:
    - `<environnement>`: Nom de l'environnement
    - `KEYFILE`: créer un secret via `pwgen -s 1024 1`
    - `root`: Mot de passe de l'utilisateur `root` de la base de données `pwgen -s 64 1`
    - `backup`: Mot de passe de l'utilisateur `backup` de la base de données `pwgen -s 64 1` utilisé pour les opérations de backup et restauration.
    - `pmm`: Mot de passe de l'utilisateur `pmm` de la base de données `pwgen -s 64 1` utilisé pour le monitoring percona.
    - `users`: Liste des utilisateurs à créer
        - `name`: Nom de l'utilisateur
        - `password`: Mot de passe de l'utilisateur `pwgen -s 64 1`
        - `database`: Nom de la base de données liée à l'utilisateur
        - `roles`: Liste des rôles de l'utilisateur séparés par une virgule

### Déploiement

1. Lancer le déploiement `.bin/mna deploy:initial:node <environnement>_<n>`
2. Redémarrer le serveur pour appliquer tous les changements

### Enregistrement DNS SRV

Créer un enregistrement DNS de type `SRV` sur [alwaysdata](https://www.alwaysdata.com/). Cet enregistrement correspond à l'adresse du cluster MongoDB.

Il faut créer un enregistrement de type `SRV` tel que:
- Hostname: `_mongodb._tcp.mongodb-<environnement>`
- Type: `SRV`
- Value: `5 27017 mongodb-<environnement>-<n>.apprentissage.beta.gouv.fr`
- Priority: `0`

### Vérification de l'installation

1. Connectez-vous au serveur via `ssh mongodb-<environnement>-<n>.apprentissage.beta.gouv.fr`
2. Passer en mode super utilisateur `sudo -i`
3. Vérifiez le status du replica set avec la commande `/opt/app/scripts/mongo.sh --eval 'db.adminCommand({replSetGetStatus: 1})'`. Vous devriez voir votre noeud, et avec le status `PRIMARY`.
4. Redémarrer le serveur pour appliquer tous les changements: `sudo reboot`
5. Connectez-vous au VPN
6. La connection au serveur via: `mongodb+srv//root:<password>@mongodb-<environnement>.apprentissage.beta.gouv.fr/?tls` avec `<password>`: Le mot de passe root tel que défini dans le vault.

## Noeuds suivants

Suivre la procédure sur [Ajouter un membre à un cluster existant](./add_member.md) pour ajouter les noeuds suivants.

## Monitoring

Veuillez vous référer à la documentation sur [Monitoring](../monitoring.md) pour activer le monitoring du cluster.

## Backup

N'oubliez pas d'activer les backups en suivant la procédure sur [Backup](../backup/backup.md).
