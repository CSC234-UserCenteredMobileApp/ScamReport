import 'package:flutter/material.dart';

import 'legal_doc.dart';

const _kPrivacySections = [
  LegalSection(
    heading: 'What we collect',
    body:
        'We collect the email address you sign up with, content of reports you '
        'submit, and search queries to monitor for abuse. We never collect your '
        'contact list, location history, or SMS message bodies.',
  ),
  LegalSection(
    heading: 'How we use it',
    body:
        'Reports approved by moderators are shared publicly without your '
        'identity. Search queries are logged per user for abuse detection only.',
  ),
  LegalSection(
    heading: 'Your rights (PDPA)',
    body:
        'Under Thailand\'s PDPA you may request access, correction, or deletion '
        'of your personal data. We purge personal data within 7 days of an '
        'account deletion request.',
  ),
  LegalSection(
    heading: 'On-device processing',
    body:
        'SMS smishing detection (Android only) extracts URLs and phone numbers '
        'from your device. Only the extracted identifiers are sent to our '
        'servers — never the raw SMS body.',
  ),
];

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy'), centerTitle: true),
      body: const LegalDoc(
        lastUpdated: 'April 25, 2026',
        sections: _kPrivacySections,
      ),
    );
  }
}
