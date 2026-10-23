import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/reports/report_viewer.dart';
import 'package:transport_hisab/features/reports/report_export_helper.dart';
import 'package:transport_hisab/features/dashboard/dashboard_provider.dart';

class CashFlowReport extends ConsumerWidget {
  const CashFlowReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dashboardAsync = ref.watch(dashboardProvider);

    return dashboardAsync.when(
        data: (dashboard) {
          final headers = [
            'Description', // i18n-ignore
            'Inflow (৳)', // i18n-ignore
            'Outflow (৳)', // i18n-ignore
            'Net (৳)', // i18n-ignore
          ];

          final rows = [
            [
              'Customer Collections', // i18n-ignore
              formatMoney(Money.paisa(dashboard.cashReceivedPaisa), context: context),
              '-',
              formatMoney(Money.paisa(dashboard.cashReceivedPaisa), context: context),
            ],
            [
              'Operating & Fleet Expenses', // i18n-ignore
              '-',
              formatMoney(Money.paisa(dashboard.totalExpensePaisa), context: context),
              '-${formatMoney(Money.paisa(dashboard.totalExpensePaisa), context: context)}',
            ],
            [
              'Driver & Loan Disbursements', // i18n-ignore
              '-',
              formatMoney(Money.paisa(dashboard.cashPaidPaisa - dashboard.totalExpensePaisa), context: context),
              '-',
            ],
          ];

          final totals = [
            'Net Cash Balance', // i18n-ignore
            formatMoney(Money.paisa(dashboard.cashReceivedPaisa), context: context),
            formatMoney(Money.paisa(dashboard.cashPaidPaisa), context: context),
            formatMoney(Money.paisa(dashboard.cashBalancePaisa), context: context),
          ];

          return ReportViewer(
            title: l10n.reportCashFlow,
            headers: headers,
            rows: rows,
            totals: totals,
            onExportExcel: (range, vehicleId) => ReportExportHelper.exportAndShareExcel(
              title: l10n.reportCashFlow,
              headers: headers,
              rows: rows,
              totals: totals,
            ),
            onExportPdf: (range, vehicleId) => ReportExportHelper.exportAndSharePdf(
              title: l10n.reportCashFlow,
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
