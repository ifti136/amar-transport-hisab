import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/reports/report_viewer.dart';
import 'package:transport_hisab/features/reports/report_export_helper.dart';
import 'package:transport_hisab/features/vehicles/vehicle_loan_provider.dart';
import 'package:transport_hisab/features/vehicles/vehicle_provider.dart';

class LoanScheduleReport extends ConsumerWidget {
  const LoanScheduleReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final loansAsync = ref.watch(allLoansProvider);
    final vehicles = ref.watch(activeVehiclesProvider).asData?.value ?? [];

    return loansAsync.when(
      data: (loans) {
        final headers = [
          l10n.vehicleLabel,
          'Principal (মূলধন)', // i18n-ignore
          'Rate (সুদ হার)', // i18n-ignore
          l10n.startDateLabel,
        ];

        int totalPrincipal = 0;
        final rows = <List<String>>[];

        for (final loan in loans) {
          totalPrincipal += loan.principalPaisa;
          final vehicle = vehicles.firstWhereOrNull((v) => v.id == loan.vehicleId);

          rows.add([
            vehicle?.regNo ?? 'Vehicle #${loan.vehicleId}',
            formatMoney(Money.paisa(loan.principalPaisa), context: context),
            '${(loan.annualInterestRateBps / 100).toStringAsFixed(2)}%',
            formatDate(loan.startDate, context: context),
          ]);
        }

        final totals = [
          'Total Loans: ${loans.length}', // i18n-ignore
          formatMoney(Money.paisa(totalPrincipal), context: context),
          '',
          '',
        ];

        return ReportViewer(
          title: l10n.reportLoanSchedule,
          headers: headers,
          rows: rows,
          totals: totals,
          onExportExcel: (range, vehicleId) => ReportExportHelper.exportAndShareExcel(
            title: l10n.reportLoanSchedule,
            headers: headers,
            rows: rows,
            totals: totals,
          ),
          onExportPdf: (range, vehicleId) => ReportExportHelper.exportAndSharePdf(
            title: l10n.reportLoanSchedule,
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
