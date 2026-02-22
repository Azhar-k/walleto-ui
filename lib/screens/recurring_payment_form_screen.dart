import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/core_providers.dart';
import '../providers/additional_providers.dart';
import '../models/models.dart';

class RecurringPaymentFormScreen extends ConsumerStatefulWidget {
  final RecurringPayment? existingPayment;
  const RecurringPaymentFormScreen({super.key, this.existingPayment});

  @override
  ConsumerState<RecurringPaymentFormScreen> createState() =>
      _RecurringPaymentFormScreenState();
}

class _RecurringPaymentFormScreenState
    extends ConsumerState<RecurringPaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _dueDayController;
  DateTime? _expiryDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingPayment?.name ?? '',
    );
    _amountController = TextEditingController(
      text: widget.existingPayment?.amount.toString() ?? '',
    );
    _dueDayController = TextEditingController(
      text: widget.existingPayment?.dueDay.toString() ?? '',
    );

    if (widget.existingPayment?.expiryDate != null) {
      _expiryDate = DateTime.tryParse(widget.existingPayment!.expiryDate!);
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate() && _expiryDate != null) {
      setState(() => _isLoading = true);
      final service = ref.read(recurringPaymentServiceProvider);

      final payment = RecurringPayment(
        id: widget.existingPayment?.id,
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        dueDay: int.parse(_dueDayController.text.trim()),
        expiryDate: DateFormat('yyyy-MM-dd').format(_expiryDate!),
      );

      try {
        if (widget.existingPayment == null) {
          await service.createRecurringPayment(payment);
        } else {
          await service.updateRecurringPayment(payment.id!, payment);
        }

        ref.invalidate(recurringPaymentsProvider);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to save payment: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expiry date.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingPayment == null
              ? 'Add Recurring Payment'
              : 'Edit Payment',
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
                        labelText: 'Payment Name *',
                        prefixIcon: Icon(Icons.receipt),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
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
                    TextFormField(
                      controller: _dueDayController,
                      decoration: const InputDecoration(
                        labelText: 'Due Day (1-31) *',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final val = int.tryParse(v);
                        if (val == null || val < 1 || val > 31)
                          return 'Must be a valid day (1-31)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Expiry Date *'),
                      subtitle: Text(
                        _expiryDate != null
                            ? DateFormat.yMMMd().format(_expiryDate!)
                            : 'Select Date',
                      ),
                      leading: const Icon(Icons.event),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              _expiryDate ??
                              DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (picked != null) {
                          setState(() => _expiryDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text(
                        'SAVE PAYMENT',
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
