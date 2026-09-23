# ProLink — Backoffice (Next.js 14)

Panneau d'administration web responsive. 15 modules du cahier des charges.

## Modules

1. Dashboard KPI temps réel
2. Gestion des pros (KYC, suspension)
3. Gestion internautes
4. Gestion annonceurs
5. Catégories métier (CRUD, hiérarchie)
6. Modération contenus
7. Modération lives (coupure d'urgence)
8. Litiges & Séquestre (arbitrage)
9. Tarifs & commissions
10. Publicité (validation campagnes)
11. Notifications push
12. Analytics (funnel, cohortes)
13. Finances (réconciliation Mobile Money)
14. Paramétrage plateforme (langues, traduction, CGU)
15. Journal d'audit (RGPD-ready)

## Démarrage

```bash
npm install
npm run dev            # http://localhost:3000
npm run build && npm run start
```

Login démo : n'importe quel email → clic « Se connecter ».

## Charte

Palette Tailwind `prolink.*` dans `tailwind.config.ts`. Composants réutilisables dans `components/` (`Sidebar`, `PageHeader`, `AdminLayout`, `Kpi`).
