import { Navigate, createBrowserRouter } from 'react-router-dom';
import { LoginPage } from '@/routes/login';
import { NoAccessPage } from '@/routes/no-access';
import { DashboardLayout } from '@/routes/dashboard-layout';
import QueuePage from '@/routes/moderation/queue';
import ModerationDetailPage from '@/routes/moderation/detail';
import AnnouncementsListPage from '@/routes/announcements/list';
import AnnouncementsNewPage from '@/routes/announcements/new';
import AnnouncementsEditPage from '@/routes/announcements/edit';
import DeletionRequestsPage from '@/routes/deletion-requests';
import ScammerDossierRoute from '@/routes/scammers/dossier';
import PersonDossierRoute from '@/routes/persons/dossier';
import PlatformSummaryRoute from '@/routes/platform-summary';
import AiEvalRoute from '@/routes/ai-eval';

export const router = createBrowserRouter([
  { path: '/login', element: <LoginPage /> },
  { path: '/no-access', element: <NoAccessPage /> },
  {
    element: <DashboardLayout />,
    children: [
      { index: true, element: <Navigate to="/moderation" replace /> },
      { path: 'moderation', element: <QueuePage /> },
      { path: 'moderation/:id', element: <ModerationDetailPage /> },
      { path: 'announcements', element: <AnnouncementsListPage /> },
      { path: 'announcements/new', element: <AnnouncementsNewPage /> },
      { path: 'announcements/:id/edit', element: <AnnouncementsEditPage /> },
      { path: 'deletion-requests', element: <DeletionRequestsPage /> },
      { path: 'scammers/:id/dossier', element: <ScammerDossierRoute /> },
      { path: 'persons/:id/dossier', element: <PersonDossierRoute /> },
      { path: 'platform-summary', element: <PlatformSummaryRoute /> },
      { path: 'ai-eval', element: <AiEvalRoute /> },
    ],
  },
  { path: '*', element: <Navigate to="/" replace /> },
]);
