import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/money/money_provider.dart';
import 'package:transport_hisab/features/money/fuel_form.dart';

class FuelDetail extends ConsumerWidget {
  final FuelRecord record;

  const FuelDetail({super.key, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fuelDetailTitle(record.id)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditForm(context),
            tooltip: l10n.edit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
            tooltip: l10n.delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Fuel Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.local_gas_station, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.fuelDetailTitle(record.id), style: theme.textTheme.headlineSmall),
                            Text(
                              formatDate(record.fuelDate, context: context),
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(label: l10n.vehicleLabel, value: 'Vehicle #${record.vehicleId}'),
                  _DetailRow(label: l10n.litresLabel, value: formatLitres(record.litres, context: context)),
                  _DetailRow(label: l10n.rateLabel, value: formatMoney(Money.paisa(record.ratePerLitrePaisa), context: context) + '/L'),
                  _DetailRow(label: l10n.totalLabel, value: formatMoney(Money.paisa((record.ratePerLitrePaisa * record.litres).round()), context: context)),
                  _DetailRow(label: l10n.odometerLabel, value: '${record.odometer} km'),
                  _DetailRow(label: l10n.dateLabel, value: formatDate(record.fuelDate, context: context)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Linked Expense
          _LinkedExpense(expenseId: record.expenseId),
        ],
      ),
    );
  }

  void _showEditForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FuelForm(fuel: record),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDeleteFuel),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final dao = ref.read(fuelDaoProvider);
              await dao.softDeleteWithAudit(record.id, userNote: 'Fuel record deleted');
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ref.invalidate(fuelRecordsProvider(const FuelFilter()));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _LinkedExpense extends ConsumerWidget {
  final int expenseId;

  const _LinkedExpense({required this.expenseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return FutureBuilder<Expense?>(
      future: ref.read(expenseDaoProvider).getById(expenseId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();
        final expense = snapshot.data!;

        return Card(
          margin: const EdgeInsets.only(top: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.addExpenseTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                _DetailRow(label: l10n.categoryLabel, value: _getCategoryLabel(expense.category)),
                _DetailRow(label: l10n.amountLabel, value: formatMoney(Money.paisa(expense.amountPaisa), context: context)),
                _DetailRow(label: l10n.dateLabel, value: formatDate(expense.expenseDate, context: context)),
                if (expense.note != null && expense.note!.isNotEmpty)
                  _DetailRow(label: l10n.noteLabel, value: expense.note!),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'diesel': return 'Diesel';
      case 'toll': return 'Toll';
      case 'repair': return 'Repair';
      case 'maintenance': return 'Maintenance';
      case 'insurance': return 'Insurance';
      case 'fitness': return 'Fitness';
      case 'tax_token': return 'Tax Token';
      default: return 'Other';
    }
  }
}