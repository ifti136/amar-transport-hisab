import 'package:drift/drift.dart';

mixin SoftDeleteMixin on Table {
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
