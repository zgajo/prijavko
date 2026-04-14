// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FacilitiesTable extends Facilities
    with TableInfo<$FacilitiesTable, DbFacility> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FacilitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _facilityCodeMeta = const VerificationMeta(
    'facilityCode',
  );
  @override
  late final GeneratedColumn<String> facilityCode = GeneratedColumn<String>(
    'facility_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultsMeta = const VerificationMeta(
    'defaults',
  );
  @override
  late final GeneratedColumn<String> defaults = GeneratedColumn<String>(
    'defaults',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, facilityCode, defaults];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'facilities';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbFacility> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('facility_code')) {
      context.handle(
        _facilityCodeMeta,
        facilityCode.isAcceptableOrUnknown(
          data['facility_code']!,
          _facilityCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_facilityCodeMeta);
    }
    if (data.containsKey('defaults')) {
      context.handle(
        _defaultsMeta,
        defaults.isAcceptableOrUnknown(data['defaults']!, _defaultsMeta),
      );
    } else if (isInserting) {
      context.missing(_defaultsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbFacility map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbFacility(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      facilityCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}facility_code'],
      )!,
      defaults: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}defaults'],
      )!,
    );
  }

  @override
  $FacilitiesTable createAlias(String alias) {
    return $FacilitiesTable(attachedDatabase, alias);
  }
}

class DbFacility extends DataClass implements Insertable<DbFacility> {
  final int id;
  final String name;
  final String facilityCode;

  /// JSON blob: [FacilityDefaults] keys for defaults editor (Epic 2).
  final String defaults;
  const DbFacility({
    required this.id,
    required this.name,
    required this.facilityCode,
    required this.defaults,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['facility_code'] = Variable<String>(facilityCode);
    map['defaults'] = Variable<String>(defaults);
    return map;
  }

  FacilitiesCompanion toCompanion(bool nullToAbsent) {
    return FacilitiesCompanion(
      id: Value(id),
      name: Value(name),
      facilityCode: Value(facilityCode),
      defaults: Value(defaults),
    );
  }

  factory DbFacility.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbFacility(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      facilityCode: serializer.fromJson<String>(json['facilityCode']),
      defaults: serializer.fromJson<String>(json['defaults']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'facilityCode': serializer.toJson<String>(facilityCode),
      'defaults': serializer.toJson<String>(defaults),
    };
  }

  DbFacility copyWith({
    int? id,
    String? name,
    String? facilityCode,
    String? defaults,
  }) => DbFacility(
    id: id ?? this.id,
    name: name ?? this.name,
    facilityCode: facilityCode ?? this.facilityCode,
    defaults: defaults ?? this.defaults,
  );
  DbFacility copyWithCompanion(FacilitiesCompanion data) {
    return DbFacility(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      facilityCode: data.facilityCode.present
          ? data.facilityCode.value
          : this.facilityCode,
      defaults: data.defaults.present ? data.defaults.value : this.defaults,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbFacility(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('facilityCode: $facilityCode, ')
          ..write('defaults: $defaults')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, facilityCode, defaults);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbFacility &&
          other.id == this.id &&
          other.name == this.name &&
          other.facilityCode == this.facilityCode &&
          other.defaults == this.defaults);
}

class FacilitiesCompanion extends UpdateCompanion<DbFacility> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> facilityCode;
  final Value<String> defaults;
  const FacilitiesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.facilityCode = const Value.absent(),
    this.defaults = const Value.absent(),
  });
  FacilitiesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String facilityCode,
    required String defaults,
  }) : name = Value(name),
       facilityCode = Value(facilityCode),
       defaults = Value(defaults);
  static Insertable<DbFacility> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? facilityCode,
    Expression<String>? defaults,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (facilityCode != null) 'facility_code': facilityCode,
      if (defaults != null) 'defaults': defaults,
    });
  }

  FacilitiesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? facilityCode,
    Value<String>? defaults,
  }) {
    return FacilitiesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      facilityCode: facilityCode ?? this.facilityCode,
      defaults: defaults ?? this.defaults,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (facilityCode.present) {
      map['facility_code'] = Variable<String>(facilityCode.value);
    }
    if (defaults.present) {
      map['defaults'] = Variable<String>(defaults.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FacilitiesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('facilityCode: $facilityCode, ')
          ..write('defaults: $defaults')
          ..write(')'))
        .toString();
  }
}

class $ScanSessionsTable extends ScanSessions
    with TableInfo<$ScanSessionsTable, DbScanSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScanSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _facilityIdMeta = const VerificationMeta(
    'facilityId',
  );
  @override
  late final GeneratedColumn<int> facilityId = GeneratedColumn<int>(
    'facility_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES facilities (id)',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _guestCountMeta = const VerificationMeta(
    'guestCount',
  );
  @override
  late final GeneratedColumn<int> guestCount = GeneratedColumn<int>(
    'guest_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    facilityId,
    startedAt,
    endedAt,
    guestCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbScanSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('facility_id')) {
      context.handle(
        _facilityIdMeta,
        facilityId.isAcceptableOrUnknown(data['facility_id']!, _facilityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_facilityIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('guest_count')) {
      context.handle(
        _guestCountMeta,
        guestCount.isAcceptableOrUnknown(data['guest_count']!, _guestCountMeta),
      );
    } else if (isInserting) {
      context.missing(_guestCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbScanSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbScanSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      facilityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}facility_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      guestCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}guest_count'],
      )!,
    );
  }

  @override
  $ScanSessionsTable createAlias(String alias) {
    return $ScanSessionsTable(attachedDatabase, alias);
  }
}

class DbScanSession extends DataClass implements Insertable<DbScanSession> {
  final int id;
  final int facilityId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int guestCount;
  const DbScanSession({
    required this.id,
    required this.facilityId,
    required this.startedAt,
    this.endedAt,
    required this.guestCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['facility_id'] = Variable<int>(facilityId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['guest_count'] = Variable<int>(guestCount);
    return map;
  }

  ScanSessionsCompanion toCompanion(bool nullToAbsent) {
    return ScanSessionsCompanion(
      id: Value(id),
      facilityId: Value(facilityId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      guestCount: Value(guestCount),
    );
  }

  factory DbScanSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbScanSession(
      id: serializer.fromJson<int>(json['id']),
      facilityId: serializer.fromJson<int>(json['facilityId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      guestCount: serializer.fromJson<int>(json['guestCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'facilityId': serializer.toJson<int>(facilityId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'guestCount': serializer.toJson<int>(guestCount),
    };
  }

  DbScanSession copyWith({
    int? id,
    int? facilityId,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    int? guestCount,
  }) => DbScanSession(
    id: id ?? this.id,
    facilityId: facilityId ?? this.facilityId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    guestCount: guestCount ?? this.guestCount,
  );
  DbScanSession copyWithCompanion(ScanSessionsCompanion data) {
    return DbScanSession(
      id: data.id.present ? data.id.value : this.id,
      facilityId: data.facilityId.present
          ? data.facilityId.value
          : this.facilityId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      guestCount: data.guestCount.present
          ? data.guestCount.value
          : this.guestCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbScanSession(')
          ..write('id: $id, ')
          ..write('facilityId: $facilityId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('guestCount: $guestCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, facilityId, startedAt, endedAt, guestCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbScanSession &&
          other.id == this.id &&
          other.facilityId == this.facilityId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.guestCount == this.guestCount);
}

class ScanSessionsCompanion extends UpdateCompanion<DbScanSession> {
  final Value<int> id;
  final Value<int> facilityId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> guestCount;
  const ScanSessionsCompanion({
    this.id = const Value.absent(),
    this.facilityId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.guestCount = const Value.absent(),
  });
  ScanSessionsCompanion.insert({
    this.id = const Value.absent(),
    required int facilityId,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required int guestCount,
  }) : facilityId = Value(facilityId),
       startedAt = Value(startedAt),
       guestCount = Value(guestCount);
  static Insertable<DbScanSession> custom({
    Expression<int>? id,
    Expression<int>? facilityId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? guestCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (facilityId != null) 'facility_id': facilityId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (guestCount != null) 'guest_count': guestCount,
    });
  }

  ScanSessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? facilityId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? guestCount,
  }) {
    return ScanSessionsCompanion(
      id: id ?? this.id,
      facilityId: facilityId ?? this.facilityId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      guestCount: guestCount ?? this.guestCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (facilityId.present) {
      map['facility_id'] = Variable<int>(facilityId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (guestCount.present) {
      map['guest_count'] = Variable<int>(guestCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanSessionsCompanion(')
          ..write('id: $id, ')
          ..write('facilityId: $facilityId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('guestCount: $guestCount')
          ..write(')'))
        .toString();
  }
}

class $CredentialsTable extends Credentials
    with TableInfo<$CredentialsTable, DbCredential> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CredentialsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _facilityIdMeta = const VerificationMeta(
    'facilityId',
  );
  @override
  late final GeneratedColumn<int> facilityId = GeneratedColumn<int>(
    'facility_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES facilities (id)',
    ),
  );
  static const VerificationMeta _encryptedUsernameMeta = const VerificationMeta(
    'encryptedUsername',
  );
  @override
  late final GeneratedColumn<String> encryptedUsername =
      GeneratedColumn<String>(
        'encrypted_username',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _encryptedPasswordMeta = const VerificationMeta(
    'encryptedPassword',
  );
  @override
  late final GeneratedColumn<String> encryptedPassword =
      GeneratedColumn<String>(
        'encrypted_password',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    facilityId,
    encryptedUsername,
    encryptedPassword,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credentials';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbCredential> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('facility_id')) {
      context.handle(
        _facilityIdMeta,
        facilityId.isAcceptableOrUnknown(data['facility_id']!, _facilityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_facilityIdMeta);
    }
    if (data.containsKey('encrypted_username')) {
      context.handle(
        _encryptedUsernameMeta,
        encryptedUsername.isAcceptableOrUnknown(
          data['encrypted_username']!,
          _encryptedUsernameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedUsernameMeta);
    }
    if (data.containsKey('encrypted_password')) {
      context.handle(
        _encryptedPasswordMeta,
        encryptedPassword.isAcceptableOrUnknown(
          data['encrypted_password']!,
          _encryptedPasswordMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedPasswordMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbCredential map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbCredential(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      facilityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}facility_id'],
      )!,
      encryptedUsername: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encrypted_username'],
      )!,
      encryptedPassword: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encrypted_password'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CredentialsTable createAlias(String alias) {
    return $CredentialsTable(attachedDatabase, alias);
  }
}

class DbCredential extends DataClass implements Insertable<DbCredential> {
  final int id;
  final int facilityId;
  final String encryptedUsername;
  final String encryptedPassword;
  final DateTime createdAt;
  const DbCredential({
    required this.id,
    required this.facilityId,
    required this.encryptedUsername,
    required this.encryptedPassword,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['facility_id'] = Variable<int>(facilityId);
    map['encrypted_username'] = Variable<String>(encryptedUsername);
    map['encrypted_password'] = Variable<String>(encryptedPassword);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CredentialsCompanion toCompanion(bool nullToAbsent) {
    return CredentialsCompanion(
      id: Value(id),
      facilityId: Value(facilityId),
      encryptedUsername: Value(encryptedUsername),
      encryptedPassword: Value(encryptedPassword),
      createdAt: Value(createdAt),
    );
  }

  factory DbCredential.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbCredential(
      id: serializer.fromJson<int>(json['id']),
      facilityId: serializer.fromJson<int>(json['facilityId']),
      encryptedUsername: serializer.fromJson<String>(json['encryptedUsername']),
      encryptedPassword: serializer.fromJson<String>(json['encryptedPassword']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'facilityId': serializer.toJson<int>(facilityId),
      'encryptedUsername': serializer.toJson<String>(encryptedUsername),
      'encryptedPassword': serializer.toJson<String>(encryptedPassword),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DbCredential copyWith({
    int? id,
    int? facilityId,
    String? encryptedUsername,
    String? encryptedPassword,
    DateTime? createdAt,
  }) => DbCredential(
    id: id ?? this.id,
    facilityId: facilityId ?? this.facilityId,
    encryptedUsername: encryptedUsername ?? this.encryptedUsername,
    encryptedPassword: encryptedPassword ?? this.encryptedPassword,
    createdAt: createdAt ?? this.createdAt,
  );
  DbCredential copyWithCompanion(CredentialsCompanion data) {
    return DbCredential(
      id: data.id.present ? data.id.value : this.id,
      facilityId: data.facilityId.present
          ? data.facilityId.value
          : this.facilityId,
      encryptedUsername: data.encryptedUsername.present
          ? data.encryptedUsername.value
          : this.encryptedUsername,
      encryptedPassword: data.encryptedPassword.present
          ? data.encryptedPassword.value
          : this.encryptedPassword,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbCredential(')
          ..write('id: $id, ')
          ..write('facilityId: $facilityId, ')
          ..write('encryptedUsername: $encryptedUsername, ')
          ..write('encryptedPassword: $encryptedPassword, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    facilityId,
    encryptedUsername,
    encryptedPassword,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbCredential &&
          other.id == this.id &&
          other.facilityId == this.facilityId &&
          other.encryptedUsername == this.encryptedUsername &&
          other.encryptedPassword == this.encryptedPassword &&
          other.createdAt == this.createdAt);
}

class CredentialsCompanion extends UpdateCompanion<DbCredential> {
  final Value<int> id;
  final Value<int> facilityId;
  final Value<String> encryptedUsername;
  final Value<String> encryptedPassword;
  final Value<DateTime> createdAt;
  const CredentialsCompanion({
    this.id = const Value.absent(),
    this.facilityId = const Value.absent(),
    this.encryptedUsername = const Value.absent(),
    this.encryptedPassword = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CredentialsCompanion.insert({
    this.id = const Value.absent(),
    required int facilityId,
    required String encryptedUsername,
    required String encryptedPassword,
    required DateTime createdAt,
  }) : facilityId = Value(facilityId),
       encryptedUsername = Value(encryptedUsername),
       encryptedPassword = Value(encryptedPassword),
       createdAt = Value(createdAt);
  static Insertable<DbCredential> custom({
    Expression<int>? id,
    Expression<int>? facilityId,
    Expression<String>? encryptedUsername,
    Expression<String>? encryptedPassword,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (facilityId != null) 'facility_id': facilityId,
      if (encryptedUsername != null) 'encrypted_username': encryptedUsername,
      if (encryptedPassword != null) 'encrypted_password': encryptedPassword,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CredentialsCompanion copyWith({
    Value<int>? id,
    Value<int>? facilityId,
    Value<String>? encryptedUsername,
    Value<String>? encryptedPassword,
    Value<DateTime>? createdAt,
  }) {
    return CredentialsCompanion(
      id: id ?? this.id,
      facilityId: facilityId ?? this.facilityId,
      encryptedUsername: encryptedUsername ?? this.encryptedUsername,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (facilityId.present) {
      map['facility_id'] = Variable<int>(facilityId.value);
    }
    if (encryptedUsername.present) {
      map['encrypted_username'] = Variable<String>(encryptedUsername.value);
    }
    if (encryptedPassword.present) {
      map['encrypted_password'] = Variable<String>(encryptedPassword.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CredentialsCompanion(')
          ..write('id: $id, ')
          ..write('facilityId: $facilityId, ')
          ..write('encryptedUsername: $encryptedUsername, ')
          ..write('encryptedPassword: $encryptedPassword, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $GuestsTable extends Guests with TableInfo<$GuestsTable, DbGuest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GuestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _guidMeta = const VerificationMeta('guid');
  @override
  late final GeneratedColumn<String> guid = GeneratedColumn<String>(
    'guid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _facilityIdMeta = const VerificationMeta(
    'facilityId',
  );
  @override
  late final GeneratedColumn<int> facilityId = GeneratedColumn<int>(
    'facility_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES facilities (id)',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scan_sessions (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<GuestState, int> state =
      GeneratedColumn<int>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<GuestState>($GuestsTable.$converterstate);
  @override
  late final GeneratedColumnWithTypeConverter<CaptureTier, int> captureTier =
      GeneratedColumn<int>(
        'capture_tier',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<CaptureTier>($GuestsTable.$convertercaptureTier);
  @override
  late final GeneratedColumnWithTypeConverter<GuestSource, int> source =
      GeneratedColumn<int>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<GuestSource>($GuestsTable.$convertersource);
  static const VerificationMeta _stayFromDateMeta = const VerificationMeta(
    'stayFromDate',
  );
  @override
  late final GeneratedColumn<String> stayFromDate = GeneratedColumn<String>(
    'stay_from_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stayFromTimeMeta = const VerificationMeta(
    'stayFromTime',
  );
  @override
  late final GeneratedColumn<String> stayFromTime = GeneratedColumn<String>(
    'stay_from_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foreseenStayUntilDateMeta =
      const VerificationMeta('foreseenStayUntilDate');
  @override
  late final GeneratedColumn<String> foreseenStayUntilDate =
      GeneratedColumn<String>(
        'foreseen_stay_until_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _foreseenStayUntilTimeMeta =
      const VerificationMeta('foreseenStayUntilTime');
  @override
  late final GeneratedColumn<String> foreseenStayUntilTime =
      GeneratedColumn<String>(
        'foreseen_stay_until_time',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _documentTypeMeta = const VerificationMeta(
    'documentType',
  );
  @override
  late final GeneratedColumn<String> documentType = GeneratedColumn<String>(
    'document_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentNumberMeta = const VerificationMeta(
    'documentNumber',
  );
  @override
  late final GeneratedColumn<String> documentNumber = GeneratedColumn<String>(
    'document_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _touristNameMeta = const VerificationMeta(
    'touristName',
  );
  @override
  late final GeneratedColumn<String> touristName = GeneratedColumn<String>(
    'tourist_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _touristSurnameMeta = const VerificationMeta(
    'touristSurname',
  );
  @override
  late final GeneratedColumn<String> touristSurname = GeneratedColumn<String>(
    'tourist_surname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _touristMiddleNameMeta = const VerificationMeta(
    'touristMiddleName',
  );
  @override
  late final GeneratedColumn<String> touristMiddleName =
      GeneratedColumn<String>(
        'tourist_middle_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countryOfBirthMeta = const VerificationMeta(
    'countryOfBirth',
  );
  @override
  late final GeneratedColumn<String> countryOfBirth = GeneratedColumn<String>(
    'country_of_birth',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cityOfBirthMeta = const VerificationMeta(
    'cityOfBirth',
  );
  @override
  late final GeneratedColumn<String> cityOfBirth = GeneratedColumn<String>(
    'city_of_birth',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateOfBirthMeta = const VerificationMeta(
    'dateOfBirth',
  );
  @override
  late final GeneratedColumn<String> dateOfBirth = GeneratedColumn<String>(
    'date_of_birth',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _citizenshipMeta = const VerificationMeta(
    'citizenship',
  );
  @override
  late final GeneratedColumn<String> citizenship = GeneratedColumn<String>(
    'citizenship',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countryOfResidenceMeta =
      const VerificationMeta('countryOfResidence');
  @override
  late final GeneratedColumn<String> countryOfResidence =
      GeneratedColumn<String>(
        'country_of_residence',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _cityOfResidenceMeta = const VerificationMeta(
    'cityOfResidence',
  );
  @override
  late final GeneratedColumn<String> cityOfResidence = GeneratedColumn<String>(
    'city_of_residence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _residenceAddressMeta = const VerificationMeta(
    'residenceAddress',
  );
  @override
  late final GeneratedColumn<String> residenceAddress = GeneratedColumn<String>(
    'residence_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _touristEmailMeta = const VerificationMeta(
    'touristEmail',
  );
  @override
  late final GeneratedColumn<String> touristEmail = GeneratedColumn<String>(
    'tourist_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _touristTelephoneMeta = const VerificationMeta(
    'touristTelephone',
  );
  @override
  late final GeneratedColumn<String> touristTelephone = GeneratedColumn<String>(
    'tourist_telephone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accommodationUnitTypeMeta =
      const VerificationMeta('accommodationUnitType');
  @override
  late final GeneratedColumn<String> accommodationUnitType =
      GeneratedColumn<String>(
        'accommodation_unit_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _ttPaymentCategoryMeta = const VerificationMeta(
    'ttPaymentCategory',
  );
  @override
  late final GeneratedColumn<String> ttPaymentCategory =
      GeneratedColumn<String>(
        'tt_payment_category',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _arrivalOrganisationMeta =
      const VerificationMeta('arrivalOrganisation');
  @override
  late final GeneratedColumn<String> arrivalOrganisation =
      GeneratedColumn<String>(
        'arrival_organisation',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _offeredServiceTypeMeta =
      const VerificationMeta('offeredServiceType');
  @override
  late final GeneratedColumn<String> offeredServiceType =
      GeneratedColumn<String>(
        'offered_service_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _borderCrossingMeta = const VerificationMeta(
    'borderCrossing',
  );
  @override
  late final GeneratedColumn<String> borderCrossing = GeneratedColumn<String>(
    'border_crossing',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _passageDateMeta = const VerificationMeta(
    'passageDate',
  );
  @override
  late final GeneratedColumn<String> passageDate = GeneratedColumn<String>(
    'passage_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eVisitorResponseMeta = const VerificationMeta(
    'eVisitorResponse',
  );
  @override
  late final GeneratedColumn<String> eVisitorResponse = GeneratedColumn<String>(
    'e_visitor_response',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isTerminalFailureMeta = const VerificationMeta(
    'isTerminalFailure',
  );
  @override
  late final GeneratedColumn<bool> isTerminalFailure = GeneratedColumn<bool>(
    'is_terminal_failure',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_terminal_failure" IN (0, 1))',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<DateTime> confirmedAt = GeneratedColumn<DateTime>(
    'confirmed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _submittedAtMeta = const VerificationMeta(
    'submittedAt',
  );
  @override
  late final GeneratedColumn<DateTime> submittedAt = GeneratedColumn<DateTime>(
    'submitted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    guid,
    facilityId,
    sessionId,
    state,
    captureTier,
    source,
    stayFromDate,
    stayFromTime,
    foreseenStayUntilDate,
    foreseenStayUntilTime,
    documentType,
    documentNumber,
    touristName,
    touristSurname,
    touristMiddleName,
    gender,
    countryOfBirth,
    cityOfBirth,
    dateOfBirth,
    citizenship,
    countryOfResidence,
    cityOfResidence,
    residenceAddress,
    touristEmail,
    touristTelephone,
    accommodationUnitType,
    ttPaymentCategory,
    arrivalOrganisation,
    offeredServiceType,
    borderCrossing,
    passageDate,
    eVisitorResponse,
    errorMessage,
    isTerminalFailure,
    createdAt,
    confirmedAt,
    submittedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'guests';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbGuest> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('guid')) {
      context.handle(
        _guidMeta,
        guid.isAcceptableOrUnknown(data['guid']!, _guidMeta),
      );
    } else if (isInserting) {
      context.missing(_guidMeta);
    }
    if (data.containsKey('facility_id')) {
      context.handle(
        _facilityIdMeta,
        facilityId.isAcceptableOrUnknown(data['facility_id']!, _facilityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_facilityIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('stay_from_date')) {
      context.handle(
        _stayFromDateMeta,
        stayFromDate.isAcceptableOrUnknown(
          data['stay_from_date']!,
          _stayFromDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stayFromDateMeta);
    }
    if (data.containsKey('stay_from_time')) {
      context.handle(
        _stayFromTimeMeta,
        stayFromTime.isAcceptableOrUnknown(
          data['stay_from_time']!,
          _stayFromTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stayFromTimeMeta);
    }
    if (data.containsKey('foreseen_stay_until_date')) {
      context.handle(
        _foreseenStayUntilDateMeta,
        foreseenStayUntilDate.isAcceptableOrUnknown(
          data['foreseen_stay_until_date']!,
          _foreseenStayUntilDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_foreseenStayUntilDateMeta);
    }
    if (data.containsKey('foreseen_stay_until_time')) {
      context.handle(
        _foreseenStayUntilTimeMeta,
        foreseenStayUntilTime.isAcceptableOrUnknown(
          data['foreseen_stay_until_time']!,
          _foreseenStayUntilTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_foreseenStayUntilTimeMeta);
    }
    if (data.containsKey('document_type')) {
      context.handle(
        _documentTypeMeta,
        documentType.isAcceptableOrUnknown(
          data['document_type']!,
          _documentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_documentTypeMeta);
    }
    if (data.containsKey('document_number')) {
      context.handle(
        _documentNumberMeta,
        documentNumber.isAcceptableOrUnknown(
          data['document_number']!,
          _documentNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_documentNumberMeta);
    }
    if (data.containsKey('tourist_name')) {
      context.handle(
        _touristNameMeta,
        touristName.isAcceptableOrUnknown(
          data['tourist_name']!,
          _touristNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_touristNameMeta);
    }
    if (data.containsKey('tourist_surname')) {
      context.handle(
        _touristSurnameMeta,
        touristSurname.isAcceptableOrUnknown(
          data['tourist_surname']!,
          _touristSurnameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_touristSurnameMeta);
    }
    if (data.containsKey('tourist_middle_name')) {
      context.handle(
        _touristMiddleNameMeta,
        touristMiddleName.isAcceptableOrUnknown(
          data['tourist_middle_name']!,
          _touristMiddleNameMeta,
        ),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    } else if (isInserting) {
      context.missing(_genderMeta);
    }
    if (data.containsKey('country_of_birth')) {
      context.handle(
        _countryOfBirthMeta,
        countryOfBirth.isAcceptableOrUnknown(
          data['country_of_birth']!,
          _countryOfBirthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_countryOfBirthMeta);
    }
    if (data.containsKey('city_of_birth')) {
      context.handle(
        _cityOfBirthMeta,
        cityOfBirth.isAcceptableOrUnknown(
          data['city_of_birth']!,
          _cityOfBirthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cityOfBirthMeta);
    }
    if (data.containsKey('date_of_birth')) {
      context.handle(
        _dateOfBirthMeta,
        dateOfBirth.isAcceptableOrUnknown(
          data['date_of_birth']!,
          _dateOfBirthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateOfBirthMeta);
    }
    if (data.containsKey('citizenship')) {
      context.handle(
        _citizenshipMeta,
        citizenship.isAcceptableOrUnknown(
          data['citizenship']!,
          _citizenshipMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_citizenshipMeta);
    }
    if (data.containsKey('country_of_residence')) {
      context.handle(
        _countryOfResidenceMeta,
        countryOfResidence.isAcceptableOrUnknown(
          data['country_of_residence']!,
          _countryOfResidenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_countryOfResidenceMeta);
    }
    if (data.containsKey('city_of_residence')) {
      context.handle(
        _cityOfResidenceMeta,
        cityOfResidence.isAcceptableOrUnknown(
          data['city_of_residence']!,
          _cityOfResidenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cityOfResidenceMeta);
    }
    if (data.containsKey('residence_address')) {
      context.handle(
        _residenceAddressMeta,
        residenceAddress.isAcceptableOrUnknown(
          data['residence_address']!,
          _residenceAddressMeta,
        ),
      );
    }
    if (data.containsKey('tourist_email')) {
      context.handle(
        _touristEmailMeta,
        touristEmail.isAcceptableOrUnknown(
          data['tourist_email']!,
          _touristEmailMeta,
        ),
      );
    }
    if (data.containsKey('tourist_telephone')) {
      context.handle(
        _touristTelephoneMeta,
        touristTelephone.isAcceptableOrUnknown(
          data['tourist_telephone']!,
          _touristTelephoneMeta,
        ),
      );
    }
    if (data.containsKey('accommodation_unit_type')) {
      context.handle(
        _accommodationUnitTypeMeta,
        accommodationUnitType.isAcceptableOrUnknown(
          data['accommodation_unit_type']!,
          _accommodationUnitTypeMeta,
        ),
      );
    }
    if (data.containsKey('tt_payment_category')) {
      context.handle(
        _ttPaymentCategoryMeta,
        ttPaymentCategory.isAcceptableOrUnknown(
          data['tt_payment_category']!,
          _ttPaymentCategoryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ttPaymentCategoryMeta);
    }
    if (data.containsKey('arrival_organisation')) {
      context.handle(
        _arrivalOrganisationMeta,
        arrivalOrganisation.isAcceptableOrUnknown(
          data['arrival_organisation']!,
          _arrivalOrganisationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_arrivalOrganisationMeta);
    }
    if (data.containsKey('offered_service_type')) {
      context.handle(
        _offeredServiceTypeMeta,
        offeredServiceType.isAcceptableOrUnknown(
          data['offered_service_type']!,
          _offeredServiceTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_offeredServiceTypeMeta);
    }
    if (data.containsKey('border_crossing')) {
      context.handle(
        _borderCrossingMeta,
        borderCrossing.isAcceptableOrUnknown(
          data['border_crossing']!,
          _borderCrossingMeta,
        ),
      );
    }
    if (data.containsKey('passage_date')) {
      context.handle(
        _passageDateMeta,
        passageDate.isAcceptableOrUnknown(
          data['passage_date']!,
          _passageDateMeta,
        ),
      );
    }
    if (data.containsKey('e_visitor_response')) {
      context.handle(
        _eVisitorResponseMeta,
        eVisitorResponse.isAcceptableOrUnknown(
          data['e_visitor_response']!,
          _eVisitorResponseMeta,
        ),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('is_terminal_failure')) {
      context.handle(
        _isTerminalFailureMeta,
        isTerminalFailure.isAcceptableOrUnknown(
          data['is_terminal_failure']!,
          _isTerminalFailureMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    }
    if (data.containsKey('submitted_at')) {
      context.handle(
        _submittedAtMeta,
        submittedAt.isAcceptableOrUnknown(
          data['submitted_at']!,
          _submittedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbGuest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbGuest(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      guid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guid'],
      )!,
      facilityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}facility_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      ),
      state: $GuestsTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}state'],
        )!,
      ),
      captureTier: $GuestsTable.$convertercaptureTier.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}capture_tier'],
        )!,
      ),
      source: $GuestsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}source'],
        )!,
      ),
      stayFromDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stay_from_date'],
      )!,
      stayFromTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stay_from_time'],
      )!,
      foreseenStayUntilDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}foreseen_stay_until_date'],
      )!,
      foreseenStayUntilTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}foreseen_stay_until_time'],
      )!,
      documentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_type'],
      )!,
      documentNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_number'],
      )!,
      touristName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tourist_name'],
      )!,
      touristSurname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tourist_surname'],
      )!,
      touristMiddleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tourist_middle_name'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      )!,
      countryOfBirth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country_of_birth'],
      )!,
      cityOfBirth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city_of_birth'],
      )!,
      dateOfBirth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_of_birth'],
      )!,
      citizenship: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}citizenship'],
      )!,
      countryOfResidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country_of_residence'],
      )!,
      cityOfResidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city_of_residence'],
      )!,
      residenceAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}residence_address'],
      ),
      touristEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tourist_email'],
      ),
      touristTelephone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tourist_telephone'],
      ),
      accommodationUnitType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accommodation_unit_type'],
      ),
      ttPaymentCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tt_payment_category'],
      )!,
      arrivalOrganisation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arrival_organisation'],
      )!,
      offeredServiceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}offered_service_type'],
      )!,
      borderCrossing: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}border_crossing'],
      ),
      passageDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}passage_date'],
      ),
      eVisitorResponse: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}e_visitor_response'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      isTerminalFailure: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_terminal_failure'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}confirmed_at'],
      ),
      submittedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}submitted_at'],
      ),
    );
  }

  @override
  $GuestsTable createAlias(String alias) {
    return $GuestsTable(attachedDatabase, alias);
  }

  static TypeConverter<GuestState, int> $converterstate =
      const GuestStateConverter();
  static TypeConverter<CaptureTier, int> $convertercaptureTier =
      const CaptureTierConverter();
  static TypeConverter<GuestSource, int> $convertersource =
      const GuestSourceConverter();
}

class DbGuest extends DataClass implements Insertable<DbGuest> {
  final int id;
  final String guid;
  final int facilityId;
  final int? sessionId;
  final GuestState state;
  final CaptureTier captureTier;
  final GuestSource source;
  final String stayFromDate;
  final String stayFromTime;
  final String foreseenStayUntilDate;
  final String foreseenStayUntilTime;
  final String documentType;
  final String documentNumber;
  final String touristName;
  final String touristSurname;
  final String? touristMiddleName;
  final String gender;
  final String countryOfBirth;
  final String cityOfBirth;
  final String dateOfBirth;
  final String citizenship;
  final String countryOfResidence;
  final String cityOfResidence;
  final String? residenceAddress;
  final String? touristEmail;
  final String? touristTelephone;
  final String? accommodationUnitType;
  final String ttPaymentCategory;
  final String arrivalOrganisation;
  final String offeredServiceType;
  final String? borderCrossing;
  final String? passageDate;
  final String? eVisitorResponse;
  final String? errorMessage;
  final bool? isTerminalFailure;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? submittedAt;
  const DbGuest({
    required this.id,
    required this.guid,
    required this.facilityId,
    this.sessionId,
    required this.state,
    required this.captureTier,
    required this.source,
    required this.stayFromDate,
    required this.stayFromTime,
    required this.foreseenStayUntilDate,
    required this.foreseenStayUntilTime,
    required this.documentType,
    required this.documentNumber,
    required this.touristName,
    required this.touristSurname,
    this.touristMiddleName,
    required this.gender,
    required this.countryOfBirth,
    required this.cityOfBirth,
    required this.dateOfBirth,
    required this.citizenship,
    required this.countryOfResidence,
    required this.cityOfResidence,
    this.residenceAddress,
    this.touristEmail,
    this.touristTelephone,
    this.accommodationUnitType,
    required this.ttPaymentCategory,
    required this.arrivalOrganisation,
    required this.offeredServiceType,
    this.borderCrossing,
    this.passageDate,
    this.eVisitorResponse,
    this.errorMessage,
    this.isTerminalFailure,
    required this.createdAt,
    this.confirmedAt,
    this.submittedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['guid'] = Variable<String>(guid);
    map['facility_id'] = Variable<int>(facilityId);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<int>(sessionId);
    }
    {
      map['state'] = Variable<int>($GuestsTable.$converterstate.toSql(state));
    }
    {
      map['capture_tier'] = Variable<int>(
        $GuestsTable.$convertercaptureTier.toSql(captureTier),
      );
    }
    {
      map['source'] = Variable<int>(
        $GuestsTable.$convertersource.toSql(source),
      );
    }
    map['stay_from_date'] = Variable<String>(stayFromDate);
    map['stay_from_time'] = Variable<String>(stayFromTime);
    map['foreseen_stay_until_date'] = Variable<String>(foreseenStayUntilDate);
    map['foreseen_stay_until_time'] = Variable<String>(foreseenStayUntilTime);
    map['document_type'] = Variable<String>(documentType);
    map['document_number'] = Variable<String>(documentNumber);
    map['tourist_name'] = Variable<String>(touristName);
    map['tourist_surname'] = Variable<String>(touristSurname);
    if (!nullToAbsent || touristMiddleName != null) {
      map['tourist_middle_name'] = Variable<String>(touristMiddleName);
    }
    map['gender'] = Variable<String>(gender);
    map['country_of_birth'] = Variable<String>(countryOfBirth);
    map['city_of_birth'] = Variable<String>(cityOfBirth);
    map['date_of_birth'] = Variable<String>(dateOfBirth);
    map['citizenship'] = Variable<String>(citizenship);
    map['country_of_residence'] = Variable<String>(countryOfResidence);
    map['city_of_residence'] = Variable<String>(cityOfResidence);
    if (!nullToAbsent || residenceAddress != null) {
      map['residence_address'] = Variable<String>(residenceAddress);
    }
    if (!nullToAbsent || touristEmail != null) {
      map['tourist_email'] = Variable<String>(touristEmail);
    }
    if (!nullToAbsent || touristTelephone != null) {
      map['tourist_telephone'] = Variable<String>(touristTelephone);
    }
    if (!nullToAbsent || accommodationUnitType != null) {
      map['accommodation_unit_type'] = Variable<String>(accommodationUnitType);
    }
    map['tt_payment_category'] = Variable<String>(ttPaymentCategory);
    map['arrival_organisation'] = Variable<String>(arrivalOrganisation);
    map['offered_service_type'] = Variable<String>(offeredServiceType);
    if (!nullToAbsent || borderCrossing != null) {
      map['border_crossing'] = Variable<String>(borderCrossing);
    }
    if (!nullToAbsent || passageDate != null) {
      map['passage_date'] = Variable<String>(passageDate);
    }
    if (!nullToAbsent || eVisitorResponse != null) {
      map['e_visitor_response'] = Variable<String>(eVisitorResponse);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || isTerminalFailure != null) {
      map['is_terminal_failure'] = Variable<bool>(isTerminalFailure);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || confirmedAt != null) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt);
    }
    if (!nullToAbsent || submittedAt != null) {
      map['submitted_at'] = Variable<DateTime>(submittedAt);
    }
    return map;
  }

  GuestsCompanion toCompanion(bool nullToAbsent) {
    return GuestsCompanion(
      id: Value(id),
      guid: Value(guid),
      facilityId: Value(facilityId),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      state: Value(state),
      captureTier: Value(captureTier),
      source: Value(source),
      stayFromDate: Value(stayFromDate),
      stayFromTime: Value(stayFromTime),
      foreseenStayUntilDate: Value(foreseenStayUntilDate),
      foreseenStayUntilTime: Value(foreseenStayUntilTime),
      documentType: Value(documentType),
      documentNumber: Value(documentNumber),
      touristName: Value(touristName),
      touristSurname: Value(touristSurname),
      touristMiddleName: touristMiddleName == null && nullToAbsent
          ? const Value.absent()
          : Value(touristMiddleName),
      gender: Value(gender),
      countryOfBirth: Value(countryOfBirth),
      cityOfBirth: Value(cityOfBirth),
      dateOfBirth: Value(dateOfBirth),
      citizenship: Value(citizenship),
      countryOfResidence: Value(countryOfResidence),
      cityOfResidence: Value(cityOfResidence),
      residenceAddress: residenceAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(residenceAddress),
      touristEmail: touristEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(touristEmail),
      touristTelephone: touristTelephone == null && nullToAbsent
          ? const Value.absent()
          : Value(touristTelephone),
      accommodationUnitType: accommodationUnitType == null && nullToAbsent
          ? const Value.absent()
          : Value(accommodationUnitType),
      ttPaymentCategory: Value(ttPaymentCategory),
      arrivalOrganisation: Value(arrivalOrganisation),
      offeredServiceType: Value(offeredServiceType),
      borderCrossing: borderCrossing == null && nullToAbsent
          ? const Value.absent()
          : Value(borderCrossing),
      passageDate: passageDate == null && nullToAbsent
          ? const Value.absent()
          : Value(passageDate),
      eVisitorResponse: eVisitorResponse == null && nullToAbsent
          ? const Value.absent()
          : Value(eVisitorResponse),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      isTerminalFailure: isTerminalFailure == null && nullToAbsent
          ? const Value.absent()
          : Value(isTerminalFailure),
      createdAt: Value(createdAt),
      confirmedAt: confirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAt),
      submittedAt: submittedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(submittedAt),
    );
  }

  factory DbGuest.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbGuest(
      id: serializer.fromJson<int>(json['id']),
      guid: serializer.fromJson<String>(json['guid']),
      facilityId: serializer.fromJson<int>(json['facilityId']),
      sessionId: serializer.fromJson<int?>(json['sessionId']),
      state: serializer.fromJson<GuestState>(json['state']),
      captureTier: serializer.fromJson<CaptureTier>(json['captureTier']),
      source: serializer.fromJson<GuestSource>(json['source']),
      stayFromDate: serializer.fromJson<String>(json['stayFromDate']),
      stayFromTime: serializer.fromJson<String>(json['stayFromTime']),
      foreseenStayUntilDate: serializer.fromJson<String>(
        json['foreseenStayUntilDate'],
      ),
      foreseenStayUntilTime: serializer.fromJson<String>(
        json['foreseenStayUntilTime'],
      ),
      documentType: serializer.fromJson<String>(json['documentType']),
      documentNumber: serializer.fromJson<String>(json['documentNumber']),
      touristName: serializer.fromJson<String>(json['touristName']),
      touristSurname: serializer.fromJson<String>(json['touristSurname']),
      touristMiddleName: serializer.fromJson<String?>(
        json['touristMiddleName'],
      ),
      gender: serializer.fromJson<String>(json['gender']),
      countryOfBirth: serializer.fromJson<String>(json['countryOfBirth']),
      cityOfBirth: serializer.fromJson<String>(json['cityOfBirth']),
      dateOfBirth: serializer.fromJson<String>(json['dateOfBirth']),
      citizenship: serializer.fromJson<String>(json['citizenship']),
      countryOfResidence: serializer.fromJson<String>(
        json['countryOfResidence'],
      ),
      cityOfResidence: serializer.fromJson<String>(json['cityOfResidence']),
      residenceAddress: serializer.fromJson<String?>(json['residenceAddress']),
      touristEmail: serializer.fromJson<String?>(json['touristEmail']),
      touristTelephone: serializer.fromJson<String?>(json['touristTelephone']),
      accommodationUnitType: serializer.fromJson<String?>(
        json['accommodationUnitType'],
      ),
      ttPaymentCategory: serializer.fromJson<String>(json['ttPaymentCategory']),
      arrivalOrganisation: serializer.fromJson<String>(
        json['arrivalOrganisation'],
      ),
      offeredServiceType: serializer.fromJson<String>(
        json['offeredServiceType'],
      ),
      borderCrossing: serializer.fromJson<String?>(json['borderCrossing']),
      passageDate: serializer.fromJson<String?>(json['passageDate']),
      eVisitorResponse: serializer.fromJson<String?>(json['eVisitorResponse']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      isTerminalFailure: serializer.fromJson<bool?>(json['isTerminalFailure']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      confirmedAt: serializer.fromJson<DateTime?>(json['confirmedAt']),
      submittedAt: serializer.fromJson<DateTime?>(json['submittedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'guid': serializer.toJson<String>(guid),
      'facilityId': serializer.toJson<int>(facilityId),
      'sessionId': serializer.toJson<int?>(sessionId),
      'state': serializer.toJson<GuestState>(state),
      'captureTier': serializer.toJson<CaptureTier>(captureTier),
      'source': serializer.toJson<GuestSource>(source),
      'stayFromDate': serializer.toJson<String>(stayFromDate),
      'stayFromTime': serializer.toJson<String>(stayFromTime),
      'foreseenStayUntilDate': serializer.toJson<String>(foreseenStayUntilDate),
      'foreseenStayUntilTime': serializer.toJson<String>(foreseenStayUntilTime),
      'documentType': serializer.toJson<String>(documentType),
      'documentNumber': serializer.toJson<String>(documentNumber),
      'touristName': serializer.toJson<String>(touristName),
      'touristSurname': serializer.toJson<String>(touristSurname),
      'touristMiddleName': serializer.toJson<String?>(touristMiddleName),
      'gender': serializer.toJson<String>(gender),
      'countryOfBirth': serializer.toJson<String>(countryOfBirth),
      'cityOfBirth': serializer.toJson<String>(cityOfBirth),
      'dateOfBirth': serializer.toJson<String>(dateOfBirth),
      'citizenship': serializer.toJson<String>(citizenship),
      'countryOfResidence': serializer.toJson<String>(countryOfResidence),
      'cityOfResidence': serializer.toJson<String>(cityOfResidence),
      'residenceAddress': serializer.toJson<String?>(residenceAddress),
      'touristEmail': serializer.toJson<String?>(touristEmail),
      'touristTelephone': serializer.toJson<String?>(touristTelephone),
      'accommodationUnitType': serializer.toJson<String?>(
        accommodationUnitType,
      ),
      'ttPaymentCategory': serializer.toJson<String>(ttPaymentCategory),
      'arrivalOrganisation': serializer.toJson<String>(arrivalOrganisation),
      'offeredServiceType': serializer.toJson<String>(offeredServiceType),
      'borderCrossing': serializer.toJson<String?>(borderCrossing),
      'passageDate': serializer.toJson<String?>(passageDate),
      'eVisitorResponse': serializer.toJson<String?>(eVisitorResponse),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'isTerminalFailure': serializer.toJson<bool?>(isTerminalFailure),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'confirmedAt': serializer.toJson<DateTime?>(confirmedAt),
      'submittedAt': serializer.toJson<DateTime?>(submittedAt),
    };
  }

  DbGuest copyWith({
    int? id,
    String? guid,
    int? facilityId,
    Value<int?> sessionId = const Value.absent(),
    GuestState? state,
    CaptureTier? captureTier,
    GuestSource? source,
    String? stayFromDate,
    String? stayFromTime,
    String? foreseenStayUntilDate,
    String? foreseenStayUntilTime,
    String? documentType,
    String? documentNumber,
    String? touristName,
    String? touristSurname,
    Value<String?> touristMiddleName = const Value.absent(),
    String? gender,
    String? countryOfBirth,
    String? cityOfBirth,
    String? dateOfBirth,
    String? citizenship,
    String? countryOfResidence,
    String? cityOfResidence,
    Value<String?> residenceAddress = const Value.absent(),
    Value<String?> touristEmail = const Value.absent(),
    Value<String?> touristTelephone = const Value.absent(),
    Value<String?> accommodationUnitType = const Value.absent(),
    String? ttPaymentCategory,
    String? arrivalOrganisation,
    String? offeredServiceType,
    Value<String?> borderCrossing = const Value.absent(),
    Value<String?> passageDate = const Value.absent(),
    Value<String?> eVisitorResponse = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
    Value<bool?> isTerminalFailure = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> confirmedAt = const Value.absent(),
    Value<DateTime?> submittedAt = const Value.absent(),
  }) => DbGuest(
    id: id ?? this.id,
    guid: guid ?? this.guid,
    facilityId: facilityId ?? this.facilityId,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    state: state ?? this.state,
    captureTier: captureTier ?? this.captureTier,
    source: source ?? this.source,
    stayFromDate: stayFromDate ?? this.stayFromDate,
    stayFromTime: stayFromTime ?? this.stayFromTime,
    foreseenStayUntilDate: foreseenStayUntilDate ?? this.foreseenStayUntilDate,
    foreseenStayUntilTime: foreseenStayUntilTime ?? this.foreseenStayUntilTime,
    documentType: documentType ?? this.documentType,
    documentNumber: documentNumber ?? this.documentNumber,
    touristName: touristName ?? this.touristName,
    touristSurname: touristSurname ?? this.touristSurname,
    touristMiddleName: touristMiddleName.present
        ? touristMiddleName.value
        : this.touristMiddleName,
    gender: gender ?? this.gender,
    countryOfBirth: countryOfBirth ?? this.countryOfBirth,
    cityOfBirth: cityOfBirth ?? this.cityOfBirth,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    citizenship: citizenship ?? this.citizenship,
    countryOfResidence: countryOfResidence ?? this.countryOfResidence,
    cityOfResidence: cityOfResidence ?? this.cityOfResidence,
    residenceAddress: residenceAddress.present
        ? residenceAddress.value
        : this.residenceAddress,
    touristEmail: touristEmail.present ? touristEmail.value : this.touristEmail,
    touristTelephone: touristTelephone.present
        ? touristTelephone.value
        : this.touristTelephone,
    accommodationUnitType: accommodationUnitType.present
        ? accommodationUnitType.value
        : this.accommodationUnitType,
    ttPaymentCategory: ttPaymentCategory ?? this.ttPaymentCategory,
    arrivalOrganisation: arrivalOrganisation ?? this.arrivalOrganisation,
    offeredServiceType: offeredServiceType ?? this.offeredServiceType,
    borderCrossing: borderCrossing.present
        ? borderCrossing.value
        : this.borderCrossing,
    passageDate: passageDate.present ? passageDate.value : this.passageDate,
    eVisitorResponse: eVisitorResponse.present
        ? eVisitorResponse.value
        : this.eVisitorResponse,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    isTerminalFailure: isTerminalFailure.present
        ? isTerminalFailure.value
        : this.isTerminalFailure,
    createdAt: createdAt ?? this.createdAt,
    confirmedAt: confirmedAt.present ? confirmedAt.value : this.confirmedAt,
    submittedAt: submittedAt.present ? submittedAt.value : this.submittedAt,
  );
  DbGuest copyWithCompanion(GuestsCompanion data) {
    return DbGuest(
      id: data.id.present ? data.id.value : this.id,
      guid: data.guid.present ? data.guid.value : this.guid,
      facilityId: data.facilityId.present
          ? data.facilityId.value
          : this.facilityId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      state: data.state.present ? data.state.value : this.state,
      captureTier: data.captureTier.present
          ? data.captureTier.value
          : this.captureTier,
      source: data.source.present ? data.source.value : this.source,
      stayFromDate: data.stayFromDate.present
          ? data.stayFromDate.value
          : this.stayFromDate,
      stayFromTime: data.stayFromTime.present
          ? data.stayFromTime.value
          : this.stayFromTime,
      foreseenStayUntilDate: data.foreseenStayUntilDate.present
          ? data.foreseenStayUntilDate.value
          : this.foreseenStayUntilDate,
      foreseenStayUntilTime: data.foreseenStayUntilTime.present
          ? data.foreseenStayUntilTime.value
          : this.foreseenStayUntilTime,
      documentType: data.documentType.present
          ? data.documentType.value
          : this.documentType,
      documentNumber: data.documentNumber.present
          ? data.documentNumber.value
          : this.documentNumber,
      touristName: data.touristName.present
          ? data.touristName.value
          : this.touristName,
      touristSurname: data.touristSurname.present
          ? data.touristSurname.value
          : this.touristSurname,
      touristMiddleName: data.touristMiddleName.present
          ? data.touristMiddleName.value
          : this.touristMiddleName,
      gender: data.gender.present ? data.gender.value : this.gender,
      countryOfBirth: data.countryOfBirth.present
          ? data.countryOfBirth.value
          : this.countryOfBirth,
      cityOfBirth: data.cityOfBirth.present
          ? data.cityOfBirth.value
          : this.cityOfBirth,
      dateOfBirth: data.dateOfBirth.present
          ? data.dateOfBirth.value
          : this.dateOfBirth,
      citizenship: data.citizenship.present
          ? data.citizenship.value
          : this.citizenship,
      countryOfResidence: data.countryOfResidence.present
          ? data.countryOfResidence.value
          : this.countryOfResidence,
      cityOfResidence: data.cityOfResidence.present
          ? data.cityOfResidence.value
          : this.cityOfResidence,
      residenceAddress: data.residenceAddress.present
          ? data.residenceAddress.value
          : this.residenceAddress,
      touristEmail: data.touristEmail.present
          ? data.touristEmail.value
          : this.touristEmail,
      touristTelephone: data.touristTelephone.present
          ? data.touristTelephone.value
          : this.touristTelephone,
      accommodationUnitType: data.accommodationUnitType.present
          ? data.accommodationUnitType.value
          : this.accommodationUnitType,
      ttPaymentCategory: data.ttPaymentCategory.present
          ? data.ttPaymentCategory.value
          : this.ttPaymentCategory,
      arrivalOrganisation: data.arrivalOrganisation.present
          ? data.arrivalOrganisation.value
          : this.arrivalOrganisation,
      offeredServiceType: data.offeredServiceType.present
          ? data.offeredServiceType.value
          : this.offeredServiceType,
      borderCrossing: data.borderCrossing.present
          ? data.borderCrossing.value
          : this.borderCrossing,
      passageDate: data.passageDate.present
          ? data.passageDate.value
          : this.passageDate,
      eVisitorResponse: data.eVisitorResponse.present
          ? data.eVisitorResponse.value
          : this.eVisitorResponse,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      isTerminalFailure: data.isTerminalFailure.present
          ? data.isTerminalFailure.value
          : this.isTerminalFailure,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
      submittedAt: data.submittedAt.present
          ? data.submittedAt.value
          : this.submittedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbGuest(')
          ..write('id: $id, ')
          ..write('guid: $guid, ')
          ..write('facilityId: $facilityId, ')
          ..write('sessionId: $sessionId, ')
          ..write('state: $state, ')
          ..write('captureTier: $captureTier, ')
          ..write('source: $source, ')
          ..write('stayFromDate: $stayFromDate, ')
          ..write('stayFromTime: $stayFromTime, ')
          ..write('foreseenStayUntilDate: $foreseenStayUntilDate, ')
          ..write('foreseenStayUntilTime: $foreseenStayUntilTime, ')
          ..write('documentType: $documentType, ')
          ..write('documentNumber: $documentNumber, ')
          ..write('touristName: $touristName, ')
          ..write('touristSurname: $touristSurname, ')
          ..write('touristMiddleName: $touristMiddleName, ')
          ..write('gender: $gender, ')
          ..write('countryOfBirth: $countryOfBirth, ')
          ..write('cityOfBirth: $cityOfBirth, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('citizenship: $citizenship, ')
          ..write('countryOfResidence: $countryOfResidence, ')
          ..write('cityOfResidence: $cityOfResidence, ')
          ..write('residenceAddress: $residenceAddress, ')
          ..write('touristEmail: $touristEmail, ')
          ..write('touristTelephone: $touristTelephone, ')
          ..write('accommodationUnitType: $accommodationUnitType, ')
          ..write('ttPaymentCategory: $ttPaymentCategory, ')
          ..write('arrivalOrganisation: $arrivalOrganisation, ')
          ..write('offeredServiceType: $offeredServiceType, ')
          ..write('borderCrossing: $borderCrossing, ')
          ..write('passageDate: $passageDate, ')
          ..write('eVisitorResponse: $eVisitorResponse, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('isTerminalFailure: $isTerminalFailure, ')
          ..write('createdAt: $createdAt, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('submittedAt: $submittedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    guid,
    facilityId,
    sessionId,
    state,
    captureTier,
    source,
    stayFromDate,
    stayFromTime,
    foreseenStayUntilDate,
    foreseenStayUntilTime,
    documentType,
    documentNumber,
    touristName,
    touristSurname,
    touristMiddleName,
    gender,
    countryOfBirth,
    cityOfBirth,
    dateOfBirth,
    citizenship,
    countryOfResidence,
    cityOfResidence,
    residenceAddress,
    touristEmail,
    touristTelephone,
    accommodationUnitType,
    ttPaymentCategory,
    arrivalOrganisation,
    offeredServiceType,
    borderCrossing,
    passageDate,
    eVisitorResponse,
    errorMessage,
    isTerminalFailure,
    createdAt,
    confirmedAt,
    submittedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbGuest &&
          other.id == this.id &&
          other.guid == this.guid &&
          other.facilityId == this.facilityId &&
          other.sessionId == this.sessionId &&
          other.state == this.state &&
          other.captureTier == this.captureTier &&
          other.source == this.source &&
          other.stayFromDate == this.stayFromDate &&
          other.stayFromTime == this.stayFromTime &&
          other.foreseenStayUntilDate == this.foreseenStayUntilDate &&
          other.foreseenStayUntilTime == this.foreseenStayUntilTime &&
          other.documentType == this.documentType &&
          other.documentNumber == this.documentNumber &&
          other.touristName == this.touristName &&
          other.touristSurname == this.touristSurname &&
          other.touristMiddleName == this.touristMiddleName &&
          other.gender == this.gender &&
          other.countryOfBirth == this.countryOfBirth &&
          other.cityOfBirth == this.cityOfBirth &&
          other.dateOfBirth == this.dateOfBirth &&
          other.citizenship == this.citizenship &&
          other.countryOfResidence == this.countryOfResidence &&
          other.cityOfResidence == this.cityOfResidence &&
          other.residenceAddress == this.residenceAddress &&
          other.touristEmail == this.touristEmail &&
          other.touristTelephone == this.touristTelephone &&
          other.accommodationUnitType == this.accommodationUnitType &&
          other.ttPaymentCategory == this.ttPaymentCategory &&
          other.arrivalOrganisation == this.arrivalOrganisation &&
          other.offeredServiceType == this.offeredServiceType &&
          other.borderCrossing == this.borderCrossing &&
          other.passageDate == this.passageDate &&
          other.eVisitorResponse == this.eVisitorResponse &&
          other.errorMessage == this.errorMessage &&
          other.isTerminalFailure == this.isTerminalFailure &&
          other.createdAt == this.createdAt &&
          other.confirmedAt == this.confirmedAt &&
          other.submittedAt == this.submittedAt);
}

class GuestsCompanion extends UpdateCompanion<DbGuest> {
  final Value<int> id;
  final Value<String> guid;
  final Value<int> facilityId;
  final Value<int?> sessionId;
  final Value<GuestState> state;
  final Value<CaptureTier> captureTier;
  final Value<GuestSource> source;
  final Value<String> stayFromDate;
  final Value<String> stayFromTime;
  final Value<String> foreseenStayUntilDate;
  final Value<String> foreseenStayUntilTime;
  final Value<String> documentType;
  final Value<String> documentNumber;
  final Value<String> touristName;
  final Value<String> touristSurname;
  final Value<String?> touristMiddleName;
  final Value<String> gender;
  final Value<String> countryOfBirth;
  final Value<String> cityOfBirth;
  final Value<String> dateOfBirth;
  final Value<String> citizenship;
  final Value<String> countryOfResidence;
  final Value<String> cityOfResidence;
  final Value<String?> residenceAddress;
  final Value<String?> touristEmail;
  final Value<String?> touristTelephone;
  final Value<String?> accommodationUnitType;
  final Value<String> ttPaymentCategory;
  final Value<String> arrivalOrganisation;
  final Value<String> offeredServiceType;
  final Value<String?> borderCrossing;
  final Value<String?> passageDate;
  final Value<String?> eVisitorResponse;
  final Value<String?> errorMessage;
  final Value<bool?> isTerminalFailure;
  final Value<DateTime> createdAt;
  final Value<DateTime?> confirmedAt;
  final Value<DateTime?> submittedAt;
  const GuestsCompanion({
    this.id = const Value.absent(),
    this.guid = const Value.absent(),
    this.facilityId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.state = const Value.absent(),
    this.captureTier = const Value.absent(),
    this.source = const Value.absent(),
    this.stayFromDate = const Value.absent(),
    this.stayFromTime = const Value.absent(),
    this.foreseenStayUntilDate = const Value.absent(),
    this.foreseenStayUntilTime = const Value.absent(),
    this.documentType = const Value.absent(),
    this.documentNumber = const Value.absent(),
    this.touristName = const Value.absent(),
    this.touristSurname = const Value.absent(),
    this.touristMiddleName = const Value.absent(),
    this.gender = const Value.absent(),
    this.countryOfBirth = const Value.absent(),
    this.cityOfBirth = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.citizenship = const Value.absent(),
    this.countryOfResidence = const Value.absent(),
    this.cityOfResidence = const Value.absent(),
    this.residenceAddress = const Value.absent(),
    this.touristEmail = const Value.absent(),
    this.touristTelephone = const Value.absent(),
    this.accommodationUnitType = const Value.absent(),
    this.ttPaymentCategory = const Value.absent(),
    this.arrivalOrganisation = const Value.absent(),
    this.offeredServiceType = const Value.absent(),
    this.borderCrossing = const Value.absent(),
    this.passageDate = const Value.absent(),
    this.eVisitorResponse = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.isTerminalFailure = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.submittedAt = const Value.absent(),
  });
  GuestsCompanion.insert({
    this.id = const Value.absent(),
    required String guid,
    required int facilityId,
    this.sessionId = const Value.absent(),
    required GuestState state,
    required CaptureTier captureTier,
    required GuestSource source,
    required String stayFromDate,
    required String stayFromTime,
    required String foreseenStayUntilDate,
    required String foreseenStayUntilTime,
    required String documentType,
    required String documentNumber,
    required String touristName,
    required String touristSurname,
    this.touristMiddleName = const Value.absent(),
    required String gender,
    required String countryOfBirth,
    required String cityOfBirth,
    required String dateOfBirth,
    required String citizenship,
    required String countryOfResidence,
    required String cityOfResidence,
    this.residenceAddress = const Value.absent(),
    this.touristEmail = const Value.absent(),
    this.touristTelephone = const Value.absent(),
    this.accommodationUnitType = const Value.absent(),
    required String ttPaymentCategory,
    required String arrivalOrganisation,
    required String offeredServiceType,
    this.borderCrossing = const Value.absent(),
    this.passageDate = const Value.absent(),
    this.eVisitorResponse = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.isTerminalFailure = const Value.absent(),
    required DateTime createdAt,
    this.confirmedAt = const Value.absent(),
    this.submittedAt = const Value.absent(),
  }) : guid = Value(guid),
       facilityId = Value(facilityId),
       state = Value(state),
       captureTier = Value(captureTier),
       source = Value(source),
       stayFromDate = Value(stayFromDate),
       stayFromTime = Value(stayFromTime),
       foreseenStayUntilDate = Value(foreseenStayUntilDate),
       foreseenStayUntilTime = Value(foreseenStayUntilTime),
       documentType = Value(documentType),
       documentNumber = Value(documentNumber),
       touristName = Value(touristName),
       touristSurname = Value(touristSurname),
       gender = Value(gender),
       countryOfBirth = Value(countryOfBirth),
       cityOfBirth = Value(cityOfBirth),
       dateOfBirth = Value(dateOfBirth),
       citizenship = Value(citizenship),
       countryOfResidence = Value(countryOfResidence),
       cityOfResidence = Value(cityOfResidence),
       ttPaymentCategory = Value(ttPaymentCategory),
       arrivalOrganisation = Value(arrivalOrganisation),
       offeredServiceType = Value(offeredServiceType),
       createdAt = Value(createdAt);
  static Insertable<DbGuest> custom({
    Expression<int>? id,
    Expression<String>? guid,
    Expression<int>? facilityId,
    Expression<int>? sessionId,
    Expression<int>? state,
    Expression<int>? captureTier,
    Expression<int>? source,
    Expression<String>? stayFromDate,
    Expression<String>? stayFromTime,
    Expression<String>? foreseenStayUntilDate,
    Expression<String>? foreseenStayUntilTime,
    Expression<String>? documentType,
    Expression<String>? documentNumber,
    Expression<String>? touristName,
    Expression<String>? touristSurname,
    Expression<String>? touristMiddleName,
    Expression<String>? gender,
    Expression<String>? countryOfBirth,
    Expression<String>? cityOfBirth,
    Expression<String>? dateOfBirth,
    Expression<String>? citizenship,
    Expression<String>? countryOfResidence,
    Expression<String>? cityOfResidence,
    Expression<String>? residenceAddress,
    Expression<String>? touristEmail,
    Expression<String>? touristTelephone,
    Expression<String>? accommodationUnitType,
    Expression<String>? ttPaymentCategory,
    Expression<String>? arrivalOrganisation,
    Expression<String>? offeredServiceType,
    Expression<String>? borderCrossing,
    Expression<String>? passageDate,
    Expression<String>? eVisitorResponse,
    Expression<String>? errorMessage,
    Expression<bool>? isTerminalFailure,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? confirmedAt,
    Expression<DateTime>? submittedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (guid != null) 'guid': guid,
      if (facilityId != null) 'facility_id': facilityId,
      if (sessionId != null) 'session_id': sessionId,
      if (state != null) 'state': state,
      if (captureTier != null) 'capture_tier': captureTier,
      if (source != null) 'source': source,
      if (stayFromDate != null) 'stay_from_date': stayFromDate,
      if (stayFromTime != null) 'stay_from_time': stayFromTime,
      if (foreseenStayUntilDate != null)
        'foreseen_stay_until_date': foreseenStayUntilDate,
      if (foreseenStayUntilTime != null)
        'foreseen_stay_until_time': foreseenStayUntilTime,
      if (documentType != null) 'document_type': documentType,
      if (documentNumber != null) 'document_number': documentNumber,
      if (touristName != null) 'tourist_name': touristName,
      if (touristSurname != null) 'tourist_surname': touristSurname,
      if (touristMiddleName != null) 'tourist_middle_name': touristMiddleName,
      if (gender != null) 'gender': gender,
      if (countryOfBirth != null) 'country_of_birth': countryOfBirth,
      if (cityOfBirth != null) 'city_of_birth': cityOfBirth,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (citizenship != null) 'citizenship': citizenship,
      if (countryOfResidence != null)
        'country_of_residence': countryOfResidence,
      if (cityOfResidence != null) 'city_of_residence': cityOfResidence,
      if (residenceAddress != null) 'residence_address': residenceAddress,
      if (touristEmail != null) 'tourist_email': touristEmail,
      if (touristTelephone != null) 'tourist_telephone': touristTelephone,
      if (accommodationUnitType != null)
        'accommodation_unit_type': accommodationUnitType,
      if (ttPaymentCategory != null) 'tt_payment_category': ttPaymentCategory,
      if (arrivalOrganisation != null)
        'arrival_organisation': arrivalOrganisation,
      if (offeredServiceType != null)
        'offered_service_type': offeredServiceType,
      if (borderCrossing != null) 'border_crossing': borderCrossing,
      if (passageDate != null) 'passage_date': passageDate,
      if (eVisitorResponse != null) 'e_visitor_response': eVisitorResponse,
      if (errorMessage != null) 'error_message': errorMessage,
      if (isTerminalFailure != null) 'is_terminal_failure': isTerminalFailure,
      if (createdAt != null) 'created_at': createdAt,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
      if (submittedAt != null) 'submitted_at': submittedAt,
    });
  }

  GuestsCompanion copyWith({
    Value<int>? id,
    Value<String>? guid,
    Value<int>? facilityId,
    Value<int?>? sessionId,
    Value<GuestState>? state,
    Value<CaptureTier>? captureTier,
    Value<GuestSource>? source,
    Value<String>? stayFromDate,
    Value<String>? stayFromTime,
    Value<String>? foreseenStayUntilDate,
    Value<String>? foreseenStayUntilTime,
    Value<String>? documentType,
    Value<String>? documentNumber,
    Value<String>? touristName,
    Value<String>? touristSurname,
    Value<String?>? touristMiddleName,
    Value<String>? gender,
    Value<String>? countryOfBirth,
    Value<String>? cityOfBirth,
    Value<String>? dateOfBirth,
    Value<String>? citizenship,
    Value<String>? countryOfResidence,
    Value<String>? cityOfResidence,
    Value<String?>? residenceAddress,
    Value<String?>? touristEmail,
    Value<String?>? touristTelephone,
    Value<String?>? accommodationUnitType,
    Value<String>? ttPaymentCategory,
    Value<String>? arrivalOrganisation,
    Value<String>? offeredServiceType,
    Value<String?>? borderCrossing,
    Value<String?>? passageDate,
    Value<String?>? eVisitorResponse,
    Value<String?>? errorMessage,
    Value<bool?>? isTerminalFailure,
    Value<DateTime>? createdAt,
    Value<DateTime?>? confirmedAt,
    Value<DateTime?>? submittedAt,
  }) {
    return GuestsCompanion(
      id: id ?? this.id,
      guid: guid ?? this.guid,
      facilityId: facilityId ?? this.facilityId,
      sessionId: sessionId ?? this.sessionId,
      state: state ?? this.state,
      captureTier: captureTier ?? this.captureTier,
      source: source ?? this.source,
      stayFromDate: stayFromDate ?? this.stayFromDate,
      stayFromTime: stayFromTime ?? this.stayFromTime,
      foreseenStayUntilDate:
          foreseenStayUntilDate ?? this.foreseenStayUntilDate,
      foreseenStayUntilTime:
          foreseenStayUntilTime ?? this.foreseenStayUntilTime,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      touristName: touristName ?? this.touristName,
      touristSurname: touristSurname ?? this.touristSurname,
      touristMiddleName: touristMiddleName ?? this.touristMiddleName,
      gender: gender ?? this.gender,
      countryOfBirth: countryOfBirth ?? this.countryOfBirth,
      cityOfBirth: cityOfBirth ?? this.cityOfBirth,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      citizenship: citizenship ?? this.citizenship,
      countryOfResidence: countryOfResidence ?? this.countryOfResidence,
      cityOfResidence: cityOfResidence ?? this.cityOfResidence,
      residenceAddress: residenceAddress ?? this.residenceAddress,
      touristEmail: touristEmail ?? this.touristEmail,
      touristTelephone: touristTelephone ?? this.touristTelephone,
      accommodationUnitType:
          accommodationUnitType ?? this.accommodationUnitType,
      ttPaymentCategory: ttPaymentCategory ?? this.ttPaymentCategory,
      arrivalOrganisation: arrivalOrganisation ?? this.arrivalOrganisation,
      offeredServiceType: offeredServiceType ?? this.offeredServiceType,
      borderCrossing: borderCrossing ?? this.borderCrossing,
      passageDate: passageDate ?? this.passageDate,
      eVisitorResponse: eVisitorResponse ?? this.eVisitorResponse,
      errorMessage: errorMessage ?? this.errorMessage,
      isTerminalFailure: isTerminalFailure ?? this.isTerminalFailure,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (guid.present) {
      map['guid'] = Variable<String>(guid.value);
    }
    if (facilityId.present) {
      map['facility_id'] = Variable<int>(facilityId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(
        $GuestsTable.$converterstate.toSql(state.value),
      );
    }
    if (captureTier.present) {
      map['capture_tier'] = Variable<int>(
        $GuestsTable.$convertercaptureTier.toSql(captureTier.value),
      );
    }
    if (source.present) {
      map['source'] = Variable<int>(
        $GuestsTable.$convertersource.toSql(source.value),
      );
    }
    if (stayFromDate.present) {
      map['stay_from_date'] = Variable<String>(stayFromDate.value);
    }
    if (stayFromTime.present) {
      map['stay_from_time'] = Variable<String>(stayFromTime.value);
    }
    if (foreseenStayUntilDate.present) {
      map['foreseen_stay_until_date'] = Variable<String>(
        foreseenStayUntilDate.value,
      );
    }
    if (foreseenStayUntilTime.present) {
      map['foreseen_stay_until_time'] = Variable<String>(
        foreseenStayUntilTime.value,
      );
    }
    if (documentType.present) {
      map['document_type'] = Variable<String>(documentType.value);
    }
    if (documentNumber.present) {
      map['document_number'] = Variable<String>(documentNumber.value);
    }
    if (touristName.present) {
      map['tourist_name'] = Variable<String>(touristName.value);
    }
    if (touristSurname.present) {
      map['tourist_surname'] = Variable<String>(touristSurname.value);
    }
    if (touristMiddleName.present) {
      map['tourist_middle_name'] = Variable<String>(touristMiddleName.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (countryOfBirth.present) {
      map['country_of_birth'] = Variable<String>(countryOfBirth.value);
    }
    if (cityOfBirth.present) {
      map['city_of_birth'] = Variable<String>(cityOfBirth.value);
    }
    if (dateOfBirth.present) {
      map['date_of_birth'] = Variable<String>(dateOfBirth.value);
    }
    if (citizenship.present) {
      map['citizenship'] = Variable<String>(citizenship.value);
    }
    if (countryOfResidence.present) {
      map['country_of_residence'] = Variable<String>(countryOfResidence.value);
    }
    if (cityOfResidence.present) {
      map['city_of_residence'] = Variable<String>(cityOfResidence.value);
    }
    if (residenceAddress.present) {
      map['residence_address'] = Variable<String>(residenceAddress.value);
    }
    if (touristEmail.present) {
      map['tourist_email'] = Variable<String>(touristEmail.value);
    }
    if (touristTelephone.present) {
      map['tourist_telephone'] = Variable<String>(touristTelephone.value);
    }
    if (accommodationUnitType.present) {
      map['accommodation_unit_type'] = Variable<String>(
        accommodationUnitType.value,
      );
    }
    if (ttPaymentCategory.present) {
      map['tt_payment_category'] = Variable<String>(ttPaymentCategory.value);
    }
    if (arrivalOrganisation.present) {
      map['arrival_organisation'] = Variable<String>(arrivalOrganisation.value);
    }
    if (offeredServiceType.present) {
      map['offered_service_type'] = Variable<String>(offeredServiceType.value);
    }
    if (borderCrossing.present) {
      map['border_crossing'] = Variable<String>(borderCrossing.value);
    }
    if (passageDate.present) {
      map['passage_date'] = Variable<String>(passageDate.value);
    }
    if (eVisitorResponse.present) {
      map['e_visitor_response'] = Variable<String>(eVisitorResponse.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (isTerminalFailure.present) {
      map['is_terminal_failure'] = Variable<bool>(isTerminalFailure.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt.value);
    }
    if (submittedAt.present) {
      map['submitted_at'] = Variable<DateTime>(submittedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GuestsCompanion(')
          ..write('id: $id, ')
          ..write('guid: $guid, ')
          ..write('facilityId: $facilityId, ')
          ..write('sessionId: $sessionId, ')
          ..write('state: $state, ')
          ..write('captureTier: $captureTier, ')
          ..write('source: $source, ')
          ..write('stayFromDate: $stayFromDate, ')
          ..write('stayFromTime: $stayFromTime, ')
          ..write('foreseenStayUntilDate: $foreseenStayUntilDate, ')
          ..write('foreseenStayUntilTime: $foreseenStayUntilTime, ')
          ..write('documentType: $documentType, ')
          ..write('documentNumber: $documentNumber, ')
          ..write('touristName: $touristName, ')
          ..write('touristSurname: $touristSurname, ')
          ..write('touristMiddleName: $touristMiddleName, ')
          ..write('gender: $gender, ')
          ..write('countryOfBirth: $countryOfBirth, ')
          ..write('cityOfBirth: $cityOfBirth, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('citizenship: $citizenship, ')
          ..write('countryOfResidence: $countryOfResidence, ')
          ..write('cityOfResidence: $cityOfResidence, ')
          ..write('residenceAddress: $residenceAddress, ')
          ..write('touristEmail: $touristEmail, ')
          ..write('touristTelephone: $touristTelephone, ')
          ..write('accommodationUnitType: $accommodationUnitType, ')
          ..write('ttPaymentCategory: $ttPaymentCategory, ')
          ..write('arrivalOrganisation: $arrivalOrganisation, ')
          ..write('offeredServiceType: $offeredServiceType, ')
          ..write('borderCrossing: $borderCrossing, ')
          ..write('passageDate: $passageDate, ')
          ..write('eVisitorResponse: $eVisitorResponse, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('isTerminalFailure: $isTerminalFailure, ')
          ..write('createdAt: $createdAt, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('submittedAt: $submittedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FacilitiesTable facilities = $FacilitiesTable(this);
  late final $ScanSessionsTable scanSessions = $ScanSessionsTable(this);
  late final $CredentialsTable credentials = $CredentialsTable(this);
  late final $GuestsTable guests = $GuestsTable(this);
  late final Index idxGuestsFacilityId = Index(
    'idx_guests_facility_id',
    'CREATE INDEX idx_guests_facility_id ON guests (facility_id)',
  );
  late final Index idxGuestsState = Index(
    'idx_guests_state',
    'CREATE INDEX idx_guests_state ON guests (state)',
  );
  late final Index idxGuestsSubmittedAt = Index(
    'idx_guests_submitted_at',
    'CREATE INDEX idx_guests_submitted_at ON guests (submitted_at)',
  );
  late final Index idxGuestsCreatedAt = Index(
    'idx_guests_created_at',
    'CREATE INDEX idx_guests_created_at ON guests (created_at)',
  );
  late final FacilitiesDao facilitiesDao = FacilitiesDao(this as AppDatabase);
  late final GuestsDao guestsDao = GuestsDao(this as AppDatabase);
  late final ScanSessionsDao scanSessionsDao = ScanSessionsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    facilities,
    scanSessions,
    credentials,
    guests,
    idxGuestsFacilityId,
    idxGuestsState,
    idxGuestsSubmittedAt,
    idxGuestsCreatedAt,
  ];
}

typedef $$FacilitiesTableCreateCompanionBuilder =
    FacilitiesCompanion Function({
      Value<int> id,
      required String name,
      required String facilityCode,
      required String defaults,
    });
typedef $$FacilitiesTableUpdateCompanionBuilder =
    FacilitiesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> facilityCode,
      Value<String> defaults,
    });

final class $$FacilitiesTableReferences
    extends BaseReferences<_$AppDatabase, $FacilitiesTable, DbFacility> {
  $$FacilitiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ScanSessionsTable, List<DbScanSession>>
  _scanSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.scanSessions,
    aliasName: $_aliasNameGenerator(
      db.facilities.id,
      db.scanSessions.facilityId,
    ),
  );

  $$ScanSessionsTableProcessedTableManager get scanSessionsRefs {
    final manager = $$ScanSessionsTableTableManager(
      $_db,
      $_db.scanSessions,
    ).filter((f) => f.facilityId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_scanSessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CredentialsTable, List<DbCredential>>
  _credentialsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.credentials,
    aliasName: $_aliasNameGenerator(
      db.facilities.id,
      db.credentials.facilityId,
    ),
  );

  $$CredentialsTableProcessedTableManager get credentialsRefs {
    final manager = $$CredentialsTableTableManager(
      $_db,
      $_db.credentials,
    ).filter((f) => f.facilityId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_credentialsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GuestsTable, List<DbGuest>> _guestsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.guests,
    aliasName: $_aliasNameGenerator(db.facilities.id, db.guests.facilityId),
  );

  $$GuestsTableProcessedTableManager get guestsRefs {
    final manager = $$GuestsTableTableManager(
      $_db,
      $_db.guests,
    ).filter((f) => f.facilityId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_guestsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FacilitiesTableFilterComposer
    extends Composer<_$AppDatabase, $FacilitiesTable> {
  $$FacilitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get facilityCode => $composableBuilder(
    column: $table.facilityCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaults => $composableBuilder(
    column: $table.defaults,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> scanSessionsRefs(
    Expression<bool> Function($$ScanSessionsTableFilterComposer f) f,
  ) {
    final $$ScanSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanSessions,
      getReferencedColumn: (t) => t.facilityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanSessionsTableFilterComposer(
            $db: $db,
            $table: $db.scanSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> credentialsRefs(
    Expression<bool> Function($$CredentialsTableFilterComposer f) f,
  ) {
    final $$CredentialsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.credentials,
      getReferencedColumn: (t) => t.facilityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialsTableFilterComposer(
            $db: $db,
            $table: $db.credentials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> guestsRefs(
    Expression<bool> Function($$GuestsTableFilterComposer f) f,
  ) {
    final $$GuestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.guests,
      getReferencedColumn: (t) => t.facilityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GuestsTableFilterComposer(
            $db: $db,
            $table: $db.guests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FacilitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $FacilitiesTable> {
  $$FacilitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get facilityCode => $composableBuilder(
    column: $table.facilityCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaults => $composableBuilder(
    column: $table.defaults,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FacilitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FacilitiesTable> {
  $$FacilitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get facilityCode => $composableBuilder(
    column: $table.facilityCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaults =>
      $composableBuilder(column: $table.defaults, builder: (column) => column);

  Expression<T> scanSessionsRefs<T extends Object>(
    Expression<T> Function($$ScanSessionsTableAnnotationComposer a) f,
  ) {
    final $$ScanSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanSessions,
      getReferencedColumn: (t) => t.facilityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.scanSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> credentialsRefs<T extends Object>(
    Expression<T> Function($$CredentialsTableAnnotationComposer a) f,
  ) {
    final $$CredentialsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.credentials,
      getReferencedColumn: (t) => t.facilityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialsTableAnnotationComposer(
            $db: $db,
            $table: $db.credentials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> guestsRefs<T extends Object>(
    Expression<T> Function($$GuestsTableAnnotationComposer a) f,
  ) {
    final $$GuestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.guests,
      getReferencedColumn: (t) => t.facilityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GuestsTableAnnotationComposer(
            $db: $db,
            $table: $db.guests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FacilitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FacilitiesTable,
          DbFacility,
          $$FacilitiesTableFilterComposer,
          $$FacilitiesTableOrderingComposer,
          $$FacilitiesTableAnnotationComposer,
          $$FacilitiesTableCreateCompanionBuilder,
          $$FacilitiesTableUpdateCompanionBuilder,
          (DbFacility, $$FacilitiesTableReferences),
          DbFacility,
          PrefetchHooks Function({
            bool scanSessionsRefs,
            bool credentialsRefs,
            bool guestsRefs,
          })
        > {
  $$FacilitiesTableTableManager(_$AppDatabase db, $FacilitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FacilitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FacilitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FacilitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> facilityCode = const Value.absent(),
                Value<String> defaults = const Value.absent(),
              }) => FacilitiesCompanion(
                id: id,
                name: name,
                facilityCode: facilityCode,
                defaults: defaults,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String facilityCode,
                required String defaults,
              }) => FacilitiesCompanion.insert(
                id: id,
                name: name,
                facilityCode: facilityCode,
                defaults: defaults,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FacilitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                scanSessionsRefs = false,
                credentialsRefs = false,
                guestsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (scanSessionsRefs) db.scanSessions,
                    if (credentialsRefs) db.credentials,
                    if (guestsRefs) db.guests,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (scanSessionsRefs)
                        await $_getPrefetchedData<
                          DbFacility,
                          $FacilitiesTable,
                          DbScanSession
                        >(
                          currentTable: table,
                          referencedTable: $$FacilitiesTableReferences
                              ._scanSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FacilitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).scanSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.facilityId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (credentialsRefs)
                        await $_getPrefetchedData<
                          DbFacility,
                          $FacilitiesTable,
                          DbCredential
                        >(
                          currentTable: table,
                          referencedTable: $$FacilitiesTableReferences
                              ._credentialsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FacilitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).credentialsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.facilityId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (guestsRefs)
                        await $_getPrefetchedData<
                          DbFacility,
                          $FacilitiesTable,
                          DbGuest
                        >(
                          currentTable: table,
                          referencedTable: $$FacilitiesTableReferences
                              ._guestsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FacilitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).guestsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.facilityId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FacilitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FacilitiesTable,
      DbFacility,
      $$FacilitiesTableFilterComposer,
      $$FacilitiesTableOrderingComposer,
      $$FacilitiesTableAnnotationComposer,
      $$FacilitiesTableCreateCompanionBuilder,
      $$FacilitiesTableUpdateCompanionBuilder,
      (DbFacility, $$FacilitiesTableReferences),
      DbFacility,
      PrefetchHooks Function({
        bool scanSessionsRefs,
        bool credentialsRefs,
        bool guestsRefs,
      })
    >;
typedef $$ScanSessionsTableCreateCompanionBuilder =
    ScanSessionsCompanion Function({
      Value<int> id,
      required int facilityId,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      required int guestCount,
    });
typedef $$ScanSessionsTableUpdateCompanionBuilder =
    ScanSessionsCompanion Function({
      Value<int> id,
      Value<int> facilityId,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int> guestCount,
    });

final class $$ScanSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $ScanSessionsTable, DbScanSession> {
  $$ScanSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FacilitiesTable _facilityIdTable(_$AppDatabase db) =>
      db.facilities.createAlias(
        $_aliasNameGenerator(db.scanSessions.facilityId, db.facilities.id),
      );

  $$FacilitiesTableProcessedTableManager get facilityId {
    final $_column = $_itemColumn<int>('facility_id')!;

    final manager = $$FacilitiesTableTableManager(
      $_db,
      $_db.facilities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_facilityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$GuestsTable, List<DbGuest>> _guestsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.guests,
    aliasName: $_aliasNameGenerator(db.scanSessions.id, db.guests.sessionId),
  );

  $$GuestsTableProcessedTableManager get guestsRefs {
    final manager = $$GuestsTableTableManager(
      $_db,
      $_db.guests,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_guestsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScanSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ScanSessionsTable> {
  $$ScanSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get guestCount => $composableBuilder(
    column: $table.guestCount,
    builder: (column) => ColumnFilters(column),
  );

  $$FacilitiesTableFilterComposer get facilityId {
    final $$FacilitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.facilityId,
      referencedTable: $db.facilities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FacilitiesTableFilterComposer(
            $db: $db,
            $table: $db.facilities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> guestsRefs(
    Expression<bool> Function($$GuestsTableFilterComposer f) f,
  ) {
    final $$GuestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.guests,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GuestsTableFilterComposer(
            $db: $db,
            $table: $db.guests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScanSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScanSessionsTable> {
  $$ScanSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get guestCount => $composableBuilder(
    column: $table.guestCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$FacilitiesTableOrderingComposer get facilityId {
    final $$FacilitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.facilityId,
      referencedTable: $db.facilities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FacilitiesTableOrderingComposer(
            $db: $db,
            $table: $db.facilities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScanSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScanSessionsTable> {
  $$ScanSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get guestCount => $composableBuilder(
    column: $table.guestCount,
    builder: (column) => column,
  );

  $$FacilitiesTableAnnotationComposer get facilityId {
    final $$FacilitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.facilityId,
      referencedTable: $db.facilities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FacilitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.facilities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> guestsRefs<T extends Object>(
    Expression<T> Function($$GuestsTableAnnotationComposer a) f,
  ) {
    final $$GuestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.guests,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GuestsTableAnnotationComposer(
            $db: $db,
            $table: $db.guests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScanSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScanSessionsTable,
          DbScanSession,
          $$ScanSessionsTableFilterComposer,
          $$ScanSessionsTableOrderingComposer,
          $$ScanSessionsTableAnnotationComposer,
          $$ScanSessionsTableCreateCompanionBuilder,
          $$ScanSessionsTableUpdateCompanionBuilder,
          (DbScanSession, $$ScanSessionsTableReferences),
          DbScanSession,
          PrefetchHooks Function({bool facilityId, bool guestsRefs})
        > {
  $$ScanSessionsTableTableManager(_$AppDatabase db, $ScanSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScanSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScanSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScanSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> facilityId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> guestCount = const Value.absent(),
              }) => ScanSessionsCompanion(
                id: id,
                facilityId: facilityId,
                startedAt: startedAt,
                endedAt: endedAt,
                guestCount: guestCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int facilityId,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required int guestCount,
              }) => ScanSessionsCompanion.insert(
                id: id,
                facilityId: facilityId,
                startedAt: startedAt,
                endedAt: endedAt,
                guestCount: guestCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ScanSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({facilityId = false, guestsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (guestsRefs) db.guests],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (facilityId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.facilityId,
                                referencedTable: $$ScanSessionsTableReferences
                                    ._facilityIdTable(db),
                                referencedColumn: $$ScanSessionsTableReferences
                                    ._facilityIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (guestsRefs)
                    await $_getPrefetchedData<
                      DbScanSession,
                      $ScanSessionsTable,
                      DbGuest
                    >(
                      currentTable: table,
                      referencedTable: $$ScanSessionsTableReferences
                          ._guestsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ScanSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).guestsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ScanSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScanSessionsTable,
      DbScanSession,
      $$ScanSessionsTableFilterComposer,
      $$ScanSessionsTableOrderingComposer,
      $$ScanSessionsTableAnnotationComposer,
      $$ScanSessionsTableCreateCompanionBuilder,
      $$ScanSessionsTableUpdateCompanionBuilder,
      (DbScanSession, $$ScanSessionsTableReferences),
      DbScanSession,
      PrefetchHooks Function({bool facilityId, bool guestsRefs})
    >;
typedef $$CredentialsTableCreateCompanionBuilder =
    CredentialsCompanion Function({
      Value<int> id,
      required int facilityId,
      required String encryptedUsername,
      required String encryptedPassword,
      required DateTime createdAt,
    });
typedef $$CredentialsTableUpdateCompanionBuilder =
    CredentialsCompanion Function({
      Value<int> id,
      Value<int> facilityId,
      Value<String> encryptedUsername,
      Value<String> encryptedPassword,
      Value<DateTime> createdAt,
    });

final class $$CredentialsTableReferences
    extends BaseReferences<_$AppDatabase, $CredentialsTable, DbCredential> {
  $$CredentialsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FacilitiesTable _facilityIdTable(_$AppDatabase db) =>
      db.facilities.createAlias(
        $_aliasNameGenerator(db.credentials.facilityId, db.facilities.id),
      );

  $$FacilitiesTableProcessedTableManager get facilityId {
    final $_column = $_itemColumn<int>('facility_id')!;

    final manager = $$FacilitiesTableTableManager(
      $_db,
      $_db.facilities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_facilityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CredentialsTableFilterComposer
    extends Composer<_$AppDatabase, $CredentialsTable> {
  $$CredentialsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptedUsername => $composableBuilder(
    column: $table.encryptedUsername,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptedPassword => $composableBuilder(
    column: $table.encryptedPassword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FacilitiesTableFilterComposer get facilityId {
    final $$FacilitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.facilityId,
      referencedTable: $db.facilities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FacilitiesTableFilterComposer(
            $db: $db,
            $table: $db.facilities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CredentialsTableOrderingComposer
    extends Composer<_$AppDatabase, $CredentialsTable> {
  $$CredentialsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptedUsername => $composableBuilder(
    column: $table.encryptedUsername,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptedPassword => $composableBuilder(
    column: $table.encryptedPassword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FacilitiesTableOrderingComposer get facilityId {
    final $$FacilitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.facilityId,
      referencedTable: $db.facilities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FacilitiesTableOrderingComposer(
            $db: $db,
            $table: $db.facilities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CredentialsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CredentialsTable> {
  $$CredentialsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get encryptedUsername => $composableBuilder(
    column: $table.encryptedUsername,
    builder: (column) => column,
  );

  GeneratedColumn<String> get encryptedPassword => $composableBuilder(
    column: $table.encryptedPassword,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$FacilitiesTableAnnotationComposer get facilityId {
    final $$FacilitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.facilityId,
      referencedTable: $db.facilities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FacilitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.facilities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CredentialsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CredentialsTable,
          DbCredential,
          $$CredentialsTableFilterComposer,
          $$CredentialsTableOrderingComposer,
          $$CredentialsTableAnnotationComposer,
          $$CredentialsTableCreateCompanionBuilder,
          $$CredentialsTableUpdateCompanionBuilder,
          (DbCredential, $$CredentialsTableReferences),
          DbCredential,
          PrefetchHooks Function({bool facilityId})
        > {
  $$CredentialsTableTableManager(_$AppDatabase db, $CredentialsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CredentialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CredentialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CredentialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> facilityId = const Value.absent(),
                Value<String> encryptedUsername = const Value.absent(),
                Value<String> encryptedPassword = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CredentialsCompanion(
                id: id,
                facilityId: facilityId,
                encryptedUsername: encryptedUsername,
                encryptedPassword: encryptedPassword,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int facilityId,
                required String encryptedUsername,
                required String encryptedPassword,
                required DateTime createdAt,
              }) => CredentialsCompanion.insert(
                id: id,
                facilityId: facilityId,
                encryptedUsername: encryptedUsername,
                encryptedPassword: encryptedPassword,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CredentialsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({facilityId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (facilityId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.facilityId,
                                referencedTable: $$CredentialsTableReferences
                                    ._facilityIdTable(db),
                                referencedColumn: $$CredentialsTableReferences
                                    ._facilityIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CredentialsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CredentialsTable,
      DbCredential,
      $$CredentialsTableFilterComposer,
      $$CredentialsTableOrderingComposer,
      $$CredentialsTableAnnotationComposer,
      $$CredentialsTableCreateCompanionBuilder,
      $$CredentialsTableUpdateCompanionBuilder,
      (DbCredential, $$CredentialsTableReferences),
      DbCredential,
      PrefetchHooks Function({bool facilityId})
    >;
typedef $$GuestsTableCreateCompanionBuilder =
    GuestsCompanion Function({
      Value<int> id,
      required String guid,
      required int facilityId,
      Value<int?> sessionId,
      required GuestState state,
      required CaptureTier captureTier,
      required GuestSource source,
      required String stayFromDate,
      required String stayFromTime,
      required String foreseenStayUntilDate,
      required String foreseenStayUntilTime,
      required String documentType,
      required String documentNumber,
      required String touristName,
      required String touristSurname,
      Value<String?> touristMiddleName,
      required String gender,
      required String countryOfBirth,
      required String cityOfBirth,
      required String dateOfBirth,
      required String citizenship,
      required String countryOfResidence,
      required String cityOfResidence,
      Value<String?> residenceAddress,
      Value<String?> touristEmail,
      Value<String?> touristTelephone,
      Value<String?> accommodationUnitType,
      required String ttPaymentCategory,
      required String arrivalOrganisation,
      required String offeredServiceType,
      Value<String?> borderCrossing,
      Value<String?> passageDate,
      Value<String?> eVisitorResponse,
      Value<String?> errorMessage,
      Value<bool?> isTerminalFailure,
      required DateTime createdAt,
      Value<DateTime?> confirmedAt,
      Value<DateTime?> submittedAt,
    });
typedef $$GuestsTableUpdateCompanionBuilder =
    GuestsCompanion Function({
      Value<int> id,
      Value<String> guid,
      Value<int> facilityId,
      Value<int?> sessionId,
      Value<GuestState> state,
      Value<CaptureTier> captureTier,
      Value<GuestSource> source,
      Value<String> stayFromDate,
      Value<String> stayFromTime,
      Value<String> foreseenStayUntilDate,
      Value<String> foreseenStayUntilTime,
      Value<String> documentType,
      Value<String> documentNumber,
      Value<String> touristName,
      Value<String> touristSurname,
      Value<String?> touristMiddleName,
      Value<String> gender,
      Value<String> countryOfBirth,
      Value<String> cityOfBirth,
      Value<String> dateOfBirth,
      Value<String> citizenship,
      Value<String> countryOfResidence,
      Value<String> cityOfResidence,
      Value<String?> residenceAddress,
      Value<String?> touristEmail,
      Value<String?> touristTelephone,
      Value<String?> accommodationUnitType,
      Value<String> ttPaymentCategory,
      Value<String> arrivalOrganisation,
      Value<String> offeredServiceType,
      Value<String?> borderCrossing,
      Value<String?> passageDate,
      Value<String?> eVisitorResponse,
      Value<String?> errorMessage,
      Value<bool?> isTerminalFailure,
      Value<DateTime> createdAt,
      Value<DateTime?> confirmedAt,
      Value<DateTime?> submittedAt,
    });

final class $$GuestsTableReferences
    extends BaseReferences<_$AppDatabase, $GuestsTable, DbGuest> {
  $$GuestsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FacilitiesTable _facilityIdTable(_$AppDatabase db) =>
      db.facilities.createAlias(
        $_aliasNameGenerator(db.guests.facilityId, db.facilities.id),
      );

  $$FacilitiesTableProcessedTableManager get facilityId {
    final $_column = $_itemColumn<int>('facility_id')!;

    final manager = $$FacilitiesTableTableManager(
      $_db,
      $_db.facilities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_facilityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ScanSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.scanSessions.createAlias(
        $_aliasNameGenerator(db.guests.sessionId, db.scanSessions.id),
      );

  $$ScanSessionsTableProcessedTableManager? get sessionId {
    final $_column = $_itemColumn<int>('session_id');
    if ($_column == null) return null;
    final manager = $$ScanSessionsTableTableManager(
      $_db,
      $_db.scanSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GuestsTableFilterComposer
    extends Composer<_$AppDatabase, $GuestsTable> {
  $$GuestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GuestState, GuestState, int> get state =>
      $composableBuilder(
        column: $table.state,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<CaptureTier, CaptureTier, int>
  get captureTier => $composableBuilder(
    column: $table.captureTier,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<GuestSource, GuestSource, int> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get stayFromDate => $composableBuilder(
    column: $table.stayFromDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stayFromTime => $composableBuilder(
    column: $table.stayFromTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foreseenStayUntilDate => $composableBuilder(
    column: $table.foreseenStayUntilDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foreseenStayUntilTime => $composableBuilder(
    column: $table.foreseenStayUntilTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentNumber => $composableBuilder(
    column: $table.documentNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get touristName => $composableBuilder(
    column: $table.touristName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get touristSurname => $composableBuilder(
    column: $table.touristSurname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get touristMiddleName => $composableBuilder(
    column: $table.touristMiddleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countryOfBirth => $composableBuilder(
    column: $table.countryOfBirth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cityOfBirth => $composableBuilder(
    column: $table.cityOfBirth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get citizenship => $composableBuilder(
    column: $table.citizenship,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countryOfResidence => $composableBuilder(
    column: $table.countryOfResidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cityOfResidence => $composableBuilder(
    column: $table.cityOfResidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get residenceAddress => $composableBuilder(
    column: $table.residenceAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get touristEmail => $composableBuilder(
    column: $table.touristEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get touristTelephone => $composableBuilder(
    column: $table.touristTelephone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accommodationUnitType => $composableBuilder(
    column: $table.accommodationUnitType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ttPaymentCategory => $composableBuilder(
    column: $table.ttPaymentCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arrivalOrganisation => $composableBuilder(
    column: $table.arrivalOrganisation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get offeredServiceType => $composableBuilder(
    column: $table.offeredServiceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get borderCrossing => $composableBuilder(
    column: $table.borderCrossing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passageDate => $composableBuilder(
    column: $table.passageDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eVisitorResponse => $composableBuilder(
    column: $table.eVisitorResponse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTerminalFailure => $composableBuilder(
    column: $table.isTerminalFailure,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FacilitiesTableFilterComposer get facilityId {
    final $$FacilitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.facilityId,
      referencedTable: $db.facilities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FacilitiesTableFilterComposer(
            $db: $db,
            $table: $db.facilities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ScanSessionsTableFilterComposer get sessionId {
    final $$ScanSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.scanSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanSessionsTableFilterComposer(
            $db: $db,
            $table: $db.scanSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GuestsTableOrderingComposer
    extends Composer<_$AppDatabase, $GuestsTable> {
  $$GuestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get captureTier => $composableBuilder(
    column: $table.captureTier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stayFromDate => $composableBuilder(
    column: $table.stayFromDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stayFromTime => $composableBuilder(
    column: $table.stayFromTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foreseenStayUntilDate => $composableBuilder(
    column: $table.foreseenStayUntilDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foreseenStayUntilTime => $composableBuilder(
    column: $table.foreseenStayUntilTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentNumber => $composableBuilder(
    column: $table.documentNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get touristName => $composableBuilder(
    column: $table.touristName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get touristSurname => $composableBuilder(
    column: $table.touristSurname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get touristMiddleName => $composableBuilder(
    column: $table.touristMiddleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countryOfBirth => $composableBuilder(
    column: $table.countryOfBirth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cityOfBirth => $composableBuilder(
    column: $table.cityOfBirth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get citizenship => $composableBuilder(
    column: $table.citizenship,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countryOfResidence => $composableBuilder(
    column: $table.countryOfResidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cityOfResidence => $composableBuilder(
    column: $table.cityOfResidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get residenceAddress => $composableBuilder(
    column: $table.residenceAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get touristEmail => $composableBuilder(
    column: $table.touristEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get touristTelephone => $composableBuilder(
    column: $table.touristTelephone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accommodationUnitType => $composableBuilder(
    column: $table.accommodationUnitType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ttPaymentCategory => $composableBuilder(
    column: $table.ttPaymentCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arrivalOrganisation => $composableBuilder(
    column: $table.arrivalOrganisation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get offeredServiceType => $composableBuilder(
    column: $table.offeredServiceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get borderCrossing => $composableBuilder(
    column: $table.borderCrossing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passageDate => $composableBuilder(
    column: $table.passageDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eVisitorResponse => $composableBuilder(
    column: $table.eVisitorResponse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTerminalFailure => $composableBuilder(
    column: $table.isTerminalFailure,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FacilitiesTableOrderingComposer get facilityId {
    final $$FacilitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.facilityId,
      referencedTable: $db.facilities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FacilitiesTableOrderingComposer(
            $db: $db,
            $table: $db.facilities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ScanSessionsTableOrderingComposer get sessionId {
    final $$ScanSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.scanSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.scanSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GuestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GuestsTable> {
  $$GuestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get guid =>
      $composableBuilder(column: $table.guid, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GuestState, int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CaptureTier, int> get captureTier =>
      $composableBuilder(
        column: $table.captureTier,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<GuestSource, int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get stayFromDate => $composableBuilder(
    column: $table.stayFromDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stayFromTime => $composableBuilder(
    column: $table.stayFromTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get foreseenStayUntilDate => $composableBuilder(
    column: $table.foreseenStayUntilDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get foreseenStayUntilTime => $composableBuilder(
    column: $table.foreseenStayUntilTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get documentNumber => $composableBuilder(
    column: $table.documentNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get touristName => $composableBuilder(
    column: $table.touristName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get touristSurname => $composableBuilder(
    column: $table.touristSurname,
    builder: (column) => column,
  );

  GeneratedColumn<String> get touristMiddleName => $composableBuilder(
    column: $table.touristMiddleName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get countryOfBirth => $composableBuilder(
    column: $table.countryOfBirth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cityOfBirth => $composableBuilder(
    column: $table.cityOfBirth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get citizenship => $composableBuilder(
    column: $table.citizenship,
    builder: (column) => column,
  );

  GeneratedColumn<String> get countryOfResidence => $composableBuilder(
    column: $table.countryOfResidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cityOfResidence => $composableBuilder(
    column: $table.cityOfResidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get residenceAddress => $composableBuilder(
    column: $table.residenceAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get touristEmail => $composableBuilder(
    column: $table.touristEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get touristTelephone => $composableBuilder(
    column: $table.touristTelephone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accommodationUnitType => $composableBuilder(
    column: $table.accommodationUnitType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ttPaymentCategory => $composableBuilder(
    column: $table.ttPaymentCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get arrivalOrganisation => $composableBuilder(
    column: $table.arrivalOrganisation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get offeredServiceType => $composableBuilder(
    column: $table.offeredServiceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get borderCrossing => $composableBuilder(
    column: $table.borderCrossing,
    builder: (column) => column,
  );

  GeneratedColumn<String> get passageDate => $composableBuilder(
    column: $table.passageDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eVisitorResponse => $composableBuilder(
    column: $table.eVisitorResponse,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTerminalFailure => $composableBuilder(
    column: $table.isTerminalFailure,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => column,
  );

  $$FacilitiesTableAnnotationComposer get facilityId {
    final $$FacilitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.facilityId,
      referencedTable: $db.facilities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FacilitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.facilities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ScanSessionsTableAnnotationComposer get sessionId {
    final $$ScanSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.scanSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.scanSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GuestsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GuestsTable,
          DbGuest,
          $$GuestsTableFilterComposer,
          $$GuestsTableOrderingComposer,
          $$GuestsTableAnnotationComposer,
          $$GuestsTableCreateCompanionBuilder,
          $$GuestsTableUpdateCompanionBuilder,
          (DbGuest, $$GuestsTableReferences),
          DbGuest,
          PrefetchHooks Function({bool facilityId, bool sessionId})
        > {
  $$GuestsTableTableManager(_$AppDatabase db, $GuestsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GuestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GuestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GuestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> guid = const Value.absent(),
                Value<int> facilityId = const Value.absent(),
                Value<int?> sessionId = const Value.absent(),
                Value<GuestState> state = const Value.absent(),
                Value<CaptureTier> captureTier = const Value.absent(),
                Value<GuestSource> source = const Value.absent(),
                Value<String> stayFromDate = const Value.absent(),
                Value<String> stayFromTime = const Value.absent(),
                Value<String> foreseenStayUntilDate = const Value.absent(),
                Value<String> foreseenStayUntilTime = const Value.absent(),
                Value<String> documentType = const Value.absent(),
                Value<String> documentNumber = const Value.absent(),
                Value<String> touristName = const Value.absent(),
                Value<String> touristSurname = const Value.absent(),
                Value<String?> touristMiddleName = const Value.absent(),
                Value<String> gender = const Value.absent(),
                Value<String> countryOfBirth = const Value.absent(),
                Value<String> cityOfBirth = const Value.absent(),
                Value<String> dateOfBirth = const Value.absent(),
                Value<String> citizenship = const Value.absent(),
                Value<String> countryOfResidence = const Value.absent(),
                Value<String> cityOfResidence = const Value.absent(),
                Value<String?> residenceAddress = const Value.absent(),
                Value<String?> touristEmail = const Value.absent(),
                Value<String?> touristTelephone = const Value.absent(),
                Value<String?> accommodationUnitType = const Value.absent(),
                Value<String> ttPaymentCategory = const Value.absent(),
                Value<String> arrivalOrganisation = const Value.absent(),
                Value<String> offeredServiceType = const Value.absent(),
                Value<String?> borderCrossing = const Value.absent(),
                Value<String?> passageDate = const Value.absent(),
                Value<String?> eVisitorResponse = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<bool?> isTerminalFailure = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> confirmedAt = const Value.absent(),
                Value<DateTime?> submittedAt = const Value.absent(),
              }) => GuestsCompanion(
                id: id,
                guid: guid,
                facilityId: facilityId,
                sessionId: sessionId,
                state: state,
                captureTier: captureTier,
                source: source,
                stayFromDate: stayFromDate,
                stayFromTime: stayFromTime,
                foreseenStayUntilDate: foreseenStayUntilDate,
                foreseenStayUntilTime: foreseenStayUntilTime,
                documentType: documentType,
                documentNumber: documentNumber,
                touristName: touristName,
                touristSurname: touristSurname,
                touristMiddleName: touristMiddleName,
                gender: gender,
                countryOfBirth: countryOfBirth,
                cityOfBirth: cityOfBirth,
                dateOfBirth: dateOfBirth,
                citizenship: citizenship,
                countryOfResidence: countryOfResidence,
                cityOfResidence: cityOfResidence,
                residenceAddress: residenceAddress,
                touristEmail: touristEmail,
                touristTelephone: touristTelephone,
                accommodationUnitType: accommodationUnitType,
                ttPaymentCategory: ttPaymentCategory,
                arrivalOrganisation: arrivalOrganisation,
                offeredServiceType: offeredServiceType,
                borderCrossing: borderCrossing,
                passageDate: passageDate,
                eVisitorResponse: eVisitorResponse,
                errorMessage: errorMessage,
                isTerminalFailure: isTerminalFailure,
                createdAt: createdAt,
                confirmedAt: confirmedAt,
                submittedAt: submittedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String guid,
                required int facilityId,
                Value<int?> sessionId = const Value.absent(),
                required GuestState state,
                required CaptureTier captureTier,
                required GuestSource source,
                required String stayFromDate,
                required String stayFromTime,
                required String foreseenStayUntilDate,
                required String foreseenStayUntilTime,
                required String documentType,
                required String documentNumber,
                required String touristName,
                required String touristSurname,
                Value<String?> touristMiddleName = const Value.absent(),
                required String gender,
                required String countryOfBirth,
                required String cityOfBirth,
                required String dateOfBirth,
                required String citizenship,
                required String countryOfResidence,
                required String cityOfResidence,
                Value<String?> residenceAddress = const Value.absent(),
                Value<String?> touristEmail = const Value.absent(),
                Value<String?> touristTelephone = const Value.absent(),
                Value<String?> accommodationUnitType = const Value.absent(),
                required String ttPaymentCategory,
                required String arrivalOrganisation,
                required String offeredServiceType,
                Value<String?> borderCrossing = const Value.absent(),
                Value<String?> passageDate = const Value.absent(),
                Value<String?> eVisitorResponse = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<bool?> isTerminalFailure = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> confirmedAt = const Value.absent(),
                Value<DateTime?> submittedAt = const Value.absent(),
              }) => GuestsCompanion.insert(
                id: id,
                guid: guid,
                facilityId: facilityId,
                sessionId: sessionId,
                state: state,
                captureTier: captureTier,
                source: source,
                stayFromDate: stayFromDate,
                stayFromTime: stayFromTime,
                foreseenStayUntilDate: foreseenStayUntilDate,
                foreseenStayUntilTime: foreseenStayUntilTime,
                documentType: documentType,
                documentNumber: documentNumber,
                touristName: touristName,
                touristSurname: touristSurname,
                touristMiddleName: touristMiddleName,
                gender: gender,
                countryOfBirth: countryOfBirth,
                cityOfBirth: cityOfBirth,
                dateOfBirth: dateOfBirth,
                citizenship: citizenship,
                countryOfResidence: countryOfResidence,
                cityOfResidence: cityOfResidence,
                residenceAddress: residenceAddress,
                touristEmail: touristEmail,
                touristTelephone: touristTelephone,
                accommodationUnitType: accommodationUnitType,
                ttPaymentCategory: ttPaymentCategory,
                arrivalOrganisation: arrivalOrganisation,
                offeredServiceType: offeredServiceType,
                borderCrossing: borderCrossing,
                passageDate: passageDate,
                eVisitorResponse: eVisitorResponse,
                errorMessage: errorMessage,
                isTerminalFailure: isTerminalFailure,
                createdAt: createdAt,
                confirmedAt: confirmedAt,
                submittedAt: submittedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$GuestsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({facilityId = false, sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (facilityId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.facilityId,
                                referencedTable: $$GuestsTableReferences
                                    ._facilityIdTable(db),
                                referencedColumn: $$GuestsTableReferences
                                    ._facilityIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$GuestsTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$GuestsTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GuestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GuestsTable,
      DbGuest,
      $$GuestsTableFilterComposer,
      $$GuestsTableOrderingComposer,
      $$GuestsTableAnnotationComposer,
      $$GuestsTableCreateCompanionBuilder,
      $$GuestsTableUpdateCompanionBuilder,
      (DbGuest, $$GuestsTableReferences),
      DbGuest,
      PrefetchHooks Function({bool facilityId, bool sessionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FacilitiesTableTableManager get facilities =>
      $$FacilitiesTableTableManager(_db, _db.facilities);
  $$ScanSessionsTableTableManager get scanSessions =>
      $$ScanSessionsTableTableManager(_db, _db.scanSessions);
  $$CredentialsTableTableManager get credentials =>
      $$CredentialsTableTableManager(_db, _db.credentials);
  $$GuestsTableTableManager get guests =>
      $$GuestsTableTableManager(_db, _db.guests);
}
