import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/mod_queue_row.dart';
import 'package:mobile/features/moderation/domain/mod_report.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _themed(Widget widget, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    theme: lightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(body: widget),
  );
}

ModQueueItem _item({
  String status = 'pending',
  bool priorityFlag = false,
  int evidenceCount = 2,
  String? lastRemarkByAdmin,
  DateTime? submittedAt,
}) =>
    ModQueueItem(
      id: 'r1',
      title: 'Fake Kerry parcel SMS',
      scamTypeCode: 'phishing_sms',
      scamTypeLabelEn: 'Phishing SMS',
      scamTypeLabelTh: 'ฟิชชิง SMS',
      submittedAt: submittedAt ?? DateTime.now().subtract(const Duration(hours: 3)),
      status: status,
      priorityFlag: priorityFlag,
      evidenceCount: evidenceCount,
      lastRemarkByAdmin: lastRemarkByAdmin,
    );

void main() {
  group('ModQueueRow', () {
    testWidgets('renders title and English scam-type label', (tester) async {
      await tester.pumpWidget(
        _themed(ModQueueRow(item: _item(), onTap: () {})),
      );

      expect(find.text('Fake Kerry parcel SMS'), findsOneWidget);
      expect(find.text('Phishing SMS'), findsOneWidget);
    });

    testWidgets('renders Thai scam-type label when locale is th', (tester) async {
      await tester.pumpWidget(
        _themed(
          ModQueueRow(item: _item(), onTap: () {}),
          locale: const Locale('th'),
        ),
      );

      expect(find.text('ฟิชชิง SMS'), findsOneWidget);
    });

    testWidgets('never renders reporter identity (FR-7.4 anti-regression)',
        (tester) async {
      await tester.pumpWidget(
        _themed(ModQueueRow(item: _item(), onTap: () {})),
      );

      // The entity doesn't carry reporter fields by design. This test stays
      // as a defensive check that no future commit reintroduces the masked
      // handle by accident.
      expect(find.textContaining('User_'), findsNothing);
      expect(find.textContaining('@user'), findsNothing);
    });

    testWidgets('renders evidence count via l10n', (tester) async {
      await tester.pumpWidget(
        _themed(ModQueueRow(item: _item(evidenceCount: 3), onTap: () {})),
      );

      expect(find.text('3 evidence'), findsOneWidget);
    });

    testWidgets('renders Review button label', (tester) async {
      await tester.pumpWidget(
        _themed(ModQueueRow(item: _item(), onTap: () {})),
      );

      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('flagged variant shows team note line', (tester) async {
      await tester.pumpWidget(
        _themed(
          ModQueueRow(
            item: _item(
              status: 'flagged',
              priorityFlag: true,
              lastRemarkByAdmin: 'Need second look',
            ),
            onTap: () {},
          ),
        ),
      );

      expect(find.textContaining('Need second look'), findsOneWidget);
    });

    testWidgets('non-flagged hides team note even if remark present',
        (tester) async {
      await tester.pumpWidget(
        _themed(
          ModQueueRow(
            item: _item(
              status: 'pending',
              lastRemarkByAdmin: 'old remark',
            ),
            onTap: () {},
          ),
        ),
      );

      expect(find.textContaining('old remark'), findsNothing);
    });

    testWidgets('age renders in hours when ≥1 hour', (tester) async {
      await tester.pumpWidget(
        _themed(
          ModQueueRow(
            item: _item(
              submittedAt: DateTime.now().subtract(const Duration(hours: 5)),
            ),
            onTap: () {},
          ),
        ),
      );

      expect(find.text('5h'), findsOneWidget);
    });

    testWidgets('age renders in minutes when <1 hour', (tester) async {
      await tester.pumpWidget(
        _themed(
          ModQueueRow(
            item: _item(
              submittedAt: DateTime.now().subtract(const Duration(minutes: 22)),
            ),
            onTap: () {},
          ),
        ),
      );

      expect(find.text('22m'), findsOneWidget);
    });

    testWidgets('onTap fires when row tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _themed(ModQueueRow(item: _item(), onTap: () => taps++)),
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(taps, greaterThanOrEqualTo(1));
    });

    testWidgets('onTap fires when Review button tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _themed(ModQueueRow(item: _item(), onTap: () => taps++)),
      );

      await tester.tap(find.text('Review'));
      await tester.pump();

      expect(taps, greaterThanOrEqualTo(1));
    });
  });
}
