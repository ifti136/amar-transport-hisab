import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/money/money_provider.dart';
import 'package:transport_hisab/features/money/expense_form.dart';
import 'package:transport_hisab/features/money/fuel_form.dart';
import 'package:transport_hisab/features/money/expense_detail.dart';
import 'package:transport_hisab/features/money/fuel_detail.dart';
import 'package:transport_hisab/features/vehicles/vehicle_provider.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ExpenseFilter _expenseFilter = const ExpenseFilter();
  FuelFilter _fuelFilter = const FuelFilter();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moneyTab),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.categoryLabel), // Reuse "Category" as "Expenses"
            Tab(text: l10n.addFuelTitle), // Reuse "New Fuel" as "Fuel"
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: l10n.filter,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ExpensesTab(filter: _expenseFilter, onFilterChanged: (f) => setState(() => _expenseFilter = f)),
          _FuelTab(filter: _fuelFilter, onFilterChanged: (f) => setState(() => _fuelFilter = f)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showExpenseForm(context);
          } else {
            _showFuelForm(context);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? l10n.addExpenseTitle : l10n.addFuelTitle),
      ),
    );
  }

  void _showExpenseForm(BuildContext context, {Expense? expense}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExpenseForm(expense: expense),
    );
  }

  void _showFuelForm(BuildContext context, {FuelRecord? fuel}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FuelForm(fuel: fuel),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        expenseFilter: _expenseFilter,
        fuelFilter: _fuelFilter,
        onExpenseFilterChanged: (f) => setState(() => _expenseFilter = f),
        onFuelFilterChanged: (f) => setState(() => _fuelFilter = f),
      ),
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  final ExpenseFilter filter;
  final ValueChanged<ExpenseFilter> onFilterChanged;

  const _ExpensesTab({required this.filter, required this.onFilterChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final expensesAsync = ref.watch(expensesProvider(filter));

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return _emptyState(context, l10n);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return _ExpenseCard(expense: expense);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _errorState(context, ref, l10n, error.toString()),
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
              'No expenses yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first expense to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showExpenseForm(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.addExpenseTitle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context, WidgetRef ref, AppLocalizations l10n, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(l10n.errorInvalidNumber, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(error, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(expensesProvider(ExpenseFilter())),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseForm(BuildContext context, {Expense? expense}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExpenseForm(expense: expense),
    );
  }
}

class _FuelTab extends ConsumerWidget {
  final FuelFilter filter;
  final ValueChanged<FuelFilter> onFilterChanged;

  const _FuelTab({required this.filter, required this.onFilterChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final fuelAsync = ref.watch(fuelRecordsProvider(filter));

    return fuelAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return _emptyState(context, l10n);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return _FuelCard(record: record);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _errorState(context, ref, l10n, error.toString()),
    );
  }

  Widget _emptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_gas_station_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No fuel records yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first fuel purchase to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showFuelForm(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.addFuelTitle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context, WidgetRef ref, AppLocalizations l10n, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(l10n.errorInvalidNumber, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(error, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(fuelRecordsProvider(FuelFilter())),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showFuelForm(BuildContext context, {FuelRecord? fuel}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FuelForm(fuel: fuel),
    );
  }
}

class _ExpenseCard extends ConsumerWidget {
  final Expense expense;

  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final vehicles = ref.watch(activeVehiclesProvider).asData?.value;
    final vehicle = vehicles?.firstWhereOrNull((v) => v.id == expense.vehicleId);
    final vehicleDisplay = vehicle?.regNo ?? 'Vehicle #${expense.vehicleId}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ExpenseDetail(expense: expense)),
        ),
        borderRadius: BorderRadius.circular(12),
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
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          formatDate(expense.expenseDate, context: context),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (expense.photoPath != null)
                    const Icon(Icons.photo, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.directions_bus,
                      label: l10n.vehicleLabel,
                      value: vehicleDisplay,
                    ),
                  ),
                  if (expense.tripId != null)
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.local_shipping,
                        label: l10n.tripLabel,
                        value: 'Trip #${expense.tripId}',
                      ),
                    ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.category,
                      label: l10n.categoryLabel,
                      value: _getCategoryLabel(expense.category),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

class _FuelCard extends ConsumerWidget {
  final FuelRecord record;

  const _FuelCard({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final vehicles = ref.watch(activeVehiclesProvider).asData?.value;
    final vehicle = vehicles?.firstWhereOrNull((v) => v.id == record.vehicleId);
    final vehicleDisplay = vehicle?.regNo ?? 'Vehicle #${record.vehicleId}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FuelDetail(record: record)),
        ),
        borderRadius: BorderRadius.circular(12),
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
                        Text(
                          'Fuel #${record.id}',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          formatDate(record.fuelDate, context: context),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.local_gas_station,
                      label: l10n.litresLabel,
                      value: formatLitres(record.litres, context: context),
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.attach_money,
                      label: l10n.rateLabel,
                      value: formatMoney(Money.paisa(record.ratePerLitrePaisa), context: context) + '/L',
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.attach_money,
                      label: l10n.totalLabel,
                      value: formatMoney(Money.paisa((record.ratePerLitrePaisa * record.litres).round()), context: context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.speed,
                      label: l10n.odometerLabel,
                      value: '${record.odometer} km',
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.directions_bus,
                      label: l10n.vehicleLabel,
                      value: vehicleDisplay,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _FilterDialog extends ConsumerStatefulWidget {
  final ExpenseFilter expenseFilter;
  final FuelFilter fuelFilter;
  final ValueChanged<ExpenseFilter> onExpenseFilterChanged;
  final ValueChanged<FuelFilter> onFuelFilterChanged;

  const _FilterDialog({
    required this.expenseFilter,
    required this.fuelFilter,
    required this.onExpenseFilterChanged,
    required this.onFuelFilterChanged,
  });

  @override
  ConsumerState<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends ConsumerState<_FilterDialog> {
  DateTime? _from;
  DateTime? _to;
  int? _vehicleId;

  @override
  void initState() {
    super.initState();
    _from = widget.expenseFilter.from ?? widget.fuelFilter.from;
    _to = widget.expenseFilter.to ?? widget.fuelFilter.to;
    _vehicleId = widget.expenseFilter.vehicleId ?? widget.fuelFilter.vehicleId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vehiclesAsync = ref.watch(activeVehiclesProvider);

    return AlertDialog(
      title: Text(l10n.filter),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.dateRangeLabel),
              subtitle: Text(
                _from != null && _to != null
                    ? '${formatDate(_from!, short: true)} - ${formatDate(_to!, short: true)}'
                    : l10n.allVehicles,
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDateRange: _from != null && _to != null
                      ? DateTimeRange(start: _from!, end: _to!)
                      : null,
                );
                if (range != null) {
                  setState(() {
                    _from = range.start;
                    _to = range.end;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            vehiclesAsync.when(
              data: (vehicles) => DropdownButtonFormField<int?>(
                value: _vehicleId,
                decoration: InputDecoration(labelText: l10n.vehicleFilterLabel),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.allVehicles)),
                  ...vehicles.map((v) => DropdownMenuItem(value: v.id, child: Text(v.regNo))),
                ],
                onChanged: (id) => setState(() => _vehicleId = id),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onExpenseFilterChanged(const ExpenseFilter());
            widget.onFuelFilterChanged(const FuelFilter());
            Navigator.pop(context);
          },
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            widget.onExpenseFilterChanged(widget.expenseFilter.copyWith(
              from: _from,
              to: _to,
              vehicleId: _vehicleId,
            ));
            widget.onFuelFilterChanged(widget.fuelFilter.copyWith(
              from: _from,
              to: _to,
              vehicleId: _vehicleId,
            ));
            Navigator.pop(context);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}