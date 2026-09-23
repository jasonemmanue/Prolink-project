import AdminLayout from '@/components/AdminLayout';

export default function ModerationPage() {
  return (
    <AdminLayout title="Modération contenus" subtitle="Signalements, actions, historique">
      <div className="grid grid-cols-3 gap-4">
        {[
          { severity: 'Haute', txt: 'Post signalé pour arnaque potentielle (12 signalements)', pro: 'Zita K.', color: 'border-prolink-danger' },
          { severity: 'Moyenne', txt: 'Contenu dupliqué détecté sur 3 posts', pro: 'Franck T.', color: 'border-prolink-accent' },
          { severity: 'Basse', txt: 'Propos limite dans un commentaire', pro: 'Landry M.', color: 'border-prolink-secondary' },
        ].map((r) => (
          <div key={r.txt} className={`card p-4 border-l-4 ${r.color}`}>
            <div className="text-xs uppercase text-prolink-textSecondary mb-1">Sévérité : {r.severity}</div>
            <div className="font-semibold mb-2">{r.txt}</div>
            <div className="text-xs mb-4">Auteur : {r.pro}</div>
            <div className="flex gap-2">
              <button className="pill bg-prolink-surface">Garder</button>
              <button className="pill bg-amber-100 text-prolink-accent">Masquer</button>
              <button className="pill bg-red-100 text-prolink-danger">Supprimer</button>
              <button className="pill bg-prolink-primary text-white">Sanctionner</button>
            </div>
          </div>
        ))}
      </div>
      <div className="card p-4 mt-6">
        <h2 className="font-semibold mb-3">Filtre de modération automatique — mots-clés</h2>
        <div className="flex flex-wrap gap-2 mb-3">
          {['insulte1', 'insulte2', 'arnaque', 'spam-url', 'contact-hors-app'].map((k) => (
            <span key={k} className="pill bg-prolink-surface">{k} ×</span>
          ))}
        </div>
        <input placeholder="Ajouter un mot-clé…" className="w-full bg-prolink-surface border border-prolink-divider px-3 py-2 rounded-lg text-sm" />
      </div>
    </AdminLayout>
  );
}
