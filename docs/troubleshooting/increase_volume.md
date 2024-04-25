# Augmenter le volume d'un noeud

Lorsque le volume d'un noeud est plein, il est nécessaire d'augmenter la taille du volume pour continuer à stocker les données.

## Vérifier l'espace disque disponible

Pour consulter l'espace disque disponible sur un noeud, connectez-vous au serveur et exécutez la commande suivante:

```bash
df -h
```

## Stopper le service MongoDB

1. Connectez-vous au serveur
2. Passer en mode super utilisateur: 
```bash
sudo -i
```
3. Arrêtez le service MongoDB:
```bash
systemctl stop mongod
```

## Augmenter la taille du volume

1. Connectez-vous à l'interface OVH
2. Cliquez sur `Public Cloud` > `Block Storage`
3. Cliquez sur le volume à augmenter
4. Éditiez le volume et augmentez la taille

Une fois le volume augmenté, il est nécessaire de redimensionner le système de fichiers:

1. Connectez-vous au serveur
2. Passer en mode super utilisateur: 
```bash
sudo -i
```
3. Remonter le volume
```bash
umount /mnt/data
mount -a
```
4. Redimensionner le système de fichiers
```bash
xfs_growfs -d /mnt/data
```
5. Vérifier l'espace disque disponible avec la commande `df -h`
6. Redémarrez le service MongoDB:
```bash
systemctl start mongod
```
7. Vérifiez que le service est bien démarré:
```bash
/opt/app/scripts/mongo.sh
```
