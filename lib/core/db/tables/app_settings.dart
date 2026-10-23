import 'package:drift/drift.dart';

class AppSettings extends Table {
  TextColumn get key => text()(); // locale, opening_cash_paisa, theme_mode, app_lock_enabled, etc.
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}