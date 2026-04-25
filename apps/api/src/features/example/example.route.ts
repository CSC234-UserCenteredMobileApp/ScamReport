import { Elysia } from 'elysia';
import { ExampleListResponse } from '@my-product/shared';

const ITEMS = [
  { id: '1', name: 'First example' },
  { id: '2', name: 'Second example' },
  { id: '3', name: 'Third example' },
];

export const exampleRoute = new Elysia().get(
  '/examples',
  () => ({ items: ITEMS }),
  { response: ExampleListResponse },
);
