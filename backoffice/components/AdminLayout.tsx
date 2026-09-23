import Sidebar from './Sidebar';
import PageHeader from './PageHeader';

export default function AdminLayout({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
}) {
  return (
    <div className="flex bg-prolink-surface">
      <Sidebar />
      <main className="flex-1 min-h-screen p-6 overflow-x-auto">
        <PageHeader title={title} subtitle={subtitle} />
        {children}
      </main>
    </div>
  );
}
