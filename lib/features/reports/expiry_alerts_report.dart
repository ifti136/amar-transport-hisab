import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/features/reports/report_viewer.dart';
import 'package:transport_hisab/features/reports/report_export_helper.dart';
import 'package:transport_hisab/core/services/expiry_alert_service.dart';

class ExpiryAlertsReport extends ConsumerWidget {
  const ExpiryAlertsReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final alerts = ref.watch(vehicleExpiryAlertsListProvider);

    final headers = [
      l10n.vehicleLabel,
      'Document', // i18n-ignore
      'Expiry Date', // i18n-ignore
      'Days Left', // i18n-ignore
      l10n.statusLabel,
    ];

    final rows = alerts.map((item) {
      return [
        item.regNo,
        item.documentType,
        item.expiryDate,
        '${item.daysRemaining}',
        item.isExpired ? 'Expired' : 'Active', // i18n-ignore
      ];
    }).toList();

    final totals = [
      'Total Alerts: ${alerts.length}', // i18n-ignore
      '',
      '',
      '',
      '',
    ];

    return ReportViewer(
      title: l10n.reportExpiryAlerts,
      headers: headers,
      rows: rows,
      totals: totals,
      onExportExcel: (range, vehicleId) => ReportExportHelper.exportAndShareExcel(
        title: l10n.reportExpiryAlerts,
        headers: headers,
        rows: rows,
        totals: totals,
      ),
      onExportPdf: (range, vehicleId) => ReportExportHelper.exportAndSharePdf(
        title: l10n.reportExpiryAlerts,
        headers: headers,
        rows: rows,
        totals: totals,
      ),
    );
  }
}
