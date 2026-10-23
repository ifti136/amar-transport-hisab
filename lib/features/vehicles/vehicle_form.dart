import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/vehicles/vehicle_provider.dart';

class VehicleForm extends ConsumerStatefulWidget {
  final Vehicle? vehicle;

  const VehicleForm({super.key, this.vehicle});

  @override
  ConsumerState<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends ConsumerState<VehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final _regNoController = TextEditingController();
  final _typeController = TextEditingController();
  DateTime? _insuranceExpiry;
  DateTime? _fitnessExpiry;
  DateTime? _taxExpiry;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    if (widget.vehicle != null) {
      _regNoController.text = widget.vehicle!.regNo;
      _typeController.text = widget.vehicle!.type;
      _insuranceExpiry = widget.vehicle!.insuranceExpiry;
      _fitnessExpiry = widget.vehicle!.fitnessExpiry;
      _taxExpiry = widget.vehicle!.taxExpiry;
      _status = widget.vehicle!.status;
    }
  }

  @override
  void dispose() {
    _regNoController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.vehicle != null;

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
            TextFormField(
              controller: _regNoController,
              decoration: InputDecoration(
                labelText: l10n.vehicleLabel,
                hintText: l10n.vehicleRegNoHint,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.errorRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _typeController,
              decoration: InputDecoration(
                labelText: l10n.vehicleTypeLabel,
                hintText: l10n.vehicleTypeHint,
              ),
              initialValue: _typeController.text.isEmpty ? l10n.vehicleTypeHint : null,
            ),
            const SizedBox(height: 16),
            _DatePickerField(
              label: l10n.category_insurance,
              value: _insuranceExpiry,
              onChanged: (date) => setState(() => _insuranceExpiry = date),
            ),
            const SizedBox(height: 16),
            _DatePickerField(
              label: l10n.category_fitness,
              value: _fitnessExpiry,
              onChanged: (date) => setState(() => _fitnessExpiry = date),
            ),
            const SizedBox(height: 16),
            _DatePickerField(
              label: l10n.category_tax_token,
              value: _taxExpiry,
              onChanged: (date) => setState(() => _taxExpiry = date),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: InputDecoration(labelText: l10n.statusLabel),
              items: [
                DropdownMenuItem(value: 'active', child: Text(l10n.statusActive)),
                DropdownMenuItem(value: 'sold', child: Text(l10n.statusSold)),
                DropdownMenuItem(value: 'retired', child: Text(l10n.statusRetired)),
              ],
              onChanged: (value) => setState(() => _status = value!),
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

    final l10n = AppLocalizations.of(context)!;
    final dao = ref.read(vehicleDaoProvider);
    final companion = VehiclesCompanion(
      regNo: Value(_regNoController.text.trim()),
      type: Value(_typeController.text.trim().isEmpty ? l10n.vehicleTypeHint : _typeController.text.trim()),
      insuranceExpiry: Value(_insuranceExpiry),
      fitnessExpiry: Value(_fitnessExpiry),
      taxExpiry: Value(_taxExpiry),
      status: Value(_status),
      updatedAt: Value(DateTime.now()),
    );

    if (widget.vehicle != null) {
      await dao.updateWithAudit(companion, id: widget.vehicle!.id, userNote: 'Vehicle updated');
    } else {
      await dao.insertWithAudit(companion, userNote: 'Vehicle added');
    }

    if (mounted) {
      Navigator.pop(context);
      ref.invalidate(activeVehiclesProvider);
      ref.invalidate(allVehiclesProvider);
    }
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null ? formatDate(value!, context: context) : l10n.today,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}