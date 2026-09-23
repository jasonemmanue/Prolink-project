'use client';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard, Users, UserCheck, Megaphone, LayoutList,
  ShieldCheck, Radio, Scale, DollarSign, BellRing, BarChart3,
  Settings, Landmark, Sliders, FileText, LogOut,
} from 'lucide-react';

const modules = [
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/pros', label: 'Gestion pros', icon: UserCheck },
  { href: '/users', label: 'Internautes', icon: Users },
  { href: '/advertisers', label: 'Annonceurs', icon: Megaphone },
  { href: '/categories', label: 'Catégories métier', icon: LayoutList },
  { href: '/moderation', label: 'Modération contenus', icon: ShieldCheck },
  { href: '/lives', label: 'Modération lives', icon: Radio },
  { href: '/disputes', label: 'Litiges & Séquestre', icon: Scale },
  { href: '/pricing', label: 'Tarifs & commissions', icon: DollarSign },
  { href: '/ads', label: 'Publicité', icon: Megaphone },
  { href: '/notifications', label: 'Notifications push', icon: BellRing },
  { href: '/analytics', label: 'Analytics', icon: BarChart3 },
  { href: '/finances', label: 'Finances', icon: Landmark },
  { href: '/platform', label: 'Paramétrage plateforme', icon: Sliders },
  { href: '/audit', label: 'Journal d\'audit', icon: FileText },
];

export default function Sidebar() {
  const pathname = usePathname();
  return (
    <aside className="w-64 h-screen sticky top-0 bg-white border-r border-prolink-divider flex flex-col">
      <div className="p-5 flex items-center gap-3 border-b border-prolink-divider">
        <Image src="/logo.png" alt="ProLink" width={36} height={36} />
        <div>
          <div className="font-display font-extrabold text-lg text-prolink-primary">ProLink</div>
          <div className="text-[10px] uppercase tracking-wider text-prolink-textSecondary">Admin</div>
        </div>
      </div>
      <nav className="flex-1 overflow-y-auto py-3">
        {modules.map((m) => {
          const active = pathname === m.href;
          const Icon = m.icon;
          return (
            <Link
              key={m.href}
              href={m.href}
              className={`flex items-center gap-3 px-4 py-2.5 text-sm mx-2 my-0.5 rounded-lg ${
                active
                  ? 'bg-prolink-primary text-white font-semibold'
                  : 'text-prolink-textPrimary hover:bg-prolink-surface'
              }`}
            >
              <Icon size={17} />
              <span>{m.label}</span>
            </Link>
          );
        })}
      </nav>
      <Link href="/" className="p-4 flex items-center gap-2 text-sm text-prolink-danger border-t border-prolink-divider">
        <LogOut size={16} /> Se déconnecter
      </Link>
    </aside>
  );
}
