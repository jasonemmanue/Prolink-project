import AdminLayout from '@/components/AdminLayout';
import { Kpi } from '@/components/Kpi';
import { Banknote, ArrowDownRight, ArrowUpRight, Wallet } from 'lucide-react';

export default function FinancesPage() {
  return (
    <AdminLayout title="Finances" subtitle="Rapports comptables, réconciliation Mobile Money">
      <div className="grid grid-cols-4 gap-4 mb-6">
        <Kpi icon={Banknote} label="Chiffre d'affaires (mois)" value="64 M XAF" trend="+22%" />
        <Kpi icon={ArrowUpRight} label="Commissions (mois)" value="48 M XAF" />
        <Kpi icon={Wallet} label="Séquestre en cours" value="184 M XAF" />
        <Kpi icon={ArrowDownRight} label="Retraits (30j)" value="12 M XAF" />
      </div>
      <div className="card p-4">
        <div className="flex items-center justify-between mb-3">
          <h2 className="font-semibold">Réconciliation Mobile Money</h2>
          <div className="flex gap-2 text-sm">
            <button className="pill bg-prolink-surface">Exporter CSV</button>
            <button className="pill bg-prolink-primary text-white">Générer rapport PDF</button>
          </div>
        </div>
        <table className="w-full text-sm">
          <thead className="text-left text-prolink-textSecondary">
            <tr><th className="p-2">Date</th><th>Opérateur</th><th>Entrées</th><th>Sorties</th><th>Écart</th><th>Statut</th></tr>
          </thead>
          <tbody>
            {['2026-09-20', '2026-09-19', '2026-09-18', '2026-09-17'].map((d, i) => (
              <tr key={d} className="border-t border-prolink-divider">
                <td className="p-2">{d}</td>
                <td>{i % 2 === 0 ? 'MTN' : 'Orange'}</td>
                <td>{(4500000 + i * 100000).toLocaleString('fr')} XAF</td>
                <td>{(1200000 + i * 50000).toLocaleString('fr')} XAF</td>
                <td>0 XAF</td>
                <td><span className="pill bg-green-100 text-prolink-success">Réconcilié</span></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </AdminLayout>
  );
}
