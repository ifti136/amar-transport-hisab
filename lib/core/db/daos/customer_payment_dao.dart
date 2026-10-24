import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/customer_payments.dart';
import 'package:transport_hisab/core/audit/audit_log.dart';
import 'base_dao.dart';

class CustomerPaymentDao extends BaseDao<CustomerPayments, CustomerPaymentsCompanion> {
  CustomerPaymentDao(super.db, super.audit) : super(tableName: 'customer_payments');

  @override
  TableInfo get table => db.customerPayments;

  @override
  Map<String, dynamic> companionToMap(CustomerPaymentsCompanion companion) {
    return {
      'trip_id': companion.tripId.valueOrNull,
      'customer_id': companion.customerId.valueOrNull,
      'amount_paisa': companion.amountPaisa.valueOrNull,
      'payment_date': companion.paymentDate.valueOrNull?.toIso8601String(),
      'note': companion.note.valueOrNull,
      'created_at': companion.createdAt.valueOrNull?.toIso8601String(),
      'updated_at': companion.updatedAt.valueOrNull?.toIso8601String(),
      'deleted_at': companion.deletedAt.valueOrNull?.toIso8601String(),
    };
  }

  @override
  Map<String, dynamic> rowToMap(dynamic row) {
    return {
      'id': row.id,
      'trip_id': row.tripId,
      'customer_id': row.customerId,
      'amount_paisa': row.amountPaisa,
      'payment_date': row.paymentDate.toIso8601String(),
      'note': row.note,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
      'deleted_at': row.deletedAt?.toIso8601String(),
    };
  }

  // Get payments for a trip
  Stream<List<CustomerPayment>> watchPaymentsForTrip(int tripId) {
    return (db.select(db.customerPayments)
          ..where((t) => t.tripId.equals(tripId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.paymentDate)]))
        .watch();
  }

  Future<List<CustomerPayment>> getPaymentsForTrip(int tripId) async {
    return (db.select(db.customerPayments)
          ..where((t) => t.tripId.equals(tripId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.paymentDate)]))
        .get();
  }

  // Get payments for a customer
  Stream<List<CustomerPayment>> watchPaymentsForCustomer(int customerId) {
    return (db.select(db.customerPayments)
          ..where((t) => t.customerId.equals(customerId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.paymentDate)]))
        .watch();
  }

  Future<List<CustomerPayment>> getPaymentsForCustomer(int customerId) async {
    return (db.select(db.customerPayments)
          ..where((t) => t.customerId.equals(customerId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.paymentDate)]))
        .get();
  }

  // Get total payments for a customer up to a date
  Future<int> getTotalPaymentsForCustomer(int customerId, DateTime upTo) async {
    final payments = await (db.select(db.customerPayments)
          ..where((t) =>
              t.customerId.equals(customerId) &
              t.deletedAt.isNull() &
              t.paymentDate.isSmallerOrEqualValue(upTo)))
        .get();
    return payments.fold<int>(0, (sum, p) => sum + p.amountPaisa);
  }

  // Get total payments for a trip
  Future<int> getTotalPaymentsForTrip(int tripId) async {
    final payments = await (db.select(db.customerPayments)
          ..where((t) => t.tripId.equals(tripId) & t.deletedAt.isNull()))
        .get();
    return payments.fold<int>(0, (sum, p) => sum + p.amountPaisa);
  }
}