import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/l10n.dart';

const _channel = MethodChannel('com.example.mobile/call_screening');

class PermissionCard extends StatelessWidget {
  const PermissionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: colors.onSecondaryContainer),
                const SizedBox(width: 8),
                Text(
                  context.l10n.callScreeningSetupTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.callScreeningSetupBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () async {
                try {
                  await _channel.invokeMethod<void>('openScreeningSettings');
                } on MissingPluginException {
                  // Non-Android environment
                }
              },
              child: Text(context.l10n.callScreeningSetupAction),
            ),
          ],
        ),
      ),
    );
  }
}
