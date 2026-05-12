import { FormatRegistry, type TSchema } from '@sinclair/typebox';
import { TypeCompiler, type TypeCheck } from '@sinclair/typebox/compiler';
import {
  AdminQueueResponse,
  AdminReportDetailResponse,
  AdminActionResponse,
  AuthSyncResponse,
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

export const validators = {
  adminQueue: TypeCompiler.Compile(AdminQueueResponse),
  adminReportDetail: TypeCompiler.Compile(AdminReportDetailResponse),
  adminAction: TypeCompiler.Compile(AdminActionResponse),
  authSync: TypeCompiler.Compile(AuthSyncResponse),
} as const;

export type Validators = typeof validators;
export type ValidatorKey = keyof Validators;
export type TypeCheckFor<S extends TSchema> = TypeCheck<S>;
