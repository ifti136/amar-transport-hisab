import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/features/money/money_provider.dart';
import 'package:transport_hisab/features/money/expense_form.dart';

class ExpenseDetail extends ConsumerWidget {
  final Expense expense;

  const ExpenseDetail({super.key, required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.expenseDetailTitle(expense.id)),
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
          // Expense Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CategoryChip(category: expense.category),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatMoney(Money.paisa(expense.amountPaisa), context: context),
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              formatDate(expense.expenseDate, context: context),
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(label: l10n.categoryLabel, value: _getCategoryLabel(expense.category)),
                  _DetailRow(label: l10n.vehicleLabel, value: 'Vehicle #${expense.vehicleId}'),
                  if (expense.tripId != null)
                    _DetailRow(label: l10n.tripLabel, value: 'Trip #${expense.tripId}'),
                  _DetailRow(label: l10n.dateLabel, value: formatDate(expense.expenseDate, context: context)),
                  if (expense.note != null && expense.note!.isNotEmpty)
                    _DetailRow(label: l10n.noteLabel, value: expense.note!),
                  if (expense.photoPath != null) ...[
                    const SizedBox(height: 16),
                    Text(l10n.receiptPhotoLabel, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(expense.photoPath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

            // Linked Fuel Record (if diesel)
            if (expense.category == 'diesel')
              _LinkedFuelRecord(expenseId: expense.id),
          ],
        ),
    );
  }

  void _showEditForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExpenseForm(expense: expense),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDeleteExpense),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final dao = ref.read(expenseDaoProvider);
              await dao.softDeleteWithAudit(expense.id, userNote: 'Expense deleted');
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ref.invalidate(expensesProvider(const ExpenseFilter()));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
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

class _CategoryChip extends StatelessWidget {
  final String category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    IconData icon;
    String label;

    switch (category) {
      case 'diesel':
        color = theme.colorScheme.primary;
        icon = Icons.local_gas_station;
        label = 'Diesel';
        break;
      case 'toll':
        color = Colors.orange;
        icon = Icons.alt_route;
        label = 'Toll';
        break;
      case 'repair':
        color = Colors.red;
        icon = Icons.build;
        label = 'Repair';
        break;
      case 'maintenance':
        color = Colors.blue;
        icon = Icons.settings;
        label = 'Maintenance';
        break;
      case 'insurance':
        color = Colors.green;
        icon = Icons.security;
        label = 'Insurance';
        break;
      case 'fitness':
        color = Colors.purple;
        icon = Icons.directions_car;
        label = 'Fitness';
        break;
      case 'tax_token':
        color = Colors.teal;
        icon = Icons.receipt;
        label = 'Tax Token';
        break;
      default:
        color = theme.colorScheme.onSurfaceVariant;
        icon = Icons.category;
        label = 'Other';
    }

    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color),
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

class _LinkedFuelRecord extends ConsumerWidget {
  final int expenseId;

  const _LinkedFuelRecord({required this.expenseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return FutureBuilder<FuelRecord?>(
      future: ref.read(fuelDaoProvider).getFuelRecordByExpenseId(expenseId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();
        final fuel = snapshot.data!;

        return Card(
          margin: const EdgeInsets.only(top: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.addFuelTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                _DetailRow(label: l10n.litresLabel, value: formatLitres(fuel.litres, context: context)),
                _DetailRow(label: l10n.rateLabel, value: formatMoney(Money.paisa(fuel.ratePerLitrePaisa), context: context) + '/L'),
                _DetailRow(label: l10n.totalLabel, value: formatMoney(Money.paisa((fuel.ratePerLitrePaisa * fuel.litres).round()), context: context)),
                _DetailRow(label: l10n.odometerLabel, value: '${fuel.odometer} km'),
                _DetailRow(label: l10n.dateLabel, value: formatDate(fuel.fuelDate, context: context)),
              ],
            ),
          ),
        );
      },
    );
  }
}