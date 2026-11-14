import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/core/localization/locale_provider.dart';
import 'package:transport_hisab/core/theme/theme_provider.dart';
import 'package:transport_hisab/domain/accounting/accounting.dart';
import 'package:transport_hisab/features/dashboard/dashboard_provider.dart';
import 'package:transport_hisab/features/vehicles/vehicle_provider.dart';
import 'package:transport_hisab/features/vehicles/vehicles_screen.dart';
import 'package:transport_hisab/features/vehicles/widgets/vehicle_summary_card.dart';
import 'package:transport_hisab/features/trips/trip_provider.dart';
import 'package:transport_hisab/features/trips/trip_form.dart';
import 'package:transport_hisab/features/trips/receive_payment.dart';
import 'package:transport_hisab/features/money/expense_form.dart';
import 'package:transport_hisab/features/customers/customer_provider.dart';
import 'package:transport_hisab/features/customers/customer_form.dart';
import 'package:transport_hisab/features/drivers/driver_provider.dart';
import 'package:transport_hisab/features/drivers/driver_form.dart';
import 'package:transport_hisab/features/drivers/pay_salary.dart';
import 'package:transport_hisab/core/widgets/add_action.dart';
import 'package:transport_hisab/core/widgets/empty_state_view.dart';
import 'package:transport_hisab/core/services/business_name_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dashboardAsync = ref.watch(dashboardProvider);
    final customName = ref.watch(businessNameProvider);
    final displayTitle = customName.trim().isNotEmpty ? customName.trim() : l10n.appTitle;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo.png', // i18n-ignore
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                displayTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => ref.read(localeProvider.notifier).toggle(),
            tooltip: l10n.languageToggle,
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
            tooltip: l10n.themeToggle,
          ),
        ],
      ),
      body: dashboardAsync.when(
        data: (dashboard) => _DashboardContent(dashboard: dashboard),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')), // i18n-ignore
      ),
      floatingActionButton: AddIconFab(
        onPressed: () => _showQuickActions(context),
        tooltip: l10n.quickActionsTitle,
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.local_shipping),
                title: Text(l10n.addTripTitle),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showTripForm(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text(l10n.addExpenseTitle),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showExpenseForm(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_gas_station),
                title: Text(l10n.addFuelTitle),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showFuelForm(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: Text(l10n.receivePaymentAction),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showCustomerPicker(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(l10n.paySalaryTitle),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showDriverPicker(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: Text(l10n.customersNavLabel),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  context.push('/customers');
                },
              ),
            ],
          ),
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

  void _showExpenseForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ExpenseForm(),
    );
  }

  void _showFuelForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ExpenseForm(initialMode: ExpenseEntryMode.fuel),
    );
  }

  void _showCustomerPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _CustomerPickerSheet(
        onSelected: (customer) {
          Navigator.pop(sheetContext);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => ReceivePaymentSheet(customer: customer),
          );
        },
      ),
    );
  }

  void _showDriverPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _DriverPickerSheet(
        onSelected: (driver) {
          Navigator.pop(sheetContext);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => PaySalarySheet(driver: driver),
          );
        },
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final DashboardData dashboard;

  const _DashboardContent({required this.dashboard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardProvider);
      },
      child: CustomScrollView(
        slivers: [
          // Expiry Alert Strip
          if (dashboard.expiryAlerts.isNotEmpty)
            SliverToBoxAdapter(
              child: _ExpiryAlertStrip(alerts: dashboard.expiryAlerts),
            ),

          // 9 Key Figures (3x3 grid)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.95,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final figures = [
                    _FigureData(l10n.totalRevenue, dashboard.totalRevenuePaisa, semantic.success, Icons.trending_up),
                    _FigureData(l10n.totalExpense, dashboard.totalExpensePaisa, semantic.danger, Icons.trending_down),
                    _FigureData(l10n.profit, dashboard.profitPaisa, dashboard.profitPaisa >= 0 ? semantic.success : semantic.danger, Icons.account_balance),
                    _FigureData(l10n.cashReceived, dashboard.cashReceivedPaisa, semantic.success, Icons.arrow_downward),
                    _FigureData(l10n.cashPaid, dashboard.cashPaidPaisa, semantic.danger, Icons.arrow_upward),
                    _FigureData(l10n.cashBalance, dashboard.cashBalancePaisa, dashboard.cashBalancePaisa >= 0 ? semantic.success : semantic.danger, Icons.account_balance_wallet),
                    _FigureData(l10n.totalOutstanding, dashboard.totalOutstandingPaisa, semantic.warning, Icons.people),
                    _FigureData(l10n.loanOutstanding, dashboard.loanOutstandingPaisa, semantic.danger, Icons.account_balance),
                    _FigureData(l10n.driverBalance, dashboard.driverBalancePaisa, semantic.success, Icons.person),
                  ];
                  final figure = figures[index];
                  return _FigureCard(
                    label: figure.label,
                    value: formatMoney(Money.paisa(figure.value), context: context),
                    icon: figure.icon,
                    color: figure.color,
                    isProfitLoss: figure.label == l10n.profit || figure.label == l10n.cashBalance,
                  );
                },
                childCount: 9,
              ),
            ),
          ),

          // Van Summary Cards
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.vanSummaryTitle, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (dashboard.vanSummaries.isEmpty)
                    EmptyStateView(
                      icon: Icons.directions_bus_outlined,
                      title: l10n.emptyVehiclesTitle,
                      message: l10n.emptyVehiclesMessage,
                      action: AddActionButton(
                        onPressed: () => context.push('/vehicles'),
                        label: l10n.addVehicleTitle,
                      ),
                    )
                  else
                    for (final van in dashboard.vanSummaries)
                      _DashboardVanCard(van: van),
                ],
              ),
            ),
          ),

          // Quick Actions (already in FAB)
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _FigureData {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  _FigureData(this.label, this.value, this.color, this.icon);
}

class _FigureCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isProfitLoss;

  const _FigureCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isProfitLoss = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final isProfit = isProfitLoss && !value.startsWith('-') && !value.startsWith('−');
    final isLoss = isProfitLoss && (value.startsWith('-') || value.startsWith('−'));

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isProfit ? semantic.success : (isLoss ? semantic.danger : color),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardVanCard extends ConsumerWidget {
  final VanSummaryData van;

  const _DashboardVanCard({required this.van});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final expiry = ref.watch(vehicleExpiryProvider(van.vehicleId)).asData?.value ?? const {};

    return VehicleSummaryCard(
      regNo: van.regNo,
      type: van.type,
      icon: Icons.directions_bus,
      expiry: expiry,
      onTap: () => context.push('/vehicles'),
      metrics: [
        VehicleSummaryMetric(
          label: l10n.tripsThisMonthLabel,
          value: '${van.tripCount}',
        ),
        VehicleSummaryMetric(
          label: l10n.profitThisMonthLabel,
          value: formatMoney(Money.paisa(van.profitPaisa), context: context),
          valueColor: van.profitPaisa >= 0 ? semantic.success : semantic.danger,
        ),
        VehicleSummaryMetric(
          label: l10n.netCashAllTimeLabel,
          value: formatMoney(Money.paisa(van.cashBalancePaisa), context: context),
          valueColor: van.cashBalancePaisa >= 0 ? semantic.success : semantic.danger,
        ),
        VehicleSummaryMetric(
          label: l10n.tripOutstandingAllTimeLabel,
          value: formatMoney(Money.paisa(van.outstandingPaisa), context: context),
          valueColor: semantic.warning,
        ),
      ],
    );
  }
}

class _CustomerPickerSheet extends ConsumerWidget {
  final ValueChanged<Customer> onSelected;

  const _CustomerPickerSheet({required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final customersAsync = ref.watch(activeCustomersProvider);

    return SafeArea(
      child: customersAsync.when(
        data: (customers) {
          if (customers.isEmpty) {
            return EmptyStateView(
              icon: Icons.people_outline,
              title: l10n.emptyReceivePaymentCustomersTitle,
              message: l10n.emptyReceivePaymentCustomersMessage,
              action: AddActionButton(
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const CustomerForm(),
                  );
                },
                label: l10n.addCustomerTitle,
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.receivePaymentAction, style: Theme.of(context).textTheme.titleMedium),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(customer.name),
                      subtitle: customer.phone == null ? null : Text(customer.phone!),
                      onTap: () => onSelected(customer),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.errorInvalidNumber),
        ),
      ),
    );
  }
}

class _DriverPickerSheet extends ConsumerWidget {
  final ValueChanged<Driver> onSelected;

  const _DriverPickerSheet({required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final driversAsync = ref.watch(activeDriversProvider);

    return SafeArea(
      child: driversAsync.when(
        data: (drivers) {
          if (drivers.isEmpty) {
            return EmptyStateView(
              icon: Icons.person_outline,
              title: l10n.emptyPaySalaryDriversTitle,
              message: l10n.emptyPaySalaryDriversMessage,
              action: AddActionButton(
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const DriverForm(),
                  );
                },
                label: l10n.addDriverTitle,
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.paySalaryTitle, style: Theme.of(context).textTheme.titleMedium),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(driver.name),
                      subtitle: driver.phone == null ? null : Text(driver.phone!),
                      onTap: () => onSelected(driver),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.errorInvalidNumber),
        ),
      ),
    );
  }
}

class _ExpiryAlertStrip extends StatelessWidget {
  final List<ExpiryAlert> alerts;

  const _ExpiryAlertStrip({required this.alerts});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    // Show all alerts up to 30 days (DESIGN.md §14): red ≤7d, amber 8-30d
    final activeAlerts = alerts.where((a) => a.daysLeft <= 30).toList();
    if (activeAlerts.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: semantic.warning.withValues(alpha: 0.1),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: activeAlerts.map((alert) {
            Color color;
            String label;
            if (alert.daysLeft <= 0) {
              color = semantic.danger;
              label = '${alert.vehicleRegNo} • ${alert.type.toUpperCase()}: ${l10n.expiryExpired}';
            } else if (alert.daysLeft <= 7) {
              color = semantic.danger;
              label = '${alert.vehicleRegNo} • ${alert.type.toUpperCase()}: ${l10n.expiryDaysLeft(alert.daysLeft)}';
            } else {
              color = semantic.warning;
              label = '${alert.vehicleRegNo} • ${alert.type.toUpperCase()}: ${l10n.expiryDaysLeft(alert.daysLeft)}';
            }
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, color: color, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
