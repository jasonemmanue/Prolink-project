import AdminLayout from '@/components/AdminLayout';
import { Kpi } from '@/components/Kpi';
import { Users, TrendingUp, MousePointerClick, Repeat } from 'lucide-react';

export default function AnalyticsPage() {
  return (
    <AdminLayout title="Analytics" subtitle="Cohortes · conversion · LTV">
      <div className="grid grid-cols-4 gap-4 mb-6">
        <Kpi icon={Users} label="MAU" value="41 320" trend="+18%" />
        <Kpi icon={TrendingUp} label="Rétention 30j" value="46 %" trend="+2%" />
        <Kpi icon={MousePointerClick} label="Taux de conversion pro" value="6,4 %" />
        <Kpi icon={Repeat} label="LTV / pro" value="185 000 XAF" />
      </div>
      <div className="card p-5">
        <h2 className="font-semibold mb-3">Funnel d&apos;acquisition</h2>
        {[
          ['Installations', 100],
          ['Compte créé', 78],
          ['Profil complété', 62],
          ['Premier suivi', 54],
          ['Premier achat', 22],
          ['Achat récurrent', 12],
        ].map(([label, v]) => (
          <div key={label as string} className="my-2">
            <div className="flex justify-between text-xs mb-1">
              <span>{label as string}</span><span className="font-semibold">{v as number} %</span>
            </div>
            <div className="h-2 bg-prolink-surface rounded"><div className="h-2 bg-prolink-primary rounded" style={{ width: `${v}%` }} /></div>
          </div>
        ))}
      </div>
    </AdminLayout>
  );
}
