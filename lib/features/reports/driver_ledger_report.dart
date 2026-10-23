import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/reports/report_viewer.dart';
import 'package:transport_hisab/features/reports/report_export_helper.dart';
import 'package:transport_hisab/features/drivers/driver_provider.dart';

class DriverLedgerReport extends ConsumerWidget {
  const DriverLedgerReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final driversAsync = ref.watch(activeDriversProvider);

    return driversAsync.when(
      data: (drivers) {
        final headers = [
          l10n.driverLabel,
          l10n.phoneLabel,
          l10n.monthlySalaryLabel,
          l10n.driverStatusLabel,
        ];

        int totalSalary = 0;
        final rows = <List<String>>[];

        for (final d in drivers) {
          totalSalary += d.monthlySalaryPaisa;
          rows.add([
            d.name,
            d.phone ?? '-',
            formatMoney(Money.paisa(d.monthlySalaryPaisa), context: context),
            d.status == 'active' ? l10n.driverStatusActive : l10n.driverStatusInactive,
          ]);
        }

        final totals = [
          '${l10n.driversNavLabel}: ${drivers.length}',
          '',
          formatMoney(Money.paisa(totalSalary), context: context),
          '',
        ];

        return ReportViewer(
          title: l10n.reportDriverLedger,
          headers: headers,
          rows: rows,
          totals: totals,
          onExportExcel: (range, vehicleId) => ReportExportHelper.exportAndShareExcel(
            title: l10n.reportDriverLedger,
            headers: headers,
            rows: rows,
            totals: totals,
          ),
          onExportPdf: (range, vehicleId) => ReportExportHelper.exportAndSharePdf(
            title: l10n.reportDriverLedger,
            headers: headers,
            rows: rows,
            totals: totals,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }
}
