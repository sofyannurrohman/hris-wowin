import 'package:drift/drift.dart';
import 'package:hris_app/core/database/database.dart';
import 'package:hris_app/core/network/api_client.dart';

class SyncRepository {
  final AppDatabase db;
  final ApiClient api;

  SyncRepository({required this.db, required this.api});

  Future<void> syncAll() async {
    await syncCheckins();
    await syncTransactions();
  }

  Future<void> syncCheckins() async {
    final pending = await (db.select(db.localCheckins)
      ..where((t) => t.syncStatus.equals('pending'))).get();

    for (final item in pending) {
      try {
        await api.client.post('sales/attendance', data: {
          'store_id': item.storeId,
          'latitude': item.latitude,
          'longitude': item.longitude,
          'selfie_url': item.selfiePath,
          'type': 'CHECKIN',
          'check_time': item.createdAt.toIso8601String(),
        });
        
        await (db.update(db.localCheckins)..where((t) => t.id.equals(item.id)))
            .write(LocalCheckinsCompanion(syncStatus: const Value('synced')));
      } catch (e) {
        // Silently fail for individual items
      }
    }
  }

  Future<void> syncTransactions() async {
    final pending = await (db.select(db.localTransactions)
      ..where((t) => t.syncStatus.equals('pending'))).get();

    for (final tr in pending) {
      try {
        final items = await (db.select(db.localTransactionItems)
          ..where((t) => t.transactionLocalId.equals(tr.localId))).get();

        final response = await api.client.post('sales/transactions', data: {
          'company_id': tr.companyId,
          'store_id': tr.storeId,
          'total_amount': tr.totalAmount,
          'payment_method': tr.paymentMethod,
          'bank': tr.paymentBank,
          'notes': tr.notes,
          'transaction_date': tr.createdAt.toIso8601String(),
          'items': items.map((i) => {
            'product_id': i.productId,
            'quantity': i.quantity,
            'price': i.price,
          }).toList(),
        });

        final officialNo = response.data['receipt_no'];

        await (db.update(db.localTransactions)..where((t) => t.localId.equals(tr.localId)))
            .write(LocalTransactionsCompanion(
              syncStatus: const Value('synced'),
              receiptNo: Value(officialNo),
            ));
      } catch (e) {
        // Silently fail
      }
    }
  }

  Future<void> pullMasterData() async {
    // 1. Pull Companies
    final compRes = await api.client.get('companies');
    final companies = compRes.data as List;
    await db.batch((batch) {
      batch.insertAll(db.companies, companies.map((c) => CompaniesCompanion.insert(
        id: c['id'],
        name: c['name'],
        code: Value(c['code']),
      )), mode: InsertMode.insertOrReplace);
    });

    // 2. Pull Products
    final prodRes = await api.client.get('factory/products');
    final products = prodRes.data as List;
    await db.batch((batch) {
      batch.insertAll(db.products, products.map((p) => ProductsCompanion.insert(
        id: p['id'],
        companyId: p['company_id'],
        name: p['name'],
        sellingPrice: (p['selling_price'] as num).toDouble(),
        sku: Value(p['sku']),
        unit: Value(p['unit']),
        category: Value(p['category']),
      )), mode: InsertMode.insertOrReplace);
    });
  }
}
