# Security policy

Thank you for helping keep ScamReport and its users safe.

## Reporting a vulnerability

**Please do not open a public GitHub issue for security problems.** Instead, email the maintainers privately:

📧 **67130500846@ad.sit.kmutt.ac.th**

Include in your report:

- A description of the vulnerability and its impact
- Steps to reproduce (a minimal proof-of-concept is ideal)
- The affected commit / version (or `main` if you're testing the latest)
- Any logs, screenshots, or sample payloads

We aim to acknowledge reports within **5 business days** and to provide an initial assessment within **10 business days**.

## Supported versions

Only the latest commit on `main` is supported during early development. Once we cut tagged releases this section will list which versions receive security fixes.

| Version | Supported |
| --- | --- |
| `main` (latest) | ✅ |
| Older commits | ❌ |

## Coordinated disclosure

Once a fix is merged, we'll publish a coordinated advisory through GitHub's [Security Advisories](https://docs.github.com/en/code-security/security-advisories) tab. Reporters will be credited unless they prefer to remain anonymous.

## Scope

In-scope vulnerabilities include (but aren't limited to):

- Auth bypass or token validation flaws (`apps/api/src/core/middleware/auth.middleware.ts`)
- Role-escalation / RBAC bypass (`apps/api/src/core/middleware/require_role.ts`, mobile `app_router.dart` redirects)
- Reporter-identity leakage on admin endpoints (`/admin/*`, `/mod/*`) — payloads must never contain `reporter_user_id`, email, display name, handle, or avatar (PRD FR-7.4 + FR-7.8)
- Server-side request forgery, SQL/NoSQL injection, or other injection in any api route
- Leakage of secrets via logs, responses, or generated artefacts
- Mobile-side handling of sensitive data (token storage, Firebase config exposure, biometric state in `flutter_secure_storage`)
- Misconfigured Supabase RLS / storage permissions
- Misconfigured Firestore rules (`firestore.rules`) — `alerts/**` must be read-public / write-server-only; `my-reports/{uid}/items/**` must be read-iff-owner / write-server-only

Out-of-scope:

- Issues in third-party services (Firebase, Supabase, Gemini) — please report those upstream
- Denial-of-service via volumetric traffic
- Self-XSS or social engineering

## Internal controls (project-side)

These are the controls the team enforces in CI + code review. External researchers don't need to verify these — they're listed for transparency:

| Control | Where | Verified by |
| --- | --- | --- |
| Secret scan | `gitleaks detect` in `.github/workflows/security.yml`; baseline `git grep -nE 'AIza[0-9A-Za-z\-_]{20,}\|sk-[A-Za-z0-9]{20,}\|firebase-adminsdk\|service-account\|BEGIN PRIVATE KEY'` | `security-reviewer` agent on every PR; CI nightly |
| Dependency audit | `bun audit` (CI fails on high/critical) | CI |
| Static analysis | `dart analyze --fatal-infos`, `bun run typecheck` | CI |
| Auth gate on mutating routes | every Elysia route uses `requireAuth()` or `requireRole(...)` | `security-reviewer` agent + architect agent |
| Reporter anonymisation | admin route serializers strip reporter fields; verified via API response shape test | `security-reviewer` agent |
| Firestore rules | emulator-based tests for the policy table above | `qa` agent (rules tests) + `security-reviewer` agent |
| Biometric gate | Android-only; Web no-op; biometric never replaces password — only unlocks stored token | `security-reviewer` agent on PR touching `biometric_service.dart` |
| `.env` hygiene | `.env*` gitignored; `.env.example` is the only template committed | `security-reviewer` agent |

The agent definitions live in `.claude/agents/security-reviewer.md`. Workflow described in `docs/ai-workflow.md`.
