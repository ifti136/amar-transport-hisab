import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/core/widgets/app_toast.dart';
import 'package:transport_hisab/features/dashboard/dashboard_provider.dart';
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

  int? _vehicleId;
  DateTime _fuelDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.fuel != null) {
      _vehicleId = widget.fuel!.vehicleId;
      _fuelDate = widget.fuel!.fuelDate;
      _litresController.text = widget.fuel!.litres.toStringAsFixed(1);
      _rateController.text = (widget.fuel!.ratePerLitrePaisa / 100).toStringAsFixed(2);
      _totalController.text = ((widget.fuel!.ratePerLitrePaisa * widget.fuel!.litres) / 100).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _litresController.dispose();
    _rateController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  void _updateTotal() {
    final litresStr = toEnDigits(_litresController.text.trim());
    final rateStr = toEnDigits(_rateController.text.trim());
    final litres = double.tryParse(litresStr) ?? 0;
    final rate = double.tryParse(rateStr) ?? 0;
    if (litres > 0 && rate > 0) {
      final total = litres * rate;
      _totalController.text = total.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.fuel != null;

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
                    lastDate: DateTime.now().add(const Duration(days: 30)),
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
                  suffixText: 'L', // i18n-ignore
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _updateTotal(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                  final parsed = double.tryParse(toEnDigits(value.trim()));
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _updateTotal(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                  final res = parseMoneyInput(value);
                  if (res is Failure) return res.error;
                  if (res is Success && res.value.paisa <= 0) return l10n.errorPositiveAmount;
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                  final res = parseMoneyInput(value);
                  if (res is Failure) return res.error;
                  if (res is Success && res.value.paisa <= 0) return l10n.errorPositiveAmount;
                  return null;
                },
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

    setState(() => _isSaving = true);

    try {
      final litres = double.parse(toEnDigits(_litresController.text.trim()));
      final rateRes = parseMoneyInput(_rateController.text);
      final totalRes = parseMoneyInput(_totalController.text);

      final ratePaisa = rateRes is Success ? rateRes.value.paisa : (litres > 0 ? (totalRes is Success ? (totalRes.value.paisa / litres).round() : 0) : 0);
      final totalPaisa = totalRes is Success ? totalRes.value.paisa : (litres * ratePaisa).round();

      final dao = ref.read(fuelDaoProvider);
      final expenseDao = ref.read(expenseDaoProvider);

      if (widget.fuel != null) {
        // Update linked diesel expense
        final expenseCompanion = ExpensesCompanion(
          vehicleId: Value(_vehicleId!),
          category: const Value('diesel'),
          amountPaisa: Value(totalPaisa),
          expenseDate: Value(_fuelDate),
          note: const Value('Fuel purchase'),
          updatedAt: Value(DateTime.now()),
        );
        await expenseDao.updateWithAudit(expenseCompanion, id: widget.fuel!.expenseId, userNote: 'Fuel expense updated');

        // Update fuel record
        final fuelCompanion = FuelRecordsCompanion(
          vehicleId: Value(_vehicleId!),
          litres: Value(litres),
          ratePerLitrePaisa: Value(ratePaisa),
          odometer: const Value(0),
          fuelDate: Value(_fuelDate),
          updatedAt: Value(DateTime.now()),
        );
        await dao.updateWithAudit(fuelCompanion, id: widget.fuel!.id, userNote: 'Fuel record updated');
      } else {
        // 1. Insert expense first to obtain expense_id
        final expenseCompanion = ExpensesCompanion(
          vehicleId: Value(_vehicleId!),
          category: const Value('diesel'),
          amountPaisa: Value(totalPaisa),
          expenseDate: Value(_fuelDate),
          note: const Value('Fuel purchase'),
          updatedAt: Value(DateTime.now()),
        );
        final expenseId = await expenseDao.insertWithAudit(expenseCompanion, userNote: 'Fuel expense added');

        // 2. Insert fuel record with valid expenseId
        final fuelCompanion = FuelRecordsCompanion(
          vehicleId: Value(_vehicleId!),
          expenseId: Value(expenseId),
          litres: Value(litres),
          ratePerLitrePaisa: Value(ratePaisa),
          odometer: const Value(0),
          fuelDate: Value(_fuelDate),
          updatedAt: Value(DateTime.now()),
        );
        await dao.insertWithAudit(fuelCompanion, userNote: 'Fuel record added');
      }

      if (mounted) {
        AppToast.showSuccess(context, l10n.fuelAddedSuccess);
        Navigator.pop(context);
        ref.invalidate(fuelRecordsProvider(const FuelFilter()));
        ref.invalidate(expensesProvider(const ExpenseFilter()));
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
          onChanged: onChanged,
          validator: validator,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Text(l10n.errorLoadingItems(label)),
    );
  }
}
