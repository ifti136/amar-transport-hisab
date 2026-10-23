import 'package:drift/drift.dart';
import '../database.dart';
import 'package:transport_hisab/core/audit/audit_log.dart';

abstract class BaseDao<T, C extends Insertable> {
  final AppDatabase db;
  final AuditService audit;
  final String tableName;

  BaseDao(this.db, this.audit, {required this.tableName});

  // Insert with audit logging
  Future<int> insertWithAudit(C companion, {String? userNote}) async {
    final id = await db.into(table).insert(companion);
    final newValues = _companionToMap(companion);
    await audit.logInsert(
      tableName: tableName,
      rowId: id,
      newValues: newValues,
      userNote: userNote,
    );
    return id;
  }

  // Update with audit logging
  Future<bool> updateWithAudit(
    C companion, {
    required int id,
    String? userNote,
  }) async {
    final oldRow = await getById(id);
    if (oldRow == null) return false;

    final oldValues = _rowToMap(oldRow);
    await (db.update(table)..where((t) => (t as dynamic).id.equals(id))).write(companion);
    final newValues = _companionToMap(companion);
    await audit.logUpdate(
      tableName: tableName,
      rowId: id,
      oldValues: oldValues,
      newValues: newValues,
      userNote: userNote,
    );
    return true;
  }

  // Soft delete with audit logging
  Future<bool> softDeleteWithAudit(int id, {String? userNote}) async {
    final oldRow = await getById(id);
    if (oldRow == null) return false;

    await db.customUpdate(
      'UPDATE $tableName SET deleted_at = ? WHERE id = ?',
      variables: [Variable.withDateTime(DateTime.now()), Variable.withInt(id)],
      updates: {table},
    );
    await audit.logSoftDelete(
      tableName: tableName,
      rowId: id,
      userNote: userNote,
    );
    return true;
  }

  // Hard delete with audit logging (use with caution)
  Future<bool> hardDeleteWithAudit(int id, {String? userNote}) async {
    final oldRow = await getById(id);
    if (oldRow == null) return false;

    final oldValues = _rowToMap(oldRow);
    await db.customUpdate(
      'DELETE FROM $tableName WHERE id = ?',
      variables: [Variable.withInt(id)],
      updates: {table},
    );
    await audit.logDelete(
      tableName: tableName,
      rowId: id,
      oldValues: oldValues,
      userNote: userNote,
    );
    return true;
  }

  // Get by ID (excludes soft-deleted by default)
  Future<dynamic> getById(int id) async {
    return (db.select(table)..where((t) => (t as dynamic).id.equals(id) & (t as dynamic).deletedAt.isNull())).getSingleOrNull();
  }

  // Get by ID including soft-deleted
  Future<dynamic> getByIdIncludingDeleted(int id) async {
    return (db.select(table)..where((t) => (t as dynamic).id.equals(id))).getSingleOrNull();
  }

  // Watch all active rows
  Stream<List<dynamic>> watchAll() {
    return (db.select(table)..where((t) => (t as dynamic).deletedAt.isNull())).watch();
  }

  // Get all active rows
  Future<List<dynamic>> getAll() async {
    return (db.select(table)..where((t) => (t as dynamic).deletedAt.isNull())).get();
  }

  // Abstract getters to be implemented by subclasses
  TableInfo get table;

  // Helper methods to be implemented by subclasses
  Map<String, dynamic> _companionToMap(C companion);
  Map<String, dynamic> _rowToMap(dynamic row);
}
