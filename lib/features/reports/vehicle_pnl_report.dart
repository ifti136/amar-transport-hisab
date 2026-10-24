import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/reports/report_viewer.dart';
import 'package:transport_hisab/features/reports/report_export_helper.dart';
import 'package:transport_hisab/features/dashboard/dashboard_provider.dart';

class VehiclePnLReport extends ConsumerStatefulWidget {
  const VehiclePnLReport({super.key});

  @override
  ConsumerState<VehiclePnLReport> createState() => _VehiclePnLReportState();
}

class _VehiclePnLReportState extends ConsumerState<VehiclePnLReport> {
  int? _vehicleId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dashboardAsync = ref.watch(dashboardProvider);

    return dashboardAsync.when(
      data: (dashboard) {
        final headers = [
          l10n.vehicleLabel,
          l10n.tripsTab,
          l10n.profit,
        ];

        int totalTrips = 0;
        int totalProfit = 0;
        final rows = <List<String>>[];

        final filteredVans = _vehicleId != null
            ? dashboard.vanSummaries.where((v) => v.vehicleId == _vehicleId).toList()
            : dashboard.vanSummaries;

        for (final van in filteredVans) {
          totalTrips += van.tripCount;
          totalProfit += van.profitPaisa;

          rows.add([
            van.regNo,
            '${van.tripCount}',
            formatMoney(Money.paisa(van.profitPaisa), context: context),
          ]);
        }

        final totals = [
          '${l10n.vehicleLabel}: ${filteredVans.length}',
          '$totalTrips',
          formatMoney(Money.paisa(totalProfit), context: context),
        ];

        return ReportViewer(
          title: l10n.reportVehiclePL,
          headers: headers,
          rows: rows,
          totals: totals,
          selectedVehicleId: _vehicleId,
          onVehicleChanged: (id) => setState(() => _vehicleId = id),
          onExportExcel: (range, vehicleId) => ReportExportHelper.exportAndShareExcel(
            title: l10n.reportVehiclePL,
            headers: headers,
            rows: rows,
            totals: totals,
          ),
          onExportPdf: (range, vehicleId) => ReportExportHelper.exportAndSharePdf(
            title: l10n.reportVehiclePL,
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
