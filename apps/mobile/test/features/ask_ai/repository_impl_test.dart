import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ask_ai/data/ask_ai_api_client.dart';
import 'package:mobile/features/ask_ai/data/ask_ai_repository_impl.dart';
import 'package:mobile/features/ask_ai/data/attachment_picker.dart';
import 'package:mobile/features/ask_ai/data/reports_submit_api.dart';
import 'package:mobile/features/ask_ai/data/submit_drafted_report_impl.dart';
import 'package:mobile/features/ask_ai/domain/ask_ai_repository.dart';
import 'package:mobile/features/ask_ai/domain/entities/ai_draft.dart';
import 'package:mobile/features/ask_ai/domain/entities/chat_message.dart';
import 'package:mobile/features/ask_ai/domain/entities/conversation.dart';
import 'package:mobile/features/ask_ai/domain/entities/turn_outcome.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements AskAiApiClient {}

class _MockSubmit extends Mock implements ReportsSubmitApi {}

void main() {
  setUpAll(() {
    registerFallbackValue(const AiDraft(
      title: 'fallback',
      description: 'fallback description',
      scamTypeCode: 'other',
    ));
    registerFallbackValue(<StagedAttachment>[]);
  });

  group('AskAiRepositoryImpl', () {
    late _MockApi api;
    late AskAiRepositoryImpl repo;

    setUp(() {
      api = _MockApi();
      repo = AskAiRepositoryImpl(api);
    });

    test('createConversation forwards', () async {
      when(() => api.createConversation()).thenAnswer((_) async => 'c-1');
      expect(await repo.createConversation(), 'c-1');
    });

    test('listConversations forwards', () async {
      final list = <ConversationSummary>[
        ConversationSummary(
          id: 'c-1',
          createdAt: DateTime(2026, 5, 7),
          lastMessageAt: DateTime(2026, 5, 7),
          preview: 'p',
        ),
      ];
      when(() => api.listConversations()).thenAnswer((_) async => list);
      expect(await repo.listConversations(), list);
    });

    test('getConversation forwards', () async {
      final detail = ConversationDetail(
        id: 'c-1',
        createdAt: DateTime(2026, 5, 7),
        messages: const [],
      );
      when(() => api.getConversation('c-1')).thenAnswer((_) async => detail);
      expect(await repo.getConversation('c-1'), detail);
    });

    test('deleteConversation forwards', () async {
      when(() => api.deleteConversation('c-1')).thenAnswer((_) async {});
      await repo.deleteConversation('c-1');
      verify(() => api.deleteConversation('c-1')).called(1);
    });

    test('sendMessage forwards to JSON path', () async {
      final outcome = TurnOutcome(
        userMessage: ChatMessage(
          id: 'u',
          role: ChatRole.user,
          content: 'hi',
          intentDetected: false,
          createdAt: DateTime(2026, 5, 7),
        ),
        assistantMessage: ChatMessage(
          id: 'a',
          role: ChatRole.assistant,
          content: 'reply',
          intentDetected: false,
          createdAt: DateTime(2026, 5, 7),
        ),
        intentDetected: false,
        reportable: false,
        hasEnoughInfo: false,
        similarReports: const [],
      );
      when(() => api.sendMessage('c-1', 'hi')).thenAnswer((_) async => outcome);
      final result = await repo.sendMessage('c-1', 'hi');
      expect(result, outcome);
    });

    test('sendMessageWithAttachments converts TurnAttachment → StagedAttachment', () async {
      final outcome = TurnOutcome(
        userMessage: ChatMessage(
          id: 'u',
          role: ChatRole.user,
          content: 'hi',
          intentDetected: false,
          createdAt: DateTime(2026, 5, 7),
        ),
        assistantMessage: ChatMessage(
          id: 'a',
          role: ChatRole.assistant,
          content: 'r',
          intentDetected: false,
          createdAt: DateTime(2026, 5, 7),
        ),
        intentDetected: false,
        reportable: false,
        hasEnoughInfo: false,
        similarReports: const [],
      );
      when(() => api.sendMessageMultipart(any(), any(), any()))
          .thenAnswer((_) async => outcome);
      final result = await repo.sendMessageWithAttachments(
        'c-1',
        'with image',
        [
          TurnAttachment(
            bytes: Uint8List.fromList([1, 2, 3]),
            mimeType: 'image/jpeg',
            filename: 'a.jpg',
          ),
        ],
      );
      expect(result, outcome);
      final captured = verify(() => api.sendMessageMultipart('c-1', 'with image', captureAny()))
          .captured
          .single as List<StagedAttachment>;
      expect(captured, hasLength(1));
      expect(captured.first.mimeType, 'image/jpeg');
    });
  });

  group('SubmitDraftedReportImpl', () {
    test('forwards to ReportsSubmitApi.submit', () async {
      final api = _MockSubmit();
      when(() => api.submit(
            draft: any(named: 'draft'),
            sourceConversationId: any(named: 'sourceConversationId'),
            clientSubmissionId: any(named: 'clientSubmissionId'),
          )).thenAnswer((_) async => (
            reportId: 'rep-1',
            createdAt: DateTime(2026, 5, 7),
          ));
      final impl = SubmitDraftedReportImpl(api);
      final result = await impl(
        draft: const AiDraft(
          title: 'Title that is long enough',
          description: 'A description that is long enough to pass.',
          scamTypeCode: 'other',
        ),
        sourceConversationId: 'c-1',
        clientSubmissionId: 'sub-1',
      );
      expect(result.reportId, 'rep-1');
    });
  });
}
