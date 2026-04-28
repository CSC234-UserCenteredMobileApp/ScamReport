# Design review — Scam Report mobile app

> **Per-screen specs:** see [`docs/design/index.md`](./design/index.md). This file stays the canonical reference for tokens, screen inventory, flows, and team-level decisions; `docs/design/` is the per-screen depth (layout / states / interactions / role variants) distilled from the prototype.

**Source:** Claude Design handoff bundle (received 2026-04-26).
Design tool URL: `https://api.anthropic.com/v1/design/h/GMhLuv4UPDeZgCDxLDgTLg?open_file=ScamReport+Prototype.html` (auth-protected; expand from claude.ai if you need to re-open).

**What was in the bundle:**
- `README.md` — instructions for the implementing agent
- `chats/chat1.md` — full conversation transcript, including the design-direction commit ("warm coral primary, traffic-light verdict palette, Plus Jakarta Sans") and two rounds of dark-mode contrast fixes
- `project/ScamReport Prototype.html` — entry point; renders an Android frame and a screen router via React+Babel-standalone
- `project/styles.css` — design tokens (brand, verdict, neutrals, type, radii, shadows) + global styles for both light and dark themes
- `project/data.jsx` — sample reports / scam types / announcements / I18N strings (EN + TH)
- `project/icons.jsx`, `screens-core.jsx`, `screens-account.jsx`, `screens-admin.jsx`, `android-frame.jsx`, `tweaks-panel.jsx`

The raw bundle is not committed; everything actionable is captured below.

---

## Design system — translated to Flutter ThemeData

| Token (CSS) | Light hex | Dark hex | Flutter destination |
| --- | --- | --- | --- |
| `--brand-500` (primary) | `#f25f2a` | same | `ColorScheme` seed |
| `--brand-50…700` ramp | `#fff5f0…#b43811` | dark-mode tints | accessed via `ColorScheme` tonal palette |
| `--scam-bg / fg / accent / soft` | `#fef2f2 / #b91c1c / #dc2626 / #fee2e2` | `#2a1414 / #fca5a5 / #dc2626 / #4a1f1f` | `VerdictPalette` extension → `.scam` |
| `--suspicious-*` | amber set | amber-on-dark | `VerdictPalette.suspicious` |
| `--safe-*` | green set | green-on-dark | `VerdictPalette.safe` |
| `--unknown-*` | slate set | slate-on-dark | `VerdictPalette.unknown` |
| `--bg / --surface / --surface-2` | `#fafaf7 / #ffffff / #f5f4ef` | `#14130f / #1d1c18 / #26241f` | `colorScheme.surface*` + `scaffoldBackgroundColor` |
| `--ink / --ink-soft / --ink-muted` | `#1a1814 / #4b4842 / #847f74` | inverted | `colorScheme.onSurface*` + `textTheme` colours |
| `--font-display` | Plus Jakarta Sans | same | `GoogleFonts.plusJakartaSansTextTheme()` |
| `--font-mono` | JetBrains Mono | same | reserve for the rare mono use case (e.g. `target_identifier` display) |
| `--r-sm / md / lg / xl / full` | `8 / 12 / 16 / 24 / 999` px | same | `RoundedRectangleBorder` per component |
| `--shadow-sm…xl` | warm soft shadows | dark equivalents | M3 elevation tokens |

Implementation: `apps/mobile/lib/core/theme/app_theme.dart` (this PR). Verdict colours are accessed via `Theme.of(context).extension<VerdictPalette>()!.scam.fg` — no hardcoded hex anywhere downstream.

---

## Screen inventory (16 + onboarding overlay)

Each prototype screen maps to a PRD §4 ID.

### Public (no auth required)
| PRD | Prototype screen | Purpose |
| --- | --- | --- |
| P-01 / P-02 | `login` | Email + Google sign-in (FR-1.1) |
| P-03 | `feed` | Verified-reports feed with filters + live aggregate stats (FR-3.1, FR-3.2) |
| P-04 | `report-detail` | Full verified report; never shows reporter (FR-3.4) |
| P-05 | `alerts` | Announcements list, filterable by category (FR-8.1) |
| P-06 | `announcement-detail` | Announcement at shareable URL (FR-8.2) |
| P-07 | `privacy` | Static legal text |
| P-08 | `terms` | Static legal text |
| P-13 | `verdict` | Traffic-light verdict screen (FR-2.2) — has two layout variants |
| — | `home` | Personalised hero + stats + recent alerts (entry into verdict) — has two layout variants |
| — | `check-input` | Manual paste field; alternative entry to verdict |
| — | `onboarding` | First-launch tutorial (FR-10.1) |

### Registered user
| PRD | Prototype screen | Purpose |
| --- | --- | --- |
| P-09 | `search` | AI semantic search; ranked relevance cards (FR-4.1–FR-4.5) |
| P-10 | `submit-report` | Two-step submit form with consent gate (FR-5.1–FR-5.3) |
| P-11 | `my-reports` | Submission history grouped by status (FR-6.1, FR-6.2) |
| P-12 | `me` (Settings) | Language, theme, account (FR-10.2) |

### Admin
| PRD | Prototype screen | Purpose |
| --- | --- | --- |
| A-01 | `mod` (Moderation queue) | Pending + flagged sorted by age, priority flag highlighted (FR-7.1, FR-7.2) |
| A-02 | `admin-review` | Approve / Reject / Flag with mandatory remark + audit log (FR-7.3–FR-7.6) |
| A-03 | `announcement-editor` | Create / edit / publish / unpublish announcements (FR-7.7) |

### Components / overlays not screens
- Clipboard banner (FR-9.2) — overlay on `home`
- Toast notifications — bottom-of-frame ephemeral
- Bottom navigation — adapts to role (Guest sees Home/Feed/Alerts/Me; User adds Report; Admin replaces Report with Mod)

---

## Primary user flows

**1. Quick Verdict (FR-2.x).**
`home` (or share-target / clipboard banner) → user types or pastes → loading state → `verdict` (Scam / Suspicious / Safe / Unknown). Verdict screen surfaces matched-reports count and a "Report this" CTA that pre-populates `submit-report` with the checked identifier.

**2. Submit Report (FR-5.x).**
`home` → `submit-report` step 1 (form) → step 2 (consent gate that explicitly states the report content — not the reporter — will be public if approved) → `my-reports` with the new entry as `Pending`. While Pending, the user can edit or withdraw.

**3. Moderation (FR-7.x).**
Admin lands on `mod` → taps a row → `admin-review` showing full submission + evidence inline → picks Approve, Reject, or Flag for Discussion (each requires a remark). Approve / Reject changes are reflected in the reporter's `my-reports` and trigger an FCM push (FR-8.3). Flag keeps the report in queue, highlighted, with a team-internal note.

**4. Announcement broadcast (FR-7.7, FR-8.4).**
Admin uses `announcement-editor` → publish → all registered users receive an FCM push that deep-links to `announcement-detail`.

---

## Alignment with PRD / DB design / scaffold

| Requirement | Design treatment | Status |
| --- | --- | --- |
| FR-2.2 verdict colour + icon + text label | Each verdict has a colour, a distinct icon, and a label | ✓ aligned |
| FR-2.4 verdict accessible to guests | `verdict` screen reachable without login | ✓ aligned |
| FR-3.4 report detail never shows reporter | `report-detail` displays scam content only | ✓ aligned |
| FR-4.4 AI Search not a verdict tool | Result cards show relevance, no Scam/Safe label | ✓ aligned |
| FR-5.3 consent gate before submit | 2-step form, step 2 is explicit consent | ✓ aligned |
| FR-6.1 flagged reports surface as Pending to reporter | **`MY_REPORTS_SAMPLE` shows `Flagged` directly** | ⚠️ diverges (sample-data bug) |
| FR-7.6 every admin action has admin ID + timestamp + remark in audit log | `admin-review` collects remarks; audit log surfaced | ✓ aligned |
| FR-9.2 clipboard banner non-destructive | Banner appears on app resume, dismissible, doesn't transmit until tap | ✓ aligned |
| FR-10.2 language toggle | Settings screen + Tweaks shows EN/TH | ✓ aligned |
| §6.4 colour is never the only differentiator | Colour + icon + label everywhere verdict appears | ✓ aligned |
| §6.4 Thai is default | Tweak default is `lang: 'en'` in this prototype, but I18N has full Thai strings | ⚠️ flip the default in the Flutter app |
| Scam types taxonomy (PRD §3.4 e.g.) | 6 types: phone_imp / phishing_sms / fake_qr / ecommerce / investment / romance | ⚠️ DB seed has 5 different keys |
| OQ-1 reporter display | Mod queue shows masked usernames (`User_3a91`) | ⚠️ implicitly resolved — team should ratify |
| Tweaks panel | Dev tooling only; not part of app | ❌ do not implement |

---

## Decisions surfaced for the team

These came out of the design review and need a call before relevant feature work starts:

1. **Scam types alignment.** Pick the canonical list. Options:
   - Adopt design's six and run a follow-up DB migration (`INSERT INTO scam_types … investment, romance`; rename `phone_impersonation` → `phone_imp` or vice versa)
   - Stick with DB's five, update the design's `data.jsx`-equivalent in the Flutter app
   - Recommendation: **adopt the design's six** but keep the DB's longer slugs (`phone_impersonation` over `phone_imp`) because they're more readable in API responses.
2. **Status mapping in My Reports.** Design's prototype data shows `Flagged` to the reporter; that contradicts PRD FR-6.1. The Flutter app must always map `flagged → 'Pending'` for reporter-facing views. Fix when implementing P-11.
3. **OQ-1 reporter display.** Design assumes masked username. Either ratify (and add `users.public_handle text NOT NULL DEFAULT 'User_' || substr(replace(id::text, '-', ''), 0, 5)` in a follow-up migration) or override in favour of full anonymisation.
4. **Slug naming.** Pick between `phone_imp` (design) and `phone_impersonation` (DB). Engineering recommendation: longer DB slugs. Update design tokens / sample data when implementing.
5. **Sample announcement copy.** `a-003` claims AI Search supports voice + screenshots. Treat as placeholder copy only; don't carry into the production seed.
6. **Two layout variations to lock in.**
   - **Home:** search-led (familiar utility-app pattern) vs. panic big-button (single-action focus). The PRD doesn't prescribe; pick one before building P-01/home.
   - **Verdict:** card layout vs. full-bleed. Both meet FR-2.2; full-bleed reads as more urgent, card lets the matched-reports count breathe. Pick before building P-13.

---

## What we are NOT building from the prototype

- **Tweaks panel** (`tweaks-panel.jsx`, ~419 lines). Dev tooling only — lets a designer toggle role / verdict / variants without rebuilding. Has no place in the production app.
- **Variation toggles inside the app.** Once we pick a Home and Verdict variant (decision 6 above), the unchosen one is dropped. Don't ship both.
- **The "investment" and "romance" scam-type icons** until decision 1 is made.
- **The `Flagged` reporter-facing status.** Bug in prototype, real product behaviour is map-to-pending.

---

## Where this lands in the codebase

- **Flutter theme:** `apps/mobile/lib/core/theme/app_theme.dart` — written this PR, exposes `lightTheme()`, `darkTheme()`, and `VerdictPalette` extension.
- **Screen implementation:** each PRD screen ID becomes a Flutter feature folder under `apps/mobile/lib/features/<screen>/{data,domain,presentation}/`. Use `/add-feature` slash command. Use the design as the visual spec; don't transliterate React component shapes — match the visual output via Flutter idioms.
- **Sample data / fixtures:** when adding a feature, copy relevant samples from the prototype's `data.jsx` for tests and dev seeding, but treat them as fixtures, not requirements.
- **EN/TH copy:** the prototype has working bilingual strings; reuse them when wiring `Localizations`.
