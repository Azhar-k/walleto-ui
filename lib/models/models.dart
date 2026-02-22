import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

enum TransactionType {
  @JsonValue('CREDIT')
  CREDIT,
  @JsonValue('DEBIT')
  DEBIT,
}

enum CategoryType {
  @JsonValue('INCOME')
  INCOME,
  @JsonValue('EXPENSE')
  EXPENSE,
}

@JsonSerializable()
class Account {
  final int? id;
  final String name;
  final String? accountNumber;
  final String? bank;
  final bool? isDefault;
  final String? expiryDate;
  final String? description;
  final String? currency;
  final int? version;

  Account({
    this.id,
    required this.name,
    this.accountNumber,
    this.bank,
    this.isDefault,
    this.expiryDate,
    this.description,
    this.currency,
    this.version,
  });

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
  Map<String, dynamic> toJson() => _$AccountToJson(this);
}

@JsonSerializable()
class Category {
  final int? id;
  final String name;
  final CategoryType type;
  final int? version;

  Category({this.id, required this.name, required this.type, this.version});

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}

@JsonSerializable()
class RecurringPayment {
  final int? id;
  final String name;
  final double amount;
  final int dueDay;
  final String? expiryDate;
  final bool? isCompleted;
  final String? lastCompletedDate;
  final int? version;

  RecurringPayment({
    this.id,
    required this.name,
    required this.amount,
    required this.dueDay,
    this.expiryDate,
    this.isCompleted,
    this.lastCompletedDate,
    this.version,
  });

  factory RecurringPayment.fromJson(Map<String, dynamic> json) =>
      _$RecurringPaymentFromJson(json);
  Map<String, dynamic> toJson() => _$RecurringPaymentToJson(this);
}

/// Flat DTO matching the API's TransactionDTO.
/// The API sends flat fields (categoryId, categoryName, accountId, accountName)
/// rather than nested objects.
@JsonSerializable()
class Transaction {
  final int? id;
  final double amount;
  final TransactionType transactionType;
  @JsonKey(name: 'dateTime')
  final DateTime dateTime;
  final String? description;
  final int? categoryId;
  final String? categoryName;
  final int? accountId;
  final String? accountName;
  final String? counterpartyName;
  final String? smsBody;
  final String? smsSender;
  final String? smsHash;
  final int? recurringPaymentId;
  final bool? excludeFromSummary;
  final int? version;

  Transaction({
    this.id,
    required this.amount,
    required this.transactionType,
    required this.dateTime,
    this.description,
    this.categoryId,
    this.categoryName,
    this.accountId,
    this.accountName,
    this.counterpartyName,
    this.smsBody,
    this.smsSender,
    this.smsHash,
    this.recurringPaymentId,
    this.excludeFromSummary,
    this.version,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionToJson(this);
}

@JsonSerializable()
class CategorySummaryBreakdown {
  final String categoryName;
  final CategoryType type;
  final double totalAmount;
  final int transactionCount;

  CategorySummaryBreakdown({
    required this.categoryName,
    required this.type,
    required this.totalAmount,
    required this.transactionCount,
  });

  factory CategorySummaryBreakdown.fromJson(Map<String, dynamic> json) =>
      _$CategorySummaryBreakdownFromJson(json);
  Map<String, dynamic> toJson() => _$CategorySummaryBreakdownToJson(this);
}

@JsonSerializable()
class MonthlySummary {
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final List<CategorySummaryBreakdown>? categoryBreakdowns;

  MonthlySummary({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    this.categoryBreakdowns,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) =>
      _$MonthlySummaryFromJson(json);
  Map<String, dynamic> toJson() => _$MonthlySummaryToJson(this);
}

@JsonSerializable()
class RegexPattern {
  final int? id;
  final String name;
  final String pattern;
  final TransactionType transactionType;
  final bool? isActive;
  final int? version;

  RegexPattern({
    this.id,
    required this.name,
    required this.pattern,
    required this.transactionType,
    this.isActive,
    this.version,
  });

  factory RegexPattern.fromJson(Map<String, dynamic> json) =>
      _$RegexPatternFromJson(json);
  Map<String, dynamic> toJson() => _$RegexPatternToJson(this);
}
