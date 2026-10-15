// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class Semesters extends Table with TableInfo<Semesters, Semester> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Semesters(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(trim(name)) > 0 AND name <> \'unclear\')',
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(start_date) = 10 AND COALESCE(date(start_date, \'+0 days\') = start_date, 0))',
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(end_date) = 10 AND COALESCE(date(end_date, \'+0 days\') = end_date, 0))',
  );
  static const VerificationMeta _totalWeeksMeta = const VerificationMeta(
    'totalWeeks',
  );
  late final GeneratedColumn<int> totalWeeks = GeneratedColumn<int>(
    'total_weeks',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (total_weeks BETWEEN 1 AND 366)',
  );
  static const VerificationMeta _weekStartDayMeta = const VerificationMeta(
    'weekStartDay',
  );
  late final GeneratedColumn<int> weekStartDay = GeneratedColumn<int>(
    'week_start_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (week_start_day BETWEEN 1 AND 7)',
  );
  static const VerificationMeta _manualWeekOffsetMeta = const VerificationMeta(
    'manualWeekOffset',
  );
  late final GeneratedColumn<int> manualWeekOffset = GeneratedColumn<int>(
    'manual_week_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    startDate,
    endDate,
    totalWeeks,
    weekStartDay,
    manualWeekOffset,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'semesters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Semester> instance, {
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
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('total_weeks')) {
      context.handle(
        _totalWeeksMeta,
        totalWeeks.isAcceptableOrUnknown(data['total_weeks']!, _totalWeeksMeta),
      );
    } else if (isInserting) {
      context.missing(_totalWeeksMeta);
    }
    if (data.containsKey('week_start_day')) {
      context.handle(
        _weekStartDayMeta,
        weekStartDay.isAcceptableOrUnknown(
          data['week_start_day']!,
          _weekStartDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_weekStartDayMeta);
    }
    if (data.containsKey('manual_week_offset')) {
      context.handle(
        _manualWeekOffsetMeta,
        manualWeekOffset.isAcceptableOrUnknown(
          data['manual_week_offset']!,
          _manualWeekOffsetMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Semester map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Semester(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      )!,
      totalWeeks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_weeks'],
      )!,
      weekStartDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}week_start_day'],
      )!,
      manualWeekOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}manual_week_offset'],
      )!,
    );
  }

  @override
  Semesters createAlias(String alias) {
    return Semesters(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['CHECK(end_date >= start_date)'];
  @override
  bool get dontWriteConstraints => true;
}

class Semester extends DataClass implements Insertable<Semester> {
  final String id;
  final String name;
  final String startDate;
  final String endDate;
  final int totalWeeks;
  final int weekStartDay;
  final int manualWeekOffset;
  const Semester({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.totalWeeks,
    required this.weekStartDay,
    required this.manualWeekOffset,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['start_date'] = Variable<String>(startDate);
    map['end_date'] = Variable<String>(endDate);
    map['total_weeks'] = Variable<int>(totalWeeks);
    map['week_start_day'] = Variable<int>(weekStartDay);
    map['manual_week_offset'] = Variable<int>(manualWeekOffset);
    return map;
  }

  SemestersCompanion toCompanion(bool nullToAbsent) {
    return SemestersCompanion(
      id: Value(id),
      name: Value(name),
      startDate: Value(startDate),
      endDate: Value(endDate),
      totalWeeks: Value(totalWeeks),
      weekStartDay: Value(weekStartDay),
      manualWeekOffset: Value(manualWeekOffset),
    );
  }

  factory Semester.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Semester(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      startDate: serializer.fromJson<String>(json['start_date']),
      endDate: serializer.fromJson<String>(json['end_date']),
      totalWeeks: serializer.fromJson<int>(json['total_weeks']),
      weekStartDay: serializer.fromJson<int>(json['week_start_day']),
      manualWeekOffset: serializer.fromJson<int>(json['manual_week_offset']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'start_date': serializer.toJson<String>(startDate),
      'end_date': serializer.toJson<String>(endDate),
      'total_weeks': serializer.toJson<int>(totalWeeks),
      'week_start_day': serializer.toJson<int>(weekStartDay),
      'manual_week_offset': serializer.toJson<int>(manualWeekOffset),
    };
  }

  Semester copyWith({
    String? id,
    String? name,
    String? startDate,
    String? endDate,
    int? totalWeeks,
    int? weekStartDay,
    int? manualWeekOffset,
  }) => Semester(
    id: id ?? this.id,
    name: name ?? this.name,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    totalWeeks: totalWeeks ?? this.totalWeeks,
    weekStartDay: weekStartDay ?? this.weekStartDay,
    manualWeekOffset: manualWeekOffset ?? this.manualWeekOffset,
  );
  Semester copyWithCompanion(SemestersCompanion data) {
    return Semester(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      totalWeeks: data.totalWeeks.present
          ? data.totalWeeks.value
          : this.totalWeeks,
      weekStartDay: data.weekStartDay.present
          ? data.weekStartDay.value
          : this.weekStartDay,
      manualWeekOffset: data.manualWeekOffset.present
          ? data.manualWeekOffset.value
          : this.manualWeekOffset,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Semester(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('totalWeeks: $totalWeeks, ')
          ..write('weekStartDay: $weekStartDay, ')
          ..write('manualWeekOffset: $manualWeekOffset')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    startDate,
    endDate,
    totalWeeks,
    weekStartDay,
    manualWeekOffset,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Semester &&
          other.id == this.id &&
          other.name == this.name &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.totalWeeks == this.totalWeeks &&
          other.weekStartDay == this.weekStartDay &&
          other.manualWeekOffset == this.manualWeekOffset);
}

class SemestersCompanion extends UpdateCompanion<Semester> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> startDate;
  final Value<String> endDate;
  final Value<int> totalWeeks;
  final Value<int> weekStartDay;
  final Value<int> manualWeekOffset;
  final Value<int> rowid;
  const SemestersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.totalWeeks = const Value.absent(),
    this.weekStartDay = const Value.absent(),
    this.manualWeekOffset = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SemestersCompanion.insert({
    required String id,
    required String name,
    required String startDate,
    required String endDate,
    required int totalWeeks,
    required int weekStartDay,
    this.manualWeekOffset = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       startDate = Value(startDate),
       endDate = Value(endDate),
       totalWeeks = Value(totalWeeks),
       weekStartDay = Value(weekStartDay);
  static Insertable<Semester> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<int>? totalWeeks,
    Expression<int>? weekStartDay,
    Expression<int>? manualWeekOffset,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (totalWeeks != null) 'total_weeks': totalWeeks,
      if (weekStartDay != null) 'week_start_day': weekStartDay,
      if (manualWeekOffset != null) 'manual_week_offset': manualWeekOffset,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SemestersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? startDate,
    Value<String>? endDate,
    Value<int>? totalWeeks,
    Value<int>? weekStartDay,
    Value<int>? manualWeekOffset,
    Value<int>? rowid,
  }) {
    return SemestersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      weekStartDay: weekStartDay ?? this.weekStartDay,
      manualWeekOffset: manualWeekOffset ?? this.manualWeekOffset,
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
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (totalWeeks.present) {
      map['total_weeks'] = Variable<int>(totalWeeks.value);
    }
    if (weekStartDay.present) {
      map['week_start_day'] = Variable<int>(weekStartDay.value);
    }
    if (manualWeekOffset.present) {
      map['manual_week_offset'] = Variable<int>(manualWeekOffset.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SemestersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('totalWeeks: $totalWeeks, ')
          ..write('weekStartDay: $weekStartDay, ')
          ..write('manualWeekOffset: $manualWeekOffset, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Courses extends Table with TableInfo<Courses, Course> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Courses(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(trim(name)) > 0 AND name <> \'unclear\')',
  );
  static const VerificationMeta _teacherMeta = const VerificationMeta(
    'teacher',
  );
  late final GeneratedColumn<String> teacher = GeneratedColumn<String>(
    'teacher',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'default\'',
    defaultValue: const CustomExpression('\'default\''),
  );
  static const VerificationMeta _remarkMeta = const VerificationMeta('remark');
  late final GeneratedColumn<String> remark = GeneratedColumn<String>(
    'remark',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, teacher, color, remark];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'courses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Course> instance, {
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
    if (data.containsKey('teacher')) {
      context.handle(
        _teacherMeta,
        teacher.isAcceptableOrUnknown(data['teacher']!, _teacherMeta),
      );
    } else if (isInserting) {
      context.missing(_teacherMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('remark')) {
      context.handle(
        _remarkMeta,
        remark.isAcceptableOrUnknown(data['remark']!, _remarkMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Course map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Course(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      teacher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      remark: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remark'],
      )!,
    );
  }

  @override
  Courses createAlias(String alias) {
    return Courses(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Course extends DataClass implements Insertable<Course> {
  final String id;
  final String name;
  final String teacher;
  final String color;
  final String remark;
  const Course({
    required this.id,
    required this.name,
    required this.teacher,
    required this.color,
    required this.remark,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['teacher'] = Variable<String>(teacher);
    map['color'] = Variable<String>(color);
    map['remark'] = Variable<String>(remark);
    return map;
  }

  CoursesCompanion toCompanion(bool nullToAbsent) {
    return CoursesCompanion(
      id: Value(id),
      name: Value(name),
      teacher: Value(teacher),
      color: Value(color),
      remark: Value(remark),
    );
  }

  factory Course.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Course(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      teacher: serializer.fromJson<String>(json['teacher']),
      color: serializer.fromJson<String>(json['color']),
      remark: serializer.fromJson<String>(json['remark']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'teacher': serializer.toJson<String>(teacher),
      'color': serializer.toJson<String>(color),
      'remark': serializer.toJson<String>(remark),
    };
  }

  Course copyWith({
    String? id,
    String? name,
    String? teacher,
    String? color,
    String? remark,
  }) => Course(
    id: id ?? this.id,
    name: name ?? this.name,
    teacher: teacher ?? this.teacher,
    color: color ?? this.color,
    remark: remark ?? this.remark,
  );
  Course copyWithCompanion(CoursesCompanion data) {
    return Course(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      teacher: data.teacher.present ? data.teacher.value : this.teacher,
      color: data.color.present ? data.color.value : this.color,
      remark: data.remark.present ? data.remark.value : this.remark,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Course(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('teacher: $teacher, ')
          ..write('color: $color, ')
          ..write('remark: $remark')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, teacher, color, remark);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Course &&
          other.id == this.id &&
          other.name == this.name &&
          other.teacher == this.teacher &&
          other.color == this.color &&
          other.remark == this.remark);
}

class CoursesCompanion extends UpdateCompanion<Course> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> teacher;
  final Value<String> color;
  final Value<String> remark;
  final Value<int> rowid;
  const CoursesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.teacher = const Value.absent(),
    this.color = const Value.absent(),
    this.remark = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoursesCompanion.insert({
    required String id,
    required String name,
    required String teacher,
    this.color = const Value.absent(),
    this.remark = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       teacher = Value(teacher);
  static Insertable<Course> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? teacher,
    Expression<String>? color,
    Expression<String>? remark,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (teacher != null) 'teacher': teacher,
      if (color != null) 'color': color,
      if (remark != null) 'remark': remark,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoursesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? teacher,
    Value<String>? color,
    Value<String>? remark,
    Value<int>? rowid,
  }) {
    return CoursesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      color: color ?? this.color,
      remark: remark ?? this.remark,
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
    if (teacher.present) {
      map['teacher'] = Variable<String>(teacher.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (remark.present) {
      map['remark'] = Variable<String>(remark.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoursesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('teacher: $teacher, ')
          ..write('color: $color, ')
          ..write('remark: $remark, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CourseSchedules extends Table
    with TableInfo<CourseSchedules, CourseSchedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CourseSchedules(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES courses(id)',
  );
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  late final GeneratedColumn<String> semesterId = GeneratedColumn<String>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES semesters(id)',
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (weekday BETWEEN 1 AND 7)',
  );
  static const VerificationMeta _startSectionMeta = const VerificationMeta(
    'startSection',
  );
  late final GeneratedColumn<int> startSection = GeneratedColumn<int>(
    'start_section',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (start_section >= 1)',
  );
  static const VerificationMeta _endSectionMeta = const VerificationMeta(
    'endSection',
  );
  late final GeneratedColumn<int> endSection = GeneratedColumn<int>(
    'end_section',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (end_section >= start_section)',
  );
  static const VerificationMeta _classroomMeta = const VerificationMeta(
    'classroom',
  );
  late final GeneratedColumn<String> classroom = GeneratedColumn<String>(
    'classroom',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _remarkMeta = const VerificationMeta('remark');
  late final GeneratedColumn<String> remark = GeneratedColumn<String>(
    'remark',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    courseId,
    semesterId,
    weekday,
    startSection,
    endSection,
    classroom,
    remark,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseSchedule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    if (data.containsKey('start_section')) {
      context.handle(
        _startSectionMeta,
        startSection.isAcceptableOrUnknown(
          data['start_section']!,
          _startSectionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startSectionMeta);
    }
    if (data.containsKey('end_section')) {
      context.handle(
        _endSectionMeta,
        endSection.isAcceptableOrUnknown(data['end_section']!, _endSectionMeta),
      );
    } else if (isInserting) {
      context.missing(_endSectionMeta);
    }
    if (data.containsKey('classroom')) {
      context.handle(
        _classroomMeta,
        classroom.isAcceptableOrUnknown(data['classroom']!, _classroomMeta),
      );
    } else if (isInserting) {
      context.missing(_classroomMeta);
    }
    if (data.containsKey('remark')) {
      context.handle(
        _remarkMeta,
        remark.isAcceptableOrUnknown(data['remark']!, _remarkMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CourseSchedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseSchedule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semester_id'],
      )!,
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
      startSection: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_section'],
      )!,
      endSection: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_section'],
      )!,
      classroom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classroom'],
      )!,
      remark: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remark'],
      )!,
    );
  }

  @override
  CourseSchedules createAlias(String alias) {
    return CourseSchedules(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CourseSchedule extends DataClass implements Insertable<CourseSchedule> {
  final String id;
  final String courseId;
  final String semesterId;
  final int weekday;
  final int startSection;
  final int endSection;
  final String classroom;
  final String remark;
  const CourseSchedule({
    required this.id,
    required this.courseId,
    required this.semesterId,
    required this.weekday,
    required this.startSection,
    required this.endSection,
    required this.classroom,
    required this.remark,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['course_id'] = Variable<String>(courseId);
    map['semester_id'] = Variable<String>(semesterId);
    map['weekday'] = Variable<int>(weekday);
    map['start_section'] = Variable<int>(startSection);
    map['end_section'] = Variable<int>(endSection);
    map['classroom'] = Variable<String>(classroom);
    map['remark'] = Variable<String>(remark);
    return map;
  }

  CourseSchedulesCompanion toCompanion(bool nullToAbsent) {
    return CourseSchedulesCompanion(
      id: Value(id),
      courseId: Value(courseId),
      semesterId: Value(semesterId),
      weekday: Value(weekday),
      startSection: Value(startSection),
      endSection: Value(endSection),
      classroom: Value(classroom),
      remark: Value(remark),
    );
  }

  factory CourseSchedule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseSchedule(
      id: serializer.fromJson<String>(json['id']),
      courseId: serializer.fromJson<String>(json['course_id']),
      semesterId: serializer.fromJson<String>(json['semester_id']),
      weekday: serializer.fromJson<int>(json['weekday']),
      startSection: serializer.fromJson<int>(json['start_section']),
      endSection: serializer.fromJson<int>(json['end_section']),
      classroom: serializer.fromJson<String>(json['classroom']),
      remark: serializer.fromJson<String>(json['remark']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'course_id': serializer.toJson<String>(courseId),
      'semester_id': serializer.toJson<String>(semesterId),
      'weekday': serializer.toJson<int>(weekday),
      'start_section': serializer.toJson<int>(startSection),
      'end_section': serializer.toJson<int>(endSection),
      'classroom': serializer.toJson<String>(classroom),
      'remark': serializer.toJson<String>(remark),
    };
  }

  CourseSchedule copyWith({
    String? id,
    String? courseId,
    String? semesterId,
    int? weekday,
    int? startSection,
    int? endSection,
    String? classroom,
    String? remark,
  }) => CourseSchedule(
    id: id ?? this.id,
    courseId: courseId ?? this.courseId,
    semesterId: semesterId ?? this.semesterId,
    weekday: weekday ?? this.weekday,
    startSection: startSection ?? this.startSection,
    endSection: endSection ?? this.endSection,
    classroom: classroom ?? this.classroom,
    remark: remark ?? this.remark,
  );
  CourseSchedule copyWithCompanion(CourseSchedulesCompanion data) {
    return CourseSchedule(
      id: data.id.present ? data.id.value : this.id,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      startSection: data.startSection.present
          ? data.startSection.value
          : this.startSection,
      endSection: data.endSection.present
          ? data.endSection.value
          : this.endSection,
      classroom: data.classroom.present ? data.classroom.value : this.classroom,
      remark: data.remark.present ? data.remark.value : this.remark,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseSchedule(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('semesterId: $semesterId, ')
          ..write('weekday: $weekday, ')
          ..write('startSection: $startSection, ')
          ..write('endSection: $endSection, ')
          ..write('classroom: $classroom, ')
          ..write('remark: $remark')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    courseId,
    semesterId,
    weekday,
    startSection,
    endSection,
    classroom,
    remark,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseSchedule &&
          other.id == this.id &&
          other.courseId == this.courseId &&
          other.semesterId == this.semesterId &&
          other.weekday == this.weekday &&
          other.startSection == this.startSection &&
          other.endSection == this.endSection &&
          other.classroom == this.classroom &&
          other.remark == this.remark);
}

class CourseSchedulesCompanion extends UpdateCompanion<CourseSchedule> {
  final Value<String> id;
  final Value<String> courseId;
  final Value<String> semesterId;
  final Value<int> weekday;
  final Value<int> startSection;
  final Value<int> endSection;
  final Value<String> classroom;
  final Value<String> remark;
  final Value<int> rowid;
  const CourseSchedulesCompanion({
    this.id = const Value.absent(),
    this.courseId = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.weekday = const Value.absent(),
    this.startSection = const Value.absent(),
    this.endSection = const Value.absent(),
    this.classroom = const Value.absent(),
    this.remark = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseSchedulesCompanion.insert({
    required String id,
    required String courseId,
    required String semesterId,
    required int weekday,
    required int startSection,
    required int endSection,
    required String classroom,
    this.remark = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       courseId = Value(courseId),
       semesterId = Value(semesterId),
       weekday = Value(weekday),
       startSection = Value(startSection),
       endSection = Value(endSection),
       classroom = Value(classroom);
  static Insertable<CourseSchedule> custom({
    Expression<String>? id,
    Expression<String>? courseId,
    Expression<String>? semesterId,
    Expression<int>? weekday,
    Expression<int>? startSection,
    Expression<int>? endSection,
    Expression<String>? classroom,
    Expression<String>? remark,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (courseId != null) 'course_id': courseId,
      if (semesterId != null) 'semester_id': semesterId,
      if (weekday != null) 'weekday': weekday,
      if (startSection != null) 'start_section': startSection,
      if (endSection != null) 'end_section': endSection,
      if (classroom != null) 'classroom': classroom,
      if (remark != null) 'remark': remark,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseSchedulesCompanion copyWith({
    Value<String>? id,
    Value<String>? courseId,
    Value<String>? semesterId,
    Value<int>? weekday,
    Value<int>? startSection,
    Value<int>? endSection,
    Value<String>? classroom,
    Value<String>? remark,
    Value<int>? rowid,
  }) {
    return CourseSchedulesCompanion(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      weekday: weekday ?? this.weekday,
      startSection: startSection ?? this.startSection,
      endSection: endSection ?? this.endSection,
      classroom: classroom ?? this.classroom,
      remark: remark ?? this.remark,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<String>(semesterId.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (startSection.present) {
      map['start_section'] = Variable<int>(startSection.value);
    }
    if (endSection.present) {
      map['end_section'] = Variable<int>(endSection.value);
    }
    if (classroom.present) {
      map['classroom'] = Variable<String>(classroom.value);
    }
    if (remark.present) {
      map['remark'] = Variable<String>(remark.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseSchedulesCompanion(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('semesterId: $semesterId, ')
          ..write('weekday: $weekday, ')
          ..write('startSection: $startSection, ')
          ..write('endSection: $endSection, ')
          ..write('classroom: $classroom, ')
          ..write('remark: $remark, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ScheduleWeeks extends Table with TableInfo<ScheduleWeeks, ScheduleWeek> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ScheduleWeeks(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  late final GeneratedColumn<String> scheduleId = GeneratedColumn<String>(
    'schedule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES course_schedules(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _activeWeekMeta = const VerificationMeta(
    'activeWeek',
  );
  late final GeneratedColumn<int> activeWeek = GeneratedColumn<int>(
    'active_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (active_week >= 1)',
  );
  @override
  List<GeneratedColumn> get $columns => [scheduleId, activeWeek];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_weeks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduleWeek> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('schedule_id')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['schedule_id']!, _scheduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scheduleIdMeta);
    }
    if (data.containsKey('active_week')) {
      context.handle(
        _activeWeekMeta,
        activeWeek.isAcceptableOrUnknown(data['active_week']!, _activeWeekMeta),
      );
    } else if (isInserting) {
      context.missing(_activeWeekMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scheduleId, activeWeek};
  @override
  ScheduleWeek map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleWeek(
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_id'],
      )!,
      activeWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_week'],
      )!,
    );
  }

  @override
  ScheduleWeeks createAlias(String alias) {
    return ScheduleWeeks(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(schedule_id, active_week)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ScheduleWeek extends DataClass implements Insertable<ScheduleWeek> {
  final String scheduleId;
  final int activeWeek;
  const ScheduleWeek({required this.scheduleId, required this.activeWeek});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['schedule_id'] = Variable<String>(scheduleId);
    map['active_week'] = Variable<int>(activeWeek);
    return map;
  }

  ScheduleWeeksCompanion toCompanion(bool nullToAbsent) {
    return ScheduleWeeksCompanion(
      scheduleId: Value(scheduleId),
      activeWeek: Value(activeWeek),
    );
  }

  factory ScheduleWeek.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleWeek(
      scheduleId: serializer.fromJson<String>(json['schedule_id']),
      activeWeek: serializer.fromJson<int>(json['active_week']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'schedule_id': serializer.toJson<String>(scheduleId),
      'active_week': serializer.toJson<int>(activeWeek),
    };
  }

  ScheduleWeek copyWith({String? scheduleId, int? activeWeek}) => ScheduleWeek(
    scheduleId: scheduleId ?? this.scheduleId,
    activeWeek: activeWeek ?? this.activeWeek,
  );
  ScheduleWeek copyWithCompanion(ScheduleWeeksCompanion data) {
    return ScheduleWeek(
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      activeWeek: data.activeWeek.present
          ? data.activeWeek.value
          : this.activeWeek,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleWeek(')
          ..write('scheduleId: $scheduleId, ')
          ..write('activeWeek: $activeWeek')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scheduleId, activeWeek);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleWeek &&
          other.scheduleId == this.scheduleId &&
          other.activeWeek == this.activeWeek);
}

class ScheduleWeeksCompanion extends UpdateCompanion<ScheduleWeek> {
  final Value<String> scheduleId;
  final Value<int> activeWeek;
  final Value<int> rowid;
  const ScheduleWeeksCompanion({
    this.scheduleId = const Value.absent(),
    this.activeWeek = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScheduleWeeksCompanion.insert({
    required String scheduleId,
    required int activeWeek,
    this.rowid = const Value.absent(),
  }) : scheduleId = Value(scheduleId),
       activeWeek = Value(activeWeek);
  static Insertable<ScheduleWeek> custom({
    Expression<String>? scheduleId,
    Expression<int>? activeWeek,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (activeWeek != null) 'active_week': activeWeek,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScheduleWeeksCompanion copyWith({
    Value<String>? scheduleId,
    Value<int>? activeWeek,
    Value<int>? rowid,
  }) {
    return ScheduleWeeksCompanion(
      scheduleId: scheduleId ?? this.scheduleId,
      activeWeek: activeWeek ?? this.activeWeek,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scheduleId.present) {
      map['schedule_id'] = Variable<String>(scheduleId.value);
    }
    if (activeWeek.present) {
      map['active_week'] = Variable<int>(activeWeek.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleWeeksCompanion(')
          ..write('scheduleId: $scheduleId, ')
          ..write('activeWeek: $activeWeek, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ClassTimes extends Table with TableInfo<ClassTimes, ClassTime> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ClassTimes(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  late final GeneratedColumn<String> semesterId = GeneratedColumn<String>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES semesters(id)',
  );
  static const VerificationMeta _sectionMeta = const VerificationMeta(
    'section',
  );
  late final GeneratedColumn<int> section = GeneratedColumn<int>(
    'section',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (section >= 1)',
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (start_time GLOB \'[0-2][0-9]:[0-5][0-9]\' AND start_time < \'24:00\')',
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (end_time GLOB \'[0-2][0-9]:[0-5][0-9]\' AND end_time < \'24:00\')',
  );
  @override
  List<GeneratedColumn> get $columns => [
    semesterId,
    section,
    startTime,
    endTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'class_times';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClassTime> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('section')) {
      context.handle(
        _sectionMeta,
        section.isAcceptableOrUnknown(data['section']!, _sectionMeta),
      );
    } else if (isInserting) {
      context.missing(_sectionMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {semesterId, section};
  @override
  ClassTime map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassTime(
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semester_id'],
      )!,
      section: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}section'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      )!,
    );
  }

  @override
  ClassTimes createAlias(String alias) {
    return ClassTimes(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(semester_id, section)',
    'CHECK(end_time > start_time)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ClassTime extends DataClass implements Insertable<ClassTime> {
  final String semesterId;
  final int section;
  final String startTime;
  final String endTime;
  const ClassTime({
    required this.semesterId,
    required this.section,
    required this.startTime,
    required this.endTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['semester_id'] = Variable<String>(semesterId);
    map['section'] = Variable<int>(section);
    map['start_time'] = Variable<String>(startTime);
    map['end_time'] = Variable<String>(endTime);
    return map;
  }

  ClassTimesCompanion toCompanion(bool nullToAbsent) {
    return ClassTimesCompanion(
      semesterId: Value(semesterId),
      section: Value(section),
      startTime: Value(startTime),
      endTime: Value(endTime),
    );
  }

  factory ClassTime.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassTime(
      semesterId: serializer.fromJson<String>(json['semester_id']),
      section: serializer.fromJson<int>(json['section']),
      startTime: serializer.fromJson<String>(json['start_time']),
      endTime: serializer.fromJson<String>(json['end_time']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'semester_id': serializer.toJson<String>(semesterId),
      'section': serializer.toJson<int>(section),
      'start_time': serializer.toJson<String>(startTime),
      'end_time': serializer.toJson<String>(endTime),
    };
  }

  ClassTime copyWith({
    String? semesterId,
    int? section,
    String? startTime,
    String? endTime,
  }) => ClassTime(
    semesterId: semesterId ?? this.semesterId,
    section: section ?? this.section,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
  );
  ClassTime copyWithCompanion(ClassTimesCompanion data) {
    return ClassTime(
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      section: data.section.present ? data.section.value : this.section,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassTime(')
          ..write('semesterId: $semesterId, ')
          ..write('section: $section, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(semesterId, section, startTime, endTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassTime &&
          other.semesterId == this.semesterId &&
          other.section == this.section &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime);
}

class ClassTimesCompanion extends UpdateCompanion<ClassTime> {
  final Value<String> semesterId;
  final Value<int> section;
  final Value<String> startTime;
  final Value<String> endTime;
  final Value<int> rowid;
  const ClassTimesCompanion({
    this.semesterId = const Value.absent(),
    this.section = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClassTimesCompanion.insert({
    required String semesterId,
    required int section,
    required String startTime,
    required String endTime,
    this.rowid = const Value.absent(),
  }) : semesterId = Value(semesterId),
       section = Value(section),
       startTime = Value(startTime),
       endTime = Value(endTime);
  static Insertable<ClassTime> custom({
    Expression<String>? semesterId,
    Expression<int>? section,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (semesterId != null) 'semester_id': semesterId,
      if (section != null) 'section': section,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClassTimesCompanion copyWith({
    Value<String>? semesterId,
    Value<int>? section,
    Value<String>? startTime,
    Value<String>? endTime,
    Value<int>? rowid,
  }) {
    return ClassTimesCompanion(
      semesterId: semesterId ?? this.semesterId,
      section: section ?? this.section,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (semesterId.present) {
      map['semester_id'] = Variable<String>(semesterId.value);
    }
    if (section.present) {
      map['section'] = Variable<int>(section.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassTimesCompanion(')
          ..write('semesterId: $semesterId, ')
          ..write('section: $section, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class TaskEvents extends Table with TableInfo<TaskEvents, TaskEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  TaskEvents(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(trim(id)) > 0)',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(title)) > 0)',
  );
  static const VerificationMeta _eventDateMeta = const VerificationMeta(
    'eventDate',
  );
  late final GeneratedColumn<String> eventDate = GeneratedColumn<String>(
    'event_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(event_date) = 10 AND COALESCE(date(event_date, \'+0 days\') = event_date, 0))',
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (start_time GLOB \'[0-2][0-9]:[0-5][0-9]\' AND start_time < \'24:00\')',
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (end_time GLOB \'[0-2][0-9]:[0-5][0-9]\' AND end_time < \'24:00\')',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  late final GeneratedColumn<int> completed = GeneratedColumn<int>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (completed IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _reminderMinutesMeta = const VerificationMeta(
    'reminderMinutes',
  );
  late final GeneratedColumn<int> reminderMinutes = GeneratedColumn<int>(
    'reminder_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (reminder_minutes >= 0)',
  );
  static const VerificationMeta _repeatRuleMeta = const VerificationMeta(
    'repeatRule',
  );
  late final GeneratedColumn<String> repeatRule = GeneratedColumn<String>(
    'repeat_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (repeat_rule IS NULL)',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    eventDate,
    startTime,
    endTime,
    description,
    completed,
    reminderMinutes,
    repeatRule,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('event_date')) {
      context.handle(
        _eventDateMeta,
        eventDate.isAcceptableOrUnknown(data['event_date']!, _eventDateMeta),
      );
    } else if (isInserting) {
      context.missing(_eventDateMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('reminder_minutes')) {
      context.handle(
        _reminderMinutesMeta,
        reminderMinutes.isAcceptableOrUnknown(
          data['reminder_minutes']!,
          _reminderMinutesMeta,
        ),
      );
    }
    if (data.containsKey('repeat_rule')) {
      context.handle(
        _repeatRuleMeta,
        repeatRule.isAcceptableOrUnknown(data['repeat_rule']!, _repeatRuleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      eventDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_date'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      ),
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed'],
      )!,
      reminderMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes'],
      ),
      repeatRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_rule'],
      ),
    );
  }

  @override
  TaskEvents createAlias(String alias) {
    return TaskEvents(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK((start_time IS NULL AND end_time IS NULL AND reminder_minutes IS NULL)OR(start_time IS NOT NULL AND end_time IS NOT NULL AND end_time > start_time))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class TaskEvent extends DataClass implements Insertable<TaskEvent> {
  final String id;
  final String title;
  final String eventDate;
  final String? startTime;
  final String? endTime;
  final String description;
  final int completed;
  final int? reminderMinutes;
  final String? repeatRule;
  const TaskEvent({
    required this.id,
    required this.title,
    required this.eventDate,
    this.startTime,
    this.endTime,
    required this.description,
    required this.completed,
    this.reminderMinutes,
    this.repeatRule,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['event_date'] = Variable<String>(eventDate);
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<String>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<String>(endTime);
    }
    map['description'] = Variable<String>(description);
    map['completed'] = Variable<int>(completed);
    if (!nullToAbsent || reminderMinutes != null) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes);
    }
    if (!nullToAbsent || repeatRule != null) {
      map['repeat_rule'] = Variable<String>(repeatRule);
    }
    return map;
  }

  TaskEventsCompanion toCompanion(bool nullToAbsent) {
    return TaskEventsCompanion(
      id: Value(id),
      title: Value(title),
      eventDate: Value(eventDate),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      description: Value(description),
      completed: Value(completed),
      reminderMinutes: reminderMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinutes),
      repeatRule: repeatRule == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatRule),
    );
  }

  factory TaskEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskEvent(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      eventDate: serializer.fromJson<String>(json['event_date']),
      startTime: serializer.fromJson<String?>(json['start_time']),
      endTime: serializer.fromJson<String?>(json['end_time']),
      description: serializer.fromJson<String>(json['description']),
      completed: serializer.fromJson<int>(json['completed']),
      reminderMinutes: serializer.fromJson<int?>(json['reminder_minutes']),
      repeatRule: serializer.fromJson<String?>(json['repeat_rule']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'event_date': serializer.toJson<String>(eventDate),
      'start_time': serializer.toJson<String?>(startTime),
      'end_time': serializer.toJson<String?>(endTime),
      'description': serializer.toJson<String>(description),
      'completed': serializer.toJson<int>(completed),
      'reminder_minutes': serializer.toJson<int?>(reminderMinutes),
      'repeat_rule': serializer.toJson<String?>(repeatRule),
    };
  }

  TaskEvent copyWith({
    String? id,
    String? title,
    String? eventDate,
    Value<String?> startTime = const Value.absent(),
    Value<String?> endTime = const Value.absent(),
    String? description,
    int? completed,
    Value<int?> reminderMinutes = const Value.absent(),
    Value<String?> repeatRule = const Value.absent(),
  }) => TaskEvent(
    id: id ?? this.id,
    title: title ?? this.title,
    eventDate: eventDate ?? this.eventDate,
    startTime: startTime.present ? startTime.value : this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    description: description ?? this.description,
    completed: completed ?? this.completed,
    reminderMinutes: reminderMinutes.present
        ? reminderMinutes.value
        : this.reminderMinutes,
    repeatRule: repeatRule.present ? repeatRule.value : this.repeatRule,
  );
  TaskEvent copyWithCompanion(TaskEventsCompanion data) {
    return TaskEvent(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      eventDate: data.eventDate.present ? data.eventDate.value : this.eventDate,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      description: data.description.present
          ? data.description.value
          : this.description,
      completed: data.completed.present ? data.completed.value : this.completed,
      reminderMinutes: data.reminderMinutes.present
          ? data.reminderMinutes.value
          : this.reminderMinutes,
      repeatRule: data.repeatRule.present
          ? data.repeatRule.value
          : this.repeatRule,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskEvent(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('eventDate: $eventDate, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('description: $description, ')
          ..write('completed: $completed, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('repeatRule: $repeatRule')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    eventDate,
    startTime,
    endTime,
    description,
    completed,
    reminderMinutes,
    repeatRule,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskEvent &&
          other.id == this.id &&
          other.title == this.title &&
          other.eventDate == this.eventDate &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.description == this.description &&
          other.completed == this.completed &&
          other.reminderMinutes == this.reminderMinutes &&
          other.repeatRule == this.repeatRule);
}

class TaskEventsCompanion extends UpdateCompanion<TaskEvent> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> eventDate;
  final Value<String?> startTime;
  final Value<String?> endTime;
  final Value<String> description;
  final Value<int> completed;
  final Value<int?> reminderMinutes;
  final Value<String?> repeatRule;
  final Value<int> rowid;
  const TaskEventsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.eventDate = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.description = const Value.absent(),
    this.completed = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskEventsCompanion.insert({
    required String id,
    required String title,
    required String eventDate,
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.description = const Value.absent(),
    this.completed = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       eventDate = Value(eventDate);
  static Insertable<TaskEvent> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? eventDate,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? description,
    Expression<int>? completed,
    Expression<int>? reminderMinutes,
    Expression<String>? repeatRule,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (eventDate != null) 'event_date': eventDate,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (description != null) 'description': description,
      if (completed != null) 'completed': completed,
      if (reminderMinutes != null) 'reminder_minutes': reminderMinutes,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? eventDate,
    Value<String?>? startTime,
    Value<String?>? endTime,
    Value<String>? description,
    Value<int>? completed,
    Value<int?>? reminderMinutes,
    Value<String?>? repeatRule,
    Value<int>? rowid,
  }) {
    return TaskEventsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      repeatRule: repeatRule ?? this.repeatRule,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (eventDate.present) {
      map['event_date'] = Variable<String>(eventDate.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (completed.present) {
      map['completed'] = Variable<int>(completed.value);
    }
    if (reminderMinutes.present) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes.value);
    }
    if (repeatRule.present) {
      map['repeat_rule'] = Variable<String>(repeatRule.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskEventsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('eventDate: $eventDate, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('description: $description, ')
          ..write('completed: $completed, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ImportDrafts extends Table with TableInfo<ImportDrafts, ImportDraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ImportDrafts(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceHashMeta = const VerificationMeta(
    'sourceHash',
  );
  late final GeneratedColumn<String> sourceHash = GeneratedColumn<String>(
    'source_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _currentRevisionMeta = const VerificationMeta(
    'currentRevision',
  );
  late final GeneratedColumn<int> currentRevision = GeneratedColumn<int>(
    'current_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (current_revision >= 1)',
  );
  static const VerificationMeta _originalJsonMeta = const VerificationMeta(
    'originalJson',
  );
  late final GeneratedColumn<String> originalJson = GeneratedColumn<String>(
    'original_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (json_valid(original_json))',
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceHash,
    currentRevision,
    originalJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportDraft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_hash')) {
      context.handle(
        _sourceHashMeta,
        sourceHash.isAcceptableOrUnknown(data['source_hash']!, _sourceHashMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceHashMeta);
    }
    if (data.containsKey('current_revision')) {
      context.handle(
        _currentRevisionMeta,
        currentRevision.isAcceptableOrUnknown(
          data['current_revision']!,
          _currentRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentRevisionMeta);
    }
    if (data.containsKey('original_json')) {
      context.handle(
        _originalJsonMeta,
        originalJson.isAcceptableOrUnknown(
          data['original_json']!,
          _originalJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceHash};
  @override
  ImportDraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportDraft(
      sourceHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_hash'],
      )!,
      currentRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_revision'],
      )!,
      originalJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_json'],
      )!,
    );
  }

  @override
  ImportDrafts createAlias(String alias) {
    return ImportDrafts(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ImportDraft extends DataClass implements Insertable<ImportDraft> {
  final String sourceHash;
  final int currentRevision;
  final String originalJson;
  const ImportDraft({
    required this.sourceHash,
    required this.currentRevision,
    required this.originalJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_hash'] = Variable<String>(sourceHash);
    map['current_revision'] = Variable<int>(currentRevision);
    map['original_json'] = Variable<String>(originalJson);
    return map;
  }

  ImportDraftsCompanion toCompanion(bool nullToAbsent) {
    return ImportDraftsCompanion(
      sourceHash: Value(sourceHash),
      currentRevision: Value(currentRevision),
      originalJson: Value(originalJson),
    );
  }

  factory ImportDraft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportDraft(
      sourceHash: serializer.fromJson<String>(json['source_hash']),
      currentRevision: serializer.fromJson<int>(json['current_revision']),
      originalJson: serializer.fromJson<String>(json['original_json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source_hash': serializer.toJson<String>(sourceHash),
      'current_revision': serializer.toJson<int>(currentRevision),
      'original_json': serializer.toJson<String>(originalJson),
    };
  }

  ImportDraft copyWith({
    String? sourceHash,
    int? currentRevision,
    String? originalJson,
  }) => ImportDraft(
    sourceHash: sourceHash ?? this.sourceHash,
    currentRevision: currentRevision ?? this.currentRevision,
    originalJson: originalJson ?? this.originalJson,
  );
  ImportDraft copyWithCompanion(ImportDraftsCompanion data) {
    return ImportDraft(
      sourceHash: data.sourceHash.present
          ? data.sourceHash.value
          : this.sourceHash,
      currentRevision: data.currentRevision.present
          ? data.currentRevision.value
          : this.currentRevision,
      originalJson: data.originalJson.present
          ? data.originalJson.value
          : this.originalJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportDraft(')
          ..write('sourceHash: $sourceHash, ')
          ..write('currentRevision: $currentRevision, ')
          ..write('originalJson: $originalJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sourceHash, currentRevision, originalJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportDraft &&
          other.sourceHash == this.sourceHash &&
          other.currentRevision == this.currentRevision &&
          other.originalJson == this.originalJson);
}

class ImportDraftsCompanion extends UpdateCompanion<ImportDraft> {
  final Value<String> sourceHash;
  final Value<int> currentRevision;
  final Value<String> originalJson;
  final Value<int> rowid;
  const ImportDraftsCompanion({
    this.sourceHash = const Value.absent(),
    this.currentRevision = const Value.absent(),
    this.originalJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportDraftsCompanion.insert({
    required String sourceHash,
    required int currentRevision,
    required String originalJson,
    this.rowid = const Value.absent(),
  }) : sourceHash = Value(sourceHash),
       currentRevision = Value(currentRevision),
       originalJson = Value(originalJson);
  static Insertable<ImportDraft> custom({
    Expression<String>? sourceHash,
    Expression<int>? currentRevision,
    Expression<String>? originalJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceHash != null) 'source_hash': sourceHash,
      if (currentRevision != null) 'current_revision': currentRevision,
      if (originalJson != null) 'original_json': originalJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportDraftsCompanion copyWith({
    Value<String>? sourceHash,
    Value<int>? currentRevision,
    Value<String>? originalJson,
    Value<int>? rowid,
  }) {
    return ImportDraftsCompanion(
      sourceHash: sourceHash ?? this.sourceHash,
      currentRevision: currentRevision ?? this.currentRevision,
      originalJson: originalJson ?? this.originalJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceHash.present) {
      map['source_hash'] = Variable<String>(sourceHash.value);
    }
    if (currentRevision.present) {
      map['current_revision'] = Variable<int>(currentRevision.value);
    }
    if (originalJson.present) {
      map['original_json'] = Variable<String>(originalJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportDraftsCompanion(')
          ..write('sourceHash: $sourceHash, ')
          ..write('currentRevision: $currentRevision, ')
          ..write('originalJson: $originalJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ImportRevisions extends Table
    with TableInfo<ImportRevisions, ImportRevision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ImportRevisions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceHashMeta = const VerificationMeta(
    'sourceHash',
  );
  late final GeneratedColumn<String> sourceHash = GeneratedColumn<String>(
    'source_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES import_drafts(source_hash)',
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (revision >= 1)',
  );
  static const VerificationMeta _reviewedJsonMeta = const VerificationMeta(
    'reviewedJson',
  );
  late final GeneratedColumn<String> reviewedJson = GeneratedColumn<String>(
    'reviewed_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (json_valid(reviewed_json))',
  );
  static const VerificationMeta _exclusionsJsonMeta = const VerificationMeta(
    'exclusionsJson',
  );
  late final GeneratedColumn<String> exclusionsJson = GeneratedColumn<String>(
    'exclusions_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (json_valid(exclusions_json))',
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceHash,
    revision,
    reviewedJson,
    exclusionsJson,
    reason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportRevision> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_hash')) {
      context.handle(
        _sourceHashMeta,
        sourceHash.isAcceptableOrUnknown(data['source_hash']!, _sourceHashMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceHashMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('reviewed_json')) {
      context.handle(
        _reviewedJsonMeta,
        reviewedJson.isAcceptableOrUnknown(
          data['reviewed_json']!,
          _reviewedJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reviewedJsonMeta);
    }
    if (data.containsKey('exclusions_json')) {
      context.handle(
        _exclusionsJsonMeta,
        exclusionsJson.isAcceptableOrUnknown(
          data['exclusions_json']!,
          _exclusionsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exclusionsJsonMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceHash, revision};
  @override
  ImportRevision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportRevision(
      sourceHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_hash'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      reviewedJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reviewed_json'],
      )!,
      exclusionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exclusions_json'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
    );
  }

  @override
  ImportRevisions createAlias(String alias) {
    return ImportRevisions(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(source_hash, revision)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ImportRevision extends DataClass implements Insertable<ImportRevision> {
  final String sourceHash;
  final int revision;
  final String reviewedJson;
  final String exclusionsJson;
  final String reason;
  const ImportRevision({
    required this.sourceHash,
    required this.revision,
    required this.reviewedJson,
    required this.exclusionsJson,
    required this.reason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_hash'] = Variable<String>(sourceHash);
    map['revision'] = Variable<int>(revision);
    map['reviewed_json'] = Variable<String>(reviewedJson);
    map['exclusions_json'] = Variable<String>(exclusionsJson);
    map['reason'] = Variable<String>(reason);
    return map;
  }

  ImportRevisionsCompanion toCompanion(bool nullToAbsent) {
    return ImportRevisionsCompanion(
      sourceHash: Value(sourceHash),
      revision: Value(revision),
      reviewedJson: Value(reviewedJson),
      exclusionsJson: Value(exclusionsJson),
      reason: Value(reason),
    );
  }

  factory ImportRevision.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportRevision(
      sourceHash: serializer.fromJson<String>(json['source_hash']),
      revision: serializer.fromJson<int>(json['revision']),
      reviewedJson: serializer.fromJson<String>(json['reviewed_json']),
      exclusionsJson: serializer.fromJson<String>(json['exclusions_json']),
      reason: serializer.fromJson<String>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source_hash': serializer.toJson<String>(sourceHash),
      'revision': serializer.toJson<int>(revision),
      'reviewed_json': serializer.toJson<String>(reviewedJson),
      'exclusions_json': serializer.toJson<String>(exclusionsJson),
      'reason': serializer.toJson<String>(reason),
    };
  }

  ImportRevision copyWith({
    String? sourceHash,
    int? revision,
    String? reviewedJson,
    String? exclusionsJson,
    String? reason,
  }) => ImportRevision(
    sourceHash: sourceHash ?? this.sourceHash,
    revision: revision ?? this.revision,
    reviewedJson: reviewedJson ?? this.reviewedJson,
    exclusionsJson: exclusionsJson ?? this.exclusionsJson,
    reason: reason ?? this.reason,
  );
  ImportRevision copyWithCompanion(ImportRevisionsCompanion data) {
    return ImportRevision(
      sourceHash: data.sourceHash.present
          ? data.sourceHash.value
          : this.sourceHash,
      revision: data.revision.present ? data.revision.value : this.revision,
      reviewedJson: data.reviewedJson.present
          ? data.reviewedJson.value
          : this.reviewedJson,
      exclusionsJson: data.exclusionsJson.present
          ? data.exclusionsJson.value
          : this.exclusionsJson,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportRevision(')
          ..write('sourceHash: $sourceHash, ')
          ..write('revision: $revision, ')
          ..write('reviewedJson: $reviewedJson, ')
          ..write('exclusionsJson: $exclusionsJson, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(sourceHash, revision, reviewedJson, exclusionsJson, reason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportRevision &&
          other.sourceHash == this.sourceHash &&
          other.revision == this.revision &&
          other.reviewedJson == this.reviewedJson &&
          other.exclusionsJson == this.exclusionsJson &&
          other.reason == this.reason);
}

class ImportRevisionsCompanion extends UpdateCompanion<ImportRevision> {
  final Value<String> sourceHash;
  final Value<int> revision;
  final Value<String> reviewedJson;
  final Value<String> exclusionsJson;
  final Value<String> reason;
  final Value<int> rowid;
  const ImportRevisionsCompanion({
    this.sourceHash = const Value.absent(),
    this.revision = const Value.absent(),
    this.reviewedJson = const Value.absent(),
    this.exclusionsJson = const Value.absent(),
    this.reason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportRevisionsCompanion.insert({
    required String sourceHash,
    required int revision,
    required String reviewedJson,
    required String exclusionsJson,
    required String reason,
    this.rowid = const Value.absent(),
  }) : sourceHash = Value(sourceHash),
       revision = Value(revision),
       reviewedJson = Value(reviewedJson),
       exclusionsJson = Value(exclusionsJson),
       reason = Value(reason);
  static Insertable<ImportRevision> custom({
    Expression<String>? sourceHash,
    Expression<int>? revision,
    Expression<String>? reviewedJson,
    Expression<String>? exclusionsJson,
    Expression<String>? reason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceHash != null) 'source_hash': sourceHash,
      if (revision != null) 'revision': revision,
      if (reviewedJson != null) 'reviewed_json': reviewedJson,
      if (exclusionsJson != null) 'exclusions_json': exclusionsJson,
      if (reason != null) 'reason': reason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportRevisionsCompanion copyWith({
    Value<String>? sourceHash,
    Value<int>? revision,
    Value<String>? reviewedJson,
    Value<String>? exclusionsJson,
    Value<String>? reason,
    Value<int>? rowid,
  }) {
    return ImportRevisionsCompanion(
      sourceHash: sourceHash ?? this.sourceHash,
      revision: revision ?? this.revision,
      reviewedJson: reviewedJson ?? this.reviewedJson,
      exclusionsJson: exclusionsJson ?? this.exclusionsJson,
      reason: reason ?? this.reason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceHash.present) {
      map['source_hash'] = Variable<String>(sourceHash.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (reviewedJson.present) {
      map['reviewed_json'] = Variable<String>(reviewedJson.value);
    }
    if (exclusionsJson.present) {
      map['exclusions_json'] = Variable<String>(exclusionsJson.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportRevisionsCompanion(')
          ..write('sourceHash: $sourceHash, ')
          ..write('revision: $revision, ')
          ..write('reviewedJson: $reviewedJson, ')
          ..write('exclusionsJson: $exclusionsJson, ')
          ..write('reason: $reason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ImportCommits extends Table with TableInfo<ImportCommits, ImportCommit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ImportCommits(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceHashMeta = const VerificationMeta(
    'sourceHash',
  );
  late final GeneratedColumn<String> sourceHash = GeneratedColumn<String>(
    'source_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  late final GeneratedColumn<String> semesterId = GeneratedColumn<String>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE REFERENCES semesters(id)',
  );
  static const VerificationMeta _courseCountMeta = const VerificationMeta(
    'courseCount',
  );
  late final GeneratedColumn<int> courseCount = GeneratedColumn<int>(
    'course_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _scheduleCountMeta = const VerificationMeta(
    'scheduleCount',
  );
  late final GeneratedColumn<int> scheduleCount = GeneratedColumn<int>(
    'schedule_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceHash,
    revision,
    semesterId,
    courseCount,
    scheduleCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_commits';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportCommit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_hash')) {
      context.handle(
        _sourceHashMeta,
        sourceHash.isAcceptableOrUnknown(data['source_hash']!, _sourceHashMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceHashMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('course_count')) {
      context.handle(
        _courseCountMeta,
        courseCount.isAcceptableOrUnknown(
          data['course_count']!,
          _courseCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_courseCountMeta);
    }
    if (data.containsKey('schedule_count')) {
      context.handle(
        _scheduleCountMeta,
        scheduleCount.isAcceptableOrUnknown(
          data['schedule_count']!,
          _scheduleCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduleCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceHash};
  @override
  ImportCommit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportCommit(
      sourceHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_hash'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semester_id'],
      )!,
      courseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_count'],
      )!,
      scheduleCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schedule_count'],
      )!,
    );
  }

  @override
  ImportCommits createAlias(String alias) {
    return ImportCommits(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY(source_hash, revision)REFERENCES import_revisions(source_hash, revision)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ImportCommit extends DataClass implements Insertable<ImportCommit> {
  final String sourceHash;
  final int revision;
  final String semesterId;
  final int courseCount;
  final int scheduleCount;
  const ImportCommit({
    required this.sourceHash,
    required this.revision,
    required this.semesterId,
    required this.courseCount,
    required this.scheduleCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_hash'] = Variable<String>(sourceHash);
    map['revision'] = Variable<int>(revision);
    map['semester_id'] = Variable<String>(semesterId);
    map['course_count'] = Variable<int>(courseCount);
    map['schedule_count'] = Variable<int>(scheduleCount);
    return map;
  }

  ImportCommitsCompanion toCompanion(bool nullToAbsent) {
    return ImportCommitsCompanion(
      sourceHash: Value(sourceHash),
      revision: Value(revision),
      semesterId: Value(semesterId),
      courseCount: Value(courseCount),
      scheduleCount: Value(scheduleCount),
    );
  }

  factory ImportCommit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportCommit(
      sourceHash: serializer.fromJson<String>(json['source_hash']),
      revision: serializer.fromJson<int>(json['revision']),
      semesterId: serializer.fromJson<String>(json['semester_id']),
      courseCount: serializer.fromJson<int>(json['course_count']),
      scheduleCount: serializer.fromJson<int>(json['schedule_count']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source_hash': serializer.toJson<String>(sourceHash),
      'revision': serializer.toJson<int>(revision),
      'semester_id': serializer.toJson<String>(semesterId),
      'course_count': serializer.toJson<int>(courseCount),
      'schedule_count': serializer.toJson<int>(scheduleCount),
    };
  }

  ImportCommit copyWith({
    String? sourceHash,
    int? revision,
    String? semesterId,
    int? courseCount,
    int? scheduleCount,
  }) => ImportCommit(
    sourceHash: sourceHash ?? this.sourceHash,
    revision: revision ?? this.revision,
    semesterId: semesterId ?? this.semesterId,
    courseCount: courseCount ?? this.courseCount,
    scheduleCount: scheduleCount ?? this.scheduleCount,
  );
  ImportCommit copyWithCompanion(ImportCommitsCompanion data) {
    return ImportCommit(
      sourceHash: data.sourceHash.present
          ? data.sourceHash.value
          : this.sourceHash,
      revision: data.revision.present ? data.revision.value : this.revision,
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      courseCount: data.courseCount.present
          ? data.courseCount.value
          : this.courseCount,
      scheduleCount: data.scheduleCount.present
          ? data.scheduleCount.value
          : this.scheduleCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportCommit(')
          ..write('sourceHash: $sourceHash, ')
          ..write('revision: $revision, ')
          ..write('semesterId: $semesterId, ')
          ..write('courseCount: $courseCount, ')
          ..write('scheduleCount: $scheduleCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(sourceHash, revision, semesterId, courseCount, scheduleCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportCommit &&
          other.sourceHash == this.sourceHash &&
          other.revision == this.revision &&
          other.semesterId == this.semesterId &&
          other.courseCount == this.courseCount &&
          other.scheduleCount == this.scheduleCount);
}

class ImportCommitsCompanion extends UpdateCompanion<ImportCommit> {
  final Value<String> sourceHash;
  final Value<int> revision;
  final Value<String> semesterId;
  final Value<int> courseCount;
  final Value<int> scheduleCount;
  final Value<int> rowid;
  const ImportCommitsCompanion({
    this.sourceHash = const Value.absent(),
    this.revision = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.courseCount = const Value.absent(),
    this.scheduleCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportCommitsCompanion.insert({
    required String sourceHash,
    required int revision,
    required String semesterId,
    required int courseCount,
    required int scheduleCount,
    this.rowid = const Value.absent(),
  }) : sourceHash = Value(sourceHash),
       revision = Value(revision),
       semesterId = Value(semesterId),
       courseCount = Value(courseCount),
       scheduleCount = Value(scheduleCount);
  static Insertable<ImportCommit> custom({
    Expression<String>? sourceHash,
    Expression<int>? revision,
    Expression<String>? semesterId,
    Expression<int>? courseCount,
    Expression<int>? scheduleCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceHash != null) 'source_hash': sourceHash,
      if (revision != null) 'revision': revision,
      if (semesterId != null) 'semester_id': semesterId,
      if (courseCount != null) 'course_count': courseCount,
      if (scheduleCount != null) 'schedule_count': scheduleCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportCommitsCompanion copyWith({
    Value<String>? sourceHash,
    Value<int>? revision,
    Value<String>? semesterId,
    Value<int>? courseCount,
    Value<int>? scheduleCount,
    Value<int>? rowid,
  }) {
    return ImportCommitsCompanion(
      sourceHash: sourceHash ?? this.sourceHash,
      revision: revision ?? this.revision,
      semesterId: semesterId ?? this.semesterId,
      courseCount: courseCount ?? this.courseCount,
      scheduleCount: scheduleCount ?? this.scheduleCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceHash.present) {
      map['source_hash'] = Variable<String>(sourceHash.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<String>(semesterId.value);
    }
    if (courseCount.present) {
      map['course_count'] = Variable<int>(courseCount.value);
    }
    if (scheduleCount.present) {
      map['schedule_count'] = Variable<int>(scheduleCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportCommitsCompanion(')
          ..write('sourceHash: $sourceHash, ')
          ..write('revision: $revision, ')
          ..write('semesterId: $semesterId, ')
          ..write('courseCount: $courseCount, ')
          ..write('scheduleCount: $scheduleCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ImportRecordMetadata extends Table
    with TableInfo<ImportRecordMetadata, ImportRecordMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ImportRecordMetadata(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  late final GeneratedColumn<String> scheduleId = GeneratedColumn<String>(
    'schedule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY REFERENCES course_schedules(id)',
  );
  static const VerificationMeta _sourceHashMeta = const VerificationMeta(
    'sourceHash',
  );
  late final GeneratedColumn<String> sourceHash = GeneratedColumn<String>(
    'source_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _draftRevisionMeta = const VerificationMeta(
    'draftRevision',
  );
  late final GeneratedColumn<int> draftRevision = GeneratedColumn<int>(
    'draft_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _teachingClassMeta = const VerificationMeta(
    'teachingClass',
  );
  late final GeneratedColumn<String> teachingClass = GeneratedColumn<String>(
    'teaching_class',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _totalHoursMeta = const VerificationMeta(
    'totalHours',
  );
  late final GeneratedColumn<int> totalHours = GeneratedColumn<int>(
    'total_hours',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _creditsMeta = const VerificationMeta(
    'credits',
  );
  late final GeneratedColumn<int> credits = GeneratedColumn<int>(
    'credits',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _sourceJsonMeta = const VerificationMeta(
    'sourceJson',
  );
  late final GeneratedColumn<String> sourceJson = GeneratedColumn<String>(
    'source_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (json_valid(source_json))',
  );
  @override
  List<GeneratedColumn> get $columns => [
    scheduleId,
    sourceHash,
    draftRevision,
    recordId,
    teachingClass,
    totalHours,
    credits,
    sourceJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_record_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportRecordMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('schedule_id')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['schedule_id']!, _scheduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scheduleIdMeta);
    }
    if (data.containsKey('source_hash')) {
      context.handle(
        _sourceHashMeta,
        sourceHash.isAcceptableOrUnknown(data['source_hash']!, _sourceHashMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceHashMeta);
    }
    if (data.containsKey('draft_revision')) {
      context.handle(
        _draftRevisionMeta,
        draftRevision.isAcceptableOrUnknown(
          data['draft_revision']!,
          _draftRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_draftRevisionMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('teaching_class')) {
      context.handle(
        _teachingClassMeta,
        teachingClass.isAcceptableOrUnknown(
          data['teaching_class']!,
          _teachingClassMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_teachingClassMeta);
    }
    if (data.containsKey('total_hours')) {
      context.handle(
        _totalHoursMeta,
        totalHours.isAcceptableOrUnknown(data['total_hours']!, _totalHoursMeta),
      );
    }
    if (data.containsKey('credits')) {
      context.handle(
        _creditsMeta,
        credits.isAcceptableOrUnknown(data['credits']!, _creditsMeta),
      );
    }
    if (data.containsKey('source_json')) {
      context.handle(
        _sourceJsonMeta,
        sourceJson.isAcceptableOrUnknown(data['source_json']!, _sourceJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scheduleId};
  @override
  ImportRecordMetadataData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportRecordMetadataData(
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_id'],
      )!,
      sourceHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_hash'],
      )!,
      draftRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}draft_revision'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      teachingClass: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teaching_class'],
      )!,
      totalHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_hours'],
      ),
      credits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}credits'],
      ),
      sourceJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_json'],
      )!,
    );
  }

  @override
  ImportRecordMetadata createAlias(String alias) {
    return ImportRecordMetadata(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY(source_hash, draft_revision)REFERENCES import_revisions(source_hash, revision)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ImportRecordMetadataData extends DataClass
    implements Insertable<ImportRecordMetadataData> {
  final String scheduleId;
  final String sourceHash;
  final int draftRevision;
  final String recordId;
  final String teachingClass;
  final int? totalHours;
  final int? credits;
  final String sourceJson;
  const ImportRecordMetadataData({
    required this.scheduleId,
    required this.sourceHash,
    required this.draftRevision,
    required this.recordId,
    required this.teachingClass,
    this.totalHours,
    this.credits,
    required this.sourceJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['schedule_id'] = Variable<String>(scheduleId);
    map['source_hash'] = Variable<String>(sourceHash);
    map['draft_revision'] = Variable<int>(draftRevision);
    map['record_id'] = Variable<String>(recordId);
    map['teaching_class'] = Variable<String>(teachingClass);
    if (!nullToAbsent || totalHours != null) {
      map['total_hours'] = Variable<int>(totalHours);
    }
    if (!nullToAbsent || credits != null) {
      map['credits'] = Variable<int>(credits);
    }
    map['source_json'] = Variable<String>(sourceJson);
    return map;
  }

  ImportRecordMetadataCompanion toCompanion(bool nullToAbsent) {
    return ImportRecordMetadataCompanion(
      scheduleId: Value(scheduleId),
      sourceHash: Value(sourceHash),
      draftRevision: Value(draftRevision),
      recordId: Value(recordId),
      teachingClass: Value(teachingClass),
      totalHours: totalHours == null && nullToAbsent
          ? const Value.absent()
          : Value(totalHours),
      credits: credits == null && nullToAbsent
          ? const Value.absent()
          : Value(credits),
      sourceJson: Value(sourceJson),
    );
  }

  factory ImportRecordMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportRecordMetadataData(
      scheduleId: serializer.fromJson<String>(json['schedule_id']),
      sourceHash: serializer.fromJson<String>(json['source_hash']),
      draftRevision: serializer.fromJson<int>(json['draft_revision']),
      recordId: serializer.fromJson<String>(json['record_id']),
      teachingClass: serializer.fromJson<String>(json['teaching_class']),
      totalHours: serializer.fromJson<int?>(json['total_hours']),
      credits: serializer.fromJson<int?>(json['credits']),
      sourceJson: serializer.fromJson<String>(json['source_json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'schedule_id': serializer.toJson<String>(scheduleId),
      'source_hash': serializer.toJson<String>(sourceHash),
      'draft_revision': serializer.toJson<int>(draftRevision),
      'record_id': serializer.toJson<String>(recordId),
      'teaching_class': serializer.toJson<String>(teachingClass),
      'total_hours': serializer.toJson<int?>(totalHours),
      'credits': serializer.toJson<int?>(credits),
      'source_json': serializer.toJson<String>(sourceJson),
    };
  }

  ImportRecordMetadataData copyWith({
    String? scheduleId,
    String? sourceHash,
    int? draftRevision,
    String? recordId,
    String? teachingClass,
    Value<int?> totalHours = const Value.absent(),
    Value<int?> credits = const Value.absent(),
    String? sourceJson,
  }) => ImportRecordMetadataData(
    scheduleId: scheduleId ?? this.scheduleId,
    sourceHash: sourceHash ?? this.sourceHash,
    draftRevision: draftRevision ?? this.draftRevision,
    recordId: recordId ?? this.recordId,
    teachingClass: teachingClass ?? this.teachingClass,
    totalHours: totalHours.present ? totalHours.value : this.totalHours,
    credits: credits.present ? credits.value : this.credits,
    sourceJson: sourceJson ?? this.sourceJson,
  );
  ImportRecordMetadataData copyWithCompanion(
    ImportRecordMetadataCompanion data,
  ) {
    return ImportRecordMetadataData(
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      sourceHash: data.sourceHash.present
          ? data.sourceHash.value
          : this.sourceHash,
      draftRevision: data.draftRevision.present
          ? data.draftRevision.value
          : this.draftRevision,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      teachingClass: data.teachingClass.present
          ? data.teachingClass.value
          : this.teachingClass,
      totalHours: data.totalHours.present
          ? data.totalHours.value
          : this.totalHours,
      credits: data.credits.present ? data.credits.value : this.credits,
      sourceJson: data.sourceJson.present
          ? data.sourceJson.value
          : this.sourceJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportRecordMetadataData(')
          ..write('scheduleId: $scheduleId, ')
          ..write('sourceHash: $sourceHash, ')
          ..write('draftRevision: $draftRevision, ')
          ..write('recordId: $recordId, ')
          ..write('teachingClass: $teachingClass, ')
          ..write('totalHours: $totalHours, ')
          ..write('credits: $credits, ')
          ..write('sourceJson: $sourceJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    scheduleId,
    sourceHash,
    draftRevision,
    recordId,
    teachingClass,
    totalHours,
    credits,
    sourceJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportRecordMetadataData &&
          other.scheduleId == this.scheduleId &&
          other.sourceHash == this.sourceHash &&
          other.draftRevision == this.draftRevision &&
          other.recordId == this.recordId &&
          other.teachingClass == this.teachingClass &&
          other.totalHours == this.totalHours &&
          other.credits == this.credits &&
          other.sourceJson == this.sourceJson);
}

class ImportRecordMetadataCompanion
    extends UpdateCompanion<ImportRecordMetadataData> {
  final Value<String> scheduleId;
  final Value<String> sourceHash;
  final Value<int> draftRevision;
  final Value<String> recordId;
  final Value<String> teachingClass;
  final Value<int?> totalHours;
  final Value<int?> credits;
  final Value<String> sourceJson;
  final Value<int> rowid;
  const ImportRecordMetadataCompanion({
    this.scheduleId = const Value.absent(),
    this.sourceHash = const Value.absent(),
    this.draftRevision = const Value.absent(),
    this.recordId = const Value.absent(),
    this.teachingClass = const Value.absent(),
    this.totalHours = const Value.absent(),
    this.credits = const Value.absent(),
    this.sourceJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportRecordMetadataCompanion.insert({
    required String scheduleId,
    required String sourceHash,
    required int draftRevision,
    required String recordId,
    required String teachingClass,
    this.totalHours = const Value.absent(),
    this.credits = const Value.absent(),
    required String sourceJson,
    this.rowid = const Value.absent(),
  }) : scheduleId = Value(scheduleId),
       sourceHash = Value(sourceHash),
       draftRevision = Value(draftRevision),
       recordId = Value(recordId),
       teachingClass = Value(teachingClass),
       sourceJson = Value(sourceJson);
  static Insertable<ImportRecordMetadataData> custom({
    Expression<String>? scheduleId,
    Expression<String>? sourceHash,
    Expression<int>? draftRevision,
    Expression<String>? recordId,
    Expression<String>? teachingClass,
    Expression<int>? totalHours,
    Expression<int>? credits,
    Expression<String>? sourceJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (sourceHash != null) 'source_hash': sourceHash,
      if (draftRevision != null) 'draft_revision': draftRevision,
      if (recordId != null) 'record_id': recordId,
      if (teachingClass != null) 'teaching_class': teachingClass,
      if (totalHours != null) 'total_hours': totalHours,
      if (credits != null) 'credits': credits,
      if (sourceJson != null) 'source_json': sourceJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportRecordMetadataCompanion copyWith({
    Value<String>? scheduleId,
    Value<String>? sourceHash,
    Value<int>? draftRevision,
    Value<String>? recordId,
    Value<String>? teachingClass,
    Value<int?>? totalHours,
    Value<int?>? credits,
    Value<String>? sourceJson,
    Value<int>? rowid,
  }) {
    return ImportRecordMetadataCompanion(
      scheduleId: scheduleId ?? this.scheduleId,
      sourceHash: sourceHash ?? this.sourceHash,
      draftRevision: draftRevision ?? this.draftRevision,
      recordId: recordId ?? this.recordId,
      teachingClass: teachingClass ?? this.teachingClass,
      totalHours: totalHours ?? this.totalHours,
      credits: credits ?? this.credits,
      sourceJson: sourceJson ?? this.sourceJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scheduleId.present) {
      map['schedule_id'] = Variable<String>(scheduleId.value);
    }
    if (sourceHash.present) {
      map['source_hash'] = Variable<String>(sourceHash.value);
    }
    if (draftRevision.present) {
      map['draft_revision'] = Variable<int>(draftRevision.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (teachingClass.present) {
      map['teaching_class'] = Variable<String>(teachingClass.value);
    }
    if (totalHours.present) {
      map['total_hours'] = Variable<int>(totalHours.value);
    }
    if (credits.present) {
      map['credits'] = Variable<int>(credits.value);
    }
    if (sourceJson.present) {
      map['source_json'] = Variable<String>(sourceJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportRecordMetadataCompanion(')
          ..write('scheduleId: $scheduleId, ')
          ..write('sourceHash: $sourceHash, ')
          ..write('draftRevision: $draftRevision, ')
          ..write('recordId: $recordId, ')
          ..write('teachingClass: $teachingClass, ')
          ..write('totalHours: $totalHours, ')
          ..write('credits: $credits, ')
          ..write('sourceJson: $sourceJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ClassDaysOff extends Table
    with TableInfo<ClassDaysOff, ClassDaysOffData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ClassDaysOff(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  late final GeneratedColumn<String> semesterId = GeneratedColumn<String>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES semesters(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(day) = 10 AND COALESCE(date(day, \'+0 days\') = day, 0))',
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(reason)) > 0)',
  );
  @override
  List<GeneratedColumn> get $columns => [semesterId, day, reason];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'class_days_off';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClassDaysOffData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {semesterId, day};
  @override
  ClassDaysOffData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassDaysOffData(
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semester_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
    );
  }

  @override
  ClassDaysOff createAlias(String alias) {
    return ClassDaysOff(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(semester_id, day)'];
  @override
  bool get dontWriteConstraints => true;
}

class ClassDaysOffData extends DataClass
    implements Insertable<ClassDaysOffData> {
  final String semesterId;
  final String day;
  final String reason;
  const ClassDaysOffData({
    required this.semesterId,
    required this.day,
    required this.reason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['semester_id'] = Variable<String>(semesterId);
    map['day'] = Variable<String>(day);
    map['reason'] = Variable<String>(reason);
    return map;
  }

  ClassDaysOffCompanion toCompanion(bool nullToAbsent) {
    return ClassDaysOffCompanion(
      semesterId: Value(semesterId),
      day: Value(day),
      reason: Value(reason),
    );
  }

  factory ClassDaysOffData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassDaysOffData(
      semesterId: serializer.fromJson<String>(json['semester_id']),
      day: serializer.fromJson<String>(json['day']),
      reason: serializer.fromJson<String>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'semester_id': serializer.toJson<String>(semesterId),
      'day': serializer.toJson<String>(day),
      'reason': serializer.toJson<String>(reason),
    };
  }

  ClassDaysOffData copyWith({
    String? semesterId,
    String? day,
    String? reason,
  }) => ClassDaysOffData(
    semesterId: semesterId ?? this.semesterId,
    day: day ?? this.day,
    reason: reason ?? this.reason,
  );
  ClassDaysOffData copyWithCompanion(ClassDaysOffCompanion data) {
    return ClassDaysOffData(
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      day: data.day.present ? data.day.value : this.day,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassDaysOffData(')
          ..write('semesterId: $semesterId, ')
          ..write('day: $day, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(semesterId, day, reason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassDaysOffData &&
          other.semesterId == this.semesterId &&
          other.day == this.day &&
          other.reason == this.reason);
}

class ClassDaysOffCompanion extends UpdateCompanion<ClassDaysOffData> {
  final Value<String> semesterId;
  final Value<String> day;
  final Value<String> reason;
  final Value<int> rowid;
  const ClassDaysOffCompanion({
    this.semesterId = const Value.absent(),
    this.day = const Value.absent(),
    this.reason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClassDaysOffCompanion.insert({
    required String semesterId,
    required String day,
    required String reason,
    this.rowid = const Value.absent(),
  }) : semesterId = Value(semesterId),
       day = Value(day),
       reason = Value(reason);
  static Insertable<ClassDaysOffData> custom({
    Expression<String>? semesterId,
    Expression<String>? day,
    Expression<String>? reason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (semesterId != null) 'semester_id': semesterId,
      if (day != null) 'day': day,
      if (reason != null) 'reason': reason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClassDaysOffCompanion copyWith({
    Value<String>? semesterId,
    Value<String>? day,
    Value<String>? reason,
    Value<int>? rowid,
  }) {
    return ClassDaysOffCompanion(
      semesterId: semesterId ?? this.semesterId,
      day: day ?? this.day,
      reason: reason ?? this.reason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (semesterId.present) {
      map['semester_id'] = Variable<String>(semesterId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassDaysOffCompanion(')
          ..write('semesterId: $semesterId, ')
          ..write('day: $day, ')
          ..write('reason: $reason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ClassDayReplacements extends Table
    with TableInfo<ClassDayReplacements, ClassDayReplacement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ClassDayReplacements(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  late final GeneratedColumn<String> semesterId = GeneratedColumn<String>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES semesters(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _targetDayMeta = const VerificationMeta(
    'targetDay',
  );
  late final GeneratedColumn<String> targetDay = GeneratedColumn<String>(
    'target_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(target_day) = 10 AND date(target_day) = target_day)',
  );
  static const VerificationMeta _sourceDayMeta = const VerificationMeta(
    'sourceDay',
  );
  late final GeneratedColumn<String> sourceDay = GeneratedColumn<String>(
    'source_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(source_day) = 10 AND date(source_day) = source_day)',
  );
  @override
  List<GeneratedColumn> get $columns => [semesterId, targetDay, sourceDay];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'class_day_replacements';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClassDayReplacement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('target_day')) {
      context.handle(
        _targetDayMeta,
        targetDay.isAcceptableOrUnknown(data['target_day']!, _targetDayMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDayMeta);
    }
    if (data.containsKey('source_day')) {
      context.handle(
        _sourceDayMeta,
        sourceDay.isAcceptableOrUnknown(data['source_day']!, _sourceDayMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceDayMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {semesterId, targetDay};
  @override
  ClassDayReplacement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassDayReplacement(
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semester_id'],
      )!,
      targetDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_day'],
      )!,
      sourceDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_day'],
      )!,
    );
  }

  @override
  ClassDayReplacements createAlias(String alias) {
    return ClassDayReplacements(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(semester_id, target_day)',
    'CHECK(source_day <> target_day)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ClassDayReplacement extends DataClass
    implements Insertable<ClassDayReplacement> {
  final String semesterId;
  final String targetDay;
  final String sourceDay;
  const ClassDayReplacement({
    required this.semesterId,
    required this.targetDay,
    required this.sourceDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['semester_id'] = Variable<String>(semesterId);
    map['target_day'] = Variable<String>(targetDay);
    map['source_day'] = Variable<String>(sourceDay);
    return map;
  }

  ClassDayReplacementsCompanion toCompanion(bool nullToAbsent) {
    return ClassDayReplacementsCompanion(
      semesterId: Value(semesterId),
      targetDay: Value(targetDay),
      sourceDay: Value(sourceDay),
    );
  }

  factory ClassDayReplacement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassDayReplacement(
      semesterId: serializer.fromJson<String>(json['semester_id']),
      targetDay: serializer.fromJson<String>(json['target_day']),
      sourceDay: serializer.fromJson<String>(json['source_day']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'semester_id': serializer.toJson<String>(semesterId),
      'target_day': serializer.toJson<String>(targetDay),
      'source_day': serializer.toJson<String>(sourceDay),
    };
  }

  ClassDayReplacement copyWith({
    String? semesterId,
    String? targetDay,
    String? sourceDay,
  }) => ClassDayReplacement(
    semesterId: semesterId ?? this.semesterId,
    targetDay: targetDay ?? this.targetDay,
    sourceDay: sourceDay ?? this.sourceDay,
  );
  ClassDayReplacement copyWithCompanion(ClassDayReplacementsCompanion data) {
    return ClassDayReplacement(
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      targetDay: data.targetDay.present ? data.targetDay.value : this.targetDay,
      sourceDay: data.sourceDay.present ? data.sourceDay.value : this.sourceDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassDayReplacement(')
          ..write('semesterId: $semesterId, ')
          ..write('targetDay: $targetDay, ')
          ..write('sourceDay: $sourceDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(semesterId, targetDay, sourceDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassDayReplacement &&
          other.semesterId == this.semesterId &&
          other.targetDay == this.targetDay &&
          other.sourceDay == this.sourceDay);
}

class ClassDayReplacementsCompanion
    extends UpdateCompanion<ClassDayReplacement> {
  final Value<String> semesterId;
  final Value<String> targetDay;
  final Value<String> sourceDay;
  final Value<int> rowid;
  const ClassDayReplacementsCompanion({
    this.semesterId = const Value.absent(),
    this.targetDay = const Value.absent(),
    this.sourceDay = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClassDayReplacementsCompanion.insert({
    required String semesterId,
    required String targetDay,
    required String sourceDay,
    this.rowid = const Value.absent(),
  }) : semesterId = Value(semesterId),
       targetDay = Value(targetDay),
       sourceDay = Value(sourceDay);
  static Insertable<ClassDayReplacement> custom({
    Expression<String>? semesterId,
    Expression<String>? targetDay,
    Expression<String>? sourceDay,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (semesterId != null) 'semester_id': semesterId,
      if (targetDay != null) 'target_day': targetDay,
      if (sourceDay != null) 'source_day': sourceDay,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClassDayReplacementsCompanion copyWith({
    Value<String>? semesterId,
    Value<String>? targetDay,
    Value<String>? sourceDay,
    Value<int>? rowid,
  }) {
    return ClassDayReplacementsCompanion(
      semesterId: semesterId ?? this.semesterId,
      targetDay: targetDay ?? this.targetDay,
      sourceDay: sourceDay ?? this.sourceDay,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (semesterId.present) {
      map['semester_id'] = Variable<String>(semesterId.value);
    }
    if (targetDay.present) {
      map['target_day'] = Variable<String>(targetDay.value);
    }
    if (sourceDay.present) {
      map['source_day'] = Variable<String>(sourceDay.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassDayReplacementsCompanion(')
          ..write('semesterId: $semesterId, ')
          ..write('targetDay: $targetDay, ')
          ..write('sourceDay: $sourceDay, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LessonTransfers extends Table
    with TableInfo<LessonTransfers, LessonTransfer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LessonTransfers(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  late final GeneratedColumn<String> semesterId = GeneratedColumn<String>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES semesters(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  late final GeneratedColumn<String> scheduleId = GeneratedColumn<String>(
    'schedule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES course_schedules(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _sourceDayMeta = const VerificationMeta(
    'sourceDay',
  );
  late final GeneratedColumn<String> sourceDay = GeneratedColumn<String>(
    'source_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _targetDayMeta = const VerificationMeta(
    'targetDay',
  );
  late final GeneratedColumn<String> targetDay = GeneratedColumn<String>(
    'target_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sourceStartMeta = const VerificationMeta(
    'sourceStart',
  );
  late final GeneratedColumn<int> sourceStart = GeneratedColumn<int>(
    'source_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (source_start > 0)',
  );
  static const VerificationMeta _sourceEndMeta = const VerificationMeta(
    'sourceEnd',
  );
  late final GeneratedColumn<int> sourceEnd = GeneratedColumn<int>(
    'source_end',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (source_end >= source_start)',
  );
  static const VerificationMeta _targetStartMeta = const VerificationMeta(
    'targetStart',
  );
  late final GeneratedColumn<int> targetStart = GeneratedColumn<int>(
    'target_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (target_start > 0)',
  );
  static const VerificationMeta _keepSourceMeta = const VerificationMeta(
    'keepSource',
  );
  late final GeneratedColumn<int> keepSource = GeneratedColumn<int>(
    'keep_source',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (keep_source IN (0, 1))',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    semesterId,
    scheduleId,
    sourceDay,
    targetDay,
    sourceStart,
    sourceEnd,
    targetStart,
    keepSource,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_transfers';
  @override
  VerificationContext validateIntegrity(
    Insertable<LessonTransfer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('schedule_id')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['schedule_id']!, _scheduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scheduleIdMeta);
    }
    if (data.containsKey('source_day')) {
      context.handle(
        _sourceDayMeta,
        sourceDay.isAcceptableOrUnknown(data['source_day']!, _sourceDayMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceDayMeta);
    }
    if (data.containsKey('target_day')) {
      context.handle(
        _targetDayMeta,
        targetDay.isAcceptableOrUnknown(data['target_day']!, _targetDayMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDayMeta);
    }
    if (data.containsKey('source_start')) {
      context.handle(
        _sourceStartMeta,
        sourceStart.isAcceptableOrUnknown(
          data['source_start']!,
          _sourceStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceStartMeta);
    }
    if (data.containsKey('source_end')) {
      context.handle(
        _sourceEndMeta,
        sourceEnd.isAcceptableOrUnknown(data['source_end']!, _sourceEndMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceEndMeta);
    }
    if (data.containsKey('target_start')) {
      context.handle(
        _targetStartMeta,
        targetStart.isAcceptableOrUnknown(
          data['target_start']!,
          _targetStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetStartMeta);
    }
    if (data.containsKey('keep_source')) {
      context.handle(
        _keepSourceMeta,
        keepSource.isAcceptableOrUnknown(data['keep_source']!, _keepSourceMeta),
      );
    } else if (isInserting) {
      context.missing(_keepSourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LessonTransfer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonTransfer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semester_id'],
      )!,
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_id'],
      )!,
      sourceDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_day'],
      )!,
      targetDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_day'],
      )!,
      sourceStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_start'],
      )!,
      sourceEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_end'],
      )!,
      targetStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_start'],
      )!,
      keepSource: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}keep_source'],
      )!,
    );
  }

  @override
  LessonTransfers createAlias(String alias) {
    return LessonTransfers(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class LessonTransfer extends DataClass implements Insertable<LessonTransfer> {
  final String id;
  final String semesterId;
  final String scheduleId;
  final String sourceDay;
  final String targetDay;
  final int sourceStart;
  final int sourceEnd;
  final int targetStart;
  final int keepSource;
  const LessonTransfer({
    required this.id,
    required this.semesterId,
    required this.scheduleId,
    required this.sourceDay,
    required this.targetDay,
    required this.sourceStart,
    required this.sourceEnd,
    required this.targetStart,
    required this.keepSource,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['semester_id'] = Variable<String>(semesterId);
    map['schedule_id'] = Variable<String>(scheduleId);
    map['source_day'] = Variable<String>(sourceDay);
    map['target_day'] = Variable<String>(targetDay);
    map['source_start'] = Variable<int>(sourceStart);
    map['source_end'] = Variable<int>(sourceEnd);
    map['target_start'] = Variable<int>(targetStart);
    map['keep_source'] = Variable<int>(keepSource);
    return map;
  }

  LessonTransfersCompanion toCompanion(bool nullToAbsent) {
    return LessonTransfersCompanion(
      id: Value(id),
      semesterId: Value(semesterId),
      scheduleId: Value(scheduleId),
      sourceDay: Value(sourceDay),
      targetDay: Value(targetDay),
      sourceStart: Value(sourceStart),
      sourceEnd: Value(sourceEnd),
      targetStart: Value(targetStart),
      keepSource: Value(keepSource),
    );
  }

  factory LessonTransfer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonTransfer(
      id: serializer.fromJson<String>(json['id']),
      semesterId: serializer.fromJson<String>(json['semester_id']),
      scheduleId: serializer.fromJson<String>(json['schedule_id']),
      sourceDay: serializer.fromJson<String>(json['source_day']),
      targetDay: serializer.fromJson<String>(json['target_day']),
      sourceStart: serializer.fromJson<int>(json['source_start']),
      sourceEnd: serializer.fromJson<int>(json['source_end']),
      targetStart: serializer.fromJson<int>(json['target_start']),
      keepSource: serializer.fromJson<int>(json['keep_source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'semester_id': serializer.toJson<String>(semesterId),
      'schedule_id': serializer.toJson<String>(scheduleId),
      'source_day': serializer.toJson<String>(sourceDay),
      'target_day': serializer.toJson<String>(targetDay),
      'source_start': serializer.toJson<int>(sourceStart),
      'source_end': serializer.toJson<int>(sourceEnd),
      'target_start': serializer.toJson<int>(targetStart),
      'keep_source': serializer.toJson<int>(keepSource),
    };
  }

  LessonTransfer copyWith({
    String? id,
    String? semesterId,
    String? scheduleId,
    String? sourceDay,
    String? targetDay,
    int? sourceStart,
    int? sourceEnd,
    int? targetStart,
    int? keepSource,
  }) => LessonTransfer(
    id: id ?? this.id,
    semesterId: semesterId ?? this.semesterId,
    scheduleId: scheduleId ?? this.scheduleId,
    sourceDay: sourceDay ?? this.sourceDay,
    targetDay: targetDay ?? this.targetDay,
    sourceStart: sourceStart ?? this.sourceStart,
    sourceEnd: sourceEnd ?? this.sourceEnd,
    targetStart: targetStart ?? this.targetStart,
    keepSource: keepSource ?? this.keepSource,
  );
  LessonTransfer copyWithCompanion(LessonTransfersCompanion data) {
    return LessonTransfer(
      id: data.id.present ? data.id.value : this.id,
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      sourceDay: data.sourceDay.present ? data.sourceDay.value : this.sourceDay,
      targetDay: data.targetDay.present ? data.targetDay.value : this.targetDay,
      sourceStart: data.sourceStart.present
          ? data.sourceStart.value
          : this.sourceStart,
      sourceEnd: data.sourceEnd.present ? data.sourceEnd.value : this.sourceEnd,
      targetStart: data.targetStart.present
          ? data.targetStart.value
          : this.targetStart,
      keepSource: data.keepSource.present
          ? data.keepSource.value
          : this.keepSource,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonTransfer(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('sourceDay: $sourceDay, ')
          ..write('targetDay: $targetDay, ')
          ..write('sourceStart: $sourceStart, ')
          ..write('sourceEnd: $sourceEnd, ')
          ..write('targetStart: $targetStart, ')
          ..write('keepSource: $keepSource')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    semesterId,
    scheduleId,
    sourceDay,
    targetDay,
    sourceStart,
    sourceEnd,
    targetStart,
    keepSource,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonTransfer &&
          other.id == this.id &&
          other.semesterId == this.semesterId &&
          other.scheduleId == this.scheduleId &&
          other.sourceDay == this.sourceDay &&
          other.targetDay == this.targetDay &&
          other.sourceStart == this.sourceStart &&
          other.sourceEnd == this.sourceEnd &&
          other.targetStart == this.targetStart &&
          other.keepSource == this.keepSource);
}

class LessonTransfersCompanion extends UpdateCompanion<LessonTransfer> {
  final Value<String> id;
  final Value<String> semesterId;
  final Value<String> scheduleId;
  final Value<String> sourceDay;
  final Value<String> targetDay;
  final Value<int> sourceStart;
  final Value<int> sourceEnd;
  final Value<int> targetStart;
  final Value<int> keepSource;
  final Value<int> rowid;
  const LessonTransfersCompanion({
    this.id = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.scheduleId = const Value.absent(),
    this.sourceDay = const Value.absent(),
    this.targetDay = const Value.absent(),
    this.sourceStart = const Value.absent(),
    this.sourceEnd = const Value.absent(),
    this.targetStart = const Value.absent(),
    this.keepSource = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonTransfersCompanion.insert({
    required String id,
    required String semesterId,
    required String scheduleId,
    required String sourceDay,
    required String targetDay,
    required int sourceStart,
    required int sourceEnd,
    required int targetStart,
    required int keepSource,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       semesterId = Value(semesterId),
       scheduleId = Value(scheduleId),
       sourceDay = Value(sourceDay),
       targetDay = Value(targetDay),
       sourceStart = Value(sourceStart),
       sourceEnd = Value(sourceEnd),
       targetStart = Value(targetStart),
       keepSource = Value(keepSource);
  static Insertable<LessonTransfer> custom({
    Expression<String>? id,
    Expression<String>? semesterId,
    Expression<String>? scheduleId,
    Expression<String>? sourceDay,
    Expression<String>? targetDay,
    Expression<int>? sourceStart,
    Expression<int>? sourceEnd,
    Expression<int>? targetStart,
    Expression<int>? keepSource,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (semesterId != null) 'semester_id': semesterId,
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (sourceDay != null) 'source_day': sourceDay,
      if (targetDay != null) 'target_day': targetDay,
      if (sourceStart != null) 'source_start': sourceStart,
      if (sourceEnd != null) 'source_end': sourceEnd,
      if (targetStart != null) 'target_start': targetStart,
      if (keepSource != null) 'keep_source': keepSource,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonTransfersCompanion copyWith({
    Value<String>? id,
    Value<String>? semesterId,
    Value<String>? scheduleId,
    Value<String>? sourceDay,
    Value<String>? targetDay,
    Value<int>? sourceStart,
    Value<int>? sourceEnd,
    Value<int>? targetStart,
    Value<int>? keepSource,
    Value<int>? rowid,
  }) {
    return LessonTransfersCompanion(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      scheduleId: scheduleId ?? this.scheduleId,
      sourceDay: sourceDay ?? this.sourceDay,
      targetDay: targetDay ?? this.targetDay,
      sourceStart: sourceStart ?? this.sourceStart,
      sourceEnd: sourceEnd ?? this.sourceEnd,
      targetStart: targetStart ?? this.targetStart,
      keepSource: keepSource ?? this.keepSource,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<String>(semesterId.value);
    }
    if (scheduleId.present) {
      map['schedule_id'] = Variable<String>(scheduleId.value);
    }
    if (sourceDay.present) {
      map['source_day'] = Variable<String>(sourceDay.value);
    }
    if (targetDay.present) {
      map['target_day'] = Variable<String>(targetDay.value);
    }
    if (sourceStart.present) {
      map['source_start'] = Variable<int>(sourceStart.value);
    }
    if (sourceEnd.present) {
      map['source_end'] = Variable<int>(sourceEnd.value);
    }
    if (targetStart.present) {
      map['target_start'] = Variable<int>(targetStart.value);
    }
    if (keepSource.present) {
      map['keep_source'] = Variable<int>(keepSource.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonTransfersCompanion(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('sourceDay: $sourceDay, ')
          ..write('targetDay: $targetDay, ')
          ..write('sourceStart: $sourceStart, ')
          ..write('sourceEnd: $sourceEnd, ')
          ..write('targetStart: $targetStart, ')
          ..write('keepSource: $keepSource, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CourseScheduleTimes extends Table
    with TableInfo<CourseScheduleTimes, CourseScheduleTime> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CourseScheduleTimes(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  late final GeneratedColumn<String> scheduleId = GeneratedColumn<String>(
    'schedule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY REFERENCES course_schedules(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (start_time GLOB \'[0-2][0-9]:[0-5][0-9]\' AND start_time < \'24:00\')',
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (end_time GLOB \'[0-2][0-9]:[0-5][0-9]\' AND end_time < \'24:00\')',
  );
  @override
  List<GeneratedColumn> get $columns => [scheduleId, startTime, endTime];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_schedule_times';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseScheduleTime> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('schedule_id')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['schedule_id']!, _scheduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scheduleIdMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scheduleId};
  @override
  CourseScheduleTime map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseScheduleTime(
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_id'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      )!,
    );
  }

  @override
  CourseScheduleTimes createAlias(String alias) {
    return CourseScheduleTimes(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['CHECK(end_time > start_time)'];
  @override
  bool get dontWriteConstraints => true;
}

class CourseScheduleTime extends DataClass
    implements Insertable<CourseScheduleTime> {
  final String scheduleId;
  final String startTime;
  final String endTime;
  const CourseScheduleTime({
    required this.scheduleId,
    required this.startTime,
    required this.endTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['schedule_id'] = Variable<String>(scheduleId);
    map['start_time'] = Variable<String>(startTime);
    map['end_time'] = Variable<String>(endTime);
    return map;
  }

  CourseScheduleTimesCompanion toCompanion(bool nullToAbsent) {
    return CourseScheduleTimesCompanion(
      scheduleId: Value(scheduleId),
      startTime: Value(startTime),
      endTime: Value(endTime),
    );
  }

  factory CourseScheduleTime.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseScheduleTime(
      scheduleId: serializer.fromJson<String>(json['schedule_id']),
      startTime: serializer.fromJson<String>(json['start_time']),
      endTime: serializer.fromJson<String>(json['end_time']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'schedule_id': serializer.toJson<String>(scheduleId),
      'start_time': serializer.toJson<String>(startTime),
      'end_time': serializer.toJson<String>(endTime),
    };
  }

  CourseScheduleTime copyWith({
    String? scheduleId,
    String? startTime,
    String? endTime,
  }) => CourseScheduleTime(
    scheduleId: scheduleId ?? this.scheduleId,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
  );
  CourseScheduleTime copyWithCompanion(CourseScheduleTimesCompanion data) {
    return CourseScheduleTime(
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseScheduleTime(')
          ..write('scheduleId: $scheduleId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scheduleId, startTime, endTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseScheduleTime &&
          other.scheduleId == this.scheduleId &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime);
}

class CourseScheduleTimesCompanion extends UpdateCompanion<CourseScheduleTime> {
  final Value<String> scheduleId;
  final Value<String> startTime;
  final Value<String> endTime;
  final Value<int> rowid;
  const CourseScheduleTimesCompanion({
    this.scheduleId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseScheduleTimesCompanion.insert({
    required String scheduleId,
    required String startTime,
    required String endTime,
    this.rowid = const Value.absent(),
  }) : scheduleId = Value(scheduleId),
       startTime = Value(startTime),
       endTime = Value(endTime);
  static Insertable<CourseScheduleTime> custom({
    Expression<String>? scheduleId,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseScheduleTimesCompanion copyWith({
    Value<String>? scheduleId,
    Value<String>? startTime,
    Value<String>? endTime,
    Value<int>? rowid,
  }) {
    return CourseScheduleTimesCompanion(
      scheduleId: scheduleId ?? this.scheduleId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scheduleId.present) {
      map['schedule_id'] = Variable<String>(scheduleId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseScheduleTimesCompanion(')
          ..write('scheduleId: $scheduleId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LessonTransferEdits extends Table
    with TableInfo<LessonTransferEdits, LessonTransferEdit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LessonTransferEdits(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _transferIdMeta = const VerificationMeta(
    'transferId',
  );
  late final GeneratedColumn<String> transferId = GeneratedColumn<String>(
    'transfer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY REFERENCES lesson_transfers(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _endSectionMeta = const VerificationMeta(
    'endSection',
  );
  late final GeneratedColumn<int> endSection = GeneratedColumn<int>(
    'end_section',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (end_section >= 1)',
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _classroomMeta = const VerificationMeta(
    'classroom',
  );
  late final GeneratedColumn<String> classroom = GeneratedColumn<String>(
    'classroom',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    transferId,
    endSection,
    startTime,
    endTime,
    classroom,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_transfer_edits';
  @override
  VerificationContext validateIntegrity(
    Insertable<LessonTransferEdit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('transfer_id')) {
      context.handle(
        _transferIdMeta,
        transferId.isAcceptableOrUnknown(data['transfer_id']!, _transferIdMeta),
      );
    } else if (isInserting) {
      context.missing(_transferIdMeta);
    }
    if (data.containsKey('end_section')) {
      context.handle(
        _endSectionMeta,
        endSection.isAcceptableOrUnknown(data['end_section']!, _endSectionMeta),
      );
    } else if (isInserting) {
      context.missing(_endSectionMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('classroom')) {
      context.handle(
        _classroomMeta,
        classroom.isAcceptableOrUnknown(data['classroom']!, _classroomMeta),
      );
    } else if (isInserting) {
      context.missing(_classroomMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {transferId};
  @override
  LessonTransferEdit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonTransferEdit(
      transferId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_id'],
      )!,
      endSection: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_section'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      ),
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      ),
      classroom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classroom'],
      )!,
    );
  }

  @override
  LessonTransferEdits createAlias(String alias) {
    return LessonTransferEdits(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK((start_time IS NULL AND end_time IS NULL)OR(start_time IS NOT NULL AND end_time IS NOT NULL AND start_time GLOB \'[0-2][0-9]:[0-5][0-9]\' AND end_time GLOB \'[0-2][0-9]:[0-5][0-9]\' AND end_time < \'24:00\' AND end_time > start_time))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class LessonTransferEdit extends DataClass
    implements Insertable<LessonTransferEdit> {
  final String transferId;
  final int endSection;
  final String? startTime;
  final String? endTime;
  final String classroom;
  const LessonTransferEdit({
    required this.transferId,
    required this.endSection,
    this.startTime,
    this.endTime,
    required this.classroom,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['transfer_id'] = Variable<String>(transferId);
    map['end_section'] = Variable<int>(endSection);
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<String>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<String>(endTime);
    }
    map['classroom'] = Variable<String>(classroom);
    return map;
  }

  LessonTransferEditsCompanion toCompanion(bool nullToAbsent) {
    return LessonTransferEditsCompanion(
      transferId: Value(transferId),
      endSection: Value(endSection),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      classroom: Value(classroom),
    );
  }

  factory LessonTransferEdit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonTransferEdit(
      transferId: serializer.fromJson<String>(json['transfer_id']),
      endSection: serializer.fromJson<int>(json['end_section']),
      startTime: serializer.fromJson<String?>(json['start_time']),
      endTime: serializer.fromJson<String?>(json['end_time']),
      classroom: serializer.fromJson<String>(json['classroom']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'transfer_id': serializer.toJson<String>(transferId),
      'end_section': serializer.toJson<int>(endSection),
      'start_time': serializer.toJson<String?>(startTime),
      'end_time': serializer.toJson<String?>(endTime),
      'classroom': serializer.toJson<String>(classroom),
    };
  }

  LessonTransferEdit copyWith({
    String? transferId,
    int? endSection,
    Value<String?> startTime = const Value.absent(),
    Value<String?> endTime = const Value.absent(),
    String? classroom,
  }) => LessonTransferEdit(
    transferId: transferId ?? this.transferId,
    endSection: endSection ?? this.endSection,
    startTime: startTime.present ? startTime.value : this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    classroom: classroom ?? this.classroom,
  );
  LessonTransferEdit copyWithCompanion(LessonTransferEditsCompanion data) {
    return LessonTransferEdit(
      transferId: data.transferId.present
          ? data.transferId.value
          : this.transferId,
      endSection: data.endSection.present
          ? data.endSection.value
          : this.endSection,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      classroom: data.classroom.present ? data.classroom.value : this.classroom,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonTransferEdit(')
          ..write('transferId: $transferId, ')
          ..write('endSection: $endSection, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('classroom: $classroom')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(transferId, endSection, startTime, endTime, classroom);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonTransferEdit &&
          other.transferId == this.transferId &&
          other.endSection == this.endSection &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.classroom == this.classroom);
}

class LessonTransferEditsCompanion extends UpdateCompanion<LessonTransferEdit> {
  final Value<String> transferId;
  final Value<int> endSection;
  final Value<String?> startTime;
  final Value<String?> endTime;
  final Value<String> classroom;
  final Value<int> rowid;
  const LessonTransferEditsCompanion({
    this.transferId = const Value.absent(),
    this.endSection = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.classroom = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonTransferEditsCompanion.insert({
    required String transferId,
    required int endSection,
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    required String classroom,
    this.rowid = const Value.absent(),
  }) : transferId = Value(transferId),
       endSection = Value(endSection),
       classroom = Value(classroom);
  static Insertable<LessonTransferEdit> custom({
    Expression<String>? transferId,
    Expression<int>? endSection,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? classroom,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (transferId != null) 'transfer_id': transferId,
      if (endSection != null) 'end_section': endSection,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (classroom != null) 'classroom': classroom,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonTransferEditsCompanion copyWith({
    Value<String>? transferId,
    Value<int>? endSection,
    Value<String?>? startTime,
    Value<String?>? endTime,
    Value<String>? classroom,
    Value<int>? rowid,
  }) {
    return LessonTransferEditsCompanion(
      transferId: transferId ?? this.transferId,
      endSection: endSection ?? this.endSection,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      classroom: classroom ?? this.classroom,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (transferId.present) {
      map['transfer_id'] = Variable<String>(transferId.value);
    }
    if (endSection.present) {
      map['end_section'] = Variable<int>(endSection.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (classroom.present) {
      map['classroom'] = Variable<String>(classroom.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonTransferEditsCompanion(')
          ..write('transferId: $transferId, ')
          ..write('endSection: $endSection, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('classroom: $classroom, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ScheduleDatabase extends GeneratedDatabase {
  _$ScheduleDatabase(QueryExecutor e) : super(e);
  late final Semesters semesters = Semesters(this);
  late final Courses courses = Courses(this);
  late final CourseSchedules courseSchedules = CourseSchedules(this);
  late final Index schedulesSemesterDay = Index(
    'schedules_semester_day',
    'CREATE INDEX schedules_semester_day ON course_schedules (semester_id, weekday, start_section)',
  );
  late final ScheduleWeeks scheduleWeeks = ScheduleWeeks(this);
  late final Trigger checkWeekInsert = Trigger(
    'CREATE TRIGGER check_week_insert BEFORE INSERT ON schedule_weeks BEGIN SELECT CASE WHEN NEW.active_week > (SELECT s.total_weeks FROM semesters AS s JOIN course_schedules AS c ON c.semester_id = s.id WHERE c.id = NEW.schedule_id) THEN RAISE (ABORT, \'Active week exceeds semester\') END;END',
    'check_week_insert',
  );
  late final Trigger checkWeekUpdate = Trigger(
    'CREATE TRIGGER check_week_update BEFORE UPDATE ON schedule_weeks BEGIN SELECT CASE WHEN NEW.active_week > (SELECT s.total_weeks FROM semesters AS s JOIN course_schedules AS c ON c.semester_id = s.id WHERE c.id = NEW.schedule_id) THEN RAISE (ABORT, \'Active week exceeds semester\') END;END',
    'check_week_update',
  );
  late final Trigger checkSemesterShrink = Trigger(
    'CREATE TRIGGER check_semester_shrink BEFORE UPDATE OF total_weeks ON semesters BEGIN SELECT CASE WHEN EXISTS (SELECT 1 FROM schedule_weeks AS w JOIN course_schedules AS c ON c.id = w.schedule_id WHERE c.semester_id = NEW.id AND w.active_week > NEW.total_weeks) THEN RAISE (ABORT, \'Existing active weeks exceed new semester\') END;END',
    'check_semester_shrink',
  );
  late final ClassTimes classTimes = ClassTimes(this);
  late final TaskEvents taskEvents = TaskEvents(this);
  late final Index tasksDateTime = Index(
    'tasks_date_time',
    'CREATE INDEX tasks_date_time ON task_events (event_date, start_time)',
  );
  late final ImportDrafts importDrafts = ImportDrafts(this);
  late final ImportRevisions importRevisions = ImportRevisions(this);
  late final ImportCommits importCommits = ImportCommits(this);
  late final ImportRecordMetadata importRecordMetadata = ImportRecordMetadata(
    this,
  );
  late final ClassDaysOff classDaysOff = ClassDaysOff(this);
  late final ClassDayReplacements classDayReplacements = ClassDayReplacements(
    this,
  );
  late final LessonTransfers lessonTransfers = LessonTransfers(this);
  late final CourseScheduleTimes courseScheduleTimes = CourseScheduleTimes(
    this,
  );
  late final LessonTransferEdits lessonTransferEdits = LessonTransferEdits(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    semesters,
    courses,
    courseSchedules,
    schedulesSemesterDay,
    scheduleWeeks,
    checkWeekInsert,
    checkWeekUpdate,
    checkSemesterShrink,
    classTimes,
    taskEvents,
    tasksDateTime,
    importDrafts,
    importRevisions,
    importCommits,
    importRecordMetadata,
    classDaysOff,
    classDayReplacements,
    lessonTransfers,
    courseScheduleTimes,
    lessonTransferEdits,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'course_schedules',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('schedule_weeks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'schedule_weeks',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'schedule_weeks',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'semesters',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'semesters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('class_days_off', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'semesters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('class_day_replacements', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'semesters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lesson_transfers', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'course_schedules',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lesson_transfers', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'course_schedules',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('course_schedule_times', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'lesson_transfers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lesson_transfer_edits', kind: UpdateKind.delete)],
    ),
  ]);
}
