import 'package:drift/drift.dart';
import '../db/database.dart';
import '../db/tables/audit_log.dart';

class AuditService {
  final AppDatabase db;

  AuditService(this.db);

  Future<void> logInsert({
    required String tableName,
    required int rowId,
    required Map<String, dynamic> newValues,
    String? userNote,
  }) async {
    for (final entry in newValues.entries) {
      await db.into(db.auditLog).insert(
        AuditLogCompanion.insert(
          targetTable: tableName,
          rowId: rowId,
          fieldName: entry.key,
          oldValue: const Value.absent(),
          newValue: Value(entry.value.toString()),
          action: 'insert',
          userNote: Value(userNote),
        ),
      );
    }
  }

  Future<void> logUpdate({
    required String tableName,
    required int rowId,
    required Map<String, dynamic> oldValues,
    required Map<String, dynamic> newValues,
    String? userNote,
  }) async {
    final allKeys = <String>{...oldValues.keys, ...newValues.keys};
    for (final key in allKeys) {
      final oldVal = oldValues[key];
      final newVal = newValues[key];
      if (oldVal != newVal) {
        await db.into(db.auditLog).insert(
          AuditLogCompanion.insert(
            targetTable: tableName,
            rowId: rowId,
            fieldName: key,
            oldValue: Value(oldVal?.toString()),
            newValue: Value(newVal?.toString()),
            action: 'update',
            userNote: Value(userNote),
          ),
        );
      }
    }
  }

  Future<void> logDelete({
    required String tableName,
    required int rowId,
    required Map<String, dynamic> oldValues,
    String? userNote,
  }) async {
    for (final entry in oldValues.entries) {
      await db.into(db.auditLog).insert(
        AuditLogCompanion.insert(
          targetTable: tableName,
          rowId: rowId,
          fieldName: entry.key,
          oldValue: Value(entry.value.toString()),
          newValue: const Value.absent(),
          action: 'delete',
          userNote: Value(userNote),
        ),
      );
    }
  }

  Future<void> logSoftDelete({
    required String tableName,
    required int rowId,
    String? userNote,
  }) async {
    await db.into(db.auditLog).insert(
      AuditLogCompanion.insert(
        targetTable: tableName,
        rowId: rowId,
        fieldName: 'deletedAt',
        oldValue: const Value.absent(),
        newValue: Value(DateTime.now().toIso8601String()),
        action: 'soft_delete',
        userNote: Value(userNote),
      ),
    );
  }

  Future<List<AuditLogData>> getAuditLog({
    required String tableName,
    required int rowId,
  }) async {
    return (db.select(db.auditLog)
          ..where((t) => t.targetTable.equals(tableName) & t.rowId.equals(rowId))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .get();
  }
}