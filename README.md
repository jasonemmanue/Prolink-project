# ProLink

Plateforme sociale + marketplace multi-services pour professionnels africains — Cameroun puis Afrique francophone.

Trois briques dans ce dépôt :

| Dossier | Rôle | Stack |
|---|---|---|
| [`Application/`](./Application) | App mobile Flutter (Internaute + Professionnel) | Flutter 3.38 / Dart 3.10 |
| [`backoffice/`](./backoffice) | Panneau d'administration web | Next.js 14 / TypeScript / Tailwind |
| [`Api/`](./Api) | Backend REST + WebSockets | FastAPI / PostgreSQL / Docker |

Documentation métier : `ProLink_Cahier_des_Charges_v1.0.pdf` (57 pages).

## Périmètre MVP

- Compte pro (KYC 3 niveaux) + compte internaute
- Fil d'actualité (posts, stories, lives)
- Messagerie riche **avec traduction automatique FR ⇄ EN (à la Alibaba)**
- Catalogue de services + paiement séquestre (escrow)
- Lives gratuits & payants (billetterie, replays)
- Portefeuille interne + Mobile Money (MTN, Orange via CinetPay)
- Notifications push granulaires
- Panneau admin 15 modules

## Démarrage rapide

```bash
# API + PostgreSQL (Docker) → http://localhost:8000/docs
cd Api && docker compose up -d --build
# Tests d'intégration
docker compose run --rm --entrypoint pytest api -q

# Backoffice
cd backoffice && npm install && npm run dev

# App mobile
cd Application && flutter pub get && flutter run
```

## Charte graphique

- Primaire `#1A237E` · Secondaire `#00838F` · Accent `#F57F17`
- Fonts : Inter (UI) + Playfair Display (titres)
- Icônes Feather / Material 3
- Modes clair et sombre obligatoires

## Contact

Jason Emmanuel — <sakamemmanuel@gmail.com>
