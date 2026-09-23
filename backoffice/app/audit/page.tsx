import AdminLayout from '@/components/AdminLayout';

export default function AuditPage() {
  return (
    <AdminLayout title="Journal d'audit" subtitle="Traçabilité RGPD-ready de toutes les actions admin">
      <div className="card p-4">
        <table className="w-full text-sm">
          <thead className="text-left text-prolink-textSecondary">
            <tr><th className="p-2">Date</th><th>Admin</th><th>Action</th><th>Cible</th><th>IP</th></tr>
          </thead>
          <tbody>
            {[
              ['2026-09-23 14:12', 'admin.jason', 'KYC validé', 'p2 · Chef Landry', '92.148.x.x'],
              ['2026-09-23 13:47', 'admin.jason', 'Libération séquestre', '#PL2401 · 900 000 XAF', '92.148.x.x'],
              ['2026-09-23 12:04', 'moderator.anna', 'Post masqué', 'Post #5241 · spam', '196.226.x.x'],
              ['2026-09-23 11:30', 'admin.jason', 'Config commission', 'lives 15→17 %', '92.148.x.x'],
              ['2026-09-22 22:03', 'moderator.anna', 'Coupure live', '#L339 illicite', '196.226.x.x'],
            ].map((r, i) => (
              <tr key={i} className="border-t border-prolink-divider">
                {r.map((c, j) => <td key={j} className="p-2">{c}</td>)}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </AdminLayout>
  );
}
