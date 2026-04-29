import { Type, type Static } from '@sinclair/typebox';

export const HomeStats = Type.Object({
  verifiedTotal: Type.Integer({ minimum: 0 }),
  newThisWeek: Type.Integer({ minimum: 0 }),
  topScamType: Type.String(),
});
export type HomeStats = Static<typeof HomeStats>;

export const HomeStatsResponse = Type.Object({ data: HomeStats });
export type HomeStatsResponse = Static<typeof HomeStatsResponse>;
