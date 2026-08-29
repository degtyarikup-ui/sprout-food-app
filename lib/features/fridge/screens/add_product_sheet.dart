import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/product_item.dart';
import '../providers/fridge_provider.dart';

class AddProductSheet extends ConsumerStatefulWidget {
  const AddProductSheet({super.key});

  @override
  ConsumerState<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<AddProductSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController(text: '1');
  String _selectedUnit = 'шт';
  String _selectedCategory = 'Овощи и зелень';
  String _selectedEmoji = '🥑';
  int _shelfLifeDays = 4;

  final List<String> _units = ['шт', 'г', 'кг', 'мл', 'л', 'уп'];
  final List<String> _categories = [
    'Овощи и зелень',
    'Молочные продукты',
    'Мясо и птица',
    'Рыба и морепродукты',
    'Бакалея',
    'Фрукты и ягоды',
    'Соусы и специи',
  ];

  final List<String> _emojis = ['🥑', '🍅', '🧀', '🥚', '🍗', '🐟', '🥛', '🥦', '🥖', '🍎', '🍄', '🥩'];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final amount = double.tryParse(_amountController.text) ?? 1.0;
    final now = DateTime.now();

    final item = ProductItem(
      name: name,
      amount: amount,
      unit: _selectedUnit,
      category: _selectedCategory,
      addedDate: now,
      expiryDate: now.add(Duration(days: _shelfLifeDays)),
      emoji: _selectedEmoji,
      estimatedPrice: 150.0,
    );

    ref.read(fridgeProvider.notifier).addProduct(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Добавить в холодильник', style: AppTypography.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Emoji selector
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _emojis.length,
                itemBuilder: (context, index) {
                  final e = _emojis[index];
                  final isSelected = _selectedEmoji == e;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = e),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.15)
                            : (isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Product Name
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Название продукта',
                hintText: 'например, Спелые томаты',
              ),
            ),
            const SizedBox(height: 14),

            // Amount and Unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Количество'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(labelText: 'Ед. изм.'),
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedUnit = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Категория'),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 16),

            // Shelf Life Slider
            Text(
              'Срок хранения: $_shelfLifeDays ${_shelfLifeDays == 1 ? 'день' : (_shelfLifeDays < 5 ? 'дня' : 'дней')}',
              style: AppTypography.labelLarge,
            ),
            Slider(
              value: _shelfLifeDays.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _shelfLifeDays = val.round()),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Сохранить продукт'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
