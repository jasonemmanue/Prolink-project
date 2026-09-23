import AdminLayout from '@/components/AdminLayout';
import { Kpi } from '@/components/Kpi';
import { Users, ShoppingBag, AlertTriangle, Ban } from 'lucide-react';

export default function UsersPage() {
  return (
    <AdminLayout title="Internautes" subtitle="Base client, historiques, signalements">
      <div className="grid grid-cols-4 gap-4 mb-6">
        <Kpi icon={Users} label="Comptes actifs (30j)" value="41 320" trend="+18%" />
        <Kpi icon={ShoppingBag} label="Achats moyens" value="1,3 / mois" />
        <Kpi icon={AlertTriangle} label="Signalements" value="42" />
        <Kpi icon={Ban} label="Suspendus" value="7" />
      </div>
      <div className="card p-4">
        <table className="w-full text-sm">
          <thead className="text-left text-prolink-textSecondary">
            <tr>
              <th className="p-2">Nom</th><th>Ville</th><th>Inscription</th><th>Achats</th><th>Statut</th><th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {['Emmanuel Sakam', 'Ariane Ngoumou', 'Kevin Tchouala', 'Marlène Fotso', 'Eric Bidoung'].map((n, i) => (
              <tr key={n} className="border-t border-prolink-divider">
                <td className="p-2 font-semibold">{n}</td>
                <td>Douala</td>
                <td>2026-0{(i % 9) + 1}-15</td>
                <td>{4 + i}</td>
                <td><span className="pill bg-green-100 text-prolink-success">Actif</span></td>
                <td><button className="pill bg-prolink-surface">Voir profil</button></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </AdminLayout>
  );
}
