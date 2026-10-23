import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/drivers/driver_provider.dart';

class DriverForm extends ConsumerStatefulWidget {
  final Driver? driver;

  const DriverForm({super.key, this.driver});

  @override
  ConsumerState<DriverForm> createState() => _DriverFormState();
}

class _DriverFormState extends ConsumerState<DriverForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _salaryController = TextEditingController();
  DateTime? _joinedDate;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    if (widget.driver != null) {
      _nameController.text = widget.driver!.name;
      _phoneController.text = widget.driver!.phone ?? '';
      _salaryController.text = (widget.driver!.monthlySalaryPaisa / 100).toStringAsFixed(0);
      _joinedDate = widget.driver!.joinedDate;
      _status = widget.driver!.status;
    } else {
      _joinedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.driver != null;

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
              isEditing ? l10n.edit : l10n.newDriverTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.driverLabel,
                hintText: l10n.driverNameHint,
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
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: l10n.phoneLabel,
                hintText: l10n.phoneHint,
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _salaryController,
              decoration: InputDecoration(
                labelText: l10n.monthlySalaryLabel,
                hintText: l10n.monthlySalaryHint,
                prefixText: '৳ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.errorRequired;
                }
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) {
                  return l10n.errorPositiveAmount;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _joinedDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _joinedDate = picked);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.joinedDateLabel,
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  _joinedDate != null
                      ? formatDate(_joinedDate!, context: context)
                      : AppLocalizations.of(context)!.today,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: InputDecoration(labelText: l10n.driverStatusLabel),
              items: [
                DropdownMenuItem(value: 'active', child: Text(l10n.driverStatusActive)),
                DropdownMenuItem(value: 'inactive', child: Text(l10n.driverStatusInactive)),
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

    final salaryPaisa = (double.parse(_salaryController.text) * 100).round();

    final dao = ref.read(driverDaoProvider);
    final companion = DriversCompanion(
      name: Value(_nameController.text.trim()),
      phone: Value(_phoneController.text.trim().isEmpty ? null : _phoneController.text.trim()),
      monthlySalaryPaisa: Value(salaryPaisa),
      joinedDate: Value(_joinedDate ?? DateTime.now()),
      status: Value(_status),
      updatedAt: Value(DateTime.now()),
    );

    if (widget.driver != null) {
      await dao.updateWithAudit(companion, id: widget.driver!.id, userNote: 'Driver updated');
    } else {
      await dao.insertWithAudit(companion, userNote: 'Driver added');
    }

    if (mounted) {
      Navigator.pop(context);
      ref.invalidate(activeDriversProvider);
      ref.invalidate(allDriversProvider);
    }
  }
}