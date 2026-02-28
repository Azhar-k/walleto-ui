import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/core_providers.dart';
import '../models/models.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  final Category? existingCategory;
  final CategoryType? defaultType;

  const CategoryFormScreen({
    super.key,
    this.existingCategory,
    this.defaultType,
  });

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late CategoryType _type;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _type =
        widget.existingCategory?.type ??
        widget.defaultType ??
        CategoryType.expense;
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final service = ref.read(categoryServiceProvider);

      final category = Category(
        id: widget.existingCategory?.id,
        name: _nameController.text.trim(),
        type: _type,
      );

      try {
        if (widget.existingCategory == null) {
          await service.createCategory(category);
        } else {
          await service.updateCategory(category.id!, category);
        }

        ref.invalidate(categoriesProvider); // Refresh list
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save category: $e')),
          );
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
          widget.existingCategory == null ? 'Add Category' : 'Edit Category',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        prefixIcon: Icon(Icons.category),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    if (widget.existingCategory == null)
                      SegmentedButton<CategoryType>(
                        segments: const [
                          ButtonSegment(
                            value: CategoryType.expense,
                            label: Text('Expense'),
                          ),
                          ButtonSegment(
                            value: CategoryType.income,
                            label: Text('Income'),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (Set<CategoryType> newSelection) {
                          setState(() {
                            _type = newSelection.first;
                          });
                        },
                      ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text(
                        'SAVE CATEGORY',
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
