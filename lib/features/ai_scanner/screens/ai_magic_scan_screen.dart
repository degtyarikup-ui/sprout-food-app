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
  int _selectedMode = 0; // 0 = Чек, 1 = Полка холодильника, 2 = Текст / Заметка
  bool _isProcessing = false;
  bool _hasScanned = false;
  String? _errorMessage;
  Uint8List? _pickedImageBytes;
  final TextEditingController _textInputController = TextEditingController();
  List<ProductItem> _recognizedItems = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    GeminiAIService.loadSavedApiKey();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (photo == null) return;

      final bytes = await photo.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
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
        content: Text('${item.name} удален из списка'),
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

  void _showApiKeyDialog() {
    final keyController = TextEditingController(text: GeminiAIService.apiKey);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
            Text('Настройка Gemini API', style: AppTypography.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Для реального сканирования нужен ключ из Google AI Studio (начинается на AIzaSy...): aistudio.google.com/app/apikey',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                hintText: 'AIzaSy...',
                prefixIcon: Icon(Icons.key_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final k = keyController.text.trim();
                  if (k.isNotEmpty) {
                    await GeminiAIService.setApiKey(k);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Сохранить ключ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Сканер продуктов'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.key_outlined, size: 20),
            tooltip: 'Ключ API',
            onPressed: _showApiKeyDialog,
          ),
          if (_recognizedItems.isNotEmpty)
            TextButton(
              onPressed: _saveAllToFridge,
              child: Text(
                'Сохранить (${_recognizedItems.length})',
                style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Mode Selector (Clean Monochromatic Pills)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildModeTab(0, 'Кассовый чек'),
                    _buildModeTab(1, 'Полка холодильника'),
                    _buildModeTab(2, 'Текст списка'),
                  ],
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Main Capture / Upload Area
                  if (_selectedMode != 2) ...[
                    GestureDetector(
                      onTap: () => _pickImage(ImageSource.camera),
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: _pickedImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.memory(_pickedImageBytes!, fit: BoxFit.cover),
                                    Container(color: Colors.black26),
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                                            SizedBox(width: 6),
                                            Text(
                                              'Переснять фото',
                                              style: TextStyle(color: Colors.white, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: const BoxDecoration(
                                      color: AppColors.surfaceMuted,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 28,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _selectedMode == 0
                                        ? 'Сфотографировать чек'
                                        : 'Сфотографировать полку',
                                    style: AppTypography.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Gemini Vision распознает продукты и сроки годности',
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Gallery button
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined, size: 18),
                            label: const Text('Выбрать из галереи'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Text / OCR Input
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Вставьте список покупок или текст чека', style: AppTypography.titleSmall),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _textInputController,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              hintText: 'Томаты черри 250г\nКуриное филе 500г\nСыр Фета 200г',
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _processText,
                              child: const Text('Распознать список'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Error Banner if API error occurred
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.statusUrgent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.statusUrgent, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Loading State
                  if (_isProcessing) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            SizedBox(height: 14),
                            Text('Gemini 1.5 Flash анализирует снимок...'),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Empty scan result state (e.g. photo of empty room or non-food)
                  if (!_isProcessing && _hasScanned && _recognizedItems.isEmpty && _errorMessage == null) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.search_off_rounded, size: 36, color: AppColors.textTertiary),
                          const SizedBox(height: 10),
                          Text('Продукты не обнаружены', style: AppTypography.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            'На данном снимке ИИ не обнаружил продуктов питания или кассового чека. Наведите камеру на полку с продуктами или чек.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Recognized Results Section
                  if (!_isProcessing && _recognizedItems.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Распознанные продукты (${_recognizedItems.length})',
                          style: AppTypography.titleMedium,
                        ),
                        Text(
                          'Нажмите для удаления',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recognizedItems.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _recognizedItems[index];
                        final days = item.daysUntilExpiry;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Text(item.emoji, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: AppTypography.titleSmall),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.amount.toStringAsFixed(item.amount % 1 == 0 ? 0 : 1)} ${item.unit} • ${item.category}',
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  days <= 2 ? '$days дня' : '$days дн.',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: days <= 2 ? AppColors.statusUrgent : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textTertiary),
                                onPressed: () => _removeItem(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            // Bottom Confirm Button
            if (_recognizedItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saveAllToFridge,
                    child: Text('Добавить в Холодильник (${_recognizedItems.length})'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(int mode, String title) {
    final isSelected = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedMode = mode;
            _pickedImageBytes = null;
            _hasScanned = false;
            _errorMessage = null;
            _recognizedItems = [];
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
