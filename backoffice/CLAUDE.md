# Backoffice — contexte

## Stack

- Next.js 14 App Router (`app/`)
- TypeScript strict
- Tailwind CSS (config `tailwind.config.ts`, thème étendu `prolink.*`)
- Icônes `lucide-react`, charts `recharts` (dispo, à câbler)

## Conventions

- Toutes les pages module habillent leur contenu avec `<AdminLayout title subtitle>` (fournit sidebar + header).
- Métriques via `<Kpi icon label value trend />`.
- Utiliser les classes utilitaires `pill`, `card`, `btn-primary` définies dans `globals.css` plutôt que d'inliner les styles.
- Aucun couplage Framework/data pour l'instant : chaque page module utilise des données statiques inline (à remplacer par des `fetch()` côté server component vers `Api/`).

## Branchement API

Le backend expose les endpoints admin dans `Api/app/api/v1/routes/admin.py` (`/api/v1/admin/*`). Le login /2FA doit poser un cookie httpOnly côté Next (route handler `app/api/auth/route.ts` à créer). Voir aussi `/api/v1/auth/otp/*` pour le 2FA.

## Rappels sécurité

- JWT stockés en cookie httpOnly / SameSite=strict.
- Chaque action admin doit être loggée dans le journal d'audit (`admin.py` back).
