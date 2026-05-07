/// Sealed-style failure hierarchy. The data layer maps HTTP / IO errors into
/// these so presentation can render localised messages without leaking raw
/// exceptions or platform-specific types.
sealed class AskAiFailure {
  const AskAiFailure(this.message);
  final String message;
}

class AskAiNetworkFailure extends AskAiFailure {
  const AskAiNetworkFailure(super.message);
}

class AskAiUnauthorizedFailure extends AskAiFailure {
  const AskAiUnauthorizedFailure() : super('Sign in required.');
}

class AskAiNotFoundFailure extends AskAiFailure {
  const AskAiNotFoundFailure() : super('Conversation not found.');
}

class AskAiValidationFailure extends AskAiFailure {
  const AskAiValidationFailure(super.message);
}

class AskAiRateLimitedFailure extends AskAiFailure {
  const AskAiRateLimitedFailure() : super('Too many requests. Try again soon.');
}

class AskAiUnknownFailure extends AskAiFailure {
  const AskAiUnknownFailure(super.message);
}
