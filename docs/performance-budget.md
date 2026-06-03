# Performance Budget — ScamReport mobile

Referenced by [`.claude/agents/qa.md`](../.claude/agents/qa.md) §Performance gates.
Last reviewed: 2026-06-03.

## Budgets

| Metric | Budget | How measured |
|---|---|---|
| App cold start (to first frame) | < 2 s | `flutter run --profile` on a Pixel-5-class device, DevTools timeline |
| Scroll jank on long lists | 60 fps (no frame > 16 ms sustained) | DevTools performance overlay on Feed + Search results |
| Web initial bundle delta per PR | ≤ +50 KB | `flutter build web` size diff in PR review |
| Network image re-downloads | 0 on revisit (memory/disk cache hit) | `cached_network_image` cache, see below |
| Upload image size | ≤ 1920 px wide, JPEG quality 80 | `image_picker` params at all `pickImage` call sites |

## List rendering policy

- **Dynamic / unbounded collections** (feed, search results, notifications,
  moderation queue) must use `ListView.builder` / `ListView.separated`
  (lazy item building). Current usage: 10 builder/separated sites — compliant.
- **Bounded static content** (settings page, filter bottom sheets, modal
  option lists) may use `ListView(children: [...])`. The 9 current
  `ListView(children:)` sites were audited 2026-06-03: all are bounded
  (< ~20 fixed children) — reviewed-OK, not a violation.
- Adding a new `ListView(children:)` over API-driven data = review blocker.

## Image policy

- **Render:** all network images go through `CachedNetworkImage`
  (memory + disk cache; no repeated downloads on tab revisits). Raw
  `Image.network` is banned — 9 call sites migrated 2026-06-03
  (alert/report cards, detail screens, Ask-AI attachments, admin review,
  announcement editor).
- **Upload:** `image_picker` calls pass `imageQuality: 80, maxWidth: 1920`
  (Ask-AI attachment picker + report evidence picker). API enforces a
  10 MB hard cap server-side.

## Known deferred items

- No `flutter build web --analyze-size` automation; bundle delta is checked
  manually in PR review.
- Profile-build startup trace is a manual gate before demo days, not CI.
