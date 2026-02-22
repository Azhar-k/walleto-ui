// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Account _$AccountFromJson(Map<String, dynamic> json) => Account(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String,
  accountNumber: json['accountNumber'] as String?,
  bank: json['bank'] as String?,
  isDefault: json['isDefault'] as bool?,
  expiryDate: json['expiryDate'] as String?,
  description: json['description'] as String?,
  currency: json['currency'] as String?,
  version: (json['version'] as num?)?.toInt(),
);

Map<String, dynamic> _$AccountToJson(Account instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'accountNumber': instance.accountNumber,
  'bank': instance.bank,
  'isDefault': instance.isDefault,
  'expiryDate': instance.expiryDate,
  'description': instance.description,
  'currency': instance.currency,
  'version': instance.version,
};

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String,
  type: $enumDecode(_$CategoryTypeEnumMap, json['type']),
  version: (json['version'] as num?)?.toInt(),
);

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$CategoryTypeEnumMap[instance.type]!,
  'version': instance.version,
};

const _$CategoryTypeEnumMap = {
  CategoryType.INCOME: 'INCOME',
  CategoryType.EXPENSE: 'EXPENSE',
};

RecurringPayment _$RecurringPaymentFromJson(Map<String, dynamic> json) =>
    RecurringPayment(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDay: (json['dueDay'] as num).toInt(),
      expiryDate: json['expiryDate'] as String?,
      isCompleted: json['isCompleted'] as bool?,
      lastCompletedDate: json['lastCompletedDate'] as String?,
      version: (json['version'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RecurringPaymentToJson(RecurringPayment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'amount': instance.amount,
      'dueDay': instance.dueDay,
      'expiryDate': instance.expiryDate,
      'isCompleted': instance.isCompleted,
      'lastCompletedDate': instance.lastCompletedDate,
      'version': instance.version,
    };

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
  id: (json['id'] as num?)?.toInt(),
  amount: (json['amount'] as num).toDouble(),
  transactionType: $enumDecode(
    _$TransactionTypeEnumMap,
    json['transactionType'],
  ),
  dateTime: DateTime.parse(json['dateTime'] as String),
  description: json['description'] as String?,
  categoryId: (json['categoryId'] as num?)?.toInt(),
  categoryName: json['categoryName'] as String?,
  accountId: (json['accountId'] as num?)?.toInt(),
  accountName: json['accountName'] as String?,
  counterpartyName: json['counterpartyName'] as String?,
  smsBody: json['smsBody'] as String?,
  smsSender: json['smsSender'] as String?,
  smsHash: json['smsHash'] as String?,
  recurringPaymentId: (json['recurringPaymentId'] as num?)?.toInt(),
  excludeFromSummary: json['excludeFromSummary'] as bool?,
  version: (json['version'] as num?)?.toInt(),
);

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'transactionType': _$TransactionTypeEnumMap[instance.transactionType]!,
      'dateTime': instance.dateTime.toIso8601String(),
      'description': instance.description,
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'accountId': instance.accountId,
      'accountName': instance.accountName,
      'counterpartyName': instance.counterpartyName,
      'smsBody': instance.smsBody,
      'smsSender': instance.smsSender,
      'smsHash': instance.smsHash,
      'recurringPaymentId': instance.recurringPaymentId,
      'excludeFromSummary': instance.excludeFromSummary,
      'version': instance.version,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.CREDIT: 'CREDIT',
  TransactionType.DEBIT: 'DEBIT',
};

CategorySummaryBreakdown _$CategorySummaryBreakdownFromJson(
  Map<String, dynamic> json,
) => CategorySummaryBreakdown(
  categoryName: json['categoryName'] as String,
  type: $enumDecode(_$CategoryTypeEnumMap, json['type']),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  transactionCount: (json['transactionCount'] as num).toInt(),
);

Map<String, dynamic> _$CategorySummaryBreakdownToJson(
  CategorySummaryBreakdown instance,
) => <String, dynamic>{
  'categoryName': instance.categoryName,
  'type': _$CategoryTypeEnumMap[instance.type]!,
  'totalAmount': instance.totalAmount,
  'transactionCount': instance.transactionCount,
};

MonthlySummary _$MonthlySummaryFromJson(Map<String, dynamic> json) =>
    MonthlySummary(
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      totalIncome: (json['totalIncome'] as num).toDouble(),
      totalExpense: (json['totalExpense'] as num).toDouble(),
      netBalance: (json['netBalance'] as num).toDouble(),
      categoryBreakdowns: (json['categoryBreakdowns'] as List<dynamic>?)
          ?.map(
            (e) => CategorySummaryBreakdown.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$MonthlySummaryToJson(MonthlySummary instance) =>
    <String, dynamic>{
      'year': instance.year,
      'month': instance.month,
      'totalIncome': instance.totalIncome,
      'totalExpense': instance.totalExpense,
      'netBalance': instance.netBalance,
      'categoryBreakdowns': instance.categoryBreakdowns,
    };

RegexPattern _$RegexPatternFromJson(Map<String, dynamic> json) => RegexPattern(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String,
  pattern: json['pattern'] as String,
  transactionType: $enumDecode(
    _$TransactionTypeEnumMap,
    json['transactionType'],
  ),
  isActive: json['isActive'] as bool?,
  version: (json['version'] as num?)?.toInt(),
);

Map<String, dynamic> _$RegexPatternToJson(RegexPattern instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'pattern': instance.pattern,
      'transactionType': _$TransactionTypeEnumMap[instance.transactionType]!,
      'isActive': instance.isActive,
      'version': instance.version,
    };
