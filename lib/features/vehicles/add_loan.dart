import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/vehicles/vehicle_loan_provider.dart';

class AddLoanSheet extends ConsumerStatefulWidget {
  final Vehicle vehicle;

  const AddLoanSheet({super.key, required this.vehicle});

  @override
  ConsumerState<AddLoanSheet> createState() => _AddLoanSheetState();
}

class _AddLoanSheetState extends ConsumerState<AddLoanSheet> {
  final _formKey = GlobalKey<FormState>();
  final _principalController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _startDate = DateTime.now();

  @override
  void dispose() {
    _principalController.dispose();
    _interestRateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = false; // TODO: Support editing

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
            Text(l10n.addLoanTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            // Vehicle Info (read-only)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.directions_bus, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.vehicle.regNo, style: Theme.of(context).textTheme.titleMedium),
                          Text(widget.vehicle.type, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Principal
            TextFormField(
              controller: _principalController,
              decoration: InputDecoration(
                labelText: l10n.principalLabel,
                hintText: l10n.principalHint,
                prefixText: '৳ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) return l10n.errorPositiveAmount;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Interest Rate
            TextFormField(
              controller: _interestRateController,
              decoration: InputDecoration(
                labelText: l10n.interestRateLabel,
                hintText: l10n.interestRateHint,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                final parsed = double.tryParse(value);
                if (parsed == null || parsed < 0) return l10n.errorPositiveAmount;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Start Date
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.startDateLabel,
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(formatDate(_startDate, context: context)),
              ),
            ),
            const SizedBox(height: 16),

            // Note
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l10n.noteLabel,
                hintText: l10n.noteHint,
              ),
              maxLines: 2,
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
                    child: Text(l10n.add),
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

    final principalPaisa = (double.parse(_principalController.text) * 100).round();
    final interestRateBps = (double.parse(_interestRateController.text) * 100).round(); // Convert % to basis points

    final dao = ref.read(vehicleLoanDaoProvider);
    await dao.insertWithAudit(VehicleLoansCompanion.insert(
      vehicleId: widget.vehicle.id,
      principalPaisa: principalPaisa,
      annualInterestRateBps: interestRateBps,
      startDate: _startDate,
    ), userNote: 'Vehicle loan added');

    if (mounted) {
      Navigator.pop(context);
      ref.invalidate(vehicleLoansProvider(widget.vehicle.id));
    }
  }
}