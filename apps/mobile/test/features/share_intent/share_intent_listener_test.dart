import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/feature_flags/feature_flags.dart';
import 'package:mobile/features/check/domain/check_result.dart';
import 'package:mobile/features/share_intent/data/share_intent_service.dart';
import 'package:mobile/features/share_intent/domain/shared_payload.dart';
import 'package:mobile/features/share_intent/presentation/share_intent_listener.dart';
import 'package:mobile/features/share_intent/presentation/share_intent_providers.dart';

class _FakeShareIntentService implements ShareIntentService {
  _FakeShareIntentService({this.coldStart});

  final SharedPayload? coldStart;
  final StreamController<SharedPayload> _controller =
      StreamController<SharedPayload>.broadcast();
  int resetCount = 0;

  void emit(SharedPayload p) => _controller.add(p);

  @override
  Future<SharedPayload?> initial() async => coldStart;

  @override
  Stream<SharedPayload> stream() => _controller.stream;

  @override
  Future<void> reset() async {
    resetCount++;
  }

  void dispose() => _controller.close();
}

Widget _mount({
  required _FakeShareIntentService service,
  required bool flagOn,
  required void Function(BuildContext, CheckQuery) onShare,
}) {
  return ProviderScope(
    overrides: [
      shareIntentServiceProvider.overrideWithValue(service),
      featureFlagProvider(shareTargetFlagKey).overrideWith((_) => flagOn),
    ],
    child: MaterialApp(
      home: ShareIntentListener(
        onShare: onShare,
        child: const Scaffold(body: Text('child')),
      ),
    ),
  );
}

void main() {
  late _FakeShareIntentService service;

  tearDown(() => service.dispose());

  testWidgets('warm share with flag on → onShare called with phone CheckQuery',
      (tester) async {
    service = _FakeShareIntentService();
    final captured = <CheckQuery>[];

    await tester.pumpWidget(_mount(
      service: service,
      flagOn: true,
      onShare: (_, q) => captured.add(q),
    ));
    await tester.pump(); // settle post-frame
    service.emit(const SharedPayload('+66812345678'));
    await tester.pump();

    expect(captured, hasLength(1));
    expect(captured.first.payload, '+66812345678');
    expect(captured.first.type, 'phone');
    expect(captured.first.source, 'share');
  });

  testWidgets('warm share with URL → type=url', (tester) async {
    service = _FakeShareIntentService();
    final captured = <CheckQuery>[];

    await tester.pumpWidget(_mount(
      service: service,
      flagOn: true,
      onShare: (_, q) => captured.add(q),
    ));
    await tester.pump();
    service.emit(const SharedPayload('https://scam-example.com/login'));
    await tester.pump();

    expect(captured, hasLength(1));
    expect(captured.first.type, 'url');
  });

  testWidgets('flag off → warm share ignored', (tester) async {
    service = _FakeShareIntentService();
    final captured = <CheckQuery>[];

    await tester.pumpWidget(_mount(
      service: service,
      flagOn: false,
      onShare: (_, q) => captured.add(q),
    ));
    await tester.pump();
    service.emit(const SharedPayload('+66812345678'));
    await tester.pump();

    expect(captured, isEmpty);
  });

  testWidgets('cold-start payload with flag on → onShare called once',
      (tester) async {
    service = _FakeShareIntentService(
      coldStart: const SharedPayload('https://cold.example/abc'),
    );
    final captured = <CheckQuery>[];

    await tester.pumpWidget(_mount(
      service: service,
      flagOn: true,
      onShare: (_, q) => captured.add(q),
    ));
    await tester.pumpAndSettle();

    expect(captured, hasLength(1));
    expect(captured.first.payload, 'https://cold.example/abc');
    expect(captured.first.source, 'share');
    expect(service.resetCount, 1);
  });

  testWidgets('cold-start with flag off → reset still NOT called, no push',
      (tester) async {
    service = _FakeShareIntentService(
      coldStart: const SharedPayload('https://cold.example/abc'),
    );
    final captured = <CheckQuery>[];

    await tester.pumpWidget(_mount(
      service: service,
      flagOn: false,
      onShare: (_, q) => captured.add(q),
    ));
    await tester.pumpAndSettle();

    expect(captured, isEmpty);
    expect(service.resetCount, 0);
  });
}
