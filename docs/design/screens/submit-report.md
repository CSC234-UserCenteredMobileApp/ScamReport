# submit-report — Report a scam (2-step form)

**PRD:** FR-5.1–FR-5.3 / P-10  **Roles:** user, admin (gated for guest)
**Flutter:** `apps/mobile/lib/features/reports/presentation/submit_report_screen.dart` (planned)

**Snapshots:** `../snapshots/user/submit-report.txt` (form), `../snapshots/guest/submit-report.txt` (gate)
**Screenshots:** `../screenshots/user/submit-report.png`, `../screenshots/guest/submit-report.png`

## Purpose

Two-step form to submit a new scam report. Step 2 is the consent gate (FR-5.3) that explicitly states the report content (not the reporter) will be public if approved.

## Layout (step 1 — captured)

- Top bar: back arrow + title `Report a scam`.
- `StepBar`: `1 of 2` (TBD — capture the indicator placement when implementing; current snapshot does not include it).
- Form fields:
  1. **Title** *required* — single-line `TextField`.
  2. **Description** *required* — multi-line `TextField` with `0/500 characters` counter.
  3. **Scam type** *required* — chip group with 6 options: `Phone Impersonation / Phishing SMS / Fake QR Code / E-commerce Fraud / Investment Fraud / Romance Scam`.
  4. **Target identifier** — single-line, helper text `Optional — what was the scammer's number, link, or account?`.
  5. **Evidence (optional)** — file picker, helper `Add up to 5 images or PDFs`.
- Primary CTA: `Continue` (full-width, disabled until required fields valid).

## Layout (step 2 — not captured, plan from design-review.md)

- Top bar: back arrow + title `Confirm and submit`.
- Recap card showing the entered values (read-only).
- **`ConsentBlock`** (reuse from `register`):
  - Body: `By submitting, you agree that this report — but never your identity — may be published to the verified feed once approved.`
  - Single checkbox: `I understand and agree.`
- Primary CTA: `Submit report` (full-width, disabled until checkbox ticked).

## Layout (guest gate)

- `EmptyGate` panel:
  - Heading `Sign in to submit a report`
  - Body `We require an account to keep the verified database trustworthy.`
  - Button: `Sign in or register` → `login` (which links to register).
- `BottomNav` visible.

## States

- **Step 1 idle** — `Continue` disabled.
- **Step 1 valid** — `Continue` enabled.
- **Step 1 prefilled** — when reached from `verdict` "Report this", `target_identifier` and possibly `scam_type` are pre-set.
- **Step 2** — see Layout (step 2).
- **Submitting** — `AbsorbPointer` + spinner on button.
- **Error** — `ErrorBanner` above the CTA.
- **Success** — toast `Report submitted — we'll let you know when it's reviewed.` + push-replace `my-reports` with the new row visible at top as `Pending`.
- **Guest** — see Layout (guest gate).

## Interactions

- Step 1 `Continue` → step 2.
- Step 2 back → step 1 (preserves values).
- Step 2 `Submit` → `POST /reports`. On success → `my-reports`.

## Role variants

| Role | Behaviour |
| --- | --- |
| Guest | `EmptyGate` |
| User | Full form |
| Admin | Same as user (admins can submit reports too) |

## Notes / open questions

- Capture step 2 from the prototype before final implementation — copy the consent string verbatim.
- Pre-fill semantics from `verdict`: pass `{ target_identifier, scam_type? }` as URL state (go_router extra). Don't pre-fill the title/description.
- Char limit on description: prototype shows `0/500`. Confirm the API enforces 500 too.
