import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import 'mod_providers.dart';

/// Compact search field for the Moderation Queue header. Debounces input
/// 250 ms before writing to [modSearchQueryProvider] so the composed
/// selector is not recomputed on every keystroke.
class ModSearchField extends ConsumerStatefulWidget {
  const ModSearchField({super.key});

  @override
  ConsumerState<ModSearchField> createState() => _ModSearchFieldState();
}

class _ModSearchFieldState extends ConsumerState<ModSearchField> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Reflect any pre-existing provider value (e.g. on restoration).
    _controller.text = ref.read(modSearchQueryProvider);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      ref.read(modSearchQueryProvider.notifier).state = value;
    });
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    ref.read(modSearchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = _controller.text.isNotEmpty;
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: hasText
            ? IconButton(
                tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
                icon: const Icon(Icons.close, size: 18),
                onPressed: _clear,
              )
            : null,
        hintText: context.l10n.modSearchHint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
