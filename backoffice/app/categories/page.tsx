import AdminLayout from '@/components/AdminLayout';
import { Plus, Edit, EyeOff } from 'lucide-react';

const cats = [
  ['Droit & Justice', 342, 12],
  ['Ingénierie & Bâtiment', 428, 8],
  ['Digital & Tech', 812, 14],
  ['Santé & Bien-être', 315, 9],
  ['Éducation & Formation', 268, 7],
  ['Gastronomie & Événementiel', 205, 11],
  ['Beauté & Mode', 189, 8],
  ['Finance & Comptabilité', 152, 5],
  ['Artisanat', 244, 12],
  ['Conseil & Business', 384, 10],
  ['Culture & Arts', 176, 8],
  ['Autres services', 703, 20],
];

export default function CategoriesPage() {
  return (
    <AdminLayout title="Catégories métier" subtitle="Structure hiérarchique · CRUD · réordonnancement">
      <div className="flex items-center gap-2 mb-4">
        <button className="btn-primary flex items-center gap-2"><Plus size={16} /> Nouvelle catégorie</button>
        <button className="pill bg-white border border-prolink-divider">Importer CSV</button>
      </div>
      <div className="card p-4 grid grid-cols-2 gap-3">
        {cats.map(([name, pros, subs]) => (
          <div key={name as string} className="border border-prolink-divider rounded-xl p-3 flex items-center">
            <div className="flex-1">
              <div className="font-semibold">{name as string}</div>
              <div className="text-xs text-prolink-textSecondary">{pros as number} pros · {subs as number} sous-catégories</div>
            </div>
            <button className="p-2 text-prolink-textSecondary"><Edit size={16} /></button>
            <button className="p-2 text-prolink-textSecondary"><EyeOff size={16} /></button>
          </div>
        ))}
      </div>
    </AdminLayout>
  );
}
