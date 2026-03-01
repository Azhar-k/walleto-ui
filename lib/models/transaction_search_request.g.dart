// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_search_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionSearchRequest _$TransactionSearchRequestFromJson(
  Map<String, dynamic> json,
) => TransactionSearchRequest(
  fromDate: json['fromDate'] as String?,
  toDate: json['toDate'] as String?,
  transactionType: json['transactionType'] as String?,
  query: json['query'] as String?,
  description: json['description'] as String?,
  counterpartyName: json['counterpartyName'] as String?,
  categoryId: (json['categoryId'] as num?)?.toInt(),
  accountId: (json['accountId'] as num?)?.toInt(),
  recurringPaymentId: (json['recurringPaymentId'] as num?)?.toInt(),
  minAmount: (json['minAmount'] as num?)?.toDouble(),
  maxAmount: (json['maxAmount'] as num?)?.toDouble(),
  isExcludeFromSummary: json['isExcludeFromSummary'] as bool?,
);

Map<String, dynamic> _$TransactionSearchRequestToJson(
  TransactionSearchRequest instance,
) => <String, dynamic>{
  'fromDate': instance.fromDate,
  'toDate': instance.toDate,
  'transactionType': instance.transactionType,
  'query': instance.query,
  'description': instance.description,
  'counterpartyName': instance.counterpartyName,
  'categoryId': instance.categoryId,
  'accountId': instance.accountId,
  'recurringPaymentId': instance.recurringPaymentId,
  'minAmount': instance.minAmount,
  'maxAmount': instance.maxAmount,
  'isExcludeFromSummary': instance.isExcludeFromSummary,
};
