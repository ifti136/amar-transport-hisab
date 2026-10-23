import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:transport_hisab/features/reports/excel_export.dart';
import 'package:transport_hisab/features/reports/pdf_export.dart';

class ReportExportHelper {
  static Future<void> exportAndShareExcel({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    required List<String> totals,
    String sheetName = 'Report',
  }) async {
    final bytes = await ExcelExportService.exportReport(
      title: title,
      headers: headers,
      rows: rows,
      totals: totals,
      sheetName: sheetName,
    );
    final tempDir = await getTemporaryDirectory();
    final fileName = '${title.replaceAll(RegExp(r'\s+'), '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], subject: title);
  }

  static Future<void> exportAndSharePdf({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    required List<String> totals,
  }) async {
    final bytes = await PdfExportService.exportReport(
      title: title,
      headers: headers,
      rows: rows,
      totals: totals,
      fontPath: 'assets/fonts/NotoSansBengali-Regular.ttf',
    );
    final tempDir = await getTemporaryDirectory();
    final fileName = '${title.replaceAll(RegExp(r'\s+'), '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], subject: title);
  }
}
