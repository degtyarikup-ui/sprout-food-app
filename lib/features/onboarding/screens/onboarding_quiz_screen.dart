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

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN RULES — Sprout Visual Language:
//  • Максимум визуала, минимум текста
//  • Без обводок (Zero Borders) — только цвет фона, тени и blur
//  • Без эмодзи в ядре интерфейса — чистые иконки Icons.*_rounded
//  • Шрифт — только GoogleFonts.onest()
//  • Без англицизмов — все подписи на русском
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingQuizScreen extends ConsumerStatefulWidget {
  const OnboardingQuizScreen({super.key});

  @override
  ConsumerState<OnboardingQuizScreen> createState() =>
      _OnboardingQuizScreenState();
}

class _OnboardingQuizScreenState extends ConsumerState<OnboardingQuizScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 6;

  // ── Step 1: Goals (Multi‑select) ──────────────────────────────────────────
  final Set<int> _selectedGoals = {0};

  static const List<Map<String, dynamic>> _goals = [
    {
      'title': 'Не выбрасывать продукты',
      'icon': Icons.eco_rounded,
    },
    {
      'title': 'Разнообразное меню',
      'icon': Icons.restaurant_rounded,
    },
    {
      'title': 'Готовить для семьи',
      'icon': Icons.family_restroom_rounded,
    },
    {
      'title': 'Следить за питанием',
      'icon': Icons.monitor_heart_rounded,
    },
    {
      'title': 'Экономить бюджет',
      'icon': Icons.savings_rounded,
    },
    {
      'title': 'Быстрые рецепты',
      'icon': Icons.timer_rounded,
    },
  ];

  // ── Step 2: Servings ──────────────────────────────────────────────────────
  int _servings = 2;

  // ── Step 3: Diet type ─────────────────────────────────────────────────────
  DietType _diet = DietType.omnivore;

  // ── Step 4: Deep Restrictions ─────────────────────────────────────────────
  final Set<String> _selectedRestrictions = {};
  int? _expandedCategoryIndex;

  static const List<Map<String, dynamic>> _restrictionCategories = [
    {
      'title': 'Аллергены',
      'icon': Icons.warning_amber_rounded,
      'items': [
        'Молоко и молочное',
        'Яйца',
        'Орехи',
        'Арахис',
        'Рыба',
        'Моллюски и ракообразные',
        'Пшеница и глютен',
        'Соя',
        'Кунжут',
      ],
    },
    {
      'title': 'Непереносимость',
      'icon': Icons.do_not_disturb_on_rounded,
      'items': [
        'Лактоза',
        'Фруктоза',
        'Гистамин',
      ],
    },
    {
      'title': 'Убеждения',
      'icon': Icons.volunteer_activism_rounded,
      'items': [
        'Халяль',
        'Кошер',
        'Без свинины',
      ],
    },
    {
      'title': 'Предпочтения',
      'icon': Icons.tune_rounded,
      'items': [
        'Не острое',
        'Без грибов',
        'Без лука и чеснока',
        'Без сахара',
      ],
    },
  ];

  // ── Step 5: Multi‑Photo Scan ──────────────────────────────────────────────
  final List<Uint8List> _capturedPhotos = [];
  final ImagePicker _picker = ImagePicker();

  // ── Step 6: Generation ────────────────────────────────────────────────────
  int _generationStage = 0;
  bool _generationComplete = false;
  bool _isGenerating = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  // ── Photo Capture ─────────────────────────────────────────────────────────
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
        setState(() => _capturedPhotos.add(bytes));
        HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }

  // ── Save & Generate ───────────────────────────────────────────────────────
  Future<void> _startMealPlanGeneration({bool skipScan = false}) async {
    // Persist preferences
    final goalTitles = _selectedGoals.map((i) => _goals[i]['title'] as String).toList();
    await ref.read(userPreferencesProvider.notifier).setGoals(goalTitles);
    await ref.read(userPreferencesProvider.notifier).setServings(_servings);
    await ref.read(userPreferencesProvider.notifier).setDiet(_diet);
    await ref.read(userPreferencesProvider.notifier).setAllergies(_selectedRestrictions.toList());

    _nextPage(); // Go to Step 6

    setState(() {
      _isGenerating = true;
      _generationStage = 0;
      _generationComplete = false;
    });

    // Stage 1: Scan photos
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

    // Stage 2: Allergies & portions
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _generationStage = 2);

    // Stage 3: Build plan
    await Future.delayed(const Duration(milliseconds: 900));
    ref.read(mealPlannerProvider.notifier).generateZeroWastePlan();
    if (mounted) setState(() => _generationStage = 3);

    // Done
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() {
        _isGenerating = false;
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
        MaterialPageRoute(builder: (_) => const MainScaffold()),
        (_) => false,
      );
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / _totalSteps;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  if (_currentStep > 0 && !_isGenerating && !_generationComplete)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      onPressed: _prevPage,
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: AppColors.surfaceMuted,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentStep + 1}/$_totalSteps',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Pages ───────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _buildStep1Goals(),
                  _buildStep2Servings(),
                  _buildStep3Diet(),
                  _buildStep4Restrictions(),
                  _buildStep5Photos(),
                  _buildStep6Generation(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 1 — Goals  (multi‑select, hero image, minimal text)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildStep1Goals() {
    return Column(
      children: [
        // Hero Image
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: Image.asset(
              'assets/images/onboarding/hero_welcome.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Что для вас важно?', style: AppTypography.displayMedium),
                const SizedBox(height: 4),
                Text(
                  'Можно выбрать несколько',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: _goals.length,
                    itemBuilder: (context, index) {
                      final goal = _goals[index];
                      final isSelected = _selectedGoals.contains(index);

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (isSelected) {
                              _selectedGoals.remove(index);
                            } else {
                              _selectedGoals.add(index);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                goal['icon'] as IconData,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  goal['title'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                _buildPrimaryButton(
                  'Продолжить',
                  enabled: _selectedGoals.isNotEmpty,
                  onPressed: _nextPage,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 2 — Servings
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildStep2Servings() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('На сколько человек\nготовите?', style: AppTypography.displayMedium),
          const SizedBox(height: 32),

          // Large visual counter
          Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$_servings',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [1, 2, 3, 4, 5, 6].map((count) {
              final isSelected = _servings == count;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _servings = count);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const Spacer(),
          _buildPrimaryButton('Далее', onPressed: _nextPage),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 3 — Diet type
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildStep3Diet() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Тип питания', style: AppTypography.displayMedium),
          const SizedBox(height: 4),
          Text(
            'Рецепты подстроятся под ваш рацион',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 20),

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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                diet.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                diet.shortDescription,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.7)
                                      : AppColors.textTertiary,
                                ),
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

          _buildPrimaryButton('Далее', onPressed: _nextPage),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 4 — Deep Restrictions (expandable categories + subcategories)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildStep4Restrictions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ограничения в еде', style: AppTypography.displayMedium),
          const SizedBox(height: 4),
          Text(
            'Мы уберём нежелательные продукты из рецептов',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView.builder(
              itemCount: _restrictionCategories.length,
              itemBuilder: (context, catIndex) {
                final category = _restrictionCategories[catIndex];
                final items = category['items'] as List<String>;
                final isExpanded = _expandedCategoryIndex == catIndex;

                // Count selected in this category
                final selectedCount = items.where((i) => _selectedRestrictions.contains(i)).length;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? AppColors.surface
                        : (selectedCount > 0
                            ? AppColors.statusUrgent.withValues(alpha: 0.08)
                            : AppColors.surface),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category Header
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _expandedCategoryIndex = isExpanded ? null : catIndex;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Icon(
                                category['icon'] as IconData,
                                size: 22,
                                color: selectedCount > 0
                                    ? AppColors.statusUrgent
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  category['title'] as String,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: selectedCount > 0
                                        ? AppColors.statusUrgent
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (selectedCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusUrgent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$selectedCount',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.statusUrgent,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 4),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 250),
                                child: const Icon(
                                  Icons.expand_more_rounded,
                                  size: 22,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Expanded Sub‑Items
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: items.map((item) {
                              final isSelected = _selectedRestrictions.contains(item);
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    if (isSelected) {
                                      _selectedRestrictions.remove(item);
                                    } else {
                                      _selectedRestrictions.add(item);
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.statusUrgent.withValues(alpha: 0.15)
                                        : AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        size: 16,
                                        color: isSelected
                                            ? AppColors.statusUrgent
                                            : AppColors.textTertiary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        item,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected
                                              ? AppColors.statusUrgent
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          if (_selectedRestrictions.isEmpty)
            Center(
              child: TextButton(
                onPressed: _nextPage,
                child: const Text(
                  'У меня нет ограничений',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                ),
              ),
            ),

          _buildPrimaryButton(
            _selectedRestrictions.isEmpty ? 'Далее' : 'Далее (${_selectedRestrictions.length} исключений)',
            onPressed: _nextPage,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 5 — Multi‑Photo Fridge Scan  (visual hero + camera)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildStep5Photos() {
    return Column(
      children: [
        // Hero Image
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: Image.asset(
              'assets/images/onboarding/hero_scan.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Покажите ваши запасы', style: AppTypography.displayMedium),
                const SizedBox(height: 4),
                Text(
                  'Сфотографируйте холодильник, морозилку или полку — мы распознаем продукты',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
                const SizedBox(height: 16),

                // Camera + Gallery buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildPhotoButton(
                        Icons.camera_alt_rounded,
                        'Камера',
                        isPrimary: true,
                        onTap: () => _pickPhoto(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPhotoButton(
                        Icons.photo_library_rounded,
                        'Галерея',
                        isPrimary: false,
                        onTap: () => _pickPhoto(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Photo Thumbnails
                if (_capturedPhotos.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Добавлено: ${_capturedPhotos.length}',
                          style: AppTypography.labelMedium,
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _capturedPhotos.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _capturedPhotos.length) {
                                // Add more button
                                return GestureDetector(
                                  onTap: () => _pickPhoto(ImageSource.camera),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.add_rounded, color: AppColors.textTertiary, size: 28),
                                  ),
                                );
                              }

                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.memory(
                                      _capturedPhotos[index],
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _capturedPhotos.removeAt(index)),
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
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.kitchen_rounded, size: 48, color: AppColors.textTertiary.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(
                            'Можно добавить несколько фото\nдля точного распознавания',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.textTertiary.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_capturedPhotos.isNotEmpty)
                  _buildPrimaryButton(
                    'Составить рацион',
                    onPressed: () => _startMealPlanGeneration(skipScan: false),
                  )
                else
                  _buildPrimaryButton(
                    'Сфотографировать',
                    onPressed: () => _pickPhoto(ImageSource.camera),
                  ),

                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: () => _startMealPlanGeneration(skipScan: true),
                    child: const Text(
                      'Пропустить',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 6 — Cinematic Generation + Results
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildStep6Generation() {
    if (_generationComplete) {
      return _buildResultCard();
    }
    return _buildLoadingAnimation();
  }

  Widget _buildLoadingAnimation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
          ),
          const SizedBox(height: 28),
          Text(
            'Готовим ваш план',
            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 32),

          _buildCheckpoint(0, 'Распознавание продуктов'),
          _buildCheckpoint(1, 'Учёт ограничений и порций'),
          _buildCheckpoint(2, 'Подбор блюд на 7 дней'),
          _buildCheckpoint(3, 'Готово!'),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Column(
      children: [
        // Hero Image
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: Image.asset(
              'assets/images/onboarding/hero_mealplan.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Рацион готов!', style: AppTypography.displayMedium),
                const SizedBox(height: 16),

                // Summary Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(Icons.calendar_month_rounded, '7 дней', '21 блюдо'),
                      const SizedBox(height: 14),
                      _buildSummaryRow(Icons.people_outline_rounded, 'Порции', '$_servings чел • ${_diet.label}'),
                      if (_selectedRestrictions.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildSummaryRow(
                          Icons.shield_rounded,
                          'Исключено',
                          '${_selectedRestrictions.length} ограничений',
                        ),
                      ],
                      if (_capturedPhotos.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildSummaryRow(
                          Icons.kitchen_rounded,
                          'Распознано',
                          '${_capturedPhotos.length} фото запасов',
                        ),
                      ],
                    ],
                  ),
                ),

                const Spacer(),

                _buildPrimaryButton('Начать', onPressed: _finishOnboarding),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Reusable helpers
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildPrimaryButton(String label, {VoidCallback? onPressed, bool enabled = true}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? AppColors.primary : AppColors.surfaceMuted,
          foregroundColor: enabled ? AppColors.primaryForeground : AppColors.textTertiary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: enabled ? onPressed : null,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }

  Widget _buildPhotoButton(IconData icon, String label, {required bool isPrimary, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isPrimary ? AppColors.primary : AppColors.textPrimary),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isPrimary ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckpoint(int stageIndex, String title) {
    final isDone = _generationStage > stageIndex;
    final isCurrent = _generationStage == stageIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isDone
                ? Icons.check_circle_rounded
                : (isCurrent ? Icons.hourglass_top_rounded : Icons.circle_outlined),
            size: 18,
            color: isDone ? AppColors.primary : (isCurrent ? AppColors.primary : AppColors.textTertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isDone || isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isDone || isCurrent ? AppColors.textPrimary : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
