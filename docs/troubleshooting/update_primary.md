# Changer le noeud primaire

La solution la plus simple est d'attribuer une priorité plus forte au noeud allant devenir primaire et laisser le cluster procéder au changement. Le langage JavaScript peut être utilisé pour manipuler la configuration du cluster.

## Mettre à jour la priorité

- En mode SUDO, depuis n’importe quel noeud, lancer :

```js
./script/mongo.sh
```

- Placer rs.conf() dans une variable :

```js
config = rs.conf();
```

- Afficher les valeurs contenues dans `config` :

```js
config;
```

- Modifier la valeur du membre souhaite en primaire à une valeur plus haute que les autres noeuds

```js
c.member[n].priority = x;
```

- Appliquer la nouvelle configuration :

```js
rs.reconfig(config);
```

- Vérifier le statut, cela peut prendre quelques minutes :

```js
rs.status();
```
