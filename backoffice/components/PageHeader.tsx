import { Bell, Search } from 'lucide-react';

export default function PageHeader({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <header className="flex items-center justify-between mb-6">
      <div>
        <h1 className="text-2xl font-bold text-prolink-textPrimary">{title}</h1>
        {subtitle && <p className="text-sm text-prolink-textSecondary">{subtitle}</p>}
      </div>
      <div className="flex items-center gap-3">
        <div className="flex items-center gap-2 bg-white border border-prolink-divider px-3 py-2 rounded-xl">
          <Search size={16} className="text-prolink-textSecondary" />
          <input placeholder="Rechercher…" className="outline-none text-sm bg-transparent w-56" />
        </div>
        <button className="relative bg-white border border-prolink-divider p-2 rounded-xl">
          <Bell size={18} />
          <span className="absolute -top-1 -right-1 bg-prolink-accent text-white text-[10px] w-4 h-4 rounded-full flex items-center justify-center">6</span>
        </button>
        <div className="flex items-center gap-2 bg-white border border-prolink-divider pl-1 pr-3 py-1 rounded-xl">
          <div className="w-8 h-8 rounded-full bg-prolink-primary text-white flex items-center justify-center font-semibold text-sm">AN</div>
          <div className="text-sm">
            <div className="font-semibold leading-tight">Admin</div>
            <div className="text-[11px] text-prolink-textSecondary leading-tight">Super-admin</div>
          </div>
        </div>
      </div>
    </header>
  );
}
