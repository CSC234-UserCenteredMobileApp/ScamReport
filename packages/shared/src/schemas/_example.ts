import { Type, type Static } from '@sinclair/typebox';

export const HealthResponse = Type.Object({
  ok: Type.Boolean(),
});

export type HealthResponse = Static<typeof HealthResponse>;
