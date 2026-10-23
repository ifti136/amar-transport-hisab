import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/reports/report_viewer.dart';
import 'package:transport_hisab/features/reports/report_export_helper.dart';
import 'package:transport_hisab/features/money/money_provider.dart';
import 'package:transport_hisab/features/vehicles/vehicle_provider.dart';

class FuelRegisterReport extends ConsumerWidget {
  const FuelRegisterReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return _FuelRegisterBody(dateRange: DateTimeRange(start: firstDayOfMonth, end: lastDayOfMonth));
  }
}

class _FuelRegisterBody extends ConsumerWidget {
  final DateTimeRange dateRange;

  const _FuelRegisterBody({required this.dateRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final fuelAsync = ref.watch(fuelRecordsProvider(FuelFilter(from: dateRange.start, to: dateRange.end)));
    final vehicles = ref.watch(activeVehiclesProvider).asData?.value ?? [];

    return fuelAsync.when(
      data: (records) {
        final headers = [
          l10n.dateLabel,
          l10n.vehicleLabel,
          l10n.litresLabel,
          l10n.rateLabel,
          l10n.amountLabel,
          l10n.odometerLabel,
        ];

        double totalLitres = 0;
        int totalCost = 0;
        final rows = <List<String>>[];

        for (final r in records) {
          totalLitres += r.litres;
          final cost = (r.litres * r.ratePerLitrePaisa).round();
          totalCost += cost;
          final vehicle = vehicles.firstWhereOrNull((v) => v.id == r.vehicleId);

          rows.add([
            formatDate(r.fuelDate, short: true, context: context),
            vehicle?.regNo ?? 'Vehicle #${r.vehicleId}',
            formatLitres(r.litres, context: context),
            formatMoney(Money.paisa(r.ratePerLitrePaisa), context: context),
            formatMoney(Money.paisa(cost), context: context),
            formatKm(r.odometer, context: context),
          ]);
        }

        final totals = [
          'Total: ${records.length}', // i18n-ignore
          '',
          formatLitres(totalLitres, context: context),
          '',
          formatMoney(Money.paisa(totalCost), context: context),
          '',
        ];

        return ReportViewer(
          title: l10n.reportFuelRegister,
          headers: headers,
          rows: rows,
          totals: totals,
          initialDateRange: dateRange,
          onExportExcel: (range, vehicleId) => ReportExportHelper.exportAndShareExcel(
            title: l10n.reportFuelRegister,
            headers: headers,
            rows: rows,
            totals: totals,
          ),
          onExportPdf: (range, vehicleId) => ReportExportHelper.exportAndSharePdf(
            title: l10n.reportFuelRegister,
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
