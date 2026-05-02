import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/domain/recent_report.dart';
import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.report});

  final RecentReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<VerdictPalette>()!;
    final locale = Localizations.localeOf(context);
    final scamTypeLabel = locale.languageCode == 'th'
        ? report.scamTypeLabelTh
        : report.scamTypeLabelEn;
    final typeColors = _scamTypeColors(report.scamTypeCode, palette);
    final typeIcon = _scamTypeIcon(report.scamTypeCode);

    return Card(
      child: InkWell(
        onTap: () => context.push('/report-detail/${report.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: typeColors.soft,
                  shape: BoxShape.circle,
                ),
                child: Icon(typeIcon, size: 20, color: typeColors.fg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Chip(
                            label: Text(scamTypeLabel),
                            backgroundColor: typeColors.bg,
                            labelStyle: theme.textTheme.labelSmall?.copyWith(
                              color: typeColors.fg,
                              fontWeight: FontWeight.w600,
                            ),
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 0),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        Text(
                          _formatMonthDay(report.verifiedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.excerpt,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.reportCountLabel(report.reportCount),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

VerdictColors _scamTypeColors(String code, VerdictPalette palette) {
  switch (code) {
    case 'phone_impersonation':
    case 'phishing_sms':
    case 'ecommerce_fraud':
    case 'romance_scam':
      return palette.scam;
    case 'fake_qr':
    case 'fake_qr_code':
    case 'investment_fraud':
      return palette.suspicious;
    default:
      return palette.unknown;
  }
}

IconData _scamTypeIcon(String code) {
  switch (code) {
    case 'phishing_sms':
      return Icons.link;
    case 'phone_impersonation':
      return Icons.phone_outlined;
    case 'fake_qr':
    case 'fake_qr_code':
      return Icons.qr_code_2;
    case 'ecommerce_fraud':
      return Icons.shopping_bag_outlined;
    case 'investment_fraud':
      return Icons.trending_up;
    case 'romance_scam':
      return Icons.favorite_outline;
    default:
      return Icons.warning_amber_outlined;
  }
}

String _formatMonthDay(DateTime dt) {
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$m-$d';
}
