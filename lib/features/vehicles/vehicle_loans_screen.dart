import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/vehicles/vehicle_loan_provider.dart';
import 'package:transport_hisab/features/vehicles/add_loan.dart';
import 'package:transport_hisab/features/vehicles/add_installment.dart';
import 'package:transport_hisab/features/vehicles/loan_detail.dart';

class VehicleLoansScreen extends ConsumerWidget {
  final Vehicle vehicle;

  const VehicleLoansScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final loansAsync = ref.watch(vehicleLoansProvider(vehicle.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loanOutstanding),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddLoan(context),
            tooltip: l10n.add,
          ),
        ],
      ),
      body: loansAsync.when(
        data: (loans) {
          if (loans.isEmpty) {
            return _emptyState(context, l10n);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: loans.length,
            itemBuilder: (context, index) {
              final loan = loans[index];
              return _LoanCard(loan: loan, vehicle: vehicle);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _errorState(context, ref, l10n, error.toString()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLoan(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.add),
      ),
    );
  }

  Widget _emptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No loans yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a vehicle loan to track installments',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showAddLoan(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context, WidgetRef ref, AppLocalizations l10n, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(l10n.errorInvalidNumber, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(error, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(vehicleLoansProvider(vehicle.id)),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLoan(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddLoanSheet(vehicle: vehicle),
    );
  }
}

class _LoanCard extends ConsumerWidget {
  final VehicleLoan loan;
  final Vehicle vehicle;

  const _LoanCard({required this.loan, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LoanDetailScreen(loan: loan, vehicle: vehicle)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.account_balance_wallet, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loan #${loan.id}',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Vehicle: ${vehicle.regNo}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _OutstandingBadge(loanId: loan.id),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.attach_money,
                      label: 'Principal',
                      value: formatMoney(Money.paisa(loan.principalPaisa), context: context),
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.percent,
                      label: 'Interest Rate',
                      value: '${(loan.annualInterestRateBps / 100).toStringAsFixed(2)}%',
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.calendar_today,
                      label: 'Start Date',
                      value: formatDate(loan.startDate, context: context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.account_balance_wallet,
                      label: l10n.loanOutstanding,
                      value: '৳0', // TODO: Load actual outstanding
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.add_circle_outline,
                      label: 'Add Installment',
                      value: '',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutstandingBadge extends ConsumerWidget {
  final int loanId;

  const _OutstandingBadge({required this.loanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    return FutureBuilder<int>(
      future: ref.read(vehicleLoanDaoProvider).getLoanOutstanding(loanId, DateTime.now()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final outstanding = snapshot.data!;
        if (outstanding <= 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: semantic.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: semantic.danger),
          ),
          child: Text(
            'Outstanding: ${formatMoney(Money.paisa(outstanding), context: context)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: semantic.danger,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}