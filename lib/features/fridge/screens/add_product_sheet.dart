import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/product_helper.dart';
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
  int _shelfDays = 3;
  String _selectedEmoji = '🥑';

  final List<String> _units = ['шт', 'г', 'кг', 'мл', 'л', 'уп'];
  final List<String> _categories = [
    'Овощи и зелень',
    'Молочные продукты',
    'Мясо и птица',
    'Рыба и морепродукты',
    'Фрукты и ягоды',
    'Бакалея',
  ];

  final List<String> _emojis = ['🥑', '🍅', '🥒', '🥩', '🍗', '🐟', '🥛', '🧀', '🥚', '🍞', '🍎', '🍋'];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 1.0;
    final now = DateTime.now();

    final product = ProductItem(
      name: name,
      amount: amount,
      unit: _selectedUnit,
      category: _selectedCategory,
      addedDate: now,
      expiryDate: now.add(Duration(days: _shelfDays)),
      emoji: _selectedEmoji,
    );

    ref.read(fridgeProvider.notifier).addProduct(product);
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Добавить продукт', style: AppTypography.titleLarge),
            const SizedBox(height: 16),

            // Product Name with Auto Emoji & Category Matching
            TextField(
              controller: _nameController,
              autofocus: true,
              onChanged: (val) {
                final autoEmoji = ProductHelper.getEmojiForName(val);
                final autoCat = ProductHelper.getCategoryForName(val);
                setState(() {
                  if (autoEmoji != '🥑' || val.trim().toLowerCase().contains('авокадо')) {
                    _selectedEmoji = autoEmoji;
                  }
                  _selectedCategory = autoCat;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Название (например: Картошка, Сыр)',
              ),
            ),
            const SizedBox(height: 12),

            // Amount and Unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: 'Количество'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedUnit,
                        isExpanded: true,
                        items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (val) => setState(() => _selectedUnit = val ?? 'шт'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val ?? _categories[0]),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Shelf life slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Срок хранения', style: AppTypography.titleSmall),
                Text('$_shelfDays дней', style: AppTypography.labelMedium),
              ],
            ),
            Slider(
              value: _shelfDays.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.surfaceMuted,
              onChanged: (val) => setState(() => _shelfDays = val.round()),
            ),

            // Emoji Picker Row
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _emojis.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final e = _emojis[index];
                  final isSel = _selectedEmoji == e;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = e),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primary : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(e, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
