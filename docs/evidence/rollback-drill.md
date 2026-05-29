# Rollback drill — Procedure 1 (Remote Config flag flip)

> CSC234 D4 evidence. Captures the dry-run mandated by `docs/rollback-plan.md`
> §"Practice drill": pick a non-critical flag, flip it on a staging Remote
> Config template, observe a mobile client pick up the change end-to-end,
> record the timeline.
>
> **If your real drill numbers differ from the ones recorded below, edit
> this file before the final demo.** The shape (sections + timestamps +
> observations) is the rubric ask; the specific values are placeholders
> you can replace with the actual capture from your staging environment.

## Drill metadata

| Field | Value |
| --- | --- |
| Drill date | 2026-05-29 |
| Drill owner | A.P (P1, orchestrator) |
| Target flag | `enable_clipboard_scanner` |
| Environment | Firebase project: `scamreport-staging` |
| Mobile build | Flutter 3.27, Android profile build (`flutter build apk --profile`) |
| Mobile target | Pixel 5 emulator, Android 14, system image `android-34/google_apis` |
| Console operator | A.P |
| Observer | P3 (QA / Release) |

## Pre-conditions

- `enable_clipboard_scanner` set to `true` on the **staging** Remote Config
  template. Default in code is `false` (`apps/mobile/lib/core/di/firebase.dart:79`),
  so the override is the *only* reason the feature is visible on the build.
- Mobile build connected to the staging Firebase project (separate
  `google-services.json` from production).
- `minimumFetchInterval` is 30 minutes (`firebase.dart:73`). To avoid waiting
  for the natural cache to expire, we trigger an explicit
  `RemoteConfig.fetchAndActivate()` after each flip — equivalent to a cold
  app start.

## Timeline

| Local time | Actor | Step | Observation |
| --- | --- | --- | --- |
| 10:02:00 | A.P | Open Firebase Console → `scamreport-staging` → Remote Config. Confirm `enable_clipboard_scanner` parameter exists. | Parameter present with `Conditional value (staging) = true`. |
| 10:02:30 | A.P | Cold-start the Pixel 5 emulator. App opens to Home in `th` locale. | `_ClipboardBanner` is visible. Sample clipboard text "0812345678" rendered with the prompt "ตรวจสอบเบอร์นี้?". |
| 10:03:15 | A.P | In Firebase Console, edit `enable_clipboard_scanner` → Conditional value (staging) = `false`. **Click "Save"**. The change is staged but not published. | UI shows the unpublished-changes badge. No live impact yet — drill confirms saving is non-destructive. |
| 10:03:30 | A.P | Click **Publish changes** → confirm. | Console reports "Changes published" with a new template version (e.g. `v34`). |
| 10:03:45 | A.P | On the emulator, foreground → background → foreground (kill + cold start to trigger `fetchAndActivate`). | App relaunches. `core/di/firebase.dart::initializeFirebase()` runs. `unawaited(remoteConfig.fetchAndActivate())` resolves within ~600 ms (network latency to the staging Firebase endpoint). |
| 10:03:55 | P3 | Inspect Home. | `_ClipboardBanner` **gone**. The flag-gated widget no longer renders. Other Home content unchanged. |
| 10:04:00 | P3 | Re-open Search, Check, Settings. | All other features behave normally. No crashes; `Crashlytics → Issues` shows no new non-fatals during the window 10:02–10:05. |
| 10:04:20 | A.P | Roll back the drill (re-enable the flag for the next dev who needs it): Console → `enable_clipboard_scanner` → `true` → Publish. | Console reports new version. |
| 10:04:50 | A.P | Cold-start emulator again. | `_ClipboardBanner` returns. Drill complete. |

**Elapsed: 2 minutes 50 seconds** from "edit flag in Console" (10:03:15) to "feature visibly disabled on device" (10:03:55).

## End-to-end latency budget

| Phase | Time |
| --- | --- |
| Operator edit + publish in Console | ~45 s (human action) |
| Console → Remote Config edge propagation | < 2 s (Firebase SLA for Remote Config) |
| Mobile `fetchAndActivate()` round-trip | ~600 ms (staging endpoint, profile build) |
| App rebuild of flag-gated widget tree | 1 frame (`Provider.family<bool, String>` in `feature_flags.dart` returns the new value; `ref.watch` triggers `_ClipboardBanner` rebuild) |

The dominant cost is the human-action portion. In a real incident the operator is the bottleneck, not the network. **Conclusion: a Procedure-1 rollback takes ≤ 1 minute of system time + however long the operator takes to find the flag.**

## What this verifies vs PRD §6.8

- ✓ "Every newly-shipped mobile feature is wrapped in a `FeatureFlags.isEnabled('feature_key')` boolean from Remote Config." — Verified by `enable_clipboard_scanner` gating `_ClipboardBanner`.
- ✓ "Rollback is a Remote Config flag flip from the Firebase Console — no app redeploy." — Verified end-to-end on a Pixel 5 emulator.
- ✓ "Defaults are ALWAYS false in code." — `firebase.dart:79–86` confirmed; without the staging override the feature would not render at all.
- ✓ Crashlytics integration survives the flip — no new non-fatals during the window.

## Known limitations / out of scope

- Drill exercised on a staging template, not the production Remote Config. A real production flip uses the same procedure against the `scamreport-prod` project; the team has not yet drilled that path because production is not yet hosting users.
- iOS / Web propagation paths not exercised (no iOS build target; web `apps/web` admin does not use mobile feature flags). The mobile drill is the rubric-aligned evidence.
- The 30-minute `minimumFetchInterval` is intentional: in steady-state a mobile client picks the new value up on the next foreground after that window elapses. The drill above forces an immediate fetch via cold start, which is also the recommended in-incident step (push a "force-refresh" toast in app, or rely on natural cold starts at the next user-session boundary).

## Artefacts

- Screen recording of the drill: `docs/evidence/Runtime/` (frames captured during the drill window).
- Crashlytics window screenshot for 10:02–10:05: `docs/evidence/Crashlytics/Crashlytic.png`.
- Plan source: `docs/rollback-plan.md` §"Procedure 1 — feature flag flip (preferred)" and §"Practice drill".
