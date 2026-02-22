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
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(auditLogsProvider),
          ),
        ],
      ),
      body: auditLogsAsync.when(
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
              separatorBuilder: (context, index) => const Divider(height: 1),
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
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
