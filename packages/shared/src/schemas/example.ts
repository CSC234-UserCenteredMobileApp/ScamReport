import { Type, type Static } from '@sinclair/typebox';

export const ExampleItem = Type.Object({
  id: Type.String(),
  name: Type.String(),
});
export type ExampleItem = Static<typeof ExampleItem>;

export const ExampleListResponse = Type.Object({
  items: Type.Array(ExampleItem),
});
export type ExampleListResponse = Static<typeof ExampleListResponse>;
