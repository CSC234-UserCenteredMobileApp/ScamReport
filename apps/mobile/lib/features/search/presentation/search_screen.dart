import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/report_card.dart';
import '../../../l10n/l10n.dart';
import 'filter_bottom_sheet.dart';
import 'search_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    ref.read(searchQueryProvider.notifier).state = _controller.text;
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _hasActiveFilters(WidgetRef ref) {
    return ref.watch(searchScamTypeFilterProvider).isNotEmpty ||
        ref.watch(searchSortByProvider) != 'latest';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasFilters = _hasActiveFilters(ref);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.searchTitle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.searchInputHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (_, value, __) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _controller.clear();
                            _focusNode.requestFocus();
                          },
                        ),
                ),
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                ActionChip(
                  avatar: Badge(
                    isLabelVisible: hasFilters,
                    smallSize: 6,
                    child: const Icon(Icons.tune, size: 16),
                  ),
                  label: Text(l10n.searchFilterTitle),
                  onPressed: () => showFilterSheet(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Expanded(child: _ResultsBody()),
        ],
      ),
    );
  }
}

class _ResultsBody extends ConsumerWidget {
  const _ResultsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final q = ref.watch(searchQueryProvider);
    final codes = ref.watch(searchScamTypeFilterProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    // Empty state — nothing typed and no filter
    if (q.trim().isEmpty && codes.isEmpty) {
      return _EmptyPrompt(message: l10n.searchEmptyPrompt);
    }

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.loadFailedRetry,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(searchResultsProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (reports) {
        if (reports.isEmpty) {
          return _EmptyPrompt(message: l10n.searchNoResults);
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => ReportCard(
            report: reports[i],
            onTap: () => context.push('/report-detail/${reports[i].id}'),
          ),
        );
      },
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}
