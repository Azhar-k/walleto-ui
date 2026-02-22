import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/core_providers.dart';
import '../models/models.dart';

class SelfTransferScreen extends ConsumerStatefulWidget {
  const SelfTransferScreen({super.key});

  @override
  ConsumerState<SelfTransferScreen> createState() => _SelfTransferScreenState();
}

class _SelfTransferScreenState extends ConsumerState<SelfTransferScreen> {
  final _formKey = GlobalKey<FormState>();

  Account? _fromAccount;
  Account? _toAccount;
  Category? _category;

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _transferDate = DateTime.now();
  TimeOfDay _transferTime = TimeOfDay.now();

  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate() &&
        _fromAccount != null &&
        _toAccount != null &&
        _category != null) {
      if (_fromAccount!.id == _toAccount!.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Source and Destination accounts must be different.'),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);
      final service = ref.read(transferServiceProvider);

      final dateTime = DateTime(
        _transferDate.year,
        _transferDate.month,
        _transferDate.day,
        _transferTime.hour,
        _transferTime.minute,
      );

      final req = {
        "fromAccountId": _fromAccount!.id,
        "toAccountId": _toAccount!.id,
        "amount": double.parse(_amountController.text),
        "dateTime": dateTime.toIso8601String(),
        "categoryId": _category!.id,
        "description": _descriptionController.text.trim(),
      };

      try {
        await service.transferFunds(req);

        // Refresh things that changed
        ref.invalidate(accountsProvider);
        ref.invalidate(transactionSearchProvider);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Transfer Successful')));
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Transfer failed: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all mandatory dropdowns.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Self Transfer')),
      body: accountsAsync.when(
        data: (accounts) {
          return categoriesAsync.when(
            data: (categories) {
              final expenses = categories
                  .where((c) => c.type == CategoryType.EXPENSE)
                  .toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<Account>(
                        initialValue: _fromAccount,
                        decoration: const InputDecoration(
                          labelText: 'From Account *',
                          prefixIcon: Icon(
                            Icons.arrow_upward,
                            color: Colors.red,
                          ),
                        ),
                        items: accounts
                            .map(
                              (a) => DropdownMenuItem(
                                value: a,
                                child: Text(a.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _fromAccount = val),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Account>(
                        initialValue: _toAccount,
                        decoration: const InputDecoration(
                          labelText: 'To Account *',
                          prefixIcon: Icon(
                            Icons.arrow_downward,
                            color: Colors.green,
                          ),
                        ),
                        items: accounts
                            .map(
                              (a) => DropdownMenuItem(
                                value: a,
                                child: Text(a.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _toAccount = val),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount *',
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null)
                            return 'Must be a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: const Text('Date'),
                              subtitle: Text(
                                DateFormat.yMMMd().format(_transferDate),
                              ),
                              leading: const Icon(Icons.calendar_today),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade400),
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _transferDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null)
                                  setState(() => _transferDate = picked);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ListTile(
                              title: const Text('Time'),
                              subtitle: Text(_transferTime.format(context)),
                              leading: const Icon(Icons.access_time),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade400),
                              ),
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _transferTime,
                                );
                                if (picked != null)
                                  setState(() => _transferTime = picked);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Category>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: expenses
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
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'TRANSFER FUNDS',
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
