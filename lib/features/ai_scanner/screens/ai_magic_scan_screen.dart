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
  int _selectedMode = 1; // Default: 1 = Полка холодильника, 0 = Чек, 2 = Текст
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
        maxWidth: 1800,
        maxHeight: 1800,
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
                          value: ['шт', 'г', 'кг', 'мл', 'л', 'уп'].contains(unit) ? unit : 'шт',
                          underline: const SizedBox(),
                          items: ['шт', 'г', 'кг', 'мл', 'л', 'уп'].map((u) {
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
                  _buildTabButton(1, 'Полка холодильника'),
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
    final isFridge = _selectedMode == 1;

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
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFridge ? Icons.kitchen_outlined : Icons.receipt_long_outlined,
                        size: 38,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isFridge ? 'Сфотографируйте холодильник' : 'Сфотографируйте чек',
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        isFridge
                            ? 'ИИ выделит каждый найденный продукт рамкой прямо на фото'
                            : 'Распознает все позиции, цены и сроки хранения',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, size: 20),
                      label: const Text('Сделать снимок'),
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

  /// Full-Screen AR Visual Object Detection View directly over the captured photo
  Widget _buildFullScreenVisualScanView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full Screen Captured Image with Object Detection Bounding Boxes
          LayoutBuilder(
            builder: (context, constraints) {
              final boxW = constraints.maxWidth;
              final boxH = constraints.maxHeight;

              final imgW = _decodedImage?.width.toDouble() ?? boxW;
              final imgH = _decodedImage?.height.toDouble() ?? boxH;

              final imgAspect = (imgW > 0 && imgH > 0) ? imgW / imgH : boxW / boxH;
              final boxAspect = boxW / boxH;

              double renderW, renderH;
              double offsetX = 0;
              double offsetY = 0;

              if (boxAspect > imgAspect) {
                renderH = boxH;
                renderW = boxH * imgAspect;
                offsetX = (boxW - renderW) / 2;
              } else {
                renderW = boxW;
                renderH = boxW / imgAspect;
                offsetY = (boxH - renderH) / 2;
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Captured Photo
                  Center(
                    child: SizedBox(
                      width: renderW,
                      height: renderH,
                      child: Image.memory(_pickedImageBytes!, fit: BoxFit.fill),
                    ),
                  ),

                  // Scanning Beam Animation while processing
                  if (_isProcessing) const _ScannerBeam(),

                  // Recognized Object Bounding Boxes & Tags
                  if (!_isProcessing && _hasScanned)
                    ..._buildVisualBoundingBoxes(
                      renderW: renderW,
                      renderH: renderH,
                      offsetX: offsetX,
                      offsetY: offsetY,
                    ),
                ],
              );
            },
          ),

          // Top Header (Back button + Status Pill)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Frosted Close Button
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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

                // Frosted Scanning/Result Status Pill
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isProcessing) ...[
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'ИИ распознает объекты...',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ] else if (_recognizedItems.isNotEmpty) ...[
                            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Найдено: ${_recognizedItems.length} поз.',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ] else ...[
                            const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'Продукты не обнаружены',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
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
            bottom: MediaQuery.of(context).padding.bottom + 16,
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
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _pickImage(ImageSource.camera);
                            },
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white24),
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

  List<Widget> _buildVisualBoundingBoxes({
    required double renderW,
    required double renderH,
    required double offsetX,
    required double offsetY,
  }) {
    final List<Widget> widgets = [];

    for (int i = 0; i < _recognizedItems.length; i++) {
      final item = _recognizedItems[i];
      final box = item.box2d;

      double top, left, width, height;

      if (box != null && box.length == 4) {
        final ymin = box[0];
        final xmin = box[1];
        final ymax = box[2];
        final xmax = box[3];

        top = offsetY + (ymin / 1000.0) * renderH;
        left = offsetX + (xmin / 1000.0) * renderW;
        width = ((xmax - xmin).abs() / 1000.0) * renderW;
        height = ((ymax - ymin).abs() / 1000.0) * renderH;

        // Ensure minimum reasonable dimensions for interaction
        if (width < 60) width = 60;
        if (height < 60) height = 60;
      } else {
        // Fallback staggered placement if no box2d returned
        final row = i % 3;
        final col = (i ~/ 3);
        width = 120;
        height = 100;
        left = offsetX + 20 + (row * 110);
        top = offsetY + 80 + (col * 120);
      }

      widgets.add(
        Positioned(
          top: top.clamp(offsetY, offsetY + renderH - 60),
          left: left.clamp(offsetX, offsetX + renderW - 80),
          child: GestureDetector(
            onTap: () => _showEditItemSheet(item, i),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Interactive Frosted Product Capsule Badge
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white70, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.emoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.amount.toStringAsFixed(item.amount % 1 == 0 ? 0 : 1)} ${item.unit}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, size: 10, color: Colors.white60),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),

                // Corner-Accented Bounding Box Frame
                Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widgets;
  }
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
