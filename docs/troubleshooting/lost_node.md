# Perte d'un noeud

En cas de perte d'un noeud, votre cluster peut se trouver dans 2 situations:
- Le cluster dispose toujours de la majorité des membres et est donc toujours fonctionnel.
- Le cluster ne dispose plus de la majorité des membres et est donc limité en lecture seule.

## Majorité des membres toujours présente

Dans le cas où le cluster dispose toujours de la majorité des membres, il est possible de simplement ajouter un nouveau noeud pour remplacer le noeud perdu.

Tout d'abord, veuillez supprimer le noeud perdu du réplicat set:
1. Connectez vous à un noeud du cluster.
2. Lancez la commande `/opt/app/scripts/mongo.sh` pour vous connecter à l'instance MongoDB.
3. Lancez la commande `rs.status()` pour obtenir la liste des membres du cluster.
4. Identifier le noeud perdu et lancer la commande `rs.remove("<hostname>")` pour le retirer du réplicat set où `<hostname>` est le nom du noeud perdu.
5. Quittez l'instance MongoDB en tapant `exit`.

Il vous suffit ensuite de suivre la procédure [Ajouter un membre à un cluster existant](../deploy/add_member.md).

## Minorité des membres présente

Dans le cas où le cluster ne dispose plus de la majorité des membres, il est nécessaire de forcer la reconfiguration.

Vous pouvez également vous référer à la documentation officielle de MongoDB pour plus d'informations [Reconfigure a Replica Set with Unavailable Members](https://www.mongodb.com/docs/manual/tutorial/reconfigure-replica-set-with-unavailable-members/)

1. Connectez vous à un noeud du cluster.
2. Lancez la commande `/opt/app/scripts/mongo.sh` pour vous connecter à l'instance MongoDB.
3. Lancez la commande `rs.status()` pour obtenir la liste des membres du cluster.
4. Récupérez la configuration actuelle du cluster avec la commande `cfg = rs.conf()`.
5. Mettez à jour la configuration pour retirer le noeud perdu avec la commande `cfg.members = cfg.members.filter(member => member.host !== "<hostname>")` où `<hostname>` est le nom du noeud perdu.
6. Forcez la reconfiguration du cluster avec la commande `rs.reconfig(cfg, {force: true})`.

Vous pouvez maintenant ajouter un nouveau noeud en suivant la procédure [Ajouter un membre à un cluster existant](../deploy/add_member.md).
