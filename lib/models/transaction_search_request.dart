// DO NOT EDIT
// This file is generated

import 'package:json_annotation/json_annotation.dart';

part 'transaction_search_request.g.dart';

@JsonSerializable(explicitToJson: true)
class TransactionSearchRequest {
  final String? fromDate;
  final String? toDate;
  final String? transactionType;
  final String? query;
  final String? description;
  final String? counterpartyName;
  final int? categoryId;
  final int? accountId;
  final int? recurringPaymentId;
  final double? minAmount;
  final double? maxAmount;
  final bool? isExcludeFromSummary;

  TransactionSearchRequest({
    this.fromDate,
    this.toDate,
    this.transactionType,
    this.query,
    this.description,
    this.counterpartyName,
    this.categoryId,
    this.accountId,
    this.recurringPaymentId,
    this.minAmount,
    this.maxAmount,
    this.isExcludeFromSummary,
  });

  factory TransactionSearchRequest.fromJson(Map<String, dynamic> json) =>
      _$TransactionSearchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionSearchRequestToJson(this);
}
