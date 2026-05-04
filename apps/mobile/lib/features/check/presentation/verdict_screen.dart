import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/verdict_pill.dart';
import '../../../l10n/l10n.dart';
import '../domain/check_result.dart';
import 'check_providers.dart';

class VerdictScreen extends ConsumerWidget {
  const VerdictScreen({super.key, required this.query});

  final CheckQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(checkResultProvider(query));
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: resultAsync.when(
          loading: () => _LoadingView(l: l),
          error: (e, _) => _ErrorView(
            error: e.toString(),
            onRetry: () => ref.invalidate(checkResultProvider(query)),
          ),
          data: (result) => _ResultView(query: query, result: result, l: l),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading state
// ---------------------------------------------------------------------------
class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(l.verdictChecking,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            l.verdictCheckingSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result state
// ---------------------------------------------------------------------------
class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.query,
    required this.result,
    required this.l,
  });

  final CheckQuery query;
  final CheckResult result;
  final AppLocalizations l;

  String _subtitle() => switch (result.verdict) {
        'scam' => l.verdictSubtitleScam,
        'suspicious' => l.verdictSubtitleSuspicious,
        'safe' => l.verdictSubtitleSafe,
        _ => l.verdictSubtitleUnknown,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cached result banner
          if (result.fromCache)
            MaterialBanner(
              backgroundColor: Colors.amber.shade100,
              content: Text(l.verdictCachedResult,
                  style: const TextStyle(color: Colors.black87)),
              actions: const [SizedBox.shrink()],
            ),

          // Full-bleed verdict pill (~40% of screen)
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.4,
            child: VerdictPill(verdict: result.verdict),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Subtitle
                Text(
                  _subtitle(),
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // YOU CHECKED section
                Text(
                  l.verdictYouChecked,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    query.payload,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),

                // Matched reports count
                if (result.matchedCount > 0) ...[
                  const SizedBox(height: 16),
                  Text(
                    l.verdictMatchedReports(result.matchedCount),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 24),

                // See matched reports (only when matches exist)
                if (result.matchedCount > 0)
                  OutlinedButton(
                    onPressed: () => context.push('/feed'),
                    child: Text(l.verdictSeeReports),
                  ),

                const SizedBox(height: 12),

                // Report this (always visible)
                OutlinedButton(
                  onPressed: () => context.push('/submit-report'),
                  child: Text(l.verdictReportThis),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
