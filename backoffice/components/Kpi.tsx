import { LucideIcon } from 'lucide-react';

export function Kpi({
  icon: Icon,
  label,
  value,
  trend,
  color = 'text-prolink-primary',
}: {
  icon: LucideIcon;
  label: string;
  value: string;
  trend?: string;
  color?: string;
}) {
  return (
    <div className="card p-4">
      <div className="flex items-center justify-between">
        <div className={`w-10 h-10 rounded-lg flex items-center justify-center bg-prolink-surface ${color}`}>
          <Icon size={20} />
        </div>
        {trend && (
          <span className="pill bg-green-100 text-prolink-success">{trend}</span>
        )}
      </div>
      <div className="mt-3 text-xs text-prolink-textSecondary">{label}</div>
      <div className="text-xl font-extrabold">{value}</div>
    </div>
  );
}
