import 'package:flutter/material.dart';

/// Row of [length] dots; the first [filled] are solid to show entry progress.
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.filled,
    this.length = 6,
    this.error = false,
  });

  final int filled;
  final int length;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = error ? cs.error : cs.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final isFilled = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? active : Colors.transparent,
            border: Border.all(
              color: isFilled ? active : cs.outlineVariant,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}
