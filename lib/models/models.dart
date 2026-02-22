import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

enum TransactionType {
  @JsonValue('CREDIT') CREDIT,
  @JsonValue('DEBIT') DEBIT
}

enum CategoryType {
  @JsonValue('INCOME') INCOME,
  @JsonValue('EXPENSE') EXPENSE
}

@JsonSerializable()
class Account {
  final int? id;
  final String accountName;
  final String? baseAccountNumber;
  final String? bankName;
  final bool? isDefault;
  final String? cardExpiryDate;
  final String? description;
  final String? currency;

  Account({
    this.id,
    required this.accountName,
    this.baseAccountNumber,
    this.bankName,
    this.isDefault,
    this.cardExpiryDate,
    this.description,
    this.currency,
  });

  factory Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);
  Map<String, dynamic> toJson() => _$AccountToJson(this);
}

@JsonSerializable()
class Category {
  final int? id;
  final String name;
  final CategoryType type;

  Category({
    this.id,
    required this.name,
    required this.type,
  });

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}

@JsonSerializable()
class RecurringPayment {
  final int? id;
  final String name;
  final double amount;
  final int dueDay;
  final String expiryDate;
  final bool? completed;
  final String? lastCompletedDate;

  RecurringPayment({
    this.id,
    required this.name,
    required this.amount,
    required this.dueDay,
    required this.expiryDate,
    this.completed,
    this.lastCompletedDate,
  });

  factory RecurringPayment.fromJson(Map<String, dynamic> json) => _$RecurringPaymentFromJson(json);
  Map<String, dynamic> toJson() => _$RecurringPaymentToJson(this);
}

@JsonSerializable()
class Transaction {
  final int? id;
  final double amount;
  final String description;
  final DateTime transactionDateTime;
  final TransactionType type;
  final Category category;
  final Account account;
  final String? counterpartyName;
  final String? smsBody;
  final String? smsSender;
  final String? smsHash;
  final int? linkedRecurringPaymentId;
  final bool? excludeFromSummary;

  Transaction({
    this.id,
    required this.amount,
    required this.description,
    required this.transactionDateTime,
    required this.type,
    required this.category,
    required this.account,
    this.counterpartyName,
    this.smsBody,
    this.smsSender,
    this.smsHash,
    this.linkedRecurringPaymentId,
    this.excludeFromSummary,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
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

  factory CategorySummaryBreakdown.fromJson(Map<String, dynamic> json) => _$CategorySummaryBreakdownFromJson(json);
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

  factory MonthlySummary.fromJson(Map<String, dynamic> json) => _$MonthlySummaryFromJson(json);
  Map<String, dynamic> toJson() => _$MonthlySummaryToJson(this);
}

@JsonSerializable()
class RegexPattern {
    final int? id;
    final String regexName;
    final String pattern;
    final String bankName;
    final TransactionType defaultType;
    final bool? isSystem;

    RegexPattern({
        this.id,
        required this.regexName,
        required this.pattern,
        required this.bankName,
        required this.defaultType,
        this.isSystem
    });

    factory RegexPattern.fromJson(Map<String, dynamic> json) => _$RegexPatternFromJson(json);
    Map<String, dynamic> toJson() => _$RegexPatternToJson(this);
}
