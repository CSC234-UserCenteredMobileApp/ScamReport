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
| `StatCardRow` | `apps/mobile/lib/core/widgets/stat_card_row.dart` | 3-up stat cards. Takes `HomeStats`. Coral accent on `newThisWeek` value. |
| `AlertCard` | `apps/mobile/lib/core/widgets/alert_card.dart` | Category-colored icon + chip + title + date. Takes `RecentAlert`. |
| `ReportCard` | `apps/mobile/lib/core/widgets/report_card.dart` | Scam type chip + date + title + excerpt + report count. Takes `RecentReport`. |
| `SectionHeader` | `apps/mobile/lib/core/widgets/section_header.dart` | Uppercase label + optional "See all" button. |
| `BrandHeader` | `apps/mobile/lib/features/home/presentation/_brand_header.dart` | Avatar pill + greeting. Home-only. |
| `ClipboardBanner` | `apps/mobile/lib/features/home/presentation/_clipboard_banner.dart` | Clipboard detection banner. Home-only. |

## To build (referenced by screens)

| Widget | Used by | Sketch |
| --- | --- | --- |
| `VerdictPill` | `report-detail`, `verdict` | Coloured chip showing one of `Scam / Suspicious / Safe / Unknown` with icon + label. Driven by `VerdictPalette.<verdict>.{bg,fg}`. |
| `FilterChipBar` | `feed`, `alerts`, `my-reports` | Horizontal scrollable chip row. Active chip uses primary fill, inactive uses `surfaceContainerHighest`. |
| `EvidenceList` | `report-detail`, `admin-review` | List of evidence items (Screenshot 1, Screenshot 2). Tap to preview (mocked in prototype). |
| `ConsentBlock` | `register` (built), reused by `submit-report` step 2 | Container with rounded corners holding the consent checkbox(es) + body text. |
| `StepBar` | `submit-report` | "Step 1 / 2" indicator at top of multi-step form. |
| `ModQueueRow` | `mod` | Type chip + age + title + reporter handle (`User_xxxx`) + N evidence + Review button. Flagged variant adds a pinned border + team note row beneath. |
| `AuditTrailRow` | `admin-review` | Timeline-style row: action label + admin handle + timestamp + remark text. |
| `LegalDoc` | `privacy`, `terms` | Static Markdown-style scrollable column with H1 + numbered sections + last-updated date. |
| `EmptyGate` | `search`, `submit-report` (guest variant) | Sign-in/sign-up call-to-action panel that replaces the gated screen for guests. |
| `Toast` | global | Bottom-of-frame ephemeral message. The prototype uses it for stubbed actions (e.g., share sheet). |

## Typography conventions

- Display title (screen H1): `textTheme.headlineSmall`, `FontWeight.w700`.
- Section heading (e.g. `THIS WEEK`, `RECENTLY VERIFIED`): uppercase, letter-spacing 0.06em, `textTheme.labelMedium`, muted.
- Body: `textTheme.bodyMedium`. Muted body uses `onSurfaceVariant`.
- Numeric stat: `textTheme.headlineMedium`, `FontWeight.w800`, tabular figures.

## Iconography

Material Outlined family throughout (`Icons.mail_outline`, `Icons.lock_outline`, `Icons.shield_outlined`, `Icons.warning_amber_outlined`, etc.). Verdict screens use a filled icon inside the verdict pill so the colour reads at a glance.
