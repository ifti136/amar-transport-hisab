import 'dart:math' as math;

/// Pure salary-payable calculation for a driver.
///
/// [deductionPaisa] is what the user typed as the advance deduction. It is
/// clamped to the smaller of the outstanding advance and the pending salary
/// (= earned - already paid), so the UI, validator and save path always use
/// one canonical number.
class SalaryPayable {
  final int earnedPaisa;
  final int paidPaisa;
  final int outstandingAdvancePaisa;
  final int deductionPaisa;

  const SalaryPayable({
    required this.earnedPaisa,
    required this.paidPaisa,
    required this.outstandingAdvancePaisa,
    required this.deductionPaisa,
  });

  /// Salary still owed before any advance deduction.
  int get pendingPaisa => math.max(0, earnedPaisa - paidPaisa);

  /// Largest deduction the user may apply.
  int get maxDeductionPaisa =>
      math.min(pendingPaisa, math.max(0, outstandingAdvancePaisa));

  /// The user's deduction clamped into the valid range.
  int get clampedDeductionPaisa =>
      math.max(0, math.min(deductionPaisa, maxDeductionPaisa));

  /// Salary that can actually be paid after the clamped deduction.
  int get netPayablePaisa => pendingPaisa - clampedDeductionPaisa;
}
