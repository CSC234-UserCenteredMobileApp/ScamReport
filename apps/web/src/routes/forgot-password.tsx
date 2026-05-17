import { zodResolver } from '@hookform/resolvers/zod';
import { sendPasswordResetEmail } from 'firebase/auth';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { z } from 'zod';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { LanguageSwitch } from '@/components/language-switch';
import { ThemeToggle } from '@/components/theme-toggle';
import { firebaseAuth } from '@/lib/auth/firebase';

const forgotSchema = z.object({
  email: z.string().email(),
});
type ForgotFormValues = z.infer<typeof forgotSchema>;

export function ForgotPasswordPage() {
  const { t } = useTranslation();
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [sentTo, setSentTo] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<ForgotFormValues>({ resolver: zodResolver(forgotSchema) });

  const onSubmit = async (values: ForgotFormValues) => {
    setSubmitting(true);
    setError(null);
    try {
      await sendPasswordResetEmail(firebaseAuth, values.email);
      setSentTo(values.email);
    } catch (err) {
      const code = (err as { code?: string }).code ?? '';
      if (code.includes('user-not-found')) {
        setSentTo(values.email);
      } else if (code.includes('invalid-email')) {
        setError(t('auth.errorInvalid'));
      } else {
        setError(t('auth.errorGeneric'));
      }
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="flex min-h-full items-center justify-center bg-background p-6">
      <div className="absolute right-4 top-4 flex items-center gap-1">
        <LanguageSwitch />
        <ThemeToggle />
      </div>
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>{t('auth.forgotTitle')}</CardTitle>
          <CardDescription>
            {sentTo ? t('auth.forgotSent') : t('auth.forgotSubtitle')}
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {sentTo ? (
            <div className="space-y-4">
              <p className="text-sm text-muted-foreground">
                {t('auth.forgotSentBody', { email: sentTo })}
              </p>
              <Button asChild variant="outline" className="w-full">
                <Link to="/login">{t('auth.backToSignIn')}</Link>
              </Button>
            </div>
          ) : (
            <>
              {error && (
                <Alert variant="destructive">
                  <AlertDescription>{error}</AlertDescription>
                </Alert>
              )}
              <form
                onSubmit={handleSubmit(onSubmit)}
                noValidate
                className="space-y-3"
                aria-label="forgot password"
              >
                <div className="space-y-1.5">
                  <Label htmlFor="email">{t('auth.email')}</Label>
                  <Input
                    id="email"
                    type="email"
                    autoComplete="email"
                    aria-invalid={errors.email ? 'true' : undefined}
                    {...register('email')}
                  />
                </div>
                <Button type="submit" className="w-full" disabled={submitting}>
                  {t('auth.forgotSubmit')}
                </Button>
              </form>
              <div className="text-center text-sm">
                <Link to="/login" className="text-primary hover:underline">
                  {t('auth.backToSignIn')}
                </Link>
              </div>
            </>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
