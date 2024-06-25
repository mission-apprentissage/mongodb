# Migration

## Création du nouveau cluster

Veuillez suivre la procédure [Créer un nouveau cluster](./docs/deploy/initial.md).

> [!IMPORTANT]  
> N'oubliez pas de créer les utilisateurs nécessaires pour votre application (typiquement app & metabase).

## Compatibilité

> [!CAUTION]
> Le nouveau cluster utilise MongoDB 7.0, il est nécessaire de vérifier:
>
> - la compatibilité de vos drivers avec MongoDB 7.0 (voir la [compatibilité des drivers NodeJS](https://www.mongodb.com/docs/drivers/node/current/compatibility/#compatibility-table-legend))
> - la version de votre MongoDB actuel doit etre au **minimum 6.0** pour pouvoir migrer vers MongoDB 7.0.

### Feature Compatibility Version

> [!CAUTION]
> Effectuer uniquement si la version de votre cluster actuel est 6.0

1. Connectez-vous à un membre du cluster actuel
2. Passez en mode super utilisateur:
   ```bash
   sudo -i
   ```
3. Lancez la commande suivante:
   ```bash
   /opt/app/scripts/mongo.sh --eval 'db.adminCommand( { setFeatureCompatibilityVersion: "6.0", confirm: true } )'
   ```

## Connexion au cluster actuel

Afin de pouvoir réaliser la migration, il est vous devez:

- Ajouter l'ip du nouveau cluster à la whitelist de votre cluster actuel.
- Créer un utilisateur avec le role `backup` sur le cluster actuel.

## Test de la migration

L'idée est de tester la migration pour valider le fonctionnement sans nécessiter de période de maintenance.

1. Connectez-vous à un membre du cluster actuel
2. Passez en mode super utilisateur:
   ```bash
   sudo -i
   ```
3. Installez tmux si ce n'est pas déjà fait:
   ```bash
   sudo apt-get install tmux
   ```
4. Lancez une session tmux:
   ```bash
   tmux
   ```
5. Lancez la commande suivante:
   ```bash
    /opt/app/scripts/migrate.sh
   ```
   - À la question `Does all services are stopped ?` répondez `y`
   - À la question `Source MongoDB host:` répondez avec l'adresse URI actuel. **Attention**: utilisez la chaine de connexion **SRV**.
   - À la question `Source MongoDB backup username:` répondez avec le nom de l'utilisateur backup créé précédemment.
   - À la question `Source MongoDB backup password:` répondez avec le mot de passe de l'utilisateur backup créé précédemment.
   - À la question `Name of the database to migrate from:` répondez avec le nom de la base de données à migrer.
   - À la question `Name of the database to migrate to:` répondez avec le nom de la base de données de destination.
     > [!TIP]
     > Vous pouvez à tout moment vous détacher de la session tmux en appuyant sur `Ctrl+b` puis `d`. Pour vous y reconnecter, lancez la commande `tmux a`.
6. Une fois la migration terminée, notez le temps écoulé sur la dernière ligne de log `Elapsed Time` et quittez la session tmux:
   ```bash
   exit
   ```
7. Vérifiez que la migration s'est bien déroulée:
   ```bash
   /opt/app/scripts/mongo.sh
   ```

## Préparation de la migration

### Vérification de la connexion au nouveau cluster

1. Connectez-vous au serveur de votre application
2. Récupérer l'uri de connexion au nouveau cluster pour avec l'utilisateur de votre application au format: `mongodb+srv://<username>:<password>@mongodb-<environnement>.apprentissage.beta.gouv.fr/<database>?tls=true`
3. Vérifiez que vous pouvez vous connecter au nouveau cluster avec l'uri de connexion via la commande `docker run --rm -it mongo:7 mongosh "<uri>"`

> [!NOTICE]
> Pensez à mettre à jour également l'url de connexion pour Metabase

### Mise à jour des variables d'environnement

1. Mettez à jour l'URI de connexion au cluster dans les variables d'environnement de votre application
2. Préparez la pull-request pour le déploiement lors de la migration.

## Exécution de la migration

> [!CAUTION]
> La migration requiert une interruption de service équivalente à la durée de la migration. Pour obtenir une estimation de la durée de la migration, référez-vous au temps écoulé lors du test de la migration.

### Arrêt des services

1. Connectez-vous au serveur de votre application
2. Passer en mode super utilisateur:
   ```bash
   sudo -i
   ```
3. Récupérez le nom de vos services avec la commande:
   ```bash
   docker service ls
   ```
4. Stoppez le job processor de votre application:
   ```bash
   docker service scale <service_name>=0
   ```
5. Lancez le mode de maintenance avec la commande:
   ```bash
   /opt/app/tools/maintenance/maintenance-on.sh
   ```
6. Stoppez le serveur applicatif:
   ```bash
   docker service scale <service_name>=0
   ```

### Lancement de la migration

Exécutez les étapes de la section [Test de la migration](#test-de-la-migration)

### Feature Compatibility Version

Lancez la commande suivante pour mettre à jour la version de compatibilité des fonctionnalités:

```bash
/opt/app/scripts/mongo.sh --eval 'db.adminCommand( { setFeatureCompatibilityVersion: "7.0", confirm: true } )'
```

### Déploiement

Déployez les changements de variables d'environnement pour votre application.

> [!WARNING]
> Pensez à mettre à jour également l'url de connexion pour Metabase dans l'interface

### Suppression de l'ancien cluster

1. Supprimer l'ip de votre application de la whitelist de l'ancien cluster
2. Vérifiez que tout fonctionne correctement
3. Supprimez l'ancien cluster
