/// Typed failure thrown by `ModApiClient` when a moderation request returns
/// a non-2xx response. Carries enough context for the admin review screen
/// to surface a localised, actionable snackbar instead of the opaque
/// `Exception: <label> failed with <status>: <body>` string we used to ship.
class ModActionFailure implements Exception {
  ModActionFailure({
    required this.statusCode,
    required this.serverMessage,
    required this.action,
  });

  /// HTTP status code returned by the API.
  final int statusCode;

  /// The server's human-readable message — parsed from `{ "error": "..." }`
  /// JSON when present, otherwise the raw response body trimmed to a sane
  /// length. May be empty for a body-less 4xx.
  final String serverMessage;

  /// Lowercase action slug — `approve` / `reject` / `flag` / `unflag` /
  /// `queue` / `detail`. Lets the UI key off the failing operation.
  final String action;

  @override
  String toString() =>
      'ModActionFailure(status: $statusCode, action: $action, message: $serverMessage)';
}
