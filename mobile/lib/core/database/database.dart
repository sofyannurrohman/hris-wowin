import 'package:drift/drift.dart';
import './connection/connection_stub.dart'
    if (dart.library.io) './connection/native_connection.dart'
    if (dart.library.html) './connection/web_connection.dart'
    if (dart.library.js_interop) './connection/web_connection.dart';

part 'database.g.dart';

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text()();
  TextColumn get name => text()();
  TextColumn get sku => text().nullable()();
  RealColumn get sellingPrice => real()();
  TextColumn get unit => text().nullable()();
  TextColumn get category => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

class Companies extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get code => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

class LocalCheckins extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get storeId => text()();
  TextColumn get storeName => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get selfiePath => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
}

class LocalTransactions extends Table {
  TextColumn get localId => text()(); // UUID v4
  TextColumn get receiptNo => text().nullable()(); // Official invoice ID from backend
  TextColumn get companyId => text()();
  TextColumn get companyName => text()();
  TextColumn get storeId => text()();
  TextColumn get storeName => text()();
  RealColumn get totalAmount => real()();
  TextColumn get selfiePath => text().nullable()();
  TextColumn get receiptPath => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  
  @override
  Set<Column> get primaryKey => {localId};
}

class LocalTransactionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transactionLocalId => text().references(LocalTransactions, #localId)();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  IntColumn get quantity => integer()();
  RealColumn get price => real()();
}


@DriftDatabase(tables: [Products, Companies, LocalCheckins, LocalTransactions, LocalTransactionItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(constructDb());

  @override
  int get schemaVersion => 1;
}
