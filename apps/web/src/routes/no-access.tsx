import { ShieldAlert } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { useAuth } from '@/lib/auth/auth-context';

export function NoAccessPage() {
  const { t } = useTranslation();
  const { signOut } = useAuth();
  return (
    <div className="flex min-h-full items-center justify-center bg-background p-6">
      <Card className="w-full max-w-md">
        <CardHeader>
          <div className="mb-2 flex size-12 items-center justify-center rounded-full bg-destructive/10 text-destructive">
            <ShieldAlert />
          </div>
          <CardTitle>{t('auth.noAccessTitle')}</CardTitle>
          <CardDescription>{t('auth.noAccessBody')}</CardDescription>
        </CardHeader>
        <CardContent>
          <Button className="w-full" onClick={() => void signOut()}>
            {t('nav.signOut')}
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
