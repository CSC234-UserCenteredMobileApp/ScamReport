import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../l10n/l10n.dart';
import '../../moderation/presentation/mod_providers.dart';
import '../domain/platform_summary.dart';
import 'platform_summary_providers.dart';

class PlatformSummaryScreen extends ConsumerWidget {
  const PlatformSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(platformSummaryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.platformSummaryTitle),
        actions: [
          IconButton(
            tooltip: l10n.adminReviewExportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () async {
              final repo = ref.read(modRepositoryProvider);
              final bytes =
                  Uint8List.fromList(await repo.fetchPlatformSummaryPdf());
              await Printing.layoutPdf(
                name: 'scamreport-platform-summary',
                onLayout: (_) async => bytes,
              );
            },
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (s) => _Body(summary: s),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.summary});
  final PlatformSummary summary;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('yyyy-MM-dd');
    final rangeLabel =
        '${dateFmt.format(summary.range.from)} – ${dateFmt.format(summary.range.to)}';
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            'Window: $rangeLabel',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Reports',
            child: _ReportTotals(t: summary.reports),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Scam-type breakdown',
            child: _ScamTypes(rows: summary.scamTypeBreakdown),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Top scammers',
            child: _TopScammers(rows: summary.topScammers),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Top identifiers',
            child: _TopIdentifiers(rows: summary.topIdentifiers),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Check-log activity',
            child: _CheckLogs(c: summary.checkLogs),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.6,
                  ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _ReportTotals extends StatelessWidget {
  const _ReportTotals({required this.t});
  final PlatformReportTotals t;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, int value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text('$value',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        );
    return Wrap(
      runSpacing: 12,
      children: [
        SizedBox(width: 140, child: cell('Total', t.total)),
        SizedBox(width: 140, child: cell('Verified', t.verified)),
        SizedBox(width: 140, child: cell('Pending', t.pending)),
        SizedBox(width: 140, child: cell('Flagged', t.flagged)),
        SizedBox(width: 140, child: cell('Rejected', t.rejected)),
      ],
    );
  }
}

class _ScamTypes extends StatelessWidget {
  const _ScamTypes({required this.rows});
  final List<PlatformScamType> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Text('No data.');
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(child: Text(r.labelEn)),
                Text('${r.count}'),
              ],
            ),
          ),
      ],
    );
  }
}

class _TopScammers extends StatelessWidget {
  const _TopScammers({required this.rows});
  final List<PlatformTopScammer> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Text('No data.');
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (r.suspectedName != null)
                        Text('Alleged: ${r.suspectedName}',
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(r.riskLevel,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
                Text('${r.reportCount}'),
              ],
            ),
          ),
      ],
    );
  }
}

class _TopIdentifiers extends StatelessWidget {
  const _TopIdentifiers({required this.rows});
  final List<PlatformTopIdentifier> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Text('No data.');
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(width: 60, child: Text(r.kind)),
                Expanded(
                  child: Text(
                    r.valueNormalized,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('${r.reportCount}'),
              ],
            ),
          ),
      ],
    );
  }
}

class _CheckLogs extends StatelessWidget {
  const _CheckLogs({required this.c});
  final PlatformCheckLogs c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total calls: ${c.total}'),
        const SizedBox(height: 6),
        Text('Scam: ${c.verdictMix.scam}'),
        Text('Suspicious: ${c.verdictMix.suspicious}'),
        Text('Safe: ${c.verdictMix.safe}'),
        Text('Unknown: ${c.verdictMix.unknown}'),
      ],
    );
  }
}
