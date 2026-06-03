# Personas — ScamReport

> CSC234 D4 deliverable. Full end-to-end journeys for each persona live in
> [`user-journey-map.md`](./user-journey-map.md); this sheet is the standalone
> persona reference used in design reviews and the audit report.

## P1 — "Aunty Som" · the cautious target

| | |
|---|---|
| Age / context | 58 · Bangkok · retired civil servant |
| Device | Mid-range Android, capped data plan |
| Language | Thai only (app default locale `th`) |
| Tech comfort | Low — uses LINE, mobile banking with help from family |
| Goal | Verify a suspicious SMS/link/number **before** acting on it |
| Frustrations | Gov-branded phishing looks real; jargon-filled warnings; tiny tap targets |
| Behaviours | Shares chain warnings in family LINE group; asks her son before clicking |
| Needs from ScamReport | One-box Check flow in plain Thai; share-target entry from the SMS app; verdicts that cite evidence ("ตรงกับ 12 รายงานที่ยืนยันแล้ว"); offline-tolerant reads |
| Design implications | 48 dp tap targets + WCAG AA contrast (see `docs/accessibility-checklist.md`); dynamic-type safe layouts; Sarabun Thai fallback; verdict colour + icon + text (never colour alone) |
| Success moment | Closes the phishing SMS without tapping; tells her friends about the app |

## P2 — "Tee" · the burned-once reporter

| | |
|---|---|
| Age / context | 24 · university student · lost ฿4,500 to a fake seller |
| Device | Android daily; campus PC for the web feed |
| Language | Thai/English bilingual |
| Tech comfort | High — power user, screenshots everything |
| Goal | Report his scam with evidence; look up sellers before transferring money |
| Frustrations | Reporting to police felt pointless; no single lookup point for seller numbers/accounts |
| Behaviours | Follows scam-watcher accounts; checks before every Marketplace deal; uses Ask AI to draft reports from screenshots |
| Needs from ScamReport | Fast evidence upload (compressed images); report status tracking (pending → verified) offline; biometric app-lock so his report history stays private on a shared device |
| Design implications | My-Reports Firestore mirror (offline-first); push on verification; Ask AI report-drafting flag; app-lock with PIN fallback |
| Success moment | His report gets verified and shows up in the public feed warning others |

## P3 — "Khun Wirat" · the NGO moderator

| | |
|---|---|
| Age / context | 41 · consumer-protection NGO staffer |
| Device | Desktop (web admin portal); phone for spot checks |
| Language | Thai primary, English UI acceptable |
| Tech comfort | Medium-high — spreadsheets, dashboards |
| Goal | Triage 50–100 community reports/day accurately and fast |
| Frustrations | Duplicate reports; thin evidence; fear of approving a false accusation |
| Behaviours | Sorts by oldest first; leans on AI confidence scores but verifies evidence himself; exports PDFs for partner agencies |
| Needs from ScamReport | Moderation queue with filters + AI score; full audit trail on every action; reporter PII hidden (anonymised admin responses); role-gated access (RBAC) |
| Design implications | Admin web portal + mod screens; `requireRole('admin')` on every `/admin/*` route; audit-trail timeline; AI verdict as *advice*, never auto-approval |
| Success moment | Clears the queue before lunch with zero mis-approvals |
