import { useTranslation } from 'react-i18next';
import { Languages } from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';

const LANGS: { code: 'th' | 'en'; label: string }[] = [
  { code: 'th', label: 'ไทย' },
  { code: 'en', label: 'English' },
];

export function LanguageSwitch() {
  const { t, i18n } = useTranslation();
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon" aria-label={t('common.language')}>
          <Languages />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuLabel>{t('common.language')}</DropdownMenuLabel>
        <DropdownMenuSeparator />
        {LANGS.map((lang) => (
          <DropdownMenuItem
            key={lang.code}
            onSelect={() => void i18n.changeLanguage(lang.code)}
            aria-current={i18n.language === lang.code}
            className={i18n.language === lang.code ? 'font-semibold' : undefined}
          >
            {lang.label}
          </DropdownMenuItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
