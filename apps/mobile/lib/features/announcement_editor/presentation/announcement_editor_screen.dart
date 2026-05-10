import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/admin_announcement.dart';
import 'announcement_editor_providers.dart';

class AnnouncementEditorScreen extends ConsumerStatefulWidget {
  const AnnouncementEditorScreen({super.key, this.announcementId});

  final String? announcementId;

  @override
  ConsumerState<AnnouncementEditorScreen> createState() =>
      _AnnouncementEditorScreenState();
}

class _AnnouncementEditorScreenState
    extends ConsumerState<AnnouncementEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  AdminAnnouncementCategory _category = AdminAnnouncementCategory.fraudAlert;

  bool _saving = false;
  bool _loaded = false;

  bool get _isEdit => widget.announcementId != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _populate(AdminAnnouncementDetail detail) {
    if (_loaded) return;
    _titleCtrl.text = detail.title;
    _bodyCtrl.text = detail.body;
    _category = detail.category;
    _loaded = true;
  }

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(announcementEditorRepositoryProvider);
      if (_isEdit) {
        await repo.update(
          widget.announcementId!,
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
          category: _category,
        );
      } else {
        await repo.create(
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
          category: _category,
        );
      }
      ref.invalidate(adminAnnouncementsListProvider);
      if (_isEdit) {
        ref.invalidate(adminAnnouncementDetailProvider(widget.announcementId!));
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publish() async {
    // Show confirmation bottom sheet with FCM push toggle
    final result = await showModalBottomSheet<({bool confirmed, bool pushToFcm})>(
      context: context,
      builder: (ctx) => _PublishSheet(),
    );
    if (result == null || !result.confirmed) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(announcementEditorRepositoryProvider);
      await repo.publish(widget.announcementId!, pushToFcm: result.pushToFcm);
      ref.invalidate(adminAnnouncementsListProvider);
      ref.invalidate(adminAnnouncementDetailProvider(widget.announcementId!));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _unpublish() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(announcementEditorRepositoryProvider);
      await repo.unpublish(widget.announcementId!);
      ref.invalidate(adminAnnouncementsListProvider);
      ref.invalidate(adminAnnouncementDetailProvider(widget.announcementId!));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // In edit mode, load existing detail to populate form
    if (_isEdit) {
      final detailAsync =
          ref.watch(adminAnnouncementDetailProvider(widget.announcementId!));
      return detailAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Announcement')),
          body: Center(child: Text(e.toString())),
        ),
        data: (detail) {
          _populate(detail);
          return _buildScaffold(context, detail);
        },
      );
    }
    return _buildScaffold(context, null);
  }

  Widget _buildScaffold(BuildContext context, AdminAnnouncementDetail? detail) {
    final isPublished = detail?.status == AdminAnnouncementStatus.published;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Announcement' : 'New Announcement'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Published banner
            if (isPublished) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Unpublish to edit this announcement.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Title field
            TextFormField(
              controller: _titleCtrl,
              enabled: !isPublished && !_saving,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<AdminAnnouncementCategory>(
              // ignore: deprecated_member_use
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: AdminAnnouncementCategory.values.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c.displayLabel),
                );
              }).toList(),
              onChanged: isPublished || _saving
                  ? null
                  : (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),

            // Body field
            TextFormField(
              controller: _bodyCtrl,
              enabled: !isPublished && !_saving,
              minLines: 5,
              maxLines: null,
              maxLength: 5000,
              decoration: const InputDecoration(
                labelText: 'Body',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Body is required' : null,
            ),
          ],
        ),
      ),

      // Bottom action bar
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildActionBar(isPublished),
        ),
      ),
    );
  }

  Widget _buildActionBar(bool isPublished) {
    if (isPublished) {
      // Published: only Unpublish available
      return FilledButton.tonal(
        onPressed: _saving ? null : _unpublish,
        child: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Unpublish'),
      );
    }

    if (!_isEdit) {
      // Create mode: only Save Draft
      return FilledButton(
        onPressed: _saving ? null : _saveDraft,
        child: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save Draft'),
      );
    }

    // Edit mode, draft/unpublished: Save Draft + Publish
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : _saveDraft,
            child: const Text('Save Draft'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _saving ? null : _publish,
            child: const Text('Publish'),
          ),
        ),
      ],
    );
  }
}

class _PublishSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PublishSheet> createState() => _PublishSheetState();
}

class _PublishSheetState extends ConsumerState<_PublishSheet> {
  bool _pushToFcm = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Publish Announcement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _pushToFcm,
              onChanged: (v) => setState(() => _pushToFcm = v),
              title: const Text('Send push notification'),
              subtitle: const Text('Broadcast to all users via FCM'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context)
                        .pop((confirmed: true, pushToFcm: _pushToFcm)),
                    child: const Text('Publish'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
