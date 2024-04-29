# Backup

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
