import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../analytics/providers/eco_savings_provider.dart';
import '../models/recipe.dart';

class SmartCookingScreen extends ConsumerStatefulWidget {
  final Recipe recipe;

  const SmartCookingScreen({super.key, required this.recipe});

  @override
  ConsumerState<SmartCookingScreen> createState() => _SmartCookingScreenState();
}

class _SmartCookingScreenState extends ConsumerState<SmartCookingScreen> {
  int _currentStepIndex = 0;
  final bool _isListeningVoice = true;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _checkAndInitTimerForStep();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _checkAndInitTimerForStep() {
    _timer?.cancel();
    _isTimerRunning = false;
    final currentStep = widget.recipe.steps[_currentStepIndex];
    if (currentStep.timerDurationSeconds != null && currentStep.timerDurationSeconds! > 0) {
      setState(() {
        _remainingSeconds = currentStep.timerDurationSeconds!;
      });
    } else {
      setState(() {
        _remainingSeconds = 0;
      });
    }
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      setState(() => _isTimerRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _timer?.cancel();
          setState(() => _isTimerRunning = false);
          HapticFeedback.heavyImpact();
          _showTimerAlert();
        }
      });
    }
  }

  void _showTimerAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Таймер завершен'),
        content: const Text('Блюдо готово к следующему этапу. Проверьте готовность и переходите дальше.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _nextStep();
            },
            child: const Text('Следующий шаг'),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStepIndex < widget.recipe.steps.length - 1) {
      HapticFeedback.mediumImpact();
      setState(() {
        _currentStepIndex++;
      });
      _checkAndInitTimerForStep();
    } else {
      _finishCooking();
    }
  }

  void _prevStep() {
    if (_currentStepIndex > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentStepIndex--;
      });
      _checkAndInitTimerForStep();
    }
  }

  void _finishCooking() {
    HapticFeedback.heavyImpact();
    ref.read(ecoSavingsProvider.notifier).recordMealCooked(
          savedMoney: 320.0,
          savedKg: 0.4,
        );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.primary),
              SizedBox(height: 8),
              Text('Блюдо готово', textAlign: TextAlign.center),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Вы приготовили «${widget.recipe.title}». Продукты сохранены от списания.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('+320 ₽', style: AppTypography.titleMedium),
                      Text('Сэкономлено', style: AppTypography.labelSmall),
                    ],
                  ),
                  Column(
                    children: [
                      Text('+0.4 кг', style: AppTypography.titleMedium),
                      Text('Спасенная еда', style: AppTypography.labelSmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close cooking screen
              },
              child: const Text('Готово'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSeconds(int sec) {
    final minutes = sec ~/ 60;
    final seconds = sec % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.recipe.steps;
    final currentStep = steps[_currentStepIndex];
    final progress = (_currentStepIndex + 1) / steps.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Режим готовки', style: AppTypography.titleMedium),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  _isListeningVoice ? Icons.mic_rounded : Icons.mic_off_rounded,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  _isListeningVoice ? 'Голос активен' : 'Голос выкл',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Linear Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Шаг ${_currentStepIndex + 1} из ${steps.length}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: AppColors.cardBorder,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Title
                    Text(
                      currentStep.title,
                      style: AppTypography.displayMedium.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 14),

                    // Big Readable Instruction Text
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        currentStep.instruction,
                        style: AppTypography.bodyLarge.copyWith(
                          fontSize: 18,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Parallel Task (Smart Multitasking Sync)
                    if (currentStep.parallelTaskHint != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.flash_on_rounded, size: 20, color: AppColors.textPrimary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Параллельная задача:',
                                    style: AppTypography.labelMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentStep.parallelTaskHint!,
                                    style: AppTypography.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Family Split Note
                    if (currentStep.familyVariantNote != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.family_restroom_rounded, size: 20, color: AppColors.textPrimary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Для семьи:',
                                    style: AppTypography.labelMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentStep.familyVariantNote!,
                                    style: AppTypography.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Active Step Timer if available
                    if (currentStep.timerDurationSeconds != null && currentStep.timerDurationSeconds! > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _isTimerRunning ? AppColors.primary : AppColors.cardBorder,
                            width: _isTimerRunning ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 28,
                                  color: AppColors.textPrimary,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Таймер шага', style: AppTypography.bodySmall),
                                    Text(
                                      _formatSeconds(_remainingSeconds),
                                      style: AppTypography.displayMedium.copyWith(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isTimerRunning ? AppColors.surfaceMuted : AppColors.primary,
                                foregroundColor: _isTimerRunning ? AppColors.textPrimary : AppColors.primaryForeground,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _toggleTimer,
                              child: Text(_isTimerRunning ? 'Пауза' : 'Старт'),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Voice Commands Helper Footer
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textTertiary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Голосовые команды: «Дальше», «Назад» или «Поставь таймер»',
                              style: AppTypography.bodySmall.copyWith(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Navigation Bottom Control Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  if (_currentStepIndex > 0) ...[
                    OutlinedButton(
                      onPressed: _prevStep,
                      child: const Icon(Icons.arrow_back_rounded, size: 20),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        child: Text(
                          _currentStepIndex == steps.length - 1 ? 'Завершить готовку' : 'Следующий шаг',
                          style: AppTypography.labelLarge,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
