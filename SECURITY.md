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
- Server-side request forgery, SQL/NoSQL injection, or other injection in any api route
- Leakage of secrets via logs, responses, or generated artefacts
- Mobile-side handling of sensitive data (token storage, Firebase config exposure)
- Misconfigured Supabase RLS / storage permissions

Out-of-scope:

- Issues in third-party services (Firebase, Supabase, Gemini) — please report those upstream
- Denial-of-service via volumetric traffic
- Self-XSS or social engineering
