import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/features/drivers/driver_account_provider.dart';
import 'package:transport_hisab/features/drivers/pay_salary.dart';
import 'package:transport_hisab/features/drivers/give_advance.dart';
import 'package:transport_hisab/features/drivers/driver_loan.dart';

class DriverLedgerScreen extends ConsumerWidget {
  final Driver driver;

  const DriverLedgerScreen({super.key, required this.driver});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final ledgerAsync = ref.watch(driverLedgerProvider(
      DriverLedgerFilter(
        driverId: driver.id,
        from: firstDayOfMonth,
        to: lastDayOfMonth,
      ),
    ));

    final balanceAsync = ref.watch(driverBalanceProvider(
      DriverBalanceFilter(driverId: driver.id, upTo: lastDayOfMonth),
    ));

    final outstandingAdvanceAsync = ref.watch(outstandingAdvanceProvider(
      OutstandingAdvanceFilter(driverId: driver.id, upTo: lastDayOfMonth),
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(driver.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'pay_salary':
                  _showPaySalary(context, ref);
                  break;
                case 'give_advance':
                  _showGiveAdvance(context, ref);
                  break;
                case 'driver_loan':
                  _showDriverLoan(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'pay_salary', child: Text(l10n.paySalaryTitle)),
              PopupMenuItem(value: 'give_advance', child: Text(l10n.giveAdvanceTitle)),
              PopupMenuItem(value: 'driver_loan', child: Text(l10n.driverLoanTitle)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          _SummaryCards(
            balanceAsync: balanceAsync,
            outstandingAdvanceAsync: outstandingAdvanceAsync,
            driver: driver,
          ),
          // Ledger List
          Expanded(
            child: ledgerAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return _emptyState(context, l10n);
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _LedgerEntryTile(entry: entry);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')), // i18n-ignore
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Salary, advances, and loans will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showPaySalary(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PaySalarySheet(driver: driver),
    );
  }

  void _showGiveAdvance(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => GiveAdvanceSheet(driver: driver),
    );
  }

  void _showDriverLoan(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DriverLoanSheet(driver: driver),
    );
  }
}

class _SummaryCards extends ConsumerWidget {
  final AsyncValue<int> balanceAsync;
  final AsyncValue<int> outstandingAdvanceAsync;
  final Driver driver;

  const _SummaryCards({
    required this.balanceAsync,
    required this.outstandingAdvanceAsync,
    required this.driver,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.reportDriverLedger, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: l10n.cashBalance,
                    value: balanceAsync.when(
                      data: (v) => formatMoney(Money.paisa(v), context: context),
                      loading: () => '...',
                      error: (_, __) => 'Error',
                    ),
                    color: semantic.success,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Outstanding Advance',
                    value: outstandingAdvanceAsync.when(
                      data: (v) => formatMoney(Money.paisa(v), context: context),
                      loading: () => '...',
                      error: (_, __) => 'Error',
                    ),
                    color: semantic.warning,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Monthly Salary',
                    value: formatMoney(Money.paisa(driver.monthlySalaryPaisa), context: context),
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _LedgerEntryTile extends StatelessWidget {
  final DriverLedgerEntry entry;

  const _LedgerEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final isPositive = entry.amount > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isPositive ? semantic.success : semantic.danger).withValues(alpha: 0.1),
          child: Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            color: isPositive ? semantic.success : semantic.danger,
            size: 20,
          ),
        ),
        title: Text(entry.description, style: theme.textTheme.titleMedium),
        subtitle: Text(
          formatDate(entry.date, context: context),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isPositive ? '+' : ''}${formatMoney(Money.paisa(entry.amount), context: context)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isPositive ? semantic.success : semantic.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Bal: ${formatMoney(Money.paisa(entry.balance), context: context)}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}