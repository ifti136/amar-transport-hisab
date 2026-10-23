import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/drivers/driver_provider.dart';
import 'package:transport_hisab/features/drivers/driver_form.dart';
import 'package:transport_hisab/features/drivers/driver_detail.dart';

class DriversScreen extends ConsumerWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final driversAsync = ref.watch(activeDriversProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.driverLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showDriverForm(context),
            tooltip: l10n.add,
          ),
        ],
      ),
      body: driversAsync.when(
        data: (drivers) {
          if (drivers.isEmpty) {
            return _emptyState(context, l10n);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index];
              return _DriverCard(driver: driver);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _errorState(context, ref, l10n, error.toString()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDriverForm(context),
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
            Icon(Icons.person_outline, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No drivers yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first driver to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showDriverForm(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.add),
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
              onPressed: () => ref.invalidate(activeDriversProvider),
              child: Text(l10n.save), // Reuse "Retry"
            ),
          ],
        ),
      ),
    );
  }

  void _showDriverForm(BuildContext context, {Driver? driver}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DriverForm(driver: driver),
    );
  }
}

class _DriverCard extends ConsumerWidget {
  final Driver driver;

  const _DriverCard({required this.driver});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DriverDetail(driver: driver)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.person, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (driver.phone != null && driver.phone!.isNotEmpty)
                      Text(
                        driver.phone!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${l10n.vanProfit(formatMoney(Money.paisa(driver.monthlySalaryPaisa), context: context))}/month',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: driver.status == 'active'
                      ? theme.extension<AppSemanticColors>()!.success.withValues(alpha: 0.1)
                      : theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  driver.status == 'active' ? 'Active' : 'Inactive',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: driver.status == 'active'
                        ? theme.extension<AppSemanticColors>()!.success
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}