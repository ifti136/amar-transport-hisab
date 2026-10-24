import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/core/widgets/app_toast.dart';
import 'package:transport_hisab/features/dashboard/dashboard_provider.dart';
import 'package:transport_hisab/features/drivers/driver_provider.dart';
import 'package:transport_hisab/features/drivers/driver_form.dart';
import 'package:transport_hisab/features/drivers/driver_ledger.dart';
import 'package:transport_hisab/features/drivers/pay_salary.dart';
import 'package:transport_hisab/features/drivers/give_advance.dart';

class DriverDetail extends ConsumerWidget {
  final Driver driver;

  const DriverDetail({super.key, required this.driver});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(driver.name),
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
          // Driver Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.person, size: 30, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(driver.name, style: theme.textTheme.headlineSmall),
                            if (driver.phone != null && driver.phone!.isNotEmpty)
                              Text(driver.phone!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
                          driver.status == 'active' ? l10n.driverStatusActive : l10n.driverStatusInactive,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: driver.status == 'active'
                                ? theme.extension<AppSemanticColors>()!.success
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(label: l10n.monthlySalaryLabel, value: formatMoney(Money.paisa(driver.monthlySalaryPaisa), context: context)),
                  _DetailRow(label: l10n.joinedDateLabel, value: formatDate(driver.joinedDate, context: context)),
                  _DetailRow(label: l10n.driverStatusLabel, value: driver.status == 'active' ? l10n.driverStatusActive : l10n.driverStatusInactive),
                  _DetailRow(label: 'Created', value: formatDate(driver.createdAt, context: context)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Actions
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.assignment),
                  title: Text(l10n.reportDriverLedger),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DriverLedgerScreen(driver: driver)),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.payments),
                  title: Text(l10n.paySalaryTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => PaySalarySheet(driver: driver),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: Text(l10n.giveAdvanceTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => GiveAdvanceSheet(driver: driver),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DriverForm(driver: driver),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDeleteDriver),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final dao = ref.read(driverDaoProvider);
                await dao.softDeleteWithAudit(driver.id, userNote: 'Driver deleted');
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close detail screen
                  ref.invalidate(activeDriversProvider);
                  ref.invalidate(allDriversProvider);
                  ref.invalidate(dashboardProvider);
                  AppToast.showSuccess(context, l10n.deleteSuccess);
                }
              } catch (e) {
                if (context.mounted) {
                  AppToast.showError(context, l10n.operationFailed(e.toString()));
                }
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