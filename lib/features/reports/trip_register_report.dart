import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/reports/report_viewer.dart';
import 'package:transport_hisab/features/reports/excel_export.dart';
import 'package:transport_hisab/features/reports/pdf_export.dart';
import 'package:transport_hisab/domain/accounting/accounting.dart';

class TripRegisterReport extends ConsumerWidget {
  const TripRegisterReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportTripRegister)),
      body: _TripRegisterReportBody(dateRange: DateTimeRange(start: firstDayOfMonth, end: lastDayOfMonth)),
    );
  }
}

class _TripRegisterReportBody extends ConsumerWidget {
  final DateTimeRange dateRange;

  const _TripRegisterReportBody({required this.dateRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // TODO: Fetch actual data from accounting engine
    final headers = [
      l10n.dateLabel,
      l10n.customerLabel,
      l10n.vehicleLabel,
      l10n.fareLabel,
      l10n.advanceLabel,
      l10n.outstandingLabel,
    ];

    final rows = <List<String>>[
      // TODO: Fetch actual data
    ];

    final totals = [
      '',
      '',
      '',
      '৳0',
      '৳0',
      '৳0',
    ];

    return ReportViewer(
      title: AppLocalizations.of(context)!.reportTripRegister,
      headers: headers,
      rows: [],
      totals: totals,
      initialDateRange: DateTimeRange(
        start: DateTime(DateTime.now().year, DateTime.now().month, 1),
        end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59),
      ),
      onExportExcel: (range, vehicleId) async {
        // TODO: Implement Excel export
      },
      onExportPdf: (range, vehicleId) async {
        // TODO: Implement PDF export
      },
    );
  }
}