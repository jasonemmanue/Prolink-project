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
              │     ├─ Feed
              │     ├─ Discover
              │     ├─ Messaging ─▶ Chat (traduction FR⇄EN)
              │     ├─ Wallet
              │     └─ Profile
              │
              └─▶ ProShell         (rôle « Je propose »)
                    ├─ Dashboard   (+ FAB « Publier »)
                    ├─ Orders
                    ├─ Catalog
                    ├─ LiveBroadcast
                    └─ Finances
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

## Données démo

`lib/data.dart::MockData` fournit :

- **4 pros** : Aïcha Nkomo (Droit), Landry Mbappé (Gastronomie), Franck Talla
  (Digital), Muna Etienne (Santé) — avec avatars/couvertures Unsplash mis
  en cache par `cached_network_image`.
- **4 posts** dont un sponsorisé et un avec galerie 2 images.
- **7 services** couvrant les 4 types de tarification (`fixed`, `from`,
  `quote`, plus `hourly` / `monthly` supportés par le modèle).
- **3 lives** (1 en direct, 2 planifiés, 1 gratuit / 2 payants).
- **2 conversations** avec messages FR + EN mélangés (démo traduction).
- **12 catégories** métier.

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
