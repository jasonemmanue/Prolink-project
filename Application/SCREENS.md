# ProLink — Parcours des écrans Android

Ce document décrit **chaque écran** de l'app ProLink (Flutter) et la navigation
d'écran à écran. Toutes les données sont issues de `lib/data.dart` (`MockData`)
pour ce MVP — aucun appel réseau bloquant, aucun écran noir.

Le logo officiel est présent à la fois à la racine du dépôt (`LogoProlink.png`)
et embarqué dans l'app (`assets/images/logo.png`). Il sert également à
générer l'icône du lanceur Android (`ic_launcher` + adaptive icon, fond
`#1A237E`) via `flutter_launcher_icons`.

## Diagramme de navigation

```
Splash (main.dart)
  └─▶ Onboarding (4 pages)
        └─▶ Auth (choix du rôle Internaute / Pro)
              ├─▶ HomeShell        (rôle « Je cherche »)
              │     ├─ Feed ──────────▶ Notifications ─▶ Réglages notifications
              │     │   ├─ 🔍 ────────▶ Recherche (Discover plein écran)
              │     │   ├─ post ──────▶ PostDetail (commentaires, signalement)
              │     │   └─ live ──────▶ LiveView (suivre, pourboire, signaler)
              │     ├─ Discover  (filtres + onglets Pros/Publications/Lives/Événements/Groupes)
              │     │   └─ live payant ▶ Achat de billet (sheet)
              │     ├─ Messaging (Tous / Non lus / Groupes / Archivés)
              │     │   ├─ Chat (traduction FR⇄EN, pièces jointes)
              │     │   ├─ GroupScreen · CreateGroup
              │     │   └─ Nouveau message (sheet)
              │     ├─ Wallet ───────▶ TopUp (recharge Mobile Money / carte)
              │     └─ Profile
              │         ├─ EditProfile · MyOrders ─▶ OrderTracking ─▶ Dispute / Review
              │         ├─ MyTickets (billets + replays) · Kyc (devenir pro)
              │         └─ NotificationSettings · Security (2FA, sessions) · HelpCenter
              │
              │   ProProfile ─▶ ServiceDetail ─▶ OrderFlow (escrow)
              │                              └─▶ QuoteRequest (devis)
              │
              └─▶ ProShell         (rôle « Je propose »)
                    ├─ Dashboard   (+ FAB « Publier »)
                    │   ├─ Notifications · Stats · Publish ─▶ Sponsor
                    │   ├─ Raccourcis : ServiceEditor · Live · Messages · Avis · Sponsor · Groupe
                    │   └─ Alertes : QuoteReply · Litige (OrderDetail) · Kyc · Plans
                    ├─ Orders ─────▶ ProOrderDetail (confirmer / livrer / signaler)
                    │           └─▶ QuoteReply (devis à chiffrer)
                    ├─ Catalog ────▶ ServiceEditor (nouveau / modifier, statut)
                    ├─ LiveBroadcast ─▶ LivePrecheck ─▶ LiveOnAir ─▶ LiveSummary (replay)
                    └─ Finances ───▶ Withdraw (retrait Mobile Money + OTP)
```

Écrans annexes accessibles depuis les onglets :

- `pro_profile.dart` (fiche pro publique, via Feed / Discover)
- `service_detail.dart` (détail d'un service, via `pro_profile`)
- `order_flow.dart` (5 étapes de commande escrow, via `service_detail`)
- `live_view.dart` (visionnage live, chat live, pourboires)
- `pro/publish.dart` (publication d'un post, via FAB du Dashboard)
- `pro/stats.dart` (statistiques audience/CA, via Dashboard)

## Détail écran par écran

### 0. Splash — `lib/main.dart`
Gradient primaire → secondaire, logo dans un cercle blanc semi‑transparent,
titre « ProLink », sous‑titre bilingue, `CircularProgressIndicator` blanc.
Navigue vers Onboarding après **1 400 ms** (`pushReplacement`).

### 1. Onboarding — `screens/onboarding.dart`
`PageView` 4 pages (chercher, payer sécurisé, lives, chat traduit). Indicateur
de progression animé. Boutons « Passer » et « Suivant / Commencer ». Sortie
vers `AuthScreen`.

### 2. Auth — `screens/auth.dart`
Formulaire combiné inscription / connexion. Choix du rôle (`_RoleCard`
« Je cherche » vs « Je propose »). Champs `Nom complet`, `Email / téléphone`,
`Mot de passe`. Boutons sociaux Google + Facebook (visuels). Le bouton
principal fait `pushReplacement` vers `HomeShell` ou `ProShell` selon `_role`.

### Shell Internaute — `screens/home_shell.dart`
`NavigationBar` Material 3 avec 5 destinations. Onglet Messages porte un
`Badge(3)`.

### 3. Feed — `screens/client/feed.dart`
- `SliverAppBar` (logo + notifications + recherche)
- Ligne « Stories » horizontale : anneau dégradé accent→primaire, avatar
  cliquable (mène vers `pro_profile`).
- Bandeau « Lives en direct » (cartes 220 px avec pastille rouge LIVE,
  vues, titre, pro). Clic → `LiveViewScreen`.
- Fil de posts : avatar → `pro_profile`, badge Vérifié/Premium/Expert,
  tag « Sponsorisé » sur `po1`, images 16:10 (1 ou 2 côte à côte),
  ligne d'actions (❤ commentaires partage 🔖).

### 4. Discover — `screens/client/discover.dart`
Barre de recherche, `TabBar` (Tendances / Nouveaux / Notés), grille des
catégories (12 items `MockData.categories`), liste de pros filtrable par
ville/langue, ouverture d'une fiche pro au tap.

### 5. Messaging — `screens/client/messaging.dart`
`TabBar` scrollable (Tous / Non lus / Groupes / Archivés). Liste de
conversations (`MockData.conversations()`) avec avatar + pastille « en ligne »,
compteur de messages non lus, dernier message + horodatage humain.
Ouvre `ChatScreen` au tap.

### 6. Chat — `screens/client/chat.dart` ⭐ traduction
- AppBar : avatar + « en ligne », caméra, appel, menu réglages.
- Bandeau `_TranslateBanner` (interrupteur + sélecteur FR/EN).
- Bulles : traduction automatique via `OfflineTranslator` (`l10n.dart`)
  quand la langue détectée diffère de la langue préférée. Pied de bulle :
  icône traduction + « Voir l'original / Voir traduction ».
- Composer : pièce jointe, micro, envoi. Réponse simulée après 1 s.

### 7. Wallet — `screens/client/wallet.dart`
Carte de solde en gradient, boutons Recharger / Retirer, historique de
transactions avec icônes catégorielles, méthodes de paiement (MTN, Orange,
CinetPay, carte).

### 8. Profile — `screens/client/profile.dart`
Cover + avatar, nom, biographie courte, actions (Modifier, Partager),
grille de statistiques (posts, suivis, suiveurs), sections Mes commandes,
Mes avis, Paramètres, Déconnexion.

### 9. Pro profile (public) — `screens/client/pro_profile.dart`
Cover 200 px, avatar 96 px, nom + badge vérifié, ville + langues, boutons
Suivre / Message, `TabBar` : À propos • Services • Avis • Portfolio.
Tap sur un service → `ServiceDetailScreen`.

### 10. Service detail — `screens/client/service_detail.dart`
Header illustré, prix XAF, modalité, annulation, description, avis, bouton
CTA « Commander maintenant » → `OrderFlowScreen`.

### 11. Order flow — `screens/client/order_flow.dart`
Stepper 5 étapes : Récap → Créneau → Détails → Paiement (MTN / Orange / carte)
→ Confirmation (illustration succès + numéro d'ordre, escrow).

### 12. Live view — `screens/live_view.dart`
Player fictif plein écran, bandeau LIVE + compteur de vues, chat overlay,
bouton pourboire (bottom sheet), bouton Suivre.

### Shell Pro — `screens/pro_shell.dart`
`NavigationBar` avec 5 destinations + FAB « Publier » visible uniquement sur
le Dashboard.

### 13. Pro Dashboard — `screens/pro/dashboard.dart`
En‑tête avec avatar pro + salutation, cartes KPI (revenus, commandes, avis,
followers), graphique CA 7j, dernières demandes, raccourcis (Statistiques,
Portfolio, Live).

### 14. Pro Publish — `screens/pro/publish.dart`
Composer riche (texte, images, radio « Type de contenu » Post / Story / Live
annoncé), sélecteur de tags/catégories, prévisualisation.

### 15. Pro Catalog — `screens/pro/catalog.dart`
`ReorderableListView` des services (drag), affichage prix (`fixed`, `from`,
`quote`), pastille « Actif », menu contextuel (Modifier / Pause / Supprimer).

### 16. Pro Orders — `screens/pro/orders.dart`
`TabBar` En attente / En cours / Livrées / Litiges, liste `ListTile` avec
client, deadline, montant. Icône colorée par statut.

### 17. Pro Live broadcast — `screens/pro/live_broadcast.dart`
Aperçu vidéo (image de couverture noire), champs Titre / Description /
Date / Heure, `RadioListTile` mode (Gratuit ouvert / Gratuit abonnés /
Payant / Pourboires), champ prix conditionnel, bouton Programmer / Démarrer.

### 18. Pro Finances — `screens/pro/finances.dart`
Carte de solde, commissions plateforme (10 % / 15 % / 10 %), historique
des versements, exports CSV / PDF fictifs.

### 19. Pro Stats — `screens/pro/stats.dart`
Cartes métriques (Audience 30j, Engagement, Revenus 30j, Taux de réponse),
sources de trafic (`LinearProgressIndicator` par canal).

## Écrans ajoutés — v1.1 (conformité au chapitre 8 du cahier des charges)

Un audit du cahier des charges (chap. 7 « User stories », chap. 8
« Spécifications UX ») a fait ressortir des écrans manquants et ~27 boutons
sans destination (`onPressed: () {}`). Tous sont désormais maquettés et reliés.

### Partagés — `screens/shared/`

| # | Écran | Fichier | Couvre |
|---|-------|---------|--------|
| 20 | Centre de notifications (filtres, « Tout lire ») | `shared/notifications.dart` | §8.1.1 (badges du header) |
| 21 | Recharger le portefeuille | `shared/wallet_actions.dart` › `TopUpScreen` | UC-IN-21 |
| 22 | Retrait Mobile Money (montant → OTP → succès) | `shared/wallet_actions.dart` › `WithdrawScreen` | UC-PR-18, annexe C.3 |

### Internaute — `screens/client/`

| # | Écran | Fichier | Couvre |
|---|-------|---------|--------|
| 23 | Filtres de recherche (ville, rayon, note, tarif, dispo, vérifiés) | `discover_tabs.dart` › `showDiscoverFilters` | §8.1.2, UC-IN-03 |
| 24 | Onglets Publications / Lives / Événements de Découvrir | `discover_tabs.dart` | §8.1.2 |
| 25 | Détail d'un post + commentaires | `post_detail.dart` | UC-IN-06 |
| 26 | Groupes : liste, fil, adhésion (public / privé / payant) | `groups.dart` › `GroupList`, `GroupScreen` | UC-IN-07 |
| 27 | Pièces jointes chat (PDF, photo, vidéo, vocal, devis) | `groups.dart` › `showAttachmentSheet` | UC-IN-08 |
| 28 | Demande de devis | `my_orders.dart` › `QuoteRequestScreen` | UC-IN-10 |
| 29 | Mes commandes | `my_orders.dart` › `MyOrdersScreen` | UC-IN-12 |
| 30 | Suivi de commande (timeline escrow, valider, annuler) | `my_orders.dart` › `OrderTrackingScreen` | UC-IN-12, annexe C.1 |
| 31 | Ouverture / suivi de litige | `my_orders.dart` › `DisputeScreen` | UC-IN-13 |
| 32 | Noter et rédiger un avis | `my_orders.dart` › `ReviewScreen` | UC-IN-14 |
| 33 | Achat de billet de live payant | `tickets.dart` › `showTicketSheet` | UC-IN-15, annexe C.2 |
| 34 | Mes billets & replays | `tickets.dart` › `MyTicketsScreen` | UC-IN-16, UC-IN-19 |
| 35 | Réglages notifications (catégories, cloche par pro, ne pas déranger) | `settings.dart` › `NotificationSettingsScreen` | §8.1.8, UC-IN-05 |
| 36 | Sécurité (2FA, biométrie, sessions actives, export données) | `settings.dart` › `SecurityScreen` | §8.1.8 |
| 37 | Modifier le profil | `settings.dart` › `EditProfileScreen` | UC-IN-01 |
| 38 | Aide, FAQ, support, CGU | `settings.dart` › `HelpCenterScreen` | §8.1.8 |
| — | Signalement (post, pro, live, groupe, avis) | `widgets/common.dart` › `showReportSheet` | UC-IN-22 |

### Professionnel — `screens/pro/`

| # | Écran | Fichier | Couvre |
|---|-------|---------|--------|
| 39 | Détail commande (confirmer / livrer / refuser / signaler) | `order_detail.dart` › `ProOrderDetailScreen` | §8.2.4 |
| 40 | Répondre à un devis (lignes, total, délai) | `order_detail.dart` › `QuoteReplyScreen` | UC-PR-08 |
| 41 | Éditeur de prestation (tarif, 3 formules, livrables, statut) | `service_editor.dart` | §8.2.3, UC-PR-07 |
| 42 | Vérification caméra / micro / réseau | `live_studio.dart` › `LivePrecheckScreen` | §8.2.5 |
| 43 | Diffusion en direct (chat, dons, spectateurs, contrôles, fin confirmée) | `live_studio.dart` › `LiveOnAirScreen` | §8.2.5 |
| 44 | Bilan de live + politique de replay | `live_studio.dart` › `LiveSummaryScreen` | UC-PR-14 |
| 45 | KYC 3 niveaux (Vérifié / Premium / Expert) | `kyc.dart` | UC-PR-01 |
| 46 | Sponsorisation en 3 étapes (quoi → audience/budget → récap) | `sponsor.dart` › `SponsorScreen` | UC-PR-16 |
| 47 | Packs Gratuit / Premium / Business | `sponsor.dart` › `PlansScreen` | UC-PR-20 |
| 48 | Avis reçus + réponse publique + blocage | `reviews.dart` | UC-PR-19, UC-PR-22 |
| — | Création de groupe (public / privé / payant) | `client/groups.dart` › `CreateGroupScreen` | UC-PR-10 |

### Écrans existants enrichis

- **Feed** : cloche → Notifications, loupe → Recherche, stories cliquables,
  menu « ⋯ » (copier / masquer / signaler), like interactif, commentaires →
  PostDetail.
- **Discover** : bouton filtres avec compteur, 4 onglets réels (plus de
  placeholders), bouton « Voir » actif, état vide.
- **Messaging** : onglets qui filtrent vraiment, onglet Groupes, nouveau
  message, nouveau groupe.
- **Chat** : pièces jointes, note vocale, appels audio/vidéo (feedback).
- **Pro profile** : Suivre + cloche séparés, partager, signaler, onglet Lives.
- **Service detail** : « Demander un devis » → QuoteRequest.
- **Live view** : durée, Suivre, Partager (lives gratuits uniquement),
  Signaler, pourboire sélectionnable qui s'affiche dans le chat.
- **Wallet** : Recharger → TopUp, export du relevé, retrait bloqué pour
  les internautes (§8.1.7 : « retrait limité aux pros »).
- **Profile** : chaque ligne mène à un écran.
- **Pro Dashboard** : raccourcis Avis / Sponsoriser / Groupe, 4 alertes
  cliquables (devis, litige, KYC, packs).
- **Pro Orders** : données `MockData.orders()`, devis à chiffrer, détail.
- **Pro Catalog** : FAB « Nouvelle prestation », réordonnancement réel,
  statuts Active / Brouillon / En pause, suppression confirmée.
- **Pro Live** : sélecteurs date/heure, « Programmer » vs « Démarrer ».
- **Pro Publish** : compteur de médias (10 max), programmation, sponsorisation.
- **Pro Finances** : retrait → WithdrawScreen (OTP 2FA).
- **Pro Stats** : export CSV.

### Hors périmètre mobile

Les parcours **Annonceur** (UC-AN-01 → 08) et **Administrateur**
(UC-AD-01 → 14) relèvent du back-office Next.js (`backoffice/` : modules
`advertisers`, `ads`, `pros`, `disputes`, `moderation`, …).

## Données démo

`lib/data.dart::MockData` fournit :

Le jeu de données est volontairement fourni pour que chaque écran ressemble
à une application en production (pas de listes à 2 éléments suivies d'un
grand vide) :

- **10 pros** couvrant 10 catégories (droit, gastronomie, tech, santé,
  bâtiment, comptabilité, beauté, éducation, artisanat, marketing) à
  Douala, Yaoundé, Bafoussam et Garoua. Portraits et images : Unsplash
  (compatible CORS, donc aussi en web), mis en cache par
  `cached_network_image`.
- **8 posts** (sponsorisé, galerie 2 images, posts texte seul, annonce live).
- **~20 services** : chaque pro a son propre catalogue, tous les types de
  tarification (`fixed`, `from`, `quote`, `hourly`, `monthly`).
- **5 lives** (2 en direct, 3 planifiés, gratuits et payants).
- **8 conversations** avec compteur de non-lus, statut en ligne, archivée,
  messages FR + EN mélangés (démo traduction).
- **11 commandes** (`MockData.orders()`) couvrant tous les statuts escrow,
  avec des clients nommés (`MockData.clients`).
- **8 notifications**, **9 transactions** portefeuille, **5 avis**,
  **6 réalisations** de portfolio, **3 groupes**, **12 catégories**.

Le pro connecté en démo est **Me. Aïcha Nkomo** (`MockData.pros[0]`) ;
l'internaute connecté est **Emmanuel Sakam** (`MockData.meAvatar`).

Tous les prix passent par `formatXaf()` (`widgets/common.dart`), qui
insère les espaces milliers et suffixe « XAF ».

## Build APK

```bash
cd Application
flutter pub get
dart run flutter_launcher_icons     # (une seule fois, régénère les mipmaps)
flutter build apk --release
```

L'APK signé (clé debug pour le MVP) est produit dans
`build/app/outputs/flutter-apk/app-release.apk`.

Pour installer sur un appareil branché : `flutter install --release`.
