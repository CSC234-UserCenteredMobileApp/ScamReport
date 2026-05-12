import { LogOut, User } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '@/lib/auth/auth-context';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';

export function UserPill() {
  const { t } = useTranslation();
  const { user, signOut } = useAuth();
  if (!user) return null;
  const name = user.displayName ?? user.email ?? '?';
  const initials = name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((s) => s[0]?.toUpperCase() ?? '')
    .join('');
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" className="gap-2 px-2">
          <Avatar>
            <AvatarFallback>{initials || <User className="size-4" />}</AvatarFallback>
          </Avatar>
          <span className="hidden text-sm font-medium md:inline">
            {user.email ?? user.displayName}
          </span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="min-w-56">
        <DropdownMenuLabel className="flex flex-col gap-0.5">
          <span className="text-sm font-semibold">
            {user.displayName ?? user.email}
          </span>
          <span className="text-xs font-normal text-muted-foreground">
            {user.email}
          </span>
        </DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuItem onSelect={() => void signOut()}>
          <LogOut className="mr-2 size-4" />
          {t('nav.signOut')}
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
