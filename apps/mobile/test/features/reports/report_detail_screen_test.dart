import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/api_client.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/reports/domain/report_detail.dart';
import 'package:mobile/features/reports/presentation/report_detail_providers.dart';
import 'package:mobile/features/reports/presentation/report_detail_screen.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _themed(Widget widget) {
  return MaterialApp(
    theme: lightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: widget,
  );
}

ReportDetail fakeReport({
  String? targetIdentifier,
  String? targetIdentifierKind,
  List<EvidenceFileItem> evidenceFiles = const [],
}) =>
    ReportDetail(
      id: 'aaaaaaaa-0000-0000-0000-000000000001',
      title: 'Fake Kerry parcel SMS with phishing link',
      description: 'A widely-circulated SMS scam impersonating Kerry Express.',
      scamTypeCode: 'phishing_sms',
      scamTypeLabelEn: 'Phishing SMS',
      scamTypeLabelTh: 'ฟิชชิง SMS',
      verifiedAt: DateTime.utc(2026, 4, 22),
      reportCount: 142,
      targetIdentifier: targetIdentifier,
      targetIdentifierKind: targetIdentifierKind,
      evidenceFiles: evidenceFiles,
    );

const _id = 'aaaaaaaa-0000-0000-0000-000000000001';

void main() {
  group('ReportDetailScreen', () {
    testWidgets('shows skeleton while loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            httpClientProvider.overrideWithValue(
              MockClient((_) => Completer<http.Response>().future),
            ),
          ],
          child: _themed(const ReportDetailScreen(id: _id)),
        ),
      );

      await tester.pump();

      // Skeleton renders AppBar + no content text
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Fake Kerry parcel SMS with phishing link'), findsNothing);
    });

    testWidgets('renders title and description when data loads', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportDetailProvider(_id).overrideWith((ref) async => fakeReport()),
          ],
          child: _themed(const ReportDetailScreen(id: _id)),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Fake Kerry parcel SMS with phishing link'),
        findsOneWidget,
      );
      expect(
        find.text('A widely-circulated SMS scam impersonating Kerry Express.'),
        findsOneWidget,
      );
    });

    testWidgets('renders verified pill and scam type chip', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportDetailProvider(_id).overrideWith((ref) async => fakeReport()),
          ],
          child: _themed(const ReportDetailScreen(id: _id)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Phishing SMS'), findsOneWidget);
    });

    testWidgets('renders report count in meta row', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportDetailProvider(_id).overrideWith((ref) async => fakeReport()),
          ],
          child: _themed(const ReportDetailScreen(id: _id)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('142 reports'), findsOneWidget);
    });

    testWidgets('shows identifier section when targetIdentifier present',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportDetailProvider(_id).overrideWith(
              (ref) async => fakeReport(
                targetIdentifier: 'kerry-th-track.net',
                targetIdentifierKind: 'url',
              ),
            ),
          ],
          child: _themed(const ReportDetailScreen(id: _id)),
        ),
      );

      await tester.pumpAndSettle();

      // URL defanged with [.]
      expect(find.text('kerry-th-track[.]net'), findsOneWidget);
    });

    testWidgets('hides identifier section when targetIdentifier is null',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportDetailProvider(_id).overrideWith((ref) async => fakeReport()),
          ],
          child: _themed(const ReportDetailScreen(id: _id)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('REPORTED IDENTIFIER'), findsNothing);
    });

    testWidgets('formats Thai phone number with spaces', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportDetailProvider(_id).overrideWith(
              (ref) async => fakeReport(
                targetIdentifier: '+66844192270',
                targetIdentifierKind: 'phone',
              ),
            ),
          ],
          child: _themed(const ReportDetailScreen(id: _id)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('+66 84 419 2270'), findsOneWidget);
    });

    testWidgets('renders evidence grid when files present', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportDetailProvider(_id).overrideWith(
              (ref) async => fakeReport(
                evidenceFiles: [
                  const EvidenceFileItem(
                    id: 'bbbbbbbb-0000-0000-0000-000000000001',
                    signedUrl: null,
                    kind: 'image',
                    mimeType: 'image/jpeg',
                  ),
                ],
              ),
            ),
          ],
          child: _themed(const ReportDetailScreen(id: _id)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('EVIDENCE'), findsOneWidget);
      expect(find.text('Screenshot 1'), findsOneWidget);
    });

    testWidgets('hides evidence section when no files', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportDetailProvider(_id).overrideWith((ref) async => fakeReport()),
          ],
          child: _themed(const ReportDetailScreen(id: _id)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('EVIDENCE'), findsNothing);
    });

    testWidgets('shows CTA button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportDetailProvider(_id).overrideWith((ref) async => fakeReport()),
          ],
          child: _themed(const ReportDetailScreen(id: _id)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Report a similar scam'), findsOneWidget);
    });

    testWidgets('shows error state with retry when fetch fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportDetailProvider(_id).overrideWith(
              (ref) => Future<ReportDetail>.error(Exception('network')),
            ),
          ],
          child: _themed(const ReportDetailScreen(id: _id)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load — tap to retry'), findsOneWidget);
    });

    testWidgets('share icon present in app bar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportDetailProvider(_id).overrideWith((ref) async => fakeReport()),
          ],
          child: _themed(const ReportDetailScreen(id: _id)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    });
  });
}
