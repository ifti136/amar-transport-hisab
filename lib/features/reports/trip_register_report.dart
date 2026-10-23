import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/reports/report_viewer.dart';
import 'package:transport_hisab/features/reports/report_export_helper.dart';
import 'package:transport_hisab/features/trips/trip_provider.dart';
import 'package:transport_hisab/features/customers/customer_provider.dart';
import 'package:transport_hisab/features/vehicles/vehicle_provider.dart';

class TripRegisterReport extends ConsumerWidget {
  const TripRegisterReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return _TripRegisterReportBody(dateRange: DateTimeRange(start: firstDayOfMonth, end: lastDayOfMonth));
  }
}

class _TripRegisterReportBody extends ConsumerWidget {
  final DateTimeRange dateRange;

  const _TripRegisterReportBody({required this.dateRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tripsAsync = ref.watch(tripsProvider(TripFilter(from: dateRange.start, to: dateRange.end)));
    final customers = ref.watch(activeCustomersProvider).asData?.value ?? [];
    final vehicles = ref.watch(activeVehiclesProvider).asData?.value ?? [];

    return tripsAsync.when(
      data: (trips) {
        final headers = [
          l10n.dateLabel,
          'Trip ID', // i18n-ignore
          l10n.customerLabel,
          l10n.vehicleLabel,
          l10n.fareLabel,
          l10n.advanceLabel,
          l10n.statusLabel,
        ];

        int totalFare = 0;
        int totalAdvance = 0;
        final rows = <List<String>>[];

        for (final trip in trips) {
          totalFare += trip.agreedFarePaisa;
          totalAdvance += trip.advancePaisa;
          final customer = customers.firstWhereOrNull((c) => c.id == trip.customerId);
          final vehicle = vehicles.firstWhereOrNull((v) => v.id == trip.vehicleId);

          rows.add([
            formatDate(trip.tripDate, short: true, context: context),
            'Trip #${trip.id}',
            customer?.name ?? 'Customer #${trip.customerId}',
            vehicle?.regNo ?? 'Vehicle #${trip.vehicleId}',
            formatMoney(Money.paisa(trip.agreedFarePaisa), context: context),
            formatMoney(Money.paisa(trip.advancePaisa), context: context),
            trip.status,
          ]);
        }

        final totals = [
          'Total: ${trips.length}', // i18n-ignore
          '',
          '',
          '',
          formatMoney(Money.paisa(totalFare), context: context),
          formatMoney(Money.paisa(totalAdvance), context: context),
          '',
        ];

        return ReportViewer(
          title: l10n.reportTripRegister,
          headers: headers,
          rows: rows,
          totals: totals,
          initialDateRange: dateRange,
          onExportExcel: (range, vehicleId) => ReportExportHelper.exportAndShareExcel(
            title: l10n.reportTripRegister,
            headers: headers,
            rows: rows,
            totals: totals,
          ),
          onExportPdf: (range, vehicleId) => ReportExportHelper.exportAndSharePdf(
            title: l10n.reportTripRegister,
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
