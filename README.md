# MongoDB Cluster - Missing Apprentissage

Ce depot contient la configuration des différents cluster MongoDB de la Mission Apprentissage. 

## Architecture

Les clusters MongoDB sont composés d'un ou plus noeuds (serveur). Ils sont basés sur la configuration commune via [le dépot infra](https://github.com/mission-apprentissage/infra).

### Configuration des serveurs

MongoDB est installé sur les serveurs via les packages officiels de MongoDB en natif.

La configuration de MongoDB comprend:
- La création des utilisateurs via le vault
- La création du keyfile pour l'authentification des membres du cluster
- La configuration du fichier de configuration de MongoDB avec:
  - L'utilisation du keyfile pour l'authentification interne
  - L'activation de l'authentification
  - L'activation du mode replSet
  - L'activation du mode TLS pour le chiffrement des connexions
  - La sauvegarde des données sur un volume externe (/mnt/data)
- Le montage du volume externe pour la sauvegarde des données
- La création d'un CRON pour la rotation des certificats TLS

Pour plus de détails sur la configuration lié à MongoDB se référer à la [documentation de l'infrastructure](./docs/infrastructure.md).

En plus de MongoDB les serveurs ont un Docker Swarm pour le lancement des services système définis dans le dépot [infra](https://github.com/mission-apprentissage/infra):
- un conteneur cadvisor pour la supervision des conteneurs
- un conteneur node-exporter pour la supervision du système
- un conteneur fluentd pour la collecte des logs
- un conteneur reverse proxy pour l'accès aux métriques par le serveur de monitoring (cadvisor, node-exporter, fluentd-prometheus-exporter).

### Liste des clusters
  
| Nom du cluster | URL de connexion | Noeud #1 | Noeud #2 | Noeud #3 |
| -------------- | ---------------- | -------- | -------- | -------- |
| `mongodb-recette` | `mongodb+srv://<credentials>@mongodb-recette.apprentissage.beta.gouv.fr` | `mongodb-recette-1.apprentissage.beta.gouv.fr` | `n/a` | `n/a` |

### Déploiement

Le déploiement des clusters est fait via Ansible, mais certaines actions ne sont pas automatisées:
- L'ajout du volume externe
- Le formatage initial du volume externe

Pour déployer un cluster MongoDB, il est nécessaire de déployer chaque noeud individuellement. En fonction de la finalité recherchée il exiiste plusieurs cas de figure, avec chacun une procédure et documentation dédiée:

- [Créer un nouveau cluster](./docs/deploy/initial.md): Créer un nouveau cluster MongoDB.
- [Ajouter un membre à un cluster existant](./docs/deploy/add_member.md): Ajouter un membre à un cluster existant.
- [Mettre à jour d'un noeud existant](./docs/deploy/update.md): Mettre à jour un cluster existant (par exemple pour changer mettre à jour les utilisateurs).

### Migration

Pour migrer un cluster MongoDB existant vers la nouvelle architecture veuillez suivre la procédure [Migration](./docs/deploy/migration.md).

### Backup et restauration

Consulter les documentations dédiées à la [sauvegarde](./docs/backup/backup.md) et à la [restauration](./docs/backup/restore.md) des données.

### Suppression d'un noeud

Pour supprimer un noeud veuillez:
- Supprimer l'adresse du noeud dans l'enregistrement DNS `SRV` sur alwaysdata.
- Supprimer le noeud du cluster MongoDB via la commande `.bin/mna deploy:remove:node <environnement>-<n>`
- Décommissionner le serveur et le volume externe associé.
- Supprimer la référence du serveur dans le fichier ini de ce dépôt ainsi que celui du dépôt infra.
- Supprimer le noeud de [Percona](https://percona.apprentissage.beta.gouv.fr)

### Dépannage

Voici une liste des problèmes courants et des solutions associées:
- [Augmenter le volume d'un noeud](./docs/troubleshooting/increase_volume.md): Augmenter la taille du volume d'un noeud.
- [Perte d'un noeud](./docs/troubleshooting/lost_node.md): Procédure en cas de perte d'un noeud.

Vous pouvez également consulter ces pages de la documentation officielle de MongoDB:

- [Adjust Priority for Replica Set Member](https://www.mongodb.com/docs/manual/tutorial/adjust-replica-set-member-priority/)
- [Perform Maintenance on Replica Set Members](https://www.mongodb.com/docs/manual/tutorial/perform-maintence-on-replica-set-members/)
- [Force a Member to Become Primary](https://www.mongodb.com/docs/manual/tutorial/force-member-to-be-primary/)
- [Resync a Member of a Replica Set](https://www.mongodb.com/docs/manual/tutorial/resync-replica-set-member/)

### Développement

Voir la documentation dédiée au [développement](./docs/developpement/developpement.md)
