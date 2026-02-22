import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/additional_providers.dart';

class RegexManagementScreen extends ConsumerWidget {
  const RegexManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regexesAsync = ref.watch(regexesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Regex Patterns')),
      body: regexesAsync.when(
        data: (regexes) {
          if (regexes.isEmpty) {
            return const Center(child: Text('No custom regex patterns.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(regexesProvider),
            child: ListView.separated(
              itemCount: regexes.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final regex = regexes[index];
                return ListTile(
                  title: Row(
                    children: [
                      Text(
                        regex.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (regex.isActive == false) ...[
                        const SizedBox(width: 8),
                        const Badge(
                          label: Text('Inactive'),
                          backgroundColor: Colors.grey,
                        ),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type: ${regex.transactionType.name}'),
                      Text(
                        regex.pattern,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      // context.push('/regex-patterns/edit', extra: regex);
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // context.push('/regex-patterns/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
