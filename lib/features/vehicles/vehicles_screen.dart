import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/formatters.dart';
import 'package:transport_hisab/core/db/database.dart';
import '../../core/widgets/add_action.dart';
import '../../core/widgets/empty_state_view.dart';
import 'vehicle_provider.dart';
import 'vehicle_form.dart';
import 'vehicle_detail.dart';
import '../dashboard/dashboard_provider.dart';
import 'widgets/vehicle_summary_card.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final vehiclesAsync = ref.watch(activeVehiclesProvider);
    final dashboard = ref.watch(dashboardProvider).asData?.value;
    final vehicleSummaries = {
      for (final summary in dashboard?.vanSummaries ?? const <VanSummaryData>[])
        summary.vehicleId: summary,
    };
    final hasVehicles =
        vehiclesAsync.asData?.value.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleLabel)),
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
              final summary = vehicleSummaries[vehicle.id];
              return VehicleSummaryCard(
                regNo: vehicle.regNo,
                type: vehicle.type,
                icon: Icons.directions_bus,
                expiry: ref.watch(vehicleExpiryProvider(vehicle.id)).asData?.value ?? const {},
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VehicleDetail(vehicle: vehicle)),
                ),
                metrics: [
                  VehicleSummaryMetric(
                    label: l10n.tripsThisMonthLabel,
                    value: '${summary?.tripCount ?? 0}',
                  ),
                  VehicleSummaryMetric(
                    label: l10n.profitThisMonthLabel,
                    value: formatMoney(
                      Money.paisa(summary?.profitPaisa ?? 0),
                      context: context,
                    ),
                  ),
                  VehicleSummaryMetric(
                    label: l10n.netCashAllTimeLabel,
                    value: formatMoney(
                      Money.paisa(summary?.cashBalancePaisa ?? 0),
                      context: context,
                    ),
                  ),
                  VehicleSummaryMetric(
                    label: l10n.tripOutstandingAllTimeLabel,
                    value: formatMoney(
                      Money.paisa(summary?.outstandingPaisa ?? 0),
                      context: context,
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _errorState(context, ref, l10n, error.toString()),
      ),
      floatingActionButton: hasVehicles
          ? AddIconFab(
              onPressed: () => _showVehicleForm(context),
              tooltip: l10n.addVehicleTitle,
            )
          : null,
    );
  }

  Widget _emptyState(BuildContext context, AppLocalizations l10n) {
    return EmptyStateView(
      icon: Icons.directions_bus_outlined,
      title: l10n.emptyVehiclesTitle,
      message: l10n.emptyVehiclesMessage,
      action: AddActionButton(
        onPressed: () => _showVehicleForm(context),
        label: l10n.addVehicleTitle,
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
