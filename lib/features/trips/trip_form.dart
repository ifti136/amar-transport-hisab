import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/core/widgets/app_toast.dart';
import 'package:transport_hisab/features/dashboard/dashboard_provider.dart';
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
  final _distanceController = TextEditingController();
  final _customCustomerController = TextEditingController();

  bool _useCustomCustomer = false;
  int? _customerId;
  int? _vehicleId;
  int? _driverId;
  DateTime _tripDate = DateTime.now();
  String _status = 'pending';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.trip != null) {
      _customerId = widget.trip!.customerId;
      if (widget.trip!.customCustomerName != null && widget.trip!.customCustomerName!.isNotEmpty) {
        _useCustomCustomer = true;
        _customCustomerController.text = widget.trip!.customCustomerName!;
      }
      _vehicleId = widget.trip!.vehicleId;
      _driverId = widget.trip!.driverId;
      _tripDate = widget.trip!.tripDate;
      _fareController.text = (widget.trip!.agreedFarePaisa / 100).toStringAsFixed(2);
      _advanceController.text = (widget.trip!.advancePaisa / 100).toStringAsFixed(2);
      final dist = widget.trip!.endOdo != null ? (widget.trip!.endOdo! - widget.trip!.startOdo) : null;
      if (dist != null && dist > 0) {
        _distanceController.text = dist.toString();
      }
      _status = widget.trip!.status;
    } else {
      _status = 'pending';
    }
  }

  @override
  void dispose() {
    _fareController.dispose();
    _advanceController.dispose();
    _distanceController.dispose();
    _customCustomerController.dispose();
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? l10n.edit : l10n.addTripTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              // Customer Mode Selection (Existing vs Custom)
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: false,
                    icon: const Icon(Icons.people_outline),
                    label: Text(l10n.customerLabel),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: const Icon(Icons.edit_note),
                    label: Text(l10n.customCustomerNameLabel),
                  ),
                ],
                selected: {_useCustomCustomer},
                onSelectionChanged: (set) {
                  setState(() {
                    _useCustomCustomer = set.first;
                    if (_useCustomCustomer) {
                      _customerId = null;
                    } else {
                      _customCustomerController.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 12),

              if (!_useCustomCustomer) ...[
                // Registered Customer Picker (Optional)
                customersAsync.when(
                  data: (customers) {
                    return DropdownButtonFormField<int?>(
                      value: _customerId,
                      decoration: InputDecoration(
                        labelText: l10n.selectCustomerOrCustom,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            l10n.noCustomer,
                            style: TextStyle(color: Theme.of(context).colorScheme.outline),
                          ),
                        ),
                        ...customers.map((c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.name),
                        )),
                      ],
                      onChanged: (id) => setState(() => _customerId = id),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Text(l10n.errorLoadingItems(l10n.customerLabel)),
                ),
              ] else ...[
                // Custom Customer Name Input
                TextFormField(
                  controller: _customCustomerController,
                  decoration: InputDecoration(
                    labelText: l10n.customCustomerNameLabel,
                    hintText: l10n.selectCustomerOrCustom,
                    prefixIcon: const Icon(Icons.person_add_outlined),
                  ),
                ),
              ],
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
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                  final res = parseMoneyInput(value);
                  if (res is Failure) return res.error;
                  if (res is Success && res.value.paisa <= 0) return l10n.errorPositiveAmount;
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null; // Optional
                  final res = parseMoneyInput(value);
                  if (res is Failure) return res.error;
                  final fareRes = parseMoneyInput(_fareController.text);
                  if (fareRes is Success && res is Success && res.value.paisa > fareRes.value.paisa) {
                    return l10n.errorAdvanceExceedsFare;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Distance (optional)
              TextFormField(
                controller: _distanceController,
                decoration: InputDecoration(
                  labelText: l10n.distanceKmLabel,
                  hintText: l10n.distanceKmHint,
                  suffixText: 'km', // i18n-ignore
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null; // Optional
                  final parsed = int.tryParse(toEnDigits(value.trim()));
                  if (parsed == null || parsed < 0) return l10n.errorInvalidNumber;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Status (pending, completed, cancelled)
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(labelText: l10n.statusLabel),
                items: [
                  DropdownMenuItem(value: 'pending', child: Text(l10n.statusPending)),
                  DropdownMenuItem(value: 'completed', child: Text(l10n.statusCompleted)),
                  DropdownMenuItem(value: 'cancelled', child: Text(l10n.statusCancelled)),
                ],
                onChanged: (value) => setState(() => _status = value!),
              ),
              const SizedBox(height: 16),

              // Outstanding preview
              if (_fareController.text.isNotEmpty)
                _OutstandingPreview(
                  fareText: _fareController.text,
                  advanceText: _advanceController.text,
                ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(isEditing ? l10n.save : l10n.add),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_vehicleId == null || _driverId == null) return;

    setState(() => _isSaving = true);

    try {
      final fareRes = parseMoneyInput(_fareController.text);
      final farePaisa = (fareRes is Success) ? fareRes.value.paisa : 0;

      int advancePaisa = 0;
      if (_advanceController.text.trim().isNotEmpty) {
        final advRes = parseMoneyInput(_advanceController.text);
        if (advRes is Success) advancePaisa = advRes.value.paisa;
      }

      int? distanceKm;
      if (_distanceController.text.trim().isNotEmpty) {
        distanceKm = int.tryParse(toEnDigits(_distanceController.text.trim()));
      }

      final customCustomer = _useCustomCustomer && _customCustomerController.text.trim().isNotEmpty
          ? _customCustomerController.text.trim()
          : null;

      final dao = ref.read(tripDaoProvider);
      final companion = TripsCompanion(
        customerId: Value(_customerId),
        customCustomerName: Value(customCustomer),
        vehicleId: Value(_vehicleId!),
        driverId: Value(_driverId!),
        tripDate: Value(_tripDate),
        agreedFarePaisa: Value(farePaisa),
        advancePaisa: Value(advancePaisa),
        startOdo: const Value(0),
        endOdo: Value(distanceKm),
        status: Value(_status),
        updatedAt: Value(DateTime.now()),
      );

      if (widget.trip != null) {
        await dao.updateWithAudit(companion, id: widget.trip!.id, userNote: 'Trip updated');
      } else {
        await dao.insertWithAudit(companion, userNote: 'Trip added');
      }

      if (mounted) {
        AppToast.showSuccess(context, l10n.tripAddedSuccess);
        Navigator.pop(context);
        ref.invalidate(tripsProvider(const TripFilter()));
        ref.invalidate(activeCustomersProvider);
        ref.invalidate(dashboardProvider);
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, l10n.operationFailed(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _PickerField<T> extends StatelessWidget {
  final String label;
  final int? value;
  final AsyncValue<List<dynamic>> asyncValue;
  final String Function(dynamic) getLabel;
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
          items: items.map((item) => DropdownMenuItem<int>(
            value: item.id,
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
  final String fareText;
  final String advanceText;

  const _OutstandingPreview({
    required this.fareText,
    required this.advanceText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fareRes = parseMoneyInput(fareText);
    final advRes = parseMoneyInput(advanceText);

    final farePaisa = fareRes is Success ? fareRes.value.paisa : 0;
    final advPaisa = advRes is Success ? advRes.value.paisa : 0;
    final outstanding = farePaisa - advPaisa;

    if (outstanding < 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.outstandingLabel, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            formatMoney(Money.paisa(outstanding), context: context),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: outstanding > 0 ? Theme.of(context).extension<AppSemanticColors>()!.danger : null,
            ),
          ),
        ],
      ),
    );
  }
}
