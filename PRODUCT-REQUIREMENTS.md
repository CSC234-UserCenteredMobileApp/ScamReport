# Scam Report Platform — Product Requirements Document

| | |
|---|---|
| **Document Version** | 1.1 |
| **Status** | Draft — for team review |
| **Date issued** | 2026-04-26 |
| **Course** | CSC231 Agile Project Management |
| **Institution** | King Mongkut's University of Technology Thonburi (KMUTT), School of Information Technology |
| **Team** | A.P (lead), T.P, B.S, S.P, Y.R |
| **Derived from** | Business Requirements Document v2.0 (2026-04-23) |

> **Scope of this document:** This PRD describes *what the application does and how it behaves* from the perspective of each type of user. Business goals, KPIs, and monetisation considerations are intentionally deferred to the BRD. This document is the authoritative reference for sprint planning, UI design, and backend contract decisions.

---

## 1. Product Overview

The **Scam Report Platform** is a Flutter mobile application (Android) that lets anyone quickly verify whether a phone number, URL, or message is associated with a known scam — and lets registered users submit scam reports that, once approved by a moderator, protect the broader community.

The application works in three complementary modes:

- **Active check** — the user opens the app and manually searches or pastes something suspicious.
- **Passive interception** — the app detects a suspicious item on the clipboard when the user returns to the app, and offers a one-tap check.
- **Push-delivered** — the app receives a background notification about a trending scam, and the user taps through to a verdict or detail screen.

The result of any check is always the same: a clear, colour-coded **traffic-light verdict** (Scam / Suspicious / Safe / Unknown) shown within 3 seconds, with supporting matched reports available one tap deeper.

---

## 2. User Roles

The application has three distinct user types. Each sees a different version of the same app — there is no separate admin web dashboard in this release.

| Role | How they get in | What they can do |
|---|---|---|
| **Guest** | Opens app, no login | Browse verified reports, open report detail pages, read announcements, view a shared deep-link verdict |
| **Registered User** | Signs up via email/password or Google OAuth | Everything a Guest can do, plus: run AI semantic search, submit scam reports, track their own submissions, receive push notifications for their report status changes and admin announcements |
| **Administrator** | Promoted manually by the team (no self-serve upgrade) | Everything a Registered User can do, plus: access the moderation queue, approve / reject / flag reports, create and publish announcements |

Role distinction is binary (`user` / `admin`) in this release. There is no mid-tier moderator or senior admin role.

---

## 3. Core User Flows

### 3.1 Quick Verdict Check (all users)

This is the most time-critical flow in the app. A user has something suspicious — a phone number, a URL, or a block of text — and needs a verdict fast.

**Entry points:**
- Typing or pasting directly into the search bar on the home screen.
- Sharing text/URL/phone number from *any other app* (e.g. LINE, SMS, Chrome) into this app via the Android share sheet.
- Tapping the clipboard banner that appears when the app detects a URL or phone number has been copied.

**What happens:**
1. The app sends the item to the `POST /check` endpoint.
2. A loading indicator is shown. The verdict must arrive within **3 seconds (P95)**.
3. The verdict screen displays one of four states:

| Verdict | Colour | Meaning |
|---|---|---|
| **Scam** | Red | This item matches one or more verified scam reports with high confidence. |
| **Suspicious** | Amber | Partial or low-confidence match; treat with caution. |
| **Safe** | Green | No matches found in the verified database. |
| **Unknown** | Grey | The item could not be classified (e.g. malformed input, service unavailable). |

4. Below the verdict label, a count of matched reports is shown (e.g. "3 verified reports matched").
5. The user can tap **"See matched reports"** to expand a list of the relevant verified report cards (title, scam type, date). Each card links to the full report detail page.
6. A persistent **"Report this"** button is always visible, allowing the user to begin a formal submission from the verdict screen.

**Design constraints:**
- The verdict itself — colour + label — must be immediately readable without scrolling.
- Colour is never the *only* indicator; each verdict also uses a distinct icon and text label (accessibility requirement).
- The verdict screen must work for a Guest (no login required to check something).

---

### 3.2 Browsing the Verified Feed (all users)

The public feed is the default home view for users who are not actively checking something. It shows all reports that an administrator has approved, in reverse-chronological order.

**Filters available:**
- Scam type (e.g. Phone Impersonation, Phishing SMS, Fake QR, E-commerce Fraud)
- Date range
- (Future) Province/region tag

**Each feed card shows:**
- Report title
- Scam type badge
- Date verified
- A short excerpt from the description

Tapping a card opens the **Report Detail Page**, which includes the full description, evidence thumbnails (if any), scam type, target identifier (phone/URL), verification date, and a shareable deep-link URL. The reporter's identity is never shown publicly — only the scam content itself is displayed.

Live aggregate statistics are displayed at the top of the feed: total verified reports, reports added this week, and the most common scam type this week.

---

### 3.3 AI Semantic Search (registered users only)

Registered users can ask the app a natural-language question about a scam, rather than requiring an exact string match.

**Examples of valid queries:**
- "ข้อความว่าพัสดุตกค้างจาก Kerry มีลิงก์ให้กดไหม" *(Is there a parcel-held message from Kerry with a link?)*
- "Someone called pretending to be from the Revenue Department"

**How it works for the user:**
1. The user types a free-text description into the search field on the Search screen.
2. Results are returned as ranked report cards, most relevant first.
3. Each result card shows a relevance indicator (high / medium / low confidence) alongside the standard report card fields.
4. The user can tap any result to open the full Report Detail Page.
5. If no relevant results are found, the screen shows a friendly empty state with a suggestion to submit a new report.

**Important UX note:** The AI search is a *discovery* tool, not a verdict tool. It helps users find similar past reports. It does not replace the Quick Verdict Check (§3.1) and does not output a Scam/Safe label on its own. This distinction must be communicated clearly in the UI (e.g. different screen entry point, different result layout).

**Why login is required:** Semantic search queries are logged per user to monitor abuse (e.g. probing the database with scammer-side queries) and to allow future personalisation. Guests see a prompt to sign up when they attempt to access this screen.

---

### 3.4 Submitting a Scam Report (registered users only)

A registered user who has encountered a scam can submit a formal report so that, if approved, it protects others.

**Report form fields:**

| Field | Required | Notes |
|---|---|---|
| Title | Yes | Short, descriptive label for the scam |
| Description | Yes | Free text — what happened, what made it suspicious |
| Scam type | Yes | Selected from a fixed taxonomy (e.g. Phone Impersonation, Phishing SMS, Fake E-commerce) |
| Target identifier | No | Phone number, URL, or other identifier involved in the scam |
| Evidence files | No | Up to 5 images or PDFs (screenshots, recordings) |

**Submission flow:**
1. User fills in the form. The "Submit" button is disabled until Title, Description, and Scam Type are filled.
2. Before final submission, the user is shown a **consent confirmation**: their report content (not their identity) will be made public if approved. They must explicitly confirm.
3. After submission, the report enters `Pending` status and appears in the user's **My Reports** list.
4. The user can edit or withdraw a submission while it remains `Pending`.
5. When an admin takes action, the report's status updates to `Verified` or `Rejected`. The user receives a push notification and sees the status change reflected in My Reports.

**On-device privacy rule:** Any URL or phone number extracted for verification is sent to the server. The raw *body* of an SMS message is never transmitted — only the extracted identifiers are.

---

### 3.5 My Reports (registered users only)

A dedicated screen listing all reports the current user has ever submitted, grouped by status:

- **Pending** — awaiting admin review; user can edit or withdraw. Reports that an admin has internally flagged for team discussion also appear here — from the reporter's perspective they are still simply "awaiting review."
- **Verified** — approved and live on the public feed.
- **Rejected** — not approved; the admin's remark is shown so the user understands why.

Tapping any report opens its detail view. For rejected reports, the admin remark is visible to the reporter but is not public.

---

### 3.6 Moderation Queue (administrators only)

The admin-facing queue is the primary tool for keeping the database trustworthy. It is accessed from within the same Flutter app via a role-gated tab that only appears for `admin` accounts.

**Queue view:**
- All `Pending` reports are listed, sorted by **age** (oldest first) by default, with an option to sort by a **Priority flag** set by the system or another admin.
- Each row shows: title, scam type, submission date, and the number of pieces of evidence attached.
- The queue auto-refreshes; a badge on the tab shows the current pending count.

**Report review screen:**
When an admin taps a report, they see the full submission: title, description, scam type, target identifier, and evidence files (viewable inline). Three actions are available:

| Action | Result | Remark required? |
|---|---|---|
| **Approve** | Report status → `Verified`; appears on public feed immediately | Yes (brief note on why it was approved is good practice, but required) |
| **Reject** | Report status → `Rejected`; reporter sees the remark | Yes — the remark is shown to the reporter |
| **Flag for discussion** | Report status → `Flagged`; stays in queue, highlighted | Yes — the note explains what the team needs to discuss |

**"Flag for discussion"** is not an escalation to a higher role — there is no higher role. It is a signal to other admins on the team that this report needs a group decision before action is taken. Flagged reports appear at the top of the queue with a distinct indicator.

**Audit trail:** Every action (approve, reject, flag, un-flag) is recorded with the admin's ID, timestamp, and remark. This log is visible to all admins on the report detail screen but is not public.

---

### 3.7 Announcements (all users; admin-created)

Announcements are short communications published by admins — distinct from user-submitted scam reports. Use cases include: alerting users to a new scam wave, sharing prevention tips, or posting platform updates.

**For guests and users:**
- Announcements appear in a dedicated tab, filterable by category (e.g. Fraud Alert, Tips, Platform Update).
- Each announcement has a detail page at a shareable URL.

**For administrators:**
- Admins can create, edit, publish, unpublish, and delete announcements from within the app.
- A published announcement triggers an FCM push notification sent to all registered users automatically.

---

### 3.8 Push Notifications (registered users)

Push notifications are scoped to two specific events only — no topic-based subscriptions or community-wide scam alerts.

**Case 1 — Report status change (reporter only):**
When an admin approves or rejects a report, the system automatically sends an FCM push notification to the user who submitted that report. The notification states the outcome (Verified or Rejected) and tapping it deep-links to the report's entry in My Reports.

**Case 2 — New announcement (all registered users):**
When an admin publishes an announcement, the system automatically sends an FCM push notification to all registered users. Tapping it deep-links to the Announcement Detail page.

There are no user-configurable notification topics or opt-out toggles in this release. All registered users receive both notification types automatically.

---

### 3.9 Proactive Interception Features

These features make the app useful *before* the user thinks to open it.

#### 3.9.1 Share-to-App (MVP)
The app registers as a Share target on Android. When a user selects "Share" on any text, URL, or phone number from any other app, this app appears as an option. Selecting it opens the Quick Verdict screen (§3.1) pre-populated with the shared content.

#### 3.9.2 Clipboard Scanner (MVP)
When the user returns to the app from the background, the app checks the clipboard for a URL or phone number. If one is detected:
- A non-intrusive banner appears at the top of the screen: *"We noticed a URL/number on your clipboard. Check it?"*
- Tapping the banner opens the Quick Verdict screen pre-populated with the clipboard content.
- The user can dismiss the banner; it does not reappear for the same clipboard value.
- The clipboard content is never read or transmitted without the user tapping the banner.

#### 3.9.3 Incoming Call Screening (Stretch — Android only)
When the device receives an incoming call, the app checks the caller's number against the verified database in the background. If a match is found:
- A notification appears on the lock screen / notification shade: *"Possible scam call — [number] has been reported X times."*
- This is a notification only; no overlay or call interception is used (platform policy compliance).
- The check must complete within 3 seconds of call start.

#### 3.9.4 SMS Smishing Detection (Stretch — Android only)
When an SMS arrives, the app reads it passively (no raw message body is sent to the server), extracts any URLs or phone numbers from the message text on-device, and submits only those identifiers to `POST /check`. If the verdict is Scam or Suspicious:
- A notification appears: *"Suspicious SMS detected — tap to review."*
- Tapping deep-links to the verdict screen.

---

## 4. Screen Inventory

| Screen ID | Name | Who can access | Primary purpose |
|---|---|---|---|
| P-01 | Splash / Login | All | Entry point; routes to onboarding or home |
| P-02 | Registration | Guest | Email/OAuth sign-up with consent capture |
| P-03 | Verified Feed | All | Browse approved reports |
| P-04 | Report Detail | All | Full view of a single verified report |
| P-05 | Announcements List | All | Browse admin-published announcements |
| P-06 | Announcement Detail | All | Full view of a single announcement |
| P-07 | Privacy Policy | All | Static legal text |
| P-08 | Terms of Service | All | Static legal text |
| P-09 | AI Search | Registered user | Natural-language semantic search |
| P-10 | Submit Report | Registered user | Report submission form |
| P-11 | My Reports | Registered user | Submission history and status |
| P-12 | Settings / Onboarding | Registered user | Notifications, language, account, tutorial |
| P-13 | Verdict Screen | All | Traffic-light result of a `POST /check` call |
| A-01 | Moderation Queue | Admin | List of pending and flagged reports |
| A-02 | Report Review | Admin | Approve / reject / flag a single report |
| A-03 | Announcement Editor | Admin | Create and manage announcements |

---

## 5. Functional Requirements

Requirement IDs map to screens in §4.

### 5.1 Identity and Access

| ID | Requirement |
|---|---|
| FR-1.1 | The system shall allow new users to register with email + password or Google OAuth. *(P-02)* |
| FR-1.2 | The system shall require explicit acceptance of the Privacy Policy and Terms of Service at registration and again at first report submission. *(P-02, P-07, P-08)* |
| FR-1.3 | The system shall allow returning users to sign in and maintain a session via Firebase ID tokens. *(P-01)* |
| FR-1.4 | The system shall gate admin-only screens based on the `admin` role flag; non-admin accounts must never reach these screens. |
| FR-1.5 | The system shall allow a user to delete their account, triggering purge of personal data within 7 days while retaining anonymised report content. |

### 5.2 Quick Verdict Check

| ID | Requirement |
|---|---|
| FR-2.1 | The system shall accept a phone number, URL, or free-text string via manual input, share-sheet, or clipboard banner, and return a verdict within 3 seconds P95. *(P-13)* |
| FR-2.2 | The verdict screen shall display exactly one of four states — Scam, Suspicious, Safe, Unknown — using both colour and a distinct icon + text label. *(P-13)* |
| FR-2.3 | The verdict screen shall show a count of matched verified reports and allow the user to expand a list of those report cards. *(P-13)* |
| FR-2.4 | The verdict screen shall be accessible to Guests (no login required). |
| FR-2.5 | A "Report this" button shall always be visible on the verdict screen; tapping it pre-populates the submission form with the checked identifier. *(P-10)* |

### 5.3 Verified Feed and Report Detail

| ID | Requirement |
|---|---|
| FR-3.1 | Anyone shall browse the verified-reports feed with filters by scam type and date sort. *(P-03)* |
| FR-3.2 | The feed shall display live aggregate statistics: total verified reports, reports this week, top scam type this week. *(P-03)* |
| FR-3.3 | Anyone shall open a verified report's detail page at a stable, shareable URL. *(P-04)* |
| FR-3.4 | The report detail page shall display scam content (title, description, type, target identifier, evidence) but shall never display the reporter's identity. *(P-04)* |

### 5.4 AI Semantic Search

| ID | Requirement |
|---|---|
| FR-4.1 | Only registered users shall access the semantic search screen; guests shall see a sign-up prompt. *(P-09)* |
| FR-4.2 | The system shall accept a natural-language query and return ranked report matches using RAG (Gemini + pgvector), within 3 seconds P95. *(P-09)* |
| FR-4.3 | Each result shall display a relevance confidence level (high / medium / low) alongside standard report card fields. *(P-09)* |
| FR-4.4 | The search results screen shall not display a Scam/Safe verdict label; it is a discovery tool, not a verdict tool. The UI must make this distinction clear. *(P-09)* |
| FR-4.5 | If no results are found, the screen shall show an empty state with a suggestion to submit a new report. *(P-09)* |

### 5.5 Report Submission

| ID | Requirement |
|---|---|
| FR-5.1 | Registered users shall submit a report with: title (required), description (required), scam type (required), target identifier (optional), and up to 5 evidence files (optional). *(P-10)* |
| FR-5.2 | The submit button shall remain disabled until all required fields are filled. *(P-10)* |
| FR-5.3 | Before final submission, the user shall see and explicitly confirm a consent notice stating that the report content (not their identity) will be made public if approved. *(P-10)* |
| FR-5.4 | Submitted reports shall enter `Pending` status and appear in My Reports immediately after submission. *(P-11)* |
| FR-5.5 | Users shall be able to edit or withdraw a report only while it is in `Pending` status. *(P-11)* |

### 5.6 My Reports

| ID | Requirement |
|---|---|
| FR-6.1 | The My Reports screen shall display all of the user's submissions grouped by status: Pending, Verified, Rejected. Reports that are internally `Flagged` by an admin shall display as `Pending` to the reporter. *(P-11)* |
| FR-6.2 | For reports in `Rejected` status, the admin's remark shall be visible to the reporter and to no one else. *(P-11)* |

### 5.7 Moderation

| ID | Requirement |
|---|---|
| FR-7.1 | Administrators shall view all `Pending` and `Flagged` reports in the moderation queue, sorted by age (oldest first) by default, with a secondary sort by priority flag. *(A-01)* |
| FR-7.2 | A badge on the admin tab shall display the current count of pending reports. *(A-01)* |
| FR-7.3 | On a report review screen, an admin shall take exactly one of three actions: Approve, Reject, or Flag for Discussion — each requiring a remark. *(A-02)* |
| FR-7.4 | Approving a report shall immediately set its status to `Verified` and make it visible on the public feed. *(A-02)* |
| FR-7.5 | Flagging a report shall set its status to `Flagged`, move it to the top of the moderation queue with a distinct visual indicator, and preserve it for further team review. There is no higher admin tier to escalate to. *(A-02)* |
| FR-7.6 | Every admin action shall be recorded in an immutable audit log with: admin user ID, action taken, timestamp, and remark. The log is visible to all admins on the report detail screen and is never shown publicly. *(A-02)* |
| FR-7.7 | Administrators shall create, edit, publish, unpublish, and delete announcements. *(A-03)* |

### 5.8 Communications and Notifications

| ID | Requirement |
|---|---|
| FR-8.1 | Anyone shall view the announcements list, filterable by category. *(P-05)* |
| FR-8.2 | Anyone shall open an announcement's detail page at a shareable URL. *(P-06)* |
| FR-8.3 | When an admin approves or rejects a report, the system shall automatically send an FCM push notification to the report's submitter indicating the outcome (Verified or Rejected). |
| FR-8.4 | When an admin publishes an announcement, the system shall automatically send an FCM push notification to all registered users. |
| FR-8.5 | Tapping a push notification shall deep-link to the correct in-app screen: My Reports (for status-change notifications) or Announcement Detail (for announcement notifications). |

### 5.9 Proactive Interception

| ID | Requirement |
|---|---|
| FR-9.1 | The app shall register as a Share target on Android; sharing text, a URL, or a phone number from any other app shall open the Verdict screen pre-populated with the shared content. |
| FR-9.2 | On app resume, the app shall detect URLs or phone numbers on the clipboard and display a dismissible banner offering one-tap verification. The clipboard value shall not be read or transmitted until the user taps the banner. |
| FR-9.3 | *(Stretch)* On Android, the app shall check an incoming caller's number against the verified database and display a lock-screen notification within 3 seconds if a scam match is found. No overlay or call interception shall be used. |
| FR-9.4 | *(Stretch)* On Android, the app shall passively read incoming SMS, extract URLs and phone numbers on-device, verify only those identifiers, and notify the user if the result is Scam or Suspicious. The raw SMS body shall never be transmitted. |

### 5.10 Onboarding and Settings

| ID | Requirement |
|---|---|
| FR-10.1 | New users shall see a brief onboarding tutorial on first launch explaining the three core actions: Check, Browse, and Report. *(P-12)* |
| FR-10.2 | Users shall manage language preference (Thai / English) and account settings from the Settings screen. Push notifications are automatic and require no user configuration. *(P-12)* |

---

## 6. Non-Functional Requirements

### 6.1 Performance

- The verdict from `POST /check` must arrive and render within **3 seconds P95** under normal load.
- Semantic search results must render within **3 seconds P95**.
- Background handlers for FCM and SMS (stretch) must complete their Dart-side work within **200 ms** before making a network call.
- The app must cache the last 100 verdict results locally so that known items can be shown instantly offline.

### 6.2 Security

- All API traffic uses HTTPS / TLS 1.2 or higher.
- Every authenticated request must include a valid Firebase ID token.
- Evidence files are stored in Supabase with row-level security; files are accessible only via signed, time-limited URLs.
- Application secrets are managed via `envied` + `.env` and are never committed to source control.

### 6.3 Privacy

- At registration and at first report submission, the user must give explicit, recorded consent.
- The reporter's identity (name, email, user ID) is stored server-side for accountability purposes only; it is never included in any public-facing API response.
- For the SMS smishing feature (stretch), URL and phone number extraction happens entirely on-device. The raw SMS body is never transmitted.
- Users may request full account deletion; personal data is purged within 7 days. Anonymised report content (the scam evidence itself) is retained as it is part of the public dataset.

### 6.4 Accessibility

- All verdict states must be communicated via colour **and** a distinct icon **and** a text label — colour is never the sole differentiator.
- Minimum tap target size: 48 × 48 dp on all interactive elements.
- All UI must support both Thai and English strings from launch; Thai is the default.
- A new user must be able to complete onboarding and receive their first verdict within **60 seconds** of first launch.

### 6.5 Offline Behaviour

- If the network is unavailable, the app shows an offline banner.
- Recently cached verdicts (last 100) are shown with a "cached result" label.
- The verdict for a new, uncached item cannot be retrieved offline; the app shows a clear "No connection — try again" message rather than a false result.

### 6.6 Platform Scope

- **Android is the only supported platform** for this release. There is no iOS build, no iOS-specific code path, and no APNs integration.
- The app must not use Android Accessibility Services or system-overlay windows (platform policy compliance).

### 6.7 Code Quality

- Architecture follows Feature-first + Clean Architecture (as defined in `GEMINI.md`).
- All repository methods return `Result<T, Failure>`; no uncaught exceptions cross the domain boundary.
- Target: 100% unit-test coverage for `domain/` and `data/` layers; widget tests for all critical UI paths.
- CI must be green before any merge to main.

---

## 7. Out of Scope (this release)

The following are explicitly excluded and should not be designed or built until a future release decision is made:

- **iOS support of any kind** — no iOS build, no APNs, no Apple OAuth, no App Store submission.
- Any use of Android Accessibility Services or system-overlay windows.
- Contact-list synchronisation or address-book risk scoring.
- OCR screenshot scanning, QR code scanner, home-screen widgets, voice-assistant shortcuts.
- In-app safe browser or protected web view.
- Federated login with national ID (ThaID) or bank KYC.
- Non-Thai/English localisation.
- Any monetisation, subscription, or advertising feature.

---

## 8. Open Questions

These must be resolved before Sprint 1 begins. Outcomes should be recorded in v1.1 of this document.

| # | Question | Owner | Impact |
|---|---|---|---|
| OQ-1 | **Reporter display in public feed** — do we show a masked username (e.g. "User_4f2a") or fully anonymise every report? | Product + Legal (B.S) | Affects Report Detail page design and API response shape |
| OQ-2 | **Evidence retention after rejection** — how long do we keep evidence files for rejected reports before purging? | Legal + Backend (A.P) | Affects Supabase storage policy and PDPA compliance |
| OQ-3 | **Regional tagging** — do we add a province field to the submission form to power a future "scam near you" view? | Product | One extra field at submission; affects feed filter design |
| OQ-4 | **Offline report queue** — if the user submits a report while offline, do we queue it for retry on reconnection, or require connectivity at submission time? | UX + Backend | Affects submission flow and local storage design |
| OQ-5 | **`POST /check` API contract** — confirm the accepted schema `{type, payload, meta?}` and the exact verdict response shape with the backend team. | Backend (A.P) | Blocks all proactive feature and verdict screen implementation |

---

## 9. Glossary

| Term | Meaning |
|---|---|
| **PRD** | Product Requirements Document (this document) |
| **MVP** | Minimum Viable Product — the smallest feature set that delivers the core product experience |
| **RAG** | Retrieval-Augmented Generation — semantic search over stored report embeddings, powered by Gemini + pgvector |
| **pgvector** | Postgres extension for vector-similarity search |
| **FCM** | Firebase Cloud Messaging — Google's push-notification service |
| **PDPA** | Personal Data Protection Act (Thailand) |
| **RBAC** | Role-Based Access Control |
| **P95 latency** | The response time that 95% of all requests meet or beat |
| **Verified report** | A submitted report that an administrator has approved; visible on the public feed |
| **Pending report** | A submitted report awaiting admin review; includes reports internally flagged by an admin (the reporter sees only "Pending") |
| **Flagged report** | An admin-internal status marking a report for team discussion before a final decision; not exposed to reporters |
| **Verdict** | The output of `POST /check`: one of Scam, Suspicious, Safe, or Unknown |
| **Proactive interception** | Features that check for scams without the user actively opening the app (share sheet, clipboard, call screening, SMS) — all Android-only |

---

## 10. Document Control

| Version | Date | Author | Notes |
|---|---|---|---|
| 1.0 | 2026-04-25 | Team | Initial PRD derived from BRD v2.0; reframed around product behaviour. |
| 1.1 | 2026-04-26 | Team | Simplified: report statuses reduced to Pending/Verified/Rejected (reporter-facing); push notifications scoped to two cases (status change → reporter, announcement → all users); platform narrowed to Android only; Apple OAuth removed; topic subscriptions removed; OQ-6 and OQ-7 resolved and closed. |

**Sign-off required before Sprint 1:**
- [ ] Team consensus (A.P, T.P, B.S, S.P, Y.R)
- [ ] `POST /check` API contract confirmed (A.P)
- [ ] Open Questions OQ-1 through OQ-5 recorded as resolved or deferred

---

*End of document. Store alongside `REVISE-BUSSINESS-REQUIREMENTS.md`, `BackLog&GANTT.xlsx`, `README.md`, and `GEMINI.md` at the repository root.*
