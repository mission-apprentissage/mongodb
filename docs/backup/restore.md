# Restauration des données

Ce guide décrit comment restaurer un cluster MongoDB à partir d'un backup créé automatiquement ou manuellement comme spécifié dans le guide [Backup](./backup.md).

Il existe deux méthodes pour restaurer les données:
 - Depuis l'instance effectuant les sauvegardes pour restaurer les données précédentes sur le cluster MongoDB.
 - Depuis votre poste de travail pour restaurer les données sur un autre cluster MongoDB (local ou distant).

## Restauration depuis l'instance effectuant les sauvegardes

> [!CAUTION]
> Via la méthode [Restauration depuis votre poste de travail](#restauration-depuis-votre-poste-de-travail) vous pouvez tester la restauration sur un cluster MongoDB de test avant de l'appliquer en production.

Pour restaurer les données il vous suffit de suivre les étapes suivantes:
1. Lister les backups disponibles via la commande `/opt/app/scripts/list-backups.sh` (pensez à utiliser grep pour filtrer les résultats).
2. Choisir le backup à restaurer et noter le nom du fichier.
3. Restaurer le backup via la commande `/opt/app/scripts/restore-database.sh <backup_file>`.

> [!CAUTION]
> La restauration des données écrase et réinitialise les utilisateurs et roles de la base de données. Il est recommandé de suivre la procédure [Mettre à jour d'un noeud existant](../deploy/update.md) pour mettre à jour les utilisateurs et roles après la restauration des données.

## Restauration depuis votre poste de travail

Si vous souhaitez restaurer les données sur un autre cluster MongoDB, assurez-vous que le cluster est accessible depuis votre poste de travail (VPN).

Pour restaurer les données il vous suffit de suivre les étapes suivantes:
1. Lister les buckets disponibles via la commande `.bin/mna backup:bucket:list`.
2. Liste les sauvegardes disponibles via la commande `.bin/mna backup:list <bucket_name>`.
3. Choisir le backup à restaurer et noter le nom du fichier.
4. Lancer la commande `.bin/mna backup:restore <backup_file> <mongoUri>` pour restaurer le backup sur le cluster MongoDB identifié par `mongoUri`.

> [!CAUTION]
> En cas d'import sur un cluster de test ou local, n'oubliez pas de supprimer les données une fois le test terminé.