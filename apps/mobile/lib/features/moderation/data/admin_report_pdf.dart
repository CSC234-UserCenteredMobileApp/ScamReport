// Build a printable PDF for an admin-reviewed report. Used by
// admin_review_screen.dart's "Print / Share PDF" action. Authority-handoff
// document — reporter identity is intentionally absent (FR-7.4 + FR-7.8).
//
// Renders:
//   - Header (title, status, scam type, submitted date, AI score)
//   - Description
//   - Target identifier (when present)
//   - Evidence list (filenames + types — no embedded thumbnails in v1)
//   - Audit trail
//   - Footer with generation timestamp
//
// Returns the raw PDF bytes ready to hand to Printing.layoutPdf.

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/mod_report.dart';

Future<Uint8List> buildAdminReportPdf({
  required ModReportDetail report,
  required String scamTypeLabel,
}) async {
  final doc = pw.Document();

  final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
  final submitted = dateFmt.format(report.submittedAt.toLocal());
  final generatedAt = dateFmt.format(DateTime.now().toLocal());

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 36),
      header: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'ScamReport — Authority Handoff',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.Text(
              'Report #${report.id.substring(0, 8)}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
      footer: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated $generatedAt',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
      build: (ctx) => [
        _headerSection(report, scamTypeLabel, submitted),
        pw.SizedBox(height: 14),
        _descriptionSection(report),
        if (report.targetIdentifier != null) ...[
          pw.SizedBox(height: 14),
          _targetIdentifierSection(report),
        ],
        pw.SizedBox(height: 14),
        _evidenceSection(report),
        pw.SizedBox(height: 14),
        _auditTrailSection(report, dateFmt),
        pw.SizedBox(height: 20),
        _disclaimer(),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _headerSection(
  ModReportDetail report,
  String scamTypeLabel,
  String submitted,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        report.title,
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 6),
      pw.Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _pill('Status: ${report.status}'),
          _pill('Type: $scamTypeLabel'),
          if (report.aiScore != null)
            _pill(
              'AI score: ${report.aiScore}'
              '${report.aiConfidence != null ? ' (${report.aiConfidence})' : ''}',
            ),
          if (report.priorityFlag) _pill('Priority flag', accent: true),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        'Submitted: $submitted',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      ),
    ],
  );
}

pw.Widget _descriptionSection(ModReportDetail report) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _sectionTitle('Description'),
      pw.SizedBox(height: 4),
      pw.Text(report.description, style: const pw.TextStyle(fontSize: 11)),
    ],
  );
}

pw.Widget _targetIdentifierSection(ModReportDetail report) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _sectionTitle('Target identifier'),
      pw.SizedBox(height: 4),
      pw.Text(
        '${report.targetIdentifier!} '
        '(${report.targetIdentifierKind ?? '—'})',
        style: pw.TextStyle(fontSize: 11, font: pw.Font.courier()),
      ),
    ],
  );
}

pw.Widget _evidenceSection(ModReportDetail report) {
  if (report.evidenceFiles.isEmpty) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Evidence'),
        pw.SizedBox(height: 4),
        pw.Text('No evidence attached.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
      ],
    );
  }
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _sectionTitle('Evidence (${report.evidenceFiles.length})'),
      pw.SizedBox(height: 4),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(2.4),
          1: pw.FlexColumnWidth(1),
          2: pw.FlexColumnWidth(1.3),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _tableCell('File', isHeader: true),
              _tableCell('Kind', isHeader: true),
              _tableCell('Mime', isHeader: true),
            ],
          ),
          ...report.evidenceFiles.map(
            (e) => pw.TableRow(
              children: [
                _tableCell(_baseName(e.storagePath)),
                _tableCell(e.kind),
                _tableCell(e.mimeType),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _auditTrailSection(ModReportDetail report, DateFormat fmt) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _sectionTitle('Audit trail'),
      pw.SizedBox(height: 4),
      if (report.auditTrail.isEmpty)
        pw.Text('No moderation actions yet.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
      else
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.3),
            1: pw.FlexColumnWidth(0.9),
            2: pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableCell('When', isHeader: true),
                _tableCell('Action', isHeader: true),
                _tableCell('Remark', isHeader: true),
              ],
            ),
            ...report.auditTrail.map(
              (a) => pw.TableRow(
                children: [
                  _tableCell(fmt.format(a.createdAt.toLocal())),
                  _tableCell(a.action),
                  _tableCell(a.remark),
                ],
              ),
            ),
          ],
        ),
    ],
  );
}

pw.Widget _disclaimer() {
  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Text(
      'Disclaimer: This dossier was compiled by ScamReport from '
      'user-submitted reports. All attributions remain alleged until '
      'corroborated through your own verification process. Reporter '
      'identity is intentionally withheld for source-protection.',
      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
    ),
  );
}

pw.Widget _sectionTitle(String text) {
  return pw.Text(
    text.toUpperCase(),
    style: pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.grey700,
      letterSpacing: 0.6,
    ),
  );
}

pw.Widget _pill(String text, {bool accent = false}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: pw.BoxDecoration(
      color: accent ? PdfColors.orange100 : PdfColors.grey200,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        color: accent ? PdfColors.orange800 : PdfColors.grey800,
      ),
    ),
  );
}

pw.Widget _tableCell(String text, {bool isHeader = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

String _baseName(String path) {
  final i = path.lastIndexOf('/');
  return i >= 0 ? path.substring(i + 1) : path;
}
