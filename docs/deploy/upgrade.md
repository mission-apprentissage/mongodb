# Mise à jour majeure de MongoDB (upgrade en place)

Cette procédure décrit la montée de version majeure d'un cluster existant **en place** (rolling
upgrade des binaires + passage de la Feature Compatibility Version), sans création d'un nouveau
cluster. Pour une migration vers une nouvelle architecture de cluster, voir plutôt
[Migration](./migration.md).

> [!CAUTION]
> Ne jamais passer la FCV avant d'avoir validé que **tous les membres** du replica set tournent
> sur la nouvelle version binaire et sont stables depuis quelques jours (burn-in). La FCV est une
> propriété du replica set (pas d'un nœud individuel) : une seule exécution suffit, sur n'importe
> quel membre.

## Pré-requis

1. Vérifier la version binaire actuelle et la FCV courante sur un membre du cluster :
   ```bash
   /opt/app/scripts/mongo.sh --eval 'db.version()'
   /opt/app/scripts/mongo.sh --eval 'db.adminCommand({getParameter: 1, featureCompatibilityVersion: 1})'
   ```
2. Vérifier la compatibilité des drivers applicatifs avec la version cible (voir la
   [compatibilité des drivers NodeJS](https://www.mongodb.com/docs/drivers/node/current/compatibility/#compatibility-table-legend)).
3. Ajouter `mongodb_version=<version cible>` (ex. `8.2`) dans `.infra/inventories/env.ini`, **uniquement**
   sous les groupes `[<environnement>_<n>:vars]` des nœuds à mettre à jour. Ne jamais poser cette
   variable en `[all:vars]` : `install_mongodb.yml` est partagé par tous les clusters, un cluster
   sans `mongodb_version` défini reste sur `8.0` par défaut.
4. Vérifier si la clé OpenPGP de signature a changé d'epoch (`https://www.mongodb.org/static/pgp/server-<epoch>.asc`,
   par ex. `curl -sIL` doit renvoyer `200`). MongoDB ne republie pas de nouvelle clé à chaque version
   mineure : la clé `8.0` signe l'ensemble de la série `8.x` (vérifié le 14/07/2026 : `server-8.1.asc`
   et `server-8.2.asc` renvoient `404`, seule `server-8.0.asc` existe). Si l'epoch n'a pas changé,
   **ne pas** définir `mongodb_pgp_key_epoch` (reste par défaut sur `8.0`) — seul `mongodb_version`
   doit changer. Si une montée de version future change réellement d'epoch de clé (ex. passage à une
   `9.0`), définir `mongodb_pgp_key_epoch=9.0` en plus de `mongodb_version=9.0`.

> [!NOTE]
> Le module `apt_repository` ajoute un nouveau fichier de dépôt pour chaque canal mais ne retire pas
> l'ancien. Ce n'est pas bloquant (le paquet `mongodb-org*` en `state: latest` installe la version la
> plus haute disponible parmi les dépôts présents), mais laisse un fichier `mongodb-org-8.0` obsolète
> sous `/etc/apt/sources.list.d/` après l'upgrade — à nettoyer manuellement si besoin.

## Rolling upgrade des binaires

Suivre la procédure standard [Mettre à jour un nœud existant](./update.md) :

```bash
.bin/mna app:deploy:cluster:node:update <environnement>_<n>
```

> [!CAUTION]
> Vérifier avec `rs.status()` **avant chaque run** quel nœud est réellement `PRIMARY` — ne pas
> supposer que c'est le nœud `1`. Mettre à jour les secondaires en premier, le primaire en dernier.
> Ne jamais mettre à jour plusieurs nœuds du même cluster en parallèle.

Après chaque nœud mis à jour, vérifier avant de passer au suivant :

```bash
/opt/app/scripts/mongo.sh --eval 'rs.status()'
```

Tous les membres doivent afficher `stateStr: "PRIMARY"` ou `"SECONDARY"` avec `health: 1`, et
`db.version()` doit refléter la nouvelle version sur le nœud qui vient d'être mis à jour.

## Burn-in

Laisser tourner le cluster complet sur la nouvelle version binaire quelques jours (comportement par
défaut, FCV encore à l'ancienne valeur) avant de passer à l'étape suivante — cela permet un
rollback simple en cas de problème inattendu.

## Passage de la Feature Compatibility Version

Une fois le burn-in validé, exécuter **une seule fois** (sur n'importe quel membre du cluster) :

```bash
/opt/app/scripts/mongo.sh --eval 'db.adminCommand({setFeatureCompatibilityVersion: "<version cible>", confirm: true})'
```

> [!WARNING]
> Cette action n'est pas trivialement réversible (voir la doc officielle MongoDB sur le
> [downgrade de FCV](https://www.mongodb.com/docs/manual/reference/command/setFeatureCompatibilityVersion/)).
> Ne l'exécuter qu'après confirmation que l'application fonctionne normalement sur la nouvelle
> version binaire.

## Vérifications post-upgrade

- `db.version()` ≥ version cible sur chaque nœud du cluster concerné.
- `rs.status()` : tous les membres `PRIMARY`/`SECONDARY` avec `health: 1`, pas de bascule de primaire imprévue.
- `db.adminCommand({getParameter: 1, featureCompatibilityVersion: 1})` reflète la version cible.
- Le backup quotidien (`configure-mongodb-backup.yml`, nœud avec `backup_enable=true`) continue de
  s'exécuter sans erreur (vérifier les logs CRON du script `backup-database.sh.jinja2`).
- Logs applicatifs des services connectés au cluster : absence d'erreurs driver
  (`MongoServerSelectionError`, incompatibilité de version).
