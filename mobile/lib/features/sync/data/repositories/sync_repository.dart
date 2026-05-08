import 'package:drift/drift.dart';
import 'package:hris_app/core/database/database.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:dio/dio.dart';

class SyncRepository {
  final AppDatabase db;
  final ApiClient api;

  SyncRepository({required this.db, required this.api});

  Future<void> syncAll() async {
    print('DEBUG SYNC: syncAll() started');
    // Run both in parallel so one doesn't block the other
    syncCheckins().catchError((e) => print('DEBUG SYNC: syncCheckins error: $e'));
    syncTransactions().catchError((e) => print('DEBUG SYNC: syncTransactions error: $e'));
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
    print('DEBUG SYNC: Checking for pending transactions...');
    
    // Debug: count total items in table regardless of status
    final allCount = await db.select(db.localTransactions).get();
    print('DEBUG SYNC: Total transactions in local DB: ${allCount.length}');
    for (var t in allCount) {
      print('DEBUG SYNC: ID: ${t.localId.substring(0,8)}, Status: ${t.syncStatus}, Store: ${t.storeName}');
    }

    final pending = await (db.select(db.localTransactions)
      ..where((t) => t.syncStatus.equals('pending'))).get();

    if (pending.isEmpty) {
      print('DEBUG SYNC: No pending transactions found.');
      return;
    }
    print('DEBUG SYNC: Found ${pending.length} pending transactions to sync');

    for (final tr in pending) {
      try {
        final items = await (db.select(db.localTransactionItems)
          ..where((t) => t.transactionLocalId.equals(tr.localId))).get();

        // Filter items to ensure they have a valid product ID
        final validItems = items.where((i) => i.productId.isNotEmpty && i.productId != '00000000-0000-0000-0000-000000000000').map((i) => {
          'product_id': i.productId,
          'quantity': i.quantity,
          'price': i.price,
        }).toList();

        if (validItems.isEmpty) {
          print('DEBUG SYNC: Skipping transaction ${tr.localId} because it has no valid items');
          continue;
        }

        final payload = {
          'company_id': tr.companyId,
          'store_id': tr.storeId,
          'total_amount': tr.totalAmount,
          'paid_amount': tr.paymentMethod == 'CASH' ? tr.totalAmount : 0.0,
          'payment_method': tr.paymentMethod,
          'bank': tr.paymentBank,
          'notes': tr.notes,
          'store_category': 'RETAIL',
          'transaction_date': tr.createdAt.toUtc().toIso8601String(),
          'items': validItems,
        };

        print('DEBUG SYNC PAYLOAD: ${payload}');
        final response = await api.client.post('sales/transactions', data: payload);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data is Map && response.data.containsKey('data') ? response.data['data'] : response.data;
          final officialNo = data['receipt_no'];

          await (db.update(db.localTransactions)..where((t) => t.localId.equals(tr.localId)))
              .write(LocalTransactionsCompanion(
                syncStatus: const Value('synced'),
                receiptNo: Value(officialNo),
                midtransId: Value(data['midtrans_id']?.toString()),
                midtransQrisUrl: Value(data['midtrans_qris_url']?.toString()),
                midtransVaNumber: Value(data['midtrans_va_number']?.toString()),
                midtransBank: Value(data['midtrans_bank']?.toString()),
                midtransBillKey: Value(data['midtrans_bill_key']?.toString()),
                midtransBillerCode: Value(data['midtrans_biller_code']?.toString()),
              ));
          print('DEBUG SYNC: Successfully synced ${tr.localId} -> $officialNo');
        } else {
          print('DEBUG SYNC: Server returned status ${response.statusCode}: ${response.data}');
        }
      } catch (e) {
        print('DEBUG SYNC: Failed to sync transaction ${tr.localId}: $e');
        if (e is DioException) {
          print('DEBUG SYNC ERROR DATA: ${e.response?.data}');
          print('DEBUG SYNC REQUEST PATH: ${e.requestOptions.path}');
        }
      }
    }
  }

  Future<void> pullMasterData() async {
    // 1. Pull Companies
    try {
      final compRes = await api.client.get('companies');
      List? companies;
      if (compRes.data is Map && compRes.data.containsKey('data')) {
        companies = compRes.data['data'] as List?;
      } else if (compRes.data is List) {
        companies = compRes.data as List?;
      }

      if (companies != null && companies.isNotEmpty) {
        await db.batch((batch) {
          batch.insertAll(db.companies, companies!.map((c) => CompaniesCompanion.insert(
            id: c['id'] ?? c['ID'] ?? '',
            name: c['name'] ?? c['Name'] ?? 'Unknown',
            code: Value(c['code'] ?? c['Code']),
          )), mode: InsertMode.insertOrReplace);
        });
        print('DEBUG: Synced ${companies.length} companies');
      }
    } catch (e) {
      print('DEBUG: pull companies error: $e');
    }

    // 2. Pull Products (Iterate through companies to be thorough)
    try {
      final companies = await db.select(db.companies).get();
      print('DEBUG: Found ${companies.length} companies in local DB to pull products for');
      
      if (companies.isEmpty) {
        print('DEBUG: No companies found in local DB. Cannot pull per-company products.');
      }

      for (final company in companies) {
        try {
          print('DEBUG: Pulling products for company ${company.name} (${company.id})');
          final prodRes = await api.client.get('factory/products', queryParameters: {'company_id': company.id});
          print('DEBUG: Product API response for ${company.name}: ${prodRes.statusCode}');
          
          List? products;
          if (prodRes.data is Map && prodRes.data.containsKey('data')) {
            products = prodRes.data['data'] as List?;
          } else if (prodRes.data is List) {
            products = prodRes.data as List?;
          }

          if (products != null && products.isNotEmpty) {
            await db.batch((batch) {
              batch.insertAll(db.products, products!.map((p) => ProductsCompanion.insert(
                id: p['id'] ?? p['ID'] ?? '',
                companyId: p['company_id'] ?? p['companyId'] ?? p['CompanyID'] ?? company.id,
                name: p['name'] ?? p['Name'] ?? 'Unknown',
                sellingPrice: (p['selling_price'] ?? p['sellingPrice'] ?? p['SellingPrice'] ?? 0 as num).toDouble(),
                sku: Value(p['sku'] ?? p['SKU']),
                unit: Value(p['unit'] ?? p['Unit']),
                category: Value(p['category'] ?? p['Category']),
              )), mode: InsertMode.insertOrReplace);
            });
            print('DEBUG: Successfully inserted ${products.length} products for company ${company.name}');
          } else {
            print('DEBUG: API returned 0 products for company ${company.name}');
          }
        } catch (e) {
          print('DEBUG: Error pulling products for company ${company.id}: $e');
        }
      }

      // Also try one pull without explicit company_id as fallback
      print('DEBUG: Trying fallback product pull (all companies)');
      final prodResFallback = await api.client.get('factory/products');
      print('DEBUG: Fallback Product API response: ${prodResFallback.statusCode}');
      
      List? productsFallback;
      if (prodResFallback.data is Map && prodResFallback.data.containsKey('data')) {
        productsFallback = prodResFallback.data['data'] as List?;
      } else if (prodResFallback.data is List) {
        productsFallback = prodResFallback.data as List?;
      }

      if (productsFallback != null && productsFallback.isNotEmpty) {
        await db.batch((batch) {
          batch.insertAll(db.products, productsFallback!.map((p) => ProductsCompanion.insert(
            id: p['id'] ?? p['ID'] ?? '',
            companyId: p['company_id'] ?? p['companyId'] ?? p['CompanyID'] ?? '',
            name: p['name'] ?? p['Name'] ?? 'Unknown',
            sellingPrice: (p['selling_price'] ?? p['sellingPrice'] ?? p['SellingPrice'] ?? 0 as num).toDouble(),
            sku: Value(p['sku'] ?? p['SKU']),
            unit: Value(p['unit'] ?? p['Unit']),
            category: Value(p['category'] ?? p['Category']),
          )), mode: InsertMode.insertOrReplace);
        });
        print('DEBUG: Synced ${productsFallback!.length} fallback products');
      }

      // 3. Pull Products from Warehouse Stock (Additional source)
      try {
        print('DEBUG: Pulling products from warehouse/stock');
        final whRes = await api.client.get('warehouse/stock');
        List? whStocks;
        if (whRes.data is Map && whRes.data.containsKey('data')) {
          whStocks = whRes.data['data'] as List?;
        } else if (whRes.data is List) {
          whStocks = whRes.data as List?;
        }

        if (whStocks != null && whStocks.isNotEmpty) {
          await db.batch((batch) {
            for (var item in whStocks!) {
              final p = item['product'] ?? item['Product'];
              if (p == null) continue;
              
              batch.insert(db.products, ProductsCompanion.insert(
                id: p['id'] ?? p['ID'] ?? '',
                companyId: p['company_id'] ?? p['companyId'] ?? p['CompanyID'] ?? '',
                name: p['name'] ?? p['Name'] ?? 'Unknown',
                sellingPrice: (p['selling_price'] ?? p['sellingPrice'] ?? p['SellingPrice'] ?? 0 as num).toDouble(),
                sku: Value(p['sku'] ?? p['SKU']),
                unit: Value(p['unit'] ?? p['Unit']),
                category: Value(p['category'] ?? p['Category']),
              ), mode: InsertMode.insertOrReplace);
            }
          });
          print('DEBUG: Synced ${whStocks.length} products from warehouse stock');
        }
      } catch (e) {
        print('DEBUG: Error pulling from warehouse/stock: $e');
      }

    } catch (e) {
      print('DEBUG: pull products main loop error: $e');
    }

    // 4. Pull Sales Stock (Bronjong)
    await pullSalesStock();
  }

  Future<void> pullSalesStock() async {
    try {
      // 1. Get Profile to find employee ID
      final profileRes = await api.client.get('employees/profile');
      final profileData = profileRes.data is Map && profileRes.data.containsKey('data') 
          ? profileRes.data['data'] 
          : profileRes.data;
      
      if (profileData == null) {
        print('DEBUG: Profile data is null, skipping sales stock sync');
        return;
      }

      final employeeId = profileData['id'] ?? profileData['ID'];
      if (employeeId == null) {
        print('DEBUG: Employee ID not found in profile');
        return;
      }

      // 2. Pull Sales Stock (Bronjong)
      final stockRes = await api.client.get('sales-transfers/stock/$employeeId');
      List? stocks;
      if (stockRes.data is Map && stockRes.data.containsKey('data')) {
        stocks = stockRes.data['data'] as List?;
      } else if (stockRes.data is List) {
        stocks = stockRes.data as List?;
      }

      if (stocks != null && stocks.isNotEmpty) {
        await db.batch((batch) {
          for (var s in stocks!) {
            // Insert stock
            batch.insert(db.salesStock, SalesStockCompanion.insert(
              productId: s['product_id'] ?? s['productId'] ?? s['ProductID'] ?? '',
              quantity: s['quantity'] ?? s['Quantity'] ?? 0,
              updatedAt: DateTime.now(),
            ), mode: InsertMode.insertOrReplace);
            
            // Insert nested product if available
            final p = s['product'] ?? s['Product'];
            if (p != null) {
              batch.insert(db.products, ProductsCompanion.insert(
                id: p['id'] ?? p['ID'] ?? '',
                companyId: p['company_id'] ?? p['companyId'] ?? p['CompanyID'] ?? '',
                name: p['name'] ?? p['Name'] ?? 'Unknown',
                sellingPrice: (p['selling_price'] ?? p['sellingPrice'] ?? p['SellingPrice'] ?? 0 as num).toDouble(),
                sku: Value(p['sku'] ?? p['SKU']),
                unit: Value(p['unit'] ?? p['Unit']),
                category: Value(p['category'] ?? p['Category']),
              ), mode: InsertMode.insertOrReplace);
            }
          }
        });
        print('DEBUG: Synced ${stocks.length} sales stocks and their products');
      } else {
        print('DEBUG: No sales stocks found for employee $employeeId');
      }
    } catch (e) {
      print('DEBUG: pullSalesStock error: $e');
    }
  }
}
