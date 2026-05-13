import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_client.dart';
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
  bool _uploadingAttachment = false;

  // Set after first save in create mode so the screen gains an ID in-place.
  String? _savedId;
  String? get _effectiveId => _savedId ?? widget.announcementId;
  bool get _isEdit => _effectiveId != null;

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

  // Saves draft in create mode to obtain an ID. Returns true if ID is ready.
  Future<bool> _ensureSaved() async {
    if (_effectiveId != null) return true;
    if (!_formKey.currentState!.validate()) return false;
    setState(() => _saving = true);
    try {
      final created = await ref.read(announcementEditorRepositoryProvider).create(
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        category: _category,
      );
      ref.invalidate(adminAnnouncementsListProvider);
      if (mounted) setState(() => _savedId = created.id);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(announcementEditorRepositoryProvider);
      if (_isEdit) {
        await repo.update(
          _effectiveId!,
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
          category: _category,
        );
        ref.invalidate(adminAnnouncementDetailProvider(_effectiveId!));
        ref.invalidate(adminAnnouncementsListProvider);
        if (mounted) context.pop();
      } else {
        final created = await repo.create(
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
          category: _category,
        );
        ref.invalidate(adminAnnouncementsListProvider);
        if (mounted) setState(() => _savedId = created.id);
      }
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
    if (!await _ensureSaved()) return;
    if (!mounted) return;
    // Show confirmation bottom sheet with FCM push toggle
    final result = await showModalBottomSheet<({bool confirmed, bool pushToFcm})>(
      context: context,
      builder: (ctx) => _PublishSheet(),
    );
    if (result == null || !result.confirmed) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(announcementEditorRepositoryProvider);
      await repo.publish(_effectiveId!, pushToFcm: result.pushToFcm);
      ref.invalidate(adminAnnouncementsListProvider);
      ref.invalidate(adminAnnouncementDetailProvider(_effectiveId!));
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete announcement?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await ref.read(announcementEditorRepositoryProvider).delete(_effectiveId!);
      ref.invalidate(adminAnnouncementsListProvider);
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
      await repo.unpublish(_effectiveId!);
      ref.invalidate(adminAnnouncementsListProvider);
      ref.invalidate(adminAnnouncementDetailProvider(_effectiveId!));
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

  Future<void> _pickAndUpload() async {
    if (!await _ensureSaved()) return;
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;
    setState(() => _uploadingAttachment = true);
    try {
      final repo = ref.read(announcementEditorRepositoryProvider);
      for (final file in result.files) {
        if (file.bytes == null) continue;
        await repo.uploadAttachment(_effectiveId!, file);
      }
      ref.invalidate(adminAnnouncementDetailProvider(_effectiveId!));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _uploadingAttachment = false);
    }
  }

  Future<void> _deleteAttachment(String attachmentId) async {
    final repo = ref.read(announcementEditorRepositoryProvider);
    try {
      await repo.deleteAttachment(_effectiveId!, attachmentId);
      ref.invalidate(adminAnnouncementDetailProvider(_effectiveId!));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // In edit mode, load existing detail to populate form
    if (_isEdit) {
      final detailAsync =
          ref.watch(adminAnnouncementDetailProvider(_effectiveId!));
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
        title: Text(widget.announcementId != null ? 'Edit Announcement' : 'New Announcement'),
        centerTitle: true,
        actions: [
          if (_isEdit && !isPublished)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Theme.of(context).colorScheme.error,
              tooltip: 'Delete',
              onPressed: _saving ? null : _delete,
            ),
        ],
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
            const SizedBox(height: 16),

            // Attachment section
            const SizedBox(height: 8),
            _AttachmentSection(
              detail: detail,
              saving: _saving || _uploadingAttachment,
              isPublished: isPublished,
              onAdd: _pickAndUpload,
              onDelete: _deleteAttachment,
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

    // Draft / unpublished / new — Save Draft + Publish
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : _saveDraft,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Draft'),
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

class _AttachmentSection extends StatelessWidget {
  const _AttachmentSection({
    required this.detail,
    required this.saving,
    required this.isPublished,
    required this.onAdd,
    required this.onDelete,
  });

  final AdminAnnouncementDetail? detail;
  final bool saving;
  final bool isPublished;
  final VoidCallback onAdd;
  final void Function(String attachmentId) onDelete;

  @override
  Widget build(BuildContext context) {
    final attachments = detail?.attachments ?? [];
    final canEdit = !isPublished && !saving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Attachments (${attachments.length}/10)',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            if (isPublished)
              Text(
                'Unpublish to edit',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else if (attachments.length < 10)
              TextButton.icon(
                onPressed: canEdit ? onAdd : null,
                icon: const Icon(Icons.attach_file, size: 18),
                label: const Text('Add'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (final att in attachments)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: att.kind == 'image'
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      '$supabasePublicUrl/storage/v1/object/public/announcement-attachments/${att.storagePath}',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_outlined),
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            title: Text(
              att.storagePath.split('/').last,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: canEdit ? () => onDelete(att.id) : null,
            ),
          ),
      ],
    );
  }
}
