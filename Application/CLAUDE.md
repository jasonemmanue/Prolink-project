# Application (Flutter) — contexte

## Conventions

- **Pas de gestionnaire d'état lourd** : Provider seulement pour `AppLocale` (FR/EN global).
- Les données MVP viennent de `lib/data.dart` (`MockData`). Remplacer par appels HTTP vers `Api/` quand backend live.
- Palette centralisée dans `AppColors` (`lib/theme.dart`). Ne jamais coder de hex en dur.
- Prix XAF via `formatXaf()` (`lib/widgets/common.dart`).

## Écrans MVP

**Internaute (5 onglets)** :
1. Feed — `client/feed.dart`
2. Découvrir — `client/discover.dart` (catégories + tabs)
3. Messages — `client/messaging.dart` → `client/chat.dart` (**traduction auto**)
4. Portefeuille — `client/wallet.dart`
5. Profil — `client/profile.dart`

Écrans annexes : `client/pro_profile.dart`, `client/service_detail.dart`, `client/order_flow.dart`, `live_view.dart`, `client/post_detail.dart`, `client/my_orders.dart` (suivi, litige, avis, devis), `client/tickets.dart`, `client/groups.dart`, `client/settings.dart`, `client/discover_tabs.dart`, `shared/notifications.dart`, `shared/wallet_actions.dart`.

**Professionnel (5 onglets)** :
1. Tableau de bord — `pro/dashboard.dart`
2. Commandes — `pro/orders.dart`
3. Catalogue — `pro/catalog.dart`
4. Live — `pro/live_broadcast.dart`
5. Finances — `pro/finances.dart`

Écrans annexes : `pro/publish.dart`, `pro/stats.dart`, `pro/order_detail.dart` (+ réponse devis), `pro/service_editor.dart`, `pro/live_studio.dart` (vérifs → direct → bilan), `pro/kyc.dart`, `pro/sponsor.dart` (+ packs), `pro/reviews.dart`.

Carte complète + matrice de couverture du cahier des charges : `SCREENS.md`.

## Points d'attention

- Le logo `assets/images/logo.png` est le logo officiel ProLink.
- Toute string affichée à l'utilisateur doit passer par `AppLocale.t(fr, en)` quand la screen est bilingue.
- La traduction du chat DOIT rester optionnelle et signalée visuellement.
- Le shell rôle est décidé par l'écran `auth.dart`. Ne pas mélanger.
- Navigation : `pushScreen(context, Widget)` ; feedback court : `showInfo(context, msg)` ; signalement : `showReportSheet(context, cible)` (tous dans `widgets/common.dart`).
- Aucun bouton ne doit rester à `onPressed: () {}` : le relier à un écran ou à un `showInfo`.
