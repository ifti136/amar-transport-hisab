import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/core/localization/locale_provider.dart';
import 'package:transport_hisab/core/theme/theme_provider.dart';
import 'package:transport_hisab/domain/accounting/accounting.dart';
import 'package:transport_hisab/features/dashboard/dashboard_provider.dart';
import 'package:transport_hisab/features/vehicles/vehicle_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dashboardAsync = ref.watch(dashboardProvider);

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
            Flexible(child: Text(l10n.appTitle)),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show quick actions menu
          _showQuickActions(context);
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.add),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: Text(l10n.addTripTitle),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                context.push('/trips/add');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text(l10n.addExpenseTitle),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                context.push('/expenses/add');
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_gas_station),
              title: Text(l10n.addFuelTitle),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                context.push('/fuel/add');
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
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: dashboard.vanSummaries.length,
                      itemBuilder: (context, index) {
                        final van = dashboard.vanSummaries[index];
                        return _VanSummaryCard(van: van);
                      },
                    ),
                  ),
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

class _VanSummaryCard extends StatelessWidget {
  final VanSummaryData van;

  const _VanSummaryCard({required this.van});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_bus, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        van.regNo,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        van.type,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                _ExpiryBadges(vehicleId: van.vehicleId),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoChip(
                    icon: Icons.route,
                    label: l10n.vanTrips(van.tripCount),
                    value: van.tripCount.toString(),
                  ),
                ),
                Expanded(
                  child: _InfoChip(
                    icon: Icons.trending_up,
                    label: l10n.profit,
                    value: formatMoney(Money.paisa(van.profitPaisa), context: context),
                    color: van.profitPaisa >= 0 ? semantic.success : semantic.danger,
                  ),
                ),
                Expanded(
                  child: _InfoChip(
                    icon: Icons.account_balance_wallet,
                    label: l10n.cashBalance,
                    value: formatMoney(Money.paisa(van.cashBalancePaisa), context: context),
                    color: van.cashBalancePaisa >= 0 ? semantic.success : semantic.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoChip(
              icon: Icons.people,
              label: l10n.totalOutstanding,
              value: formatMoney(Money.paisa(van.outstandingPaisa), context: context),
              color: semantic.warning,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpiryBadges extends ConsumerWidget {
  final int vehicleId;

  const _ExpiryBadges({required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final expiryAsync = ref.watch(vehicleExpiryProvider(vehicleId));

    return expiryAsync.when(
      data: (expiry) {
        final badges = <Widget>[];
        expiry.forEach((type, days) {
          if (days == null) return;
          Color color;
          String label;
          if (days <= 0) {
            color = semantic.danger;
            label = '${type.toUpperCase()}: ${l10n.expiryExpired}';
          } else if (days <= 7) {
            color = semantic.danger;
            label = '${type.toUpperCase()}: ${l10n.expiryDaysLeft(days)}';
          } else if (days <= 30) {
            color = semantic.warning;
            label = '${type.toUpperCase()}: ${l10n.expiryDaysLeft(days)}';
          } else {
            color = semantic.success;
            label = '${type.toUpperCase()}: ${l10n.expiryDaysLeft(days)}';
          }
          badges.add(
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color),
              ),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w500),
              ),
            ),
          );
        });
        return Wrap(spacing: 4, runSpacing: 4, children: badges);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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

    final criticalAlerts = alerts.where((a) => a.daysLeft <= 7).toList();
    if (criticalAlerts.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: semantic.danger.withValues(alpha: 0.1),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: criticalAlerts.map((alert) {
            Color color;
            String label;
            if (alert.daysLeft <= 0) {
              color = semantic.danger;
              label = '${alert.vehicleRegNo} • ${alert.type.toUpperCase()}: ${l10n.expiryExpired}';
            } else {
              color = semantic.danger;
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, required this.value, this.color});

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
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}