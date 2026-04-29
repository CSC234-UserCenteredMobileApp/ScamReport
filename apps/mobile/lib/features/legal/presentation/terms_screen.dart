import 'package:flutter/material.dart';

import 'legal_doc.dart';

const _kTermsSections = [
  LegalSection(
    heading: 'Eligibility',
    body:
        'You must be at least 13 years old to use ScamReport. By submitting a '
        'report you confirm that the information is truthful to the best of '
        'your knowledge.',
  ),
  LegalSection(
    heading: 'Acceptable use',
    body:
        'You may not submit false or malicious reports, use ScamReport to spam '
        'or harass others, or scrape data from the platform by automated means '
        'without written permission.',
  ),
  LegalSection(
    heading: 'Content ownership',
    body:
        'Reports you submit are licensed to ScamReport for public display and '
        'research purposes. You retain ownership of your original content but '
        'grant us a non-exclusive, royalty-free licence to use it.',
  ),
  LegalSection(
    heading: 'Termination',
    body:
        'We may suspend or delete accounts that repeatedly violate these terms. '
        'You may request deletion of your account and associated data at any '
        'time from the Settings screen.',
  ),
];

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service'), centerTitle: true),
      body: const LegalDoc(
        lastUpdated: 'April 25, 2026',
        sections: _kTermsSections,
      ),
    );
  }
}
