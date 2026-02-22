import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/sms_providers.dart';
import '../providers/core_providers.dart';
import '../providers/summary_providers.dart';

class ScanSmsScreen extends ConsumerStatefulWidget {
  const ScanSmsScreen({super.key});

  @override
  ConsumerState<ScanSmsScreen> createState() => _ScanSmsScreenState();
}

class _ScanSmsScreenState extends ConsumerState<ScanSmsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isProcessing = false;
  String? _resultMessage;

  void _scanSms() async {
    setState(() {
      _isProcessing = true;
      _resultMessage = null;
    });

    try {
      // 1. Request SMS Permissions (Requires permission_handler or similar package)
      // Since this is a UI-only phase, we simulate reading SMS from the device

      // Simulate delay for reading device SMS
      await Future.delayed(const Duration(seconds: 1));

      // 2. Mock SMS Data that would normally be read from Native Side
      final mockMessages = [
        {
          "sender": "VM-HDFCBK",
          "body":
              "Rs.500.00 debited from a/c **1234 on 15/02/25 to Swiggy. Ref No: 123.",
          "timestamp": _startDate
              .add(const Duration(hours: 1))
              .millisecondsSinceEpoch,
        },
        {
          "sender": "AD-ICICIB",
          "body":
              "Acct **5678 credited with INR 2000.00 on 14-Feb-25. Info: Salary.",
          "timestamp": _startDate
              .add(const Duration(hours: 2))
              .millisecondsSinceEpoch,
        },
      ];

      // 3. Send to Backend - wrapped in BulkSmsDTO shape
      final service = ref.read(smsServiceProvider);
      final result =
          await service.processBatchSms({'messages': mockMessages})
              as Map<String, dynamic>? ??
          {};

      // 4. Update UI
      setState(() {
        final processed = result['createdTransactions'] ?? 0;
        final ignored = result['duplicatesIdentified'] ?? 0;
        final errors = result['processingError'] ?? 0;
        _resultMessage =
            'Scan Complete!\n\nCreated: $processed\nDuplicates: $ignored\nErrors: $errors';
      });

      // Refresh transactions and balances
      ref.invalidate(transactionSearchProvider);
      ref.invalidate(netBalanceProvider);
    } catch (e) {
      setState(() {
        _resultMessage = 'Failed to process SMS: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan SMS')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select a date range to scan your device for financial SMS messages.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('From date'),
                    subtitle: Text(DateFormat.yMMMd().format(_startDate)),
                    leading: const Icon(Icons.date_range),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListTile(
                    title: const Text('To date'),
                    subtitle: Text(DateFormat.yMMMd().format(_endDate)),
                    leading: const Icon(Icons.date_range),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _endDate = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isProcessing ? null : _scanSms,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'START SCAN',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 32),
            if (_resultMessage != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _resultMessage!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
