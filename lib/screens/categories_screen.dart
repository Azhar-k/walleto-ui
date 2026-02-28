import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/core_providers.dart';
import '../models/models.dart';
import 'category_form_screen.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'EXPENSES'),
            Tab(text: 'INCOME'),
          ],
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final expenses = categories
              .where((c) => c.type == CategoryType.expense)
              .toList();
          final incomes = categories
              .where((c) => c.type == CategoryType.income)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(expenses, CategoryType.expense),
              _buildCategoryList(incomes, CategoryType.income),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final type = _tabController.index == 0
              ? CategoryType.expense
              : CategoryType.income;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryFormScreen(defaultType: type),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories, CategoryType type) {
    if (categories.isEmpty) {
      return Center(
        child: Text(
          'No ${type == CategoryType.expense ? 'expense' : 'income'} categories found.',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(categoriesProvider),
      child: ListView.separated(
        itemCount: categories.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final category = categories[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: type == CategoryType.expense
                  ? Theme.of(context).colorScheme.error.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              foregroundColor: type == CategoryType.expense
                  ? Theme.of(context).colorScheme.error
                  : Colors.green,
              child: Icon(
                type == CategoryType.expense
                    ? Icons.trending_down
                    : Icons.trending_up,
              ),
            ),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CategoryFormScreen(existingCategory: category),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
