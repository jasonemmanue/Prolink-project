# ProLink — API (FastAPI)

REST + WebSockets. Python 3.12 · PostgreSQL 16 · Redis 7.

## Routes

| Préfixe | Objet |
|---|---|
| `/api/v1/auth` | Register, login JWT, OTP SMS |
| `/api/v1/pros` | Liste pros, KYC, follow |
| `/api/v1/feed` | Fil d'actualité, posts, signalement |
| `/api/v1/services` | Catalogue de services |
| `/api/v1/orders` | Commandes + séquestre (initiated → validated → released) |
| `/api/v1/chat` | Conversations REST + `/ws/{cid}` WebSocket |
| `/api/v1/translate` | Traduction FR ⇄ EN (LibreTranslate + fallback local) |
| `/api/v1/lives` | Lives, billets, LiveKit tokens, pourboires |
| `/api/v1/wallet` | Solde, top-up, retrait Mobile Money |
| `/api/v1/notifications` | Enregistrement token FCM, push |
| `/api/v1/admin` | Dashboard, KYC, séquestre manuel, catégories, mots-clés |

## Démarrer en local

```bash
python -m venv .venv && .venv/Scripts/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload --port 8000
# http://localhost:8000/docs
```

Docker :
```bash
docker compose up -d
```

## Traduction (feature clé)

`POST /api/v1/translate` — payload `{ text, source?, target }`. Le service tente LibreTranslate (`TRANSLATION_BASE_URL`) puis retombe sur un dictionnaire local. Utilisé par l'app mobile pour le chat inter-langues.
