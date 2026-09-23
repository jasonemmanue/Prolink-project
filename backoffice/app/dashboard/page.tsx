import AdminLayout from '@/components/AdminLayout';
import { Kpi } from '@/components/Kpi';
import {
  Users, UserCheck, ShoppingBag, Radio, DollarSign, AlertTriangle,
} from 'lucide-react';

export default function DashboardPage() {
  return (
    <AdminLayout title="Dashboard" subtitle="Vue globale en temps réel">
      <div className="grid grid-cols-4 gap-4 mb-6">
        <Kpi icon={UserCheck} label="Pros vérifiés" value="4 218" trend="+12%" />
        <Kpi icon={Users} label="Internautes actifs (30j)" value="41 320" trend="+18%" />
        <Kpi icon={ShoppingBag} label="Prestations (30j)" value="12 480" trend="+9%" />
        <Kpi icon={Radio} label="Lives en cours" value="26" />
      </div>
      <div className="grid grid-cols-3 gap-4 mb-6">
        <div className="card p-5 col-span-2">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="font-semibold">Revenus mensuels</h2>
              <p className="text-xs text-prolink-textSecondary">6 derniers mois — projection 64 M XAF</p>
            </div>
            <span className="pill bg-green-100 text-prolink-success">+22%</span>
          </div>
          <div className="flex items-end gap-4 h-48">
            {[38, 45, 52, 48, 61, 64].map((v, i) => (
              <div key={i} className="flex-1 flex flex-col items-center gap-2">
                <div className="w-full rounded-lg bg-gradient-to-t from-prolink-primary to-prolink-secondary" style={{ height: `${v * 2}px` }} />
                <div className="text-[10px] text-prolink-textSecondary">M-{6 - i}</div>
              </div>
            ))}
          </div>
        </div>
        <div className="card p-5">
          <div className="flex items-center gap-2 mb-2">
            <AlertTriangle size={18} className="text-prolink-accent" />
            <h2 className="font-semibold">Alertes</h2>
          </div>
          <ul className="text-sm space-y-3 mt-3">
            <li className="border-l-4 border-prolink-danger pl-3">3 lives signalés à modérer</li>
            <li className="border-l-4 border-prolink-accent pl-3">14 KYC en attente {'>'}24h</li>
            <li className="border-l-4 border-prolink-secondary pl-3">2 litiges à arbitrer</li>
            <li className="border-l-4 border-prolink-primary pl-3">Campagne pub à valider</li>
          </ul>
        </div>
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div className="card p-5">
          <h2 className="font-semibold mb-3">Sources de revenus (mois)</h2>
          {[
            ['Commissions prestations', 22500000, 'bg-prolink-primary'],
            ['Commissions lives payants', 25500000, 'bg-prolink-secondary'],
            ['Comptes Premium/Business', 3500000, 'bg-prolink-accent'],
            ['Sponsorisation', 9000000, 'bg-emerald-500'],
            ['Publicité annonceurs', 3000000, 'bg-purple-500'],
          ].map(([label, v, cls]) => (
            <div key={label as string} className="my-2">
              <div className="flex justify-between text-xs">
                <span>{label as string}</span>
                <span className="font-semibold">{(v as number).toLocaleString('fr')} XAF</span>
              </div>
              <div className="h-2 bg-prolink-surface rounded mt-1"><div className={`h-2 ${cls} rounded`} style={{ width: `${(v as number) / 300000}%` }} /></div>
            </div>
          ))}
        </div>
        <div className="card p-5">
          <h2 className="font-semibold mb-3">Journal récent</h2>
          <ul className="text-sm space-y-2">
            <li>✅ KYC validé — Me. Aïcha Nkomo</li>
            <li>🚫 Post masqué — spam détecté</li>
            <li>💸 Séquestre libéré — 250 000 XAF</li>
            <li>⚡ Live démarré — Chef Landry</li>
            <li>🔍 Nouveau signalement — arnaque potentielle</li>
          </ul>
        </div>
      </div>
    </AdminLayout>
  );
}
