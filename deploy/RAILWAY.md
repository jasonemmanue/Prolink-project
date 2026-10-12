# Déploiement ProLink sur Railway (CLI)

Environnement de **test/staging**. Quatre services dans un même projet Railway :

| Service | Source | Build | Port | Rôle |
|---|---|---|---|---|
| `Postgres` | modèle Railway | — | 5432 (privé) | Base PostgreSQL |
| `Redis` | modèle Railway | — | 6379 (privé) | Cache + limitation de débit |
| `api` | `Api/` | `Api/Dockerfile` + `Api/railway.toml` | 8000 | FastAPI (REST + WebSockets) |
| `backoffice` | `backoffice/` | `backoffice/Dockerfile` + `backoffice/railway.toml` | 3000 | Next.js admin |

L'`api` lance au démarrage `alembic upgrade head` puis le seed de démo (`SEED_DEMO=true`).
Railway contrôle `/health` avant de basculer le trafic.

## 1. Pré-requis (une fois)

```bash
npm i -g @railway/cli
```

```bash
railway login
```

## 2. Créer et lier le projet

Depuis la racine du dépôt :

```bash
railway init --name prolink
```

(ou `railway link` si le projet a été créé depuis le tableau de bord.)

## 3. Premier déploiement

```powershell
.\deploy\railway.ps1 -Setup
```

Le script :
1. ajoute `Postgres` et `Redis` ;
2. crée les services vides `api` et `backoffice` ;
3. pose les variables (voir plus bas), dont un `JWT_SECRET` aléatoire passé par stdin ;
4. génère un domaine `*.up.railway.app` pour `api` et `backoffice` ;
5. envoie `Api/` et `backoffice/` (`railway up <dossier> --path-as-root`).

## 4. Redéploiements

```powershell
.\deploy\railway.ps1               # api + backoffice
.\deploy\railway.ps1 -Only api     # api seule
```

Pour passer plus tard en déploiement auto depuis GitHub (monorepo) : dans chaque
service, définir *Root Directory* = `Api` ou `backoffice`, puis
`railway service source connect --repo <owner>/<repo> --branch main --service api`.

## Variables

### `api`

| Variable | Valeur | Note |
|---|---|---|
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | réseau privé ; `postgresql://` converti en `postgresql+psycopg2://` par `config.py` |
| `REDIS_URL` | `${{Redis.REDIS_URL}}` | réseau privé |
| `JWT_SECRET` | aléatoire | généré par le script |
| `PORT` | `8000` | lu par `docker/entrypoint.sh` |
| `ENVIRONMENT` | `staging` | |
| `SEED_DEMO` | `true` | comptes de démo (voir `Api/README.md`) |
| `OTP_DEV_ECHO` | `true` | code OTP renvoyé dans la réponse : **`false` en prod** |
| `CORS_ORIGINS` | `["https://${{backoffice.RAILWAY_PUBLIC_DOMAIN}}","*"]` | retirer `"*"` en prod |
| `TRANSLATION_PROVIDER` / `TRANSLATION_BASE_URL` | `libretranslate` / `https://libretranslate.de` | |

À ajouter quand les clés existent (sinon mode sandbox) : `CINETPAY_API_KEY`,
`CINETPAY_SITE_ID`, `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`,
`FIREBASE_PROJECT_ID`.

```bash
railway variable set CINETPAY_API_KEY=xxx --service api
```

### `backoffice`

| Variable | Valeur |
|---|---|
| `PORT` | `3000` |
| `NEXT_PUBLIC_API_URL` | `https://${{api.RAILWAY_PUBLIC_DOMAIN}}` (figée au build, pour le branchement à venir) |

## Vérifier

```bash
railway domain list --service api
```

```bash
railway logs --service api
```

Puis ouvrir `https://<domaine-api>/health` (doit renvoyer `"database":"ok","cache":"ok"`)
et `https://<domaine-api>/docs`.

## Application mobile → API Railway

```bash
flutter build apk --dart-define=API_URL=https://<domaine-api>
```

(L'URL reste aussi modifiable dans l'app, cf. `Application/lib/api/api_client.dart`.)

## Base de données en local

```bash
railway connect Postgres
```

Ouvre un `psql` sur la base Railway (utile pour inspecter les données de test).
