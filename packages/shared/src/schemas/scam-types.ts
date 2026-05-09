import { Type, type Static } from '@sinclair/typebox';

export const ScamTypeItem = Type.Object({
  code: Type.String(),
  labelEn: Type.String(),
  labelTh: Type.String(),
  displayOrder: Type.Integer(),
});
export type ScamTypeItem = Static<typeof ScamTypeItem>;

export const ScamTypeListResponse = Type.Object({
  items: Type.Array(ScamTypeItem),
});
export type ScamTypeListResponse = Static<typeof ScamTypeListResponse>;
