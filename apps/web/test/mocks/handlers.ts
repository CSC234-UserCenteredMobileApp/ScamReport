import { http, HttpResponse } from 'msw';
import type {
  AdminEvidenceUrlResponse,
  AdminQueueItem,
  AdminQueueResponse,
  AdminReportDetail,
  AdminReportDetailResponse,
  AuthSyncResponse,
} from '@my-product/shared';

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

export const sampleDetail: AdminReportDetail = {
  id: '11111111-1111-1111-1111-111111111111',
  title: 'Fake parcel SMS',
  description:
    'I received an SMS claiming a parcel was held for clearance fees. The link looked suspicious.',
  scamTypeCode: 'phishing_sms',
  scamTypeLabelEn: 'Phishing SMS',
  scamTypeLabelTh: 'ฟิชชิ่ง SMS',
  submittedAt: new Date(Date.now() - 12 * 3_600_000).toISOString(),
  status: 'pending',
  priorityFlag: false,
  targetIdentifier: '0812345678',
  targetIdentifierKind: 'phone',
  evidenceFiles: [
    {
      id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      storagePath: 'evidence/admin/sample.jpg',
      kind: 'image',
      mimeType: 'image/jpeg',
      sizeBytes: 24_576,
    },
    {
      id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      storagePath: 'evidence/admin/sample.pdf',
      kind: 'pdf',
      mimeType: 'application/pdf',
      sizeBytes: 65_536,
    },
  ],
  duplicateCount: 0,
  aiScore: 78,
  aiConfidence: 'high',
  auditTrail: [
    {
      adminId: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
      action: 'flag',
      remark: 'Need a second pair of eyes on this one.',
      createdAt: new Date(Date.now() - 2 * 3_600_000).toISOString(),
    },
  ],
};

export const sampleDetailResponse: AdminReportDetailResponse = { report: sampleDetail };

export const sampleEvidenceUrlResponse: AdminEvidenceUrlResponse = {
  url: 'https://signed.example/evidence/sample.jpg?token=mock',
  expiresAt: new Date(Date.now() + 3_600_000).toISOString(),
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
  http.get(`${BASE}/admin/reports/:id`, () => HttpResponse.json(sampleDetailResponse)),
  http.get(`${BASE}/admin/reports/:id/evidence/:fileId/url`, () =>
    HttpResponse.json(sampleEvidenceUrlResponse),
  ),
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
