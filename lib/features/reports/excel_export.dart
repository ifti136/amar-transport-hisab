import 'package:excel/excel.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/domain/accounting/accounting.dart';

/// Excel export service
class ExcelExportService {
  /// Export a report to Excel
  static Future<List<int>> exportReport({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    required List<String> totals,
    required String sheetName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel[sheetName];

    // Add title
    sheet.appendRow([TextCellValue(title)]);

    // Add headers
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Add rows
    for (final row in rows) {
      sheet.appendRow(row.map((cell) => TextCellValue(cell)).toList());
    }

    // Add totals row
    sheet.appendRow(totals.map((t) => TextCellValue(t)).toList());

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Save to bytes
    final bytes = excel.encode();
    return bytes!;
  }

  /// Export multiple reports to a single Excel file
  static Future<List<int>> exportMultipleReports({
    required String fileName,
    required List<ReportSheetData> sheets,
  }) async {
    final excel = Excel.createExcel();

    // Remove default sheet
    excel.delete('Sheet1');

    for (final sheetData in sheets) {
      final sheet = excel[sheetData.sheetName];
      
      // Add title
      sheet.appendRow([TextCellValue(sheetData.title)]);

      // Add headers
      sheet.appendRow(sheetData.headers.map((h) => TextCellValue(h)).toList());

      // Add rows
      for (final row in sheetData.rows) {
        sheet.appendRow(row.map((cell) => TextCellValue(cell)).toList());
      }

      // Add totals
      sheet.appendRow(sheetData.totals.map((t) => TextCellValue(t)).toList());

      // Set column widths
      for (int i = 0; i < sheetData.headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }
    }

    final bytes = excel.encode();
    return bytes!;
  }
}

class ReportSheetData {
  final String sheetName;
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  final List<String> totals;

  ReportSheetData({
    required this.sheetName,
    required this.title,
    required this.headers,
    required this.rows,
    required this.totals,
  });
}