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
  });

  final ChatMessage userMessage;
  final ChatMessage assistantMessage;
  final bool intentDetected;
  final bool reportable;
  final bool hasEnoughInfo;
  final List<String> similarReportIds;
  final AiDraft? draft;
}
