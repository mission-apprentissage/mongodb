# Mettre à jour d'un noeud existant

## Github Action

Lancer l'action `Mise à jour d'un Cluster` en spécifiant le nom du cluster à mettre à jour et la liste des numéros des noeuds à mettre à jour.

> [!INFORMATION]
> La liste par défaut est dans le sens décroissant, afin de mettre à jour le master en dernier. En cas d'erreur lors de la mise à jour, le master sera toujours disponible.

## Manuellement

> [!CAUTION]
> Ne pas mettre à jour des noeuds d'un meme cluster en même temps. Effectuer les mise à jour un sequentiellement pour éviter les perturbations.

Pour mettre à jour un noeud existant, il suffit de lancer la commande suivante :

```bash
.bin/mna deploy:update:node <environnement>-<n>
```
