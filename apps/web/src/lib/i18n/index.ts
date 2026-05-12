import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';

import enCommon from '@/i18n/en/common.json';
import enModeration from '@/i18n/en/moderation.json';
import enAnnouncements from '@/i18n/en/announcements.json';
import thCommon from '@/i18n/th/common.json';
import thModeration from '@/i18n/th/moderation.json';
import thAnnouncements from '@/i18n/th/announcements.json';

export const SUPPORTED_LANGS = ['th', 'en'] as const;
export type SupportedLang = (typeof SUPPORTED_LANGS)[number];

void i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    fallbackLng: 'en',
    supportedLngs: SUPPORTED_LANGS as unknown as string[],
    defaultNS: 'common',
    ns: ['common', 'moderation', 'announcements'],
    resources: {
      en: {
        common: enCommon,
        moderation: enModeration,
        announcements: enAnnouncements,
      },
      th: {
        common: thCommon,
        moderation: thModeration,
        announcements: thAnnouncements,
      },
    },
    detection: {
      order: ['localStorage', 'navigator'],
      caches: ['localStorage'],
      lookupLocalStorage: 'scamreport-admin-lang',
    },
    interpolation: { escapeValue: false },
  });

export default i18n;
