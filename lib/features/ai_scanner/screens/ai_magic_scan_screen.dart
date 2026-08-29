import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/gemini_ai_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/product_helper.dart';
import '../../fridge/models/product_item.dart';
import '../../fridge/providers/fridge_provider.dart';
import '../../premium/widgets/premium_gate.dart';

class AiMagicScanScreen extends ConsumerStatefulWidget {
  const AiMagicScanScreen({super.key});

  @override
  ConsumerState<AiMagicScanScreen> createState() => _AiMagicScanScreenState();
}

class _AiMagicScanScreenState extends ConsumerState<AiMagicScanScreen> {
  int _selectedMode = 1; // 0 = Чек, 1 = Продукты, 2 = Текст списка
  int _viewMode = 0; // 0 = Фото с AR-точками, 1 = Список
  bool _isProcessing = false;
  bool _hasScanned = false;
  String? _errorMessage;
  Uint8List? _pickedImageBytes;
  ui.Image? _decodedImage;
  final TextEditingController _textInputController = TextEditingController();
  List<ProductItem> _recognizedItems = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final hasPremium = await PremiumGate.check(
      context,
      ref,
      featureName: 'Умный ИИ-сканер',
    );
    if (!hasPremium) return;

    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1440,
        maxHeight: 2560, // 9:16 vertical high resolution
        imageQuality: 88,
      );

      if (photo == null) return;

      final bytes = await photo.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();

      setState(() {
        _pickedImageBytes = bytes;
        _decodedImage = frameInfo.image;
        _isProcessing = true;
        _hasScanned = false;
        _viewMode = 0;
        _errorMessage = null;
        _recognizedItems = [];
      });

      final result = await GeminiAIService.scanReceiptOrFridge(
        imageBytes: bytes,
        mimeType: 'image/jpeg',
        isReceipt: _selectedMode == 0,
      );

      setState(() {
        _isProcessing = false;
        _hasScanned = true;
        _recognizedItems = result;
      });

      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _hasScanned = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Ошибка сканирования'),
            backgroundColor: AppColors.statusUrgent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _processText() async {
    final hasPremium = await PremiumGate.check(
      context,
      ref,
      featureName: 'Распознавание списка продуктов',
    );
    if (!hasPremium) return;

    final text = _textInputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _hasScanned = false;
      _errorMessage = null;
      _recognizedItems = [];
    });

    try {
      final result = await GeminiAIService.scanReceiptOrFridge(
        rawOcrText: text,
        isReceipt: _selectedMode == 0,
      );

      setState(() {
        _isProcessing = false;
        _hasScanned = true;
        _recognizedItems = result;
      });

      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _hasScanned = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _saveAllToFridge() {
    if (_recognizedItems.isEmpty) return;

    for (final item in _recognizedItems) {
      ref.read(fridgeProvider.notifier).addProduct(item);
    }

    HapticFeedback.heavyImpact();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Добавлено ${_recognizedItems.length} продуктов в Холодильник'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeItem(int index) {
    if (index < 0 || index >= _recognizedItems.length) return;
    final item = _recognizedItems[index];
    setState(() {
      _recognizedItems.removeAt(index);
    });

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} удален'),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Отменить',
          textColor: Colors.white,
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() {
              if (index <= _recognizedItems.length) {
                _recognizedItems.insert(index, item);
              } else {
                _recognizedItems.add(item);
              }
            });
          },
        ),
      ),
    );
  }

  void _showEmojiPicker(BuildContext context, String currentEmoji, Function(String) onSelected) {
    HapticFeedback.selectionClick();
    const foodEmojis = [
      '🥑', '🥛', '🧀', '🍅', '🥚', '🍗', '🥩', '🐟', '🍞', '🥒',
      '🥕', '🍎', '🍌', '🍓', '🍇', '🍋', '🧄', '🧅', '🌽', '🥬',
      '🥦', '🍄', '🍝', '🍚', '🥫', '🫒', '🧈', '🍯', '🍫', '🍦',
      '🍰', '🧃', '☕', '🍵', '🥤', '🍱', '🥗', '🍲', '🍕', '🥪',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Выберите иконку продукта', style: AppTypography.titleSmall),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: foodEmojis.map((emoji) {
                  final isSelected = emoji == currentEmoji;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelected(emoji);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: AppColors.primary, width: 1.5) : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditItemSheet(ProductItem item, int index, {bool isNew = false}) {
    HapticFeedback.mediumImpact();
    final nameCtrl = TextEditingController(text: item.name);
    double amount = item.amount;
    String unit = item.unit;
    String category = item.category;
    int shelfLife = item.daysUntilExpiry > 0 ? item.daysUntilExpiry : 4;
    String emoji = item.emoji;

    final allCategories = [
      'Овощи и зелень',
      'Фрукты и ягоды',
      'Молочные продукты',
      'Мясо и птица',
      'Рыба и морепродукты',
      'Бакалея',
      'Напитки',
      'Готовая еда',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Smoothly place selected category at the first position
            final orderedCategories = [
              category,
              ...allCategories.where((c) => c != category),
            ];

            return Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
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
                    children: [
                      // Clickable Emoji Picker Avatar
                      GestureDetector(
                        onTap: () {
                          _showEmojiPicker(context, emoji, (newEmoji) {
                            setSheetState(() => emoji = newEmoji);
                          });
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          alignment: Alignment.center,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 26)),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit, size: 8, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isNew ? 'Добавить продукт' : 'Редактировать продукт',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (!isNew)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.statusUrgent),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _removeItem(index);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Name Field with Auto Emoji & Category Matching
                  TextField(
                    controller: nameCtrl,
                    autofocus: isNew,
                    onChanged: (val) {
                      final autoEmoji = ProductHelper.getEmojiForName(val);
                      final autoCat = ProductHelper.getCategoryForName(val);
                      setSheetState(() {
                        if (autoEmoji != '🥑' || val.trim().toLowerCase().contains('авокадо')) {
                          emoji = autoEmoji;
                        }
                        if (isNew) {
                          category = autoCat;
                        }
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Название продукта',
                      hintText: 'Например: Картошка, Сыр, Молоко',
                      prefixIcon: Icon(Icons.edit_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Amount and Unit Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_rounded, size: 18),
                                onPressed: () {
                                  if (amount > 0.5) {
                                    setSheetState(() => amount -= 1);
                                  }
                                },
                              ),
                              Text(
                                '${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 1)} $unit',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_rounded, size: 18),
                                onPressed: () => setSheetState(() => amount += 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Unit Selector Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: DropdownButton<String>(
                          value: ['шт', 'г', 'кг', 'мл', 'л', 'уп', 'пачка', 'банка', 'блюдо'].contains(unit) ? unit : 'шт',
                          underline: const SizedBox(),
                          items: ['шт', 'г', 'кг', 'мл', 'л', 'уп', 'пачка', 'банка', 'блюдо'].map((u) {
                            return DropdownMenuItem(value: u, child: Text(u));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setSheetState(() => unit = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Shelf Life Slider
                  Text('Срок хранения: $shelfLife дн.', style: AppTypography.bodySmall),
                  Slider(
                    value: shelfLife.toDouble().clamp(1.0, 30.0),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    activeColor: AppColors.primary,
                    label: '$shelfLife дн.',
                    onChanged: (v) => setSheetState(() => shelfLife = v.round()),
                  ),
                  const SizedBox(height: 10),

                  // Category selector: Selected item is ALWAYS first and WITHOUT checkmark icon
                  AnimatedSize(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutCubic,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        key: ValueKey('cats_$category'),
                        children: orderedCategories.map((cat) {
                          final isSel = category == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              showCheckmark: false, // NO CHECKMARK ICON
                              label: Text(cat),
                              selected: isSel,
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.surfaceMuted,
                              labelStyle: TextStyle(
                                color: isSel ? AppColors.primaryForeground : AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              ),
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setSheetState(() => category = cat);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final finalName = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : (isNew ? 'Продукт' : item.name);
                        final updated = item.copyWith(
                          name: finalName,
                          amount: amount,
                          unit: unit,
                          category: category,
                          emoji: emoji,
                          expiryDate: DateTime.now().add(Duration(days: shelfLife)),
                        );

                        setState(() {
                          if (isNew) {
                            _recognizedItems.add(updated);
                          } else {
                            _recognizedItems[index] = updated;
                          }
                        });

                        Navigator.pop(ctx);
                        HapticFeedback.lightImpact();
                      },
                      child: Text(isNew ? 'Добавить продукт' : 'Сохранить изменения'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handlePhotoTap(TapUpDetails details, double renderW, double renderH, double offsetX, double offsetY) {
    if (_isProcessing || !_hasScanned || _viewMode != 0) return;

    final localPos = details.localPosition;
    if (localPos.dx < offsetX || localPos.dx > offsetX + renderW ||
        localPos.dy < offsetY || localPos.dy > offsetY + renderH) {
      return;
    }

    final relX = (localPos.dx - offsetX) / renderW * 1000.0;
    final relY = (localPos.dy - offsetY) / renderH * 1000.0;

    final newItem = ProductItem(
      name: '',
      amount: 1.0,
      unit: 'шт',
      category: 'Овощи и зелень',
      addedDate: DateTime.now(),
      expiryDate: DateTime.now().add(const Duration(days: 4)),
      emoji: '🥑',
      box2d: [relY - 15, relX - 15, relY + 15, relX + 15],
    );

    _showEditItemSheet(newItem, -1, isNew: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_pickedImageBytes != null) {
      return _buildFullScreenVisualScanView();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Сканер продуктов', style: AppTypography.displayMedium),
      ),
      body: Column(
        children: [
          // Mode Selector (4 clean modes: Чек, Покупки, Полка, Текст)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildTabButton(0, 'Чек'),
                  _buildTabButton(1, 'Покупки'),
                  _buildTabButton(2, 'Полка'),
                  _buildTabButton(3, 'Текст'),
                ],
              ),
            ),
          ),

          Expanded(
            child: _selectedMode == 3 ? _buildTextModeView() : _buildInitialCameraView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _selectedMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedMode = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildInitialCameraView() {
    final isProducts = _selectedMode == 1;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _pickImage(ImageSource.camera),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.cardBorder, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isProducts ? Icons.lunch_dining_outlined : Icons.receipt_long_outlined,
                        size: 38,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isProducts ? 'Сфотографируйте продукты' : 'Сфотографируйте чек',
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        isProducts
                            ? 'ИИ расставит метки с линиями на прозрачном блюре. Можно нажать на фото для добавления.'
                            : 'Распознает все позиции, цены и сроки хранения',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, size: 20),
                      label: const Text('Сделать снимок (9:16)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined, size: 20),
              label: const Text('Выбрать из галереи'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.cardBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextModeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Вставьте текст списка или рецепта:',
            style: AppTypography.titleSmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textInputController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Например:\n- Молоко 1л\n- Томаты 500г\n- Сыр 200г',
              hintStyle: TextStyle(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processText,
              child: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Распознать продукты'),
            ),
          ),
          if (_hasScanned && _recognizedItems.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Распознанные продукты (${_recognizedItems.length}):', style: AppTypography.titleSmall),
            const SizedBox(height: 12),
            ...List.generate(_recognizedItems.length, (idx) {
              final item = _recognizedItems[idx];
              return ListTile(
                leading: Text(item.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(item.name),
                subtitle: Text('${item.amount} ${item.unit} • ${item.category}'),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => _removeItem(idx),
                ),
              );
            }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saveAllToFridge,
                icon: const Icon(Icons.check_rounded),
                label: Text('Добавить в Холодильник (${_recognizedItems.length})'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Full-Screen AR Visual Object Detection View directly over the captured 9:16 photo
  Widget _buildFullScreenVisualScanView() {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full Screen Photo View with tap detection
          LayoutBuilder(
            builder: (context, constraints) {
              final screenW = constraints.maxWidth;
              final screenH = constraints.maxHeight;

              final imgW = _decodedImage?.width.toDouble() ?? screenW;
              final imgH = _decodedImage?.height.toDouble() ?? screenH;

              final imgAspect = (imgW > 0 && imgH > 0) ? imgW / imgH : screenW / screenH;
              final boxAspect = screenW / screenH;

              double renderW, renderH;
              double offsetX = 0;
              double offsetY = 0;

              if (_viewMode == 1) {
                // In list view mode: upscale smoothly to fill screen for deep background blur
                renderW = screenW;
                renderH = screenH;
              } else {
                if (boxAspect > imgAspect) {
                  renderH = screenH;
                  renderW = screenH * imgAspect;
                  offsetX = (screenW - renderW) / 2;
                } else {
                  renderW = screenW;
                  renderH = screenW / imgAspect;
                  offsetY = (screenH - renderH) / 2;
                }
              }

              // Precalculate Pin Points and Non-Overlapping Badge Positions with exact measurement
              final layout = _calculateBadgeLayout(
                renderW: renderW,
                renderH: renderH,
                offsetX: offsetX,
                offsetY: offsetY,
                screenW: screenW,
                screenH: screenH,
                topPadding: topPadding,
                bottomPadding: bottomPadding,
              );

              return GestureDetector(
                onTapUp: (details) => _handlePhotoTap(details, renderW, renderH, offsetX, offsetY),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Photo Background (scaled to cover when in list mode)
                    Positioned.fill(
                      child: Image.memory(
                        _pickedImageBytes!,
                        fit: _viewMode == 1 ? BoxFit.cover : BoxFit.contain,
                      ),
                    ),

                    // Dynamic Engaging Sci-Fi Scanner Animation without central circle
                    if (_isProcessing) const _EngagingScannerBeam(),

                    // If in Photo Mode and not processing: Render connecting lines and badges
                    if (!_isProcessing && _hasScanned && _viewMode == 0) ...[
                      // Continuous Connecting Lines ("Палочки")
                      CustomPaint(
                        size: Size(screenW, screenH),
                        painter: _ConnectingLinesPainter(layout: layout),
                      ),

                      // Center Dot Pins on Products
                      ...layout.map((item) => _buildCenterDot(item)),

                      // Frosted Glass Badges with High Transparency, No quantity, No pencil, No outline
                      ...layout.map((item) => _buildFrostedBadge(item)),
                    ],

                    // If in List Mode: Render scrollable frosted list over the full blurred photo
                    if (!_isProcessing && _hasScanned && _viewMode == 1)
                      _buildFrostedListView(topPadding, bottomPadding),
                  ],
                ),
              );
            },
          ),

          // Top Header: Back Button + Mode Switcher Tabs (📸 Фото / 📋 Список)
          Positioned(
            top: topPadding + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Frosted Back Button
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _pickedImageBytes = null;
                          _decodedImage = null;
                          _hasScanned = false;
                          _recognizedItems = [];
                        });
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.32),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),

                // Top Segmented Switcher: [ 📸 Фото | 📋 Список (N) ]
                if (!_isProcessing && _hasScanned)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.32),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildViewModePill(0, 'Фото', Icons.camera_alt_outlined),
                            _buildViewModePill(1, 'Список (${_recognizedItems.length})', Icons.list_alt_rounded),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (_isProcessing)
                  // Engaging Dynamic Scanning Status Pill (warm, funny phrases)
                  const Flexible(
                    child: Center(
                      child: _ScanningStatusPill(),
                    ),
                  ),

                const SizedBox(width: 44), // balance spacing
              ],
            ),
          ),

          // Bottom Action Bar: Retake & Add to Fridge
          Positioned(
            bottom: bottomPadding + 16,
            left: 16,
            right: 16,
            child: _isProcessing
                ? const SizedBox()
                : Row(
                    children: [
                      // Retake Button
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _pickImage(ImageSource.camera);
                            },
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.32),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Переснять',
                                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Add to Fridge Main Action
                      if (_recognizedItems.isNotEmpty)
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                elevation: 8,
                              ),
                              onPressed: _saveAllToFridge,
                              icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                              label: Text(
                                'В Холодильник (${_recognizedItems.length})',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModePill(int mode, String label, IconData icon) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _viewMode = mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.28) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.white70),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Center Pin Dot placed exactly on the recognized food item
  Widget _buildCenterDot(_BadgeLayoutItem item) {
    return Positioned(
      left: item.dotX - 9,
      top: item.dotY - 9,
      child: GestureDetector(
        onTap: () => _showEditItemSheet(item.product, item.index),
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Frosted Glass Badge with HIGH TRANSPARENCY, NO QUANTITY, NO PENCIL ICON, NO OUTLINE
  Widget _buildFrostedBadge(_BadgeLayoutItem item) {
    return Positioned(
      left: item.badgeX,
      top: item.badgeY,
      child: GestureDetector(
        onTap: () => _showEditItemSheet(item.product, item.index),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28), // Deep transparent frosted blur without outline
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.product.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Frosted List View for review when switching to the "Список" tab
  Widget _buildFrostedListView(double topPadding, double bottomPadding) {
    return Positioned.fill(
      top: 0,
      bottom: 0,
      left: 0,
      right: 0,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          color: Colors.black.withValues(alpha: 0.68),
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(16, topPadding + 64, 16, bottomPadding + 84),
            itemCount: _recognizedItems.length,
            itemBuilder: (context, index) {
              final item = _recognizedItems[index];
              return Dismissible(
                key: Key('scan_${item.name}_$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: AppColors.statusUrgent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                ),
                onDismissed: (_) => _removeItem(index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(item.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.amount.toStringAsFixed(item.amount % 1 == 0 ? 0 : 1)} ${item.unit} • ${item.category} • ${item.daysUntilExpiry} дн.',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                        onPressed: () => _showEditItemSheet(item, index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                        onPressed: () => _removeItem(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Calculates center pins and non-overlapping badge positions with smart diagonal & directional adaptation
  List<_BadgeLayoutItem> _calculateBadgeLayout({
    required double renderW,
    required double renderH,
    required double offsetX,
    required double offsetY,
    required double screenW,
    required double screenH,
    required double topPadding,
    required double bottomPadding,
  }) {
    final List<_BadgeLayoutItem> items = [];
    const badgeH = 28.0;
    final minTop = topPadding + 64.0;
    final maxBottom = screenH - bottomPadding - 100.0;

    // Step 1: Pre-calculate all dot coordinates and exact badge sizes
    final List<_InitialItemData> initialData = [];
    for (int i = 0; i < _recognizedItems.length; i++) {
      final product = _recognizedItems[i];
      final box = product.box2d;

      double dotX, dotY;

      if (box != null && box.length == 4) {
        final ymin = box[0];
        final xmin = box[1];
        final ymax = box[2];
        final xmax = box[3];

        final centerY = (ymin + ymax) / 2.0;
        final centerX = (xmin + xmax) / 2.0;

        dotY = offsetY + (centerY / 1000.0) * renderH;
        dotX = offsetX + (centerX / 1000.0) * renderW;
      } else {
        final row = i % 3;
        final col = (i ~/ 3);
        dotX = offsetX + 60 + (row * ((renderW - 120) / 2));
        dotY = offsetY + 120 + (col * 150);
      }

      dotX = dotX.clamp(offsetX + 14.0, offsetX + renderW - 14.0);
      dotY = dotY.clamp(offsetY + 14.0, offsetY + renderH - 14.0);

      // Measure exact badge width
      final tp = TextPainter(
        text: TextSpan(
          text: '${product.emoji}  ${product.name}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();

      final exactW = tp.width + 24.0;
      initialData.add(_InitialItemData(index: i, product: product, dotX: dotX, dotY: dotY, exactW: exactW));
    }

    // Step 2: For each item, test smart candidate positions (Diagonal Top, Side, Above, Below)
    for (int i = 0; i < initialData.length; i++) {
      final cur = initialData[i];
      final isOnLeftSide = cur.dotX <= (screenW * 0.5);

      // Generate smart directional candidates around this dot
      final List<_CandidatePlacement> candidates = [];

      if (isOnLeftSide) {
        // Preferred order for left half:
        candidates.add(_CandidatePlacement(cur.dotX + 32.0, cur.dotY - 42.0)); // Diagonal Top-Right
        candidates.add(_CandidatePlacement(cur.dotX + 38.0, cur.dotY - 14.0)); // Side Right
        candidates.add(_CandidatePlacement(cur.dotX + 32.0, cur.dotY + 32.0)); // Diagonal Bottom-Right
        candidates.add(_CandidatePlacement(cur.dotX - (cur.exactW * 0.3), cur.dotY - 48.0)); // Straight Above
        candidates.add(_CandidatePlacement(cur.dotX - cur.exactW - 28.0, cur.dotY - 42.0)); // Diagonal Top-Left
        candidates.add(_CandidatePlacement(cur.dotX - cur.exactW - 32.0, cur.dotY - 14.0)); // Side Left
        candidates.add(_CandidatePlacement(cur.dotX - (cur.exactW * 0.3), cur.dotY + 36.0)); // Straight Below
      } else {
        // Preferred order for right half:
        candidates.add(_CandidatePlacement(cur.dotX - cur.exactW - 32.0, cur.dotY - 42.0)); // Diagonal Top-Left
        candidates.add(_CandidatePlacement(cur.dotX - cur.exactW - 38.0, cur.dotY - 14.0)); // Side Left
        candidates.add(_CandidatePlacement(cur.dotX - cur.exactW - 32.0, cur.dotY + 32.0)); // Diagonal Bottom-Left
        candidates.add(_CandidatePlacement(cur.dotX - (cur.exactW * 0.7), cur.dotY - 48.0)); // Straight Above
        candidates.add(_CandidatePlacement(cur.dotX + 28.0, cur.dotY - 42.0)); // Diagonal Top-Right
        candidates.add(_CandidatePlacement(cur.dotX + 32.0, cur.dotY - 14.0)); // Side Right
        candidates.add(_CandidatePlacement(cur.dotX - (cur.exactW * 0.7), cur.dotY + 36.0)); // Straight Below
      }

      // Score each candidate to find the cleanest, non-overlapping spot
      _CandidatePlacement bestCandidate = candidates.first;
      double minPenalty = double.infinity;

      for (final cand in candidates) {
        double penalty = 0.0;
        final clampedX = cand.x.clamp(12.0, screenW - cur.exactW - 12.0);
        final clampedY = cand.y.clamp(minTop, maxBottom);

        // Penalty for clamping (off-screen)
        penalty += (cand.x - clampedX).abs() * 20.0;
        penalty += (cand.y - clampedY).abs() * 20.0;

        final candRect = Rect.fromLTWH(clampedX, clampedY, cur.exactW, badgeH);

        // Penalty for overlapping already placed badges
        for (final placed in items) {
          final placedRect = Rect.fromLTWH(placed.badgeX, placed.badgeY, placed.exactBadgeWidth, badgeH);
          if (candRect.inflate(6.0).overlaps(placedRect)) {
            penalty += 10000.0;
          }
        }

        // Penalty for covering ANY product dot
        for (final anyDot in initialData) {
          if (candRect.inflate(12.0).contains(Offset(anyDot.dotX, anyDot.dotY))) {
            penalty += 20000.0;
          }
        }

        // Preference for shorter distance to own dot
        final dist = (Offset(clampedX + cur.exactW / 2, clampedY + badgeH / 2) - Offset(cur.dotX, cur.dotY)).distance;
        penalty += dist * 1.2;

        if (penalty < minPenalty) {
          minPenalty = penalty;
          bestCandidate = _CandidatePlacement(clampedX, clampedY);
        }
      }

      items.add(
        _BadgeLayoutItem(
          index: cur.index,
          product: cur.product,
          dotX: cur.dotX,
          dotY: cur.dotY,
          badgeX: bestCandidate.x.clamp(12.0, screenW - cur.exactW - 12.0),
          badgeY: bestCandidate.y.clamp(minTop, maxBottom),
          exactBadgeWidth: cur.exactW,
        ),
      );
    }

    return items;
  }
}

class _InitialItemData {
  final int index;
  final ProductItem product;
  final double dotX;
  final double dotY;
  final double exactW;

  _InitialItemData({
    required this.index,
    required this.product,
    required this.dotX,
    required this.dotY,
    required this.exactW,
  });
}

class _CandidatePlacement {
  final double x;
  final double y;

  _CandidatePlacement(this.x, this.y);
}

class _BadgeLayoutItem {
  final int index;
  final ProductItem product;
  final double dotX;
  final double dotY;
  double badgeX;
  double badgeY;
  final double exactBadgeWidth;

  _BadgeLayoutItem({
    required this.index,
    required this.product,
    required this.dotX,
    required this.dotY,
    required this.badgeX,
    required this.badgeY,
    required this.exactBadgeWidth,
  });
}

/// CustomPainter that draws uninterrupted continuous smooth leader lines ("палочки") from center dots to badges
class _ConnectingLinesPainter extends CustomPainter {
  final List<_BadgeLayoutItem> layout;

  _ConnectingLinesPainter({required this.layout});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    final dotHaloPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    for (final item in layout) {
      canvas.drawCircle(Offset(item.dotX, item.dotY), 7, dotHaloPaint);

      const badgeH = 28.0;
      final badgeLeft = item.badgeX;
      final badgeRight = item.badgeX + item.exactBadgeWidth;
      final badgeTop = item.badgeY;
      final badgeBottom = item.badgeY + badgeH;

      double targetX, targetY;

      // Calculate the closest natural docking point on the badge boundary
      if (item.dotX < badgeLeft) {
        targetX = badgeLeft;
        targetY = item.dotY.clamp(badgeTop + 6.0, badgeBottom - 6.0);
      } else if (item.dotX > badgeRight) {
        targetX = badgeRight;
        targetY = item.dotY.clamp(badgeTop + 6.0, badgeBottom - 6.0);
      } else if (item.dotY < badgeTop) {
        targetX = item.dotX.clamp(badgeLeft + 6.0, badgeRight - 6.0);
        targetY = badgeTop;
      } else {
        targetX = item.dotX.clamp(badgeLeft + 6.0, badgeRight - 6.0);
        targetY = badgeBottom;
      }

      final path = Path();
      path.moveTo(item.dotX, item.dotY);

      // Smooth, natural continuous curve directly to the badge edge
      final midX = (item.dotX + targetX) / 2;
      path.cubicTo(
        midX, item.dotY,
        midX, targetY,
        targetX, targetY,
      );

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectingLinesPainter oldDelegate) => true;
}

/// Dynamic, engaging scanning status pill with warm, funny, delightful phrases (1.8s interval)
class _ScanningStatusPill extends StatefulWidget {
  const _ScanningStatusPill();

  @override
  State<_ScanningStatusPill> createState() => _ScanningStatusPillState();
}

class _ScanningStatusPillState extends State<_ScanningStatusPill> {
  int _phraseIdx = 0;
  Timer? _timer;

  final _phrases = [
    'Ищу сыр... Он точно где-то здесь 🧀',
    'Вглядываюсь в глубины полок... 👀',
    'Что же в той закрытой миске? 🍲',
    'Договариваюсь с йогуртом не портиться 🥛',
    'Считаю запасы на нижней полке 🥟',
    'Определяю, чей это контейнер... 🕵️‍♂️',
    'Изучаю состав кулинарных шедевров 👨‍🍳',
    'Почти готово, навожу красоту! ✨',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (mounted) {
        setState(() {
          _phraseIdx = (_phraseIdx + 1) % _phrases.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _phrases[_phraseIdx],
                  key: ValueKey(_phrases[_phraseIdx]),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Engaging Sci-Fi Scanner Animation with moving laser line (no center circle, smooth speed)
class _EngagingScannerBeam extends StatefulWidget {
  const _EngagingScannerBeam();

  @override
  State<_EngagingScannerBeam> createState() => _EngagingScannerBeamState();
}

class _EngagingScannerBeamState extends State<_EngagingScannerBeam> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800), // Smooth, cinematic 2.8s sweep
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        return Align(
          alignment: Alignment(0, (progress * 2) - 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.12),
                    ],
                  ),
                ),
              ),
              Container(
                height: 2.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.95),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.75),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
