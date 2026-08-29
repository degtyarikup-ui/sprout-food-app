import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/gemini_ai_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../fridge/models/product_item.dart';
import '../../fridge/providers/fridge_provider.dart';
import '../../meal_planner/providers/meal_planner_provider.dart';
import '../../navigation/main_scaffold.dart';
import '../../profile/models/user_preferences.dart';
import '../../profile/providers/user_preferences_provider.dart';
import '../providers/onboarding_provider.dart';

class OnboardingQuizScreen extends ConsumerStatefulWidget {
  const OnboardingQuizScreen({super.key});

  @override
  ConsumerState<OnboardingQuizScreen> createState() => _OnboardingQuizScreenState();
}

class _OnboardingQuizScreenState extends ConsumerState<OnboardingQuizScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 5;

  // Step 1: Goal
  String _selectedGoal = 'Экономить время и бюджет';
  final List<Map<String, dynamic>> _goals = [
    {
      'title': 'Экономить время и бюджет',
      'subtitle': 'Zero Waste: готовить из того, что уже есть в холодильнике',
      'icon': Icons.bolt_rounded,
    },
    {
      'title': 'Здоровое и разнообразное меню',
      'subtitle': 'Свежие и сбалансированные рецепты каждый день',
      'icon': Icons.spa_outlined,
    },
    {
      'title': 'Готовить для всей семьи',
      'subtitle': 'Удобный расчет порций и блюда, которые любят дети',
      'icon': Icons.family_restroom_rounded,
    },
    {
      'title': 'Легкий баланс калорий',
      'subtitle': 'Контроль БЖУ и стройность без строгих ограничений',
      'icon': Icons.fitness_center_rounded,
    },
  ];

  // Step 2: Servings & Diet
  int _servings = 2;
  DietType _diet = DietType.omnivore;

  // Step 3: Allergies
  final Set<String> _selectedAllergies = {};
  static const List<String> _kAllergies = [
    'Без глютена',
    'Без лактозы',
    'Без орехов',
    'Без морепродуктов',
    'Без сахара',
    'Не острое',
  ];

  // Step 4: Multi-Photo Fridge/Pantry capture
  final List<Uint8List> _capturedPhotos = [];
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzingPhotos = false;

  // Step 5: Generation Animation
  int _generationStage = 0;
  bool _generationComplete = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1440,
        maxHeight: 2560,
        imageQuality: 85,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _capturedPhotos.add(bytes);
        });
        HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }

  Future<void> _startMealPlanGeneration({bool skipScan = false}) async {
    // 1. Save preferences
    await ref.read(userPreferencesProvider.notifier).setServings(_servings);
    await ref.read(userPreferencesProvider.notifier).setDiet(_diet);
    for (final allergy in _selectedAllergies) {
      await ref.read(userPreferencesProvider.notifier).toggleAllergy(allergy);
    }

    _nextPage(); // Move to Step 5 (Generation screen)

    setState(() {
      _isAnalyzingPhotos = true;
      _generationStage = 0;
      _generationComplete = false;
    });

    // Animate stage 1: Analyze products
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _generationStage = 1);

    if (!skipScan && _capturedPhotos.isNotEmpty) {
      try {
        final List<ProductItem> recognized = [];
        for (final photoBytes in _capturedPhotos) {
          final items = await GeminiAIService.scanReceiptOrFridge(
            imageBytes: photoBytes,
            mimeType: 'image/jpeg',
            isReceipt: false,
          );
          recognized.addAll(items);
        }
        if (recognized.isNotEmpty) {
          await ref.read(fridgeProvider.notifier).addMultipleProducts(recognized);
        }
      } catch (_) {}
    }

    // Animate stage 2: Exclude allergies & set portions
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _generationStage = 2);

    // Animate stage 3: Generate 7-day plan
    await Future.delayed(const Duration(milliseconds: 900));
    ref.read(mealPlannerProvider.notifier).generateZeroWastePlan();
    if (mounted) setState(() => _generationStage = 3);

    // Complete!
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() {
        _isAnalyzingPhotos = false;
        _generationComplete = true;
      });
      HapticFeedback.heavyImpact();
    }
  }

  void _finishOnboarding() async {
    HapticFeedback.mediumImpact();
    await ref.read(onboardingProvider.notifier).completeOnboarding();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScaffold()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / _totalSteps;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress & Back Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (_currentStep > 0 && !_isAnalyzingPhotos && !_generationComplete)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      onPressed: _prevPage,
                    )
                  else
                    const SizedBox(width: 40),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: AppColors.surfaceMuted,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentStep + 1}/$_totalSteps',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),

            // Main Steps PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _buildStep1Goal(),
                  _buildStep2FamilyAndDiet(),
                  _buildStep3Allergies(),
                  _buildStep4MultiPhotoFridge(),
                  _buildStep5Generation(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1: Main Goal
  Widget _buildStep1Goal() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Добро пожаловать в Sprout 🌱', style: AppTypography.displayMedium),
          const SizedBox(height: 6),
          Text(
            'Какая ваша главная цель питания на ближайшую неделю?',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                final isSelected = _selectedGoal == goal['title'];

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedGoal = goal['title'] as String);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            goal['icon'] as IconData,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal['title'] as String,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                goal['subtitle'] as String,
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.primaryForeground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _nextPage,
              child: const Text('Продолжить', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // STEP 2: Family Portions & Diet Type
  Widget _buildStep2FamilyAndDiet() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Семья и тип питания 🍽️', style: AppTypography.displayMedium),
          const SizedBox(height: 6),
          Text(
            'На сколько человек готовить и какого рациона вы придерживаетесь?',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Servings
          Text('Количество персон', style: AppTypography.labelMedium),
          const SizedBox(height: 10),
          Row(
            children: [1, 2, 4, 6].map((count) {
              final isSelected = _servings == count;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _servings = count);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$count ${count == 1 ? 'чел' : 'чел'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Diet
          Text('Тип питания', style: AppTypography.labelMedium),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: DietType.values.length,
              itemBuilder: (context, index) {
                final diet = DietType.values[index];
                final isSelected = _diet == diet;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _diet = diet);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text(
                          diet.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.primaryForeground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _nextPage,
              child: const Text('Далее', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // STEP 3: Allergies & Exclusions
  Widget _buildStep3Allergies() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Аллергии и ограничения ⚠️', style: AppTypography.displayMedium),
          const SizedBox(height: 6),
          Text(
            'Мы исключим нежелательные продукты из рецептов и плана питания.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _kAllergies.length,
              itemBuilder: (context, index) {
                final allergy = _kAllergies[index];
                final isSelected = _selectedAllergies.contains(allergy);

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isSelected) {
                        _selectedAllergies.remove(allergy);
                      } else {
                        _selectedAllergies.add(allergy);
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.statusUrgent.withValues(alpha: 0.12) : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? AppColors.statusUrgent : AppColors.textTertiary,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          allergy,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppColors.statusUrgent : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.primaryForeground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _nextPage,
              child: const Text('Перейти к фото продуктов', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // STEP 4: Multi-Photo Fridge & Kitchen Scan
  Widget _buildStep4MultiPhotoFridge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Сфотографируйте запасы 📸', style: AppTypography.displayMedium),
          const SizedBox(height: 6),
          Text(
            'Сделайте фото холодильника, морозилки или полок с едой. ИИ сам распознает продукты!',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Captured Photos Grid / Add Trigger
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action buttons row (Camera + Gallery)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickPhoto(ImageSource.camera),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.camera_alt_rounded, size: 32, color: AppColors.primary),
                                SizedBox(height: 8),
                                Text(
                                  'Сделать фото',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickPhoto(ImageSource.gallery),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.photo_library_rounded, size: 32, color: AppColors.textPrimary),
                                SizedBox(height: 8),
                                Text(
                                  'Из галереи',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Photo Thumbnails List
                  if (_capturedPhotos.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Добавленные фото (${_capturedPhotos.length})', style: AppTypography.titleSmall),
                        TextButton(
                          onPressed: () => _pickPhoto(ImageSource.camera),
                          child: const Text('+ Добавить еще', style: TextStyle(color: AppColors.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _capturedPhotos.asMap().entries.map((entry) {
                        final index = entry.key;
                        final bytes = entry.value;

                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(
                                bytes,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _capturedPhotos.removeAt(index));
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Совет: сфотографируйте несколько полок подряд, чтобы рацион был максимально точным!',
                              style: TextStyle(fontSize: 12, height: 1.35, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Action Buttons
          if (_capturedPhotos.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.primaryForeground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () => _startMealPlanGeneration(skipScan: false),
                child: Text(
                  'Распознать и составить меню (${_capturedPhotos.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.primaryForeground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () => _pickPhoto(ImageSource.camera),
                child: const Text('Сфотографировать холодильник', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          const SizedBox(height: 8),

          Center(
            child: TextButton(
              onPressed: () => _startMealPlanGeneration(skipScan: true),
              child: const Text(
                'Пропустить (составить меню из базовых продуктов)',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // STEP 5: Cinematic AI Generation & Celebration
  Widget _buildStep5Generation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_generationComplete) ...[
            const Spacer(),
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text('Шеф-ИИ формирует рацион', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Подбираем идеальное меню на неделю...', style: AppTypography.bodySmall),
            const SizedBox(height: 32),

            // Checkpoints list
            _buildGenerationCheckpoint(0, 'Анализ продуктов и сроков годности'),
            _buildGenerationCheckpoint(1, 'Исключение аллергенов и настройка порций ($_servings чел)'),
            _buildGenerationCheckpoint(2, 'Подбор 21 сбалансированного блюда на 7 дней'),
            _buildGenerationCheckpoint(3, 'Финализация персонального плана питания'),

            const Spacer(),
          ] else ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 52),
            ),
            const SizedBox(height: 20),
            Text('Ваш рацион готов! 🎉', style: AppTypography.displayMedium),
            const SizedBox(height: 8),
            Text(
              'Меню составлено с учетом ваших целей, диеты и состава семьи.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(Icons.calendar_month_rounded, 'Период', '7 дней (21 блюдо)'),
                  const Divider(height: 20),
                  _buildSummaryRow(Icons.people_outline_rounded, 'Размер порций', '$_servings чел • ${_diet.label}'),
                  const Divider(height: 20),
                  _buildSummaryRow(Icons.savings_outlined, 'Ожидаемая экономия', '~2 400 ₽ за неделю', isAccent: true),
                ],
              ),
            ),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.primaryForeground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _finishOnboarding,
                child: const Text('Открыть план питания', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildGenerationCheckpoint(int stageIndex, String title) {
    final isDone = _generationStage > stageIndex;
    final isCurrent = _generationStage == stageIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isDone
                ? Icons.check_circle_rounded
                : (isCurrent ? Icons.hourglass_top_rounded : Icons.radio_button_unchecked_rounded),
            size: 18,
            color: isDone ? AppColors.primary : (isCurrent ? AppColors.primary : AppColors.textTertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isCurrent || isDone ? FontWeight.w700 : FontWeight.w500,
                color: isDone || isCurrent ? AppColors.textPrimary : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, {bool isAccent = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isAccent ? AppColors.primary : AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isAccent ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
