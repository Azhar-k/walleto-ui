import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walleto_ui/screens/category_form_screen.dart';
import 'package:walleto_ui/providers/core_providers.dart';
import 'package:walleto_ui/models/models.dart';
import 'package:walleto_ui/services/category_service.dart';

class MockCategoryService implements CategoryService {
  Category? lastCreated;
  Category? lastUpdated;
  bool throwError = false;

  @override
  Future<Category> createCategory(Category category) async {
    lastCreated = category;
    if (throwError) throw Exception('API Error');
    return category;
  }

  @override
  Future<Category> updateCategory(int id, Category category) async {
    lastUpdated = category;
    if (throwError) throw Exception('API Error');
    return category;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildTestSetup(
    MockCategoryService mockService, {
    Category? existingCategory,
    CategoryType? defaultType,
  }) {
    return ProviderScope(
      overrides: [
        categoryServiceProvider.overrideWithValue(mockService),
        // We override categoriesProvider so that ref.invalidate does not fail or try to fetch from API
        categoriesProvider.overrideWith((ref) => <Category>[]),
      ],
      child: MaterialApp(
        home: CategoryFormScreen(
          existingCategory: existingCategory,
          defaultType: defaultType,
        ),
      ),
    );
  }

  testWidgets('CategoryFormScreen - Add Mode Rendering & Validation', (
    WidgetTester tester,
  ) async {
    final mockService = MockCategoryService();

    await tester.pumpWidget(buildTestSetup(mockService));

    expect(find.text('Add Category'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);

    // Tap save without entering name
    await tester.tap(find.text('SAVE CATEGORY'));
    await tester.pump();

    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('CategoryFormScreen - Create New Category successfully', (
    WidgetTester tester,
  ) async {
    final mockService = MockCategoryService();

    await tester.pumpWidget(
      buildTestSetup(mockService, defaultType: CategoryType.expense),
    );

    await tester.enterText(find.byType(TextFormField), 'Groceries');

    await tester.tap(find.text('SAVE CATEGORY'));
    await tester.pump(); // trigger validation and submission

    expect(mockService.lastCreated, isNotNull);
    expect(mockService.lastCreated!.name, 'Groceries');
    expect(mockService.lastCreated!.type, CategoryType.expense);
  });

  testWidgets(
    'CategoryFormScreen - Edit Mode Rendering & Update successfully',
    (WidgetTester tester) async {
      final mockService = MockCategoryService();
      final existingCategory = Category(
        id: 1,
        name: 'Salary',
        type: CategoryType.income,
      );

      await tester.pumpWidget(
        buildTestSetup(mockService, existingCategory: existingCategory),
      );

      expect(find.text('Edit Category'), findsOneWidget);
      // Segmented button for Type should NOT be visible in edit mode
      expect(find.byType(SegmentedButton<CategoryType>), findsNothing);

      await tester.enterText(find.byType(TextFormField), 'Monthly Salary');
      await tester.tap(find.text('SAVE CATEGORY'));
      await tester.pump();

      expect(mockService.lastUpdated, isNotNull);
      expect(mockService.lastUpdated!.name, 'Monthly Salary');
      expect(mockService.lastUpdated!.type, CategoryType.income);
    },
  );

  testWidgets('CategoryFormScreen - Error Handling', (
    WidgetTester tester,
  ) async {
    final mockService = MockCategoryService()..throwError = true;

    await tester.pumpWidget(buildTestSetup(mockService));

    await tester.enterText(find.byType(TextFormField), 'Test');
    await tester.tap(find.text('SAVE CATEGORY'));
    await tester.pump();

    expect(find.textContaining('Failed to save category'), findsOneWidget);
  });
}
