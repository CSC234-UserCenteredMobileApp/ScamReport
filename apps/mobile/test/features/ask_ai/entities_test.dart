import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ask_ai/domain/entities/ai_draft.dart';
import 'package:mobile/features/ask_ai/domain/entities/chat_attachment.dart';
import 'package:mobile/features/ask_ai/domain/entities/chat_message.dart';
import 'package:mobile/features/ask_ai/domain/entities/conversation.dart';
import 'package:mobile/features/ask_ai/domain/entities/similar_report.dart';
import 'package:mobile/features/ask_ai/domain/entities/turn_outcome.dart';
import 'package:mobile/features/ask_ai/domain/failures.dart';

void main() {
  group('AiDraft', () {
    const base = AiDraft(
      title: 'Title that is long enough',
      description: 'A description that is long enough.',
      scamTypeCode: 'phishing_sms',
      targetIdentifier: 'kerry-th.net',
      targetIdentifierKind: TargetIdentifierKind.url,
    );

    test('copyWith overrides specific fields', () {
      final updated = base.copyWith(title: 'New title that is long enough');
      expect(updated.title, 'New title that is long enough');
      expect(updated.description, base.description);
      expect(updated.targetIdentifier, base.targetIdentifier);
    });

    test('copyWith with clearTargetIdentifier nulls both fields', () {
      final cleared = base.copyWith(clearTargetIdentifier: true);
      expect(cleared.targetIdentifier, isNull);
      expect(cleared.targetIdentifierKind, isNull);
    });

    test('copyWith preserves identifier kind when overriding', () {
      final updated =
          base.copyWith(targetIdentifierKind: TargetIdentifierKind.phone);
      expect(updated.targetIdentifierKind, TargetIdentifierKind.phone);
    });
  });

  test('ChatAttachment holds metadata', () {
    const a = ChatAttachment(
      id: 'a-1',
      mimeType: 'image/jpeg',
      sizeBytes: 1024,
      signedUrl: 'https://x',
    );
    expect(a.id, 'a-1');
    expect(a.signedUrl, 'https://x');
  });

  test('ChatMessage defaults to empty attachments', () {
    final msg = ChatMessage(
      id: 'm-1',
      role: ChatRole.assistant,
      content: 'hello',
      intentDetected: false,
      createdAt: DateTime(2026, 5, 7),
    );
    expect(msg.attachments, isEmpty);
    expect(msg.role, ChatRole.assistant);
  });

  test('ConversationSummary + ConversationDetail construct cleanly', () {
    final summary = ConversationSummary(
      id: 'c-1',
      createdAt: DateTime(2026, 5, 7),
      lastMessageAt: DateTime(2026, 5, 7),
      preview: 'p',
      linkedReportId: 'rep-1',
    );
    expect(summary.linkedReportId, 'rep-1');

    final detail = ConversationDetail(
      id: 'c-1',
      createdAt: DateTime(2026, 5, 7),
      messages: const [],
      linkedReportId: null,
    );
    expect(detail.messages, isEmpty);
    expect(detail.linkedReportId, isNull);
  });

  test('TurnOutcome holds outcome shape', () {
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
        intentDetected: true,
        createdAt: DateTime(2026, 5, 7),
      ),
      intentDetected: true,
      reportable: true,
      hasEnoughInfo: true,
      similarReports: [
        SimilarReport(
          id: 'r-1',
          title: 'Sample',
          scamTypeCode: 'other',
          scamTypeLabelEn: 'Other',
          scamTypeLabelTh: 'อื่นๆ',
          verifiedAt: DateTime(2026, 5, 7),
        ),
      ],
      draft: const AiDraft(
        title: 'A draft title here',
        description: 'A draft description here.',
        scamTypeCode: 'other',
      ),
    );
    expect(outcome.draft, isNotNull);
    expect(outcome.similarReports.map((r) => r.id).toList(), ['r-1']);
  });

  test('AskAiFailure subclasses carry messages', () {
    expect(const AskAiUnauthorizedFailure().message, isNotEmpty);
    expect(const AskAiNotFoundFailure().message, isNotEmpty);
    expect(const AskAiRateLimitedFailure().message, isNotEmpty);
    expect(const AskAiNetworkFailure('net').message, 'net');
    expect(const AskAiValidationFailure('v').message, 'v');
    expect(const AskAiUnknownFailure('u').message, 'u');
  });
}
