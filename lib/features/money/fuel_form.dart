import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/money/money_provider.dart';
import 'package:transport_hisab/features/vehicles/vehicle_provider.dart';

class FuelForm extends ConsumerStatefulWidget {
  final FuelRecord? fuel;

  const FuelForm({super.key, this.fuel});

  @override
  ConsumerState<FuelForm> createState() => _FuelFormState();
}

class _FuelFormState extends ConsumerState<FuelForm> {
  final _formKey = GlobalKey<FormState>();
  final _litresController = TextEditingController();
  final _rateController = TextEditingController();
  final _totalController = TextEditingController();
  final _odometerController = TextEditingController();

  int? _vehicleId;
  DateTime _fuelDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.fuel != null) {
      _vehicleId = widget.fuel!.vehicleId;
      _fuelDate = widget.fuel!.fuelDate;
      _litresController.text = widget.fuel!.litres.toStringAsFixed(1);
      _rateController.text = (widget.fuel!.ratePerLitrePaisa / 100).toStringAsFixed(2);
      _totalController.text = ((widget.fuel!.ratePerLitrePaisa * widget.fuel!.litres) / 100).toStringAsFixed(2);
      _odometerController.text = widget.fuel!.odometer.toString();
    }
  }

  @override
  void dispose() {
    _litresController.dispose();
    _rateController.dispose();
    _totalController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  void _updateTotal() {
    final litres = double.tryParse(_litresController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final total = litres * rate;
    _totalController.text = total.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.fuel != null;
    final vehiclesAsync = ref.watch(activeVehiclesProvider);

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
              isEditing ? l10n.edit : l10n.addFuelTitle,
              style: Theme.of(context).textTheme.headlineSmall,
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
                  initialDate: _fuelDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _fuelDate = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.dateLabel,
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(formatDate(_fuelDate, context: context)),
              ),
            ),
            const SizedBox(height: 16),

            // Litres
            TextFormField(
              controller: _litresController,
              decoration: InputDecoration(
                labelText: l10n.litresLabel,
                hintText: l10n.litresHint,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _updateTotal(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) return l10n.errorPositiveAmount;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Rate per Litre
            TextFormField(
              controller: _rateController,
              decoration: InputDecoration(
                labelText: l10n.rateLabel,
                hintText: l10n.rateHint,
                prefixText: '৳ ',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _updateTotal(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) return l10n.errorPositiveAmount;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Total (auto-calculated, editable)
            TextFormField(
              controller: _totalController,
              decoration: InputDecoration(
                labelText: l10n.totalLabel,
                hintText: l10n.totalHint,
                prefixText: '৳ ',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) {
                // Allow manual override of total
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) return l10n.errorPositiveAmount;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Odometer
            TextFormField(
              controller: _odometerController,
              decoration: InputDecoration(
                labelText: l10n.odometerLabel,
                hintText: l10n.odometerHint,
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

            // Date Picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fuelDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _fuelDate = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.dateLabel,
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(formatDate(_fuelDate, context: context)),
              ),
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

    final litres = double.parse(_litresController.text);
    final ratePaisa = (double.parse(_rateController.text) * 100).round();
    final totalPaisa = (double.parse(_totalController.text) * 100).round();
    final odometer = int.parse(_odometerController.text);

    final dao = ref.read(fuelDaoProvider);
    final expenseDao = ref.read(expenseDaoProvider);

    // Create/update fuel record
    final fuelCompanion = FuelRecordsCompanion(
      vehicleId: Value(_vehicleId!),
      litres: Value(litres),
      ratePerLitrePaisa: Value(ratePaisa),
      odometer: Value(odometer),
      fuelDate: Value(_fuelDate),
      updatedAt: Value(DateTime.now()),
    );

    int fuelId;
    if (widget.fuel != null) {
      await dao.updateWithAudit(fuelCompanion, id: widget.fuel!.id, userNote: 'Fuel record updated');
      fuelId = widget.fuel!.id;
    } else {
      fuelId = await dao.insertWithAudit(fuelCompanion, userNote: 'Fuel record added');
    }

    // Create/update linked diesel expense
    final expenseCompanion = ExpensesCompanion(
      vehicleId: Value(_vehicleId!),
      category: const Value('diesel'),
      amountPaisa: Value(totalPaisa),
      expenseDate: Value(_fuelDate),
      note: const Value('Fuel purchase'),
      updatedAt: Value(DateTime.now()),
    );

    if (widget.fuel != null && widget.fuel!.expenseId != null) {
      await expenseDao.updateWithAudit(expenseCompanion, id: widget.fuel!.expenseId!, userNote: 'Fuel expense updated');
    } else {
      final expenseId = await expenseDao.insertWithAudit(expenseCompanion, userNote: 'Fuel expense added');
      // Update fuel record with expense_id
      await (dao.db.update(dao.db.fuelRecords)..where((t) => t.id.equals(fuelId)))
          .write(FuelRecordsCompanion(expenseId: Value(expenseId)));
    }

    if (mounted) {
      Navigator.pop(context);
      ref.invalidate(fuelRecordsProvider(const FuelFilter()));
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
          onChanged: (id) => onChanged(id as int?),
          validator: (id) => id == null ? l10n.errorRequired : null,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Text(l10n.errorLoadingItems(label)),
    );
  }
}