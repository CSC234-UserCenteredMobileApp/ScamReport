import 'package:flutter/material.dart';

/// Horizontally scrollable row of [FilterChip] widgets for narrowing list content.
/// Generic over [T] so it works with any filter type.
class FilterChipBar<T> extends StatelessWidget {
  const FilterChipBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(BuildContext context, T option) labelBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option == selected;
          return FilterChip(
            label: Text(labelBuilder(context, option)),
            selected: isSelected,
            onSelected: (_) => onSelected(option),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
