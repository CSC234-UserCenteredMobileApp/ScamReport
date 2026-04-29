import 'package:flutter/material.dart';

class LegalSection {
  const LegalSection({required this.heading, required this.body});
  final String heading;
  final String body;
}

class LegalDoc extends StatelessWidget {
  const LegalDoc({
    super.key,
    required this.lastUpdated,
    required this.sections,
  });

  final String lastUpdated;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last updated: $lastUpdated',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < sections.length; i++) ...[
            Text(
              '${i + 1}. ${sections[i].heading}',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(sections[i].body, style: tt.bodyMedium),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
