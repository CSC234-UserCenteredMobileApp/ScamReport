# Design specs — ScamReport mobile

How to use this directory when implementing a Flutter screen:

1. Load `docs/design-review.md` once for design tokens, PRD mapping, and team-level decisions.
2. Load `docs/design/components.md` for the catalogue of reusable widgets.
3. Load `docs/design/screens/<screen>.md` for the screen you are building. That file points at:
   - `docs/design/screenshots/<role>/<screen>.png` — rendered phone-frame visual
   - `docs/design/snapshots/<role>/<screen>.txt` — accessibility text dump

Tokens come from `apps/mobile/lib/core/theme/app_theme.dart`. Don't hardcode hex.

Source: extracted from `~/Documents/ScamReport Prototype _standalone_{guest,user,admin}.html` (Claude Design bundles, 2026-04-26 handoff).

## Screens

| Screen | PRD | Roles | Spec |
| --- | --- | --- | --- |
| `onboarding` | FR-10.1 | first-launch | [onboarding.md](screens/onboarding.md) |
| `login` | FR-1.1 / P-01 | guest entry | [login.md](screens/login.md) |
| `home` | — (entry point) | all | [home.md](screens/home.md) |
| `check-input` | FR-2.1 | all | [check-input.md](screens/check-input.md) |
| `verdict` | FR-2.2 / P-13 | all | [verdict.md](screens/verdict.md) |
| `feed` | FR-3.1 / P-03 | all | [feed.md](screens/feed.md) |
| `report-detail` | FR-3.4 / P-04 | all | [report-detail.md](screens/report-detail.md) |
| `alerts` | FR-8.1 / P-05 | all | [alerts.md](screens/alerts.md) |
| `announcement-detail` | FR-8.2 / P-06 | all | [announcement-detail.md](screens/announcement-detail.md) |
| `privacy` | P-07 | all | [privacy.md](screens/privacy.md) |
| `terms` | P-08 | all | [terms.md](screens/terms.md) |
| `search` | FR-4.x / P-09 | user, admin (gated for guest) | [search.md](screens/search.md) |
| `submit-report` | FR-5.x / P-10 | user, admin (gated for guest) | [submit-report.md](screens/submit-report.md) |
| `my-reports` | FR-6.x / P-11 | user, admin | [my-reports.md](screens/my-reports.md) |
| `me` | P-12 / FR-10.2 | all | [me.md](screens/me.md) |
| `mod` | FR-7.1 / A-01 | admin | [mod.md](screens/mod.md) |
| `admin-review` | FR-7.3 / A-02 | admin | [admin-review.md](screens/admin-review.md) |
| `announcement-editor` | FR-7.7 / A-03 | admin | [announcement-editor.md](screens/announcement-editor.md) |

## Role variants

The prototype renders the same screens for every role and changes only:

- **Bottom nav.** Guest + user see `Home / Feed / Report / Alerts / Me`. Admin replaces "Report" with "Moderate" (deep-links to `mod`).
- **Greeting.** Guest sees `Hi 👋 Stay one step ahead of scams`. Logged-in roles see avatar + `Hi, <name> 👋`.
- **`me`.** Guest shows "Not signed in / Sign in". User shows account row with email + Sign out. Admin adds an `Admin` badge under the email.
- **`search` and `submit-report`.** Guest sees a sign-in gate; user/admin sees the real screen.

PRD §6.4 (colour never the only differentiator), FR-10.2 (TH default) and the divergences listed in `design-review.md` apply throughout.

## Re-extracting

Source HTMLs are not committed (they live in `~/Documents/`). To re-run the capture:

```bash
cd ~/Documents
python3 -m http.server 8765 --bind 127.0.0.1 &
PLAYWRIGHT_BROWSERS_PATH=/home/symphony/.cache/ms-playwright bun /tmp/extract-design.mjs
kill %1
```

The script (`/tmp/extract-design.mjs`) is intentionally outside the repo — it depends on the local Playwright cache and the local prototype files. If that workflow needs to be portable, copy it into `scripts/` and have it accept an arg for the source HTML directory.
