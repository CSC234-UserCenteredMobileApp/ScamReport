import { Database, Flag, ScanLine, Users } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { KpiTile } from '@/components/kpi-tile';
import { useFormat } from '@/lib/format';
import { useScamOverview } from '../api/scam-overview';
import { BarList, type BarListRow } from './bar-list';
import { Sparkline } from './sparkline';

function pickLang(language: string): 'th' | 'en' {
  return language.startsWith('th') ? 'th' : 'en';
}

export function ScamOverviewSection() {
  const { t, i18n } = useTranslation();
  const lang = pickLang(i18n.language);
  const fmt = useFormat();
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
          value={fmt.number(data.totalReports)}
          tone="primary"
        />
        <KpiTile
          icon={ScanLine}
          label={t('scamOverview.totalScammers')}
          value={fmt.number(data.totalScammers)}
          tone="alert"
        />
        <KpiTile
          icon={Users}
          label={t('scamOverview.totalPersons')}
          value={fmt.number(data.totalPersons)}
          tone="info"
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
            <BarList
              rows={scamTypeRows}
              emptyLabel={t('scamOverview.noData')}
              ariaLabel={t('scamOverview.byScamType')}
            />
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
            <BarList
              rows={sourceSiteRows}
              emptyLabel={t('scamOverview.noData')}
              ariaLabel={t('scamOverview.bySourceSite')}
            />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              {t('scamOverview.byProvince')}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <BarList
              rows={provinceRows}
              emptyLabel={t('scamOverview.noData')}
              ariaLabel={t('scamOverview.byProvince')}
            />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              {t('scamOverview.byNationality')}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <BarList
              rows={nationalityRows}
              emptyLabel={t('scamOverview.noData')}
              ariaLabel={t('scamOverview.byNationality')}
            />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              {t('scamOverview.byArrestStatus')}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <BarList
              rows={arrestRows}
              emptyLabel={t('scamOverview.noData')}
              ariaLabel={t('scamOverview.byArrestStatus')}
            />
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
            <Sparkline
              daily={data.dailyReports}
              title={t('scamOverview.daily')}
            />
          </CardContent>
        </Card>
      </div>

      <p className="flex items-center justify-end gap-1 text-xs text-muted-foreground">
        <Database className="size-3" aria-hidden="true" />
        {t('scamOverview.footer', {
          generatedAt: fmt.dateTime(data.generatedAt),
        })}
      </p>
    </section>
  );
}
