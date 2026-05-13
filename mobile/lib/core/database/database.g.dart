// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _companyIdMeta =
      const VerificationMeta('companyId');
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
      'company_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
      'sku', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sellingPriceMeta =
      const VerificationMeta('sellingPrice');
  @override
  late final GeneratedColumn<double> sellingPrice = GeneratedColumn<double>(
      'selling_price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _warehouseStockMeta =
      const VerificationMeta('warehouseStock');
  @override
  late final GeneratedColumn<int> warehouseStock = GeneratedColumn<int>(
      'warehouse_stock', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _pcsPerUnitMeta =
      const VerificationMeta('pcsPerUnit');
  @override
  late final GeneratedColumn<int> pcsPerUnit = GeneratedColumn<int>(
      'pcs_per_unit', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        companyId,
        name,
        sku,
        sellingPrice,
        unit,
        category,
        warehouseStock,
        pcsPerUnit,
        imageUrl
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(Insertable<Product> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(_companyIdMeta,
          companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta));
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
          _skuMeta, sku.isAcceptableOrUnknown(data['sku']!, _skuMeta));
    }
    if (data.containsKey('selling_price')) {
      context.handle(
          _sellingPriceMeta,
          sellingPrice.isAcceptableOrUnknown(
              data['selling_price']!, _sellingPriceMeta));
    } else if (isInserting) {
      context.missing(_sellingPriceMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('warehouse_stock')) {
      context.handle(
          _warehouseStockMeta,
          warehouseStock.isAcceptableOrUnknown(
              data['warehouse_stock']!, _warehouseStockMeta));
    }
    if (data.containsKey('pcs_per_unit')) {
      context.handle(
          _pcsPerUnitMeta,
          pcsPerUnit.isAcceptableOrUnknown(
              data['pcs_per_unit']!, _pcsPerUnitMeta));
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      companyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sku: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sku']),
      sellingPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}selling_price'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      warehouseStock: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}warehouse_stock'])!,
      pcsPerUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pcs_per_unit'])!,
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url']),
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final String companyId;
  final String name;
  final String? sku;
  final double sellingPrice;
  final String? unit;
  final String? category;
  final int warehouseStock;
  final int pcsPerUnit;
  final String? imageUrl;
  const Product(
      {required this.id,
      required this.companyId,
      required this.name,
      this.sku,
      required this.sellingPrice,
      this.unit,
      this.category,
      required this.warehouseStock,
      required this.pcsPerUnit,
      this.imageUrl});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['company_id'] = Variable<String>(companyId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    map['selling_price'] = Variable<double>(sellingPrice);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['warehouse_stock'] = Variable<int>(warehouseStock);
    map['pcs_per_unit'] = Variable<int>(pcsPerUnit);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      companyId: Value(companyId),
      name: Value(name),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      sellingPrice: Value(sellingPrice),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      warehouseStock: Value(warehouseStock),
      pcsPerUnit: Value(pcsPerUnit),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
    );
  }

  factory Product.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      companyId: serializer.fromJson<String>(json['companyId']),
      name: serializer.fromJson<String>(json['name']),
      sku: serializer.fromJson<String?>(json['sku']),
      sellingPrice: serializer.fromJson<double>(json['sellingPrice']),
      unit: serializer.fromJson<String?>(json['unit']),
      category: serializer.fromJson<String?>(json['category']),
      warehouseStock: serializer.fromJson<int>(json['warehouseStock']),
      pcsPerUnit: serializer.fromJson<int>(json['pcsPerUnit']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'companyId': serializer.toJson<String>(companyId),
      'name': serializer.toJson<String>(name),
      'sku': serializer.toJson<String?>(sku),
      'sellingPrice': serializer.toJson<double>(sellingPrice),
      'unit': serializer.toJson<String?>(unit),
      'category': serializer.toJson<String?>(category),
      'warehouseStock': serializer.toJson<int>(warehouseStock),
      'pcsPerUnit': serializer.toJson<int>(pcsPerUnit),
      'imageUrl': serializer.toJson<String?>(imageUrl),
    };
  }

  Product copyWith(
          {String? id,
          String? companyId,
          String? name,
          Value<String?> sku = const Value.absent(),
          double? sellingPrice,
          Value<String?> unit = const Value.absent(),
          Value<String?> category = const Value.absent(),
          int? warehouseStock,
          int? pcsPerUnit,
          Value<String?> imageUrl = const Value.absent()}) =>
      Product(
        id: id ?? this.id,
        companyId: companyId ?? this.companyId,
        name: name ?? this.name,
        sku: sku.present ? sku.value : this.sku,
        sellingPrice: sellingPrice ?? this.sellingPrice,
        unit: unit.present ? unit.value : this.unit,
        category: category.present ? category.value : this.category,
        warehouseStock: warehouseStock ?? this.warehouseStock,
        pcsPerUnit: pcsPerUnit ?? this.pcsPerUnit,
        imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
      );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      name: data.name.present ? data.name.value : this.name,
      sku: data.sku.present ? data.sku.value : this.sku,
      sellingPrice: data.sellingPrice.present
          ? data.sellingPrice.value
          : this.sellingPrice,
      unit: data.unit.present ? data.unit.value : this.unit,
      category: data.category.present ? data.category.value : this.category,
      warehouseStock: data.warehouseStock.present
          ? data.warehouseStock.value
          : this.warehouseStock,
      pcsPerUnit:
          data.pcsPerUnit.present ? data.pcsPerUnit.value : this.pcsPerUnit,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('unit: $unit, ')
          ..write('category: $category, ')
          ..write('warehouseStock: $warehouseStock, ')
          ..write('pcsPerUnit: $pcsPerUnit, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, companyId, name, sku, sellingPrice, unit,
      category, warehouseStock, pcsPerUnit, imageUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.companyId == this.companyId &&
          other.name == this.name &&
          other.sku == this.sku &&
          other.sellingPrice == this.sellingPrice &&
          other.unit == this.unit &&
          other.category == this.category &&
          other.warehouseStock == this.warehouseStock &&
          other.pcsPerUnit == this.pcsPerUnit &&
          other.imageUrl == this.imageUrl);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String> companyId;
  final Value<String> name;
  final Value<String?> sku;
  final Value<double> sellingPrice;
  final Value<String?> unit;
  final Value<String?> category;
  final Value<int> warehouseStock;
  final Value<int> pcsPerUnit;
  final Value<String?> imageUrl;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.companyId = const Value.absent(),
    this.name = const Value.absent(),
    this.sku = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.unit = const Value.absent(),
    this.category = const Value.absent(),
    this.warehouseStock = const Value.absent(),
    this.pcsPerUnit = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String companyId,
    required String name,
    this.sku = const Value.absent(),
    required double sellingPrice,
    this.unit = const Value.absent(),
    this.category = const Value.absent(),
    this.warehouseStock = const Value.absent(),
    this.pcsPerUnit = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        companyId = Value(companyId),
        name = Value(name),
        sellingPrice = Value(sellingPrice);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? companyId,
    Expression<String>? name,
    Expression<String>? sku,
    Expression<double>? sellingPrice,
    Expression<String>? unit,
    Expression<String>? category,
    Expression<int>? warehouseStock,
    Expression<int>? pcsPerUnit,
    Expression<String>? imageUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (name != null) 'name': name,
      if (sku != null) 'sku': sku,
      if (sellingPrice != null) 'selling_price': sellingPrice,
      if (unit != null) 'unit': unit,
      if (category != null) 'category': category,
      if (warehouseStock != null) 'warehouse_stock': warehouseStock,
      if (pcsPerUnit != null) 'pcs_per_unit': pcsPerUnit,
      if (imageUrl != null) 'image_url': imageUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith(
      {Value<String>? id,
      Value<String>? companyId,
      Value<String>? name,
      Value<String?>? sku,
      Value<double>? sellingPrice,
      Value<String?>? unit,
      Value<String?>? category,
      Value<int>? warehouseStock,
      Value<int>? pcsPerUnit,
      Value<String?>? imageUrl,
      Value<int>? rowid}) {
    return ProductsCompanion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      warehouseStock: warehouseStock ?? this.warehouseStock,
      pcsPerUnit: pcsPerUnit ?? this.pcsPerUnit,
      imageUrl: imageUrl ?? this.imageUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (sellingPrice.present) {
      map['selling_price'] = Variable<double>(sellingPrice.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (warehouseStock.present) {
      map['warehouse_stock'] = Variable<int>(warehouseStock.value);
    }
    if (pcsPerUnit.present) {
      map['pcs_per_unit'] = Variable<int>(pcsPerUnit.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('unit: $unit, ')
          ..write('category: $category, ')
          ..write('warehouseStock: $warehouseStock, ')
          ..write('pcsPerUnit: $pcsPerUnit, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompaniesTable extends Companies
    with TableInfo<$CompaniesTable, Company> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompaniesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, name, code];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'companies';
  @override
  VerificationContext validateIntegrity(Insertable<Company> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Company map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Company(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code']),
    );
  }

  @override
  $CompaniesTable createAlias(String alias) {
    return $CompaniesTable(attachedDatabase, alias);
  }
}

class Company extends DataClass implements Insertable<Company> {
  final String id;
  final String name;
  final String? code;
  const Company({required this.id, required this.name, this.code});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    return map;
  }

  CompaniesCompanion toCompanion(bool nullToAbsent) {
    return CompaniesCompanion(
      id: Value(id),
      name: Value(name),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
    );
  }

  factory Company.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Company(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String?>(json['code']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String?>(code),
    };
  }

  Company copyWith(
          {String? id,
          String? name,
          Value<String?> code = const Value.absent()}) =>
      Company(
        id: id ?? this.id,
        name: name ?? this.name,
        code: code.present ? code.value : this.code,
      );
  Company copyWithCompanion(CompaniesCompanion data) {
    return Company(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Company(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('code: $code')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, code);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Company &&
          other.id == this.id &&
          other.name == this.name &&
          other.code == this.code);
}

class CompaniesCompanion extends UpdateCompanion<Company> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> code;
  final Value<int> rowid;
  const CompaniesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompaniesCompanion.insert({
    required String id,
    required String name,
    this.code = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<Company> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? code,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompaniesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? code,
      Value<int>? rowid}) {
    return CompaniesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompaniesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCheckinsTable extends LocalCheckins
    with TableInfo<$LocalCheckinsTable, LocalCheckin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCheckinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _storeIdMeta =
      const VerificationMeta('storeId');
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
      'store_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _storeNameMeta =
      const VerificationMeta('storeName');
  @override
  late final GeneratedColumn<String> storeName = GeneratedColumn<String>(
      'store_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _selfiePathMeta =
      const VerificationMeta('selfiePath');
  @override
  late final GeneratedColumn<String> selfiePath = GeneratedColumn<String>(
      'selfie_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        storeId,
        storeName,
        latitude,
        longitude,
        selfiePath,
        createdAt,
        syncStatus
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_checkins';
  @override
  VerificationContext validateIntegrity(Insertable<LocalCheckin> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('store_id')) {
      context.handle(_storeIdMeta,
          storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta));
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('store_name')) {
      context.handle(_storeNameMeta,
          storeName.isAcceptableOrUnknown(data['store_name']!, _storeNameMeta));
    } else if (isInserting) {
      context.missing(_storeNameMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('selfie_path')) {
      context.handle(
          _selfiePathMeta,
          selfiePath.isAcceptableOrUnknown(
              data['selfie_path']!, _selfiePathMeta));
    } else if (isInserting) {
      context.missing(_selfiePathMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCheckin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCheckin(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      storeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}store_id'])!,
      storeName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}store_name'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      selfiePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}selfie_path'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $LocalCheckinsTable createAlias(String alias) {
    return $LocalCheckinsTable(attachedDatabase, alias);
  }
}

class LocalCheckin extends DataClass implements Insertable<LocalCheckin> {
  final int id;
  final String storeId;
  final String storeName;
  final double latitude;
  final double longitude;
  final String selfiePath;
  final DateTime createdAt;
  final String syncStatus;
  const LocalCheckin(
      {required this.id,
      required this.storeId,
      required this.storeName,
      required this.latitude,
      required this.longitude,
      required this.selfiePath,
      required this.createdAt,
      required this.syncStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['store_id'] = Variable<String>(storeId);
    map['store_name'] = Variable<String>(storeName);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['selfie_path'] = Variable<String>(selfiePath);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  LocalCheckinsCompanion toCompanion(bool nullToAbsent) {
    return LocalCheckinsCompanion(
      id: Value(id),
      storeId: Value(storeId),
      storeName: Value(storeName),
      latitude: Value(latitude),
      longitude: Value(longitude),
      selfiePath: Value(selfiePath),
      createdAt: Value(createdAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory LocalCheckin.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCheckin(
      id: serializer.fromJson<int>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      storeName: serializer.fromJson<String>(json['storeName']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      selfiePath: serializer.fromJson<String>(json['selfiePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'storeId': serializer.toJson<String>(storeId),
      'storeName': serializer.toJson<String>(storeName),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'selfiePath': serializer.toJson<String>(selfiePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  LocalCheckin copyWith(
          {int? id,
          String? storeId,
          String? storeName,
          double? latitude,
          double? longitude,
          String? selfiePath,
          DateTime? createdAt,
          String? syncStatus}) =>
      LocalCheckin(
        id: id ?? this.id,
        storeId: storeId ?? this.storeId,
        storeName: storeName ?? this.storeName,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        selfiePath: selfiePath ?? this.selfiePath,
        createdAt: createdAt ?? this.createdAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );
  LocalCheckin copyWithCompanion(LocalCheckinsCompanion data) {
    return LocalCheckin(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      storeName: data.storeName.present ? data.storeName.value : this.storeName,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      selfiePath:
          data.selfiePath.present ? data.selfiePath.value : this.selfiePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCheckin(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('storeName: $storeName, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('selfiePath: $selfiePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, storeId, storeName, latitude, longitude,
      selfiePath, createdAt, syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCheckin &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.storeName == this.storeName &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.selfiePath == this.selfiePath &&
          other.createdAt == this.createdAt &&
          other.syncStatus == this.syncStatus);
}

class LocalCheckinsCompanion extends UpdateCompanion<LocalCheckin> {
  final Value<int> id;
  final Value<String> storeId;
  final Value<String> storeName;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String> selfiePath;
  final Value<DateTime> createdAt;
  final Value<String> syncStatus;
  const LocalCheckinsCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.storeName = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.selfiePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
  });
  LocalCheckinsCompanion.insert({
    this.id = const Value.absent(),
    required String storeId,
    required String storeName,
    required double latitude,
    required double longitude,
    required String selfiePath,
    required DateTime createdAt,
    this.syncStatus = const Value.absent(),
  })  : storeId = Value(storeId),
        storeName = Value(storeName),
        latitude = Value(latitude),
        longitude = Value(longitude),
        selfiePath = Value(selfiePath),
        createdAt = Value(createdAt);
  static Insertable<LocalCheckin> custom({
    Expression<int>? id,
    Expression<String>? storeId,
    Expression<String>? storeName,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? selfiePath,
    Expression<DateTime>? createdAt,
    Expression<String>? syncStatus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (storeName != null) 'store_name': storeName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (selfiePath != null) 'selfie_path': selfiePath,
      if (createdAt != null) 'created_at': createdAt,
      if (syncStatus != null) 'sync_status': syncStatus,
    });
  }

  LocalCheckinsCompanion copyWith(
      {Value<int>? id,
      Value<String>? storeId,
      Value<String>? storeName,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<String>? selfiePath,
      Value<DateTime>? createdAt,
      Value<String>? syncStatus}) {
    return LocalCheckinsCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      selfiePath: selfiePath ?? this.selfiePath,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (storeName.present) {
      map['store_name'] = Variable<String>(storeName.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (selfiePath.present) {
      map['selfie_path'] = Variable<String>(selfiePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCheckinsCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('storeName: $storeName, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('selfiePath: $selfiePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }
}

class $LocalTransactionsTable extends LocalTransactions
    with TableInfo<$LocalTransactionsTable, LocalTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
      'local_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _receiptNoMeta =
      const VerificationMeta('receiptNo');
  @override
  late final GeneratedColumn<String> receiptNo = GeneratedColumn<String>(
      'receipt_no', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _companyIdMeta =
      const VerificationMeta('companyId');
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
      'company_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _companyNameMeta =
      const VerificationMeta('companyName');
  @override
  late final GeneratedColumn<String> companyName = GeneratedColumn<String>(
      'company_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _storeIdMeta =
      const VerificationMeta('storeId');
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
      'store_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _storeNameMeta =
      const VerificationMeta('storeName');
  @override
  late final GeneratedColumn<String> storeName = GeneratedColumn<String>(
      'store_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalAmountMeta =
      const VerificationMeta('totalAmount');
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
      'total_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _selfiePathMeta =
      const VerificationMeta('selfiePath');
  @override
  late final GeneratedColumn<String> selfiePath = GeneratedColumn<String>(
      'selfie_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _receiptPathMeta =
      const VerificationMeta('receiptPath');
  @override
  late final GeneratedColumn<String> receiptPath = GeneratedColumn<String>(
      'receipt_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('CASH'));
  static const VerificationMeta _paymentBankMeta =
      const VerificationMeta('paymentBank');
  @override
  late final GeneratedColumn<String> paymentBank = GeneratedColumn<String>(
      'payment_bank', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _midtransIdMeta =
      const VerificationMeta('midtransId');
  @override
  late final GeneratedColumn<String> midtransId = GeneratedColumn<String>(
      'midtrans_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _midtransQrisUrlMeta =
      const VerificationMeta('midtransQrisUrl');
  @override
  late final GeneratedColumn<String> midtransQrisUrl = GeneratedColumn<String>(
      'midtrans_qris_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _midtransVaNumberMeta =
      const VerificationMeta('midtransVaNumber');
  @override
  late final GeneratedColumn<String> midtransVaNumber = GeneratedColumn<String>(
      'midtrans_va_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _midtransBankMeta =
      const VerificationMeta('midtransBank');
  @override
  late final GeneratedColumn<String> midtransBank = GeneratedColumn<String>(
      'midtrans_bank', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _midtransBillKeyMeta =
      const VerificationMeta('midtransBillKey');
  @override
  late final GeneratedColumn<String> midtransBillKey = GeneratedColumn<String>(
      'midtrans_bill_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _midtransBillerCodeMeta =
      const VerificationMeta('midtransBillerCode');
  @override
  late final GeneratedColumn<String> midtransBillerCode =
      GeneratedColumn<String>('midtrans_biller_code', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        receiptNo,
        companyId,
        companyName,
        storeId,
        storeName,
        totalAmount,
        selfiePath,
        receiptPath,
        notes,
        paymentMethod,
        paymentBank,
        midtransId,
        midtransQrisUrl,
        midtransVaNumber,
        midtransBank,
        midtransBillKey,
        midtransBillerCode,
        createdAt,
        syncStatus
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_transactions';
  @override
  VerificationContext validateIntegrity(Insertable<LocalTransaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('receipt_no')) {
      context.handle(_receiptNoMeta,
          receiptNo.isAcceptableOrUnknown(data['receipt_no']!, _receiptNoMeta));
    }
    if (data.containsKey('company_id')) {
      context.handle(_companyIdMeta,
          companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta));
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('company_name')) {
      context.handle(
          _companyNameMeta,
          companyName.isAcceptableOrUnknown(
              data['company_name']!, _companyNameMeta));
    } else if (isInserting) {
      context.missing(_companyNameMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(_storeIdMeta,
          storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta));
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('store_name')) {
      context.handle(_storeNameMeta,
          storeName.isAcceptableOrUnknown(data['store_name']!, _storeNameMeta));
    } else if (isInserting) {
      context.missing(_storeNameMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
          _totalAmountMeta,
          totalAmount.isAcceptableOrUnknown(
              data['total_amount']!, _totalAmountMeta));
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('selfie_path')) {
      context.handle(
          _selfiePathMeta,
          selfiePath.isAcceptableOrUnknown(
              data['selfie_path']!, _selfiePathMeta));
    }
    if (data.containsKey('receipt_path')) {
      context.handle(
          _receiptPathMeta,
          receiptPath.isAcceptableOrUnknown(
              data['receipt_path']!, _receiptPathMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    }
    if (data.containsKey('payment_bank')) {
      context.handle(
          _paymentBankMeta,
          paymentBank.isAcceptableOrUnknown(
              data['payment_bank']!, _paymentBankMeta));
    }
    if (data.containsKey('midtrans_id')) {
      context.handle(
          _midtransIdMeta,
          midtransId.isAcceptableOrUnknown(
              data['midtrans_id']!, _midtransIdMeta));
    }
    if (data.containsKey('midtrans_qris_url')) {
      context.handle(
          _midtransQrisUrlMeta,
          midtransQrisUrl.isAcceptableOrUnknown(
              data['midtrans_qris_url']!, _midtransQrisUrlMeta));
    }
    if (data.containsKey('midtrans_va_number')) {
      context.handle(
          _midtransVaNumberMeta,
          midtransVaNumber.isAcceptableOrUnknown(
              data['midtrans_va_number']!, _midtransVaNumberMeta));
    }
    if (data.containsKey('midtrans_bank')) {
      context.handle(
          _midtransBankMeta,
          midtransBank.isAcceptableOrUnknown(
              data['midtrans_bank']!, _midtransBankMeta));
    }
    if (data.containsKey('midtrans_bill_key')) {
      context.handle(
          _midtransBillKeyMeta,
          midtransBillKey.isAcceptableOrUnknown(
              data['midtrans_bill_key']!, _midtransBillKeyMeta));
    }
    if (data.containsKey('midtrans_biller_code')) {
      context.handle(
          _midtransBillerCodeMeta,
          midtransBillerCode.isAcceptableOrUnknown(
              data['midtrans_biller_code']!, _midtransBillerCodeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  LocalTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTransaction(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_id'])!,
      receiptNo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receipt_no']),
      companyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company_id'])!,
      companyName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company_name'])!,
      storeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}store_id'])!,
      storeName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}store_name'])!,
      totalAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_amount'])!,
      selfiePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}selfie_path']),
      receiptPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receipt_path']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method'])!,
      paymentBank: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_bank']),
      midtransId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}midtrans_id']),
      midtransQrisUrl: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}midtrans_qris_url']),
      midtransVaNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}midtrans_va_number']),
      midtransBank: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}midtrans_bank']),
      midtransBillKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}midtrans_bill_key']),
      midtransBillerCode: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}midtrans_biller_code']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $LocalTransactionsTable createAlias(String alias) {
    return $LocalTransactionsTable(attachedDatabase, alias);
  }
}

class LocalTransaction extends DataClass
    implements Insertable<LocalTransaction> {
  final String localId;
  final String? receiptNo;
  final String companyId;
  final String companyName;
  final String storeId;
  final String storeName;
  final double totalAmount;
  final String? selfiePath;
  final String? receiptPath;
  final String? notes;
  final String paymentMethod;
  final String? paymentBank;
  final String? midtransId;
  final String? midtransQrisUrl;
  final String? midtransVaNumber;
  final String? midtransBank;
  final String? midtransBillKey;
  final String? midtransBillerCode;
  final DateTime createdAt;
  final String syncStatus;
  const LocalTransaction(
      {required this.localId,
      this.receiptNo,
      required this.companyId,
      required this.companyName,
      required this.storeId,
      required this.storeName,
      required this.totalAmount,
      this.selfiePath,
      this.receiptPath,
      this.notes,
      required this.paymentMethod,
      this.paymentBank,
      this.midtransId,
      this.midtransQrisUrl,
      this.midtransVaNumber,
      this.midtransBank,
      this.midtransBillKey,
      this.midtransBillerCode,
      required this.createdAt,
      required this.syncStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || receiptNo != null) {
      map['receipt_no'] = Variable<String>(receiptNo);
    }
    map['company_id'] = Variable<String>(companyId);
    map['company_name'] = Variable<String>(companyName);
    map['store_id'] = Variable<String>(storeId);
    map['store_name'] = Variable<String>(storeName);
    map['total_amount'] = Variable<double>(totalAmount);
    if (!nullToAbsent || selfiePath != null) {
      map['selfie_path'] = Variable<String>(selfiePath);
    }
    if (!nullToAbsent || receiptPath != null) {
      map['receipt_path'] = Variable<String>(receiptPath);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['payment_method'] = Variable<String>(paymentMethod);
    if (!nullToAbsent || paymentBank != null) {
      map['payment_bank'] = Variable<String>(paymentBank);
    }
    if (!nullToAbsent || midtransId != null) {
      map['midtrans_id'] = Variable<String>(midtransId);
    }
    if (!nullToAbsent || midtransQrisUrl != null) {
      map['midtrans_qris_url'] = Variable<String>(midtransQrisUrl);
    }
    if (!nullToAbsent || midtransVaNumber != null) {
      map['midtrans_va_number'] = Variable<String>(midtransVaNumber);
    }
    if (!nullToAbsent || midtransBank != null) {
      map['midtrans_bank'] = Variable<String>(midtransBank);
    }
    if (!nullToAbsent || midtransBillKey != null) {
      map['midtrans_bill_key'] = Variable<String>(midtransBillKey);
    }
    if (!nullToAbsent || midtransBillerCode != null) {
      map['midtrans_biller_code'] = Variable<String>(midtransBillerCode);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  LocalTransactionsCompanion toCompanion(bool nullToAbsent) {
    return LocalTransactionsCompanion(
      localId: Value(localId),
      receiptNo: receiptNo == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptNo),
      companyId: Value(companyId),
      companyName: Value(companyName),
      storeId: Value(storeId),
      storeName: Value(storeName),
      totalAmount: Value(totalAmount),
      selfiePath: selfiePath == null && nullToAbsent
          ? const Value.absent()
          : Value(selfiePath),
      receiptPath: receiptPath == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptPath),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      paymentMethod: Value(paymentMethod),
      paymentBank: paymentBank == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentBank),
      midtransId: midtransId == null && nullToAbsent
          ? const Value.absent()
          : Value(midtransId),
      midtransQrisUrl: midtransQrisUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(midtransQrisUrl),
      midtransVaNumber: midtransVaNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(midtransVaNumber),
      midtransBank: midtransBank == null && nullToAbsent
          ? const Value.absent()
          : Value(midtransBank),
      midtransBillKey: midtransBillKey == null && nullToAbsent
          ? const Value.absent()
          : Value(midtransBillKey),
      midtransBillerCode: midtransBillerCode == null && nullToAbsent
          ? const Value.absent()
          : Value(midtransBillerCode),
      createdAt: Value(createdAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory LocalTransaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTransaction(
      localId: serializer.fromJson<String>(json['localId']),
      receiptNo: serializer.fromJson<String?>(json['receiptNo']),
      companyId: serializer.fromJson<String>(json['companyId']),
      companyName: serializer.fromJson<String>(json['companyName']),
      storeId: serializer.fromJson<String>(json['storeId']),
      storeName: serializer.fromJson<String>(json['storeName']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      selfiePath: serializer.fromJson<String?>(json['selfiePath']),
      receiptPath: serializer.fromJson<String?>(json['receiptPath']),
      notes: serializer.fromJson<String?>(json['notes']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      paymentBank: serializer.fromJson<String?>(json['paymentBank']),
      midtransId: serializer.fromJson<String?>(json['midtransId']),
      midtransQrisUrl: serializer.fromJson<String?>(json['midtransQrisUrl']),
      midtransVaNumber: serializer.fromJson<String?>(json['midtransVaNumber']),
      midtransBank: serializer.fromJson<String?>(json['midtransBank']),
      midtransBillKey: serializer.fromJson<String?>(json['midtransBillKey']),
      midtransBillerCode:
          serializer.fromJson<String?>(json['midtransBillerCode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'receiptNo': serializer.toJson<String?>(receiptNo),
      'companyId': serializer.toJson<String>(companyId),
      'companyName': serializer.toJson<String>(companyName),
      'storeId': serializer.toJson<String>(storeId),
      'storeName': serializer.toJson<String>(storeName),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'selfiePath': serializer.toJson<String?>(selfiePath),
      'receiptPath': serializer.toJson<String?>(receiptPath),
      'notes': serializer.toJson<String?>(notes),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'paymentBank': serializer.toJson<String?>(paymentBank),
      'midtransId': serializer.toJson<String?>(midtransId),
      'midtransQrisUrl': serializer.toJson<String?>(midtransQrisUrl),
      'midtransVaNumber': serializer.toJson<String?>(midtransVaNumber),
      'midtransBank': serializer.toJson<String?>(midtransBank),
      'midtransBillKey': serializer.toJson<String?>(midtransBillKey),
      'midtransBillerCode': serializer.toJson<String?>(midtransBillerCode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  LocalTransaction copyWith(
          {String? localId,
          Value<String?> receiptNo = const Value.absent(),
          String? companyId,
          String? companyName,
          String? storeId,
          String? storeName,
          double? totalAmount,
          Value<String?> selfiePath = const Value.absent(),
          Value<String?> receiptPath = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          String? paymentMethod,
          Value<String?> paymentBank = const Value.absent(),
          Value<String?> midtransId = const Value.absent(),
          Value<String?> midtransQrisUrl = const Value.absent(),
          Value<String?> midtransVaNumber = const Value.absent(),
          Value<String?> midtransBank = const Value.absent(),
          Value<String?> midtransBillKey = const Value.absent(),
          Value<String?> midtransBillerCode = const Value.absent(),
          DateTime? createdAt,
          String? syncStatus}) =>
      LocalTransaction(
        localId: localId ?? this.localId,
        receiptNo: receiptNo.present ? receiptNo.value : this.receiptNo,
        companyId: companyId ?? this.companyId,
        companyName: companyName ?? this.companyName,
        storeId: storeId ?? this.storeId,
        storeName: storeName ?? this.storeName,
        totalAmount: totalAmount ?? this.totalAmount,
        selfiePath: selfiePath.present ? selfiePath.value : this.selfiePath,
        receiptPath: receiptPath.present ? receiptPath.value : this.receiptPath,
        notes: notes.present ? notes.value : this.notes,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        paymentBank: paymentBank.present ? paymentBank.value : this.paymentBank,
        midtransId: midtransId.present ? midtransId.value : this.midtransId,
        midtransQrisUrl: midtransQrisUrl.present
            ? midtransQrisUrl.value
            : this.midtransQrisUrl,
        midtransVaNumber: midtransVaNumber.present
            ? midtransVaNumber.value
            : this.midtransVaNumber,
        midtransBank:
            midtransBank.present ? midtransBank.value : this.midtransBank,
        midtransBillKey: midtransBillKey.present
            ? midtransBillKey.value
            : this.midtransBillKey,
        midtransBillerCode: midtransBillerCode.present
            ? midtransBillerCode.value
            : this.midtransBillerCode,
        createdAt: createdAt ?? this.createdAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );
  LocalTransaction copyWithCompanion(LocalTransactionsCompanion data) {
    return LocalTransaction(
      localId: data.localId.present ? data.localId.value : this.localId,
      receiptNo: data.receiptNo.present ? data.receiptNo.value : this.receiptNo,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      companyName:
          data.companyName.present ? data.companyName.value : this.companyName,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      storeName: data.storeName.present ? data.storeName.value : this.storeName,
      totalAmount:
          data.totalAmount.present ? data.totalAmount.value : this.totalAmount,
      selfiePath:
          data.selfiePath.present ? data.selfiePath.value : this.selfiePath,
      receiptPath:
          data.receiptPath.present ? data.receiptPath.value : this.receiptPath,
      notes: data.notes.present ? data.notes.value : this.notes,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      paymentBank:
          data.paymentBank.present ? data.paymentBank.value : this.paymentBank,
      midtransId:
          data.midtransId.present ? data.midtransId.value : this.midtransId,
      midtransQrisUrl: data.midtransQrisUrl.present
          ? data.midtransQrisUrl.value
          : this.midtransQrisUrl,
      midtransVaNumber: data.midtransVaNumber.present
          ? data.midtransVaNumber.value
          : this.midtransVaNumber,
      midtransBank: data.midtransBank.present
          ? data.midtransBank.value
          : this.midtransBank,
      midtransBillKey: data.midtransBillKey.present
          ? data.midtransBillKey.value
          : this.midtransBillKey,
      midtransBillerCode: data.midtransBillerCode.present
          ? data.midtransBillerCode.value
          : this.midtransBillerCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTransaction(')
          ..write('localId: $localId, ')
          ..write('receiptNo: $receiptNo, ')
          ..write('companyId: $companyId, ')
          ..write('companyName: $companyName, ')
          ..write('storeId: $storeId, ')
          ..write('storeName: $storeName, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('selfiePath: $selfiePath, ')
          ..write('receiptPath: $receiptPath, ')
          ..write('notes: $notes, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('paymentBank: $paymentBank, ')
          ..write('midtransId: $midtransId, ')
          ..write('midtransQrisUrl: $midtransQrisUrl, ')
          ..write('midtransVaNumber: $midtransVaNumber, ')
          ..write('midtransBank: $midtransBank, ')
          ..write('midtransBillKey: $midtransBillKey, ')
          ..write('midtransBillerCode: $midtransBillerCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId,
      receiptNo,
      companyId,
      companyName,
      storeId,
      storeName,
      totalAmount,
      selfiePath,
      receiptPath,
      notes,
      paymentMethod,
      paymentBank,
      midtransId,
      midtransQrisUrl,
      midtransVaNumber,
      midtransBank,
      midtransBillKey,
      midtransBillerCode,
      createdAt,
      syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTransaction &&
          other.localId == this.localId &&
          other.receiptNo == this.receiptNo &&
          other.companyId == this.companyId &&
          other.companyName == this.companyName &&
          other.storeId == this.storeId &&
          other.storeName == this.storeName &&
          other.totalAmount == this.totalAmount &&
          other.selfiePath == this.selfiePath &&
          other.receiptPath == this.receiptPath &&
          other.notes == this.notes &&
          other.paymentMethod == this.paymentMethod &&
          other.paymentBank == this.paymentBank &&
          other.midtransId == this.midtransId &&
          other.midtransQrisUrl == this.midtransQrisUrl &&
          other.midtransVaNumber == this.midtransVaNumber &&
          other.midtransBank == this.midtransBank &&
          other.midtransBillKey == this.midtransBillKey &&
          other.midtransBillerCode == this.midtransBillerCode &&
          other.createdAt == this.createdAt &&
          other.syncStatus == this.syncStatus);
}

class LocalTransactionsCompanion extends UpdateCompanion<LocalTransaction> {
  final Value<String> localId;
  final Value<String?> receiptNo;
  final Value<String> companyId;
  final Value<String> companyName;
  final Value<String> storeId;
  final Value<String> storeName;
  final Value<double> totalAmount;
  final Value<String?> selfiePath;
  final Value<String?> receiptPath;
  final Value<String?> notes;
  final Value<String> paymentMethod;
  final Value<String?> paymentBank;
  final Value<String?> midtransId;
  final Value<String?> midtransQrisUrl;
  final Value<String?> midtransVaNumber;
  final Value<String?> midtransBank;
  final Value<String?> midtransBillKey;
  final Value<String?> midtransBillerCode;
  final Value<DateTime> createdAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const LocalTransactionsCompanion({
    this.localId = const Value.absent(),
    this.receiptNo = const Value.absent(),
    this.companyId = const Value.absent(),
    this.companyName = const Value.absent(),
    this.storeId = const Value.absent(),
    this.storeName = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.selfiePath = const Value.absent(),
    this.receiptPath = const Value.absent(),
    this.notes = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.paymentBank = const Value.absent(),
    this.midtransId = const Value.absent(),
    this.midtransQrisUrl = const Value.absent(),
    this.midtransVaNumber = const Value.absent(),
    this.midtransBank = const Value.absent(),
    this.midtransBillKey = const Value.absent(),
    this.midtransBillerCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTransactionsCompanion.insert({
    required String localId,
    this.receiptNo = const Value.absent(),
    required String companyId,
    required String companyName,
    required String storeId,
    required String storeName,
    required double totalAmount,
    this.selfiePath = const Value.absent(),
    this.receiptPath = const Value.absent(),
    this.notes = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.paymentBank = const Value.absent(),
    this.midtransId = const Value.absent(),
    this.midtransQrisUrl = const Value.absent(),
    this.midtransVaNumber = const Value.absent(),
    this.midtransBank = const Value.absent(),
    this.midtransBillKey = const Value.absent(),
    this.midtransBillerCode = const Value.absent(),
    required DateTime createdAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : localId = Value(localId),
        companyId = Value(companyId),
        companyName = Value(companyName),
        storeId = Value(storeId),
        storeName = Value(storeName),
        totalAmount = Value(totalAmount),
        createdAt = Value(createdAt);
  static Insertable<LocalTransaction> custom({
    Expression<String>? localId,
    Expression<String>? receiptNo,
    Expression<String>? companyId,
    Expression<String>? companyName,
    Expression<String>? storeId,
    Expression<String>? storeName,
    Expression<double>? totalAmount,
    Expression<String>? selfiePath,
    Expression<String>? receiptPath,
    Expression<String>? notes,
    Expression<String>? paymentMethod,
    Expression<String>? paymentBank,
    Expression<String>? midtransId,
    Expression<String>? midtransQrisUrl,
    Expression<String>? midtransVaNumber,
    Expression<String>? midtransBank,
    Expression<String>? midtransBillKey,
    Expression<String>? midtransBillerCode,
    Expression<DateTime>? createdAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (receiptNo != null) 'receipt_no': receiptNo,
      if (companyId != null) 'company_id': companyId,
      if (companyName != null) 'company_name': companyName,
      if (storeId != null) 'store_id': storeId,
      if (storeName != null) 'store_name': storeName,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (selfiePath != null) 'selfie_path': selfiePath,
      if (receiptPath != null) 'receipt_path': receiptPath,
      if (notes != null) 'notes': notes,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (paymentBank != null) 'payment_bank': paymentBank,
      if (midtransId != null) 'midtrans_id': midtransId,
      if (midtransQrisUrl != null) 'midtrans_qris_url': midtransQrisUrl,
      if (midtransVaNumber != null) 'midtrans_va_number': midtransVaNumber,
      if (midtransBank != null) 'midtrans_bank': midtransBank,
      if (midtransBillKey != null) 'midtrans_bill_key': midtransBillKey,
      if (midtransBillerCode != null)
        'midtrans_biller_code': midtransBillerCode,
      if (createdAt != null) 'created_at': createdAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTransactionsCompanion copyWith(
      {Value<String>? localId,
      Value<String?>? receiptNo,
      Value<String>? companyId,
      Value<String>? companyName,
      Value<String>? storeId,
      Value<String>? storeName,
      Value<double>? totalAmount,
      Value<String?>? selfiePath,
      Value<String?>? receiptPath,
      Value<String?>? notes,
      Value<String>? paymentMethod,
      Value<String?>? paymentBank,
      Value<String?>? midtransId,
      Value<String?>? midtransQrisUrl,
      Value<String?>? midtransVaNumber,
      Value<String?>? midtransBank,
      Value<String?>? midtransBillKey,
      Value<String?>? midtransBillerCode,
      Value<DateTime>? createdAt,
      Value<String>? syncStatus,
      Value<int>? rowid}) {
    return LocalTransactionsCompanion(
      localId: localId ?? this.localId,
      receiptNo: receiptNo ?? this.receiptNo,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      totalAmount: totalAmount ?? this.totalAmount,
      selfiePath: selfiePath ?? this.selfiePath,
      receiptPath: receiptPath ?? this.receiptPath,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentBank: paymentBank ?? this.paymentBank,
      midtransId: midtransId ?? this.midtransId,
      midtransQrisUrl: midtransQrisUrl ?? this.midtransQrisUrl,
      midtransVaNumber: midtransVaNumber ?? this.midtransVaNumber,
      midtransBank: midtransBank ?? this.midtransBank,
      midtransBillKey: midtransBillKey ?? this.midtransBillKey,
      midtransBillerCode: midtransBillerCode ?? this.midtransBillerCode,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (receiptNo.present) {
      map['receipt_no'] = Variable<String>(receiptNo.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (companyName.present) {
      map['company_name'] = Variable<String>(companyName.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (storeName.present) {
      map['store_name'] = Variable<String>(storeName.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (selfiePath.present) {
      map['selfie_path'] = Variable<String>(selfiePath.value);
    }
    if (receiptPath.present) {
      map['receipt_path'] = Variable<String>(receiptPath.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (paymentBank.present) {
      map['payment_bank'] = Variable<String>(paymentBank.value);
    }
    if (midtransId.present) {
      map['midtrans_id'] = Variable<String>(midtransId.value);
    }
    if (midtransQrisUrl.present) {
      map['midtrans_qris_url'] = Variable<String>(midtransQrisUrl.value);
    }
    if (midtransVaNumber.present) {
      map['midtrans_va_number'] = Variable<String>(midtransVaNumber.value);
    }
    if (midtransBank.present) {
      map['midtrans_bank'] = Variable<String>(midtransBank.value);
    }
    if (midtransBillKey.present) {
      map['midtrans_bill_key'] = Variable<String>(midtransBillKey.value);
    }
    if (midtransBillerCode.present) {
      map['midtrans_biller_code'] = Variable<String>(midtransBillerCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTransactionsCompanion(')
          ..write('localId: $localId, ')
          ..write('receiptNo: $receiptNo, ')
          ..write('companyId: $companyId, ')
          ..write('companyName: $companyName, ')
          ..write('storeId: $storeId, ')
          ..write('storeName: $storeName, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('selfiePath: $selfiePath, ')
          ..write('receiptPath: $receiptPath, ')
          ..write('notes: $notes, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('paymentBank: $paymentBank, ')
          ..write('midtransId: $midtransId, ')
          ..write('midtransQrisUrl: $midtransQrisUrl, ')
          ..write('midtransVaNumber: $midtransVaNumber, ')
          ..write('midtransBank: $midtransBank, ')
          ..write('midtransBillKey: $midtransBillKey, ')
          ..write('midtransBillerCode: $midtransBillerCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalTransactionItemsTable extends LocalTransactionItems
    with TableInfo<$LocalTransactionItemsTable, LocalTransactionItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTransactionItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _transactionLocalIdMeta =
      const VerificationMeta('transactionLocalId');
  @override
  late final GeneratedColumn<String> transactionLocalId =
      GeneratedColumn<String>('transaction_local_id', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'REFERENCES local_transactions (local_id)'));
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _orderedQuantityMeta =
      const VerificationMeta('orderedQuantity');
  @override
  late final GeneratedColumn<int> orderedQuantity = GeneratedColumn<int>(
      'ordered_quantity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('PCS'));
  static const VerificationMeta _piecesPerUnitMeta =
      const VerificationMeta('piecesPerUnit');
  @override
  late final GeneratedColumn<int> piecesPerUnit = GeneratedColumn<int>(
      'pieces_per_unit', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        transactionLocalId,
        productId,
        productName,
        quantity,
        orderedQuantity,
        unit,
        piecesPerUnit,
        price
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_transaction_items';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalTransactionItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('transaction_local_id')) {
      context.handle(
          _transactionLocalIdMeta,
          transactionLocalId.isAcceptableOrUnknown(
              data['transaction_local_id']!, _transactionLocalIdMeta));
    } else if (isInserting) {
      context.missing(_transactionLocalIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('ordered_quantity')) {
      context.handle(
          _orderedQuantityMeta,
          orderedQuantity.isAcceptableOrUnknown(
              data['ordered_quantity']!, _orderedQuantityMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('pieces_per_unit')) {
      context.handle(
          _piecesPerUnitMeta,
          piecesPerUnit.isAcceptableOrUnknown(
              data['pieces_per_unit']!, _piecesPerUnitMeta));
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTransactionItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTransactionItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      transactionLocalId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}transaction_local_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      orderedQuantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ordered_quantity'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      piecesPerUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pieces_per_unit'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
    );
  }

  @override
  $LocalTransactionItemsTable createAlias(String alias) {
    return $LocalTransactionItemsTable(attachedDatabase, alias);
  }
}

class LocalTransactionItem extends DataClass
    implements Insertable<LocalTransactionItem> {
  final int id;
  final String transactionLocalId;
  final String productId;
  final String productName;
  final int quantity;
  final int orderedQuantity;
  final String unit;
  final int piecesPerUnit;
  final double price;
  const LocalTransactionItem(
      {required this.id,
      required this.transactionLocalId,
      required this.productId,
      required this.productName,
      required this.quantity,
      required this.orderedQuantity,
      required this.unit,
      required this.piecesPerUnit,
      required this.price});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['transaction_local_id'] = Variable<String>(transactionLocalId);
    map['product_id'] = Variable<String>(productId);
    map['product_name'] = Variable<String>(productName);
    map['quantity'] = Variable<int>(quantity);
    map['ordered_quantity'] = Variable<int>(orderedQuantity);
    map['unit'] = Variable<String>(unit);
    map['pieces_per_unit'] = Variable<int>(piecesPerUnit);
    map['price'] = Variable<double>(price);
    return map;
  }

  LocalTransactionItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalTransactionItemsCompanion(
      id: Value(id),
      transactionLocalId: Value(transactionLocalId),
      productId: Value(productId),
      productName: Value(productName),
      quantity: Value(quantity),
      orderedQuantity: Value(orderedQuantity),
      unit: Value(unit),
      piecesPerUnit: Value(piecesPerUnit),
      price: Value(price),
    );
  }

  factory LocalTransactionItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTransactionItem(
      id: serializer.fromJson<int>(json['id']),
      transactionLocalId:
          serializer.fromJson<String>(json['transactionLocalId']),
      productId: serializer.fromJson<String>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      quantity: serializer.fromJson<int>(json['quantity']),
      orderedQuantity: serializer.fromJson<int>(json['orderedQuantity']),
      unit: serializer.fromJson<String>(json['unit']),
      piecesPerUnit: serializer.fromJson<int>(json['piecesPerUnit']),
      price: serializer.fromJson<double>(json['price']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'transactionLocalId': serializer.toJson<String>(transactionLocalId),
      'productId': serializer.toJson<String>(productId),
      'productName': serializer.toJson<String>(productName),
      'quantity': serializer.toJson<int>(quantity),
      'orderedQuantity': serializer.toJson<int>(orderedQuantity),
      'unit': serializer.toJson<String>(unit),
      'piecesPerUnit': serializer.toJson<int>(piecesPerUnit),
      'price': serializer.toJson<double>(price),
    };
  }

  LocalTransactionItem copyWith(
          {int? id,
          String? transactionLocalId,
          String? productId,
          String? productName,
          int? quantity,
          int? orderedQuantity,
          String? unit,
          int? piecesPerUnit,
          double? price}) =>
      LocalTransactionItem(
        id: id ?? this.id,
        transactionLocalId: transactionLocalId ?? this.transactionLocalId,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        quantity: quantity ?? this.quantity,
        orderedQuantity: orderedQuantity ?? this.orderedQuantity,
        unit: unit ?? this.unit,
        piecesPerUnit: piecesPerUnit ?? this.piecesPerUnit,
        price: price ?? this.price,
      );
  LocalTransactionItem copyWithCompanion(LocalTransactionItemsCompanion data) {
    return LocalTransactionItem(
      id: data.id.present ? data.id.value : this.id,
      transactionLocalId: data.transactionLocalId.present
          ? data.transactionLocalId.value
          : this.transactionLocalId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      orderedQuantity: data.orderedQuantity.present
          ? data.orderedQuantity.value
          : this.orderedQuantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      piecesPerUnit: data.piecesPerUnit.present
          ? data.piecesPerUnit.value
          : this.piecesPerUnit,
      price: data.price.present ? data.price.value : this.price,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTransactionItem(')
          ..write('id: $id, ')
          ..write('transactionLocalId: $transactionLocalId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('orderedQuantity: $orderedQuantity, ')
          ..write('unit: $unit, ')
          ..write('piecesPerUnit: $piecesPerUnit, ')
          ..write('price: $price')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, transactionLocalId, productId,
      productName, quantity, orderedQuantity, unit, piecesPerUnit, price);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTransactionItem &&
          other.id == this.id &&
          other.transactionLocalId == this.transactionLocalId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.quantity == this.quantity &&
          other.orderedQuantity == this.orderedQuantity &&
          other.unit == this.unit &&
          other.piecesPerUnit == this.piecesPerUnit &&
          other.price == this.price);
}

class LocalTransactionItemsCompanion
    extends UpdateCompanion<LocalTransactionItem> {
  final Value<int> id;
  final Value<String> transactionLocalId;
  final Value<String> productId;
  final Value<String> productName;
  final Value<int> quantity;
  final Value<int> orderedQuantity;
  final Value<String> unit;
  final Value<int> piecesPerUnit;
  final Value<double> price;
  const LocalTransactionItemsCompanion({
    this.id = const Value.absent(),
    this.transactionLocalId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.orderedQuantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.piecesPerUnit = const Value.absent(),
    this.price = const Value.absent(),
  });
  LocalTransactionItemsCompanion.insert({
    this.id = const Value.absent(),
    required String transactionLocalId,
    required String productId,
    required String productName,
    required int quantity,
    this.orderedQuantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.piecesPerUnit = const Value.absent(),
    required double price,
  })  : transactionLocalId = Value(transactionLocalId),
        productId = Value(productId),
        productName = Value(productName),
        quantity = Value(quantity),
        price = Value(price);
  static Insertable<LocalTransactionItem> custom({
    Expression<int>? id,
    Expression<String>? transactionLocalId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<int>? quantity,
    Expression<int>? orderedQuantity,
    Expression<String>? unit,
    Expression<int>? piecesPerUnit,
    Expression<double>? price,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionLocalId != null)
        'transaction_local_id': transactionLocalId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (quantity != null) 'quantity': quantity,
      if (orderedQuantity != null) 'ordered_quantity': orderedQuantity,
      if (unit != null) 'unit': unit,
      if (piecesPerUnit != null) 'pieces_per_unit': piecesPerUnit,
      if (price != null) 'price': price,
    });
  }

  LocalTransactionItemsCompanion copyWith(
      {Value<int>? id,
      Value<String>? transactionLocalId,
      Value<String>? productId,
      Value<String>? productName,
      Value<int>? quantity,
      Value<int>? orderedQuantity,
      Value<String>? unit,
      Value<int>? piecesPerUnit,
      Value<double>? price}) {
    return LocalTransactionItemsCompanion(
      id: id ?? this.id,
      transactionLocalId: transactionLocalId ?? this.transactionLocalId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      orderedQuantity: orderedQuantity ?? this.orderedQuantity,
      unit: unit ?? this.unit,
      piecesPerUnit: piecesPerUnit ?? this.piecesPerUnit,
      price: price ?? this.price,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (transactionLocalId.present) {
      map['transaction_local_id'] = Variable<String>(transactionLocalId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (orderedQuantity.present) {
      map['ordered_quantity'] = Variable<int>(orderedQuantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (piecesPerUnit.present) {
      map['pieces_per_unit'] = Variable<int>(piecesPerUnit.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTransactionItemsCompanion(')
          ..write('id: $id, ')
          ..write('transactionLocalId: $transactionLocalId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('orderedQuantity: $orderedQuantity, ')
          ..write('unit: $unit, ')
          ..write('piecesPerUnit: $piecesPerUnit, ')
          ..write('price: $price')
          ..write(')'))
        .toString();
  }
}

class $SalesStockTable extends SalesStock
    with TableInfo<$SalesStockTable, SalesStockData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesStockTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [productId, quantity, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales_stock';
  @override
  VerificationContext validateIntegrity(Insertable<SalesStockData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {productId};
  @override
  SalesStockData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SalesStockData(
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SalesStockTable createAlias(String alias) {
    return $SalesStockTable(attachedDatabase, alias);
  }
}

class SalesStockData extends DataClass implements Insertable<SalesStockData> {
  final String productId;
  final int quantity;
  final DateTime updatedAt;
  const SalesStockData(
      {required this.productId,
      required this.quantity,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<String>(productId);
    map['quantity'] = Variable<int>(quantity);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SalesStockCompanion toCompanion(bool nullToAbsent) {
    return SalesStockCompanion(
      productId: Value(productId),
      quantity: Value(quantity),
      updatedAt: Value(updatedAt),
    );
  }

  factory SalesStockData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SalesStockData(
      productId: serializer.fromJson<String>(json['productId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<String>(productId),
      'quantity': serializer.toJson<int>(quantity),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SalesStockData copyWith(
          {String? productId, int? quantity, DateTime? updatedAt}) =>
      SalesStockData(
        productId: productId ?? this.productId,
        quantity: quantity ?? this.quantity,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SalesStockData copyWithCompanion(SalesStockCompanion data) {
    return SalesStockData(
      productId: data.productId.present ? data.productId.value : this.productId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SalesStockData(')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(productId, quantity, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SalesStockData &&
          other.productId == this.productId &&
          other.quantity == this.quantity &&
          other.updatedAt == this.updatedAt);
}

class SalesStockCompanion extends UpdateCompanion<SalesStockData> {
  final Value<String> productId;
  final Value<int> quantity;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SalesStockCompanion({
    this.productId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SalesStockCompanion.insert({
    required String productId,
    required int quantity,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : productId = Value(productId),
        quantity = Value(quantity),
        updatedAt = Value(updatedAt);
  static Insertable<SalesStockData> custom({
    Expression<String>? productId,
    Expression<int>? quantity,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (quantity != null) 'quantity': quantity,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SalesStockCompanion copyWith(
      {Value<String>? productId,
      Value<int>? quantity,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SalesStockCompanion(
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesStockCompanion(')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $CompaniesTable companies = $CompaniesTable(this);
  late final $LocalCheckinsTable localCheckins = $LocalCheckinsTable(this);
  late final $LocalTransactionsTable localTransactions =
      $LocalTransactionsTable(this);
  late final $LocalTransactionItemsTable localTransactionItems =
      $LocalTransactionItemsTable(this);
  late final $SalesStockTable salesStock = $SalesStockTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        products,
        companies,
        localCheckins,
        localTransactions,
        localTransactionItems,
        salesStock
      ];
}

typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  required String id,
  required String companyId,
  required String name,
  Value<String?> sku,
  required double sellingPrice,
  Value<String?> unit,
  Value<String?> category,
  Value<int> warehouseStock,
  Value<int> pcsPerUnit,
  Value<String?> imageUrl,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<String> companyId,
  Value<String> name,
  Value<String?> sku,
  Value<double> sellingPrice,
  Value<String?> unit,
  Value<String?> category,
  Value<int> warehouseStock,
  Value<int> pcsPerUnit,
  Value<String?> imageUrl,
  Value<int> rowid,
});

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyId => $composableBuilder(
      column: $table.companyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sellingPrice => $composableBuilder(
      column: $table.sellingPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get warehouseStock => $composableBuilder(
      column: $table.warehouseStock,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pcsPerUnit => $composableBuilder(
      column: $table.pcsPerUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnFilters(column));
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyId => $composableBuilder(
      column: $table.companyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sellingPrice => $composableBuilder(
      column: $table.sellingPrice,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get warehouseStock => $composableBuilder(
      column: $table.warehouseStock,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pcsPerUnit => $composableBuilder(
      column: $table.pcsPerUnit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnOrderings(column));
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<double> get sellingPrice => $composableBuilder(
      column: $table.sellingPrice, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get warehouseStock => $composableBuilder(
      column: $table.warehouseStock, builder: (column) => column);

  GeneratedColumn<int> get pcsPerUnit => $composableBuilder(
      column: $table.pcsPerUnit, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);
}

class $$ProductsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
    Product,
    PrefetchHooks Function()> {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> companyId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> sku = const Value.absent(),
            Value<double> sellingPrice = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<int> warehouseStock = const Value.absent(),
            Value<int> pcsPerUnit = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion(
            id: id,
            companyId: companyId,
            name: name,
            sku: sku,
            sellingPrice: sellingPrice,
            unit: unit,
            category: category,
            warehouseStock: warehouseStock,
            pcsPerUnit: pcsPerUnit,
            imageUrl: imageUrl,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String companyId,
            required String name,
            Value<String?> sku = const Value.absent(),
            required double sellingPrice,
            Value<String?> unit = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<int> warehouseStock = const Value.absent(),
            Value<int> pcsPerUnit = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion.insert(
            id: id,
            companyId: companyId,
            name: name,
            sku: sku,
            sellingPrice: sellingPrice,
            unit: unit,
            category: category,
            warehouseStock: warehouseStock,
            pcsPerUnit: pcsPerUnit,
            imageUrl: imageUrl,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProductsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
    Product,
    PrefetchHooks Function()>;
typedef $$CompaniesTableCreateCompanionBuilder = CompaniesCompanion Function({
  required String id,
  required String name,
  Value<String?> code,
  Value<int> rowid,
});
typedef $$CompaniesTableUpdateCompanionBuilder = CompaniesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> code,
  Value<int> rowid,
});

class $$CompaniesTableFilterComposer
    extends Composer<_$AppDatabase, $CompaniesTable> {
  $$CompaniesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));
}

class $$CompaniesTableOrderingComposer
    extends Composer<_$AppDatabase, $CompaniesTable> {
  $$CompaniesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));
}

class $$CompaniesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompaniesTable> {
  $$CompaniesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);
}

class $$CompaniesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CompaniesTable,
    Company,
    $$CompaniesTableFilterComposer,
    $$CompaniesTableOrderingComposer,
    $$CompaniesTableAnnotationComposer,
    $$CompaniesTableCreateCompanionBuilder,
    $$CompaniesTableUpdateCompanionBuilder,
    (Company, BaseReferences<_$AppDatabase, $CompaniesTable, Company>),
    Company,
    PrefetchHooks Function()> {
  $$CompaniesTableTableManager(_$AppDatabase db, $CompaniesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompaniesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompaniesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompaniesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> code = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CompaniesCompanion(
            id: id,
            name: name,
            code: code,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> code = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CompaniesCompanion.insert(
            id: id,
            name: name,
            code: code,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CompaniesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CompaniesTable,
    Company,
    $$CompaniesTableFilterComposer,
    $$CompaniesTableOrderingComposer,
    $$CompaniesTableAnnotationComposer,
    $$CompaniesTableCreateCompanionBuilder,
    $$CompaniesTableUpdateCompanionBuilder,
    (Company, BaseReferences<_$AppDatabase, $CompaniesTable, Company>),
    Company,
    PrefetchHooks Function()>;
typedef $$LocalCheckinsTableCreateCompanionBuilder = LocalCheckinsCompanion
    Function({
  Value<int> id,
  required String storeId,
  required String storeName,
  required double latitude,
  required double longitude,
  required String selfiePath,
  required DateTime createdAt,
  Value<String> syncStatus,
});
typedef $$LocalCheckinsTableUpdateCompanionBuilder = LocalCheckinsCompanion
    Function({
  Value<int> id,
  Value<String> storeId,
  Value<String> storeName,
  Value<double> latitude,
  Value<double> longitude,
  Value<String> selfiePath,
  Value<DateTime> createdAt,
  Value<String> syncStatus,
});

class $$LocalCheckinsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCheckinsTable> {
  $$LocalCheckinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storeId => $composableBuilder(
      column: $table.storeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storeName => $composableBuilder(
      column: $table.storeName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get selfiePath => $composableBuilder(
      column: $table.selfiePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));
}

class $$LocalCheckinsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCheckinsTable> {
  $$LocalCheckinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storeId => $composableBuilder(
      column: $table.storeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storeName => $composableBuilder(
      column: $table.storeName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get selfiePath => $composableBuilder(
      column: $table.selfiePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));
}

class $$LocalCheckinsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCheckinsTable> {
  $$LocalCheckinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get storeName =>
      $composableBuilder(column: $table.storeName, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get selfiePath => $composableBuilder(
      column: $table.selfiePath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);
}

class $$LocalCheckinsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalCheckinsTable,
    LocalCheckin,
    $$LocalCheckinsTableFilterComposer,
    $$LocalCheckinsTableOrderingComposer,
    $$LocalCheckinsTableAnnotationComposer,
    $$LocalCheckinsTableCreateCompanionBuilder,
    $$LocalCheckinsTableUpdateCompanionBuilder,
    (
      LocalCheckin,
      BaseReferences<_$AppDatabase, $LocalCheckinsTable, LocalCheckin>
    ),
    LocalCheckin,
    PrefetchHooks Function()> {
  $$LocalCheckinsTableTableManager(_$AppDatabase db, $LocalCheckinsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCheckinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCheckinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCheckinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> storeId = const Value.absent(),
            Value<String> storeName = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<String> selfiePath = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
          }) =>
              LocalCheckinsCompanion(
            id: id,
            storeId: storeId,
            storeName: storeName,
            latitude: latitude,
            longitude: longitude,
            selfiePath: selfiePath,
            createdAt: createdAt,
            syncStatus: syncStatus,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String storeId,
            required String storeName,
            required double latitude,
            required double longitude,
            required String selfiePath,
            required DateTime createdAt,
            Value<String> syncStatus = const Value.absent(),
          }) =>
              LocalCheckinsCompanion.insert(
            id: id,
            storeId: storeId,
            storeName: storeName,
            latitude: latitude,
            longitude: longitude,
            selfiePath: selfiePath,
            createdAt: createdAt,
            syncStatus: syncStatus,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalCheckinsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalCheckinsTable,
    LocalCheckin,
    $$LocalCheckinsTableFilterComposer,
    $$LocalCheckinsTableOrderingComposer,
    $$LocalCheckinsTableAnnotationComposer,
    $$LocalCheckinsTableCreateCompanionBuilder,
    $$LocalCheckinsTableUpdateCompanionBuilder,
    (
      LocalCheckin,
      BaseReferences<_$AppDatabase, $LocalCheckinsTable, LocalCheckin>
    ),
    LocalCheckin,
    PrefetchHooks Function()>;
typedef $$LocalTransactionsTableCreateCompanionBuilder
    = LocalTransactionsCompanion Function({
  required String localId,
  Value<String?> receiptNo,
  required String companyId,
  required String companyName,
  required String storeId,
  required String storeName,
  required double totalAmount,
  Value<String?> selfiePath,
  Value<String?> receiptPath,
  Value<String?> notes,
  Value<String> paymentMethod,
  Value<String?> paymentBank,
  Value<String?> midtransId,
  Value<String?> midtransQrisUrl,
  Value<String?> midtransVaNumber,
  Value<String?> midtransBank,
  Value<String?> midtransBillKey,
  Value<String?> midtransBillerCode,
  required DateTime createdAt,
  Value<String> syncStatus,
  Value<int> rowid,
});
typedef $$LocalTransactionsTableUpdateCompanionBuilder
    = LocalTransactionsCompanion Function({
  Value<String> localId,
  Value<String?> receiptNo,
  Value<String> companyId,
  Value<String> companyName,
  Value<String> storeId,
  Value<String> storeName,
  Value<double> totalAmount,
  Value<String?> selfiePath,
  Value<String?> receiptPath,
  Value<String?> notes,
  Value<String> paymentMethod,
  Value<String?> paymentBank,
  Value<String?> midtransId,
  Value<String?> midtransQrisUrl,
  Value<String?> midtransVaNumber,
  Value<String?> midtransBank,
  Value<String?> midtransBillKey,
  Value<String?> midtransBillerCode,
  Value<DateTime> createdAt,
  Value<String> syncStatus,
  Value<int> rowid,
});

final class $$LocalTransactionsTableReferences extends BaseReferences<
    _$AppDatabase, $LocalTransactionsTable, LocalTransaction> {
  $$LocalTransactionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LocalTransactionItemsTable,
      List<LocalTransactionItem>> _localTransactionItemsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.localTransactionItems,
          aliasName: $_aliasNameGenerator(db.localTransactions.localId,
              db.localTransactionItems.transactionLocalId));

  $$LocalTransactionItemsTableProcessedTableManager
      get localTransactionItemsRefs {
    final manager = $$LocalTransactionItemsTableTableManager(
            $_db, $_db.localTransactionItems)
        .filter((f) => f.transactionLocalId.localId
            .sqlEquals($_itemColumn<String>('local_id')!));

    final cache =
        $_typedResult.readTableOrNull(_localTransactionItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LocalTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTransactionsTable> {
  $$LocalTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receiptNo => $composableBuilder(
      column: $table.receiptNo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyId => $composableBuilder(
      column: $table.companyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyName => $composableBuilder(
      column: $table.companyName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storeId => $composableBuilder(
      column: $table.storeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storeName => $composableBuilder(
      column: $table.storeName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get selfiePath => $composableBuilder(
      column: $table.selfiePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receiptPath => $composableBuilder(
      column: $table.receiptPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentBank => $composableBuilder(
      column: $table.paymentBank, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get midtransId => $composableBuilder(
      column: $table.midtransId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get midtransQrisUrl => $composableBuilder(
      column: $table.midtransQrisUrl,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get midtransVaNumber => $composableBuilder(
      column: $table.midtransVaNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get midtransBank => $composableBuilder(
      column: $table.midtransBank, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get midtransBillKey => $composableBuilder(
      column: $table.midtransBillKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get midtransBillerCode => $composableBuilder(
      column: $table.midtransBillerCode,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  Expression<bool> localTransactionItemsRefs(
      Expression<bool> Function($$LocalTransactionItemsTableFilterComposer f)
          f) {
    final $$LocalTransactionItemsTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.localId,
            referencedTable: $db.localTransactionItems,
            getReferencedColumn: (t) => t.transactionLocalId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$LocalTransactionItemsTableFilterComposer(
                  $db: $db,
                  $table: $db.localTransactionItems,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$LocalTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTransactionsTable> {
  $$LocalTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receiptNo => $composableBuilder(
      column: $table.receiptNo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyId => $composableBuilder(
      column: $table.companyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyName => $composableBuilder(
      column: $table.companyName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storeId => $composableBuilder(
      column: $table.storeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storeName => $composableBuilder(
      column: $table.storeName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get selfiePath => $composableBuilder(
      column: $table.selfiePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receiptPath => $composableBuilder(
      column: $table.receiptPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentBank => $composableBuilder(
      column: $table.paymentBank, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get midtransId => $composableBuilder(
      column: $table.midtransId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get midtransQrisUrl => $composableBuilder(
      column: $table.midtransQrisUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get midtransVaNumber => $composableBuilder(
      column: $table.midtransVaNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get midtransBank => $composableBuilder(
      column: $table.midtransBank,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get midtransBillKey => $composableBuilder(
      column: $table.midtransBillKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get midtransBillerCode => $composableBuilder(
      column: $table.midtransBillerCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));
}

class $$LocalTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTransactionsTable> {
  $$LocalTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get receiptNo =>
      $composableBuilder(column: $table.receiptNo, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get companyName => $composableBuilder(
      column: $table.companyName, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get storeName =>
      $composableBuilder(column: $table.storeName, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => column);

  GeneratedColumn<String> get selfiePath => $composableBuilder(
      column: $table.selfiePath, builder: (column) => column);

  GeneratedColumn<String> get receiptPath => $composableBuilder(
      column: $table.receiptPath, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => column);

  GeneratedColumn<String> get paymentBank => $composableBuilder(
      column: $table.paymentBank, builder: (column) => column);

  GeneratedColumn<String> get midtransId => $composableBuilder(
      column: $table.midtransId, builder: (column) => column);

  GeneratedColumn<String> get midtransQrisUrl => $composableBuilder(
      column: $table.midtransQrisUrl, builder: (column) => column);

  GeneratedColumn<String> get midtransVaNumber => $composableBuilder(
      column: $table.midtransVaNumber, builder: (column) => column);

  GeneratedColumn<String> get midtransBank => $composableBuilder(
      column: $table.midtransBank, builder: (column) => column);

  GeneratedColumn<String> get midtransBillKey => $composableBuilder(
      column: $table.midtransBillKey, builder: (column) => column);

  GeneratedColumn<String> get midtransBillerCode => $composableBuilder(
      column: $table.midtransBillerCode, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  Expression<T> localTransactionItemsRefs<T extends Object>(
      Expression<T> Function($$LocalTransactionItemsTableAnnotationComposer a)
          f) {
    final $$LocalTransactionItemsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.localId,
            referencedTable: $db.localTransactionItems,
            getReferencedColumn: (t) => t.transactionLocalId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$LocalTransactionItemsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.localTransactionItems,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$LocalTransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalTransactionsTable,
    LocalTransaction,
    $$LocalTransactionsTableFilterComposer,
    $$LocalTransactionsTableOrderingComposer,
    $$LocalTransactionsTableAnnotationComposer,
    $$LocalTransactionsTableCreateCompanionBuilder,
    $$LocalTransactionsTableUpdateCompanionBuilder,
    (LocalTransaction, $$LocalTransactionsTableReferences),
    LocalTransaction,
    PrefetchHooks Function({bool localTransactionItemsRefs})> {
  $$LocalTransactionsTableTableManager(
      _$AppDatabase db, $LocalTransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTransactionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> localId = const Value.absent(),
            Value<String?> receiptNo = const Value.absent(),
            Value<String> companyId = const Value.absent(),
            Value<String> companyName = const Value.absent(),
            Value<String> storeId = const Value.absent(),
            Value<String> storeName = const Value.absent(),
            Value<double> totalAmount = const Value.absent(),
            Value<String?> selfiePath = const Value.absent(),
            Value<String?> receiptPath = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<String?> paymentBank = const Value.absent(),
            Value<String?> midtransId = const Value.absent(),
            Value<String?> midtransQrisUrl = const Value.absent(),
            Value<String?> midtransVaNumber = const Value.absent(),
            Value<String?> midtransBank = const Value.absent(),
            Value<String?> midtransBillKey = const Value.absent(),
            Value<String?> midtransBillerCode = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalTransactionsCompanion(
            localId: localId,
            receiptNo: receiptNo,
            companyId: companyId,
            companyName: companyName,
            storeId: storeId,
            storeName: storeName,
            totalAmount: totalAmount,
            selfiePath: selfiePath,
            receiptPath: receiptPath,
            notes: notes,
            paymentMethod: paymentMethod,
            paymentBank: paymentBank,
            midtransId: midtransId,
            midtransQrisUrl: midtransQrisUrl,
            midtransVaNumber: midtransVaNumber,
            midtransBank: midtransBank,
            midtransBillKey: midtransBillKey,
            midtransBillerCode: midtransBillerCode,
            createdAt: createdAt,
            syncStatus: syncStatus,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String localId,
            Value<String?> receiptNo = const Value.absent(),
            required String companyId,
            required String companyName,
            required String storeId,
            required String storeName,
            required double totalAmount,
            Value<String?> selfiePath = const Value.absent(),
            Value<String?> receiptPath = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<String?> paymentBank = const Value.absent(),
            Value<String?> midtransId = const Value.absent(),
            Value<String?> midtransQrisUrl = const Value.absent(),
            Value<String?> midtransVaNumber = const Value.absent(),
            Value<String?> midtransBank = const Value.absent(),
            Value<String?> midtransBillKey = const Value.absent(),
            Value<String?> midtransBillerCode = const Value.absent(),
            required DateTime createdAt,
            Value<String> syncStatus = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalTransactionsCompanion.insert(
            localId: localId,
            receiptNo: receiptNo,
            companyId: companyId,
            companyName: companyName,
            storeId: storeId,
            storeName: storeName,
            totalAmount: totalAmount,
            selfiePath: selfiePath,
            receiptPath: receiptPath,
            notes: notes,
            paymentMethod: paymentMethod,
            paymentBank: paymentBank,
            midtransId: midtransId,
            midtransQrisUrl: midtransQrisUrl,
            midtransVaNumber: midtransVaNumber,
            midtransBank: midtransBank,
            midtransBillKey: midtransBillKey,
            midtransBillerCode: midtransBillerCode,
            createdAt: createdAt,
            syncStatus: syncStatus,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$LocalTransactionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({localTransactionItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (localTransactionItemsRefs) db.localTransactionItems
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (localTransactionItemsRefs)
                    await $_getPrefetchedData<LocalTransaction,
                            $LocalTransactionsTable, LocalTransactionItem>(
                        currentTable: table,
                        referencedTable: $$LocalTransactionsTableReferences
                            ._localTransactionItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LocalTransactionsTableReferences(db, table, p0)
                                .localTransactionItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems.where(
                                (e) => e.transactionLocalId == item.localId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$LocalTransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalTransactionsTable,
    LocalTransaction,
    $$LocalTransactionsTableFilterComposer,
    $$LocalTransactionsTableOrderingComposer,
    $$LocalTransactionsTableAnnotationComposer,
    $$LocalTransactionsTableCreateCompanionBuilder,
    $$LocalTransactionsTableUpdateCompanionBuilder,
    (LocalTransaction, $$LocalTransactionsTableReferences),
    LocalTransaction,
    PrefetchHooks Function({bool localTransactionItemsRefs})>;
typedef $$LocalTransactionItemsTableCreateCompanionBuilder
    = LocalTransactionItemsCompanion Function({
  Value<int> id,
  required String transactionLocalId,
  required String productId,
  required String productName,
  required int quantity,
  Value<int> orderedQuantity,
  Value<String> unit,
  Value<int> piecesPerUnit,
  required double price,
});
typedef $$LocalTransactionItemsTableUpdateCompanionBuilder
    = LocalTransactionItemsCompanion Function({
  Value<int> id,
  Value<String> transactionLocalId,
  Value<String> productId,
  Value<String> productName,
  Value<int> quantity,
  Value<int> orderedQuantity,
  Value<String> unit,
  Value<int> piecesPerUnit,
  Value<double> price,
});

final class $$LocalTransactionItemsTableReferences extends BaseReferences<
    _$AppDatabase, $LocalTransactionItemsTable, LocalTransactionItem> {
  $$LocalTransactionItemsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LocalTransactionsTable _transactionLocalIdTable(_$AppDatabase db) =>
      db.localTransactions.createAlias($_aliasNameGenerator(
          db.localTransactionItems.transactionLocalId,
          db.localTransactions.localId));

  $$LocalTransactionsTableProcessedTableManager get transactionLocalId {
    final $_column = $_itemColumn<String>('transaction_local_id')!;

    final manager =
        $$LocalTransactionsTableTableManager($_db, $_db.localTransactions)
            .filter((f) => f.localId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionLocalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LocalTransactionItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTransactionItemsTable> {
  $$LocalTransactionItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderedQuantity => $composableBuilder(
      column: $table.orderedQuantity,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get piecesPerUnit => $composableBuilder(
      column: $table.piecesPerUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  $$LocalTransactionsTableFilterComposer get transactionLocalId {
    final $$LocalTransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionLocalId,
        referencedTable: $db.localTransactions,
        getReferencedColumn: (t) => t.localId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalTransactionsTableFilterComposer(
              $db: $db,
              $table: $db.localTransactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalTransactionItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTransactionItemsTable> {
  $$LocalTransactionItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderedQuantity => $composableBuilder(
      column: $table.orderedQuantity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get piecesPerUnit => $composableBuilder(
      column: $table.piecesPerUnit,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  $$LocalTransactionsTableOrderingComposer get transactionLocalId {
    final $$LocalTransactionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionLocalId,
        referencedTable: $db.localTransactions,
        getReferencedColumn: (t) => t.localId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalTransactionsTableOrderingComposer(
              $db: $db,
              $table: $db.localTransactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalTransactionItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTransactionItemsTable> {
  $$LocalTransactionItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get orderedQuantity => $composableBuilder(
      column: $table.orderedQuantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get piecesPerUnit => $composableBuilder(
      column: $table.piecesPerUnit, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  $$LocalTransactionsTableAnnotationComposer get transactionLocalId {
    final $$LocalTransactionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.transactionLocalId,
            referencedTable: $db.localTransactions,
            getReferencedColumn: (t) => t.localId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$LocalTransactionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.localTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$LocalTransactionItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalTransactionItemsTable,
    LocalTransactionItem,
    $$LocalTransactionItemsTableFilterComposer,
    $$LocalTransactionItemsTableOrderingComposer,
    $$LocalTransactionItemsTableAnnotationComposer,
    $$LocalTransactionItemsTableCreateCompanionBuilder,
    $$LocalTransactionItemsTableUpdateCompanionBuilder,
    (LocalTransactionItem, $$LocalTransactionItemsTableReferences),
    LocalTransactionItem,
    PrefetchHooks Function({bool transactionLocalId})> {
  $$LocalTransactionItemsTableTableManager(
      _$AppDatabase db, $LocalTransactionItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTransactionItemsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTransactionItemsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTransactionItemsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> transactionLocalId = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<int> orderedQuantity = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<int> piecesPerUnit = const Value.absent(),
            Value<double> price = const Value.absent(),
          }) =>
              LocalTransactionItemsCompanion(
            id: id,
            transactionLocalId: transactionLocalId,
            productId: productId,
            productName: productName,
            quantity: quantity,
            orderedQuantity: orderedQuantity,
            unit: unit,
            piecesPerUnit: piecesPerUnit,
            price: price,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String transactionLocalId,
            required String productId,
            required String productName,
            required int quantity,
            Value<int> orderedQuantity = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<int> piecesPerUnit = const Value.absent(),
            required double price,
          }) =>
              LocalTransactionItemsCompanion.insert(
            id: id,
            transactionLocalId: transactionLocalId,
            productId: productId,
            productName: productName,
            quantity: quantity,
            orderedQuantity: orderedQuantity,
            unit: unit,
            piecesPerUnit: piecesPerUnit,
            price: price,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$LocalTransactionItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({transactionLocalId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (transactionLocalId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.transactionLocalId,
                    referencedTable: $$LocalTransactionItemsTableReferences
                        ._transactionLocalIdTable(db),
                    referencedColumn: $$LocalTransactionItemsTableReferences
                        ._transactionLocalIdTable(db)
                        .localId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LocalTransactionItemsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $LocalTransactionItemsTable,
        LocalTransactionItem,
        $$LocalTransactionItemsTableFilterComposer,
        $$LocalTransactionItemsTableOrderingComposer,
        $$LocalTransactionItemsTableAnnotationComposer,
        $$LocalTransactionItemsTableCreateCompanionBuilder,
        $$LocalTransactionItemsTableUpdateCompanionBuilder,
        (LocalTransactionItem, $$LocalTransactionItemsTableReferences),
        LocalTransactionItem,
        PrefetchHooks Function({bool transactionLocalId})>;
typedef $$SalesStockTableCreateCompanionBuilder = SalesStockCompanion Function({
  required String productId,
  required int quantity,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SalesStockTableUpdateCompanionBuilder = SalesStockCompanion Function({
  Value<String> productId,
  Value<int> quantity,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SalesStockTableFilterComposer
    extends Composer<_$AppDatabase, $SalesStockTable> {
  $$SalesStockTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SalesStockTableOrderingComposer
    extends Composer<_$AppDatabase, $SalesStockTable> {
  $$SalesStockTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SalesStockTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalesStockTable> {
  $$SalesStockTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SalesStockTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SalesStockTable,
    SalesStockData,
    $$SalesStockTableFilterComposer,
    $$SalesStockTableOrderingComposer,
    $$SalesStockTableAnnotationComposer,
    $$SalesStockTableCreateCompanionBuilder,
    $$SalesStockTableUpdateCompanionBuilder,
    (
      SalesStockData,
      BaseReferences<_$AppDatabase, $SalesStockTable, SalesStockData>
    ),
    SalesStockData,
    PrefetchHooks Function()> {
  $$SalesStockTableTableManager(_$AppDatabase db, $SalesStockTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesStockTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesStockTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesStockTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> productId = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SalesStockCompanion(
            productId: productId,
            quantity: quantity,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String productId,
            required int quantity,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SalesStockCompanion.insert(
            productId: productId,
            quantity: quantity,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SalesStockTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SalesStockTable,
    SalesStockData,
    $$SalesStockTableFilterComposer,
    $$SalesStockTableOrderingComposer,
    $$SalesStockTableAnnotationComposer,
    $$SalesStockTableCreateCompanionBuilder,
    $$SalesStockTableUpdateCompanionBuilder,
    (
      SalesStockData,
      BaseReferences<_$AppDatabase, $SalesStockTable, SalesStockData>
    ),
    SalesStockData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$CompaniesTableTableManager get companies =>
      $$CompaniesTableTableManager(_db, _db.companies);
  $$LocalCheckinsTableTableManager get localCheckins =>
      $$LocalCheckinsTableTableManager(_db, _db.localCheckins);
  $$LocalTransactionsTableTableManager get localTransactions =>
      $$LocalTransactionsTableTableManager(_db, _db.localTransactions);
  $$LocalTransactionItemsTableTableManager get localTransactionItems =>
      $$LocalTransactionItemsTableTableManager(_db, _db.localTransactionItems);
  $$SalesStockTableTableManager get salesStock =>
      $$SalesStockTableTableManager(_db, _db.salesStock);
}
