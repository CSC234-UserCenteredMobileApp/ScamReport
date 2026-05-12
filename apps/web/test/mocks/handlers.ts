import { http, HttpResponse } from 'msw';
import type { AdminQueueItem, AdminQueueResponse, AuthSyncResponse } from '@my-product/shared';

const BASE = '*';

export const sampleItem: AdminQueueItem = {
  id: '11111111-1111-1111-1111-111111111111',
  title: 'Fake parcel SMS',
  scamTypeCode: 'phishing_sms',
  scamTypeLabelEn: 'Phishing SMS',
  scamTypeLabelTh: 'ฟิชชิ่ง SMS',
  submittedAt: new Date(Date.now() - 12 * 3_600_000).toISOString(),
  status: 'pending',
  priorityFlag: false,
  evidenceCount: 2,
  lastRemarkByAdmin: null,
  aiScore: 78,
  aiConfidence: 'high',
};

export const sampleFlagged: AdminQueueItem = {
  ...sampleItem,
  id: '22222222-2222-2222-2222-222222222222',
  title: 'Suspicious investment scheme',
  status: 'flagged',
  priorityFlag: true,
  aiScore: null,
  aiConfidence: null,
};

export const sampleQueue: AdminQueueResponse = {
  items: [sampleItem, sampleFlagged],
  pendingCount: 1,
  flaggedCount: 1,
};

export const adminSyncResponse: AuthSyncResponse = {
  user: {
    id: '99999999-9999-9999-9999-999999999999',
    firebaseUid: 'firebase-admin-uid',
    email: 'admin@example.com',
    displayName: 'Admin User',
    role: 'admin',
    preferredLanguage: 'en',
  },
};

export const userSyncResponse: AuthSyncResponse = {
  ...adminSyncResponse,
  user: { ...adminSyncResponse.user, role: 'user', email: 'regular@example.com' },
};

export const handlers = [
  http.post(`${BASE}/auth/sync`, () => HttpResponse.json(adminSyncResponse)),
  http.get(`${BASE}/admin/reports/queue`, () => HttpResponse.json(sampleQueue)),
  http.post(`${BASE}/admin/reports/:id/approve`, ({ params }) =>
    HttpResponse.json({
      id: params.id as string,
      status: 'verified',
      updatedAt: new Date().toISOString(),
    }),
  ),
  http.post(`${BASE}/admin/reports/:id/reject`, ({ params }) =>
    HttpResponse.json({
      id: params.id as string,
      status: 'rejected',
      updatedAt: new Date().toISOString(),
    }),
  ),
  http.post(`${BASE}/admin/reports/:id/flag`, ({ params }) =>
    HttpResponse.json({
      id: params.id as string,
      status: 'flagged',
      updatedAt: new Date().toISOString(),
    }),
  ),
  http.post(`${BASE}/admin/reports/:id/unflag`, ({ params }) =>
    HttpResponse.json({
      id: params.id as string,
      status: 'pending',
      updatedAt: new Date().toISOString(),
    }),
  ),
];
