# ProLink — API (FastAPI + PostgreSQL)

REST + WebSocket. Python 3.12 · FastAPI · SQLAlchemy 2 · PostgreSQL 16 · Alembic.
~150 opérations, séquestre réel, commissions, 2FA, audit admin, tests d'intégration.

## Démarrer (Docker, recommandé)

```bash
cd Api
docker compose up -d --build
```

Au démarrage le conteneur `api` : applique les migrations Alembic → charge les
données de démo (si la base est vide) → lance Uvicorn.

- API : http://localhost:8000 — docs interactives : http://localhost:8000/docs
- Santé : http://localhost:8000/health (`database`, mode de paiement)
- PostgreSQL : `localhost:5432`, base `prolink`, utilisateur/mot de passe `prolink`
- Redis : `localhost:6379` (cache + limitation de débit)

### Cache Redis

`app/services/cache.py` — lecture des données publiques mises en cache,
invalidées à chaque écriture (clés versionnées par espace : `pros`, `services`,
`feed`, `lives`, `categories`, `settings`, `admin`) :

| Endpoint | TTL |
|---|---|
| `GET /categories`, `GET /plans` | 1 h |
| `GET /pros`, `GET /pros/{id}`, `GET /services`, services d'un pro | 60 s |
| `GET /feed` (par utilisateur) | 30 s |
| `GET /lives` | 15 s |
| `GET /admin/dashboard` | 30 s |

Les informations propres à l'utilisateur (suivi, cloche, like, favori, accès
à un live) sont recalculées à chaque requête et superposées au cache.
Redis sert aussi à limiter l'envoi de codes SMS (5 / 10 min par numéro →
HTTP 429). Si Redis est arrêté, l'API continue sans cache (`/health` → `"cache": "off"`).

### Comptes de démo

| Rôle | Identifiant | Mot de passe |
|---|---|---|
| Admin | `admin@prolink.cm` | `Admin1234!` |
| Internaute | `client@prolink.cm` (2FA active : le code est renvoyé dans `dev_code`) | `Demo1234!` |
| Pro | `aicha@prolink.cm`, `landry@prolink.cm`, `franck@prolink.cm`, `muna@prolink.cm`, `paul@prolink.cm`, `nadege@prolink.cm`, `sandrine@prolink.cm`, `herve@prolink.cm`, `ibrahim@prolink.cm`, `grace@prolink.cm` | `Demo1234!` |

Mêmes pros, services, posts et lives que l'app Flutter ; commandes à tous les
statuts, créées via le vrai grand livre (soldes cohérents).

### Tests

```bash
docker compose run --rm --entrypoint pytest api -q
```

28 scénarios de bout en bout sur la base `prolink_test` (créée automatiquement) :
cycle escrow complet et montants exacts, remboursements, libération auto 72 h,
litige tranché par l'admin (remboursement partiel), devis, retrait avec OTP et
solde minimum, seuil 2FA, lives payants (billet → jeton → pourboire → bilan),
groupe payant, chat + WebSocket, modération (mots-clés, signalements), KYC,
commissions configurables, sponsorisation, audit, idempotence du seed.

### Commandes utiles

```bash
docker compose logs -f api                      # logs
docker compose down                             # arrêt (données conservées)
docker compose down -v                          # arrêt + suppression de la base
docker compose exec api alembic revision --autogenerate -m "..."   # nouvelle migration
```

Sans Docker : `pip install -r requirements.txt`, PostgreSQL local, puis
`alembic upgrade head && python -m app.seed && uvicorn app.main:app --reload`.

## Routes (préfixe `/api/v1`)

| Domaine | Endpoints principaux |
|---|---|
| **auth** | `POST /auth/register`, `/auth/login` (+2FA), `/auth/refresh`, `/auth/otp/send`, `/auth/otp/verify`, `/auth/otp/login`, `GET/PATCH /auth/me`, `/auth/password`, `/auth/2fa/enable`, `/auth/2fa/disable` |
| **pros** | `GET /categories`, `GET /pros` (q, catégorie, ville, note min, vérifiés, langue, tri), `GET /pros/{id}` (+ `/services`, `/posts`, `/portfolio`, `/reviews`, `/lives`), `POST/DELETE /pros/{id}/follow?notify=` (cloche), `GET /me/following`, `POST/PATCH /pros/me`, `GET/POST /pros/me/kyc`, `GET /pros/me/dashboard`, `GET /pros/me/stats` |
| **feed** | `GET /feed`, `POST /posts`, `GET/PATCH/DELETE /posts/{id}`, like/unlike, save/unsave, `GET /me/saved`, commentaires (+ modération par l'auteur), `POST /reports` |
| **catalogue** | `GET /services` (recherche), CRUD `/services`, `POST /services/reorder` |
| **devis** | `POST /quotes`, `GET /quotes`, `POST /quotes/{id}/reply` (pro), `/accept` (→ commande), `/decline` |
| **commandes** | `POST /orders`, `GET /orders?role=&status=`, `/confirm`, `/decline`, `/cancel`, `/deliver`, `/validate`, `/dispute` (+ messages), `/review`, `POST /reviews/{id}/reply` |
| **portefeuille** | `GET /wallet`, `/wallet/transactions`, `/wallet/statement.csv`, `POST /wallet/topup`, `/wallet/withdraw` (OTP), webhook `/wallet/cinetpay/notify` |
| **chat** | `GET/POST /chat/conversations`, messages (pagination `before`), `/read`, archiver/épingler, groupes (`/chat/groups`, join payant, demande/approbation, leave), WebSocket `/chat/ws?token=` |
| **lives** | CRUD `/lives`, `/start`, `/end` (bilan + replay), `/token` (LiveKit, accès vérifié), `/ticket`, `/replay`, `/tip`, `/leave`, `GET /lives/tickets/mine` |
| **notifications** | liste, `/unread-count`, `/read`, `/read-all`, `POST/DELETE /notifications/devices` (FCM) |
| **sponsoring & packs** | `POST /campaigns/estimate`, CRUD campagnes (pause/resume/stop avec remboursement), `GET /plans`, `POST /plans/subscribe` |
| **traduction** | `POST /translate` (LibreTranslate/DeepL + repli local) |
| **admin** | dashboard, analytics, utilisateurs (suspendre/réactiver), KYC, niveau de vérification, signalements, mots-clés bannis, catégories (CRUD + fusion), paramètres (commissions, packs…), litiges, commandes (libération/remboursement manuels), lives (coupure d'urgence), campagnes, notifications ciblées, finances + export CSV, journal d'audit |

## Règles métier implémentées

- **Séquestre** : à la commande, l'acheteur est débité et les fonds bloqués
  (`escrow_xaf` acheteur ; net « à recevoir » côté pro). Validation client →
  le pro reçoit le brut puis la commission est prélevée. Annulation / refus →
  remboursement intégral. Sans réponse 72 h après livraison → libération
  automatique (tâche de fond toutes les 10 min).
- **Commissions** (configurables par l'admin, table `platform_settings`) :
  10 % prestations et groupes payants, 15 % billets/replays de lives, 10 % pourboires.
- **2FA** obligatoire au-delà de 100 000 XAF de transactions sur 30 jours
  (commande, rechargement, billet, pourboire, retrait).
- **Retrait** réservé aux pros, code SMS obligatoire, solde minimum 500 XAF.
- **KYC 3 niveaux** : identité + selfie → bleu ; + registre/justificatif → or ; + diplômes → violet.
- **Packs** : gratuit (5 prestations actives max, pas de live payant), Premium, Business.
- **Modération** : mots-clés bannis masqués dans posts, commentaires, messages, avis.
- **Audit** : chaque action admin écrit dans `audit_logs` (acteur, cible, payload, IP).
- Mots de passe **Argon2**, JWT d'accès 60 min + refresh 30 j.

## Intégrations externes (`.env`)

| Fournisseur | Variables | Sans configuration |
|---|---|---|
| CinetPay (Mobile Money) | `CINETPAY_API_KEY`, `CINETPAY_SITE_ID` | **sandbox** : paiements confirmés immédiatement |
| LiveKit | `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET` | jeton de dev (`configured: false`) |
| Firebase (push) | `FIREBASE_PROJECT_ID` | push journalisé, notification en base + WebSocket |
| SMS OTP | — (à brancher dans `services/otp.py`) | code renvoyé dans `dev_code` (`OTP_DEV_ECHO=true`) |
| Traduction | `TRANSLATION_PROVIDER`, `TRANSLATION_BASE_URL` | dictionnaire local |

⚠️ Avant la production : `JWT_SECRET` fort, `OTP_DEV_ECHO=false`, `SEED_DEMO=false`,
`CORS_ORIGINS` restreint, vraies clés CinetPay/LiveKit/Firebase.
