// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversion_history_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetConversionHistoryModelCollection on Isar {
  IsarCollection<ConversionHistoryModel> get conversionHistoryModels =>
      this.collection();
}

const ConversionHistoryModelSchema = CollectionSchema(
  name: r'ConversionHistoryModel',
  id: -4390145512239002551,
  properties: {
    r'fileSizeBytes': PropertySchema(
      id: 0,
      name: r'fileSizeBytes',
      type: IsarType.long,
    ),
    r'fileSizeFormatted': PropertySchema(
      id: 1,
      name: r'fileSizeFormatted',
      type: IsarType.string,
    ),
    r'outputAudioName': PropertySchema(
      id: 2,
      name: r'outputAudioName',
      type: IsarType.string,
    ),
    r'outputAudioPath': PropertySchema(
      id: 3,
      name: r'outputAudioPath',
      type: IsarType.string,
    ),
    r'sourceVideoName': PropertySchema(
      id: 4,
      name: r'sourceVideoName',
      type: IsarType.string,
    ),
    r'sourceVideoPath': PropertySchema(
      id: 5,
      name: r'sourceVideoPath',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 6,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _conversionHistoryModelEstimateSize,
  serialize: _conversionHistoryModelSerialize,
  deserialize: _conversionHistoryModelDeserialize,
  deserializeProp: _conversionHistoryModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _conversionHistoryModelGetId,
  getLinks: _conversionHistoryModelGetLinks,
  attach: _conversionHistoryModelAttach,
  version: '3.3.2',
);

int _conversionHistoryModelEstimateSize(
  ConversionHistoryModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.fileSizeFormatted.length * 3;
  bytesCount += 3 + object.outputAudioName.length * 3;
  bytesCount += 3 + object.outputAudioPath.length * 3;
  bytesCount += 3 + object.sourceVideoName.length * 3;
  bytesCount += 3 + object.sourceVideoPath.length * 3;
  return bytesCount;
}

void _conversionHistoryModelSerialize(
  ConversionHistoryModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.fileSizeBytes);
  writer.writeString(offsets[1], object.fileSizeFormatted);
  writer.writeString(offsets[2], object.outputAudioName);
  writer.writeString(offsets[3], object.outputAudioPath);
  writer.writeString(offsets[4], object.sourceVideoName);
  writer.writeString(offsets[5], object.sourceVideoPath);
  writer.writeDateTime(offsets[6], object.timestamp);
}

ConversionHistoryModel _conversionHistoryModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ConversionHistoryModel();
  object.fileSizeBytes = reader.readLong(offsets[0]);
  object.id = id;
  object.outputAudioName = reader.readString(offsets[2]);
  object.outputAudioPath = reader.readString(offsets[3]);
  object.sourceVideoName = reader.readString(offsets[4]);
  object.sourceVideoPath = reader.readString(offsets[5]);
  object.timestamp = reader.readDateTime(offsets[6]);
  return object;
}

P _conversionHistoryModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _conversionHistoryModelGetId(ConversionHistoryModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _conversionHistoryModelGetLinks(
    ConversionHistoryModel object) {
  return [];
}

void _conversionHistoryModelAttach(
    IsarCollection<dynamic> col, Id id, ConversionHistoryModel object) {
  object.id = id;
}

extension ConversionHistoryModelQueryWhereSort
    on QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QWhere> {
  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ConversionHistoryModelQueryWhere on QueryBuilder<
    ConversionHistoryModel, ConversionHistoryModel, QWhereClause> {
  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterWhereClause> idBetween(
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
}

extension ConversionHistoryModelQueryFilter on QueryBuilder<
    ConversionHistoryModel, ConversionHistoryModel, QFilterCondition> {
  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> fileSizeBytesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileSizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> fileSizeBytesGreaterThan(
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

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> fileSizeBytesLessThan(
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

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> fileSizeBytesBetween(
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

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> fileSizeFormattedEqualTo(
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

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> fileSizeFormattedGreaterThan(
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

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> fileSizeFormattedLessThan(
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

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> fileSizeFormattedBetween(
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

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> fileSizeFormattedStartsWith(
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

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> fileSizeFormattedEndsWith(
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

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
          QAfterFilterCondition>
      fileSizeFormattedContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fileSizeFormatted',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
          QAfterFilterCondition>
      fileSizeFormattedMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fileSizeFormatted',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> fileSizeFormattedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileSizeFormatted',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> fileSizeFormattedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fileSizeFormatted',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> outputAudioNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outputAudioName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> outputAudioNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'outputAudioName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> outputAudioNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'outputAudioName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> outputAudioNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'outputAudioName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> outputAudioNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'outputAudioName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> outputAudioNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'outputAudioName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
          QAfterFilterCondition>
      outputAudioNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'outputAudioName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
          QAfterFilterCondition>
      outputAudioNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'outputAudioName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> outputAudioNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outputAudioName',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> outputAudioNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'outputAudioName',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> outputAudioPathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outputAudioPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> outputAudioPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'outputAudioPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> outputAudioPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'outputAudioPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> outputAudioPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'outputAudioPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> outputAudioPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'outputAudioPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> outputAudioPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'outputAudioPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
          QAfterFilterCondition>
      outputAudioPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'outputAudioPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
          QAfterFilterCondition>
      outputAudioPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'outputAudioPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> outputAudioPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outputAudioPath',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> outputAudioPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'outputAudioPath',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> sourceVideoNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceVideoName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> sourceVideoNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceVideoName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> sourceVideoNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceVideoName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> sourceVideoNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceVideoName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> sourceVideoNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceVideoName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> sourceVideoNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceVideoName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
          QAfterFilterCondition>
      sourceVideoNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceVideoName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
          QAfterFilterCondition>
      sourceVideoNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceVideoName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> sourceVideoNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceVideoName',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> sourceVideoNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceVideoName',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> sourceVideoPathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceVideoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> sourceVideoPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceVideoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> sourceVideoPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceVideoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> sourceVideoPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceVideoPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> sourceVideoPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceVideoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> sourceVideoPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceVideoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
          QAfterFilterCondition>
      sourceVideoPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceVideoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
          QAfterFilterCondition>
      sourceVideoPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceVideoPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> sourceVideoPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceVideoPath',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> sourceVideoPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceVideoPath',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> timestampGreaterThan(
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

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> timestampLessThan(
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

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel,
      QAfterFilterCondition> timestampBetween(
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
}

extension ConversionHistoryModelQueryObject on QueryBuilder<
    ConversionHistoryModel, ConversionHistoryModel, QFilterCondition> {}

extension ConversionHistoryModelQueryLinks on QueryBuilder<
    ConversionHistoryModel, ConversionHistoryModel, QFilterCondition> {}

extension ConversionHistoryModelQuerySortBy
    on QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QSortBy> {
  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      sortByFileSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeBytes', Sort.asc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      sortByFileSizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeBytes', Sort.desc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      sortByFileSizeFormatted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeFormatted', Sort.asc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      sortByFileSizeFormattedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeFormatted', Sort.desc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      sortByOutputAudioName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputAudioName', Sort.asc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      sortByOutputAudioNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputAudioName', Sort.desc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      sortByOutputAudioPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputAudioPath', Sort.asc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      sortByOutputAudioPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputAudioPath', Sort.desc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      sortBySourceVideoName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceVideoName', Sort.asc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      sortBySourceVideoNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceVideoName', Sort.desc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      sortBySourceVideoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceVideoPath', Sort.asc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      sortBySourceVideoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceVideoPath', Sort.desc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension ConversionHistoryModelQuerySortThenBy on QueryBuilder<
    ConversionHistoryModel, ConversionHistoryModel, QSortThenBy> {
  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      thenByFileSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeBytes', Sort.asc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      thenByFileSizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeBytes', Sort.desc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      thenByFileSizeFormatted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeFormatted', Sort.asc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      thenByFileSizeFormattedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeFormatted', Sort.desc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      thenByOutputAudioName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputAudioName', Sort.asc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      thenByOutputAudioNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputAudioName', Sort.desc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      thenByOutputAudioPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputAudioPath', Sort.asc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      thenByOutputAudioPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputAudioPath', Sort.desc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      thenBySourceVideoName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceVideoName', Sort.asc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      thenBySourceVideoNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceVideoName', Sort.desc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      thenBySourceVideoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceVideoPath', Sort.asc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      thenBySourceVideoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceVideoPath', Sort.desc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension ConversionHistoryModelQueryWhereDistinct
    on QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QDistinct> {
  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QDistinct>
      distinctByFileSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileSizeBytes');
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QDistinct>
      distinctByFileSizeFormatted({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileSizeFormatted',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QDistinct>
      distinctByOutputAudioName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'outputAudioName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QDistinct>
      distinctByOutputAudioPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'outputAudioPath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QDistinct>
      distinctBySourceVideoName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceVideoName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QDistinct>
      distinctBySourceVideoPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceVideoPath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversionHistoryModel, ConversionHistoryModel, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension ConversionHistoryModelQueryProperty on QueryBuilder<
    ConversionHistoryModel, ConversionHistoryModel, QQueryProperty> {
  QueryBuilder<ConversionHistoryModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ConversionHistoryModel, int, QQueryOperations>
      fileSizeBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileSizeBytes');
    });
  }

  QueryBuilder<ConversionHistoryModel, String, QQueryOperations>
      fileSizeFormattedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileSizeFormatted');
    });
  }

  QueryBuilder<ConversionHistoryModel, String, QQueryOperations>
      outputAudioNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'outputAudioName');
    });
  }

  QueryBuilder<ConversionHistoryModel, String, QQueryOperations>
      outputAudioPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'outputAudioPath');
    });
  }

  QueryBuilder<ConversionHistoryModel, String, QQueryOperations>
      sourceVideoNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceVideoName');
    });
  }

  QueryBuilder<ConversionHistoryModel, String, QQueryOperations>
      sourceVideoPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceVideoPath');
    });
  }

  QueryBuilder<ConversionHistoryModel, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}
