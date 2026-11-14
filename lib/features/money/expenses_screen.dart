import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/money/money_provider.dart';
import 'package:transport_hisab/features/money/expense_form.dart';
import 'package:transport_hisab/features/money/expense_detail.dart';
import 'package:transport_hisab/features/money/fuel_detail.dart';
import 'package:transport_hisab/features/vehicles/vehicle_provider.dart';
import 'package:transport_hisab/features/trips/trip_provider.dart';
import 'package:transport_hisab/features/trips/trip_form.dart';
import 'package:transport_hisab/features/money/expense_categories_provider.dart';
import 'package:transport_hisab/core/widgets/add_action.dart';
import 'package:transport_hisab/core/widgets/empty_state_view.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
            Tab(text: l10n.generalExpenseOption),
            Tab(text: l10n.tripExpenseOption),
            Tab(text: l10n.fuelExpenseOption),
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
          _ExpensesTab(
            filter: _expenseFilter,
            mode: ExpenseEntryMode.general,
            onFilterChanged: (f) => setState(() => _expenseFilter = f),
          ),
          _TripExpensesTab(
            filter: _expenseFilter,
            onFilterChanged: (f) => setState(() => _expenseFilter = f),
          ),
          _FuelTab(filter: _fuelFilter, onFilterChanged: (f) => setState(() => _fuelFilter = f)),
        ],
      ),

    );
  }

  void _showExpenseForm(BuildContext context, {Expense? expense, FuelRecord? fuel, ExpenseEntryMode initialMode = ExpenseEntryMode.general}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExpenseForm(expense: expense, fuel: fuel, initialMode: initialMode),
    );
  }

  void _showFuelForm(BuildContext context, {FuelRecord? fuel}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExpenseForm(fuel: fuel, initialMode: ExpenseEntryMode.fuel),
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
  final ExpenseEntryMode mode;
  final ValueChanged<ExpenseFilter> onFilterChanged;

  const _ExpensesTab({
    required this.filter,
    required this.mode,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final expensesAsync = ref.watch(expensesProvider(filter));
    final filtered = (expensesAsync.asData?.value ?? const <Expense>[])
        .where((e) => e.tripId == null && e.category != 'diesel')
        .toList();
    final hasFilter = filter.from != null ||
        filter.to != null ||
        filter.vehicleId != null ||
        filter.category != null;

    return Scaffold(
      body: expensesAsync.when(
        data: (expenses) {
          if (filtered.isEmpty) {
            return _emptyState(context, l10n, hasFilter: hasFilter);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final expense = filtered[index];
              return _ExpenseCard(expense: expense);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _errorState(context, ref, l10n, error.toString()),
      ),
      floatingActionButton: filtered.isNotEmpty
          ? AddIconFab(
              onPressed: () => _showExpenseForm(context),
              tooltip: l10n.addExpenseTitle,
            )
          : null,
    );
  }

  Widget _emptyState(
    BuildContext context,
    AppLocalizations l10n, {
    required bool hasFilter,
  }) {
    return EmptyStateView(
      icon: Icons.receipt_long_outlined,
      title: hasFilter ? l10n.noExpensesMatchFilter : l10n.emptyExpensesTitle,
      message: hasFilter
          ? l10n.noExpensesMatchFilterMessage
          : l10n.emptyExpensesMessage,
      action: AddActionButton(
        onPressed: () => _showExpenseForm(context),
        label: l10n.addExpenseTitle,
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
            Text(l10n.errorTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(error, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(expensesProvider(filter)),
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
      builder: (context) => ExpenseForm(expense: expense, initialMode: mode),
    );
  }
}

class _TripExpensesTab extends ConsumerWidget {
  final ExpenseFilter filter;
  final ValueChanged<ExpenseFilter> onFilterChanged;

  const _TripExpensesTab({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final expensesAsync = ref.watch(expensesProvider(filter));
    final tripsAsync = ref.watch(tripsProvider(const TripFilter()));
    final vehicles = ref.watch(activeVehiclesProvider).asData?.value ?? const <Vehicle>[];

    final expenses = expensesAsync.asData?.value ?? const <Expense>[];
    final trips = (tripsAsync.asData?.value ?? const <Trip>[])
        .where((t) => t.status != 'cancelled')
        .toList();

    final groups = <_TripExpenseGroup>[];
    for (final trip in trips) {
      final tripExpenses = expenses
          .where((e) => e.tripId == trip.id && e.tripId != null)
          .toList();
      if (tripExpenses.isEmpty) continue;
      groups.add(_TripExpenseGroup(
        trip: trip,
        expenses: tripExpenses,
        totalPaisa: tripExpenses.fold<int>(0, (sum, e) => sum + e.amountPaisa),
      ));
    }
    groups.sort((a, b) => b.trip.tripDate.compareTo(a.trip.tripDate));

    final hasFilter = filter.from != null ||
        filter.to != null ||
        filter.vehicleId != null ||
        filter.category != null;

    return Scaffold(
      body: () {
        if (expensesAsync.isLoading || tripsAsync.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final error = expensesAsync.error ?? tripsAsync.error;
        if (error != null) {
          return _errorState(context, ref, l10n, error.toString());
        }
        if (trips.isEmpty) {
          return EmptyStateView(
            icon: Icons.local_shipping_outlined,
            title: l10n.noTripsForExpenseTitle,
            message: l10n.noTripsForExpenseMessage,
            action: AddActionButton(
              onPressed: () => _showTripForm(context),
              label: l10n.addTripTitle,
            ),
          );
        }
        if (groups.isEmpty) {
          return EmptyStateView(
            icon: Icons.receipt_long_outlined,
            title: hasFilter
                ? l10n.noExpensesMatchFilter
                : l10n.emptyTripExpensesTitle,
            message: hasFilter
                ? l10n.noExpensesMatchFilterMessage
                : l10n.emptyTripExpensesMessage,
            action: AddActionButton(
              onPressed: () => _showTripExpenseForm(context),
              label: l10n.addTripExpenseButton,
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final vehicle = vehicles.where((v) => v.id == group.trip.vehicleId).firstOrNull;
            final vehicleDisplay = vehicle?.regNo ?? '${l10n.vehicleLabel} #${group.trip.vehicleId}';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(l10n.tripDetailTitle(group.trip.id)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatDate(group.trip.tripDate, context: context)),
                    Text(
                      vehicleDisplay,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                trailing: Text(
                  formatMoney(Money.paisa(group.totalPaisa), context: context),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                onTap: () => _showTripExpensesSheet(
                  context,
                  group,
                  vehicleDisplay,
                ),
              ),
            );
          },
        );
      }(),
      floatingActionButton: groups.isNotEmpty
          ? AddIconFab(
              onPressed: () => _showTripExpenseForm(context),
              tooltip: l10n.addTripExpenseButton,
            )
          : null,
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
            Text(l10n.errorTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(error, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ref.invalidate(expensesProvider(filter));
                ref.invalidate(tripsProvider(const TripFilter()));
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showTripForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const TripForm(),
    );
  }

  void _showTripExpenseForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ExpenseForm(initialMode: ExpenseEntryMode.trip),
    );
  }

  void _showTripExpensesSheet(
    BuildContext context,
    _TripExpenseGroup group,
    String vehicleDisplay,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Consumer(
        builder: (context, sheetRef, _) {
          final l10n = AppLocalizations.of(context)!;
          // The list tab may be filtered; the detail sheet always shows every
          // expense for the selected trip so its total is unambiguous.
          final allExpenses = sheetRef
                  .watch(expensesProvider(const ExpenseFilter()))
                  .asData
                  ?.value
                  .where((e) => e.tripId == group.trip.id)
                  .toList() ??
              group.expenses;
          final totalPaisa =
              allExpenses.fold<int>(0, (sum, e) => sum + e.amountPaisa);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tripDetailTitle(group.trip.id),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(formatDate(group.trip.tripDate, context: context)),
                  Text(
                    vehicleDisplay,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final expense in allExpenses)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                getCategoryDisplayName(
                                  expense.category,
                                  context,
                                ),
                              ),
                              subtitle: expense.note == null || expense.note!.isEmpty
                                  ? null
                                  : Text(expense.note!),
                              trailing: Text(
                                formatMoney(
                                  Money.paisa(expense.amountPaisa),
                                  context: context,
                                ),
                              ),
                            ),
                          const Divider(),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.tripExpensesTotalLabel,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                formatMoney(
                                  Money.paisa(totalPaisa),
                                  context: context,
                                ),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TripExpenseGroup {
  final Trip trip;
  final List<Expense> expenses;
  final int totalPaisa;

  const _TripExpenseGroup({
    required this.trip,
    required this.expenses,
    required this.totalPaisa,
  });
}

class _FuelTab extends ConsumerWidget {
  final FuelFilter filter;
  final ValueChanged<FuelFilter> onFilterChanged;

  const _FuelTab({required this.filter, required this.onFilterChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final fuelAsync = ref.watch(fuelRecordsProvider(filter));

    final records = fuelAsync.asData?.value ?? const <FuelRecord>[];
    final hasFilter = filter.from != null ||
        filter.to != null ||
        filter.vehicleId != null;

    return Scaffold(
      body: fuelAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return _emptyState(context, l10n, hasFilter: hasFilter);
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
      ),
      floatingActionButton: records.isNotEmpty
          ? AddIconFab(
              onPressed: () => _showFuelForm(context),
              tooltip: l10n.addFuelTitle,
            )
          : null,
    );
  }

  Widget _emptyState(
    BuildContext context,
    AppLocalizations l10n, {
    required bool hasFilter,
  }) {
    return EmptyStateView(
      icon: Icons.local_gas_station_outlined,
      title: hasFilter ? l10n.noFuelMatchFilter : l10n.emptyFuelTitle,
      message: hasFilter
          ? l10n.noFuelMatchFilterMessage
          : l10n.emptyFuelMessage,
      action: AddActionButton(
        onPressed: () => _showFuelForm(context),
        label: l10n.addFuelTitle,
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
            Text(l10n.errorTitle, style: Theme.of(context).textTheme.headlineSmall),
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
      builder: (context) => ExpenseForm(fuel: fuel, initialMode: ExpenseEntryMode.fuel),
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
                      value: _getCategoryLabel(l10n, expense.category),
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

  String _getCategoryLabel(AppLocalizations l10n, String category) {
    switch (category) {
      case 'diesel': return l10n.category_diesel;
      case 'toll': return l10n.category_toll;
      case 'repair': return l10n.category_repair;
      case 'maintenance': return l10n.category_maintenance;
      case 'insurance': return l10n.category_insurance;
      case 'fitness': return l10n.category_fitness;
      case 'tax_token': return l10n.category_tax_token;
      default: return l10n.category_other;
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