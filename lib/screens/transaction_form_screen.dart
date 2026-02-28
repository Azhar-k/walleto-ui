import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/core_providers.dart';
import '../providers/summary_providers.dart';
import '../providers/additional_providers.dart';
import '../models/models.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final Transaction? existingTransaction;
  const TransactionFormScreen({super.key, this.existingTransaction});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  Account? _account;
  Category? _category;
  TransactionType _type = TransactionType.debit; // Default Expense mapping

  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _counterpartyController;

  DateTime _transactionDate = DateTime.now();
  TimeOfDay _transactionTime = TimeOfDay.now();

  bool _excludeFromSummary = false;
  bool _isLoading = false;
  RecurringPayment? _linkedRecurringPayment;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.existingTransaction?.amount.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.existingTransaction?.description ?? '',
    );
    _counterpartyController = TextEditingController(
      text: widget.existingTransaction?.counterpartyName ?? '',
    );

    if (widget.existingTransaction != null) {
      _type = widget.existingTransaction!.transactionType;
      _transactionDate = widget.existingTransaction!.dateTime;
      _transactionTime = TimeOfDay.fromDateTime(
        widget.existingTransaction!.dateTime,
      );
      _excludeFromSummary =
          widget.existingTransaction!.excludeFromSummary ?? false;
    }
  }

  String _currencySymbol(String currency) {
    const symbols = {'INR': '₹', 'USD': '\$', 'EUR': '€', 'GBP': '£'};
    return symbols[currency] ?? currency;
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await ref
            .read(transactionServiceProvider)
            .deleteTransaction(widget.existingTransaction!.id!);
        ref.invalidate(transactionSearchProvider);
        ref.invalidate(netBalanceProvider);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _submit(List<Account> accounts, List<Category> categories) async {
    if (_formKey.currentState!.validate() &&
        _account != null &&
        _category != null) {
      setState(() => _isLoading = true);
      final service = ref.read(transactionServiceProvider);

      final dateTime = DateTime(
        _transactionDate.year,
        _transactionDate.month,
        _transactionDate.day,
        _transactionTime.hour,
        _transactionTime.minute,
      );

      // Build a flat Transaction for the API
      final transaction = Transaction(
        id: widget.existingTransaction?.id,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dateTime: dateTime,
        transactionType: _type,
        categoryId: _category!.id,
        categoryName: _category!.name,
        accountId: _account!.id,
        accountName: _account!.name,
        counterpartyName: _counterpartyController.text.trim(),
        excludeFromSummary: _excludeFromSummary,
        recurringPaymentId: _linkedRecurringPayment?.id,
      );

      try {
        if (widget.existingTransaction == null) {
          await service.createTransaction(transaction);
        } else {
          await service.updateTransaction(transaction.id!, transaction);
        }

        // Refresh search list and balance
        ref.invalidate(transactionSearchProvider);
        ref.invalidate(netBalanceProvider);

        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save transaction: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_account == null || _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account and Category are required.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final recurringPaymentsAsync = ref.watch(recurringPaymentsProvider);
    final isEditing = widget.existingTransaction != null;

    // Currency symbol from the currently selected account
    final currency = _account?.currency ?? 'INR';
    final currencySymbol = _currencySymbol(currency);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              color: Colors.red.shade300,
              onPressed: _isLoading ? null : _confirmDelete,
            ),
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          return categoriesAsync.when(
            data: (categories) {
              final recurringPayments =
                  recurringPaymentsAsync.valueOrNull ?? [];

              // Preselect for editing
              if (widget.existingTransaction != null &&
                  _account == null &&
                  _category == null) {
                _account = accounts.firstWhere(
                  (a) => a.id == widget.existingTransaction!.accountId,
                  orElse: () => accounts.first,
                );
                _category = categories.firstWhere(
                  (c) => c.id == widget.existingTransaction!.categoryId,
                  orElse: () => categories.first,
                );
                // Preselect linked recurring payment
                final rpId = widget.existingTransaction!.recurringPaymentId;
                if (rpId != null && _linkedRecurringPayment == null) {
                  _linkedRecurringPayment = recurringPayments
                      .where((r) => r.id == rpId)
                      .firstOrNull;
                }
              } else if (_account == null && accounts.isNotEmpty) {
                _account = accounts.firstWhere(
                  (a) => a.isDefault == true,
                  orElse: () => accounts.first,
                );
              }

              final filteredCategories = categories
                  .where(
                    (c) =>
                        c.type ==
                        (_type == TransactionType.credit
                            ? CategoryType.income
                            : CategoryType.expense),
                  )
                  .toList();

              // if type changed and category invalid, clear it
              if (_category != null &&
                  !filteredCategories.any((c) => c.id == _category!.id)) {
                _category = null;
              }

              if (_category == null && filteredCategories.isNotEmpty) {
                // Pre-select the first available category as a default
                _category = filteredCategories.first;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<TransactionType>(
                        segments: const [
                          ButtonSegment(
                            value: TransactionType.debit,
                            label: Text('Debit/Expense'),
                          ),
                          ButtonSegment(
                            value: TransactionType.credit,
                            label: Text('Credit/Income'),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged:
                            (Set<TransactionType> newSelection) {
                              setState(() {
                                _type = newSelection.first;
                              });
                            },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Amount *',
                          prefixIcon: const Icon(Icons.attach_money),
                          prefixText: '$currencySymbol ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) {
                            return 'Must be a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          prefixIcon: Icon(Icons.description),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: const Text('Date'),
                              subtitle: Text(
                                DateFormat.yMMMd().format(_transactionDate),
                              ),
                              leading: const Icon(Icons.calendar_today),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade400),
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _transactionDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() => _transactionDate = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ListTile(
                              title: const Text('Time'),
                              subtitle: Text(_transactionTime.format(context)),
                              leading: const Icon(Icons.access_time),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade400),
                              ),
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _transactionTime,
                                );
                                if (picked != null) {
                                  setState(() => _transactionTime = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Account>(
                        initialValue: _account,
                        decoration: const InputDecoration(
                          labelText: 'Account *',
                          prefixIcon: Icon(Icons.account_balance_wallet),
                        ),
                        items: accounts
                            .map(
                              (a) => DropdownMenuItem(
                                value: a,
                                child: Text(a.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _account = val),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Category>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: filteredCategories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _category = val),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _counterpartyController,
                        decoration: const InputDecoration(
                          labelText: 'Counterparty (optional)',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ── Recurring Payment linkage ─────────────────────────
                      DropdownButtonFormField<RecurringPayment?>(
                        initialValue: _linkedRecurringPayment,
                        decoration: const InputDecoration(
                          labelText: 'Linked Recurring Payment (optional)',
                          prefixIcon: Icon(Icons.repeat),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('None'),
                          ),
                          ...recurringPayments.map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(
                                '${r.name}  •  ₹${r.amount.toStringAsFixed(0)}',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _linkedRecurringPayment = val),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Exclude from Summary'),
                        value: _excludeFromSummary,
                        onChanged: (val) =>
                            setState(() => _excludeFromSummary = val),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _submit(accounts, categories),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'SAVE TRANSACTION',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) =>
                Center(child: Text('Error loading categories: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading accounts: $e')),
      ),
    );
  }
}
