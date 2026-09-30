# ProLink — App mobile (Flutter)

App bilingue Internaute + Professionnel dans un seul binaire.

## Structure

```
lib/
├── main.dart                # Splash + Provider
├── theme.dart               # Palette #1A237E / #00838F / #F57F17
├── l10n.dart                # AppLocale + OfflineTranslator (Alibaba-style)
├── models.dart              # Pro, Post, Service, LiveEvent, Chat, Order, AppNotification
├── data.dart                # Mock data (pros, posts, services, lives, commandes, notifications)
├── widgets/common.dart      # AppLogo, Avatar, Pill, VerifiedBadge, pushScreen, showReportSheet…
└── screens/
    ├── onboarding.dart
    ├── auth.dart            # Choix du rôle (Client / Pro)
    ├── home_shell.dart      # BottomNav Internaute
    ├── pro_shell.dart       # BottomNav Professionnel
    ├── live_view.dart       # Visionnage live + chat + pourboire + signalement
    ├── shared/              # Notifications, Recharge / Retrait Mobile Money
    ├── client/              # Feed, Discover (+filtres), Chat (traduction), Groupes, Wallet, Profile,
    │                        # Détail service, Order flow, Suivi commande, Litige, Avis, Devis,
    │                        # Billets & replays, Réglages (notifications, sécurité, aide)
    └── pro/                 # Dashboard, Publish, Catalog + éditeur, Orders + détail / devis,
                             # Live (préparation → vérifs → direct → bilan), Stats, Finances,
                             # KYC, Sponsorisation, Packs, Avis
```

## Traduction automatique du chat

Fichier clé : `lib/screens/client/chat.dart`. Bandeau « Traduction automatique » activable, sélecteur FR/EN, chaque bulle traduite affiche un pied avec « Voir l'original / Voir traduction ». MVP : dictionnaire embarqué (`l10n.dart::OfflineTranslator`). En production : appel à `POST /api/v1/translate` de l'API (LibreTranslate self-hosted ou DeepL).

## Lancer

```bash
flutter pub get
flutter run                        # émulateur / téléphone branché
flutter build apk --release        # APK release
flutter install                    # installer sur le téléphone connecté
```

## Connexion à l'API

L'app parle à l'API FastAPI (`Api/`, `docker compose up -d`). Couche réseau :

```
lib/api/
├── api_client.dart   # HTTP + JWT (refresh auto sur 401), URL du serveur mémorisée
├── session.dart      # Session (Provider) : login/inscription/2FA, chargement des données
└── mappers.dart      # JSON de l'API → modèles de l'app
```

- **URL du serveur** : fixée au build (`--dart-define=API_URL=...`), modifiable
  dans l'app (écran de connexion → **Serveur**), puis mémorisée.
  - Émulateur Android : `http://10.0.2.2:8000` (valeur par défaut)
  - Téléphone : `http://<IP du PC sur le Wi-Fi>:8000` — autoriser le port 8000
    dans le pare-feu Windows (réseau privé).
- **Session** : le jeton est mémorisé ; au relancement l'app ouvre directement
  le bon espace (internaute ou pro).
- **Mode démo** : bouton sur l'écran de connexion (ou proposé si le serveur est
  injoignable) — données embarquées de `data.dart`, rien n'est enregistré.
- Comptes de démo : `client@prolink.cm` (2FA : le code est pré-rempli en dev),
  `aicha@prolink.cm` (pro) — mot de passe `Demo1234!`.

Build pour un téléphone sur le même Wi-Fi que le PC :

```bash
flutter build apk --release --dart-define=API_URL=http://192.168.1.33:8000
```

Branché sur l'API : inscription/connexion (+2FA), fil (likes, favoris,
commentaires, signalements), suivi + cloche, recherche, commandes avec
séquestre (paiement portefeuille ou Mobile Money sandbox), suivi/validation/
annulation/litige/avis, devis (demande et réponse), portefeuille (solde,
historique, recharge, retrait avec code SMS), messagerie (conversations,
envoi, rafraîchissement 4 s, traduction serveur), groupes (adhésion, paiement,
messages), lives (billet, accès vérifié, pourboires, démarrage/fin/replay côté
pro), notifications, espace pro (tableau de bord, commandes, catalogue CRUD +
ordre, publication, finances, KYC, sponsorisation, packs, avis).

Pas encore branché : envoi de fichiers (photos/PDF → stockage objet à ajouter),
vidéo LiveKit (le jeton est déjà délivré par l'API), push FCM, paiements
CinetPay réels (sandbox sans clés).

## Compilation testée

- Android 8+ (arm64/armeabi/x86_64)
- iOS 13+ (via Codemagic)

## Documentation

- **[SCREENS.md](./SCREENS.md)** — parcours détaillé des 48 écrans (21 d'origine + 27 ajoutés
  en v1.1), matrice de couverture du cahier des charges,
  navigation, données démo utilisées et procédure de build APK.
- **[CLAUDE.md](./CLAUDE.md)** — conventions internes (theme, l10n,
  formatXaf, gestion d'état).

## Icône de lancement

L'icône Android est générée à partir de `assets/images/logo.png` via
`flutter_launcher_icons`. Pour la régénérer après modification du logo :

```bash
flutter pub get
dart run flutter_launcher_icons
```

Adaptive icon : logo sur fond `#1A237E` (primaire ProLink).
