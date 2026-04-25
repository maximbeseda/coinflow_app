// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CategoryType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<CategoryType>($CategoriesTable.$convertertype);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<int> icon = GeneratedColumn<int>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bgColorMeta = const VerificationMeta(
    'bgColor',
  );
  @override
  late final GeneratedColumn<int> bgColor = GeneratedColumn<int>(
    'bg_color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconColorMeta = const VerificationMeta(
    'iconColor',
  );
  @override
  late final GeneratedColumn<int> iconColor = GeneratedColumn<int>(
    'icon_color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _budgetMeta = const VerificationMeta('budget');
  @override
  late final GeneratedColumn<int> budget = GeneratedColumn<int>(
    'budget',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('UAH'),
  );
  static const VerificationMeta _includeInTotalMeta = const VerificationMeta(
    'includeInTotal',
  );
  @override
  late final GeneratedColumn<bool> includeInTotal = GeneratedColumn<bool>(
    'include_in_total',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("include_in_total" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    name,
    icon,
    bgColor,
    iconColor,
    amount,
    budget,
    isArchived,
    currency,
    includeInTotal,
    sortOrder,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('bg_color')) {
      context.handle(
        _bgColorMeta,
        bgColor.isAcceptableOrUnknown(data['bg_color']!, _bgColorMeta),
      );
    } else if (isInserting) {
      context.missing(_bgColorMeta);
    }
    if (data.containsKey('icon_color')) {
      context.handle(
        _iconColorMeta,
        iconColor.isAcceptableOrUnknown(data['icon_color']!, _iconColorMeta),
      );
    } else if (isInserting) {
      context.missing(_iconColorMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('budget')) {
      context.handle(
        _budgetMeta,
        budget.isAcceptableOrUnknown(data['budget']!, _budgetMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('include_in_total')) {
      context.handle(
        _includeInTotalMeta,
        includeInTotal.isAcceptableOrUnknown(
          data['include_in_total']!,
          _includeInTotalMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: $CategoriesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon'],
      )!,
      bgColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bg_color'],
      )!,
      iconColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_color'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      budget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}budget'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      includeInTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}include_in_total'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CategoryType, int, int> $convertertype =
      const EnumIndexConverter<CategoryType>(CategoryType.values);
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final CategoryType type;
  final String name;
  final int icon;
  final int bgColor;
  final int iconColor;
  final int amount;
  final int? budget;
  final bool isArchived;
  final String currency;
  final bool includeInTotal;
  final int sortOrder;
  final DateTime? deletedAt;
  const Category({
    required this.id,
    required this.type,
    required this.name,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.amount,
    this.budget,
    required this.isArchived,
    required this.currency,
    required this.includeInTotal,
    required this.sortOrder,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['type'] = Variable<int>($CategoriesTable.$convertertype.toSql(type));
    }
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<int>(icon);
    map['bg_color'] = Variable<int>(bgColor);
    map['icon_color'] = Variable<int>(iconColor);
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || budget != null) {
      map['budget'] = Variable<int>(budget);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    map['currency'] = Variable<String>(currency);
    map['include_in_total'] = Variable<bool>(includeInTotal);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      type: Value(type),
      name: Value(name),
      icon: Value(icon),
      bgColor: Value(bgColor),
      iconColor: Value(iconColor),
      amount: Value(amount),
      budget: budget == null && nullToAbsent
          ? const Value.absent()
          : Value(budget),
      isArchived: Value(isArchived),
      currency: Value(currency),
      includeInTotal: Value(includeInTotal),
      sortOrder: Value(sortOrder),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      type: $CategoriesTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<int>(json['icon']),
      bgColor: serializer.fromJson<int>(json['bgColor']),
      iconColor: serializer.fromJson<int>(json['iconColor']),
      amount: serializer.fromJson<int>(json['amount']),
      budget: serializer.fromJson<int?>(json['budget']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      currency: serializer.fromJson<String>(json['currency']),
      includeInTotal: serializer.fromJson<bool>(json['includeInTotal']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<int>(
        $CategoriesTable.$convertertype.toJson(type),
      ),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<int>(icon),
      'bgColor': serializer.toJson<int>(bgColor),
      'iconColor': serializer.toJson<int>(iconColor),
      'amount': serializer.toJson<int>(amount),
      'budget': serializer.toJson<int?>(budget),
      'isArchived': serializer.toJson<bool>(isArchived),
      'currency': serializer.toJson<String>(currency),
      'includeInTotal': serializer.toJson<bool>(includeInTotal),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Category copyWith({
    String? id,
    CategoryType? type,
    String? name,
    int? icon,
    int? bgColor,
    int? iconColor,
    int? amount,
    Value<int?> budget = const Value.absent(),
    bool? isArchived,
    String? currency,
    bool? includeInTotal,
    int? sortOrder,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Category(
    id: id ?? this.id,
    type: type ?? this.type,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    bgColor: bgColor ?? this.bgColor,
    iconColor: iconColor ?? this.iconColor,
    amount: amount ?? this.amount,
    budget: budget.present ? budget.value : this.budget,
    isArchived: isArchived ?? this.isArchived,
    currency: currency ?? this.currency,
    includeInTotal: includeInTotal ?? this.includeInTotal,
    sortOrder: sortOrder ?? this.sortOrder,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      bgColor: data.bgColor.present ? data.bgColor.value : this.bgColor,
      iconColor: data.iconColor.present ? data.iconColor.value : this.iconColor,
      amount: data.amount.present ? data.amount.value : this.amount,
      budget: data.budget.present ? data.budget.value : this.budget,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      currency: data.currency.present ? data.currency.value : this.currency,
      includeInTotal: data.includeInTotal.present
          ? data.includeInTotal.value
          : this.includeInTotal,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('bgColor: $bgColor, ')
          ..write('iconColor: $iconColor, ')
          ..write('amount: $amount, ')
          ..write('budget: $budget, ')
          ..write('isArchived: $isArchived, ')
          ..write('currency: $currency, ')
          ..write('includeInTotal: $includeInTotal, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    name,
    icon,
    bgColor,
    iconColor,
    amount,
    budget,
    isArchived,
    currency,
    includeInTotal,
    sortOrder,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.type == this.type &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.bgColor == this.bgColor &&
          other.iconColor == this.iconColor &&
          other.amount == this.amount &&
          other.budget == this.budget &&
          other.isArchived == this.isArchived &&
          other.currency == this.currency &&
          other.includeInTotal == this.includeInTotal &&
          other.sortOrder == this.sortOrder &&
          other.deletedAt == this.deletedAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<CategoryType> type;
  final Value<String> name;
  final Value<int> icon;
  final Value<int> bgColor;
  final Value<int> iconColor;
  final Value<int> amount;
  final Value<int?> budget;
  final Value<bool> isArchived;
  final Value<String> currency;
  final Value<bool> includeInTotal;
  final Value<int> sortOrder;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.bgColor = const Value.absent(),
    this.iconColor = const Value.absent(),
    this.amount = const Value.absent(),
    this.budget = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.currency = const Value.absent(),
    this.includeInTotal = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required CategoryType type,
    required String name,
    required int icon,
    required int bgColor,
    required int iconColor,
    this.amount = const Value.absent(),
    this.budget = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.currency = const Value.absent(),
    this.includeInTotal = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       name = Value(name),
       icon = Value(icon),
       bgColor = Value(bgColor),
       iconColor = Value(iconColor);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<int>? type,
    Expression<String>? name,
    Expression<int>? icon,
    Expression<int>? bgColor,
    Expression<int>? iconColor,
    Expression<int>? amount,
    Expression<int>? budget,
    Expression<bool>? isArchived,
    Expression<String>? currency,
    Expression<bool>? includeInTotal,
    Expression<int>? sortOrder,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (bgColor != null) 'bg_color': bgColor,
      if (iconColor != null) 'icon_color': iconColor,
      if (amount != null) 'amount': amount,
      if (budget != null) 'budget': budget,
      if (isArchived != null) 'is_archived': isArchived,
      if (currency != null) 'currency': currency,
      if (includeInTotal != null) 'include_in_total': includeInTotal,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<CategoryType>? type,
    Value<String>? name,
    Value<int>? icon,
    Value<int>? bgColor,
    Value<int>? iconColor,
    Value<int>? amount,
    Value<int?>? budget,
    Value<bool>? isArchived,
    Value<String>? currency,
    Value<bool>? includeInTotal,
    Value<int>? sortOrder,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      bgColor: bgColor ?? this.bgColor,
      iconColor: iconColor ?? this.iconColor,
      amount: amount ?? this.amount,
      budget: budget ?? this.budget,
      isArchived: isArchived ?? this.isArchived,
      currency: currency ?? this.currency,
      includeInTotal: includeInTotal ?? this.includeInTotal,
      sortOrder: sortOrder ?? this.sortOrder,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
        $CategoriesTable.$convertertype.toSql(type.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<int>(icon.value);
    }
    if (bgColor.present) {
      map['bg_color'] = Variable<int>(bgColor.value);
    }
    if (iconColor.present) {
      map['icon_color'] = Variable<int>(iconColor.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (budget.present) {
      map['budget'] = Variable<int>(budget.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (includeInTotal.present) {
      map['include_in_total'] = Variable<bool>(includeInTotal.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('bgColor: $bgColor, ')
          ..write('iconColor: $iconColor, ')
          ..write('amount: $amount, ')
          ..write('budget: $budget, ')
          ..write('isArchived: $isArchived, ')
          ..write('currency: $currency, ')
          ..write('includeInTotal: $includeInTotal, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromIdMeta = const VerificationMeta('fromId');
  @override
  late final GeneratedColumn<String> fromId = GeneratedColumn<String>(
    'from_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toIdMeta = const VerificationMeta('toId');
  @override
  late final GeneratedColumn<String> toId = GeneratedColumn<String>(
    'to_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetAmountMeta = const VerificationMeta(
    'targetAmount',
  );
  @override
  late final GeneratedColumn<int> targetAmount = GeneratedColumn<int>(
    'target_amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetCurrencyMeta = const VerificationMeta(
    'targetCurrency',
  );
  @override
  late final GeneratedColumn<String> targetCurrency = GeneratedColumn<String>(
    'target_currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baseAmountMeta = const VerificationMeta(
    'baseAmount',
  );
  @override
  late final GeneratedColumn<int> baseAmount = GeneratedColumn<int>(
    'base_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _baseCurrencyMeta = const VerificationMeta(
    'baseCurrency',
  );
  @override
  late final GeneratedColumn<String> baseCurrency = GeneratedColumn<String>(
    'base_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fromId,
    toId,
    title,
    date,
    amount,
    currency,
    targetAmount,
    targetCurrency,
    baseAmount,
    baseCurrency,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('from_id')) {
      context.handle(
        _fromIdMeta,
        fromId.isAcceptableOrUnknown(data['from_id']!, _fromIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fromIdMeta);
    }
    if (data.containsKey('to_id')) {
      context.handle(
        _toIdMeta,
        toId.isAcceptableOrUnknown(data['to_id']!, _toIdMeta),
      );
    } else if (isInserting) {
      context.missing(_toIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('target_amount')) {
      context.handle(
        _targetAmountMeta,
        targetAmount.isAcceptableOrUnknown(
          data['target_amount']!,
          _targetAmountMeta,
        ),
      );
    }
    if (data.containsKey('target_currency')) {
      context.handle(
        _targetCurrencyMeta,
        targetCurrency.isAcceptableOrUnknown(
          data['target_currency']!,
          _targetCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('base_amount')) {
      context.handle(
        _baseAmountMeta,
        baseAmount.isAcceptableOrUnknown(data['base_amount']!, _baseAmountMeta),
      );
    }
    if (data.containsKey('base_currency')) {
      context.handle(
        _baseCurrencyMeta,
        baseCurrency.isAcceptableOrUnknown(
          data['base_currency']!,
          _baseCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseCurrencyMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fromId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_id'],
      )!,
      toId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      targetAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_amount'],
      ),
      targetCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_currency'],
      ),
      baseAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_amount'],
      )!,
      baseCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_currency'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;
  final String fromId;
  final String toId;
  final String title;
  final DateTime date;
  final int amount;
  final String currency;
  final int? targetAmount;
  final String? targetCurrency;
  final int baseAmount;
  final String baseCurrency;
  final DateTime? deletedAt;
  const Transaction({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.title,
    required this.date,
    required this.amount,
    required this.currency,
    this.targetAmount,
    this.targetCurrency,
    required this.baseAmount,
    required this.baseCurrency,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['from_id'] = Variable<String>(fromId);
    map['to_id'] = Variable<String>(toId);
    map['title'] = Variable<String>(title);
    map['date'] = Variable<DateTime>(date);
    map['amount'] = Variable<int>(amount);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || targetAmount != null) {
      map['target_amount'] = Variable<int>(targetAmount);
    }
    if (!nullToAbsent || targetCurrency != null) {
      map['target_currency'] = Variable<String>(targetCurrency);
    }
    map['base_amount'] = Variable<int>(baseAmount);
    map['base_currency'] = Variable<String>(baseCurrency);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      fromId: Value(fromId),
      toId: Value(toId),
      title: Value(title),
      date: Value(date),
      amount: Value(amount),
      currency: Value(currency),
      targetAmount: targetAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(targetAmount),
      targetCurrency: targetCurrency == null && nullToAbsent
          ? const Value.absent()
          : Value(targetCurrency),
      baseAmount: Value(baseAmount),
      baseCurrency: Value(baseCurrency),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      fromId: serializer.fromJson<String>(json['fromId']),
      toId: serializer.fromJson<String>(json['toId']),
      title: serializer.fromJson<String>(json['title']),
      date: serializer.fromJson<DateTime>(json['date']),
      amount: serializer.fromJson<int>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      targetAmount: serializer.fromJson<int?>(json['targetAmount']),
      targetCurrency: serializer.fromJson<String?>(json['targetCurrency']),
      baseAmount: serializer.fromJson<int>(json['baseAmount']),
      baseCurrency: serializer.fromJson<String>(json['baseCurrency']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fromId': serializer.toJson<String>(fromId),
      'toId': serializer.toJson<String>(toId),
      'title': serializer.toJson<String>(title),
      'date': serializer.toJson<DateTime>(date),
      'amount': serializer.toJson<int>(amount),
      'currency': serializer.toJson<String>(currency),
      'targetAmount': serializer.toJson<int?>(targetAmount),
      'targetCurrency': serializer.toJson<String?>(targetCurrency),
      'baseAmount': serializer.toJson<int>(baseAmount),
      'baseCurrency': serializer.toJson<String>(baseCurrency),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Transaction copyWith({
    String? id,
    String? fromId,
    String? toId,
    String? title,
    DateTime? date,
    int? amount,
    String? currency,
    Value<int?> targetAmount = const Value.absent(),
    Value<String?> targetCurrency = const Value.absent(),
    int? baseAmount,
    String? baseCurrency,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Transaction(
    id: id ?? this.id,
    fromId: fromId ?? this.fromId,
    toId: toId ?? this.toId,
    title: title ?? this.title,
    date: date ?? this.date,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    targetAmount: targetAmount.present ? targetAmount.value : this.targetAmount,
    targetCurrency: targetCurrency.present
        ? targetCurrency.value
        : this.targetCurrency,
    baseAmount: baseAmount ?? this.baseAmount,
    baseCurrency: baseCurrency ?? this.baseCurrency,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      fromId: data.fromId.present ? data.fromId.value : this.fromId,
      toId: data.toId.present ? data.toId.value : this.toId,
      title: data.title.present ? data.title.value : this.title,
      date: data.date.present ? data.date.value : this.date,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
      targetCurrency: data.targetCurrency.present
          ? data.targetCurrency.value
          : this.targetCurrency,
      baseAmount: data.baseAmount.present
          ? data.baseAmount.value
          : this.baseAmount,
      baseCurrency: data.baseCurrency.present
          ? data.baseCurrency.value
          : this.baseCurrency,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('fromId: $fromId, ')
          ..write('toId: $toId, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('targetCurrency: $targetCurrency, ')
          ..write('baseAmount: $baseAmount, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fromId,
    toId,
    title,
    date,
    amount,
    currency,
    targetAmount,
    targetCurrency,
    baseAmount,
    baseCurrency,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.fromId == this.fromId &&
          other.toId == this.toId &&
          other.title == this.title &&
          other.date == this.date &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.targetAmount == this.targetAmount &&
          other.targetCurrency == this.targetCurrency &&
          other.baseAmount == this.baseAmount &&
          other.baseCurrency == this.baseCurrency &&
          other.deletedAt == this.deletedAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String> fromId;
  final Value<String> toId;
  final Value<String> title;
  final Value<DateTime> date;
  final Value<int> amount;
  final Value<String> currency;
  final Value<int?> targetAmount;
  final Value<String?> targetCurrency;
  final Value<int> baseAmount;
  final Value<String> baseCurrency;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.fromId = const Value.absent(),
    this.toId = const Value.absent(),
    this.title = const Value.absent(),
    this.date = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.targetCurrency = const Value.absent(),
    this.baseAmount = const Value.absent(),
    this.baseCurrency = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String fromId,
    required String toId,
    required String title,
    required DateTime date,
    required int amount,
    required String currency,
    this.targetAmount = const Value.absent(),
    this.targetCurrency = const Value.absent(),
    this.baseAmount = const Value.absent(),
    required String baseCurrency,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fromId = Value(fromId),
       toId = Value(toId),
       title = Value(title),
       date = Value(date),
       amount = Value(amount),
       currency = Value(currency),
       baseCurrency = Value(baseCurrency);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<String>? fromId,
    Expression<String>? toId,
    Expression<String>? title,
    Expression<DateTime>? date,
    Expression<int>? amount,
    Expression<String>? currency,
    Expression<int>? targetAmount,
    Expression<String>? targetCurrency,
    Expression<int>? baseAmount,
    Expression<String>? baseCurrency,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromId != null) 'from_id': fromId,
      if (toId != null) 'to_id': toId,
      if (title != null) 'title': title,
      if (date != null) 'date': date,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (targetCurrency != null) 'target_currency': targetCurrency,
      if (baseAmount != null) 'base_amount': baseAmount,
      if (baseCurrency != null) 'base_currency': baseCurrency,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? fromId,
    Value<String>? toId,
    Value<String>? title,
    Value<DateTime>? date,
    Value<int>? amount,
    Value<String>? currency,
    Value<int?>? targetAmount,
    Value<String?>? targetCurrency,
    Value<int>? baseAmount,
    Value<String>? baseCurrency,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      title: title ?? this.title,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      targetAmount: targetAmount ?? this.targetAmount,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      baseAmount: baseAmount ?? this.baseAmount,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fromId.present) {
      map['from_id'] = Variable<String>(fromId.value);
    }
    if (toId.present) {
      map['to_id'] = Variable<String>(toId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<int>(targetAmount.value);
    }
    if (targetCurrency.present) {
      map['target_currency'] = Variable<String>(targetCurrency.value);
    }
    if (baseAmount.present) {
      map['base_amount'] = Variable<int>(baseAmount.value);
    }
    if (baseCurrency.present) {
      map['base_currency'] = Variable<String>(baseCurrency.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('fromId: $fromId, ')
          ..write('toId: $toId, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('targetCurrency: $targetCurrency, ')
          ..write('baseAmount: $baseAmount, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubscriptionsTable extends Subscriptions
    with TableInfo<$SubscriptionsTable, Subscription> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextPaymentDateMeta = const VerificationMeta(
    'nextPaymentDate',
  );
  @override
  late final GeneratedColumn<DateTime> nextPaymentDate =
      GeneratedColumn<DateTime>(
        'next_payment_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _periodicityMeta = const VerificationMeta(
    'periodicity',
  );
  @override
  late final GeneratedColumn<String> periodicity = GeneratedColumn<String>(
    'periodicity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('monthly'),
  );
  static const VerificationMeta _customIconCodePointMeta =
      const VerificationMeta('customIconCodePoint');
  @override
  late final GeneratedColumn<int> customIconCodePoint = GeneratedColumn<int>(
    'custom_icon_code_point',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAutoPayMeta = const VerificationMeta(
    'isAutoPay',
  );
  @override
  late final GeneratedColumn<bool> isAutoPay = GeneratedColumn<bool>(
    'is_auto_pay',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_auto_pay" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('UAH'),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    amount,
    categoryId,
    accountId,
    nextPaymentDate,
    periodicity,
    customIconCodePoint,
    isAutoPay,
    currency,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subscription> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('next_payment_date')) {
      context.handle(
        _nextPaymentDateMeta,
        nextPaymentDate.isAcceptableOrUnknown(
          data['next_payment_date']!,
          _nextPaymentDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextPaymentDateMeta);
    }
    if (data.containsKey('periodicity')) {
      context.handle(
        _periodicityMeta,
        periodicity.isAcceptableOrUnknown(
          data['periodicity']!,
          _periodicityMeta,
        ),
      );
    }
    if (data.containsKey('custom_icon_code_point')) {
      context.handle(
        _customIconCodePointMeta,
        customIconCodePoint.isAcceptableOrUnknown(
          data['custom_icon_code_point']!,
          _customIconCodePointMeta,
        ),
      );
    }
    if (data.containsKey('is_auto_pay')) {
      context.handle(
        _isAutoPayMeta,
        isAutoPay.isAcceptableOrUnknown(data['is_auto_pay']!, _isAutoPayMeta),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subscription map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subscription(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      nextPaymentDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_payment_date'],
      )!,
      periodicity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}periodicity'],
      )!,
      customIconCodePoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}custom_icon_code_point'],
      ),
      isAutoPay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_auto_pay'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $SubscriptionsTable createAlias(String alias) {
    return $SubscriptionsTable(attachedDatabase, alias);
  }
}

class Subscription extends DataClass implements Insertable<Subscription> {
  final String id;
  final String name;
  final int amount;
  final String categoryId;
  final String accountId;
  final DateTime nextPaymentDate;
  final String periodicity;
  final int? customIconCodePoint;
  final bool isAutoPay;
  final String currency;
  final DateTime? deletedAt;
  const Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    required this.nextPaymentDate,
    required this.periodicity,
    this.customIconCodePoint,
    required this.isAutoPay,
    required this.currency,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<int>(amount);
    map['category_id'] = Variable<String>(categoryId);
    map['account_id'] = Variable<String>(accountId);
    map['next_payment_date'] = Variable<DateTime>(nextPaymentDate);
    map['periodicity'] = Variable<String>(periodicity);
    if (!nullToAbsent || customIconCodePoint != null) {
      map['custom_icon_code_point'] = Variable<int>(customIconCodePoint);
    }
    map['is_auto_pay'] = Variable<bool>(isAutoPay);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  SubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionsCompanion(
      id: Value(id),
      name: Value(name),
      amount: Value(amount),
      categoryId: Value(categoryId),
      accountId: Value(accountId),
      nextPaymentDate: Value(nextPaymentDate),
      periodicity: Value(periodicity),
      customIconCodePoint: customIconCodePoint == null && nullToAbsent
          ? const Value.absent()
          : Value(customIconCodePoint),
      isAutoPay: Value(isAutoPay),
      currency: Value(currency),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Subscription.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subscription(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<int>(json['amount']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      nextPaymentDate: serializer.fromJson<DateTime>(json['nextPaymentDate']),
      periodicity: serializer.fromJson<String>(json['periodicity']),
      customIconCodePoint: serializer.fromJson<int?>(
        json['customIconCodePoint'],
      ),
      isAutoPay: serializer.fromJson<bool>(json['isAutoPay']),
      currency: serializer.fromJson<String>(json['currency']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<int>(amount),
      'categoryId': serializer.toJson<String>(categoryId),
      'accountId': serializer.toJson<String>(accountId),
      'nextPaymentDate': serializer.toJson<DateTime>(nextPaymentDate),
      'periodicity': serializer.toJson<String>(periodicity),
      'customIconCodePoint': serializer.toJson<int?>(customIconCodePoint),
      'isAutoPay': serializer.toJson<bool>(isAutoPay),
      'currency': serializer.toJson<String>(currency),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Subscription copyWith({
    String? id,
    String? name,
    int? amount,
    String? categoryId,
    String? accountId,
    DateTime? nextPaymentDate,
    String? periodicity,
    Value<int?> customIconCodePoint = const Value.absent(),
    bool? isAutoPay,
    String? currency,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Subscription(
    id: id ?? this.id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    categoryId: categoryId ?? this.categoryId,
    accountId: accountId ?? this.accountId,
    nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
    periodicity: periodicity ?? this.periodicity,
    customIconCodePoint: customIconCodePoint.present
        ? customIconCodePoint.value
        : this.customIconCodePoint,
    isAutoPay: isAutoPay ?? this.isAutoPay,
    currency: currency ?? this.currency,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Subscription copyWithCompanion(SubscriptionsCompanion data) {
    return Subscription(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      nextPaymentDate: data.nextPaymentDate.present
          ? data.nextPaymentDate.value
          : this.nextPaymentDate,
      periodicity: data.periodicity.present
          ? data.periodicity.value
          : this.periodicity,
      customIconCodePoint: data.customIconCodePoint.present
          ? data.customIconCodePoint.value
          : this.customIconCodePoint,
      isAutoPay: data.isAutoPay.present ? data.isAutoPay.value : this.isAutoPay,
      currency: data.currency.present ? data.currency.value : this.currency,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subscription(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('nextPaymentDate: $nextPaymentDate, ')
          ..write('periodicity: $periodicity, ')
          ..write('customIconCodePoint: $customIconCodePoint, ')
          ..write('isAutoPay: $isAutoPay, ')
          ..write('currency: $currency, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    amount,
    categoryId,
    accountId,
    nextPaymentDate,
    periodicity,
    customIconCodePoint,
    isAutoPay,
    currency,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subscription &&
          other.id == this.id &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.categoryId == this.categoryId &&
          other.accountId == this.accountId &&
          other.nextPaymentDate == this.nextPaymentDate &&
          other.periodicity == this.periodicity &&
          other.customIconCodePoint == this.customIconCodePoint &&
          other.isAutoPay == this.isAutoPay &&
          other.currency == this.currency &&
          other.deletedAt == this.deletedAt);
}

class SubscriptionsCompanion extends UpdateCompanion<Subscription> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> amount;
  final Value<String> categoryId;
  final Value<String> accountId;
  final Value<DateTime> nextPaymentDate;
  final Value<String> periodicity;
  final Value<int?> customIconCodePoint;
  final Value<bool> isAutoPay;
  final Value<String> currency;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const SubscriptionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.nextPaymentDate = const Value.absent(),
    this.periodicity = const Value.absent(),
    this.customIconCodePoint = const Value.absent(),
    this.isAutoPay = const Value.absent(),
    this.currency = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubscriptionsCompanion.insert({
    required String id,
    required String name,
    required int amount,
    required String categoryId,
    required String accountId,
    required DateTime nextPaymentDate,
    this.periodicity = const Value.absent(),
    this.customIconCodePoint = const Value.absent(),
    this.isAutoPay = const Value.absent(),
    this.currency = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       amount = Value(amount),
       categoryId = Value(categoryId),
       accountId = Value(accountId),
       nextPaymentDate = Value(nextPaymentDate);
  static Insertable<Subscription> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? amount,
    Expression<String>? categoryId,
    Expression<String>? accountId,
    Expression<DateTime>? nextPaymentDate,
    Expression<String>? periodicity,
    Expression<int>? customIconCodePoint,
    Expression<bool>? isAutoPay,
    Expression<String>? currency,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (nextPaymentDate != null) 'next_payment_date': nextPaymentDate,
      if (periodicity != null) 'periodicity': periodicity,
      if (customIconCodePoint != null)
        'custom_icon_code_point': customIconCodePoint,
      if (isAutoPay != null) 'is_auto_pay': isAutoPay,
      if (currency != null) 'currency': currency,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubscriptionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? amount,
    Value<String>? categoryId,
    Value<String>? accountId,
    Value<DateTime>? nextPaymentDate,
    Value<String>? periodicity,
    Value<int?>? customIconCodePoint,
    Value<bool>? isAutoPay,
    Value<String>? currency,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return SubscriptionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      periodicity: periodicity ?? this.periodicity,
      customIconCodePoint: customIconCodePoint ?? this.customIconCodePoint,
      isAutoPay: isAutoPay ?? this.isAutoPay,
      currency: currency ?? this.currency,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (nextPaymentDate.present) {
      map['next_payment_date'] = Variable<DateTime>(nextPaymentDate.value);
    }
    if (periodicity.present) {
      map['periodicity'] = Variable<String>(periodicity.value);
    }
    if (customIconCodePoint.present) {
      map['custom_icon_code_point'] = Variable<int>(customIconCodePoint.value);
    }
    if (isAutoPay.present) {
      map['is_auto_pay'] = Variable<bool>(isAutoPay.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('nextPaymentDate: $nextPaymentDate, ')
          ..write('periodicity: $periodicity, ')
          ..write('customIconCodePoint: $customIconCodePoint, ')
          ..write('isAutoPay: $isAutoPay, ')
          ..write('currency: $currency, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $SubscriptionsTable subscriptions = $SubscriptionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    transactions,
    subscriptions,
  ];
}

typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      required CategoryType type,
      required String name,
      required int icon,
      required int bgColor,
      required int iconColor,
      Value<int> amount,
      Value<int?> budget,
      Value<bool> isArchived,
      Value<String> currency,
      Value<bool> includeInTotal,
      Value<int> sortOrder,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<CategoryType> type,
      Value<String> name,
      Value<int> icon,
      Value<int> bgColor,
      Value<int> iconColor,
      Value<int> amount,
      Value<int?> budget,
      Value<bool> isArchived,
      Value<String> currency,
      Value<bool> includeInTotal,
      Value<int> sortOrder,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CategoryType, CategoryType, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bgColor => $composableBuilder(
    column: $table.bgColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iconColor => $composableBuilder(
    column: $table.iconColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get budget => $composableBuilder(
    column: $table.budget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get includeInTotal => $composableBuilder(
    column: $table.includeInTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bgColor => $composableBuilder(
    column: $table.bgColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iconColor => $composableBuilder(
    column: $table.iconColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get budget => $composableBuilder(
    column: $table.budget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get includeInTotal => $composableBuilder(
    column: $table.includeInTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CategoryType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get bgColor =>
      $composableBuilder(column: $table.bgColor, builder: (column) => column);

  GeneratedColumn<int> get iconColor =>
      $composableBuilder(column: $table.iconColor, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get budget =>
      $composableBuilder(column: $table.budget, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<bool> get includeInTotal => $composableBuilder(
    column: $table.includeInTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
          Category,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<CategoryType> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> icon = const Value.absent(),
                Value<int> bgColor = const Value.absent(),
                Value<int> iconColor = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int?> budget = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<bool> includeInTotal = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                type: type,
                name: name,
                icon: icon,
                bgColor: bgColor,
                iconColor: iconColor,
                amount: amount,
                budget: budget,
                isArchived: isArchived,
                currency: currency,
                includeInTotal: includeInTotal,
                sortOrder: sortOrder,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required CategoryType type,
                required String name,
                required int icon,
                required int bgColor,
                required int iconColor,
                Value<int> amount = const Value.absent(),
                Value<int?> budget = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<bool> includeInTotal = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                type: type,
                name: name,
                icon: icon,
                bgColor: bgColor,
                iconColor: iconColor,
                amount: amount,
                budget: budget,
                isArchived: isArchived,
                currency: currency,
                includeInTotal: includeInTotal,
                sortOrder: sortOrder,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
      Category,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String fromId,
      required String toId,
      required String title,
      required DateTime date,
      required int amount,
      required String currency,
      Value<int?> targetAmount,
      Value<String?> targetCurrency,
      Value<int> baseAmount,
      required String baseCurrency,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> fromId,
      Value<String> toId,
      Value<String> title,
      Value<DateTime> date,
      Value<int> amount,
      Value<String> currency,
      Value<int?> targetAmount,
      Value<String?> targetCurrency,
      Value<int> baseAmount,
      Value<String> baseCurrency,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromId => $composableBuilder(
    column: $table.fromId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toId => $composableBuilder(
    column: $table.toId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetCurrency => $composableBuilder(
    column: $table.targetCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseAmount => $composableBuilder(
    column: $table.baseAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromId => $composableBuilder(
    column: $table.fromId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toId => $composableBuilder(
    column: $table.toId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetCurrency => $composableBuilder(
    column: $table.targetCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseAmount => $composableBuilder(
    column: $table.baseAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fromId =>
      $composableBuilder(column: $table.fromId, builder: (column) => column);

  GeneratedColumn<String> get toId =>
      $composableBuilder(column: $table.toId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetCurrency => $composableBuilder(
    column: $table.targetCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baseAmount => $composableBuilder(
    column: $table.baseAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            Transaction,
            BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
          ),
          Transaction,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fromId = const Value.absent(),
                Value<String> toId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int?> targetAmount = const Value.absent(),
                Value<String?> targetCurrency = const Value.absent(),
                Value<int> baseAmount = const Value.absent(),
                Value<String> baseCurrency = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                fromId: fromId,
                toId: toId,
                title: title,
                date: date,
                amount: amount,
                currency: currency,
                targetAmount: targetAmount,
                targetCurrency: targetCurrency,
                baseAmount: baseAmount,
                baseCurrency: baseCurrency,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String fromId,
                required String toId,
                required String title,
                required DateTime date,
                required int amount,
                required String currency,
                Value<int?> targetAmount = const Value.absent(),
                Value<String?> targetCurrency = const Value.absent(),
                Value<int> baseAmount = const Value.absent(),
                required String baseCurrency,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                fromId: fromId,
                toId: toId,
                title: title,
                date: date,
                amount: amount,
                currency: currency,
                targetAmount: targetAmount,
                targetCurrency: targetCurrency,
                baseAmount: baseAmount,
                baseCurrency: baseCurrency,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        Transaction,
        BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
      ),
      Transaction,
      PrefetchHooks Function()
    >;
typedef $$SubscriptionsTableCreateCompanionBuilder =
    SubscriptionsCompanion Function({
      required String id,
      required String name,
      required int amount,
      required String categoryId,
      required String accountId,
      required DateTime nextPaymentDate,
      Value<String> periodicity,
      Value<int?> customIconCodePoint,
      Value<bool> isAutoPay,
      Value<String> currency,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$SubscriptionsTableUpdateCompanionBuilder =
    SubscriptionsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> amount,
      Value<String> categoryId,
      Value<String> accountId,
      Value<DateTime> nextPaymentDate,
      Value<String> periodicity,
      Value<int?> customIconCodePoint,
      Value<bool> isAutoPay,
      Value<String> currency,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$SubscriptionsTableFilterComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextPaymentDate => $composableBuilder(
    column: $table.nextPaymentDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodicity => $composableBuilder(
    column: $table.periodicity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get customIconCodePoint => $composableBuilder(
    column: $table.customIconCodePoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAutoPay => $composableBuilder(
    column: $table.isAutoPay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubscriptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextPaymentDate => $composableBuilder(
    column: $table.nextPaymentDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodicity => $composableBuilder(
    column: $table.periodicity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get customIconCodePoint => $composableBuilder(
    column: $table.customIconCodePoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAutoPay => $composableBuilder(
    column: $table.isAutoPay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubscriptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableAnnotationComposer({
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

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<DateTime> get nextPaymentDate => $composableBuilder(
    column: $table.nextPaymentDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get periodicity => $composableBuilder(
    column: $table.periodicity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get customIconCodePoint => $composableBuilder(
    column: $table.customIconCodePoint,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAutoPay =>
      $composableBuilder(column: $table.isAutoPay, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$SubscriptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubscriptionsTable,
          Subscription,
          $$SubscriptionsTableFilterComposer,
          $$SubscriptionsTableOrderingComposer,
          $$SubscriptionsTableAnnotationComposer,
          $$SubscriptionsTableCreateCompanionBuilder,
          $$SubscriptionsTableUpdateCompanionBuilder,
          (
            Subscription,
            BaseReferences<_$AppDatabase, $SubscriptionsTable, Subscription>,
          ),
          Subscription,
          PrefetchHooks Function()
        > {
  $$SubscriptionsTableTableManager(_$AppDatabase db, $SubscriptionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubscriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubscriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubscriptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<DateTime> nextPaymentDate = const Value.absent(),
                Value<String> periodicity = const Value.absent(),
                Value<int?> customIconCodePoint = const Value.absent(),
                Value<bool> isAutoPay = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionsCompanion(
                id: id,
                name: name,
                amount: amount,
                categoryId: categoryId,
                accountId: accountId,
                nextPaymentDate: nextPaymentDate,
                periodicity: periodicity,
                customIconCodePoint: customIconCodePoint,
                isAutoPay: isAutoPay,
                currency: currency,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int amount,
                required String categoryId,
                required String accountId,
                required DateTime nextPaymentDate,
                Value<String> periodicity = const Value.absent(),
                Value<int?> customIconCodePoint = const Value.absent(),
                Value<bool> isAutoPay = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionsCompanion.insert(
                id: id,
                name: name,
                amount: amount,
                categoryId: categoryId,
                accountId: accountId,
                nextPaymentDate: nextPaymentDate,
                periodicity: periodicity,
                customIconCodePoint: customIconCodePoint,
                isAutoPay: isAutoPay,
                currency: currency,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubscriptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubscriptionsTable,
      Subscription,
      $$SubscriptionsTableFilterComposer,
      $$SubscriptionsTableOrderingComposer,
      $$SubscriptionsTableAnnotationComposer,
      $$SubscriptionsTableCreateCompanionBuilder,
      $$SubscriptionsTableUpdateCompanionBuilder,
      (
        Subscription,
        BaseReferences<_$AppDatabase, $SubscriptionsTable, Subscription>,
      ),
      Subscription,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$SubscriptionsTableTableManager get subscriptions =>
      $$SubscriptionsTableTableManager(_db, _db.subscriptions);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appDatabase)
const appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  const AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'0ce68e34f9025c8885fac780bfabfdf936fe3bc7';
