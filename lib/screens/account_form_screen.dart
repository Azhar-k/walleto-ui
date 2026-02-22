import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/core_providers.dart';
import '../models/models.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  final Account? existingAccount;
  const AccountFormScreen({super.key, this.existingAccount});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bankController;
  late TextEditingController _accountNumberController;
  late TextEditingController _descriptionController;
  String _currency = 'INR';
  bool _isLoading = false;

  final List<String> _currencies = ['INR', 'USD', 'EUR', 'GBP'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingAccount?.name ?? '',
    );
    _bankController = TextEditingController(
      text: widget.existingAccount?.bank ?? '',
    );
    _accountNumberController = TextEditingController(
      text: widget.existingAccount?.accountNumber ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.existingAccount?.description ?? '',
    );
    if (widget.existingAccount?.currency != null &&
        _currencies.contains(widget.existingAccount!.currency)) {
      _currency = widget.existingAccount!.currency!;
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final service = ref.read(accountServiceProvider);

      final account = Account(
        id: widget.existingAccount?.id,
        name: _nameController.text.trim(),
        bank: _bankController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        description: _descriptionController.text.trim(),
        currency: _currency,
        isDefault: widget.existingAccount?.isDefault ?? false,
      );

      try {
        if (widget.existingAccount == null) {
          await service.createAccount(account);
        } else {
          await service.updateAccount(account.id!, account);
        }

        ref.invalidate(accountsProvider); // Refresh list
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to save account: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingAccount == null ? 'Add Account' : 'Edit Account',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Account Name *',
                        prefixIcon: Icon(Icons.wallet),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bankController,
                      decoration: const InputDecoration(
                        labelText: 'Bank Name',
                        prefixIcon: Icon(Icons.account_balance),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Account/Card Number ending',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        prefixIcon: Icon(Icons.payments),
                      ),
                      items: _currencies
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _currency = val);
                      },
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
                      onPressed: _submit,
                      child: const Text(
                        'SAVE ACCOUNT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
