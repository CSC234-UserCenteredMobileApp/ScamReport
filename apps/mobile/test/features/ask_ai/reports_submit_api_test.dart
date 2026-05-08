import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/features/ask_ai/data/reports_submit_api.dart';
import 'package:mobile/features/ask_ai/domain/entities/ai_draft.dart';
import 'package:mobile/features/ask_ai/domain/failures.dart';
import 'package:mocktail/mocktail.dart';

class _MockUser extends Mock implements User {}

class _MockAuth extends Mock implements FirebaseAuth {}

class _StubClient extends http.BaseClient {
  _StubClient(this._handler);
  final Future<http.StreamedResponse> Function(http.BaseRequest) _handler;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _handler(request);
}

http.StreamedResponse _streamed(int status, String body) =>
    http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

const _draft = AiDraft(
  title: 'Fake Kerry parcel SMS',
  description: 'I received an SMS asking me to click a tracking link.',
  scamTypeCode: 'phishing_sms',
  targetIdentifier: 'kerry-th.net',
  targetIdentifierKind: TargetIdentifierKind.url,
);

void main() {
  late _MockAuth auth;
  late _MockUser user;

  setUp(() {
    auth = _MockAuth();
    user = _MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.getIdToken()).thenAnswer((_) async => 'tok-123');
  });

  test('throws unauth when no user', () async {
    when(() => auth.currentUser).thenReturn(null);
    final api = ReportsSubmitApi(_StubClient((_) async => _streamed(200, '{}')), auth);
    await expectLater(
      () => api.submit(draft: _draft, sourceConversationId: 'c-1'),
      throwsA(isA<AskAiUnauthorizedFailure>()),
    );
  });

  test('throws unauth when token empty', () async {
    when(() => user.getIdToken()).thenAnswer((_) async => '');
    final api = ReportsSubmitApi(_StubClient((_) async => _streamed(200, '{}')), auth);
    await expectLater(
      () => api.submit(draft: _draft, sourceConversationId: 'c-1'),
      throwsA(isA<AskAiUnauthorizedFailure>()),
    );
  });

  test('builds request body with draft fields and conversation linkage', () async {
    String? sentBody;
    final api = ReportsSubmitApi(
      _StubClient((req) async {
        if (req is http.Request) sentBody = req.body;
        return _streamed(
          200,
          jsonEncode({
            'id': 'rep-1',
            'status': 'pending',
            'createdAt': '2026-05-07T00:00:00Z',
          }),
        );
      }),
      auth,
    );
    final result = await api.submit(
      draft: _draft,
      sourceConversationId: 'conv-1',
      clientSubmissionId: 'sub-abc',
    );
    expect(result.reportId, 'rep-1');
    final json = jsonDecode(sentBody!) as Map<String, dynamic>;
    expect(json['title'], _draft.title);
    expect(json['scamTypeCode'], 'phishing_sms');
    expect(json['targetIdentifierKind'], 'url');
    expect(json['sourceConversationId'], 'conv-1');
    expect(json['clientSubmissionId'], 'sub-abc');
  });

  test('omits target fields when null', () async {
    String? sentBody;
    final api = ReportsSubmitApi(
      _StubClient((req) async {
        if (req is http.Request) sentBody = req.body;
        return _streamed(
          200,
          jsonEncode({
            'id': 'rep-1',
            'status': 'pending',
            'createdAt': '2026-05-07T00:00:00Z',
          }),
        );
      }),
      auth,
    );
    await api.submit(
      draft: const AiDraft(
        title: 'No identifier',
        description: 'Something happened with no specific phone or url.',
        scamTypeCode: 'other',
      ),
      sourceConversationId: 'conv-1',
    );
    final json = jsonDecode(sentBody!) as Map<String, dynamic>;
    expect(json.containsKey('targetIdentifier'), isFalse);
    expect(json.containsKey('targetIdentifierKind'), isFalse);
    expect(json.containsKey('clientSubmissionId'), isFalse);
  });

  test('maps 401 to AskAiUnauthorizedFailure', () async {
    final api = ReportsSubmitApi(
      _StubClient((_) async => _streamed(401, '{"error":"u"}')),
      auth,
    );
    await expectLater(
      () => api.submit(draft: _draft, sourceConversationId: 'c-1'),
      throwsA(isA<AskAiUnauthorizedFailure>()),
    );
  });

  test('maps 422 to AskAiValidationFailure with message', () async {
    final api = ReportsSubmitApi(
      _StubClient((_) async => _streamed(422, '{"error":"bad title"}')),
      auth,
    );
    await expectLater(
      () => api.submit(draft: _draft, sourceConversationId: 'c-1'),
      throwsA(isA<AskAiValidationFailure>()),
    );
  });

  test('maps 500 to AskAiUnknownFailure', () async {
    final api = ReportsSubmitApi(
      _StubClient((_) async => _streamed(500, 'oops')),
      auth,
    );
    await expectLater(
      () => api.submit(draft: _draft, sourceConversationId: 'c-1'),
      throwsA(isA<AskAiUnknownFailure>()),
    );
  });
}
