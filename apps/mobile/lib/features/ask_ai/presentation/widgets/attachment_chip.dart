import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Pre-send thumbnail chip in the staged-attachments row. Stateful + a
/// hoisted [MemoryImage] so the bytes decode once and Flutter's image
/// cache hits across rebuilds — keeps `flutter run` smooth when the
/// surrounding chat list rebuilds during send (state flips: isSending,
/// userMessage appended, assistantMessage appended, staged cleared).
class AttachmentChip extends StatefulWidget {
  const AttachmentChip({
    super.key,
    required this.bytes,
    required this.mimeType,
    required this.onRemove,
  });

  final Uint8List bytes;
  final String mimeType;
  final VoidCallback onRemove;

  @override
  State<AttachmentChip> createState() => _AttachmentChipState();
}

class _AttachmentChipState extends State<AttachmentChip> {
  late final ImageProvider? _provider =
      widget.mimeType.startsWith('image/') ? MemoryImage(widget.bytes) : null;

  @override
  void dispose() {
    // Free the cached decode so the image cache doesn't hold the bytes
    // longer than needed once the chip is removed.
    _provider?.evict();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RepaintBoundary(
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _provider != null
                  ? Image(
                      image: _provider,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: theme.colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child:
                          const Icon(Icons.picture_as_pdf_outlined, size: 28),
                    ),
            ),
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: widget.onRemove,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: const Icon(Icons.close, size: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
