import 'ai_draft.dart';
import 'chat_message.dart';

class TurnOutcome {
  const TurnOutcome({
    required this.userMessage,
    required this.assistantMessage,
    required this.intentDetected,
    required this.reportable,
    required this.hasEnoughInfo,
    required this.similarReportIds,
    this.draft,
    this.missingFacts = const [],
  });

  final ChatMessage userMessage;
  final ChatMessage assistantMessage;
  final bool intentDetected;
  final bool reportable;
  final bool hasEnoughInfo;
  final List<String> similarReportIds;
  final AiDraft? draft;
  // Facts the AI hasn't gathered yet. Empty when hasEnoughInfo=true.
  // Allowed values: 'description', 'targetIdentifier', 'scamTypeCue',
  // 'userAction'. Forward-looking — v1 doesn't render this; future PR can
  // surface a "still need: …" chip below the AI bubble.
  final List<String> missingFacts;
}
