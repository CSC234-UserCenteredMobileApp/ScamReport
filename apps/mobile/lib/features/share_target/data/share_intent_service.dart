import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../domain/share_input.dart';

class ShareIntentService {
  StreamSubscription<List<SharedMediaFile>>? _sub;
  StreamController<ShareInput>? _controller;

  /// Returns text from the launch intent (cold start). Null if none.
  Future<ShareInput?> getInitial() async {
    final files = await ReceiveSharingIntent.instance.getInitialMedia();
    final text = _extractText(files);
    if (text == null) return null;
    ReceiveSharingIntent.instance.reset();
    return ShareInput(text: text, kind: ShareInput.detectKind(text));
  }

  /// Stream of intents received while the app is running.
  Stream<ShareInput> get stream {
    _controller = StreamController<ShareInput>.broadcast();
    _sub = ReceiveSharingIntent.instance.getMediaStream().listen((files) {
      final text = _extractText(files);
      if (text != null) {
        _controller?.add(
          ShareInput(text: text, kind: ShareInput.detectKind(text)),
        );
        ReceiveSharingIntent.instance.reset();
      }
    });
    return _controller!.stream;
  }

  void dispose() {
    _sub?.cancel();
    _controller?.close();
  }

  String? _extractText(List<SharedMediaFile> files) {
    if (files.isEmpty) return null;
    final f = files.first;
    if (f.type == SharedMediaType.text || f.type == SharedMediaType.url) {
      final t = f.path.trim();
      return t.isEmpty ? null : t;
    }
    return null;
  }
}
