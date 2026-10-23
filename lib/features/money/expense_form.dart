import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:image_picker/image_picker.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/money/money_provider.dart';
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

  String _category = 'diesel';
  int? _vehicleId;
  int? _tripId;
  DateTime _expenseDate = DateTime.now();
  String? _photoPath;

  final List<String> _categories = [
    'diesel', 'toll', 'repair', 'maintenance', 'insurance', 'fitness', 'tax_token', 'other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _category = widget.expense!.category;
      _vehicleId = widget.expense!.vehicleId;
      _tripId = widget.expense!.tripId;
      _expenseDate = widget.expense!.expenseDate;
      _amountController.text = (widget.expense!.amountPaisa / 100).toStringAsFixed(2);
      _noteController.text = widget.expense!.note ?? '';
      _photoPath = widget.expense!.photoPath;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? l10n.edit : l10n.addExpenseTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Category Chips
            Text(l10n.categoryLabel, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _category == cat;
                return FilterChip(
                  label: Text(_getCategoryLabel(cat)),
                  selected: isSelected,
                  onSelected: (selected) => setState(() => _category = cat),
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
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
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) return l10n.errorPositiveAmount;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Vehicle Picker
            _PickerField<int>(
              label: l10n.vehicleLabel,
              value: _vehicleId,
              asyncValue: ref.watch(activeVehiclesProvider),
              getLabel: (v) => '${v.regNo} (${v.type})',
              getId: (v) => v.id,
              onChanged: (id) => setState(() => _vehicleId = id),
              validator: (id) => id == null ? l10n.errorRequired : null,
            ),
            const SizedBox(height: 16),

            // Date Picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _expenseDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
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

            // Trip Picker (optional)
            _PickerField<int>(
              label: l10n.tripLabel,
              value: _tripId,
              asyncValue: ref.watch(tripsProvider(const TripFilter())),
              getLabel: (t) => 'Trip #${t.id} (${formatDate(t.tripDate, context: context)})',
              getId: (t) => t.id,
              onChanged: (id) => setState(() => _tripId = id),
              allowNull: true,
              nullLabel: l10n.tripLabel + ' (optional)',
            ),
            const SizedBox(height: 16),

            // Category Dropdown (for non-diesel)
            if (_category != 'diesel')
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(labelText: l10n.categoryLabel),
                items: _categories.where((c) => c != 'diesel').map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(_getCategoryLabel(c)),
                )).toList(),
                onChanged: (value) => setState(() => _category = value!),
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

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'diesel': return 'Diesel';
      case 'toll': return 'Toll';
      case 'repair': return 'Repair';
      case 'maintenance': return 'Maintenance';
      case 'insurance': return 'Insurance';
      case 'fitness': return 'Fitness';
      case 'tax_token': return 'Tax Token';
      default: return 'Other';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amountPaisa = (double.parse(_amountController.text) * 100).round();

    final dao = ref.read(expenseDaoProvider);
    final companion = ExpensesCompanion(
      vehicleId: Value(_vehicleId!),
      tripId: Value(_tripId),
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
      Navigator.pop(context);
      ref.invalidate(expensesProvider(const ExpenseFilter()));
    }
  }
}

class _PickerField<T> extends StatelessWidget {
  final String label;
  final int? value;
  final AsyncValue<List<dynamic>> asyncValue;
  final String Function(dynamic) getLabel;
  final int Function(dynamic) getId;
  final ValueChanged<int?> onChanged;
  final String? Function(int?)? validator;
  final bool allowNull;
  final String? nullLabel;

  const _PickerField({
    required this.label,
    required this.value,
    required this.asyncValue,
    required this.getLabel,
    required this.getId,
    required this.onChanged,
    this.validator,
    this.allowNull = false,
    this.nullLabel,
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
          items: [
            if (allowNull) DropdownMenuItem<int>(value: null, child: Text(nullLabel ?? 'None')),
            ...items.map((item) => DropdownMenuItem(
              value: getId(item),
              child: Text(getLabel(item)),
            )),
          ],
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.receiptPhotoLabel, style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        if (currentPhotoPath != null) ...[
          Stack(
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
              Positioned(
                top: 4,
                right: 4,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.white),
                    onPressed: onPhotoRemoved,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: Text(l10n.cameraLabel),
              onPressed: () async {
                final photo = await PhotoService.pickImage(source: ImageSource.camera);
                if (photo != null) {
                  final saved = await PhotoService.saveImage(photo);
                  onPhotoSelected(saved);
                }
              },
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: Text(l10n.galleryLabel),
              onPressed: () async {
                final photo = await PhotoService.pickImage(source: ImageSource.gallery);
                if (photo != null) {
                  final saved = await PhotoService.saveImage(photo);
                  onPhotoSelected(saved);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}