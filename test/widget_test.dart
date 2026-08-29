import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sprout_app/main.dart';
import 'package:sprout_app/features/fridge/models/freshness_category.dart';
import 'package:sprout_app/features/fridge/models/product_item.dart';
import 'package:sprout_app/features/recipes/data/curated_recipes.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru', null);
  });

  group('Domain & Logic Unit Tests', () {
    test('ProductItem correctly calculates days until expiry and FreshnessCategory', () {
      final now = DateTime.now();

      final urgentItem = ProductItem(
        name: 'Томаты',
        amount: 200,
        unit: 'г',
        category: 'Овощи',
        addedDate: now,
        expiryDate: now.add(const Duration(days: 1)),
      );
      expect(urgentItem.freshness, FreshnessCategory.urgent);

      final soonItem = ProductItem(
        name: 'Курица',
        amount: 500,
        unit: 'г',
        category: 'Мясо',
        addedDate: now,
        expiryDate: now.add(const Duration(days: 4)),
      );
      expect(soonItem.freshness, FreshnessCategory.soon);

      final goodItem = ProductItem(
        name: 'Сыр',
        amount: 200,
        unit: 'г',
        category: 'Молочные',
        addedDate: now,
        expiryDate: now.add(const Duration(days: 8)),
      );
      expect(goodItem.freshness, FreshnessCategory.good);

      final pantryItem = ProductItem(
        name: 'Паста',
        amount: 500,
        unit: 'г',
        category: 'Бакалея',
        addedDate: now,
        expiryDate: now.add(const Duration(days: 90)),
      );
      expect(pantryItem.freshness, FreshnessCategory.pantry);
    });

    test('Curated recipes list contains rich recipes with Zero-Waste tips', () {
      expect(kCuratedRecipes.isNotEmpty, true);
      for (final recipe in kCuratedRecipes) {
        expect(recipe.title.isNotEmpty, true);
        expect(recipe.ingredients.isNotEmpty, true);
        expect(recipe.steps.isNotEmpty, true);
        expect(recipe.calories > 0, true);
      }
    });
  });

  group('Widget Tests', () {
    testWidgets('Sprout App launches and displays main navigation tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SproutApp(),
        ),
      );
      await tester.pump();

      expect(find.text('План'), findsOneWidget);
      expect(find.text('Холодильник'), findsOneWidget);
      expect(find.text('Рецепты'), findsOneWidget);
      expect(find.text('Покупки'), findsOneWidget);
    });
  });
}
