import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/db/daos/customer_dao.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/features/customers/customer_provider.dart';
import 'package:transport_hisab/features/trips/receive_payment.dart';

class CustomerLedgerScreen extends ConsumerWidget {
  final Customer customer;

  const CustomerLedgerScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final ledgerAsync = ref.watch(customerLedgerProvider(
      CustomerLedgerFilter(
        customerId: customer.id,
        from: firstDayOfMonth,
        to: lastDayOfMonth,
      ),
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showDateRangePicker(context, ref),
            tooltip: l10n.filter,
          ),
        ],
      ),
      body: ledgerAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return _emptyState(context, l10n);
          }
          return Column(
            children: [
              // Summary Card
              _SummaryCard(customer: customer, entries: entries),
              // Ledger List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _LedgerEntryTile(entry: entry);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.errorLoadingLedger)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReceivePayment(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.add),
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
            Icon(Icons.receipt_long_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              l10n.noTransactionsYet,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addTripOrPaymentToSeeLedger,
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

  void _showDateRangePicker(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.dateRangePickerComingSoon)),
    );
  }

  void _showReceivePayment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReceivePaymentSheet(customer: customer),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  final Customer customer;
  final List<CustomerLedgerEntry> entries;

  const _SummaryCard({required this.customer, required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    final openingBalance = customer.openingBalancePaisa;
    final totalFares = entries.where((e) => e.type == 'trip').fold<int>(0, (sum, e) => sum + e.amount);
    final totalPayments = entries.where((e) => e.type == 'payment').fold<int>(0, (sum, e) => sum + e.amount.abs());
    final closingBalance = entries.isNotEmpty ? entries.last.balance : openingBalance;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.reportCustomerLedger, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: l10n.openingCashLabel,
                    value: formatMoney(Money.paisa(openingBalance), context: context),
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: l10n.totalFares,
                    value: formatMoney(Money.paisa(totalFares), context: context),
                    color: semantic.success,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: l10n.totalPayments,
                    value: formatMoney(Money.paisa(totalPayments), context: context),
                    color: semantic.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.cashBalance, style: theme.textTheme.titleMedium),
                Text(
                  formatMoney(Money.paisa(closingBalance), context: context),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: closingBalance >= 0 ? semantic.success : semantic.danger,
                    fontWeight: FontWeight.bold,
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
  final CustomerLedgerEntry entry;

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