import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/app_settings.dart';
import '../tables/customers.dart';
import '../tables/drivers.dart';
import 'package:transport_hisab/core/audit/audit_log.dart';
import 'base_dao.dart';

class OpeningBalancesDao {
  final AppDatabase db;
  final AuditService audit;

  OpeningBalancesDao(this.db, this.audit);

  // Opening Cash (stored in app_settings)
  static const _openingCashKey = 'opening_cash_paisa';

  Future<int> getOpeningCash() async {
    final setting = await (db.select(db.appSettings)
          ..where((t) => t.key.equals(_openingCashKey)))
        .getSingleOrNull();
    return setting != null ? int.tryParse(setting.value) ?? 0 : 0;
  }

  Future<void> setOpeningCash(int amountPaisa) async {
    final oldSetting = await (db.select(db.appSettings)
          ..where((t) => t.key.equals(_openingCashKey)))
        .getSingleOrNull();

    final oldValue = oldSetting?.value ?? '0';
    final newValue = amountPaisa.toString();

    await db.into(db.appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(
        key: _openingCashKey,
        value: newValue,
      ),
    );

    await audit.logUpdate(
      tableName: 'app_settings',
      rowId: 0, // app_settings uses key as PK
      oldValues: {'value': oldValue},
      newValues: {'value': newValue},
      userNote: 'Opening cash updated',
    );
  }

  // Customer Opening Balances (stored in customers table)
  Future<int> getCustomerOpeningBalance(int customerId) async {
    final customer = await (db.select(db.customers)
          ..where((t) => t.id.equals(customerId) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return customer?.openingBalancePaisa ?? 0;
  }

  Future<void> setCustomerOpeningBalance(int customerId, int amountPaisa) async {
    final oldCustomer = await (db.select(db.customers)
          ..where((t) => t.id.equals(customerId) & t.deletedAt.isNull()))
        .getSingleOrNull();

    if (oldCustomer == null) return;

    final oldValue = oldCustomer.openingBalancePaisa.toString();
    final newValue = amountPaisa.toString();

    await (db.update(db.customers)..where((t) => t.id.equals(customerId)))
        .write(CustomersCompanion(openingBalancePaisa: Value(amountPaisa)));

    await audit.logUpdate(
      tableName: 'customers',
      rowId: customerId,
      oldValues: {'opening_balance_paisa': oldValue},
      newValues: {'opening_balance_paisa': newValue},
      userNote: 'Customer opening balance updated',
    );
  }

  // Driver Opening Balances (stored as driver_transaction type 'opening_balance')
  static const _driverOpeningBalanceType = 'opening_balance';

  Future<int> getDriverOpeningBalance(int driverId) async {
    final result = await (db.select(db.driverTransactions)
          ..where((t) =>
              t.driverId.equals(driverId) &
              t.deletedAt.isNull() &
              t.type.equals(_driverOpeningBalanceType)))
        .get();

    return result.fold<int>(0, (sum, t) => sum + t.amountPaisa);
  }

  Future<void> setDriverOpeningBalance(int driverId, int amountPaisa) async {
    // Check if opening balance already exists
    final existing = await (db.select(db.driverTransactions)
          ..where((t) =>
              t.driverId.equals(driverId) &
              t.deletedAt.isNull() &
              t.type.equals(_driverOpeningBalanceType)))
        .getSingleOrNull();

    if (existing != null) {
      // Update existing
      final oldValue = existing.amountPaisa.toString();
      final newValue = amountPaisa.toString();

      await (db.update(db.driverTransactions)..where((t) => t.id.equals(existing.id)))
          .write(DriverTransactionsCompanion(amountPaisa: Value(amountPaisa)));

      await audit.logUpdate(
        tableName: 'driver_transactions',
        rowId: existing.id,
        oldValues: {'amount_paisa': oldValue},
        newValues: {'amount_paisa': newValue},
        userNote: 'Driver opening balance updated',
      );
    } else if (amountPaisa != 0) {
      // Insert new
      await db.into(db.driverTransactions).insert(
        DriverTransactionsCompanion(
          driverId: Value(driverId),
          type: const Value(_driverOpeningBalanceType),
          amountPaisa: Value(amountPaisa),
          transactionDate: Value(DateTime.now()),
          note: const Value('Driver opening balance'),
        ),
      );
    }
  }

  // Get all opening balances for display
  Future<Map<String, dynamic>> getAllOpeningBalances() async {
    final cash = await getOpeningCash();

    final customers = await (db.select(db.customers)
          ..where((t) => t.deletedAt.isNull() & t.openingBalancePaisa.isBiggerThanValue(0)))
        .get();

    final drivers = await (db.select(db.drivers)
          ..where((t) => t.deletedAt.isNull()))
        .get();

    final driverBalances = <int, int>{};
    for (final driver in drivers) {
      final balance = await getDriverOpeningBalance(driver.id);
      if (balance != 0) {
        driverBalances[driver.id] = balance;
      }
    }

    return {
      'cash': cash,
      'customers': {for (var c in customers) c.id: c.openingBalancePaisa},
      'drivers': driverBalances,
    };
  }
}