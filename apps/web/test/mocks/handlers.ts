import { http, HttpResponse } from 'msw';
import type {
  AdminAnnouncementDetail,
  AdminAnnouncementDetailResponse,
  AdminAnnouncementListItem,
  AdminAnnouncementListResponse,
  AdminEvidenceUrlResponse,
  AdminQueueItem,
  AdminQueueResponse,
  AdminReportDetail,
  AdminReportDetailResponse,
  AdminReportSearchResponse,
  AuthSyncResponse,
  ScamTypeListResponse,
  SubscriberCountResponse,
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

export const sampleMediumScore: AdminQueueItem = {
  ...sampleItem,
  id: '33333333-3333-3333-3333-333333333333',
  title: 'Medium confidence report',
  aiScore: 55,
  aiConfidence: 'medium',
};

export const sampleLowScore: AdminQueueItem = {
  ...sampleItem,
  id: '44444444-4444-4444-4444-444444444444',
  title: 'Low confidence report',
  aiScore: 22,
  aiConfidence: 'low',
};

export const sampleScamTypes: ScamTypeListResponse = {
  items: [
    { code: 'phishing_sms', labelEn: 'Phishing SMS', labelTh: 'ฟิชชิ่ง SMS', displayOrder: 1 },
    { code: 'investment_fraud', labelEn: 'Investment Fraud', labelTh: 'หลอกลวงลงทุน', displayOrder: 2 },
  ],
};

export const sampleSearchResponse: AdminReportSearchResponse = {
  items: [
    {
      id: sampleItem.id,
      title: sampleItem.title,
      status: sampleItem.status,
      scamTypeCode: sampleItem.scamTypeCode,
      scamTypeLabelEn: sampleItem.scamTypeLabelEn,
      scamTypeLabelTh: sampleItem.scamTypeLabelTh,
      targetIdentifier: '0812345678',
      submittedAt: sampleItem.submittedAt,
      aiScore: sampleItem.aiScore,
    },
  ],
  total: 1,
};

export const sampleQueue: AdminQueueResponse = {
  items: [sampleItem, sampleFlagged],
  pendingCount: 1,
  flaggedCount: 1,
  total: 2,
  page: 1,
  pageSize: 25,
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
      signedUrl: null,
    },
    {
      id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      storagePath: 'evidence/admin/sample.pdf',
      kind: 'pdf',
      mimeType: 'application/pdf',
      sizeBytes: 65_536,
      signedUrl: null,
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
  suspectedNameAtSubmit: null,
  scammer: null,
  siblingCases: [],
  relatedCases: [],
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

export const sampleAnnouncementDraft: AdminAnnouncementDetail = {
  id: '33333333-3333-3333-3333-333333333333',
  slug: 'draft-launch-tips-abc',
  title: 'Launch tips draft',
  body: 'Walkthrough of the new app onboarding.',
  category: 'tips',
  status: 'draft',
  createdAt: new Date(Date.now() - 2 * 3_600_000).toISOString(),
  updatedAt: new Date(Date.now() - 1 * 3_600_000).toISOString(),
  publishedAt: null,
  pushedToFcmAt: null,
  authorId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  attachments: [],
};

export const samplePublishedAnnouncement: AdminAnnouncementDetail = {
  ...sampleAnnouncementDraft,
  id: '44444444-4444-4444-4444-444444444444',
  slug: 'fraud-alert-published-abc',
  title: 'Published fraud alert',
  status: 'published',
  publishedAt: new Date().toISOString(),
  pushedToFcmAt: new Date().toISOString(),
};

export const sampleAnnouncementList: AdminAnnouncementListResponse = {
  items: [sampleAnnouncementDraft, samplePublishedAnnouncement].map(
    (it): AdminAnnouncementListItem => ({
      id: it.id,
      slug: it.slug,
      title: it.title,
      category: it.category,
      status: it.status,
      createdAt: it.createdAt,
      publishedAt: it.publishedAt,
    }),
  ),
};

export const sampleSubscriberCount: SubscriberCountResponse = { count: 42 };

export const handlers = [
  http.post(`${BASE}/auth/sync`, () => HttpResponse.json(adminSyncResponse)),
  http.get(`${BASE}/admin/announcements`, () =>
    HttpResponse.json(sampleAnnouncementList),
  ),
  http.get(`${BASE}/admin/announcements/:id`, ({ params }) => {
    const id = params.id as string;
    if (id === samplePublishedAnnouncement.id) {
      return HttpResponse.json<AdminAnnouncementDetailResponse>({
        item: samplePublishedAnnouncement,
      });
    }
    return HttpResponse.json<AdminAnnouncementDetailResponse>({
      item: sampleAnnouncementDraft,
    });
  }),
  http.post(`${BASE}/admin/announcements`, () =>
    HttpResponse.json<AdminAnnouncementDetailResponse>({
      item: sampleAnnouncementDraft,
    }),
  ),
  http.put(`${BASE}/admin/announcements/:id`, () =>
    HttpResponse.json<AdminAnnouncementDetailResponse>({
      item: sampleAnnouncementDraft,
    }),
  ),
  http.delete(`${BASE}/admin/announcements/:id`, ({ params }) =>
    HttpResponse.json({
      id: params.id as string,
      status: 'deleted',
      updatedAt: new Date().toISOString(),
    }),
  ),
  http.post(`${BASE}/admin/announcements/:id/publish`, ({ params }) =>
    HttpResponse.json<AdminAnnouncementDetailResponse>({
      item: {
        ...samplePublishedAnnouncement,
        id: params.id as string,
      },
    }),
  ),
  http.post(`${BASE}/admin/announcements/:id/unpublish`, ({ params }) =>
    HttpResponse.json({
      id: params.id as string,
      status: 'unpublished',
      updatedAt: new Date().toISOString(),
    }),
  ),
  http.get(`${BASE}/admin/notifications/subscribers/count`, () =>
    HttpResponse.json(sampleSubscriberCount),
  ),
  http.get(`${BASE}/scam-types`, () => HttpResponse.json(sampleScamTypes)),
  http.get(`${BASE}/admin/reports/search`, ({ request }) => {
    const url = new URL(request.url);
    const q = url.searchParams.get('q') ?? '';
    const filtered = sampleSearchResponse.items.filter((it) =>
      it.title.toLowerCase().includes(q.toLowerCase()),
    );
    return HttpResponse.json<AdminReportSearchResponse>({ items: filtered, total: filtered.length });
  }),
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
