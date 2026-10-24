import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/core/db/daos/trip_dao.dart';
import 'package:transport_hisab/features/trips/trip_provider.dart';
import 'package:transport_hisab/features/trips/trip_form.dart';
import 'package:transport_hisab/features/trips/receive_payment.dart';
import 'package:collection/collection.dart';
import 'package:transport_hisab/features/customers/customer_provider.dart';
import 'package:transport_hisab/features/vehicles/vehicle_provider.dart';
import 'package:transport_hisab/features/drivers/driver_provider.dart';
import 'package:transport_hisab/features/money/money_provider.dart';
import 'package:transport_hisab/features/money/expense_form.dart';

class TripDetailScreen extends ConsumerWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tripWithOutstandingAsync = ref.watch(tripWithOutstandingProvider(trip.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tripDetailTitle(trip.id)),
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
      body: tripWithOutstandingAsync.when(
        data: (tripData) {
          if (tripData == null) return _notFound(context, l10n);
          return _TripDetailContent(trip: tripData.trip, tripData: tripData);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.errorLoadingTrip(error.toString()))),
      ),
    );
  }

  Widget _notFound(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(l10n.errorInvalidNumber, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showEditForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TripForm(trip: trip),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDeleteTrip),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final dao = ref.read(tripDaoProvider);
              await dao.softDeleteWithAudit(trip.id, userNote: 'Trip deleted');
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ref.invalidate(tripsProvider(const TripFilter()));
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

class _TripDetailContent extends ConsumerWidget {
  final Trip trip;
  final TripWithOutstanding tripData;

  const _TripDetailContent({required this.trip, required this.tripData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    final customers = ref.watch(activeCustomersProvider).asData?.value;
    final vehicles = ref.watch(activeVehiclesProvider).asData?.value;
    final drivers = ref.watch(activeDriversProvider).asData?.value;

    final customer = customers?.firstWhereOrNull((c) => c.id == trip.customerId);
    final vehicle = vehicles?.firstWhereOrNull((v) => v.id == trip.vehicleId);
    final driver = drivers?.firstWhereOrNull((d) => d.id == trip.driverId);

    final customerDisplay = customer?.name ?? (trip.customCustomerName != null && trip.customCustomerName!.isNotEmpty ? trip.customCustomerName! : (trip.customerId != null ? 'Customer #${trip.customerId}' : l10n.noCustomer));
    final vehicleDisplay = vehicle != null ? '${vehicle.regNo} (${vehicle.type})' : 'Vehicle #${trip.vehicleId}';
    final driverDisplay = driver?.name ?? 'Driver #${trip.driverId}';

    String statusDisplay;
    switch (trip.status) {
      case 'completed':
        statusDisplay = l10n.statusCompleted;
        break;
      case 'pending':
        statusDisplay = l10n.statusPending;
        break;
      case 'cancelled':
        statusDisplay = l10n.statusCancelled;
        break;
      default:
        statusDisplay = trip.status;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Trip Info Card
        Card(
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
                          Text(l10n.tripDetailHeader(trip.id), style: theme.textTheme.headlineSmall),
                          Text(
                            formatDate(trip.tripDate, context: context),
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    _TripStatusBadge(status: trip.status),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailRow(label: l10n.customerLabel, value: customerDisplay),
                _DetailRow(label: l10n.vehicleLabel, value: vehicleDisplay),
                _DetailRow(label: l10n.driverLabel, value: driverDisplay),
                _DetailRow(label: l10n.fareLabel, value: formatMoney(Money.paisa(trip.agreedFarePaisa), context: context)),
                _DetailRow(label: l10n.advanceLabel, value: formatMoney(Money.paisa(trip.advancePaisa), context: context)),
                if (trip.endOdo != null && trip.endOdo! > trip.startOdo)
                  _DetailRow(label: l10n.distanceKmLabel, value: '${trip.endOdo! - trip.startOdo} km'), // i18n-ignore
                _DetailRow(label: l10n.outstandingLabel, value: formatMoney(Money.paisa(tripData.outstanding), context: context)),
                _DetailRow(label: l10n.statusLabel, value: statusDisplay),

                if (trip.status != 'cancelled') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: trip.status == 'pending'
                        ? FilledButton.icon(
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(l10n.markCompletedAction),
                            onPressed: () => _toggleStatus(context, ref, 'completed'),
                          )
                        : OutlinedButton.icon(
                            icon: const Icon(Icons.pending_actions),
                            label: Text(l10n.markPendingAction),
                            onPressed: () => _toggleStatus(context, ref, 'pending'),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

          // Financial Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.reportTripRegister, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryItem(
                          label: l10n.fareLabel,
                          value: formatMoney(Money.paisa(trip.agreedFarePaisa), context: context),
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Expanded(
                        child: _SummaryItem(
                          label: l10n.advanceLabel,
                          value: formatMoney(Money.paisa(trip.advancePaisa), context: context),
                          color: theme.extension<AppSemanticColors>()!.success,
                        ),
                      ),
                      Expanded(
                        child: _SummaryItem(
                          label: l10n.outstandingLabel,
                          value: formatMoney(Money.paisa(tripData.outstanding), context: context),
                          color: theme.extension<AppSemanticColors>()!.danger,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Payments
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(l10n.reportCustomerLedger),
                  subtitle: Text(tripData.totalPaid > 0 ? l10n.paidAmount(formatMoney(Money.paisa(tripData.totalPaid), context: context)) : l10n.noPaymentsYet),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPaymentHistory(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: Text(l10n.add),
                  subtitle: Text(l10n.receivePaymentAction),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showReceivePayment(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Expenses
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text(l10n.reportExpenseRegister),
                  subtitle: Text(l10n.viewTripExpensesAction),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showTripExpenses(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: Text(l10n.add),
                  subtitle: Text(l10n.tripExpenseOption),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAddTripExpense(context),
                ),
              ],
            ),
          ),
        ],
      );
  }

  void _showPaymentHistory(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dao = ref.read(customerPaymentDaoProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.reportCustomerLedger,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<CustomerPayment>>(
                future: dao.getPaymentsForTrip(trip.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(l10n.noPaymentsYet),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, idx) {
                      final item = list[idx];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.payment)),
                        title: Text(formatMoney(Money.paisa(item.amountPaisa), context: context)),
                        subtitle: Text(
                          '${formatDate(item.paymentDate, context: context)}${item.note != null && item.note!.isNotEmpty ? ' • ${item.note}' : ''}',
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTripExpenses(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dao = ref.read(expenseDaoProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.reportExpenseRegister,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Expense>>(
                future: dao.getExpensesForTrip(trip.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No expenses recorded for this trip'), // i18n-ignore
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, idx) {
                      final item = list[idx];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                        title: Text('${item.category}: ${formatMoney(Money.paisa(item.amountPaisa), context: context)}'), // i18n-ignore
                        subtitle: Text(formatDate(item.expenseDate, context: context)),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReceivePayment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReceivePaymentSheet(trip: trip),
    );
  }

  void _showAddTripExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExpenseForm(
        initialMode: ExpenseEntryMode.trip,
        preselectedTripId: trip.id,
      ),
    );
  }

  Future<void> _toggleStatus(BuildContext context, WidgetRef ref, String newStatus) async {
    final dao = ref.read(tripDaoProvider);
    await dao.updateWithAudit(
      TripsCompanion(
        status: Value(newStatus),
        updatedAt: Value(DateTime.now()),
      ),
      id: trip.id,
      userNote: 'Trip marked as $newStatus',
    );
    ref.invalidate(tripWithOutstandingProvider(trip.id));
    ref.invalidate(tripsProvider(const TripFilter()));
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

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}