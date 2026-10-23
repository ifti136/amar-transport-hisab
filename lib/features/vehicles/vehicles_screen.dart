import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/features/vehicles/vehicle_provider.dart';
import 'package:transport_hisab/features/vehicles/vehicle_form.dart';
import 'package:transport_hisab/features/vehicles/vehicle_detail.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final vehiclesAsync = ref.watch(activeVehiclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vehicleLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showVehicleForm(context),
            tooltip: l10n.add,
          ),
        ],
      ),
      body: vehiclesAsync.when(
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return _emptyState(context, l10n);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return _VehicleCard(vehicle: vehicle);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _errorState(context, ref, l10n, error.toString()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVehicleForm(context),
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
            Icon(Icons.directions_bus_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              l10n.scaffoldHome, // Reuse "No vehicles yet" concept
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first vehicle to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showVehicleForm(context),
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
              onPressed: () => ref.invalidate(activeVehiclesProvider),
              child: Text(l10n.save), // Reuse "Retry"
            ),
          ],
        ),
      ),
    );
  }

  void _showVehicleForm(BuildContext context, {Vehicle? vehicle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => VehicleForm(vehicle: vehicle),
    );
  }
}

class _VehicleCard extends ConsumerWidget {
  final Vehicle vehicle;

  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final expiryAsync = ref.watch(vehicleExpiryProvider(vehicle.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VehicleDetail(vehicle: vehicle)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
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
                          vehicle.regNo,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          vehicle.type,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ExpiryBadges(vehicleId: vehicle.id),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.route,
                      label: l10n.vanTrips(0), // TODO: Get actual trip count
                      value: '0',
                    ),
                  ),
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.trending_up,
                      label: l10n.profit,
                      value: '৳0', // TODO: Get actual profit
                    ),
                  ),
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.account_balance_wallet,
                      label: l10n.cashBalance,
                      value: '৳0', // TODO: Get actual cash
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

class _ExpiryBadges extends ConsumerWidget {
  final int vehicleId;

  const _ExpiryBadges({required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expiryAsync = ref.watch(vehicleExpiryProvider(vehicleId));
    final theme = Theme.of(context);

    return expiryAsync.when(
      data: (expiry) {
        final badges = <Widget>[];
        expiry.forEach((type, days) {
          if (days == null) return;
          Color color;
          String label;
          if (days <= 0) {
            color = theme.extension<AppSemanticColors>()!.danger;
            label = '${type.toUpperCase()}: ${AppLocalizations.of(context)!.expiryExpired}';
          } else if (days <= 7) {
            color = theme.extension<AppSemanticColors>()!.warning;
            label = '${type.toUpperCase()}: ${AppLocalizations.of(context)!.expiryDaysLeft(days)}';
          } else if (days <= 30) {
            color = theme.extension<AppSemanticColors>()!.warning;
            label = '${type.toUpperCase()}: ${AppLocalizations.of(context)!.expiryDaysLeft(days)}';
          } else {
            color = theme.extension<AppSemanticColors>()!.success;
            label = '${type.toUpperCase()}: ${AppLocalizations.of(context)!.expiryDaysLeft(days)}';
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}