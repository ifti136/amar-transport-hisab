import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/db/daos/trip_dao.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/features/trips/trip_provider.dart';
import 'package:transport_hisab/features/customers/customer_provider.dart';

class ReceivePaymentSheet extends ConsumerStatefulWidget {
  final Customer? customer;
  final Trip? trip;

  const ReceivePaymentSheet({super.key, this.customer, this.trip});

  @override
  ConsumerState<ReceivePaymentSheet> createState() => _ReceivePaymentSheetState();
}

class _ReceivePaymentSheetState extends ConsumerState<ReceivePaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  int? _selectedCustomerId;
  int? _selectedTripId;
  List<TripWithOutstanding> _availableTrips = [];
  bool _loadingTrips = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _selectedCustomerId = widget.customer!.id;
      _loadTripsForCustomer(widget.customer!.id);
    } else if (widget.trip != null) {
      _selectedTripId = widget.trip!.id;
      _selectedCustomerId = widget.trip!.customerId;
    }
  }

  Future<void> _loadTripsForCustomer(int customerId) async {
    setState(() => _loadingTrips = true);
    final trips = await ref.read(tripDaoProvider).getTripsWithOutstandingForCustomer(customerId);
    if (mounted) {
      setState(() {
        _availableTrips = trips;
        _loadingTrips = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customersAsync = ref.watch(activeCustomersProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.add, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            // Customer Picker (if not pre-selected)
            if (widget.customer == null && widget.trip == null) ...[
              customersAsync.when(
                data: (customers) => DropdownButtonFormField<int>(
                  value: _selectedCustomerId,
                  decoration: InputDecoration(labelText: l10n.customerLabel),
                  items: customers.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  )).toList(),
                  onChanged: (id) {
                    setState(() {
                      _selectedCustomerId = id;
                      _selectedTripId = null;
                      _availableTrips = [];
                    });
                    if (id != null) _loadTripsForCustomer(id);
                  },
                  validator: (id) => id == null ? l10n.errorRequired : null,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error loading customers: $e'),
              ),
              const SizedBox(height: 16),
            ]
            else if (widget.customer != null)
              _ReadOnlyField(label: l10n.customerLabel, value: widget.customer!.name),

            // Trip Picker (if customer selected)
            if (_selectedCustomerId != null && widget.trip == null) ...[
              const SizedBox(height: 16),
              _loadingTrips
                  ? const Center(child: CircularProgressIndicator())
                  : _availableTrips.isEmpty
                      ? Text(l10n.noOutstandingTrips, style: Theme.of(context).textTheme.bodyMedium)
                      : DropdownButtonFormField<int>(
                          value: _selectedTripId,
                          decoration: InputDecoration(labelText: l10n.tripLabel),
                          items: _availableTrips.map((t) => DropdownMenuItem(
                            value: t.trip.id,
                            child: Text(l10n.tripOutstandingLabel(t.trip.id, formatMoney(Money.paisa(t.outstanding), context: context))),
                          )).toList(),
                          onChanged: (id) => setState(() => _selectedTripId = id),
                          validator: (id) => id == null ? l10n.errorRequired : null,
                        ),
              const SizedBox(height: 16),
            ],

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: l10n.amountLabel,
                hintText: l10n.paymentAmountHint,
                prefixText: '৳ ',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) return l10n.errorPositiveAmount;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Note
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l10n.noteLabel,
                hintText: l10n.noteLabel,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Outstanding Preview
            if (_selectedTripId != null)
              _OutstandingPreview(
                trip: _availableTrips.firstWhere((t) => t.trip.id == _selectedTripId),
              ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTripId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.selectTripError)));
      return;
    }

    final amountPaisa = (double.parse(_amountController.text) * 100).round();
    final selectedTrip = _availableTrips.firstWhere((t) => t.trip.id == _selectedTripId);

    if (amountPaisa > selectedTrip.outstanding) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.paymentExceedsWarning),
          content: Text(l10n.paymentExceedsMessage),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancelButton)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.continueButton)),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final dao = ref.read(customerPaymentDaoProvider);
    await dao.insertWithAudit(CustomerPaymentsCompanion.insert(
      tripId: _selectedTripId!,
      customerId: _selectedCustomerId!,
      amountPaisa: amountPaisa,
      paymentDate: DateTime.now(),
      note: Value(_noteController.text.trim().isEmpty ? null : _noteController.text.trim()),
    ), userNote: 'Payment received');

    if (mounted) {
      Navigator.pop(context);
      ref.invalidate(tripsProvider(const TripFilter()));
      ref.invalidate(activeCustomersProvider);
    }
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Text(value, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}

class _OutstandingPreview extends StatelessWidget {
  final TripWithOutstanding trip;

  const _OutstandingPreview({required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.outstandingLabel, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.tripOutstandingPreview(trip.trip.id), style: theme.textTheme.bodyMedium),
              Text(
                formatMoney(Money.paisa(trip.outstanding), context: context),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: semantic.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}