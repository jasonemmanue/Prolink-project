# API — contexte

## Layout

```
app/
├── main.py                    # FastAPI + CORS + include des routers
├── core/
│   ├── config.py              # Settings via pydantic-settings (.env)
│   └── security.py            # JWT (jose) + bcrypt (passlib)
├── api/v1/routes/
│   ├── auth.py                # register/login/OTP
│   ├── pros.py                # profils pros + KYC
│   ├── feed.py                # posts, likes, signalements
│   ├── services.py            # catalogue
│   ├── orders.py              # commandes + escrow
│   ├── chat.py                # REST + WebSocket /chat/ws/{cid}
│   ├── translate.py           # LibreTranslate + fallback
│   ├── lives.py               # LiveKit tokens, billets, tips
│   ├── wallet.py              # solde, top-up, retrait Mobile Money
│   ├── notifications.py       # FCM
│   └── admin.py               # backoffice
├── services/                  # (à créer) logique métier
├── models/                    # (à créer) SQLAlchemy
└── schemas/                   # (à créer) Pydantic partagés
```

## Persistance

- PostgreSQL 16 principal, Redis pour cache + sessions.
- Alembic à ajouter (`alembic init alembic`) quand les modèles sont posés.
- Aucune donnée n'est écrite dans `_MOCK` en prod — retirer avant mise en ligne.

## Sécurité

- TLS 1.3 terminé au reverse proxy (Cloudflare / Nginx).
- JWT courts (60 min) + refresh 30 j.
- 2FA obligatoire au-delà de 100 000 XAF de revenus mensuels.
- Journal d'audit à câbler via un middleware admin.

## Intégrations externes (config `.env`)

| Fournisseur | Var | Usage |
|---|---|---|
| CinetPay | `CINETPAY_API_KEY`, `CINETPAY_SITE_ID` | Mobile Money agrégateur |
| LiveKit | `LIVEKIT_URL/KEY/SECRET` | Streaming vidéo live |
| Firebase | `FIREBASE_PROJECT_ID` | Notifications push |
| LibreTranslate/DeepL | `TRANSLATION_PROVIDER`, `TRANSLATION_BASE_URL` | Chat auto-translate |
