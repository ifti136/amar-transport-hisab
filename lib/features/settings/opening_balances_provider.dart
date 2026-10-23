import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/db/daos/opening_balances_dao.dart';
import 'package:transport_hisab/core/audit/audit_log.dart';

/// Opening balances DAO provider
final openingBalancesDaoProvider = Provider<OpeningBalancesDao>((ref) {
  final db = ref.watch(databaseProvider);
  final audit = ref.watch(auditServiceProvider);
  return OpeningBalancesDao(db, audit);
});

/// Opening cash provider
final openingCashProvider = FutureProvider<int>((ref) async {
  final dao = ref.watch(openingBalancesDaoProvider);
  return dao.getOpeningCash();
});

/// Customer opening balances provider
final customerOpeningBalancesProvider = FutureProvider<Map<int, int>>((ref) async {
  final dao = ref.watch(openingBalancesDaoProvider);
  final all = await dao.getAllOpeningBalances();
  return all['customers'] as Map<int, int>;
});

/// Driver opening balances provider
final driverOpeningBalancesProvider = FutureProvider<Map<int, int>>((ref) async {
  final dao = ref.watch(openingBalancesDaoProvider);
  final all = await dao.getAllOpeningBalances();
  return all['drivers'] as Map<int, int>;
});

/// All opening balances provider
final allOpeningBalancesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dao = ref.watch(openingBalancesDaoProvider);
  return dao.getAllOpeningBalances();
});