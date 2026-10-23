import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/reports/report_viewer.dart';
import 'package:transport_hisab/features/reports/report_export_helper.dart';
import 'package:transport_hisab/features/money/money_provider.dart';
import 'package:transport_hisab/features/vehicles/vehicle_provider.dart';

class ExpenseRegisterReport extends ConsumerWidget {
  const ExpenseRegisterReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return _ExpenseRegisterBody(dateRange: DateTimeRange(start: firstDayOfMonth, end: lastDayOfMonth));
  }
}

class _ExpenseRegisterBody extends ConsumerWidget {
  final DateTimeRange dateRange;

  const _ExpenseRegisterBody({required this.dateRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final expensesAsync = ref.watch(expensesProvider(ExpenseFilter(from: dateRange.start, to: dateRange.end)));
    final vehicles = ref.watch(activeVehiclesProvider).asData?.value ?? [];

    return expensesAsync.when(
      data: (expenses) {
        final headers = [
          l10n.dateLabel,
          l10n.categoryLabel,
          l10n.vehicleLabel,
          l10n.amountLabel,
          l10n.noteLabel,
        ];

        int totalAmount = 0;
        final rows = <List<String>>[];

        for (final exp in expenses) {
          totalAmount += exp.amountPaisa;
          final vehicle = vehicles.firstWhereOrNull((v) => v.id == exp.vehicleId);

          rows.add([
            formatDate(exp.expenseDate, short: true, context: context),
            exp.category,
            vehicle?.regNo ?? (exp.vehicleId != null ? 'Vehicle #${exp.vehicleId}' : '-'),
            formatMoney(Money.paisa(exp.amountPaisa), context: context),
            exp.note ?? '',
          ]);
        }

        final totals = [
          'Total: ${expenses.length}', // i18n-ignore
          '',
          '',
          formatMoney(Money.paisa(totalAmount), context: context),
          '',
        ];

        return ReportViewer(
          title: l10n.reportExpenseRegister,
          headers: headers,
          rows: rows,
          totals: totals,
          initialDateRange: dateRange,
          onExportExcel: (range, vehicleId) => ReportExportHelper.exportAndShareExcel(
            title: l10n.reportExpenseRegister,
            headers: headers,
            rows: rows,
            totals: totals,
          ),
          onExportPdf: (range, vehicleId) => ReportExportHelper.exportAndSharePdf(
            title: l10n.reportExpenseRegister,
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
