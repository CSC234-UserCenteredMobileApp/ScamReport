import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
    strictPort: true,
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./test/setup.ts'],
    css: false,
    env: {
      // Dummy values for unit tests only — Firebase getAuth() asserts apiKey is non-empty.
      // Real dev/prod values come from apps/web/.env.local (gitignored) and Vercel env vars.
      VITE_API_BASE_URL: 'http://localhost:3000',
      VITE_FIREBASE_API_KEY: 'AIzaSyTestKey0000000000000000000000000',
      VITE_FIREBASE_AUTH_DOMAIN: 'scamreport-test.firebaseapp.com',
      VITE_FIREBASE_PROJECT_ID: 'scamreport-test',
      VITE_FIREBASE_APP_ID: '1:000000000000:web:0000000000000000000000',
    },
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'json-summary'],
      thresholds: {
        lines: 80,
        statements: 80,
        functions: 70,
        branches: 70,
      },
      include: ['src/**/*.{ts,tsx}'],
      exclude: [
        // shadcn UI primitives — restyled via theme tokens, not unit tested here.
        'src/components/ui/**',
        // Composition shells — exercised by integration / e2e, not unit tests.
        'src/App.tsx',
        'src/main.tsx',
        'src/app/**',
        'src/components/app-shell.tsx',
        'src/components/sidebar.tsx',
        'src/components/topbar.tsx',
        'src/components/language-switch.tsx',
        'src/components/theme-toggle.tsx',
        'src/components/user-pill.tsx',
        // Routes that are placeholders or auth screens (Firebase-driven).
        'src/routes/login.tsx',
        'src/routes/no-access.tsx',
        'src/routes/dashboard-layout.tsx',
        'src/routes/announcements/**',
        // Composition shells — exercised by integration / e2e, not unit tests.
        'src/components/breadcrumb.tsx',
        'src/components/global-search.tsx',
        // Search hook is only consumed by global-search (above); no unit test needed.
        'src/features/moderation/api/search.ts',
        // Route shims — thin wrappers around feature pages, exercised by
        // integration / e2e. The feature page implementations cover the logic.
        'src/routes/dashboard.tsx',
        'src/routes/moderation/**',
        'src/routes/scammers/**',
        'src/routes/persons/**',
        'src/routes/platform-summary.tsx',
        'src/routes/ai-eval.tsx',
        'src/routes/deletion-requests.tsx',
        // Feature pages with no logic beyond passing data to JSX. Coverage
        // comes from the feature components + api hooks that they compose.
        'src/features/dashboard/pages/**',
        'src/features/scammers/pages/**',
        'src/features/persons/pages/**',
        'src/features/platform-summary/pages/**',
        'src/features/ai-eval/pages/**',
        // Generated / static.
        'src/i18n/**',
        'src/lib/i18n/**',
        'src/styles/**',
        'src/vite-env.d.ts',
        '**/*.d.ts',
        '**/index.ts',
      ],
    },
  },
});
