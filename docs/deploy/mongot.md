# Installation de MongoDB Search (mongot)

Cette procédure installe mongot en natif, colocalisé sur chaque nœud mongod d'un cluster
(recette ou lba uniquement — voir le handoff `mongot`). mongot ne remplace pas mongod, il tourne
en tant que service systemd séparé sur le même hôte et se synchronise via une connexion locale
(`127.0.0.1:27017`).

> [!CAUTION]
> Prérequis strict : mongod doit être en version >= 8.2 (voir [Upgrade](./upgrade.md)) — le rôle
> builtin `searchCoordinator` utilisé par `mongotUser` n'existe pas avant.

## Pré-requis avant déploiement

1. Vérifier l'espace disque disponible sur le volume `/mnt/data` de chaque nœud (`df -h`) : les
   données Lucene de mongot (`/mnt/data/mongot`) s'ajoutent aux données mongod déjà présentes.
   Non codifié dans ce repo (provisioning OVH manuel, voir [instance.md](./instance.md)) — à
   vérifier nœud par nœud.
2. Vérifier la RAM disponible (`free -h`) pour valider le `-Xmx 2g` par défaut (`mongot.service`,
   valeur reprise de la configuration preview validée pour le catalogue LBA ~370k docs/1 index).
   Ajuster `JAVA_TOOL_OPTIONS` dans `.infra/files/configs/mongot/mongot.service` si nécessaire.

## Ce que fait le déploiement

- Scope strict via `mongot_enable=true` (uniquement recette/lba) : `create_users.yml`,
  `mongod.conf.step-1/2.jinja2` et l'inclusion de `install_mongot.yml` dans `deploy.yml` sont tous
  gardés par cette variable — aucun effet sur les autres clusters (bal/api/tdb/sandbox).
- Création de `mongotUser` (rôle builtin `searchCoordinator`/`admin`) via le mécanisme SOPS/
  `create_user.yml` existant.
- `setParameter` côté mongod : `mongotHost`/`searchIndexManagementHostAndPort` pointent vers
  `127.0.0.1:27028` (port par défaut du canal gRPC mongot), `searchTLSMode: disabled` (ce canal
  gRPC mongod→mongot reste local, distinct du `net.tls.mode` qui régit les connexions clients),
  `useGrpcForSearch: true`.
- Téléchargement + extraction du binaire mongot dans `/opt/mongot`, données dans
  `/mnt/data/mongot` (hors `/mnt/data/db`, donc hors backup logique `mongodump` existant).
- Service systemd `mongot` dépendant de `mongod.service` (`Requires=`, `After=`).

## Ordre de rollout recommandé

1. Recette (`recette_1`, cluster à un seul nœud) — valider complètement le flux avant de toucher lba.
2. lba : démarrer par un secondaire, valider `$search` fonctionne en lisant depuis ce nœud, puis
   généraliser aux deux autres.

## Vérification

```bash
# Service actif
systemctl status mongot
journalctl -u mongot -f          # pas d'erreur d'auth/TLS au démarrage

# Health check local
curl http://127.0.0.1:8080/health

# Depuis mongosh (utilisateur root)
/opt/app/scripts/mongo.sh --eval 'db.adminCommand({getParameter: 1, mongotHost: 1})'
```

Test fonctionnel `$search` (à faire sur une collection LBA de test, en recette d'abord) :

```js
db.<collection>.createSearchIndex("test", { mappings: { dynamic: true } })
db.<collection>.aggregate([{ $search: { index: "test", text: { query: "<terme>", path: "<champ>" } } }])
```

Vérifier également que le backup quotidien (`mongodump --oplog`, cf. [backup.md](../backup/backup.md))
continue de s'exécuter normalement — les données Lucene de mongot vivent hors `/mnt/data/db` donc
hors du dump logique, mais à confirmer explicitement après le premier déploiement.

## Monitoring

Non couvert par cette PR : exposition des métriques Prometheus (`:9946`) et du health check
(`:8080`) au serveur de monitoring nécessite une règle firewall côté repo `infra`
(`products/mongodb/nftables.lba.conf.jinja2`/`nftables.recette.conf.jinja2`) et une nouvelle cible
côté repo `monitoring` (`prometheus.yml.jinja2`) — voir PR dédiée.
