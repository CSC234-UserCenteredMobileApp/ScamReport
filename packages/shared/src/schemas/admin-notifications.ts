import { Type, type Static } from '@sinclair/typebox';

export const SubscriberCountResponse = Type.Object({
  count: Type.Integer({ minimum: 0 }),
});
export type SubscriberCountResponse = Static<typeof SubscriberCountResponse>;
