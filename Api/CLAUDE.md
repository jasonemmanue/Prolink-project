# API — contexte

## Layout

```
app/
├── main.py                 # FastAPI, CORS, routers, tâche de fond (libération auto du séquestre)
├── db.py                   # engine, SessionLocal, Base, get_db
├── seed.py                 # données de démo (python -m app.seed), idempotent
├── core/
│   ├── config.py           # Settings (.env) + règles produit par défaut
│   ├── security.py         # Argon2, JWT access/refresh, OTP
│   └── deps.py             # current_user, optional_user, require_pro, require_admin, Page
├── models/                 # SQLAlchemy 2 (user, social, catalog, orders, wallet, chat, lives, platform)
├── schemas/__init__.py     # Pydantic in/out + constructeurs *_out(orm)
├── services/
│   ├── ledger.py           # grand livre + séquestre (SELECT … FOR UPDATE), seuil 2FA
│   ├── orders.py           # cycle de vie des commandes, libération auto, notes
│   ├── platform.py         # paramètres (commissions/packs), audit, modération
│   ├── notify.py           # notification en base + WebSocket + FCM
│   ├── realtime.py         # hub WebSocket en mémoire
│   ├── payments.py         # CinetPay (sandbox sans clés)
│   ├── livekit.py          # jetons LiveKit
│   ├── otp.py              # codes SMS hachés, usage unique
│   └── translation.py      # détection + traduction FR⇄EN
└── api/v1/routes/          # auth, pros, feed, services(+quotes), orders, wallet, chat, lives,
                            # notifications, campaigns, translate, admin
alembic/versions/           # migrations (autogenerate)
tests/                      # intégration sur PostgreSQL (prolink_test)
```

## Conventions

- Routes `def` (synchrones) + SQLAlchemy sync ; seul le WebSocket est `async`
  (les accès base y passent par `run_in_threadpool`).
- Tout mouvement d'argent passe par `services/ledger.py` : jamais de
  `wallet.balance_xaf += …` dans une route. Montants en XAF entiers.
- Toute action admin appelle `audit(...)` avant le commit.
- Les textes publiés par les utilisateurs passent par `moderate_text`.
- Nouvelle table / colonne : modifier `models/`, puis
  `docker compose exec api alembic revision --autogenerate -m "..."`.
- Tests : `docker compose run --rm --entrypoint pytest api -q` — à garder verts.

## Sécurité

- TLS 1.3 terminé au reverse proxy (Cloudflare / Nginx).
- JWT courts (60 min) + refresh 30 j ; Argon2.
- 2FA obligatoire au-delà de 100 000 XAF de transactions sur 30 jours.
- OTP : `OTP_DEV_ECHO=true` renvoie le code dans la réponse — à désactiver en prod.

## Intégrations externes (config `.env`)

| Fournisseur | Var | Usage |
|---|---|---|
| CinetPay | `CINETPAY_API_KEY`, `CINETPAY_SITE_ID` | Mobile Money (sandbox si vide) |
| LiveKit | `LIVEKIT_URL/KEY/SECRET` | Streaming vidéo live |
| Firebase | `FIREBASE_PROJECT_ID` | Notifications push |
| LibreTranslate/DeepL | `TRANSLATION_PROVIDER`, `TRANSLATION_BASE_URL` | Chat auto-translate |
