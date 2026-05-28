// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import 'mod_providers.dart';

/// Bottom sheet with the full Moderation Queue filter + sort surface.
/// Mirrors the search screen's [filter_bottom_sheet] for visual parity:
/// draggable handle, sticky header with Reset, scrollable body, sticky Apply
/// footer.
Future<void> showModFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const ModFilterSheet(),
  );
}

@visibleForTesting
class ModFilterSheet extends ConsumerWidget {
  const ModFilterSheet({super.key});

  static const _scamTypes = <String>[
    'phone_impersonation',
    'phishing_sms',
    'fake_qr',
    'ecommerce_fraud',
    'investment',
    'romance',
  ];

  static const _aiConfidences = <String>[
    'high',
    'medium',
    'low',
    'unknown',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Column(
          children: [
            const _SheetHandle(),
            _Header(onReset: () => resetModFilters(ref)),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  _SectionLabel(l10n.modFilterSectionSort),
                  const SizedBox(height: 4),
                  const _SortRadios(),
                  const SizedBox(height: 16),
                  _SectionLabel(l10n.modFilterSectionScamType),
                  const SizedBox(height: 4),
                  const _ScamTypeCheckboxes(codes: _scamTypes),
                  const SizedBox(height: 16),
                  _SectionLabel(l10n.modFilterSectionAiConfidence),
                  const SizedBox(height: 8),
                  const _AiConfidenceChips(tiers: _aiConfidences),
                  const SizedBox(height: 16),
                  _SectionLabel(l10n.modFilterSectionFlags),
                  _ToggleRow(
                    icon: Icons.bolt_outlined,
                    labelKey: _ToggleLabel.priority,
                    provider: modPriorityOnlyProvider,
                  ),
                  _ToggleRow(
                    icon: Icons.attach_file_outlined,
                    labelKey: _ToggleLabel.hasEvidence,
                    provider: modHasEvidenceOnlyProvider,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 8,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.modFilterApply),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Subwidgets
// ---------------------------------------------------------------------------

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

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

class _Header extends StatelessWidget {
  const _Header({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Text(
            l10n.modFilterTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onReset,
            child: Text(l10n.modFilterReset),
          ),
        ],
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
            letterSpacing: 0.6,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _SortRadios extends ConsumerWidget {
  const _SortRadios();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newestFirst = ref.watch(modSortNewestFirstProvider);
    final l10n = context.l10n;
    return Column(
      children: [
        RadioListTile<bool>(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(l10n.modSortOldestFirst,
              style: const TextStyle(fontSize: 14)),
          value: false,
          groupValue: newestFirst,
          onChanged: (v) =>
              ref.read(modSortNewestFirstProvider.notifier).state = v ?? false,
        ),
        RadioListTile<bool>(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(l10n.modSortNewestFirst,
              style: const TextStyle(fontSize: 14)),
          value: true,
          groupValue: newestFirst,
          onChanged: (v) =>
              ref.read(modSortNewestFirstProvider.notifier).state = v ?? true,
        ),
      ],
    );
  }
}

class _ScamTypeCheckboxes extends ConsumerWidget {
  const _ScamTypeCheckboxes({required this.codes});
  final List<String> codes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(modScamTypeFilterProvider);
    final l10n = context.l10n;

    String labelFor(String code) {
      switch (code) {
        case 'phone_impersonation':
          return l10n.scamTypePhoneImpersonation;
        case 'phishing_sms':
          return l10n.scamTypePhishingSms;
        case 'fake_qr':
          return l10n.scamTypeFakeQr;
        case 'ecommerce_fraud':
          return l10n.scamTypeEcommerce;
        case 'investment':
          return l10n.scamTypeInvestment;
        case 'romance':
          return l10n.scamTypeRomance;
        default:
          return code;
      }
    }

    return Column(
      children: codes.map((code) {
        final isSelected = selected.contains(code);
        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(labelFor(code), style: const TextStyle(fontSize: 14)),
          value: isSelected,
          onChanged: (_) {
            final next = Set<String>.from(selected);
            if (isSelected) {
              next.remove(code);
            } else {
              next.add(code);
            }
            ref.read(modScamTypeFilterProvider.notifier).state = next;
          },
        );
      }).toList(),
    );
  }
}

class _AiConfidenceChips extends ConsumerWidget {
  const _AiConfidenceChips({required this.tiers});
  final List<String> tiers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(modAiConfidenceFilterProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);

    String labelFor(String tier) {
      switch (tier) {
        case 'high':
          return l10n.aiConfidenceHigh;
        case 'medium':
          return l10n.aiConfidenceMedium;
        case 'low':
          return l10n.aiConfidenceLow;
        default:
          return l10n.aiConfidenceUnknown;
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tiers.map((tier) {
        final isSelected = selected.contains(tier);
        return FilterChip(
          label: Text(labelFor(tier)),
          selected: isSelected,
          showCheckmark: false,
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          selectedColor: theme.colorScheme.primary,
          side: BorderSide(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
          onSelected: (_) {
            final next = Set<String>.from(selected);
            if (isSelected) {
              next.remove(tier);
            } else {
              next.add(tier);
            }
            ref.read(modAiConfidenceFilterProvider.notifier).state = next;
          },
        );
      }).toList(),
    );
  }
}

enum _ToggleLabel { priority, hasEvidence }

class _ToggleRow extends ConsumerWidget {
  const _ToggleRow({
    required this.icon,
    required this.labelKey,
    required this.provider,
  });

  final IconData icon;
  final _ToggleLabel labelKey;
  final StateProvider<bool> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);
    final l10n = context.l10n;
    final label = labelKey == _ToggleLabel.priority
        ? l10n.modFilterPriorityOnly
        : l10n.modFilterHasEvidence;

    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      secondary:
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      value: value,
      onChanged: (v) => ref.read(provider.notifier).state = v,
    );
  }
}
