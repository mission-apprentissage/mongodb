# Créer un nouveau cluster

Cette section décrit comment créer un nouveau cluster, pour un nouvel environnement.

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
    - `users`: Liste des utilisateurs à créer
        - `name`: Nom de l'utilisateur
        - `password`: Mot de passe de l'utilisateur `pwgen -s 64 1`
        - `database`: Nom de la base de données liée à l'utilisateur
        - `roles`: Liste des rôles de l'utilisateur séparés par une virgule

### Déploiement

1. Lancer le déploiement `.bin/mna deploy:initial:node <environnement>-<n>`
2. Redémarrer le serveur pour appliquer tous les changements

## Noeuds suivants

Suivre la procédure sur [Ajouter un membre à un cluster existant](./add_member.md) pour ajouter les noeuds suivants.

## Backup

N'oubliez pas d'activer les backups en suivant la procédure sur [Backup](../backup/backup.md).
