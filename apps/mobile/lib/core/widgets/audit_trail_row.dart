import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One row in a moderation audit trail (FR-7.6).
///
/// Admin label is admin-to-admin transparency — the PRD requires recording
/// the acting admin's identity in the audit log, visible to all admins.
/// This is **not** the reporter-anonymity surface; reporter identity never
/// reaches this widget.
class AuditTrailRow extends StatelessWidget {
  const AuditTrailRow({
    super.key,
    required this.action,
    required this.at,
    this.remark,
    this.adminLabel,
  });

  final String action;
  final DateTime at;
  final String? remark;
  final String? adminLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final adminSuffix = adminLabel == null ? '' : ' — $adminLabel';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5, right: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${action.toUpperCase()}$adminSuffix',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat.yMMMd().add_jm().format(at),
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                if (remark != null && remark!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    remark!,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
