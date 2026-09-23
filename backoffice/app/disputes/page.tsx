import AdminLayout from '@/components/AdminLayout';

export default function DisputesPage() {
  return (
    <AdminLayout title="Litiges & Séquestre" subtitle="Arbitrage, libération manuelle, remboursements">
      <div className="card p-4 mb-4">
        <table className="w-full text-sm">
          <thead className="text-left text-prolink-textSecondary">
            <tr><th className="p-2">Ref</th><th>Client</th><th>Pro</th><th>Montant</th><th>Motif</th><th>État</th><th>Actions</th></tr>
          </thead>
          <tbody>
            {[
              ['#L2401', 'Emmanuel S.', 'Ing. Franck T.', 900000, 'Livraison partielle', 'Ouvert'],
              ['#L2402', 'Ariane N.', 'Chef Landry M.', 250000, 'Retard 5j', 'Ouvert'],
              ['#L2403', 'Kevin T.', 'Me. Aïcha N.', 15000, 'Non conforme', 'En arbitrage'],
              ['#L2404', 'Marlène F.', 'Dr. Muna E.', 30000, 'Annulation force majeure', 'Résolu'],
            ].map((r) => (
              <tr key={r[0] as string} className="border-t border-prolink-divider">
                <td className="p-2 font-semibold">{r[0]}</td>
                <td>{r[1]}</td>
                <td>{r[2]}</td>
                <td>{(r[3] as number).toLocaleString('fr')} XAF</td>
                <td>{r[4]}</td>
                <td><span className="pill bg-amber-100 text-prolink-accent">{r[5]}</span></td>
                <td>
                  <div className="flex gap-1">
                    <button className="pill bg-green-100 text-prolink-success">Libérer pro</button>
                    <button className="pill bg-red-100 text-prolink-danger">Rembourser</button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div className="card p-4">
        <h2 className="font-semibold mb-3">Fonds en séquestre — vue globale</h2>
        <div className="grid grid-cols-3 gap-4 text-center">
          <div><div className="text-xs text-prolink-textSecondary">Bloqués</div><div className="text-2xl font-bold">184 M XAF</div></div>
          <div><div className="text-xs text-prolink-textSecondary">Libérés (30j)</div><div className="text-2xl font-bold">522 M XAF</div></div>
          <div><div className="text-xs text-prolink-textSecondary">Remboursés (30j)</div><div className="text-2xl font-bold">18 M XAF</div></div>
        </div>
      </div>
    </AdminLayout>
  );
}
