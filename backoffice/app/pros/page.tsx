import AdminLayout from '@/components/AdminLayout';
import { CheckCircle2, XCircle, Clock, MoreHorizontal, Filter } from 'lucide-react';

const pros = [
  { id: 'p1', name: 'Me. Aïcha Nkomo', job: 'Avocate', city: 'Douala', status: 'Vérifié', level: 3, orders: 84 },
  { id: 'p2', name: 'Chef Landry Mbappé', job: 'Chef cuisinier', city: 'Yaoundé', status: 'Vérifié', level: 2, orders: 62 },
  { id: 'p3', name: 'Ing. Franck Talla', job: 'Développeur mobile', city: 'Douala', status: 'En attente', level: 0, orders: 0 },
  { id: 'p4', name: 'Dr. Muna Etienne', job: 'Coach sportif', city: 'Yaoundé', status: 'Vérifié', level: 2, orders: 124 },
  { id: 'p5', name: 'Zita Kouam', job: 'Community manager', city: 'Kribi', status: 'Rejeté', level: 0, orders: 0 },
];

export default function ProsPage() {
  return (
    <AdminLayout title="Gestion pros" subtitle="Validation KYC, suspensions, exclusions">
      <div className="card p-4 flex items-center gap-3 mb-4">
        <button className="pill bg-prolink-primary text-white">Tous (4 218)</button>
        <button className="pill bg-prolink-surface">Vérifiés</button>
        <button className="pill bg-prolink-accent/20 text-prolink-accent">KYC en attente (14)</button>
        <button className="pill bg-red-100 text-prolink-danger">Suspendus</button>
        <div className="ml-auto flex items-center gap-2 text-sm text-prolink-textSecondary"><Filter size={14} /> Filtres</div>
      </div>
      <div className="card overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-prolink-surface text-prolink-textSecondary text-left">
            <tr>
              <th className="p-3">Pro</th>
              <th className="p-3">Métier · Ville</th>
              <th className="p-3">Niveau</th>
              <th className="p-3">Statut</th>
              <th className="p-3">Prestations</th>
              <th className="p-3">Actions</th>
            </tr>
          </thead>
          <tbody>
            {pros.map((p) => (
              <tr key={p.id} className="border-t border-prolink-divider">
                <td className="p-3 font-semibold">{p.name}</td>
                <td className="p-3">{p.job} · {p.city}</td>
                <td className="p-3">
                  <span className="pill bg-prolink-surface">Niveau {p.level}</span>
                </td>
                <td className="p-3">
                  {p.status === 'Vérifié' && <span className="pill bg-green-100 text-prolink-success"><CheckCircle2 size={12} /> Vérifié</span>}
                  {p.status === 'En attente' && <span className="pill bg-amber-100 text-prolink-accent"><Clock size={12} /> En attente</span>}
                  {p.status === 'Rejeté' && <span className="pill bg-red-100 text-prolink-danger"><XCircle size={12} /> Rejeté</span>}
                </td>
                <td className="p-3">{p.orders}</td>
                <td className="p-3">
                  <div className="flex gap-2">
                    <button className="pill bg-prolink-primary text-white">Voir KYC</button>
                    <button className="pill bg-prolink-surface"><MoreHorizontal size={12} /></button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </AdminLayout>
  );
}
