import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/features/ask_ai/data/ask_ai_api_client.dart';
import 'package:mobile/features/ask_ai/data/attachment_picker.dart';
import 'package:mobile/features/ask_ai/domain/entities/ai_draft.dart';
import 'package:mobile/features/ask_ai/domain/entities/chat_message.dart';
import 'package:mobile/features/ask_ai/domain/entities/conversation.dart';
import 'package:mobile/features/ask_ai/domain/failures.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:typed_data';

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

void main() {
  late _MockAuth auth;
  late _MockUser user;

  setUp(() {
    auth = _MockAuth();
    user = _MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.getIdToken()).thenAnswer((_) async => 'tok-123');
  });

  group('AskAiApiClient — auth', () {
    test('throws AskAiUnauthorizedFailure when no current user', () async {
      when(() => auth.currentUser).thenReturn(null);
      final api = AskAiApiClient(_StubClient((_) async => _streamed(200, '{}')), auth);
      await expectLater(
        () => api.createConversation(),
        throwsA(isA<AskAiUnauthorizedFailure>()),
      );
    });

    test('throws AskAiUnauthorizedFailure when token is empty', () async {
      when(() => user.getIdToken()).thenAnswer((_) async => '');
      final api = AskAiApiClient(_StubClient((_) async => _streamed(200, '{}')), auth);
      await expectLater(
        () => api.createConversation(),
        throwsA(isA<AskAiUnauthorizedFailure>()),
      );
    });
  });

  group('AskAiApiClient — createConversation', () {
    test('returns conversationId on 200', () async {
      final api = AskAiApiClient(
        _StubClient((req) async {
          expect(req.method, 'POST');
          expect(req.url.path, '/ask-ai/conversations');
          expect(req.headers['Authorization'], 'Bearer tok-123');
          return _streamed(
            200,
            jsonEncode({'conversationId': 'c-1', 'createdAt': '2026-05-07T00:00:00Z'}),
          );
        }),
        auth,
      );
      expect(await api.createConversation(), 'c-1');
    });

    test('maps 401 to AskAiUnauthorizedFailure', () async {
      final api = AskAiApiClient(
        _StubClient((_) async => _streamed(401, '{"error":"Unauthorized"}')),
        auth,
      );
      await expectLater(
        () => api.createConversation(),
        throwsA(isA<AskAiUnauthorizedFailure>()),
      );
    });

    test('maps 429 to AskAiRateLimitedFailure', () async {
      final api = AskAiApiClient(
        _StubClient((_) async => _streamed(429, '{"error":"slow down"}')),
        auth,
      );
      await expectLater(
        () => api.createConversation(),
        throwsA(isA<AskAiRateLimitedFailure>()),
      );
    });

    test('maps 422 to AskAiValidationFailure', () async {
      final api = AskAiApiClient(
        _StubClient((_) async => _streamed(422, '{"error":"bad"}')),
        auth,
      );
      await expectLater(
        () => api.createConversation(),
        throwsA(isA<AskAiValidationFailure>()),
      );
    });

    test('maps 500 to AskAiUnknownFailure', () async {
      final api = AskAiApiClient(
        _StubClient((_) async => _streamed(500, 'oops')),
        auth,
      );
      await expectLater(
        () => api.createConversation(),
        throwsA(isA<AskAiUnknownFailure>()),
      );
    });
  });

  group('AskAiApiClient — listConversations', () {
    test('parses items array', () async {
      final api = AskAiApiClient(
        _StubClient((_) async => _streamed(
              200,
              jsonEncode({
                'items': [
                  {
                    'id': 'c-1',
                    'createdAt': '2026-05-07T00:00:00Z',
                    'lastMessageAt': '2026-05-07T01:00:00Z',
                    'preview': 'kerry parcel sms…',
                    'linkedReportId': null,
                  },
                ],
              }),
            )),
        auth,
      );
      final list = await api.listConversations();
      expect(list, hasLength(1));
      expect(list.first.preview, 'kerry parcel sms…');
      expect(list.first.linkedReportId, isNull);
    });
  });

  group('AskAiApiClient — getConversation', () {
    test('parses messages + attachments', () async {
      final api = AskAiApiClient(
        _StubClient((_) async => _streamed(
              200,
              jsonEncode({
                'id': 'c-1',
                'createdAt': '2026-05-07T00:00:00Z',
                'linkedReportId': 'rep-9',
                'messages': [
                  {
                    'id': 'm-1',
                    'role': 'user',
                    'content': 'hi',
                    'intentDetected': false,
                    'createdAt': '2026-05-07T00:00:01Z',
                    'attachments': [
                      {
                        'id': 'a-1',
                        'mimeType': 'image/jpeg',
                        'sizeBytes': 1024,
                        'signedUrl': 'https://signed/x',
                      }
                    ],
                  },
                  {
                    'id': 'm-2',
                    'role': 'assistant',
                    'content': 'hello',
                    'intentDetected': true,
                    'createdAt': '2026-05-07T00:00:02Z',
                    'attachments': [],
                  },
                ],
              }),
            )),
        auth,
      );
      final detail = await api.getConversation('c-1');
      expect(detail.id, 'c-1');
      expect(detail.linkedReportId, 'rep-9');
      expect(detail.messages, hasLength(2));
      expect(detail.messages[0].role, ChatRole.user);
      expect(detail.messages[0].attachments.first.signedUrl, 'https://signed/x');
      expect(detail.messages[1].intentDetected, isTrue);
    });

    test('throws AskAiNotFoundFailure on 404', () async {
      final api = AskAiApiClient(
        _StubClient((_) async => _streamed(404, '{"error":"not found"}')),
        auth,
      );
      await expectLater(
        () => api.getConversation('c-1'),
        throwsA(isA<AskAiNotFoundFailure>()),
      );
    });
  });

  group('AskAiApiClient — deleteConversation', () {
    test('succeeds on 200', () async {
      final api = AskAiApiClient(
        _StubClient((req) async {
          expect(req.method, 'DELETE');
          return _streamed(200, '{"ok":true}');
        }),
        auth,
      );
      await api.deleteConversation('c-1');
    });
  });

  group('AskAiApiClient — sendMessage (JSON)', () {
    test('sends body and parses turn outcome', () async {
      String? sentBody;
      final api = AskAiApiClient(
        _StubClient((req) async {
          if (req is http.Request) sentBody = req.body;
          return _streamed(
            200,
            jsonEncode({
              'userMessage': {
                'id': 'm-1',
                'role': 'user',
                'content': 'hi',
                'intentDetected': false,
                'createdAt': '2026-05-07T00:00:01Z',
                'attachments': [],
              },
              'assistantMessage': {
                'id': 'm-2',
                'role': 'assistant',
                'content': 'reply',
                'intentDetected': false,
                'createdAt': '2026-05-07T00:00:02Z',
                'attachments': [],
              },
              'intentDetected': false,
              'reportable': false,
              'hasEnoughInfo': false,
              'draft': null,
              'similarReportIds': ['r-1', 'r-2'],
            }),
          );
        }),
        auth,
      );
      final out = await api.sendMessage('c-1', 'hi');
      expect(jsonDecode(sentBody!)['content'], 'hi');
      expect(out.similarReportIds, ['r-1', 'r-2']);
      expect(out.draft, isNull);
    });

    test('parses draft fields when reportable', () async {
      final api = AskAiApiClient(
        _StubClient((_) async => _streamed(
              200,
              jsonEncode({
                'userMessage': {
                  'id': 'm-1',
                  'role': 'user',
                  'content': 'hi',
                  'intentDetected': false,
                  'createdAt': '2026-05-07T00:00:01Z',
                  'attachments': [],
                },
                'assistantMessage': {
                  'id': 'm-2',
                  'role': 'assistant',
                  'content': 'r',
                  'intentDetected': true,
                  'createdAt': '2026-05-07T00:00:02Z',
                  'attachments': [],
                },
                'intentDetected': true,
                'reportable': true,
                'hasEnoughInfo': true,
                'draft': {
                  'title': 'Fake parcel SMS',
                  'description': 'I got an SMS asking me to click a tracking link.',
                  'scamTypeCode': 'phishing_sms',
                  'targetIdentifier': 'kerry-th.net',
                  'targetIdentifierKind': 'url',
                },
                'similarReportIds': [],
              }),
            )),
        auth,
      );
      final out = await api.sendMessage('c-1', 'hi');
      expect(out.draft, isNotNull);
      expect(out.draft!.targetIdentifierKind, TargetIdentifierKind.url);
    });

    test('handles each TargetIdentifierKind variant', () async {
      for (final entry in {
        'phone': TargetIdentifierKind.phone,
        'other': TargetIdentifierKind.other,
        null: null,
      }.entries) {
        final api = AskAiApiClient(
          _StubClient((_) async => _streamed(
                200,
                jsonEncode({
                  'userMessage': {
                    'id': 'm-1',
                    'role': 'user',
                    'content': 'hi',
                    'intentDetected': false,
                    'createdAt': '2026-05-07T00:00:01Z',
                    'attachments': [],
                  },
                  'assistantMessage': {
                    'id': 'm-2',
                    'role': 'assistant',
                    'content': 'r',
                    'intentDetected': false,
                    'createdAt': '2026-05-07T00:00:02Z',
                    'attachments': [],
                  },
                  'intentDetected': false,
                  'reportable': true,
                  'hasEnoughInfo': true,
                  'draft': {
                    'title': 'A title that is long enough',
                    'description': 'A description that is long enough.',
                    'scamTypeCode': 'other',
                    'targetIdentifier': 'x',
                    'targetIdentifierKind': entry.key,
                  },
                  'similarReportIds': [],
                }),
              )),
          auth,
        );
        final out = await api.sendMessage('c-1', 'hi');
        expect(out.draft!.targetIdentifierKind, entry.value);
      }
    });
  });

  group('AskAiApiClient — sendMessageMultipart', () {
    test('builds MultipartRequest with files and content', () async {
      String? capturedPath;
      final api = AskAiApiClient(
        _StubClient((req) async {
          capturedPath = req.url.path;
          // Drain the body.
          final mr = req as http.MultipartRequest;
          expect(mr.fields['content'], 'with image');
          expect(mr.files, hasLength(1));
          return _streamed(
            200,
            jsonEncode({
              'userMessage': {
                'id': 'm-1',
                'role': 'user',
                'content': 'with image',
                'intentDetected': false,
                'createdAt': '2026-05-07T00:00:01Z',
                'attachments': [],
              },
              'assistantMessage': {
                'id': 'm-2',
                'role': 'assistant',
                'content': 'r',
                'intentDetected': false,
                'createdAt': '2026-05-07T00:00:02Z',
                'attachments': [],
              },
              'intentDetected': false,
              'reportable': false,
              'hasEnoughInfo': false,
              'draft': null,
              'similarReportIds': [],
            }),
          );
        }),
        auth,
      );
      final out = await api.sendMessageMultipart('c-1', 'with image', [
        StagedAttachment(
          bytes: Uint8List.fromList([1, 2, 3, 4]),
          mimeType: 'image/jpeg',
          filename: 'a.jpg',
        ),
      ]);
      expect(capturedPath, '/ask-ai/conversations/c-1/messages/multipart');
      expect(out.userMessage.content, 'with image');
    });

    test('throws unauth when not signed in', () async {
      when(() => auth.currentUser).thenReturn(null);
      final api = AskAiApiClient(_StubClient((_) async => _streamed(200, '{}')), auth);
      await expectLater(
        () => api.sendMessageMultipart('c-1', 'hi', const []),
        throwsA(isA<AskAiUnauthorizedFailure>()),
      );
    });

    test('maps 413 from server to validation failure', () async {
      final api = AskAiApiClient(
        _StubClient((_) async =>
            _streamed(413, '{"error":"too big","code":"attachment_too_large"}')),
        auth,
      );
      // 413 isn't in the explicit map; falls through to AskAiUnknownFailure.
      await expectLater(
        () => api.sendMessageMultipart('c-1', 'hi', [
          StagedAttachment(
            bytes: Uint8List.fromList([1]),
            mimeType: 'image/jpeg',
            filename: 'a.jpg',
          ),
        ]),
        throwsA(isA<AskAiUnknownFailure>()),
      );
    });
  });

  group('AskAiApiClient — iter-5 locale passthrough', () {
    test('sendMessage adds locale field from provider', () async {
      String? capturedLocale;
      final api = AskAiApiClient(
        _StubClient((req) async {
          final body = jsonDecode(await _readBody(req)) as Map<String, dynamic>;
          capturedLocale = body['locale'] as String?;
          return _streamed(
            200,
            jsonEncode({
              'userMessage': {
                'id': 'a',
                'role': 'user',
                'content': 'hi',
                'intentDetected': false,
                'createdAt': '2026-05-07T00:00:00Z',
                'attachments': [],
              },
              'assistantMessage': {
                'id': 'b',
                'role': 'assistant',
                'content': 'hi',
                'intentDetected': false,
                'createdAt': '2026-05-07T00:00:01Z',
                'attachments': [],
              },
              'intentDetected': false,
              'reportable': false,
              'hasEnoughInfo': false,
              'similarReportIds': [],
              'missingFacts': [],
            }),
          );
        }),
        auth,
        locale: () => 'en',
      );
      await api.sendMessage('c-1', 'hi');
      expect(capturedLocale, 'en');
    });

    test('sendMessageMultipart adds locale form field', () async {
      String? capturedLocale;
      final api = AskAiApiClient(
        _StubClient((req) async {
          if (req is http.MultipartRequest) {
            capturedLocale = req.fields['locale'];
          }
          return _streamed(
            200,
            jsonEncode({
              'userMessage': {
                'id': 'a',
                'role': 'user',
                'content': 'hi',
                'intentDetected': false,
                'createdAt': '2026-05-07T00:00:00Z',
                'attachments': [],
              },
              'assistantMessage': {
                'id': 'b',
                'role': 'assistant',
                'content': 'hi',
                'intentDetected': false,
                'createdAt': '2026-05-07T00:00:01Z',
                'attachments': [],
              },
              'intentDetected': false,
              'reportable': false,
              'hasEnoughInfo': false,
              'similarReportIds': [],
              'missingFacts': [],
            }),
          );
        }),
        auth,
        locale: () => 'th',
      );
      await api.sendMessageMultipart('c-1', 'hi', [
        StagedAttachment(
          bytes: Uint8List.fromList([1]),
          mimeType: 'image/jpeg',
          filename: 'a.jpg',
        ),
      ]);
      expect(capturedLocale, 'th');
    });
  });

  group('AskAiApiClient — iter-5 upsertDraft', () {
    test('PATCHes draft with payload', () async {
      String? capturedBody;
      String? capturedMethod;
      String? capturedPath;
      final api = AskAiApiClient(
        _StubClient((req) async {
          capturedMethod = req.method;
          capturedPath = req.url.path;
          capturedBody = await _readBody(req);
          return _streamed(
            200,
            jsonEncode({'ok': true, 'draft': null}),
          );
        }),
        auth,
      );
      await api.upsertDraft(
        'c-1',
        const PersistedDraft(
          draft: AiDraft(
            title: 'My drafted title',
            description: 'A long enough description here',
            scamTypeCode: 'phishing_sms',
            targetIdentifier: 'kerry-th.net',
            targetIdentifierKind: TargetIdentifierKind.url,
          ),
          userEditedDraft: true,
          evidenceAttachmentIds: ['11111111-1111-4111-1111-111111111111'],
        ),
      );
      expect(capturedMethod, 'PATCH');
      expect(capturedPath, '/ask-ai/conversations/c-1/draft');
      final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(body['title'], 'My drafted title');
      expect(body['userEditedDraft'], true);
      expect(body['evidenceAttachmentIds'], hasLength(1));
    });

    test('clears draft with null payload', () async {
      String? capturedBody;
      final api = AskAiApiClient(
        _StubClient((req) async {
          capturedBody = await _readBody(req);
          return _streamed(200, jsonEncode({'ok': true, 'draft': null}));
        }),
        auth,
      );
      await api.upsertDraft('c-1', null);
      expect(capturedBody, 'null');
    });

    test('parses draft + evidenceAttachments from getConversation', () async {
      final api = AskAiApiClient(
        _StubClient((req) async {
          return _streamed(
            200,
            jsonEncode({
              'id': 'c-1',
              'createdAt': '2026-05-07T00:00:00Z',
              'linkedReportId': null,
              'messages': [],
              'draft': {
                'title': 'Server-stored title',
                'description': 'Server description that is long.',
                'scamTypeCode': 'phishing_sms',
                'targetIdentifier': null,
                'targetIdentifierKind': null,
                'userEditedDraft': false,
                'evidenceAttachmentIds': ['aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa'],
              },
              'evidenceAttachments': [
                {
                  'id': 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
                  'mimeType': 'image/jpeg',
                  'sizeBytes': 12345,
                  'signedUrl': 'https://signed.example/a.jpg',
                },
              ],
            }),
          );
        }),
        auth,
      );
      final detail = await api.getConversation('c-1');
      expect(detail.draft, isNotNull);
      expect(detail.draft!.draft.title, 'Server-stored title');
      expect(detail.draft!.evidenceAttachmentIds, hasLength(1));
      expect(detail.evidenceAttachments, hasLength(1));
      expect(detail.evidenceAttachments.first.signedUrl, contains('a.jpg'));
    });
  });
}

Future<String> _readBody(http.BaseRequest req) async {
  if (req is http.Request) return req.body;
  if (req is http.MultipartRequest) {
    return req.fields.entries.map((e) => '${e.key}=${e.value}').join('&');
  }
  return '';
}
