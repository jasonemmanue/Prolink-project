# Contexte pour Claude — ProLink

## Vision

Plateforme sociale + marketplace multi-services mobile-first pour professionnels africains. Combine réseau social (fil, lives), vitrine pro (portfolio, avis) et marketplace (catalogue de services, paiement séquestré). Marché initial : Cameroun. Bilingue **FR/EN** avec **traduction automatique du chat à la Alibaba**.

## Trois dossiers, trois briques

- **`Application/`** — Flutter (Dart). Deux expériences dans une même app : Internaute (5 onglets) et Professionnel (5 onglets). Splash → Onboarding → Auth (choix du rôle) → shell adéquat.
- **`backoffice/`** — Next.js 14 App Router + Tailwind. 15 modules admin (dashboard, pros, litiges, finances, modération, tarifs, notifications, audit…).
- **`Api/`** — FastAPI (Python 3.12). REST + WebSockets (chat + notifications). Endpoints : auth, pros, feed, services, orders (escrow), chat, translate, lives, wallet, admin, notifications.

## Règles produit essentielles

- Commission plateforme : 10 % prestations, 15–20 % lives payants, 10 % pourboires.
- Paiement séquestre (escrow) obligatoire pour toute prestation en ligne.
- KYC pro 3 niveaux : bleu Vérifié · or Premium · violet Expert.
- Traduction chat : provider LibreTranslate/DeepL avec fallback local. Interface Alibaba-style : bulle traduite + « Voir l'original ».
- Charte : `#1A237E` primaire, `#00838F` secondaire, `#F57F17` accent, Inter + Playfair Display.

## Contraintes techniques

- Mobile Money via CinetPay (MVP) puis natif MTN/Orange (Phase 2).
- Push via Firebase Cloud Messaging.
- Diffusion live via LiveKit (RTMP/WebRTC).
- Hébergement recommandé : Google Cloud Platform (europe-west1) ou AWS Cape Town.
- Tests, sécurité (TLS 1.3, JWT, Argon2, 2FA au-delà de 100 000 XAF/mois).

## Points d'attention

- Tout tarif s'affiche en **XAF**. Utiliser `formatXaf` côté Flutter.
- Toujours vérifier que la traduction chat est optionnelle (interrupteur visible).
- Journal d'audit obligatoire pour toute action admin.

## Documents

- Cahier des charges v1.0 (57 pages) à la racine du dépôt.
