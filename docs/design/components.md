# Component catalogue

Reusable widgets used across screens. Each entry: source path (or "to build") + 1-line usage. When implementing a screen, prefer extending an existing widget over inventing a new one.

Tokens always come from `apps/mobile/lib/core/theme/app_theme.dart` (`ColorScheme`, `VerdictPalette` extension). Spacing: 8 / 16 / 24 px. Radii: `--r-sm 8 / md 12 / lg 16 / xl 24 / full 999` (already in theme).

## Already built

| Widget | Source | Usage |
| --- | --- | --- |
| `AuthScaffold` | `apps/mobile/lib/features/auth/presentation/_auth_scaffold.dart` | Scrollable scaffold with brand pill + wordmark + tagline. Used by `login` and `register`. |
| `PasswordField` | `apps/mobile/lib/features/auth/presentation/_password_field.dart` | TextFormField with show/hide toggle. |
| `ErrorBanner` | `apps/mobile/lib/features/auth/presentation/_error_banner.dart` | Soft container using `VerdictPalette.scam` tones. |
| `AppShell` | `apps/mobile/lib/core/widgets/app_shell.dart` | Shared scaffold with 5-tab `BottomNavigationBar`. Role-aware: 3rd tab = "Moderate" for admin. Wraps GoRouter `StatefulNavigationShell`. |
| `EmptyGate` | `apps/mobile/lib/core/widgets/empty_gate.dart` | Sign-in/sign-up CTA for guests on gated screens. Renders inside shell scaffold (bottom nav stays visible). |
| `StatCardRow` | `apps/mobile/lib/core/widgets/stat_card_row.dart` | 3-up stat cards. Takes `HomeStats`. Coral accent on `newThisWeek` value. |
| `AlertCard` | `apps/mobile/lib/core/widgets/alert_card.dart` | Category-colored icon + chip + title + date. Takes `RecentAlert`. Reuse in `alerts`. |
| `ReportCard` | `apps/mobile/lib/core/widgets/report_card.dart` | Scamxcerpt + report count. Takes `RecentReport`. Reuse in `feed`. |
| `SectionHeader` | `apps/mobile/lib/core/widgets/section_header.dart` | Uppercase label + optional "See all" button. |
| `LegalDoc` | `apps/mobile/lib/features/legal/presentation/legal_doc.d body: "Last updated" caption + numbered sections. Used by`PrivacyScreen` and `TermsScreen`. |
| `BrandHeader` | `apps/mobile/lib/features/home/presentation/_brand_heeeting. Home-only. |
| `ClipboardBanner` | `apps/mobile/lib/features/home/presentation/_clipboard_banner.dart` | Clipboard detection banner. Home-only. |
| `_AccountCard` | `apps/mobile/lib/features/settings/presentation/_accidentity card (guest / user / admin). Settings-internal — private class. |
| `ModQueueRow` | `apps/mobile/lib/core/widgets/mod_queue_row.dart` | Moderation queue row: scam-type chip + age + title + evidence count + Review button. Flagged variant adds a coral-amber left border + team-note line. **Reporter handle is intentionally not rendered** (PRD v1.2 FR-7.4 + FR-7.8 — admin views are fully anonymised). |
| `AuditTrailRow` | `apps/mobile/lib/core/widgets/audit_trail_row.dart` | Timeline-style audit row: action label + optional admin label + timestamp + remark. Admin label is admin-to-admin transparency (FR-7.6) and is not the anonymised surface. |

## To build (referenced by screens)

| Widget | Used by | Sketch |
| --- | --- | --- |
| `VerdictPill` | `report-detail`, `verdict` | Coloured chip showing one of `Scam / Suspicious / Safe / Unknown` with icon + label. Driven by
`VerdictPalette.<verdict>.{bg,fg}`. |
| `FilterChipBar` | `feed`, `alerts`, `my-reports` | Horizontal scrollable chip row. Active chip uses primary fill, inactive uses `surfaceContainerHighest`. |
| `EvidenceList` | `report-detail`, `admin-review` | List of evidence it 2). Tap to preview (mocked in prototype). |
| `ConsentBlock` | `register` (built), reused by `submit-report` step 2 | Container with rounded corners holding the consent checkbox(es) + body text. |
| `StepBar` | `submit-report` | "Step 1 / 2" indicator at top of multi-
| `Toast` | global | Bottom-of-frame ephemeral message. The prototype u.g., share sheet). |

## Typography conventions

- Display title (screen H1): `textTheme.headlineSmall`, `FontWeight.w70
- Section heading (e.g. `THIS WEEK`, `RECENTLY VERIFIED`): uppercase, letter-spacing 0.06em, `textTheme.labelMedium`, muted.
- Body: `textTheme.bodyMedium`. Muted body uses `onSurfaceVariant`.
- Numeric stat: `textTheme.headlineMedium`, `FontWeight.w800`, tabular figures.

## Iconography
  
Material Outlined family throughout (`Icons.mail_outline`, `Icons.lock_outline`, `Icons.shield_outlined`, `Icons.warning_amber_outlined`, etc.). Verdict screens use a filled icon inside the verdict pill so the colour reads at a glance.
