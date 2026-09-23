import AdminLayout from '@/components/AdminLayout';

export default function NotificationsPage() {
  return (
    <AdminLayout title="Notifications push" subtitle="Messages globaux · segments · planification">
      <div className="grid grid-cols-3 gap-4">
        <div className="card p-4 col-span-2">
          <h2 className="font-semibold mb-3">Nouveau message</h2>
          <input placeholder="Titre" className="w-full bg-prolink-surface border border-prolink-divider px-3 py-2 rounded-lg mb-2" />
          <textarea placeholder="Corps du message… (support des emojis)" rows={4} className="w-full bg-prolink-surface border border-prolink-divider px-3 py-2 rounded-lg mb-2"></textarea>
          <div className="grid grid-cols-2 gap-2 mb-2">
            <select className="bg-prolink-surface border border-prolink-divider px-3 py-2 rounded-lg text-sm">
              <option>Cible : tous</option>
              <option>Pros</option>
              <option>Internautes</option>
              <option>Par catégorie</option>
              <option>Par ville</option>
            </select>
            <input type="datetime-local" className="bg-prolink-surface border border-prolink-divider px-3 py-2 rounded-lg text-sm" />
          </div>
          <button className="btn-primary">Programmer l&apos;envoi</button>
        </div>
        <div className="card p-4">
          <h2 className="font-semibold mb-3">Envois récents</h2>
          <ul className="text-sm space-y-3">
            <li>📢 Maintenance planifiée — 41 320 destinataires</li>
            <li>🎁 Compte pro gratuit 6 mois — 4 218 destinataires</li>
            <li>⚡ Nouveau live populaire — 12 040 destinataires</li>
            <li>🔔 Litige — 32 destinataires</li>
          </ul>
        </div>
      </div>
    </AdminLayout>
  );
}
