part of 'home_screen.dart';

/// Holds the clipboard value that triggered the banner.
/// Null means banner is dismissed or no qualifying value was found.
final clipboardValueProvider = StateProvider<String?>((ref) => null);

final _phoneRegex = RegExp(r'^(\+66|0)\d{8,9}$');

class _ClipboardBanner extends ConsumerStatefulWidget {
  const _ClipboardBanner();

  @override
  ConsumerState<_ClipboardBanner> createState() => _ClipboardBannerState();
}

class _ClipboardBannerState extends ConsumerState<_ClipboardBanner> {
  @override
  void initState() {
    super.initState();
    _checkClipboard();
  }

  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    final isPhone = _phoneRegex.hasMatch(text);
    final isUrl =
        text.startsWith('http://') || text.startsWith('https://');
    if (isPhone || isUrl) {
      // Only update if not already dismissed.
      if (ref.read(clipboardValueProvider) == null) {
        ref.read(clipboardValueProvider.notifier).state = text;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(clipboardValueProvider);
    if (value == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final truncated =
        value.length > 40 ? '${value.substring(0, 40)}…' : value;

    return Card(
      color: theme.colorScheme.primary.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.content_paste_outlined,
                color: theme.colorScheme.onPrimary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.clipboardBannerTitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    truncated,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => context.push(
                '/verdict',
                extra: CheckQuery(
                  payload: value,
                  type: detectType(value),
                  source: 'clipboard',
                ),
              ),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: theme.textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              child: Text(context.l10n.checkIt),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () =>
                  ref.read(clipboardValueProvider.notifier).state = null,
              icon: const Icon(Icons.close, size: 18),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
      ),
    );
  }
}
