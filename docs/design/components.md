# Component catalogue

Reusable widgets used across screens. Each entry: source path (or "to build") + 1-line usage. When implementing a screen, prefer extending an existing widget over inventing a new one.

Tokens always come from `apps/mobile/lib/core/theme/app_theme.dart` (`ColorScheme`, `VerdictPalette` extension). Spacing: 8 / 16 / 24 px. Radii: `--r-sm 8 / md 12 / lg 16 / xl 24 / full 999` (already in theme).

## Already built

| Widget | Source | Usage |
| --- | --- | --- |
| `AuthScaffold` | `apps/mobile/lib/features/auth/presentation/_auth_scaffold.dart` | Scrollable scaffold with brand pill + wordmark + tagline. Used by `login` and `register`. |
| `PasswordField` | `apps/mobile/lib/features/auth/presentation/_password_field.dart` | TextFormField with show/hide toggle. |
| `ErrorBanner` | `apps/mobile/lib/features/auth/presentation/_error_banner.dart` | Soft container using `VerdictPalette.scam` tones. |
| `BottomNav` (via `AppShell`) | `apps/mobile/lib/core/widgets/app_shell.dart` | 5-tab `BottomNavigationBar` inside a `StatefulShellRoute`. Admin role swaps tab 2 label to "Moderate". Reads `currentUserProvider` to detect role. |
| `BrandHeader` | `apps/mobile/lib/features/home/presentation/_brand_header.dart` | Avatar pill (initials for authed, generic icon for guest) + greeting + tagline. Used by `home`. |
| `ClipboardBanner` | `apps/mobile/lib/features/home/presentation/_clipboard_banner.dart` | Coral card with clipboard snippet, "Check it" button, dismiss ×. Shown when clipboard has phone/url pattern (FR-9.2). |
| `StatCardRow` | `apps/mobile/lib/features/home/presentation/_stat_card_row.dart` | 3-up grid: big number / label. Used by `home`; reuse in `feed` and `mod`. |
| `AlertCard` | `apps/mobile/lib/features/home/presentation/_alert_card.dart` | Category chip + title + date. Category colour variants (Fraud Alert → scam red, Tips → safe green, Platform Update → coral). Reuse in `alerts`. |
| `ReportCard` | `apps/mobile/lib/features/home/presentation/_report_card.dart` | Type chip + date + title + excerpt + "N reports" count. Tappable → `report-detail`. Reuse in `feed`. |
| `_AccountCard` | `apps/mobile/lib/features/settings/presentation/_account_card.dart` | Role-aware identity card: guest (person icon + "Sign in" btn) / user (coral avatar + name + email) / admin (+ coral "Admin" chip). Reuse wherever user identity is shown. |
| `EmptyGate` | `apps/mobile/lib/core/widgets/empty_gate.dart` | Sign-in/sign-up CTA panel for guests on gated screens. Props: icon, heading, body, primaryLabel/onPrimary, optional secondaryLabel/onSecondary. Bottom nav stays visible — gate renders inside the shell scaffold. |

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
| `Toast` | global | Bottom-of-frame ephemeral message. The prototype uses it for stubbed actions (e.g., share sheet). |

## Typography conventions

- Display title (screen H1): `textTheme.headlineSmall`, `FontWeight.w700`.
- Section heading (e.g. `THIS WEEK`, `RECENTLY VERIFIED`): uppercase, letter-spacing 0.06em, `textTheme.labelMedium`, muted.
- Body: `textTheme.bodyMedium`. Muted body uses `onSurfaceVariant`.
- Numeric stat: `textTheme.headlineMedium`, `FontWeight.w800`, tabular figures.

## Iconography

Material Outlined family throughout (`Icons.mail_outline`, `Icons.lock_outline`, `Icons.shield_outlined`, `Icons.warning_amber_outlined`, etc.). Verdict screens use a filled icon inside the verdict pill so the colour reads at a glance.
