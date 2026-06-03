import 'package:flutter/material.dart';

/// Opaque, branded full-screen cover. Used as the cold-start splash (while the
/// lock config loads) and as the privacy screen painted over the app when it
/// is backgrounded, so the OS app-switcher thumbnail never shows content.
class AppLockCover extends StatelessWidget {
  const AppLockCover({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      child: Center(
        child: Icon(Icons.shield_outlined, size: 56, color: cs.primary),
      ),
    );
  }
}
