import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../domain/user_profile.dart';
import 'profile_providers.dart';

/// Bottom-sheet editor for the public profile card (Firestore `profiles/{uid}`,
/// the rules-validated client-write surface).
class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key});

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  final _controller = TextEditingController();
  bool _seeded = false;
  bool _saving = false;
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text;
    if (!UserProfile.isValidDisplayName(name)) {
      setState(() => _invalid = true);
      return;
    }
    setState(() {
      _saving = true;
      _invalid = false;
    });
    await ref.read(profileControllerProvider.notifier).save(displayName: name);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    if (!_seeded && profile != null) {
      _controller.text = profile.displayName;
      _seeded = true;
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.profileEditHeading,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('profile-display-name'),
            controller: _controller,
            maxLength: UserProfile.maxDisplayNameLength,
            decoration: InputDecoration(
              labelText: l10n.profileDisplayNameLabel,
              border: const OutlineInputBorder(),
              errorText: _invalid ? l10n.profileDisplayNameInvalid : null,
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const ValueKey('profile-save'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.profileSave),
          ),
        ],
      ),
    );
  }
}

/// Opens the editor; resolves true when the profile was saved.
Future<bool?> showEditProfileSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const SafeArea(child: EditProfileSheet()),
  );
}
