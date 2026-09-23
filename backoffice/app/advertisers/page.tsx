import AdminLayout from '@/components/AdminLayout';

export default function AdvertisersPage() {
  return (
    <AdminLayout title="Annonceurs" subtitle="Gestion des marques partenaires et facturation">
      <div className="card p-4 mb-4">
        <table className="w-full text-sm">
          <thead className="text-left text-prolink-textSecondary">
            <tr><th className="p-2">Annonceur</th><th>Campagnes actives</th><th>Budget cumulé</th><th>Facturation</th><th>Statut</th></tr>
          </thead>
          <tbody>
            {['Orange Cameroun', 'MTN Mobile Money', 'Ecobank Business', 'Bao Tech', 'Nescafé Africa'].map((n, i) => (
              <tr key={n} className="border-t border-prolink-divider">
                <td className="p-2 font-semibold">{n}</td>
                <td>{2 + i}</td>
                <td>{(300000 + i * 50000).toLocaleString('fr')} XAF</td>
                <td>Mensuelle</td>
                <td><span className="pill bg-green-100 text-prolink-success">Actif</span></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </AdminLayout>
  );
}
