import { FormatRegistry, type TSchema } from '@sinclair/typebox';
import { TypeCompiler, type TypeCheck } from '@sinclair/typebox/compiler';
import {
  AdminQueueResponse,
  AdminReportDetailResponse,
  AdminReportSearchResponse,
  AdminEvidenceUrlResponse,
  AdminActionResponse,
  AdminAnnouncementListResponse,
  AdminAnnouncementDetailResponse,
  AdminAnnouncementActionResponse,
  AdminAnnouncementAttachmentResponse,
  SubscriberCountResponse,
  AuthSyncResponse,
  LinkScammerResponse,
  PersonDossierResponse,
  PlatformSummaryResponse,
  ScammerDossierResponse,
  ScamTypeListResponse,
  SearchScammersResponse,
  AdminAiEvalLatestResponse,
  AdminAiEvalHistoryResponse,
  AdminScamOverviewResponse,
} from '@my-product/shared';

// Register the JSON-Schema formats our admin payloads use.
// TypeBox ships zero format validators by default; without these, every
// compiled checker would reject any field annotated `format: 'uuid' | 'date-time'`.
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const DATETIME_RE =
  /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:?\d{2})$/;

if (!FormatRegistry.Has('uuid')) {
  FormatRegistry.Set('uuid', (v) => UUID_RE.test(v));
}
if (!FormatRegistry.Has('date-time')) {
  FormatRegistry.Set('date-time', (v) => DATETIME_RE.test(v));
}
// Loose URI check — admin evidence URLs are Supabase-signed and always
// `https://...`. The schema only needs to confirm "looks like a URL", not
// RFC-3986 perfection.
if (!FormatRegistry.Has('uri')) {
  FormatRegistry.Set('uri', (v) => {
    try {
      new URL(v);
      return true;
    } catch {
      return false;
    }
  });
}

export const validators = {
  adminQueue: TypeCompiler.Compile(AdminQueueResponse),
  adminReportDetail: TypeCompiler.Compile(AdminReportDetailResponse),
  adminEvidenceUrl: TypeCompiler.Compile(AdminEvidenceUrlResponse),
  adminAction: TypeCompiler.Compile(AdminActionResponse),
  adminAnnouncementList: TypeCompiler.Compile(AdminAnnouncementListResponse),
  adminAnnouncementDetail: TypeCompiler.Compile(AdminAnnouncementDetailResponse),
  adminAnnouncementAction: TypeCompiler.Compile(AdminAnnouncementActionResponse),
  adminAnnouncementAttachment: TypeCompiler.Compile(AdminAnnouncementAttachmentResponse),
  subscriberCount: TypeCompiler.Compile(SubscriberCountResponse),
  authSync: TypeCompiler.Compile(AuthSyncResponse),
  scammerDossier: TypeCompiler.Compile(ScammerDossierResponse),
  scammerSearch: TypeCompiler.Compile(SearchScammersResponse),
  personDossier: TypeCompiler.Compile(PersonDossierResponse),
  linkScammer: TypeCompiler.Compile(LinkScammerResponse),
  platformSummary: TypeCompiler.Compile(PlatformSummaryResponse),
  scamTypes: TypeCompiler.Compile(ScamTypeListResponse),
  adminReportSearch: TypeCompiler.Compile(AdminReportSearchResponse),
  aiEvalLatest: TypeCompiler.Compile(AdminAiEvalLatestResponse),
  aiEvalHistory: TypeCompiler.Compile(AdminAiEvalHistoryResponse),
  scamOverview: TypeCompiler.Compile(AdminScamOverviewResponse),
} as const;

export type Validators = typeof validators;
export type ValidatorKey = keyof Validators;
export type TypeCheckFor<S extends TSchema> = TypeCheck<S>;
