import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ask_ai/presentation/widgets/attachment_chip.dart';

// 1×1 transparent PNG.
final _png = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

Widget _wrap(Widget w) => MaterialApp(home: Scaffold(body: w));

void main() {
  testWidgets('image MIME renders Image.memory thumbnail', (tester) async {
    await tester.pumpWidget(
      _wrap(AttachmentChip(
        bytes: _png,
        mimeType: 'image/png',
        onRemove: () {},
      )),
    );
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('non-image MIME renders PDF placeholder icon', (tester) async {
    await tester.pumpWidget(
      _wrap(AttachmentChip(
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'application/pdf',
        onRemove: () {},
      )),
    );
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
  });

  testWidgets('tap × calls onRemove', (tester) async {
    var removed = false;
    await tester.pumpWidget(
      _wrap(AttachmentChip(
        bytes: _png,
        mimeType: 'image/png',
        onRemove: () => removed = true,
      )),
    );
    await tester.tap(find.byIcon(Icons.close));
    expect(removed, isTrue);
  });
}
