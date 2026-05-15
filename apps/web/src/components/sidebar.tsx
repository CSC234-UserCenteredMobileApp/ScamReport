import { NavLink } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { BarChart3, Megaphone, Shield, ShieldCheck, Sparkles, Trash2 } from 'lucide-react';
import type { ComponentType, SVGProps } from 'react';
import { cn } from '@/lib/utils';

type IconType = ComponentType<SVGProps<SVGSVGElement>>;

interface NavItem {
  to: string;
  icon: IconType;
  labelKey: string;
}

const NAV_ITEMS: NavItem[] = [
  { to: '/moderation', icon: ShieldCheck, labelKey: 'nav.moderation' },
  { to: '/announcements', icon: Megaphone, labelKey: 'nav.announcements' },
  { to: '/deletion-requests', icon: Trash2, labelKey: 'nav.deletionRequests' },
  { to: '/platform-summary', icon: BarChart3, labelKey: 'nav.platformSummary' },
  { to: '/ai-eval', icon: Sparkles, labelKey: 'nav.aiEval' },
];

export function Sidebar({ onNavigate }: { onNavigate?: () => void }) {
  const { t } = useTranslation();
  return (
    <nav
      aria-label="Main navigation"
      className="flex h-full w-64 flex-col gap-1 border-r bg-card px-4 py-6"
    >
      <div className="mb-6 flex items-center gap-2 px-2">
        <Shield className="size-6 text-primary" aria-hidden />
        <span className="text-lg font-bold tracking-tight">
          {t('appName')}
        </span>
      </div>
      {NAV_ITEMS.map((item) => (
        <NavLink
          key={item.to}
          to={item.to}
          onClick={onNavigate}
          className={({ isActive }) =>
            cn(
              'flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors',
              isActive
                ? 'bg-primary/10 text-primary'
                : 'text-muted-foreground hover:bg-accent hover:text-foreground',
            )
          }
        >
          <item.icon className="size-4" aria-hidden />
          <span>{t(item.labelKey)}</span>
        </NavLink>
      ))}
    </nav>
  );
}
