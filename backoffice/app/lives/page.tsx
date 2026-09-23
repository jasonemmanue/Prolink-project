import AdminLayout from '@/components/AdminLayout';
import { Kpi } from '@/components/Kpi';
import { Radio, AlertTriangle, Ban, ShieldAlert } from 'lucide-react';

export default function LivesPage() {
  return (
    <AdminLayout title="Modération lives" subtitle="Surveillance temps réel · coupure d'urgence">
      <div className="grid grid-cols-4 gap-4 mb-6">
        <Kpi icon={Radio} label="Lives en cours" value="26" />
        <Kpi icon={AlertTriangle} label="Signalés" value="3" />
        <Kpi icon={ShieldAlert} label="Sanctions 24h" value="2" />
        <Kpi icon={Ban} label="Coupures d'urgence 30j" value="1" />
      </div>
      <div className="grid grid-cols-2 gap-4">
        {['Créer sa SARL en 3 étapes', 'Astuces beauté du jour'].map((title, i) => (
          <div key={title} className="card p-4">
            <div className="aspect-video bg-black rounded-lg mb-3" />
            <div className="flex items-center justify-between">
              <div>
                <div className="font-semibold">{title}</div>
                <div className="text-xs text-prolink-textSecondary">Pro : Me. Aïcha · 143 spectateurs</div>
              </div>
              <span className="pill bg-red-100 text-prolink-danger">● LIVE</span>
            </div>
            <div className="flex gap-2 mt-3">
              <button className="pill bg-prolink-surface">Observer chat</button>
              <button className="pill bg-amber-100 text-prolink-accent">Avertir pro</button>
              <button className="pill bg-red-100 text-prolink-danger">Couper d&apos;urgence</button>
            </div>
          </div>
        ))}
      </div>
    </AdminLayout>
  );
}
