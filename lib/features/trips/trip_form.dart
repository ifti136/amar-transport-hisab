import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/trips/trip_provider.dart';
import 'package:transport_hisab/features/vehicles/vehicle_provider.dart';
import 'package:transport_hisab/features/drivers/driver_provider.dart';
import 'package:transport_hisab/features/customers/customer_provider.dart';

class TripForm extends ConsumerStatefulWidget {
  final Trip? trip;

  const TripForm({super.key, this.trip});

  @override
  ConsumerState<TripForm> createState() => _TripFormState();
}

class _TripFormState extends ConsumerState<TripForm> {
  final _formKey = GlobalKey<FormState>();
  final _fareController = TextEditingController();
  final _advanceController = TextEditingController();
  final _startOdoController = TextEditingController();
  final _endOdoController = TextEditingController();

  int? _customerId;
  int? _vehicleId;
  int? _driverId;
  DateTime _tripDate = DateTime.now();
  String _status = 'completed';

  @override
  void initState() {
    super.initState();
    if (widget.trip != null) {
      _customerId = widget.trip!.customerId;
      _vehicleId = widget.trip!.vehicleId;
      _driverId = widget.trip!.driverId;
      _tripDate = widget.trip!.tripDate;
      _fareController.text = (widget.trip!.agreedFarePaisa / 100).toStringAsFixed(2);
      _advanceController.text = (widget.trip!.advancePaisa / 100).toStringAsFixed(2);
      _startOdoController.text = widget.trip!.startOdo.toString();
      _endOdoController.text = widget.trip!.endOdo?.toString() ?? '';
      _status = widget.trip!.status;
    }
  }

  @override
  void dispose() {
    _fareController.dispose();
    _advanceController.dispose();
    _startOdoController.dispose();
    _endOdoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.trip != null;
    final vehiclesAsync = ref.watch(activeVehiclesProvider);
    final driversAsync = ref.watch(activeDriversProvider);
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
            Text(
              isEditing ? l10n.edit : l10n.addTripTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Customer Picker
            _PickerField<Customer>(
              label: l10n.customerLabel,
              value: _customerId,
              asyncValue: customersAsync,
              getLabel: (c) => c.name,
              onChanged: (id) => setState(() => _customerId = id),
              validator: (id) => id == null ? l10n.errorRequired : null,
            ),
            const SizedBox(height: 16),

            // Vehicle Picker
            _PickerField<Vehicle>(
              label: l10n.vehicleLabel,
              value: _vehicleId,
              asyncValue: vehiclesAsync,
              getLabel: (v) => '${v.regNo} (${v.type})',
              onChanged: (id) => setState(() => _vehicleId = id),
              validator: (id) => id == null ? l10n.errorRequired : null,
            ),
            const SizedBox(height: 16),

            // Driver Picker
            _PickerField<Driver>(
              label: l10n.driverLabel,
              value: _driverId,
              asyncValue: driversAsync,
              getLabel: (d) => '${d.name} (৳${(d.monthlySalaryPaisa / 100).toStringAsFixed(0)}/mo)',
              onChanged: (id) => setState(() => _driverId = id),
              validator: (id) => id == null ? l10n.errorRequired : null,
            ),
            const SizedBox(height: 16),

            // Date Picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _tripDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _tripDate = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.dateLabel,
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(formatDate(_tripDate, context: context)),
              ),
            ),
            const SizedBox(height: 16),

            // Fare
            TextFormField(
              controller: _fareController,
              decoration: InputDecoration(
                labelText: l10n.fareLabel,
                hintText: l10n.fareHint,
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

            // Advance
            TextFormField(
              controller: _advanceController,
              decoration: InputDecoration(
                labelText: l10n.advanceLabel,
                hintText: l10n.advanceHint,
                prefixText: '৳ ',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null; // Optional
                final parsed = double.tryParse(value);
                if (parsed == null || parsed < 0) return l10n.errorPositiveAmount;
                final fare = double.tryParse(_fareController.text) ?? 0;
                if (parsed > fare) return l10n.errorAdvanceExceedsFare;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Start Odometer
            TextFormField(
              controller: _startOdoController,
              decoration: InputDecoration(
                labelText: l10n.startOdoLabel,
                hintText: l10n.startOdoHint,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                final parsed = int.tryParse(value);
                if (parsed == null || parsed < 0) return l10n.errorInvalidNumber;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // End Odometer
            TextFormField(
              controller: _endOdoController,
              decoration: InputDecoration(
                labelText: l10n.endOdoLabel,
                hintText: l10n.endOdoHint,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null; // Optional
                final parsed = int.tryParse(value);
                if (parsed == null || parsed < 0) return l10n.errorInvalidNumber;
                final start = int.tryParse(_startOdoController.text) ?? 0;
                if (parsed < start) return l10n.errorOdometerDecreased;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Status
            DropdownButtonFormField<String>(
              value: _status,
              decoration: InputDecoration(labelText: l10n.statusLabel),
              items: [
                DropdownMenuItem(value: 'completed', child: Text(l10n.statusActive)),
                DropdownMenuItem(value: 'cancelled', child: Text(l10n.statusCancelled)),
              ],
              onChanged: (value) => setState(() => _status = value!),
            ),
            const SizedBox(height: 16),

            // Outstanding (read-only)
            if (_customerId != null && _fareController.text.isNotEmpty && _advanceController.text.isNotEmpty)
              _OutstandingPreview(
                fare: double.tryParse(_fareController.text) ?? 0,
                advance: double.tryParse(_advanceController.text) ?? 0,
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
                    child: Text(isEditing ? l10n.save : l10n.add),
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
    if (!_formKey.currentState!.validate()) return;

    final farePaisa = (_fareController.text.isEmpty) ? 0 : (double.parse(_fareController.text) * 100).round();
    final advancePaisa = (_advanceController.text.isEmpty) ? 0 : (double.parse(_advanceController.text) * 100).round();
    final startOdo = int.parse(_startOdoController.text);
    final endOdo = _endOdoController.text.isEmpty ? null : int.parse(_endOdoController.text);

    final dao = ref.read(tripDaoProvider);
    final companion = TripsCompanion(
      customerId: Value(_customerId!),
      vehicleId: Value(_vehicleId!),
      driverId: Value(_driverId!),
      tripDate: Value(_tripDate),
      agreedFarePaisa: Value(farePaisa),
      advancePaisa: Value(advancePaisa),
      startOdo: Value(startOdo),
      endOdo: Value(endOdo),
      status: Value(_status),
      updatedAt: Value(DateTime.now()),
    );

    if (widget.trip != null) {
      await dao.updateWithAudit(companion, id: widget.trip!.id, userNote: 'Trip updated');
    } else {
      await dao.insertWithAudit(companion, userNote: 'Trip added');
    }

    if (mounted) {
      Navigator.pop(context);
      ref.invalidate(tripsProvider(const TripFilter()));
    }
  }
}

class _PickerField<T> extends StatelessWidget {
  final String label;
  final int? value;
  final AsyncValue<List<T>> asyncValue;
  final String Function(T) getLabel;
  final ValueChanged<int?> onChanged;
  final String? Function(int?)? validator;

  const _PickerField({
    required this.label,
    required this.value,
    required this.asyncValue,
    required this.getLabel,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return asyncValue.when(
      data: (items) {
        if (items.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              Text(l10n.noItemsAvailable(label), style: Theme.of(context).textTheme.bodyMedium),
            ],
          );
        }

        return DropdownButtonFormField<int>(
          value: value,
          decoration: InputDecoration(labelText: label),
          items: items.map((item) => DropdownMenuItem(
            value: (item as dynamic).id as int,
            child: Text(getLabel(item)),
          )).toList(),
          onChanged: onChanged,
          validator: validator,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Text(l10n.errorLoadingItems(label)),
    );
  }
}

class _OutstandingPreview extends StatelessWidget {
  final double fare;
  final double advance;

  const _OutstandingPreview({required this.fare, required this.advance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final outstanding = fare - advance;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.outstandingLabel, style: theme.textTheme.titleMedium),
          Text(
            formatMoney(Money.paisa((outstanding * 100).round()), context: context),
            style: theme.textTheme.titleLarge?.copyWith(
              color: outstanding >= 0 ? theme.extension<AppSemanticColors>()!.danger : theme.extension<AppSemanticColors>()!.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}