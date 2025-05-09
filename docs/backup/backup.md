# Backup

## Configuration du S3

### Création de l'utilisateur S3 dédié

Le backup est réalisé sur un bucket S3. Les credentials utilisé pour la création des backups doivent avoir la polique de permission suivante en remplaçant le `<bucket>` par le nom du bucket S3:

```json
{
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "s3:ListMultipartUploadParts",
        "s3:ListBucketMultipartUploads",
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::<bucket>",
        "arn:aws:s3:::<bucket>/*"
      ],
      "Sid": "MongoDBBackups"
    }
  ]
}
```

> Note: il est possible d'utiliser `*` dans le nom du bucket pour permettre l'accès à tous les buckets S3.

### Création du bucket S3

Créer le bucket S3 puis procéder à la configuration suivante:
- Activer le versioning et l'encryption du bucket S3 via l'interface OVH
- Activer le access server logging https://help.ovhcloud.com/csm/fr-public-cloud-storage-s3-server-access-logging?id=kb_article_view&sysparm_article=KB0056623
- Activer le lifecycle management pour supprimer les backups de plus de 90 jours:
  - Créer le fichier `lifecycle.json` avec le contenu suivant:
    ```json
    {
        "Rules": [{
            "ID": "DeleteOldBackups",
            "Filter": {},
            "Status": "Enabled",
            "Expiration": { "Days": 90 }
        }]
    }
    ```
  - `aws s3api put-bucket-lifecycle-configuration --bucket <bucket> --lifecycle-configuration file://lifecycle.json`

## Configuration du CRON de backup

Le backup est réalisé via un CRON qui lance un script de backup journalier et upload les backups sur un bucket S3.

Pour activer le backup, il est nécessaire de s'assurer que la variable `backup_enable` est à `true` pour un seul et unique noeud du cluster.

Une fois le paramètre définit, veuillez lancer la commande suivante pour activer le CRON:

```bash
.bin/mna deploy:update:node <environnement>-<n>
```

## Backup manuel

Pour lancer un backup manuellement:
- Se connecter au serveur
- Passer en mode super utilisateur:
```bash
sudo -i
```
- Lancer la commande suivante:
```bash
/opt/app/scripts/backup-database.sh
```

## Vérification des backups

1. Connectez-vous au serveur via `ssh mongodb-<environnement>-<n>.apprentissage.beta.gouv.fr`
2. Passer en mode super utilisateur `sudo -i`
3. Lancer la commande `/opt/app/scripts/list-backups.sh`
