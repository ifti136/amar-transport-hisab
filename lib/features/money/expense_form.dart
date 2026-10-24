import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:collection/collection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/money/money_provider.dart';
import 'package:transport_hisab/features/money/expense_categories_provider.dart';
import 'package:transport_hisab/features/vehicles/vehicle_provider.dart';
import 'package:transport_hisab/features/trips/trip_provider.dart';
import 'package:transport_hisab/core/services/photo_service.dart';

class ExpenseForm extends ConsumerStatefulWidget {
  final Expense? expense;

  const ExpenseForm({super.key, this.expense});

  @override
  ConsumerState<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isTripExpense = false;
  String _category = 'toll';
  int? _vehicleId;
  int? _tripId;
  DateTime _expenseDate = DateTime.now();
  String? _photoPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _isTripExpense = widget.expense!.tripId != null;
      _category = widget.expense!.category;
      _vehicleId = widget.expense!.vehicleId;
      _tripId = widget.expense!.tripId;
      _expenseDate = widget.expense!.expenseDate;
      _amountController.text = (widget.expense!.amountPaisa / 100).toStringAsFixed(2);
      _noteController.text = widget.expense!.note ?? '';
      _photoPath = widget.expense!.photoPath;
    } else {
      _category = 'toll';
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
    final isEditing = widget.expense != null;
    final tripCategories = ref.watch(tripCategoriesProvider);
    final vehicleCategories = ref.watch(vehicleCategoriesProvider);
    final activeCategories = _isTripExpense ? tripCategories : vehicleCategories;

    // Ensure _category is in current active categories
    if (!activeCategories.contains(_category)) {
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

              // Segmented option: Trip Expense vs Vehicle Expense
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: true,
                    icon: const Icon(Icons.local_shipping),
                    label: Text(l10n.tripExpenseOption),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    icon: const Icon(Icons.directions_bus),
                    label: Text(l10n.generalExpenseOption),
                  ),
                ],
                selected: {_isTripExpense},
                onSelectionChanged: (set) {
                  setState(() {
                    _isTripExpense = set.first;
                    if (_isTripExpense) {
                      _category = tripCategories.first;
                    } else {
                      _tripId = null;
                      _category = vehicleCategories.first;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Trip Picker (if Trip Expense)
              if (_isTripExpense) ...[
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
                      items: trips.map((t) => DropdownMenuItem(
                        value: t.id,
                        child: Text('Trip #${t.id} - ${formatDate(t.tripDate, short: true, context: context)}'), // i18n-ignore
                      )).toList(),
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

              // Vehicle Picker (always show or auto-selected)
              _PickerField<int>(
                label: l10n.vehicleLabel,
                value: _vehicleId,
                asyncValue: vehiclesAsync,
                getLabel: (v) => '${v.regNo} (${v.type})',
                getId: (v) => v.id,
                onChanged: _isTripExpense ? null : (id) => setState(() => _vehicleId = id),
                validator: (id) => id == null ? l10n.errorRequired : null,
              ),
              const SizedBox(height: 16),

              // Single Category Selector
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

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: l10n.amountLabel,
                  hintText: l10n.amountHint,
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
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
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

              // Receipt Photo
              _PhotoPicker(
                currentPhotoPath: _photoPath,
                onPhotoSelected: (path) => setState(() => _photoPath = path),
                onPhotoRemoved: () => setState(() => _photoPath = null),
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
    if (_vehicleId == null) return;
    if (_isTripExpense && _tripId == null) return;

    setState(() => _isSaving = true);

    try {
      final amtRes = parseMoneyInput(_amountController.text);
      final amountPaisa = amtRes is Success ? amtRes.value.paisa : 0;

      final dao = ref.read(expenseDaoProvider);
      final companion = ExpensesCompanion(
        vehicleId: Value(_vehicleId!),
        tripId: Value(_isTripExpense ? _tripId : null),
        category: Value(_category),
        amountPaisa: Value(amountPaisa),
        expenseDate: Value(_expenseDate),
        note: Value(_noteController.text.trim().isEmpty ? null : _noteController.text.trim()),
        photoPath: Value(_photoPath),
        updatedAt: Value(DateTime.now()),
      );

      if (widget.expense != null) {
        await dao.updateWithAudit(companion, id: widget.expense!.id, userNote: 'Expense updated');
      } else {
        await dao.insertWithAudit(companion, userNote: 'Expense added');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.expenseAddedSuccess)),
        );
        Navigator.pop(context);
        ref.invalidate(expensesProvider(const ExpenseFilter()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')), // i18n-ignore
        );
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

    if (currentPhotoPath != null) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(currentPhotoPath!),
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onPhotoRemoved,
            style: IconButton.styleFrom(backgroundColor: Colors.black54),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: Text(l10n.cameraLabel),
            onPressed: () => _pickImage(ref, ImageSource.camera),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.photo_library),
            label: Text(l10n.galleryLabel),
            onPressed: () => _pickImage(ref, ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(WidgetRef ref, ImageSource source) async {
    final file = await PhotoService.pickImage(source: source);
    if (file != null) {
      final savedPath = await PhotoService.saveImage(file);
      onPhotoSelected(savedPath);
    }
  }
}
