import { useTranslation } from 'react-i18next';
import type { ScamTypeItem } from '@my-product/shared';
import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Separator } from '@/components/ui/separator';
import type { QueueSearch } from '@/features/moderation/pages/queue-page';

interface Props {
  search: QueueSearch;
  scamTypes: ScamTypeItem[];
  onChange: (updates: Partial<QueueSearch>) => void;
}

export function QueueFiltersPopover({ search, scamTypes, onChange }: Props) {
  const { t, i18n } = useTranslation('moderation');

  return (
    <div className="space-y-4 p-1">
      <div className="space-y-1.5">
        <Label className="text-xs text-muted-foreground">
          {t('filter.statusLabel')}
        </Label>
        <Select
          value={search.status ?? 'all'}
          onValueChange={(v) =>
            onChange({ status: v as QueueSearch['status'] })
          }
        >
          <SelectTrigger className="h-9">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">{t('filter.statusAll')}</SelectItem>
            <SelectItem value="pending">{t('status.pending')}</SelectItem>
            <SelectItem value="flagged">{t('status.flagged')}</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div className="flex items-center gap-2">
        <Checkbox
          id="priority-only"
          checked={search.priority === 'true'}
          onCheckedChange={(c) =>
            onChange({ priority: c === true ? 'true' : undefined })
          }
        />
        <Label
          htmlFor="priority-only"
          className="cursor-pointer text-sm font-normal"
        >
          {t('filter.priorityOnly')}
        </Label>
      </div>

      <div className="space-y-1.5">
        <Label className="text-xs text-muted-foreground">
          {t('filter.confidenceLabel')}
        </Label>
        <Select
          value={search.confidence ?? 'all'}
          onValueChange={(v) =>
            onChange({ confidence: v as QueueSearch['confidence'] })
          }
        >
          <SelectTrigger className="h-9">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">{t('filter.confidenceAll')}</SelectItem>
            <SelectItem value="high">{t('filter.confidenceHigh')}</SelectItem>
            <SelectItem value="medium">{t('filter.confidenceMedium')}</SelectItem>
            <SelectItem value="low">{t('filter.confidenceLow')}</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div className="space-y-1.5">
        <Label className="text-xs text-muted-foreground">
          {t('filter.typeLabel')}
        </Label>
        <Select
          value={search.scam_type ?? 'all'}
          onValueChange={(v) =>
            onChange({ scam_type: v === 'all' ? undefined : v })
          }
        >
          <SelectTrigger className="h-9">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">{t('filter.scamTypeAll')}</SelectItem>
            {scamTypes.map((st) => (
              <SelectItem key={st.code} value={st.code}>
                {i18n.language === 'th' ? st.labelTh : st.labelEn}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <Separator />

      <div className="flex justify-end">
        <Button
          variant="ghost"
          size="sm"
          onClick={() =>
            onChange({
              status: undefined,
              priority: undefined,
              confidence: undefined,
              scam_type: undefined,
            })
          }
        >
          {t('filter.reset')}
        </Button>
      </div>
    </div>
  );
}
