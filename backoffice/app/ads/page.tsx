import AdminLayout from '@/components/AdminLayout';

export default function AdsPage() {
  return (
    <AdminLayout title="Publicité" subtitle="Validation campagnes, enchères, qualité">
      <div className="card p-4 mb-4">
        <table className="w-full text-sm">
          <thead className="text-left text-prolink-textSecondary">
            <tr><th className="p-2">Campagne</th><th>Annonceur</th><th>Format</th><th>Cible</th><th>Budget/j</th><th>Statut</th><th>Actions</th></tr>
          </thead>
          <tbody>
            {[
              ['Promo Orange 4G', 'Orange Cameroun', 'Bannière fil', 'Douala 18-35', 25000, 'À valider'],
              ['MoMo Business', 'MTN', 'Vidéo native', 'Pros toutes cats', 40000, 'Active'],
              ['Ecobank Pack Pro', 'Ecobank', 'Post sponsorisé', 'Finance', 15000, 'Active'],
              ['Formation Bao', 'Bao Tech', 'Recommandation pro', 'Tech Yaoundé', 8000, 'En pause'],
            ].map((r) => (
              <tr key={r[0] as string} className="border-t border-prolink-divider">
                <td className="p-2 font-semibold">{r[0]}</td>
                <td>{r[1]}</td>
                <td>{r[2]}</td>
                <td>{r[3]}</td>
                <td>{(r[4] as number).toLocaleString('fr')} XAF</td>
                <td><span className="pill bg-amber-100 text-prolink-accent">{r[5]}</span></td>
                <td><div className="flex gap-1"><button className="pill bg-green-100 text-prolink-success">Valider</button><button className="pill bg-red-100 text-prolink-danger">Refuser</button></div></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </AdminLayout>
  );
}
