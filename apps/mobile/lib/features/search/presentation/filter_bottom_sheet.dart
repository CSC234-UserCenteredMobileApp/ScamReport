// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../domain/scam_type_item.dart';
import 'search_providers.dart';

Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sortBy = ref.watch(searchSortByProvider);
    final selectedCodes = ref.watch(searchScamTypeFilterProvider);
    final scamTypesAsync = ref.watch(scamTypesProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Column(
          children: [
            _SheetHandle(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    l10n.searchFilterTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ref.read(searchSortByProvider.notifier).state = 'latest';
                      ref.read(searchScamTypeFilterProvider.notifier).state =
                          const [];
                    },
                    child: Text(l10n.searchFilterReset),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  _SectionLabel(l10n.searchFilterSortLabel),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(l10n.searchFilterSortLatest,
                            style: const TextStyle(fontSize: 14)),
                        value: 'latest',
                        groupValue: sortBy,
                        onChanged: (v) =>
                            ref.read(searchSortByProvider.notifier).state = v!,
                      ),
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(l10n.searchFilterSortReporters,
                            style: const TextStyle(fontSize: 14)),
                        value: 'reportCount',
                        groupValue: sortBy,
                        onChanged: (v) =>
                            ref.read(searchSortByProvider.notifier).state = v!,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel(l10n.searchFilterScamTypeLabel),
                  const SizedBox(height: 8),
                  scamTypesAsync.when(
                    data: (types) => _ScamTypeCheckboxList(
                      types: types,
                      selected: selectedCodes,
                      onToggle: (code) {
                        final current = List<String>.from(
                          ref.read(searchScamTypeFilterProvider),
                        );
                        if (current.contains(code)) {
                          current.remove(code);
                        } else {
                          current.add(code);
                        }
                        ref.read(searchScamTypeFilterProvider.notifier).state =
                            List.unmodifiable(current);
                      },
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.searchFilterApply),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.06,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _ScamTypeCheckboxList extends StatelessWidget {
  const _ScamTypeCheckboxList({
    required this.types,
    required this.selected,
    required this.onToggle,
  });

  final List<ScamTypeItem> types;
  final List<String> selected;
  final void Function(String code) onToggle;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return Column(
      children: types.map((type) {
        final label = locale == 'th' ? type.labelTh : type.labelEn;
        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(label, style: const TextStyle(fontSize: 14)),
          value: selected.contains(type.code),
          onChanged: (_) => onToggle(type.code),
        );
      }).toList(),
    );
  }
}
