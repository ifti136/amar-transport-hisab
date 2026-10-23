import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/domain/accounting/accounting.dart';

/// PDF export service
class PdfExportService {
  /// Export a report to PDF
  static Future<List<int>> exportReport({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    required List<String> totals,
    required String fontPath, // Path to Noto Sans Bengali font
  }) async {
    final pdf = pw.Document();

    // Load Bengali font
    final fontData = await _loadFont(fontPath);
    final font = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.all(16),
          child: pw.Text(
            title,
            style: pw.TextStyle(font: font, fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.all(16),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
        ),
        build: (context) => [
          pw.Table.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: pw.TextStyle(font: font, fontSize: 9),
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              for (int i = 0; i < headers.length; i++)
                i: const pw.FlexColumnWidth(1),
            },
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Total'],
            data: [totals],
            headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, fontSize: 10),
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<ByteData> _loadFont(String fontPath) async {
    return await rootBundle.load(fontPath);
  }

  /// Export multiple reports to a single PDF
  static Future<List<int>> exportMultipleReports({
    required String fileName,
    required List<ReportSheetData> sheets,
    required String fontPath,
  }) async {
    final pdf = pw.Document();
    final fontData = await _loadFont(fontPath);
    final font = pw.Font.ttf(fontData);

    for (final sheetData in sheets) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => pw.Container(
            alignment: pw.Alignment.center,
            padding: const pw.EdgeInsets.all(16),
            child: pw.Text(
              sheetData.title,
              style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            padding: const pw.EdgeInsets.all(16),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
          ),
          build: (context) => [
            pw.Table.fromTextArray(
              headers: sheetData.headers,
              data: sheetData.rows,
              headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: pw.TextStyle(font: font, fontSize: 9),
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                for (int i = 0; i < sheetData.headers.length; i++)
                  i: const pw.FlexColumnWidth(1),
              },
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Total'],
              data: [sheetData.totals],
              headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, fontSize: 10),
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),
          ],
        ),
      );
    }

    return pdf.save();
  }
}

class ReportSheetData {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  final List<String> totals;

  ReportSheetData({
    required this.title,
    required this.headers,
    required this.rows,
    required this.totals,
  });
}