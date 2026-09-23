import AdminLayout from '@/components/AdminLayout';

const rows = [
  ['Commission prestations', '10 %', 'Prélevée sur chaque paiement séquestré'],
  ['Commission live payant unique', '15 %', 'Sur chaque billet vendu'],
  ['Commission live payant abonnement mensuel', '20 %', 'Sur abonnements mensuels'],
  ['Commission pourboires (lives gratuits)', '10 %', 'Sur les dons/pourboires'],
  ['Pack Compte Pro Premium', '5 000 XAF/mois', '50 000 XAF/an'],
  ['Pack Compte Pro Business', '20 000 XAF/mois', 'Multi-utilisateurs, API'],
  ['Vérification express KYC', '5 000 XAF', 'Traitement <24h'],
  ['Rapport export CSV', '2 000 XAF', 'Par rapport'],
  ['Frais litige', '1 000 XAF', 'Facultatif, si abus détecté'],
];

export default function PricingPage() {
  return (
    <AdminLayout title="Tarifs & commissions" subtitle="Configuration MVP · commission 10 % max prestation">
      <div className="card overflow-hidden mb-4">
        <table className="w-full text-sm">
          <thead className="bg-prolink-surface text-left text-prolink-textSecondary">
            <tr><th className="p-3">Poste</th><th>Valeur</th><th>Notes</th><th>Actif</th></tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r[0]} className="border-t border-prolink-divider">
                <td className="p-3 font-semibold">{r[0]}</td>
                <td><input defaultValue={r[1]} className="bg-prolink-surface border border-prolink-divider px-2 py-1 rounded-md" /></td>
                <td className="text-prolink-textSecondary">{r[2]}</td>
                <td><input type="checkbox" defaultChecked className="accent-prolink-primary" /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <button className="btn-primary">Enregistrer les modifications</button>
    </AdminLayout>
  );
}
