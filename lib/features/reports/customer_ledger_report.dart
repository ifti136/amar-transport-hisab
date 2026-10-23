import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/reports/report_viewer.dart';
import 'package:transport_hisab/features/reports/report_export_helper.dart';
import 'package:transport_hisab/features/customers/customer_provider.dart';

class CustomerLedgerReport extends ConsumerWidget {
  const CustomerLedgerReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final customersAsync = ref.watch(activeCustomersProvider);

    return customersAsync.when(
      data: (customers) {
        final headers = [
          l10n.customerLabel,
          l10n.phoneLabel,
          l10n.customerOpeningLabel,
        ];

        int totalOpening = 0;
        final rows = <List<String>>[];

        for (final c in customers) {
          totalOpening += c.openingBalancePaisa;
          rows.add([
            c.name,
            c.phone ?? '-',
            formatMoney(Money.paisa(c.openingBalancePaisa), context: context),
          ]);
        }

        final totals = [
          '${l10n.customersNavLabel}: ${customers.length}',
          '',
          formatMoney(Money.paisa(totalOpening), context: context),
        ];

        return ReportViewer(
          title: l10n.reportCustomerLedger,
          headers: headers,
          rows: rows,
          totals: totals,
          onExportExcel: (range, vehicleId) => ReportExportHelper.exportAndShareExcel(
            title: l10n.reportCustomerLedger,
            headers: headers,
            rows: rows,
            totals: totals,
          ),
          onExportPdf: (range, vehicleId) => ReportExportHelper.exportAndSharePdf(
            title: l10n.reportCustomerLedger,
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
