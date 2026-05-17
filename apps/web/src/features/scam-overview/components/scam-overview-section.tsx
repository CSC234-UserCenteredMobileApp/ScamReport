import { Database, Flag, ScanLine, Users } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { useScamOverview } from '../api/scam-overview';
import { BarList, type BarListRow } from './bar-list';
import { Sparkline } from './sparkline';

function pickLang(language: string): 'th' | 'en' {
  return language.startsWith('th') ? 'th' : 'en';
}

function KpiTile({
  icon: Icon,
  label,
  value,
  tone,
}: {
  icon: React.ComponentType<{ className?: string }>;
  label: string;
  value: number;
  tone: string;
}) {
  return (
    <Card>
      <CardContent className="flex items-center gap-4 p-5">
        <div className={`rounded-lg p-2 ${tone}`}>
          <Icon className="size-5" />
        </div>
        <div>
          <p className="text-xs uppercase tracking-wide text-muted-foreground">
            {label}
          </p>
          <p className="text-2xl font-bold tabular-nums">{value}</p>
        </div>
      </CardContent>
    </Card>
  );
}

export function ScamOverviewSection() {
  const { t, i18n } = useTranslation();
  const lang = pickLang(i18n.language);
  const { data, isLoading, isError } = useScamOverview();

  if (isLoading) {
    return (
      <section>
        <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-muted-foreground">
          {t('scamOverview.title')}
        </h2>
        <p className="text-sm text-muted-foreground">{t('common.loading')}</p>
      </section>
    );
  }
  if (isError || !data) {
    return (
      <section>
        <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-muted-foreground">
          {t('scamOverview.title')}
        </h2>
        <p className="text-sm text-destructive">{t('scamOverview.loadError')}</p>
      </section>
    );
  }

  const scamTypeRows: BarListRow[] = data.byScamType.map((r) => ({
    key: r.code,
    primaryLabel: lang === 'th' ? r.labelTh : r.labelEn,
    secondaryLabel: lang === 'th' ? r.labelEn : r.labelTh,
    count: r.count,
  }));
  const sourceSiteRows: BarListRow[] = data.bySourceSite.map((r) => ({
    key: r.site,
    primaryLabel: r.site,
    count: r.count,
  }));
  const provinceRows: BarListRow[] = data.byProvince.map((r) => ({
    key: `${r.thai}|${r.english}`,
    primaryLabel: lang === 'th' ? r.thai : r.english,
    secondaryLabel: lang === 'th' ? r.english : r.thai,
    count: r.count,
  }));
  const nationalityRows: BarListRow[] = data.byNationality.map((r) => ({
    key: `${r.english}|${r.thai}`,
    primaryLabel: lang === 'th' ? r.thai : r.english,
    secondaryLabel: lang === 'th' ? r.english : r.thai,
    count: r.count,
  }));
  const arrestRows: BarListRow[] = data.byArrestStatus.map((r) => ({
    key: r.code,
    primaryLabel: lang === 'th' ? r.labelTh : r.labelEn,
    secondaryLabel: lang === 'th' ? r.labelEn : r.labelTh,
    count: r.count,
  }));

  return (
    <section className="space-y-4">
      <h2 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">
        {t('scamOverview.title')}
      </h2>

      <div className="grid gap-4 sm:grid-cols-3">
        <KpiTile
          icon={Flag}
          label={t('scamOverview.totalReports')}
          value={data.totalReports}
          tone="bg-primary/10 text-primary"
        />
        <KpiTile
          icon={ScanLine}
          label={t('scamOverview.totalScammers')}
          value={data.totalScammers}
          tone="bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400"
        />
        <KpiTile
          icon={Users}
          label={t('scamOverview.totalPersons')}
          value={data.totalPersons}
          tone="bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400"
        />
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              {t('scamOverview.byScamType')}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <BarList rows={scamTypeRows} emptyLabel={t('scamOverview.noData')} />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              {t('scamOverview.bySourceSite')}
            </CardTitle>
            <p className="text-xs text-muted-foreground">
              {t('scamOverview.sourceNote')}
            </p>
          </CardHeader>
          <CardContent>
            <BarList rows={sourceSiteRows} emptyLabel={t('scamOverview.noData')} />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              {t('scamOverview.byProvince')}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <BarList rows={provinceRows} emptyLabel={t('scamOverview.noData')} />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              {t('scamOverview.byNationality')}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <BarList rows={nationalityRows} emptyLabel={t('scamOverview.noData')} />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              {t('scamOverview.byArrestStatus')}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <BarList rows={arrestRows} emptyLabel={t('scamOverview.noData')} />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              {t('scamOverview.daily')}
            </CardTitle>
            <p className="text-xs text-muted-foreground">
              {t('scamOverview.dailyNote')}
            </p>
          </CardHeader>
          <CardContent>
            <Sparkline daily={data.dailyReports} />
          </CardContent>
        </Card>
      </div>

      <p className="flex items-center justify-end gap-1 text-xs text-muted-foreground">
        <Database className="size-3" />
        {t('scamOverview.footer', { generatedAt: new Date(data.generatedAt).toLocaleString() })}
      </p>
    </section>
  );
}
