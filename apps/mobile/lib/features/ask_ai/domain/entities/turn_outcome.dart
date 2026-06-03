import 'ai_draft.dart';
import 'chat_message.dart';
import 'similar_report.dart';

class TurnOutcome {
  const TurnOutcome({
    required this.userMessage,
    required this.assistantMessage,
    required this.intentDetected,
    required this.reportable,
    required this.hasEnoughInfo,
    required this.similarReports,
    this.searchIntent = false,
    this.draft,
    this.missingFacts = const [],
  });

  final ChatMessage userMessage;
  final ChatMessage assistantMessage;
  final bool intentDetected;

  /// True when the user was looking up existing reports (search mode) rather
  /// than describing their own incident. In that case `similarReports` are the
  /// answer and `reportable`/`draft` are always false/null.
  final bool searchIntent;
  final bool reportable;
  final bool hasEnoughInfo;

  /// Verified-report cards the AI surfaced for this turn. Rendered as
  /// tap-through cards under the assistant bubble in `_MessageBubble`.
  /// Empty when the AI found no relevant matches.
  final List<SimilarReport> similarReports;
  final AiDraft? draft;
  // Facts the AI hasn't gathered yet. Empty when hasEnoughInfo=true.
  // Allowed values: 'description', 'targetIdentifier', 'scamTypeCue',
  // 'userAction'. Forward-looking — v1 doesn't render this; future PR can
  // surface a "still need: …" chip below the AI bubble.
  final List<String> missingFacts;
}
