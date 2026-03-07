import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/additional_providers.dart';
import '../models/models.dart';

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditLogsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(auditLogsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_hasActiveFilter(ref))
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  const Text(
                    'Filters Applied',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ref.read(auditLogSearchFilterProvider.notifier).state =
                          AuditLogSearchRequest();
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: auditLogsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No audit logs available.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(auditLogsProvider),
                  child: ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _AuditLogTile(log: log);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, st) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Failed to load audit logs: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(auditLogsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilter(WidgetRef ref) {
    final filter = ref.read(auditLogSearchFilterProvider);
    return filter.action != null ||
        filter.entityType != null ||
        filter.entityId != null ||
        filter.fromDate != null ||
        filter.toDate != null ||
        filter.username != null ||
        filter.query != null;
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _AuditLogFilterForm(
            currentFilter: ref.read(auditLogSearchFilterProvider),
            onApply: (newFilter) {
              ref.read(auditLogSearchFilterProvider.notifier).state = newFilter;
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }
}

class _AuditLogFilterForm extends StatefulWidget {
  final AuditLogSearchRequest currentFilter;
  final ValueChanged<AuditLogSearchRequest> onApply;

  const _AuditLogFilterForm({
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<_AuditLogFilterForm> createState() => _AuditLogFilterFormState();
}

class _AuditLogFilterFormState extends State<_AuditLogFilterForm> {
  final _actionController = TextEditingController();
  final _entityTypeController = TextEditingController();
  final _queryController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _actionController.text = widget.currentFilter.action ?? '';
    _entityTypeController.text = widget.currentFilter.entityType ?? '';
    _queryController.text = widget.currentFilter.query ?? '';
    if (widget.currentFilter.fromDate != null) {
      _fromDate = DateTime.tryParse(widget.currentFilter.fromDate!);
    }
    if (widget.currentFilter.toDate != null) {
      _toDate = DateTime.tryParse(widget.currentFilter.toDate!);
    }
  }

  @override
  void dispose() {
    _actionController.dispose();
    _entityTypeController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Audit Logs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _actionController.text.isEmpty
                ? null
                : _actionController.text,
            decoration: const InputDecoration(
              labelText: 'Action',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'CREATE', child: Text('CREATE')),
              DropdownMenuItem(value: 'UPDATE', child: Text('UPDATE')),
              DropdownMenuItem(value: 'DELETE', child: Text('DELETE')),
            ],
            onChanged: (value) {
              setState(() {
                _actionController.text = value ?? '';
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _entityTypeController.text.isEmpty
                ? null
                : _entityTypeController.text,
            decoration: const InputDecoration(
              labelText: 'Entity Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Transaction',
                child: Text('Transaction'),
              ),
              DropdownMenuItem(value: 'Account', child: Text('Account')),
              DropdownMenuItem(value: 'Category', child: Text('Category')),
              DropdownMenuItem(
                value: 'RecurringPayment',
                child: Text('Recurring Payment'),
              ),
              DropdownMenuItem(
                value: 'RegexPattern',
                child: Text('Regex Pattern'),
              ),
              DropdownMenuItem(value: 'User', child: Text('User')),
            ],
            onChanged: (value) {
              setState(() {
                _entityTypeController.text = value ?? '';
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _queryController,
            decoration: const InputDecoration(
              labelText: 'Search Query',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _fromDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _fromDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'From Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _fromDate != null
                          ? DateFormat('yyyy-MM-dd').format(_fromDate!)
                          : 'Select Date',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _toDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _toDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'To Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _toDate != null
                          ? DateFormat('yyyy-MM-dd').format(_toDate!)
                          : 'Select Date',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final newFilter = AuditLogSearchRequest(
                action: _actionController.text.isEmpty
                    ? null
                    : _actionController.text,
                entityType: _entityTypeController.text.isEmpty
                    ? null
                    : _entityTypeController.text,
                query: _queryController.text.isEmpty
                    ? null
                    : _queryController.text,
                fromDate: _fromDate?.toIso8601String().split('T')[0],
                toDate: _toDate?.toIso8601String().split('T')[0],
              );
              widget.onApply(newFilter);
            },
            child: const Text('Apply Filter'),
          ),
        ],
      ),
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  final AuditLog log;

  const _AuditLogTile({required this.log});

  Color _getActionColor(String? action) {
    switch (action?.toUpperCase()) {
      case 'CREATE':
        return Colors.green;
      case 'UPDATE':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String? action) {
    switch (action?.toUpperCase()) {
      case 'CREATE':
        return Icons.add_circle_outline;
      case 'UPDATE':
        return Icons.edit_outlined;
      case 'DELETE':
        return Icons.delete_outline;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionColor = _getActionColor(log.action);
    final actionIcon = _getActionIcon(log.action);
    final timestampText = log.timestamp != null
        ? DateFormat('MMM d, y • h:mm:ss a').format(log.timestamp!.toLocal())
        : 'Unknown time';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: actionColor.withValues(alpha: 0.1),
        child: Icon(actionIcon, color: actionColor),
      ),
      title: Text(
        log.description ?? '${log.action} ${log.entityType}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'Entity: ${log.entityType ?? 'N/A'} (ID: ${log.entityId ?? 'N/A'})',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          if (log.username != null)
            Text(
              'User: ${log.username}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          const SizedBox(height: 4),
          Text(
            timestampText,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
      onTap: () {
        // Optionally show a dialog with the raw JSON changes payload if needed
        if (log.changes != null && log.changes!.isNotEmpty) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Change Details'),
              content: SingleChildScrollView(
                child: SelectableText(log.changes!),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
