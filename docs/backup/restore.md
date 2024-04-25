# Restauration des données

Ce guide décrit comment restaurer un cluster MongoDB à partir d'un backup créé automatiquement ou manuellement comme spécifié dans le guide [Backup](./backup.md).

Pour restaurer les données il vous suffit de suivre les étapes suivantes:
1. Lister les backups disponibles via la commande `/opt/app/scripts/list-backups.sh` (pensez à utiliser grep pour filtrer les résultats).
2. Choisir le backup à restaurer et noter le nom du fichier.
3. Restaurer le backup via la commande `/opt/app/scripts/restore-database.sh <backup_file>`.

> [!CAUTION]
> La restauration des données écrase et réinitialise les utilisateurs et roles de la base de données. Il est recommandé de suivre la procédure [Mettre à jour d'un noeud existant](../deploy/update.md) pour mettre à jour les utilisateurs et roles après la restauration des données.
