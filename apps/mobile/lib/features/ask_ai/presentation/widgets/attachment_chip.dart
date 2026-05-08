import 'dart:typed_data';

import 'package:flutter/material.dart';

class AttachmentChip extends StatelessWidget {
  const AttachmentChip({
    super.key,
    required this.bytes,
    required this.mimeType,
    required this.onRemove,
  });

  final Uint8List bytes;
  final String mimeType;
  final VoidCallback onRemove;

  bool get _isImage => mimeType.startsWith('image/');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 64,
      height: 64,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _isImage
                ? Image.memory(bytes, width: 64, height: 64, fit: BoxFit.cover)
                : Container(
                    width: 64,
                    height: 64,
                    color: theme.colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: const Icon(Icons.picture_as_pdf_outlined, size: 28),
                  ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
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
    );
  }
}
