import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:collection/collection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/core/widgets/app_toast.dart';
import 'package:transport_hisab/features/dashboard/dashboard_provider.dart';
import 'package:transport_hisab/features/money/money_provider.dart';
import 'package:transport_hisab/features/money/expense_categories_provider.dart';
import 'package:transport_hisab/features/vehicles/vehicle_provider.dart';
import 'package:transport_hisab/features/trips/trip_provider.dart';
import 'package:transport_hisab/core/services/photo_service.dart';

enum ExpenseEntryMode { general, trip, fuel }

class ExpenseForm extends ConsumerStatefulWidget {
  final Expense? expense;
  final FuelRecord? fuel;
  final ExpenseEntryMode initialMode;
  final int? preselectedTripId;

  const ExpenseForm({
    super.key,
    this.expense,
    this.fuel,
    this.initialMode = ExpenseEntryMode.general,
    this.preselectedTripId,
  });

  @override
  ConsumerState<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  // Fuel specific controllers
  final _litresController = TextEditingController();
  final _rateController = TextEditingController();

  late ExpenseEntryMode _mode;
  String _category = 'toll';
  int? _vehicleId;
  int? _tripId;
  DateTime _expenseDate = DateTime.now();
  String? _photoPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;

    if (widget.fuel != null) {
      _mode = ExpenseEntryMode.fuel;
      _vehicleId = widget.fuel!.vehicleId;
      _expenseDate = widget.fuel!.fuelDate;
      _litresController.text = widget.fuel!.litres.toStringAsFixed(1);
      _rateController.text = (widget.fuel!.ratePerLitrePaisa / 100).toStringAsFixed(2);
      _amountController.text = ((widget.fuel!.ratePerLitrePaisa * widget.fuel!.litres) / 100).toStringAsFixed(2);
    } else if (widget.expense != null) {
      if (widget.expense!.category == 'diesel') {
        _mode = ExpenseEntryMode.fuel;
      } else if (widget.expense!.tripId != null) {
        _mode = ExpenseEntryMode.trip;
      } else {
        _mode = ExpenseEntryMode.general;
      }
      _category = widget.expense!.category;
      _vehicleId = widget.expense!.vehicleId;
      _tripId = widget.expense!.tripId;
      _expenseDate = widget.expense!.expenseDate;
      _amountController.text = (widget.expense!.amountPaisa / 100).toStringAsFixed(2);
      _noteController.text = widget.expense!.note ?? '';
      _photoPath = widget.expense!.photoPath;
    } else {
      if (widget.preselectedTripId != null) {
        _mode = ExpenseEntryMode.trip;
        _tripId = widget.preselectedTripId;
      }
      _category = _mode == ExpenseEntryMode.trip ? 'toll' : 'maintenance';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _litresController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _updateFuelTotal() {
    final litres = double.tryParse(toEnDigits(_litresController.text.trim())) ?? 0;
    final rate = double.tryParse(toEnDigits(_rateController.text.trim())) ?? 0;
    if (litres > 0 && rate > 0) {
      _amountController.text = (litres * rate).toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.expense != null || widget.fuel != null;
    final tripCategories = ref.watch(tripCategoriesProvider);
    final vehicleCategories = ref.watch(vehicleCategoriesProvider);

    final activeCategories = _mode == ExpenseEntryMode.trip ? tripCategories : vehicleCategories;

    // Ensure _category is in current active categories when not fuel
    if (_mode != ExpenseEntryMode.fuel && !activeCategories.contains(_category)) {
      _category = activeCategories.isNotEmpty ? activeCategories.first : 'other';
    }

    final vehiclesAsync = ref.watch(activeVehiclesProvider);
    final tripsAsync = ref.watch(tripsProvider(const TripFilter()));

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
                isEditing ? l10n.edit : l10n.addExpenseTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              // 3-way Primary Expense Category Segmented Control
              SegmentedButton<ExpenseEntryMode>(
                segments: [
                  ButtonSegment<ExpenseEntryMode>(
                    value: ExpenseEntryMode.general,
                    icon: const Icon(Icons.directions_bus),
                    label: Text(l10n.generalExpenseOption),
                  ),
                  ButtonSegment<ExpenseEntryMode>(
                    value: ExpenseEntryMode.trip,
                    icon: const Icon(Icons.local_shipping),
                    label: Text(l10n.tripExpenseOption),
                  ),
                  ButtonSegment<ExpenseEntryMode>(
                    value: ExpenseEntryMode.fuel,
                    icon: const Icon(Icons.local_gas_station),
                    label: Text(l10n.fuelExpenseOption),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (set) {
                  setState(() {
                    _mode = set.first;
                    if (_mode == ExpenseEntryMode.trip) {
                      _category = tripCategories.first;
                    } else if (_mode == ExpenseEntryMode.general) {
                      _tripId = null;
                      _category = vehicleCategories.first;
                    } else {
                      _tripId = null;
                      _category = 'diesel';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Trip Picker (for Trip Expense)
              if (_mode == ExpenseEntryMode.trip) ...[
                tripsAsync.when(
                  data: (trips) {
                    if (trips.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          l10n.noTransactionsYet,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      );
                    }
                    return DropdownButtonFormField<int>(
                      value: _tripId,
                      decoration: InputDecoration(
                        labelText: l10n.tripLabel,
                        prefixIcon: const Icon(Icons.local_shipping),
                      ),
                      items: trips.map((t) {
                        final custName = t.customCustomerName != null && t.customCustomerName!.isNotEmpty
                            ? ' • ${t.customCustomerName}'
                            : (t.customerId != null ? ' • #${t.customerId}' : '');
                        return DropdownMenuItem(
                          value: t.id,
                          child: Text('Trip #${t.id}$custName (${formatDate(t.tripDate, short: true, context: context)})'), // i18n-ignore
                        );
                      }).toList(),
                      onChanged: (id) {
                        setState(() {
                          _tripId = id;
                          final selectedTrip = trips.firstWhereOrNull((t) => t.id == id);
                          if (selectedTrip != null) {
                            _vehicleId = selectedTrip.vehicleId;
                          }
                        });
                      },
                      validator: (id) => id == null ? l10n.selectTripError : null,
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Text(l10n.errorLoadingItems(l10n.tripLabel)),
                ),
                const SizedBox(height: 16),
              ],

              // Vehicle Picker
              _PickerField<int>(
                label: l10n.vehicleLabel,
                value: _vehicleId,
                asyncValue: vehiclesAsync,
                getLabel: (v) => '${v.regNo} (${v.type})',
                getId: (v) => v.id,
                onChanged: _mode == ExpenseEntryMode.trip ? null : (id) => setState(() => _vehicleId = id),
                validator: (id) => id == null ? l10n.errorRequired : null,
              ),
              const SizedBox(height: 16),

              // Category Selector (General or Trip)
              if (_mode != ExpenseEntryMode.fuel) ...[
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: InputDecoration(
                    labelText: l10n.categoryLabel,
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                  items: activeCategories.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(getCategoryDisplayName(c, context)),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Fuel-specific fields: Litres and Rate
              if (_mode == ExpenseEntryMode.fuel) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _litresController,
                        decoration: InputDecoration(
                          labelText: l10n.litresLabel,
                          hintText: l10n.litresHint,
                          suffixText: 'L', // i18n-ignore
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => _updateFuelTotal(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                          final parsed = double.tryParse(toEnDigits(value.trim()));
                          if (parsed == null || parsed <= 0) return l10n.errorInvalidNumber;
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _rateController,
                        decoration: InputDecoration(
                          labelText: l10n.rateLabel,
                          hintText: l10n.rateHint,
                          prefixText: '৳ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => _updateFuelTotal(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                          final res = parseMoneyInput(value);
                          if (res is Failure) return res.error;
                          if (res is Success && res.value.paisa <= 0) return l10n.errorPositiveAmount;
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Amount / Total Field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: _mode == ExpenseEntryMode.fuel ? l10n.totalLabel : l10n.amountLabel,
                  hintText: _mode == ExpenseEntryMode.fuel ? l10n.totalHint : l10n.amountHint,
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

              // Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expenseDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _expenseDate = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.dateLabel,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(formatDate(_expenseDate, context: context)),
                ),
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

              // Receipt Photo (for general and trip)
              if (_mode != ExpenseEntryMode.fuel) ...[
                _PhotoPicker(
                  currentPhotoPath: _photoPath,
                  onPhotoSelected: (path) => setState(() => _photoPath = path),
                  onPhotoRemoved: () => setState(() => _photoPath = null),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 12),

              // Action buttons: Cancel, Save & Add Another (for Trip Expense), and Save
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_mode == ExpenseEntryMode.trip && !isEditing) ...[
                    FilledButton.tonalIcon(
                      onPressed: _isSaving ? null : () => _save(addAnother: true),
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(l10n.saveAndAddAnother),
                    ),
                    const SizedBox(height: 8),
                  ],
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
                          onPressed: _isSaving ? null : () => _save(addAnother: false),
                          child: _isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(isEditing ? l10n.save : l10n.add),
                        ),
                      ),
                    ],
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

  Future<void> _save({bool addAnother = false}) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_vehicleId == null) return;
    if (_mode == ExpenseEntryMode.trip && _tripId == null) return;

    setState(() => _isSaving = true);

    try {
      final amtRes = parseMoneyInput(_amountController.text);
      final amountPaisa = amtRes is Success ? amtRes.value.paisa : 0;
      final expenseDao = ref.read(expenseDaoProvider);
      final fuelDao = ref.read(fuelDaoProvider);

      if (_mode == ExpenseEntryMode.fuel) {
        final litres = double.parse(toEnDigits(_litresController.text.trim()));
        final rateRes = parseMoneyInput(_rateController.text);
        final ratePaisa = rateRes is Success ? rateRes.value.paisa : (litres > 0 ? (amountPaisa / litres).round() : 0);

        if (widget.fuel != null) {
          // Update linked diesel expense
          final expenseCompanion = ExpensesCompanion(
            vehicleId: Value(_vehicleId!),
            category: const Value('diesel'),
            amountPaisa: Value(amountPaisa),
            expenseDate: Value(_expenseDate),
            note: Value(_noteController.text.trim().isEmpty ? 'Fuel purchase' : _noteController.text.trim()),
            updatedAt: Value(DateTime.now()),
          );
          await expenseDao.updateWithAudit(expenseCompanion, id: widget.fuel!.expenseId, userNote: 'Fuel expense updated');

          // Update fuel record
          final fuelCompanion = FuelRecordsCompanion(
            vehicleId: Value(_vehicleId!),
            litres: Value(litres),
            ratePerLitrePaisa: Value(ratePaisa),
            odometer: const Value(0),
            fuelDate: Value(_expenseDate),
            updatedAt: Value(DateTime.now()),
          );
          await fuelDao.updateWithAudit(fuelCompanion, id: widget.fuel!.id, userNote: 'Fuel record updated');
        } else {
          // Insert linked diesel expense first
          final expenseCompanion = ExpensesCompanion(
            vehicleId: Value(_vehicleId!),
            category: const Value('diesel'),
            amountPaisa: Value(amountPaisa),
            expenseDate: Value(_expenseDate),
            note: Value(_noteController.text.trim().isEmpty ? 'Fuel purchase' : _noteController.text.trim()),
            updatedAt: Value(DateTime.now()),
          );
          final expenseId = await expenseDao.insertWithAudit(expenseCompanion, userNote: 'Fuel expense added');

          // Insert fuel record linked to expense
          final fuelCompanion = FuelRecordsCompanion(
            vehicleId: Value(_vehicleId!),
            expenseId: Value(expenseId),
            litres: Value(litres),
            ratePerLitrePaisa: Value(ratePaisa),
            odometer: const Value(0),
            fuelDate: Value(_expenseDate),
            updatedAt: Value(DateTime.now()),
          );
          await fuelDao.insertWithAudit(fuelCompanion, userNote: 'Fuel record added');
        }
      } else {
        // General or Trip Expense
        final companion = ExpensesCompanion(
          vehicleId: Value(_vehicleId!),
          tripId: Value(_mode == ExpenseEntryMode.trip ? _tripId : null),
          category: Value(_category),
          amountPaisa: Value(amountPaisa),
          expenseDate: Value(_expenseDate),
          note: Value(_noteController.text.trim().isEmpty ? null : _noteController.text.trim()),
          photoPath: Value(_photoPath),
          updatedAt: Value(DateTime.now()),
        );

        if (widget.expense != null) {
          await expenseDao.updateWithAudit(companion, id: widget.expense!.id, userNote: 'Expense updated');
        } else {
          await expenseDao.insertWithAudit(companion, userNote: 'Expense added');
        }
      }

      ref.invalidate(expensesProvider(const ExpenseFilter()));
      ref.invalidate(fuelRecordsProvider(const FuelFilter()));
      ref.invalidate(dashboardProvider);
      if (_tripId != null) {
        ref.invalidate(tripWithOutstandingProvider(_tripId!));
      }

      if (mounted) {
        AppToast.showSuccess(
          context,
          _mode == ExpenseEntryMode.fuel ? l10n.fuelAddedSuccess : l10n.expenseAddedSuccess,
        );

        if (addAnother) {
          // Clear current amount and note, keep trip, vehicle, and date intact
          _amountController.clear();
          _noteController.clear();
          _photoPath = null;
          setState(() => _isSaving = false);
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, l10n.operationFailed(e.toString()));
      }
    } finally {
      if (mounted && !addAnother) {
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
  final int Function(dynamic) getId;
  final ValueChanged<int?>? onChanged;
  final String? Function(int?)? validator;

  const _PickerField({
    required this.label,
    required this.value,
    required this.asyncValue,
    required this.getLabel,
    required this.getId,
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
            value: getId(item),
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

class _PhotoPicker extends ConsumerWidget {
  final String? currentPhotoPath;
  final ValueChanged<String> onPhotoSelected;
  final VoidCallback onPhotoRemoved;

  const _PhotoPicker({
    required this.currentPhotoPath,
    required this.onPhotoSelected,
    required this.onPhotoRemoved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.receiptPhotoLabel, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        if (currentPhotoPath != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(currentPhotoPath!),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton.filled(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onPhotoRemoved,
                ),
              ),
            ],
          ),
        ] else ...[
          OutlinedButton.icon(
            onPressed: () => _pickImage(context, ref),
            icon: const Icon(Icons.camera_alt),
            label: Text(l10n.receiptPhotoLabel),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
    final image = await PhotoService.pickImage(source: ImageSource.camera);
    if (image != null) {
      final savedPath = await PhotoService.saveImage(image);
      onPhotoSelected(savedPath);
    }
  }
}
