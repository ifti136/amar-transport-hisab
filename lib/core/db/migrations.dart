import 'package:drift/drift.dart';

/// Runs all migrations from [from] to [to].
Future<void> runMigrations(Migrator m, int from, int to) async {
  for (int i = from + 1; i <= to; i++) {
    switch (i) {
      case 1:
        await _migrationV1(m);
        break;
      default:
        throw Exception('No migration for version $i');
    }
  }
}

/// Migration v1: Initial schema with all 12 tables, indexes, and foreign keys.
Future<void> _migrationV1(Migrator m) async {
  // All tables are created via m.createAll() in onCreate
  // This migration is a placeholder for future schema changes
}