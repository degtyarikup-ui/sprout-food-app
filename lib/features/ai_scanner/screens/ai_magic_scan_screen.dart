import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/gemini_ai_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../fridge/models/product_item.dart';
import '../../fridge/providers/fridge_provider.dart';

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

  void _showEditItemSheet(ProductItem item, int index) {
    HapticFeedback.mediumImpact();
    final nameCtrl = TextEditingController(text: item.name);
    double amount = item.amount;
    String unit = item.unit;
    String category = item.category;
    int shelfLife = item.daysUntilExpiry > 0 ? item.daysUntilExpiry : 4;
    String emoji = item.emoji;

    final categories = [
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
                      Text(emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Редактировать продукт',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
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

                  // Name Field
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Название продукта',
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

                  // Category selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isSel = category == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSel,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSel ? AppColors.primaryForeground : AppColors.textPrimary,
                              fontSize: 12,
                            ),
                            onSelected: (_) => setSheetState(() => category = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final updated = item.copyWith(
                          name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : item.name,
                          amount: amount,
                          unit: unit,
                          category: category,
                          expiryDate: DateTime.now().add(Duration(days: shelfLife)),
                        );
                        setState(() {
                          _recognizedItems[index] = updated;
                        });
                        Navigator.pop(ctx);
                        HapticFeedback.lightImpact();
                      },
                      child: const Text('Сохранить изменения'),
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
          // Mode Selector
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
                  _buildTabButton(0, 'Кассовый чек'),
                  _buildTabButton(1, 'Продукты'),
                  _buildTabButton(2, 'Текст списка'),
                ],
              ),
            ),
          ),

          Expanded(
            child: _selectedMode == 2 ? _buildTextModeView() : _buildInitialCameraView(),
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
                            ? 'ИИ поставит точку в центре каждого продукта с линией к блюр-плашке'
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
          // Full Screen Photo View (when in photo mode or during scan)
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

              if (boxAspect > imgAspect) {
                renderH = screenH;
                renderW = screenH * imgAspect;
                offsetX = (screenW - renderW) / 2;
              } else {
                renderW = screenW;
                renderH = screenW / imgAspect;
                offsetY = (screenH - renderH) / 2;
              }

              // Precalculate Pin Points and Non-Overlapping Badge Positions
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

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Photo Background
                  Center(
                    child: SizedBox(
                      width: renderW,
                      height: renderH,
                      child: Image.memory(_pickedImageBytes!, fit: BoxFit.fill),
                    ),
                  ),

                  // Scanning Beam Animation while processing
                  if (_isProcessing) const _ScannerBeam(),

                  // If in Photo Mode and not processing: Render connecting lines and badges
                  if (!_isProcessing && _hasScanned && _viewMode == 0) ...[
                    // Custom Painter for Connecting Lines ("Палочки")
                    CustomPaint(
                      size: Size(screenW, screenH),
                      painter: _ConnectingLinesPainter(layout: layout),
                    ),

                    // Center Dot Pins on Products
                    ...layout.map((item) => _buildCenterDot(item)),

                    // Frosted Glass Badges without Outlines
                    ...layout.map((item) => _buildFrostedBadge(item)),
                  ],

                  // If in List Mode: Render scrollable frosted list over photo
                  if (!_isProcessing && _hasScanned && _viewMode == 1)
                    _buildFrostedListView(topPadding, bottomPadding),
                ],
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
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
                          color: Colors.black.withValues(alpha: 0.45),
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
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
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
                  // Processing status pill
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'ИИ ставит точки...',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
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
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _pickImage(ImageSource.camera);
                            },
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
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
          color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.transparent,
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
            color: Colors.white.withValues(alpha: 0.3),
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
                  color: Colors.black45,
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

  /// Frosted Glass Badge with ZERO border outline and soft shadow
  Widget _buildFrostedBadge(_BadgeLayoutItem item) {
    return Positioned(
      left: item.badgeX,
      top: item.badgeY,
      child: GestureDetector(
        onTap: () => _showEditItemSheet(item.product, item.index),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.48), // Translucent frosted blur without outline
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
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
                          color: Colors.black54,
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.product.amount.toStringAsFixed(item.product.amount % 1 == 0 ? 0 : 1)} ${item.product.unit}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit, size: 10, color: Colors.white54),
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
      top: topPadding + 64,
      bottom: bottomPadding + 80,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: Colors.black.withValues(alpha: 0.72),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      ),
    );
  }

  /// Calculates center pins and non-overlapping badge positions with relaxation
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

    for (int i = 0; i < _recognizedItems.length; i++) {
      final product = _recognizedItems[i];
      final box = product.box2d;

      double dotX, dotY;

      if (box != null && box.length == 4) {
        final ymin = box[0];
        final xmin = box[1];
        final ymax = box[2];
        final xmax = box[3];

        // Center point of the detected object
        final centerY = (ymin + ymax) / 2.0;
        final centerX = (xmin + xmax) / 2.0;

        dotY = offsetY + (centerY / 1000.0) * renderH;
        dotX = offsetX + (centerX / 1000.0) * renderW;
      } else {
        // Fallback default grid distribution
        final row = i % 4;
        final col = (i ~/ 4);
        dotX = offsetX + 50 + (row * ((renderW - 100) / 3));
        dotY = offsetY + 120 + (col * 140);
      }

      // Initial desired badge placement (offset above / to the side of the dot)
      final isOnLeftSide = dotX < (screenW / 2);
      double badgeX = isOnLeftSide ? (dotX + 16) : (dotX - 160);
      double badgeY = dotY - 26;

      badgeX = badgeX.clamp(14.0, screenW - 180.0);
      badgeY = badgeY.clamp(topPadding + 64.0, screenH - bottomPadding - 100.0);

      items.add(
        _BadgeLayoutItem(
          index: i,
          product: product,
          dotX: dotX.clamp(offsetX + 8, offsetX + renderW - 8),
          dotY: dotY.clamp(offsetY + 8, offsetY + renderH - 8),
          badgeX: badgeX,
          badgeY: badgeY,
        ),
      );
    }

    // Anti-collision relaxation pass on badge vertical coordinates
    items.sort((a, b) => a.badgeY.compareTo(b.badgeY));
    const minVerticalGap = 36.0;

    for (int i = 1; i < items.length; i++) {
      final prev = items[i - 1];
      final curr = items[i];

      // Check if both badges are horizontally close (overlapping)
      if ((curr.badgeX - prev.badgeX).abs() < 130) {
        if (curr.badgeY < prev.badgeY + minVerticalGap) {
          curr.badgeY = prev.badgeY + minVerticalGap;
        }
      }
    }

    return items;
  }
}

class _BadgeLayoutItem {
  final int index;
  final ProductItem product;
  final double dotX;
  final double dotY;
  double badgeX;
  double badgeY;

  _BadgeLayoutItem({
    required this.index,
    required this.product,
    required this.dotX,
    required this.dotY,
    required this.badgeX,
    required this.badgeY,
  });
}

/// CustomPainter that draws elegant connecting leader lines ("палочки") from center dots to badges
class _ConnectingLinesPainter extends CustomPainter {
  final List<_BadgeLayoutItem> layout;

  _ConnectingLinesPainter({required this.layout});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final dotHaloPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    for (final item in layout) {
      // Connect dot to badge anchor
      final targetX = item.badgeX > item.dotX ? item.badgeX : item.badgeX + 140;
      final targetY = item.badgeY + 16;

      // Draw subtle halo behind the dot
      canvas.drawCircle(Offset(item.dotX, item.dotY), 6, dotHaloPaint);

      final path = Path();
      path.moveTo(item.dotX, item.dotY);

      // Smooth elbow bezier curve to badge
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

/// Scanning radar beam animation
class _ScannerBeam extends StatefulWidget {
  const _ScannerBeam();

  @override
  State<_ScannerBeam> createState() => _ScannerBeamState();
}

class _ScannerBeamState extends State<_ScannerBeam> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
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
        return Align(
          alignment: Alignment(0, (_controller.value * 2) - 1),
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.7),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
