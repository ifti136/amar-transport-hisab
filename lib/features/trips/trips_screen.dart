import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/db/daos/trip_dao.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/trips/trip_provider.dart';
import 'package:transport_hisab/features/trips/trip_form.dart';
import 'package:transport_hisab/features/trips/trip_detail.dart';
import 'package:transport_hisab/features/customers/customer_provider.dart';
import 'package:transport_hisab/features/vehicles/vehicle_provider.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  TripFilter _filter = const TripFilter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tripsAsync = ref.watch(tripsProvider(_filter));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tripsTab),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: l10n.filter,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTripForm(context),
            tooltip: l10n.add,
          ),
        ],
      ),
      body: tripsAsync.when(
        data: (trips) {
          if (trips.isEmpty) {
            return _emptyState(context, l10n);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return _TripCard(trip: trip);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _errorState(context, l10n, error.toString()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTripForm(context),
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
            Icon(Icons.local_shipping_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No trips yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first trip to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showTripForm(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context, AppLocalizations l10n, String error) {
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
              onPressed: () => ref.invalidate(tripsProvider(_filter)),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showTripForm(BuildContext context, {Trip? trip}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TripForm(trip: trip),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(filter: _filter, onChanged: (newFilter) {
        setState(() => _filter = newFilter);
      }),
    );
  }
}

class _TripCard extends ConsumerWidget {
  final Trip trip;

  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final vehicles = ref.watch(activeVehiclesProvider).asData?.value;
    final customers = ref.watch(activeCustomersProvider).asData?.value;
    final vehicle = vehicles?.firstWhereOrNull((v) => v.id == trip.vehicleId);
    final customer = customers?.firstWhereOrNull((c) => c.id == trip.customerId);
    final customerDisplay = customer?.name ?? (trip.customCustomerName != null && trip.customCustomerName!.isNotEmpty ? trip.customCustomerName! : (trip.customerId != null ? 'Customer #${trip.customerId}' : l10n.noCustomer));
    final vehicleDisplay = vehicle?.regNo ?? 'Vehicle #${trip.vehicleId}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
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
                    child: Icon(Icons.local_shipping, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trip #${trip.id}',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          formatDate(trip.tripDate, context: context),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _TripStatusBadge(status: trip.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.person,
                      label: l10n.customerLabel,
                      value: customerDisplay,
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.directions_bus,
                      label: l10n.vehicleLabel,
                      value: vehicleDisplay,
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.attach_money,
                      label: l10n.fareLabel,
                      value: formatMoney(Money.paisa(trip.agreedFarePaisa), context: context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.money,
                      label: l10n.advanceLabel,
                      value: formatMoney(Money.paisa(trip.advancePaisa), context: context),
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.straighten,
                      label: l10n.distanceKmLabel,
                      value: (trip.endOdo != null && trip.endOdo! > trip.startOdo)
                          ? '${trip.endOdo! - trip.startOdo} km'
                          : (trip.endOdo != null && trip.endOdo! > 0 ? '${trip.endOdo} km' : '-'),
                    ),
                  ),
                  Expanded(
                    child: _OutstandingBadge(tripId: trip.id),
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

class _TripStatusBadge extends StatelessWidget {
  final String status;

  const _TripStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    Color color;
    String label;
    switch (status) {
      case 'completed':
        color = semantic.success;
        label = l10n.statusCompleted;
        break;
      case 'pending':
        color = semantic.warning;
        label = l10n.statusPending;
        break;
      case 'cancelled':
        color = semantic.danger;
        label = l10n.statusCancelled;
        break;
      default:
        color = theme.colorScheme.onSurfaceVariant;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w500),
      ),
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

class _OutstandingBadge extends ConsumerWidget {
  final int tripId;

  const _OutstandingBadge({required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    return FutureBuilder<TripWithOutstanding?>(
      future: ref.read(tripDaoProvider).getTripWithOutstanding(tripId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();
        final outstanding = snapshot.data!.outstanding;
        if (outstanding <= 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: semantic.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: semantic.danger),
          ),
          child: Text(
            '${l10n.outstandingLabel}: ${formatMoney(Money.paisa(outstanding), context: context)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: semantic.danger,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
}

class _FilterDialog extends ConsumerStatefulWidget {
  final TripFilter filter;
  final ValueChanged<TripFilter> onChanged;

  const _FilterDialog({required this.filter, required this.onChanged});

  @override
  ConsumerState<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends ConsumerState<_FilterDialog> {
  late TripFilter _filter;
  DateTime? _from;
  DateTime? _to;
  int? _vehicleId;
  int? _customerId;
  int? _driverId;
  String? _status;

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
    _from = _filter.from;
    _to = _filter.to;
    _vehicleId = _filter.vehicleId;
    _customerId = _filter.customerId;
    _driverId = _filter.driverId;
    _status = _filter.status;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.filter),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date Range
            ListTile(
              title: Text(l10n.dateRangeLabel),
              subtitle: Text(_from != null && _to != null
                  ? '${formatDate(_from!, context: context)} - ${formatDate(_to!, context: context)}'
                  : l10n.thisMonth),
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
            // Vehicle Filter
            ListTile(
              title: Text(l10n.vehicleFilterLabel),
              subtitle: Builder(
                builder: (context) {
                  if (_vehicleId == null) return Text(l10n.allVehicles);
                  final vehicles = ref.read(activeVehiclesProvider).asData?.value ?? [];
                  final v = vehicles.firstWhereOrNull((v) => v.id == _vehicleId);
                  return Text(v?.regNo ?? 'Vehicle #$_vehicleId');
                },
              ),
              trailing: const Icon(Icons.directions_bus),
              onTap: () {
                final vehicles = ref.read(activeVehiclesProvider).asData?.value ?? [];
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        ListTile(
                          title: Text(l10n.allVehicles),
                          selected: _vehicleId == null,
                          onTap: () {
                            setState(() => _vehicleId = null);
                            Navigator.pop(ctx);
                          },
                        ),
                        ...vehicles.map((v) => ListTile(
                          title: Text(v.regNo),
                          subtitle: Text(v.type),
                          selected: _vehicleId == v.id,
                          onTap: () {
                            setState(() => _vehicleId = v.id);
                            Navigator.pop(ctx);
                          },
                        )),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Status Filter
            ListTile(
              title: Text(l10n.statusFilterTitle),
              subtitle: Text(_status == null ? l10n.statusAll : _status == 'completed' ? l10n.statusCompleted : l10n.statusCancelled),
              trailing: const Icon(Icons.filter_alt),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(title: Text(l10n.statusAll), onTap: () { setState(() => _status = null); Navigator.pop(context); }),
                      ListTile(title: Text(l10n.statusCompleted), onTap: () { setState(() => _status = 'completed'); Navigator.pop(context); }),
                      ListTile(title: Text(l10n.statusCancelled), onTap: () { setState(() => _status = 'cancelled'); Navigator.pop(context); }),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _from = null;
              _to = null;
              _vehicleId = null;
              _customerId = null;
              _driverId = null;
              _status = null;
            });
          },
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            widget.onChanged(TripFilter(
              from: _from,
              to: _to,
              vehicleId: _vehicleId,
              customerId: _customerId,
              driverId: _driverId,
              status: _status,
            ));
            Navigator.pop(context);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}