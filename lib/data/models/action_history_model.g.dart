// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_history_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetActionHistoryModelCollection on Isar {
  IsarCollection<ActionHistoryModel> get actionHistoryModels =>
      this.collection();
}

const ActionHistoryModelSchema = CollectionSchema(
  name: r'ActionHistoryModel',
  id: -5385967642812729588,
  properties: {
    r'error': PropertySchema(
      id: 0,
      name: r'error',
      type: IsarType.string,
    ),
    r'fileSizeBytes': PropertySchema(
      id: 1,
      name: r'fileSizeBytes',
      type: IsarType.long,
    ),
    r'fileSizeFormatted': PropertySchema(
      id: 2,
      name: r'fileSizeFormatted',
      type: IsarType.string,
    ),
    r'isSuccess': PropertySchema(
      id: 3,
      name: r'isSuccess',
      type: IsarType.bool,
    ),
    r'outputPath': PropertySchema(
      id: 4,
      name: r'outputPath',
      type: IsarType.string,
    ),
    r'sourcePath': PropertySchema(
      id: 5,
      name: r'sourcePath',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 6,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'title': PropertySchema(
      id: 7,
      name: r'title',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 8,
      name: r'type',
      type: IsarType.string,
    )
  },
  estimateSize: _actionHistoryModelEstimateSize,
  serialize: _actionHistoryModelSerialize,
  deserialize: _actionHistoryModelDeserialize,
  deserializeProp: _actionHistoryModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'type': IndexSchema(
      id: 5117122708147080838,
      name: r'type',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'type',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'timestamp': IndexSchema(
      id: 1852253767416892198,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _actionHistoryModelGetId,
  getLinks: _actionHistoryModelGetLinks,
  attach: _actionHistoryModelAttach,
  version: '3.3.2',
);

int _actionHistoryModelEstimateSize(
  ActionHistoryModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.error;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.fileSizeFormatted.length * 3;
  bytesCount += 3 + object.outputPath.length * 3;
  bytesCount += 3 + object.sourcePath.length * 3;
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.type.length * 3;
  return bytesCount;
}

void _actionHistoryModelSerialize(
  ActionHistoryModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.error);
  writer.writeLong(offsets[1], object.fileSizeBytes);
  writer.writeString(offsets[2], object.fileSizeFormatted);
  writer.writeBool(offsets[3], object.isSuccess);
  writer.writeString(offsets[4], object.outputPath);
  writer.writeString(offsets[5], object.sourcePath);
  writer.writeDateTime(offsets[6], object.timestamp);
  writer.writeString(offsets[7], object.title);
  writer.writeString(offsets[8], object.type);
}

ActionHistoryModel _actionHistoryModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ActionHistoryModel();
  object.error = reader.readStringOrNull(offsets[0]);
  object.fileSizeBytes = reader.readLong(offsets[1]);
  object.id = id;
  object.isSuccess = reader.readBool(offsets[3]);
  object.outputPath = reader.readString(offsets[4]);
  object.sourcePath = reader.readString(offsets[5]);
  object.timestamp = reader.readDateTime(offsets[6]);
  object.title = reader.readString(offsets[7]);
  object.type = reader.readString(offsets[8]);
  return object;
}

P _actionHistoryModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _actionHistoryModelGetId(ActionHistoryModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _actionHistoryModelGetLinks(
    ActionHistoryModel object) {
  return [];
}

void _actionHistoryModelAttach(
    IsarCollection<dynamic> col, Id id, ActionHistoryModel object) {
  object.id = id;
}

extension ActionHistoryModelQueryWhereSort
    on QueryBuilder<ActionHistoryModel, ActionHistoryModel, QWhere> {
  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterWhere>
      anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }
}

extension ActionHistoryModelQueryWhere
    on QueryBuilder<ActionHistoryModel, ActionHistoryModel, QWhereClause> {
  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterWhereClause>
      typeEqualTo(String type) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'type',
        value: [type],
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterWhereClause>
      typeNotEqualTo(String type) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [],
              upper: [type],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [type],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [type],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [],
              upper: [type],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterWhereClause>
      timestampEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterWhereClause>
      timestampNotEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterWhereClause>
      timestampGreaterThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [timestamp],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterWhereClause>
      timestampLessThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [],
        upper: [timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterWhereClause>
      timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [lowerTimestamp],
        includeLower: includeLower,
        upper: [upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ActionHistoryModelQueryFilter
    on QueryBuilder<ActionHistoryModel, ActionHistoryModel, QFilterCondition> {
  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      errorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'error',
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      errorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'error',
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      errorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'error',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      errorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'error',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      errorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'error',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      errorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'error',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      errorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'error',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      errorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'error',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      errorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'error',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      errorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'error',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      errorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'error',
        value: '',
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      errorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'error',
        value: '',
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      fileSizeBytesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileSizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      fileSizeBytesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fileSizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      fileSizeBytesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fileSizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      fileSizeBytesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fileSizeBytes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      fileSizeFormattedEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileSizeFormatted',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      fileSizeFormattedGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fileSizeFormatted',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      fileSizeFormattedLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fileSizeFormatted',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      fileSizeFormattedBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fileSizeFormatted',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      fileSizeFormattedStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fileSizeFormatted',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      fileSizeFormattedEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fileSizeFormatted',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      fileSizeFormattedContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fileSizeFormatted',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      fileSizeFormattedMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fileSizeFormatted',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      fileSizeFormattedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileSizeFormatted',
        value: '',
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      fileSizeFormattedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fileSizeFormatted',
        value: '',
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      isSuccessEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSuccess',
        value: value,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      outputPathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outputPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      outputPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'outputPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      outputPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'outputPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      outputPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'outputPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      outputPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'outputPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      outputPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'outputPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      outputPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'outputPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      outputPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'outputPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      outputPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outputPath',
        value: '',
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      outputPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'outputPath',
        value: '',
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      sourcePathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourcePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      sourcePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourcePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      sourcePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourcePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      sourcePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourcePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      sourcePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourcePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      sourcePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourcePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      sourcePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourcePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      sourcePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourcePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      sourcePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourcePath',
        value: '',
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      sourcePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourcePath',
        value: '',
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }
}

extension ActionHistoryModelQueryObject
    on QueryBuilder<ActionHistoryModel, ActionHistoryModel, QFilterCondition> {}

extension ActionHistoryModelQueryLinks
    on QueryBuilder<ActionHistoryModel, ActionHistoryModel, QFilterCondition> {}

extension ActionHistoryModelQuerySortBy
    on QueryBuilder<ActionHistoryModel, ActionHistoryModel, QSortBy> {
  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      sortByError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'error', Sort.asc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      sortByErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'error', Sort.desc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      sortByFileSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeBytes', Sort.asc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      sortByFileSizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeBytes', Sort.desc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      sortByFileSizeFormatted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeFormatted', Sort.asc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      sortByFileSizeFormattedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeFormatted', Sort.desc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      sortByIsSuccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSuccess', Sort.asc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      sortByIsSuccessDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSuccess', Sort.desc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      sortByOutputPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputPath', Sort.asc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      sortByOutputPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputPath', Sort.desc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      sortBySourcePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourcePath', Sort.asc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      sortBySourcePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourcePath', Sort.desc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension ActionHistoryModelQuerySortThenBy
    on QueryBuilder<ActionHistoryModel, ActionHistoryModel, QSortThenBy> {
  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenByError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'error', Sort.asc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenByErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'error', Sort.desc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenByFileSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeBytes', Sort.asc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenByFileSizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeBytes', Sort.desc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenByFileSizeFormatted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeFormatted', Sort.asc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenByFileSizeFormattedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeFormatted', Sort.desc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenByIsSuccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSuccess', Sort.asc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenByIsSuccessDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSuccess', Sort.desc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenByOutputPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputPath', Sort.asc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenByOutputPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputPath', Sort.desc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenBySourcePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourcePath', Sort.asc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenBySourcePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourcePath', Sort.desc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension ActionHistoryModelQueryWhereDistinct
    on QueryBuilder<ActionHistoryModel, ActionHistoryModel, QDistinct> {
  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QDistinct>
      distinctByError({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'error', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QDistinct>
      distinctByFileSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileSizeBytes');
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QDistinct>
      distinctByFileSizeFormatted({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileSizeFormatted',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QDistinct>
      distinctByIsSuccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSuccess');
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QDistinct>
      distinctByOutputPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'outputPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QDistinct>
      distinctBySourcePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourcePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QDistinct>
      distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ActionHistoryModel, ActionHistoryModel, QDistinct>
      distinctByType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }
}

extension ActionHistoryModelQueryProperty
    on QueryBuilder<ActionHistoryModel, ActionHistoryModel, QQueryProperty> {
  QueryBuilder<ActionHistoryModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ActionHistoryModel, String?, QQueryOperations> errorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'error');
    });
  }

  QueryBuilder<ActionHistoryModel, int, QQueryOperations>
      fileSizeBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileSizeBytes');
    });
  }

  QueryBuilder<ActionHistoryModel, String, QQueryOperations>
      fileSizeFormattedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileSizeFormatted');
    });
  }

  QueryBuilder<ActionHistoryModel, bool, QQueryOperations> isSuccessProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSuccess');
    });
  }

  QueryBuilder<ActionHistoryModel, String, QQueryOperations>
      outputPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'outputPath');
    });
  }

  QueryBuilder<ActionHistoryModel, String, QQueryOperations>
      sourcePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourcePath');
    });
  }

  QueryBuilder<ActionHistoryModel, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<ActionHistoryModel, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<ActionHistoryModel, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}
