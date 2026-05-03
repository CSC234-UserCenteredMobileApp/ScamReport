// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CacheEntriesTable extends CacheEntries
    with TableInfo<$CacheEntriesTable, CacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value, expiresAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_entries';
  @override
  VerificationContext validateIntegrity(Insertable<CacheEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
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
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  CacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheEntry(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CacheEntriesTable createAlias(String alias) {
    return $CacheEntriesTable(attachedDatabase, alias);
  }
}

class CacheEntry extends DataClass implements Insertable<CacheEntry> {
  final String key;
  final String value;
  final DateTime? expiresAt;
  final DateTime updatedAt;
  const CacheEntry(
      {required this.key,
      required this.value,
      this.expiresAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return CacheEntriesCompanion(
      key: Value(key),
      value: Value(value),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CacheEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CacheEntry copyWith(
          {String? key,
          String? value,
          Value<DateTime?> expiresAt = const Value.absent(),
          DateTime? updatedAt}) =>
      CacheEntry(
        key: key ?? this.key,
        value: value ?? this.value,
        expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CacheEntry copyWithCompanion(CacheEntriesCompanion data) {
    return CacheEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheEntry(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, expiresAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheEntry &&
          other.key == this.key &&
          other.value == this.value &&
          other.expiresAt == this.expiresAt &&
          other.updatedAt == this.updatedAt);
}

class CacheEntriesCompanion extends UpdateCompanion<CacheEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime?> expiresAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CacheEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheEntriesCompanion.insert({
    required String key,
    required String value,
    this.expiresAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value),
        updatedAt = Value(updatedAt);
  static Insertable<CacheEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheEntriesCompanion copyWith(
      {Value<String>? key,
      Value<String>? value,
      Value<DateTime?>? expiresAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CacheEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      expiresAt: expiresAt ?? this.expiresAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
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
    return (StringBuffer('CacheEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DraftsTable extends Drafts with TableInfo<$DraftsTable, Draft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, type, payload, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drafts';
  @override
  VerificationContext validateIntegrity(Insertable<Draft> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Draft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Draft(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DraftsTable createAlias(String alias) {
    return $DraftsTable(attachedDatabase, alias);
  }
}

class Draft extends DataClass implements Insertable<Draft> {
  final int id;
  final String type;
  final String payload;
  final DateTime updatedAt;
  const Draft(
      {required this.id,
      required this.type,
      required this.payload,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DraftsCompanion toCompanion(bool nullToAbsent) {
    return DraftsCompanion(
      id: Value(id),
      type: Value(type),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
    );
  }

  factory Draft.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Draft(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Draft copyWith(
          {int? id, String? type, String? payload, DateTime? updatedAt}) =>
      Draft(
        id: id ?? this.id,
        type: type ?? this.type,
        payload: payload ?? this.payload,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Draft copyWithCompanion(DraftsCompanion data) {
    return Draft(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Draft(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, payload, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Draft &&
          other.id == this.id &&
          other.type == this.type &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt);
}

class DraftsCompanion extends UpdateCompanion<Draft> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  const DraftsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DraftsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String payload,
    required DateTime updatedAt,
  })  : type = Value(type),
        payload = Value(payload),
        updatedAt = Value(updatedAt);
  static Insertable<Draft> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DraftsCompanion copyWith(
      {Value<int>? id,
      Value<String>? type,
      Value<String>? payload,
      Value<DateTime>? updatedAt}) {
    return DraftsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SmsAlertsTable extends SmsAlerts
    with TableInfo<$SmsAlertsTable, SmsAlert> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmsAlertsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _senderMaskedMeta =
      const VerificationMeta('senderMasked');
  @override
  late final GeneratedColumn<String> senderMasked = GeneratedColumn<String>(
      'sender_masked', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyExcerptMeta =
      const VerificationMeta('bodyExcerpt');
  @override
  late final GeneratedColumn<String> bodyExcerpt = GeneratedColumn<String>(
      'body_excerpt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _verdictMeta =
      const VerificationMeta('verdict');
  @override
  late final GeneratedColumn<String> verdict = GeneratedColumn<String>(
      'verdict', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _detectedAtMeta =
      const VerificationMeta('detectedAt');
  @override
  late final GeneratedColumn<DateTime> detectedAt = GeneratedColumn<DateTime>(
      'detected_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, senderMasked, bodyExcerpt, verdict, detectedAt, isRead];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sms_alerts';
  @override
  VerificationContext validateIntegrity(Insertable<SmsAlert> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sender_masked')) {
      context.handle(
          _senderMaskedMeta,
          senderMasked.isAcceptableOrUnknown(
              data['sender_masked']!, _senderMaskedMeta));
    } else if (isInserting) {
      context.missing(_senderMaskedMeta);
    }
    if (data.containsKey('body_excerpt')) {
      context.handle(
          _bodyExcerptMeta,
          bodyExcerpt.isAcceptableOrUnknown(
              data['body_excerpt']!, _bodyExcerptMeta));
    } else if (isInserting) {
      context.missing(_bodyExcerptMeta);
    }
    if (data.containsKey('verdict')) {
      context.handle(_verdictMeta,
          verdict.isAcceptableOrUnknown(data['verdict']!, _verdictMeta));
    } else if (isInserting) {
      context.missing(_verdictMeta);
    }
    if (data.containsKey('detected_at')) {
      context.handle(
          _detectedAtMeta,
          detectedAt.isAcceptableOrUnknown(
              data['detected_at']!, _detectedAtMeta));
    } else if (isInserting) {
      context.missing(_detectedAtMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SmsAlert map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmsAlert(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      senderMasked: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_masked'])!,
      bodyExcerpt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body_excerpt'])!,
      verdict: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}verdict'])!,
      detectedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}detected_at'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
    );
  }

  @override
  $SmsAlertsTable createAlias(String alias) {
    return $SmsAlertsTable(attachedDatabase, alias);
  }
}

class SmsAlert extends DataClass implements Insertable<SmsAlert> {
  final int id;
  final String senderMasked;
  final String bodyExcerpt;
  final String verdict;
  final DateTime detectedAt;
  final bool isRead;
  const SmsAlert(
      {required this.id,
      required this.senderMasked,
      required this.bodyExcerpt,
      required this.verdict,
      required this.detectedAt,
      required this.isRead});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sender_masked'] = Variable<String>(senderMasked);
    map['body_excerpt'] = Variable<String>(bodyExcerpt);
    map['verdict'] = Variable<String>(verdict);
    map['detected_at'] = Variable<DateTime>(detectedAt);
    map['is_read'] = Variable<bool>(isRead);
    return map;
  }

  SmsAlertsCompanion toCompanion(bool nullToAbsent) {
    return SmsAlertsCompanion(
      id: Value(id),
      senderMasked: Value(senderMasked),
      bodyExcerpt: Value(bodyExcerpt),
      verdict: Value(verdict),
      detectedAt: Value(detectedAt),
      isRead: Value(isRead),
    );
  }

  factory SmsAlert.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmsAlert(
      id: serializer.fromJson<int>(json['id']),
      senderMasked: serializer.fromJson<String>(json['senderMasked']),
      bodyExcerpt: serializer.fromJson<String>(json['bodyExcerpt']),
      verdict: serializer.fromJson<String>(json['verdict']),
      detectedAt: serializer.fromJson<DateTime>(json['detectedAt']),
      isRead: serializer.fromJson<bool>(json['isRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'senderMasked': serializer.toJson<String>(senderMasked),
      'bodyExcerpt': serializer.toJson<String>(bodyExcerpt),
      'verdict': serializer.toJson<String>(verdict),
      'detectedAt': serializer.toJson<DateTime>(detectedAt),
      'isRead': serializer.toJson<bool>(isRead),
    };
  }

  SmsAlert copyWith(
          {int? id,
          String? senderMasked,
          String? bodyExcerpt,
          String? verdict,
          DateTime? detectedAt,
          bool? isRead}) =>
      SmsAlert(
        id: id ?? this.id,
        senderMasked: senderMasked ?? this.senderMasked,
        bodyExcerpt: bodyExcerpt ?? this.bodyExcerpt,
        verdict: verdict ?? this.verdict,
        detectedAt: detectedAt ?? this.detectedAt,
        isRead: isRead ?? this.isRead,
      );
  SmsAlert copyWithCompanion(SmsAlertsCompanion data) {
    return SmsAlert(
      id: data.id.present ? data.id.value : this.id,
      senderMasked: data.senderMasked.present
          ? data.senderMasked.value
          : this.senderMasked,
      bodyExcerpt:
          data.bodyExcerpt.present ? data.bodyExcerpt.value : this.bodyExcerpt,
      verdict: data.verdict.present ? data.verdict.value : this.verdict,
      detectedAt:
          data.detectedAt.present ? data.detectedAt.value : this.detectedAt,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmsAlert(')
          ..write('id: $id, ')
          ..write('senderMasked: $senderMasked, ')
          ..write('bodyExcerpt: $bodyExcerpt, ')
          ..write('verdict: $verdict, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('isRead: $isRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, senderMasked, bodyExcerpt, verdict, detectedAt, isRead);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmsAlert &&
          other.id == this.id &&
          other.senderMasked == this.senderMasked &&
          other.bodyExcerpt == this.bodyExcerpt &&
          other.verdict == this.verdict &&
          other.detectedAt == this.detectedAt &&
          other.isRead == this.isRead);
}

class SmsAlertsCompanion extends UpdateCompanion<SmsAlert> {
  final Value<int> id;
  final Value<String> senderMasked;
  final Value<String> bodyExcerpt;
  final Value<String> verdict;
  final Value<DateTime> detectedAt;
  final Value<bool> isRead;
  const SmsAlertsCompanion({
    this.id = const Value.absent(),
    this.senderMasked = const Value.absent(),
    this.bodyExcerpt = const Value.absent(),
    this.verdict = const Value.absent(),
    this.detectedAt = const Value.absent(),
    this.isRead = const Value.absent(),
  });
  SmsAlertsCompanion.insert({
    this.id = const Value.absent(),
    required String senderMasked,
    required String bodyExcerpt,
    required String verdict,
    required DateTime detectedAt,
    this.isRead = const Value.absent(),
  })  : senderMasked = Value(senderMasked),
        bodyExcerpt = Value(bodyExcerpt),
        verdict = Value(verdict),
        detectedAt = Value(detectedAt);
  static Insertable<SmsAlert> custom({
    Expression<int>? id,
    Expression<String>? senderMasked,
    Expression<String>? bodyExcerpt,
    Expression<String>? verdict,
    Expression<DateTime>? detectedAt,
    Expression<bool>? isRead,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (senderMasked != null) 'sender_masked': senderMasked,
      if (bodyExcerpt != null) 'body_excerpt': bodyExcerpt,
      if (verdict != null) 'verdict': verdict,
      if (detectedAt != null) 'detected_at': detectedAt,
      if (isRead != null) 'is_read': isRead,
    });
  }

  SmsAlertsCompanion copyWith(
      {Value<int>? id,
      Value<String>? senderMasked,
      Value<String>? bodyExcerpt,
      Value<String>? verdict,
      Value<DateTime>? detectedAt,
      Value<bool>? isRead}) {
    return SmsAlertsCompanion(
      id: id ?? this.id,
      senderMasked: senderMasked ?? this.senderMasked,
      bodyExcerpt: bodyExcerpt ?? this.bodyExcerpt,
      verdict: verdict ?? this.verdict,
      detectedAt: detectedAt ?? this.detectedAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (senderMasked.present) {
      map['sender_masked'] = Variable<String>(senderMasked.value);
    }
    if (bodyExcerpt.present) {
      map['body_excerpt'] = Variable<String>(bodyExcerpt.value);
    }
    if (verdict.present) {
      map['verdict'] = Variable<String>(verdict.value);
    }
    if (detectedAt.present) {
      map['detected_at'] = Variable<DateTime>(detectedAt.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmsAlertsCompanion(')
          ..write('id: $id, ')
          ..write('senderMasked: $senderMasked, ')
          ..write('bodyExcerpt: $bodyExcerpt, ')
          ..write('verdict: $verdict, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('isRead: $isRead')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CacheEntriesTable cacheEntries = $CacheEntriesTable(this);
  late final $DraftsTable drafts = $DraftsTable(this);
  late final $SmsAlertsTable smsAlerts = $SmsAlertsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [cacheEntries, drafts, smsAlerts];
}

typedef $$CacheEntriesTableCreateCompanionBuilder = CacheEntriesCompanion
    Function({
  required String key,
  required String value,
  Value<DateTime?> expiresAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CacheEntriesTableUpdateCompanionBuilder = CacheEntriesCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<DateTime?> expiresAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$CacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CacheEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CacheEntriesTable,
    CacheEntry,
    $$CacheEntriesTableFilterComposer,
    $$CacheEntriesTableOrderingComposer,
    $$CacheEntriesTableAnnotationComposer,
    $$CacheEntriesTableCreateCompanionBuilder,
    $$CacheEntriesTableUpdateCompanionBuilder,
    (CacheEntry, BaseReferences<_$AppDatabase, $CacheEntriesTable, CacheEntry>),
    CacheEntry,
    PrefetchHooks Function()> {
  $$CacheEntriesTableTableManager(_$AppDatabase db, $CacheEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CacheEntriesCompanion(
            key: key,
            value: value,
            expiresAt: expiresAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<DateTime?> expiresAt = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CacheEntriesCompanion.insert(
            key: key,
            value: value,
            expiresAt: expiresAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CacheEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CacheEntriesTable,
    CacheEntry,
    $$CacheEntriesTableFilterComposer,
    $$CacheEntriesTableOrderingComposer,
    $$CacheEntriesTableAnnotationComposer,
    $$CacheEntriesTableCreateCompanionBuilder,
    $$CacheEntriesTableUpdateCompanionBuilder,
    (CacheEntry, BaseReferences<_$AppDatabase, $CacheEntriesTable, CacheEntry>),
    CacheEntry,
    PrefetchHooks Function()>;
typedef $$DraftsTableCreateCompanionBuilder = DraftsCompanion Function({
  Value<int> id,
  required String type,
  required String payload,
  required DateTime updatedAt,
});
typedef $$DraftsTableUpdateCompanionBuilder = DraftsCompanion Function({
  Value<int> id,
  Value<String> type,
  Value<String> payload,
  Value<DateTime> updatedAt,
});

class $$DraftsTableFilterComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DraftsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DraftsTable,
    Draft,
    $$DraftsTableFilterComposer,
    $$DraftsTableOrderingComposer,
    $$DraftsTableAnnotationComposer,
    $$DraftsTableCreateCompanionBuilder,
    $$DraftsTableUpdateCompanionBuilder,
    (Draft, BaseReferences<_$AppDatabase, $DraftsTable, Draft>),
    Draft,
    PrefetchHooks Function()> {
  $$DraftsTableTableManager(_$AppDatabase db, $DraftsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              DraftsCompanion(
            id: id,
            type: type,
            payload: payload,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String type,
            required String payload,
            required DateTime updatedAt,
          }) =>
              DraftsCompanion.insert(
            id: id,
            type: type,
            payload: payload,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DraftsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DraftsTable,
    Draft,
    $$DraftsTableFilterComposer,
    $$DraftsTableOrderingComposer,
    $$DraftsTableAnnotationComposer,
    $$DraftsTableCreateCompanionBuilder,
    $$DraftsTableUpdateCompanionBuilder,
    (Draft, BaseReferences<_$AppDatabase, $DraftsTable, Draft>),
    Draft,
    PrefetchHooks Function()>;
typedef $$SmsAlertsTableCreateCompanionBuilder = SmsAlertsCompanion Function({
  Value<int> id,
  required String senderMasked,
  required String bodyExcerpt,
  required String verdict,
  required DateTime detectedAt,
  Value<bool> isRead,
});
typedef $$SmsAlertsTableUpdateCompanionBuilder = SmsAlertsCompanion Function({
  Value<int> id,
  Value<String> senderMasked,
  Value<String> bodyExcerpt,
  Value<String> verdict,
  Value<DateTime> detectedAt,
  Value<bool> isRead,
});

class $$SmsAlertsTableFilterComposer
    extends Composer<_$AppDatabase, $SmsAlertsTable> {
  $$SmsAlertsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get senderMasked => $composableBuilder(
      column: $table.senderMasked, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bodyExcerpt => $composableBuilder(
      column: $table.bodyExcerpt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get verdict => $composableBuilder(
      column: $table.verdict, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get detectedAt => $composableBuilder(
      column: $table.detectedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnFilters(column));
}

class $$SmsAlertsTableOrderingComposer
    extends Composer<_$AppDatabase, $SmsAlertsTable> {
  $$SmsAlertsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get senderMasked => $composableBuilder(
      column: $table.senderMasked,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bodyExcerpt => $composableBuilder(
      column: $table.bodyExcerpt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get verdict => $composableBuilder(
      column: $table.verdict, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get detectedAt => $composableBuilder(
      column: $table.detectedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnOrderings(column));
}

class $$SmsAlertsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmsAlertsTable> {
  $$SmsAlertsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get senderMasked => $composableBuilder(
      column: $table.senderMasked, builder: (column) => column);

  GeneratedColumn<String> get bodyExcerpt => $composableBuilder(
      column: $table.bodyExcerpt, builder: (column) => column);

  GeneratedColumn<String> get verdict =>
      $composableBuilder(column: $table.verdict, builder: (column) => column);

  GeneratedColumn<DateTime> get detectedAt => $composableBuilder(
      column: $table.detectedAt, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);
}

class $$SmsAlertsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SmsAlertsTable,
    SmsAlert,
    $$SmsAlertsTableFilterComposer,
    $$SmsAlertsTableOrderingComposer,
    $$SmsAlertsTableAnnotationComposer,
    $$SmsAlertsTableCreateCompanionBuilder,
    $$SmsAlertsTableUpdateCompanionBuilder,
    (SmsAlert, BaseReferences<_$AppDatabase, $SmsAlertsTable, SmsAlert>),
    SmsAlert,
    PrefetchHooks Function()> {
  $$SmsAlertsTableTableManager(_$AppDatabase db, $SmsAlertsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmsAlertsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmsAlertsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SmsAlertsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> senderMasked = const Value.absent(),
            Value<String> bodyExcerpt = const Value.absent(),
            Value<String> verdict = const Value.absent(),
            Value<DateTime> detectedAt = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
          }) =>
              SmsAlertsCompanion(
            id: id,
            senderMasked: senderMasked,
            bodyExcerpt: bodyExcerpt,
            verdict: verdict,
            detectedAt: detectedAt,
            isRead: isRead,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String senderMasked,
            required String bodyExcerpt,
            required String verdict,
            required DateTime detectedAt,
            Value<bool> isRead = const Value.absent(),
          }) =>
              SmsAlertsCompanion.insert(
            id: id,
            senderMasked: senderMasked,
            bodyExcerpt: bodyExcerpt,
            verdict: verdict,
            detectedAt: detectedAt,
            isRead: isRead,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SmsAlertsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SmsAlertsTable,
    SmsAlert,
    $$SmsAlertsTableFilterComposer,
    $$SmsAlertsTableOrderingComposer,
    $$SmsAlertsTableAnnotationComposer,
    $$SmsAlertsTableCreateCompanionBuilder,
    $$SmsAlertsTableUpdateCompanionBuilder,
    (SmsAlert, BaseReferences<_$AppDatabase, $SmsAlertsTable, SmsAlert>),
    SmsAlert,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CacheEntriesTableTableManager get cacheEntries =>
      $$CacheEntriesTableTableManager(_db, _db.cacheEntries);
  $$DraftsTableTableManager get drafts =>
      $$DraftsTableTableManager(_db, _db.drafts);
  $$SmsAlertsTableTableManager get smsAlerts =>
      $$SmsAlertsTableTableManager(_db, _db.smsAlerts);
}
