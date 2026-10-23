import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/features/reports/trip_register_report.dart';
import 'package:transport_hisab/features/reports/customer_ledger_report.dart';
import 'package:transport_hisab/features/reports/driver_ledger_report.dart';
import 'package:transport_hisab/features/reports/expense_register_report.dart';
import 'package:transport_hisab/features/reports/fuel_register_report.dart';
import 'package:transport_hisab/features/reports/vehicle_pnl_report.dart';
import 'package:transport_hisab/features/reports/cash_flow_report.dart';
import 'package:transport_hisab/features/reports/loan_schedule_report.dart';
import 'package:transport_hisab/features/reports/expiry_alerts_report.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final reports = [
      _ReportItem(
        title: l10n.reportTripRegister,
        icon: Icons.local_shipping,
        route: '/reports/trip_register',
        builder: (context) => const TripRegisterReport(),
      ),
      _ReportItem(
        title: l10n.reportCustomerLedger,
        icon: Icons.people,
        route: '/reports/customer_ledger',
        builder: (context) => const CustomerLedgerReport(),
      ),
      _ReportItem(
        title: l10n.reportDriverLedger,
        icon: Icons.person,
        route: '/reports/driver_ledger',
        builder: (context) => const DriverLedgerReport(),
      ),
      _ReportItem(
        title: l10n.reportExpenseRegister,
        icon: Icons.receipt_long,
        route: '/reports/expense_register',
        builder: (context) => const ExpenseRegisterReport(),
      ),
      _ReportItem(
        title: l10n.reportFuelRegister,
        icon: Icons.local_gas_station,
        route: '/reports/fuel_register',
        builder: (context) => const FuelRegisterReport(),
      ),
      _ReportItem(
        title: l10n.reportVehiclePL,
        icon: Icons.trending_up,
        route: '/reports/vehicle_pnl',
        builder: (context) => const VehiclePnLReport(),
      ),
      _ReportItem(
        title: l10n.reportCashFlow,
        icon: Icons.account_balance_wallet,
        route: '/reports/cash_flow',
        builder: (context) => const CashFlowReport(),
      ),
      _ReportItem(
        title: l10n.reportLoanSchedule,
        icon: Icons.account_balance,
        route: '/reports/loan_schedule',
        builder: (context) => const LoanScheduleReport(),
      ),
      _ReportItem(
        title: l10n.reportExpiryAlerts,
        icon: Icons.warning,
        route: '/reports/expiry_alerts',
        builder: (context) => const ExpiryAlertsReport(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsNavLabel)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(report.icon, color: Theme.of(context).colorScheme.primary),
              ),
              title: Text(report.title, style: Theme.of(context).textTheme.titleMedium),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: report.builder),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ReportItem {
  final String title;
  final IconData icon;
  final String route;
  final Widget Function(BuildContext) builder;

  _ReportItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.builder,
  });
}