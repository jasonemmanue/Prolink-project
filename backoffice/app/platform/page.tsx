import AdminLayout from '@/components/AdminLayout';

export default function PlatformPage() {
  return (
    <AdminLayout title="Paramétrage plateforme" subtitle="CGU, confidentialité, mots-clés interdits, langues, traduction">
      <div className="grid grid-cols-2 gap-4">
        <div className="card p-4">
          <h2 className="font-semibold mb-2">Langues supportées</h2>
          <div className="flex flex-wrap gap-2 mb-3">
            {['FR', 'EN', 'DUALA (Phase 3)', 'BASSA (Phase 3)'].map((l) => <span key={l} className="pill bg-prolink-surface">{l}</span>)}
          </div>
          <label className="text-sm block mb-1">Fournisseur de traduction chat</label>
          <select className="w-full bg-prolink-surface border border-prolink-divider px-3 py-2 rounded-lg text-sm">
            <option>LibreTranslate self-hosted</option>
            <option>DeepL API</option>
            <option>Google Cloud Translate</option>
          </select>
        </div>
        <div className="card p-4">
          <h2 className="font-semibold mb-2">Politique de contenu (extrait)</h2>
          <textarea rows={7} className="w-full bg-prolink-surface border border-prolink-divider px-3 py-2 rounded-lg text-sm" defaultValue={'Interdiction : alcool, tabac, jeux d\'argent, politique. Publicité modérée manuellement.'}></textarea>
        </div>
        <div className="card p-4 col-span-2">
          <h2 className="font-semibold mb-2">Ordre des CGU / mentions légales</h2>
          <textarea rows={5} className="w-full bg-prolink-surface border border-prolink-divider px-3 py-2 rounded-lg text-sm" defaultValue={'Conformité loi camerounaise sur les données personnelles. RGPD-ready pour extension Europe.'}></textarea>
        </div>
      </div>
    </AdminLayout>
  );
}
