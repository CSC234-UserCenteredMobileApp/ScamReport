import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/l10n.dart';
import '../../ask_ai/domain/failures.dart';
import '../data/reports_api.dart';
import '../domain/edit_report_detail.dart';
import 'edit_report_providers.dart';

class EditReportScreen extends ConsumerStatefulWidget {
  const EditReportScreen({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends ConsumerState<EditReportScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _identCtrl = TextEditingController();
  String? _scamTypeCode;
  String? _identifierKind;
  List<EditStagedFile> _evidence = [];
  bool _initialized = false;
  bool _saving = false;
  int _uploadedCount = 0;
  int _totalNewFiles = 0;
  int? _uploadingIndex;
  Set<int> _uploadedIndices = {};

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _identCtrl.dispose();
    super.dispose();
  }

  void _onDetailLoaded(EditReportDetail detail) {
    if (_initialized) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _initialized = true;
        _titleCtrl.text = detail.title;
        _descCtrl.text = detail.description;
        _identCtrl.text = detail.targetIdentifier ?? '';
        _scamTypeCode = detail.scamTypeCode;
        _identifierKind = detail.targetIdentifierKind;
        _evidence = <EditStagedFile>[
          ...detail.evidenceFiles.map(ExistingFile.fromEvidence),
        ];
      });
    });
  }

  Future<void> _pickEvidence() async {
    final l10n = context.l10n;
    if (_evidence.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.askAiEvidenceCapReached)),
      );
      return;
    }
    final picker = ImagePicker();
    try {
      final XFile? picked = await showModalBottomSheet<XFile?>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.askAiAttachCamera),
                onTap: () async {
                  final f = await picker.pickImage(source: ImageSource.camera);
                  if (ctx.mounted) Navigator.of(ctx).pop(f);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.askAiAttachGallery),
                onTap: () async {
                  final f = await picker.pickImage(source: ImageSource.gallery);
                  if (ctx.mounted) Navigator.of(ctx).pop(f);
                },
              ),
            ],
          ),
        ),
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      final mime = picked.mimeType ?? _inferMime(picked.path);
      setState(() => _evidence.add(
            NewFile(bytes: bytes, mimeType: mime, filename: picked.name),
          ));
    } on AskAiFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.editReportUploadFailed)),
        );
      }
    }
  }

  String _inferMime(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.jpg') || p.endsWith('.jpeg')) return 'image/jpeg';
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.gif')) return 'image/gif';
    if (p.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }

  Future<void> _save() async {
    if (_scamTypeCode == null || _saving) return;
    final l10n = context.l10n;
    final newFileCount = _evidence.whereType<NewFile>().length;
    setState(() {
      _saving = true;
      _totalNewFiles = newFileCount;
      _uploadedCount = 0;
    });
    try {
      final repo = ref.read(reportsRepositoryProvider);
      final evidencePayload = <Map<String, dynamic>>[];
      for (var i = 0; i < _evidence.length; i++) {
        final f = _evidence[i];
        switch (f) {
          case ExistingFile ef:
            evidencePayload.add({
              'storagePath': ef.storagePath,
              'kind': ef.kind,
              'mimeType': ef.mimeType,
              'sizeBytes': ef.sizeBytes,
            });
          case NewFile nf:
            if (mounted) setState(() => _uploadingIndex = i);
            try {
              final meta = await repo.uploadEvidence(
                bytes: nf.bytes,
                mimeType: nf.mimeType,
                filename: nf.filename,
              );
              evidencePayload.add(meta);
              if (mounted) {
                setState(() {
                  _uploadingIndex = null;
                  _uploadedIndices.add(i);
                  _uploadedCount++;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.editReportUploadSuccess)),
                );
              }
            } catch (e) {
              if (mounted) {
                setState(() => _uploadingIndex = null);
                final msg = e is ReportValidationException
                    ? e.message
                    : l10n.editReportUploadFailed;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg)),
                );
              }
              return;
            }
        }
      }
      final trimmedId = _identCtrl.text.trim();
      await repo.updateReport(
        reportId: widget.reportId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        scamTypeCode: _scamTypeCode!,
        targetIdentifier: trimmedId.isEmpty ? null : trimmedId,
        targetIdentifierKind: trimmedId.isEmpty ? null : _identifierKind,
        evidenceFiles: evidencePayload,
      );
      ref.invalidate(myReportsProvider);
      ref.invalidate(editReportDetailProvider(widget.reportId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.editReportSaved)),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.editReportSaveFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _totalNewFiles = 0;
          _uploadedCount = 0;
          _uploadingIndex = null;
          _uploadedIndices = {};
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final detailAsync = ref.watch(editReportDetailProvider(widget.reportId));
    final scamTypesAsync = ref.watch(editScamTypesProvider);
    final canSave = _initialized && _scamTypeCode != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editReportTitle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_saving)
            LinearProgressIndicator(
              value:
                  _totalNewFiles > 0 ? _uploadedCount / _totalNewFiles : null,
              minHeight: 6,
            ),
          Expanded(
            child: detailAsync.when(
              loading: () => const _LoadingBody(),
              error: (_, __) => _ErrorBody(
                message: l10n.editReportLoadFailed,
                onRetry: () =>
                    ref.invalidate(editReportDetailProvider(widget.reportId)),
              ),
              data: (detail) {
                _onDetailLoaded(detail);
                if (!_initialized) return const _LoadingBody();
                return _EditForm(
                  titleCtrl: _titleCtrl,
                  descCtrl: _descCtrl,
                  identCtrl: _identCtrl,
                  scamTypeCode: _scamTypeCode,
                  scamTypesAsync: scamTypesAsync,
                  onScamTypeChanged: (v) => setState(() => _scamTypeCode = v),
                  identifierKind: _identifierKind,
                  onKindChanged: (v) => setState(() => _identifierKind = v),
                  evidence: _evidence,
                  onAddEvidence: _pickEvidence,
                  onRemoveEvidence: (i) =>
                      setState(() => _evidence.removeAt(i)),
                  onSave: canSave ? _save : null,
                  saving: _saving,
                  uploadingIndex: _uploadingIndex,
                  uploadedIndices: _uploadedIndices,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form body
// ---------------------------------------------------------------------------
class _EditForm extends StatelessWidget {
  const _EditForm({
    required this.titleCtrl,
    required this.descCtrl,
    required this.identCtrl,
    required this.scamTypeCode,
    required this.scamTypesAsync,
    required this.onScamTypeChanged,
    required this.identifierKind,
    required this.onKindChanged,
    required this.evidence,
    required this.onAddEvidence,
    required this.onRemoveEvidence,
    required this.onSave,
    required this.saving,
    required this.uploadingIndex,
    required this.uploadedIndices,
  });

  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController identCtrl;
  final String? scamTypeCode;
  final AsyncValue<List<ScamTypeOption>> scamTypesAsync;
  final void Function(String?) onScamTypeChanged;
  final String? identifierKind;
  final void Function(String?) onKindChanged;
  final List<EditStagedFile> evidence;
  final VoidCallback onAddEvidence;
  final void Function(int) onRemoveEvidence;
  final VoidCallback? onSave;
  final bool saving;
  final int? uploadingIndex;
  final Set<int> uploadedIndices;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(l10n.editReportSectionDetails),
          _FormSection(
            children: [
              TextField(
                controller: titleCtrl,
                decoration:
                    InputDecoration(labelText: l10n.askAiDraftFieldTitle),
                maxLength: 200,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration:
                    InputDecoration(labelText: l10n.askAiDraftFieldDescription),
                minLines: 3,
                maxLines: 6,
                maxLength: 2000,
              ),
              const SizedBox(height: 12),
              _ScamTypeField(
                scamTypeCode: scamTypeCode,
                scamTypesAsync: scamTypesAsync,
                onChanged: onScamTypeChanged,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(l10n.editReportSectionTarget),
          _FormSection(
            children: [
              TextField(
                controller: identCtrl,
                decoration:
                    InputDecoration(labelText: l10n.askAiDraftFieldIdentifier),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                // ignore: deprecated_member_use
                value: identifierKind,
                decoration:
                    InputDecoration(labelText: l10n.askAiDraftFieldKind),
                items: [
                  DropdownMenuItem(
                      value: null, child: Text(l10n.askAiKindNone)),
                  DropdownMenuItem(
                      value: 'phone', child: Text(l10n.askAiKindPhone)),
                  DropdownMenuItem(
                      value: 'url', child: Text(l10n.askAiKindUrl)),
                  DropdownMenuItem(
                      value: 'other', child: Text(l10n.askAiKindOther)),
                ],
                onChanged: onKindChanged,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _EditEvidenceSection(
            evidence: evidence,
            onAdd: evidence.length < 5 ? onAddEvidence : null,
            onRemove: onRemoveEvidence,
            uploadingIndex: uploadingIndex,
            uploadedIndices: uploadedIndices,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: saving ? null : () => context.pop(),
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: saving ? null : onSave,
                  child: saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.editReportSave),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label — accent bar + uppercase label
// ---------------------------------------------------------------------------
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form section card — groups related fields with a surface background
// ---------------------------------------------------------------------------
class _FormSection extends StatelessWidget {
  const _FormSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scam type dropdown — handles loading/error from API
// ---------------------------------------------------------------------------
class _ScamTypeField extends StatelessWidget {
  const _ScamTypeField({
    required this.scamTypeCode,
    required this.scamTypesAsync,
    required this.onChanged,
  });

  final String? scamTypeCode;
  final AsyncValue<List<ScamTypeOption>> scamTypesAsync;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return scamTypesAsync.when(
      loading: () => TextField(
        readOnly: true,
        controller: TextEditingController(text: scamTypeCode ?? ''),
        decoration: InputDecoration(
          labelText: l10n.askAiDraftFieldScamType,
          suffixIcon: const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (_, __) => TextField(
        readOnly: true,
        controller: TextEditingController(text: scamTypeCode ?? ''),
        decoration: InputDecoration(labelText: l10n.askAiDraftFieldScamType),
      ),
      data: (types) {
        final codes = types.map((t) => t.code).toSet();
        final safeValue = (scamTypeCode != null && codes.contains(scamTypeCode))
            ? scamTypeCode
            : null;
        return DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: safeValue,
          decoration: InputDecoration(labelText: l10n.askAiDraftFieldScamType),
          items: [
            for (final t in types)
              DropdownMenuItem(value: t.code, child: Text(t.labelEn)),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Evidence section
// ---------------------------------------------------------------------------
class _EditEvidenceSection extends StatelessWidget {
  const _EditEvidenceSection({
    required this.evidence,
    required this.onAdd,
    required this.onRemove,
    required this.uploadingIndex,
    required this.uploadedIndices,
  });

  final List<EditStagedFile> evidence;
  final VoidCallback? onAdd;
  final void Function(int) onRemove;
  final int? uploadingIndex;
  final Set<int> uploadedIndices;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.askAiEvidenceTitle,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Text(
              l10n.askAiEvidenceCount(evidence.length),
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < evidence.length; i++)
              if (evidence[i] is ExistingFile)
                _ExistingChip(
                  file: evidence[i] as ExistingFile,
                  onRemove: () => onRemove(i),
                )
              else if (evidence[i] is NewFile)
                _NewChip(
                  file: evidence[i] as NewFile,
                  onRemove: () => onRemove(i),
                  isUploading: uploadingIndex == i,
                  isUploaded: uploadedIndices.contains(i),
                ),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
              label: Text(l10n.askAiEvidenceAdd),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Evidence chip — existing (URL-based)
// ---------------------------------------------------------------------------
class _ExistingChip extends StatelessWidget {
  const _ExistingChip({required this.file, required this.onRemove});

  final ExistingFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _EvidenceChipFrame(
      onRemove: onRemove,
      child: file.kind == 'image' && file.signedUrl != null
          ? Image.network(
              file.signedUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _FileIcon(kind: file.kind),
            )
          : _FileIcon(kind: file.kind),
    );
  }
}

// ---------------------------------------------------------------------------
// Evidence chip — new bytes
// ---------------------------------------------------------------------------
class _NewChip extends StatelessWidget {
  const _NewChip({
    required this.file,
    required this.onRemove,
    required this.isUploading,
    required this.isUploaded,
  });

  final NewFile file;
  final VoidCallback onRemove;
  final bool isUploading;
  final bool isUploaded;

  @override
  Widget build(BuildContext context) {
    final imageWidget = file.mimeType.startsWith('image/')
        ? Image.memory(file.bytes, fit: BoxFit.cover)
        : const _FileIcon(kind: 'pdf');

    return _EvidenceChipFrame(
      onRemove: isUploading ? null : onRemove,
      borderColor: isUploaded ? const Color(0xFF16A34A) : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          if (isUploading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared chip frame: 80×80 rounded box with a remove button
// ---------------------------------------------------------------------------
class _EvidenceChipFrame extends StatelessWidget {
  const _EvidenceChipFrame({
    required this.child,
    required this.onRemove,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onRemove;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final hasBorder = borderColor != null;
    return SizedBox.square(
      dimension: 80,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: hasBorder
                  ? Border.all(color: borderColor!, width: 2.5)
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(hasBorder ? 8 : 10),
              child: child,
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FileIcon extends StatelessWidget {
  const _FileIcon({required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        kind == 'pdf' ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton — field-shaped placeholders
// ---------------------------------------------------------------------------
class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Skel(height: 16, color: color, width: 100),
          const SizedBox(height: 12),
          _Skel(height: 56, color: color),
          const SizedBox(height: 12),
          _Skel(height: 108, color: color),
          const SizedBox(height: 12),
          _Skel(height: 56, color: color),
          const SizedBox(height: 28),
          _Skel(height: 16, color: color, width: 72),
          const SizedBox(height: 12),
          _Skel(height: 56, color: color),
          const SizedBox(height: 12),
          _Skel(height: 56, color: color),
          const SizedBox(height: 28),
          _Skel(height: 16, color: color, width: 80),
          const SizedBox(height: 12),
          _Skel(height: 80, color: color),
          const SizedBox(height: 28),
          _Skel(height: 52, color: color),
        ],
      ),
    );
  }
}

class _Skel extends StatelessWidget {
  const _Skel({required this.height, required this.color, this.width});

  final double height;
  final Color color;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------
class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
