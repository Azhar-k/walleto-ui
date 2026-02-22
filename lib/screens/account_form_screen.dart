import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/core_providers.dart';
import '../providers/summary_providers.dart';
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
  late TextEditingController _expiryDateController;
  String _currency = 'INR';
  bool _isLoading = false;
  bool _isDefault = false;

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
    _expiryDateController = TextEditingController(
      text: widget.existingAccount?.expiryDate ?? '',
    );
    _isDefault = widget.existingAccount?.isDefault ?? false;

    if (widget.existingAccount?.currency != null &&
        _currencies.contains(widget.existingAccount!.currency)) {
      _currency = widget.existingAccount!.currency!;
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete this account? All transactions will be deleted as well.',
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
            .read(accountServiceProvider)
            .deleteAccount(widget.existingAccount!.id!);
        ref.invalidate(accountsProvider);
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
        expiryDate: _expiryDateController.text.trim().isEmpty
            ? null
            : _expiryDateController.text.trim(),
        isDefault: _isDefault,
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
    final isEditing = widget.existingAccount != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Account' : 'Add Account'),
        actions: [
          if (isEditing && widget.existingAccount?.isDefault != true)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              color: Colors.red.shade300,
              onPressed: _isLoading ? null : _confirmDelete,
            ),
        ],
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
                      controller: _expiryDateController,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date (MM/YY)',
                        hintText: 'Optional',
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Set as Default Account'),
                      subtitle: const Text(
                        'Used for default transaction views',
                      ),
                      value: _isDefault,
                      onChanged: widget.existingAccount?.isDefault == true
                          ? null // Prevent unchecking if it's already the default (they should make another one default instead)
                          : (val) => setState(() => _isDefault = val),
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
