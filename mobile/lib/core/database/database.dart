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
  TextColumn get paymentMethod => text().withDefault(const Constant('CASH'))(); // 'CASH', 'QRIS', 'TEMPO', 'VA'
  TextColumn get paymentBank => text().nullable()(); // 'bca', 'bni', 'bri'
  TextColumn get midtransId => text().nullable()();
  TextColumn get midtransQrisUrl => text().nullable()();
  TextColumn get midtransVaNumber => text().nullable()();
  TextColumn get midtransBank => text().nullable()();
  TextColumn get midtransBillKey => text().nullable()();
  TextColumn get midtransBillerCode => text().nullable()();
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

class SalesStock extends Table {
  TextColumn get productId => text()();
  IntColumn get quantity => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {productId};
}

@DriftDatabase(tables: [Products, Companies, LocalCheckins, LocalTransactions, LocalTransactionItems, SalesStock])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(constructDb());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Add Midtrans columns
        await m.addColumn(localTransactions, localTransactions.midtransId);
        await m.addColumn(localTransactions, localTransactions.midtransQrisUrl);
        await m.addColumn(localTransactions, localTransactions.midtransVaNumber);
        await m.addColumn(localTransactions, localTransactions.midtransBank);
        await m.addColumn(localTransactions, localTransactions.midtransBillKey);
        await m.addColumn(localTransactions, localTransactions.midtransBillerCode);
      }
    },
  );
}
