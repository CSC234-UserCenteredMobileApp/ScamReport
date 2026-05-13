import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import 'mod_providers.dart';

/// Horizontal scrollable scam-type filter rail above the queue. Mirrors
/// `FilterChipBar` style but is bound directly to
/// [modScamTypeFilterProvider] (a `Set<String>` of codes) so multi-select
/// works without lifting state into the screen.
class ModScamTypeChipRail extends ConsumerWidget {
  const ModScamTypeChipRail({super.key});

  // Taxonomy mirrors `scam_types` seed (DATABASE_DESIGN §4.3). Keeping the
  // list inline avoids an extra round-trip to a scam-types endpoint for the
  // queue screen; the admin user can still see codes they don't recognise
  // in the row chip itself.
  static const _types = <_ScamTypeChip>[
    _ScamTypeChip('phone_impersonation'),
    _ScamTypeChip('phishing_sms'),
    _ScamTypeChip('fake_qr'),
    _ScamTypeChip('ecommerce_fraud'),
    _ScamTypeChip('investment'),
    _ScamTypeChip('romance'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final selected = ref.watch(modScamTypeFilterProvider);
    final isAll = selected.isEmpty;

    Widget chipFor(String? code, String label) {
      final isSelected = code == null ? isAll : selected.contains(code);
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
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
            if (code == null) {
              ref.read(modScamTypeFilterProvider.notifier).state =
                  const <String>{};
              return;
            }
            final next = Set<String>.from(selected);
            if (next.contains(code)) {
              next.remove(code);
            } else {
              next.add(code);
            }
            ref.read(modScamTypeFilterProvider.notifier).state = next;
          },
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chipFor(null, l10n.modFilterChipAllTypes),
          for (final t in _types) chipFor(t.code, t.label(l10n)),
        ],
      ),
    );
  }
}

class _ScamTypeChip {
  const _ScamTypeChip(this.code);
  final String code;

  String label(AppLocalizations l10n) {
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
}
