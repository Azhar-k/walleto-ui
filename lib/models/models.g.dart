// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Account _$AccountFromJson(Map<String, dynamic> json) => Account(
  id: (json['id'] as num?)?.toInt(),
  accountName: json['accountName'] as String,
  baseAccountNumber: json['baseAccountNumber'] as String?,
  bankName: json['bankName'] as String?,
  isDefault: json['isDefault'] as bool?,
  cardExpiryDate: json['cardExpiryDate'] as String?,
  description: json['description'] as String?,
  currency: json['currency'] as String?,
);

Map<String, dynamic> _$AccountToJson(Account instance) => <String, dynamic>{
  'id': instance.id,
  'accountName': instance.accountName,
  'baseAccountNumber': instance.baseAccountNumber,
  'bankName': instance.bankName,
  'isDefault': instance.isDefault,
  'cardExpiryDate': instance.cardExpiryDate,
  'description': instance.description,
  'currency': instance.currency,
};

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String,
  type: $enumDecode(_$CategoryTypeEnumMap, json['type']),
);

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$CategoryTypeEnumMap[instance.type]!,
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
      expiryDate: json['expiryDate'] as String,
      completed: json['completed'] as bool?,
      lastCompletedDate: json['lastCompletedDate'] as String?,
    );

Map<String, dynamic> _$RecurringPaymentToJson(RecurringPayment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'amount': instance.amount,
      'dueDay': instance.dueDay,
      'expiryDate': instance.expiryDate,
      'completed': instance.completed,
      'lastCompletedDate': instance.lastCompletedDate,
    };

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
  id: (json['id'] as num?)?.toInt(),
  amount: (json['amount'] as num).toDouble(),
  description: json['description'] as String,
  transactionDateTime: DateTime.parse(json['transactionDateTime'] as String),
  type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
  category: Category.fromJson(json['category'] as Map<String, dynamic>),
  account: Account.fromJson(json['account'] as Map<String, dynamic>),
  counterpartyName: json['counterpartyName'] as String?,
  smsBody: json['smsBody'] as String?,
  smsSender: json['smsSender'] as String?,
  smsHash: json['smsHash'] as String?,
  linkedRecurringPaymentId: (json['linkedRecurringPaymentId'] as num?)?.toInt(),
  excludeFromSummary: json['excludeFromSummary'] as bool?,
);

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'description': instance.description,
      'transactionDateTime': instance.transactionDateTime.toIso8601String(),
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'category': instance.category,
      'account': instance.account,
      'counterpartyName': instance.counterpartyName,
      'smsBody': instance.smsBody,
      'smsSender': instance.smsSender,
      'smsHash': instance.smsHash,
      'linkedRecurringPaymentId': instance.linkedRecurringPaymentId,
      'excludeFromSummary': instance.excludeFromSummary,
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
  regexName: json['regexName'] as String,
  pattern: json['pattern'] as String,
  bankName: json['bankName'] as String,
  defaultType: $enumDecode(_$TransactionTypeEnumMap, json['defaultType']),
  isSystem: json['isSystem'] as bool?,
);

Map<String, dynamic> _$RegexPatternToJson(RegexPattern instance) =>
    <String, dynamic>{
      'id': instance.id,
      'regexName': instance.regexName,
      'pattern': instance.pattern,
      'bankName': instance.bankName,
      'defaultType': _$TransactionTypeEnumMap[instance.defaultType]!,
      'isSystem': instance.isSystem,
    };
