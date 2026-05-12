import { Moon, Sun } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { Button } from '@/components/ui/button';
import { useTheme } from '@/app/theme-provider';

export function ThemeToggle() {
  const { t } = useTranslation();
  const { theme, toggleTheme } = useTheme();
  const isDark = theme === 'dark';
  return (
    <Button
      variant="ghost"
      size="icon"
      onClick={toggleTheme}
      aria-label={isDark ? t('common.lightMode') : t('common.darkMode')}
    >
      {isDark ? <Sun /> : <Moon />}
    </Button>
  );
}
