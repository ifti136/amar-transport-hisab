import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/vehicles/vehicle_provider.dart';
import 'package:transport_hisab/features/vehicles/vehicle_form.dart';
import 'package:transport_hisab/features/vehicles/vehicle_loans_screen.dart';
import 'package:transport_hisab/features/reports/vehicle_pnl_report.dart';

class VehicleDetail extends ConsumerWidget {
  final Vehicle vehicle;

  const VehicleDetail({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final expiryAsync = ref.watch(vehicleExpiryProvider(vehicle.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vanCardTitle(vehicle.regNo)),
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
          // Vehicle Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.vehicleLabel, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _DetailRow(label: l10n.vehicleLabel, value: vehicle.regNo),
                  _DetailRow(label: l10n.vehicleTypeLabel, value: vehicle.type),
                  _DetailRow(label: l10n.statusLabel, value: vehicle.status),
                  _DetailRow(
                    label: 'Created',
                    value: formatDate(vehicle.createdAt, context: context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Expiry Dates Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.expiryDatesTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  expiryAsync.when(
                    data: (expiry) {
                      return Column(
                        children: [
                          _ExpiryRow(
                            label: l10n.category_insurance,
                            days: expiry['insurance'],
                            icon: Icons.security,
                          ),
                          _ExpiryRow(
                            label: l10n.category_fitness,
                            days: expiry['fitness'],
                            icon: Icons.directions_car,
                          ),
                          _ExpiryRow(
                            label: l10n.category_tax_token,
                            days: expiry['tax'],
                            icon: Icons.receipt,
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => Text(l10n.errorLoadingExpiry),
                  ),
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
                  leading: const Icon(Icons.account_balance_wallet),
                  title: Text(l10n.loanOutstanding),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VehicleLoansScreen(vehicle: vehicle),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.assignment),
                  title: Text(l10n.reportVehiclePL),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VehiclePnLReport(),
                      ),
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
      builder: (context) => VehicleForm(vehicle: vehicle),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDeleteVehicle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final dao = ref.read(vehicleDaoProvider);
              await dao.softDeleteWithAudit(vehicle.id, userNote: 'Vehicle deleted');
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close detail screen
                ref.invalidate(activeVehiclesProvider);
                ref.invalidate(allVehiclesProvider);
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

class _ExpiryRow extends StatelessWidget {
  final String label;
  final int? days;
  final IconData icon;

  const _ExpiryRow({required this.label, required this.days, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    Color color;
    String text;
    if (days == null) {
      color = theme.colorScheme.onSurfaceVariant;
      text = 'Not set';
    } else if (days! <= 0) {
      color = semantic.danger;
      text = '${AppLocalizations.of(context)!.expiryExpired} (${days!.abs()} days ago)';
    } else if (days! <= 7) {
      color = semantic.danger;
      text = AppLocalizations.of(context)!.expiryDaysLeft(days!);
    } else if (days! <= 30) {
      color = semantic.warning;
      text = AppLocalizations.of(context)!.expiryDaysLeft(days!);
    } else {
      color = semantic.success;
      text = AppLocalizations.of(context)!.expiryDaysLeft(days!);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                Text(text, style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color),
            ),
            child: Text(
              days == null ? '—' : '${days!}d',
              style: theme.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}