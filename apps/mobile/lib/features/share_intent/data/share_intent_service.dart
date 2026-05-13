import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../domain/shared_payload.dart';

/// Boundary in front of `receive_sharing_intent`. Returning a typed
/// [SharedPayload] keeps the plugin's `SharedMediaFile` out of the rest of
/// the app and gives tests a seam to fake.
abstract class ShareIntentService {
  /// Payload that launched the app via a share intent (cold start).
  /// Null when the launch was not from a share or when running on a
  /// non-Android platform.
  Future<SharedPayload?> initial();

  /// Payloads delivered while the app is already running (warm shares).
  Stream<SharedPayload> stream();

  /// Clears the cold-start buffer so the same payload is not replayed on
  /// the next hot restart. Safe to call multiple times.
  Future<void> reset();
}

class PluginShareIntentService implements ShareIntentService {
  PluginShareIntentService();

  bool get _supported => !kIsWeb && Platform.isAndroid;

  @override
  Future<SharedPayload?> initial() async {
    if (!_supported) return null;
    final files = await ReceiveSharingIntent.instance.getInitialMedia();
    return _firstTextPayload(files);
  }

  @override
  Stream<SharedPayload> stream() {
    if (!_supported) return const Stream<SharedPayload>.empty();
    return ReceiveSharingIntent.instance
        .getMediaStream()
        .map(_firstTextPayload)
        .where((p) => p != null)
        .cast<SharedPayload>();
  }

  @override
  Future<void> reset() async {
    if (!_supported) return;
    ReceiveSharingIntent.instance.reset();
  }

  static SharedPayload? _firstTextPayload(List<SharedMediaFile> files) {
    for (final f in files) {
      if (f.type == SharedMediaType.text || f.type == SharedMediaType.url) {
        final trimmed = f.path.trim();
        if (trimmed.isNotEmpty) return SharedPayload(trimmed);
      }
    }
    return null;
  }
}
