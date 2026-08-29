import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../analytics/providers/eco_savings_provider.dart';
import '../models/cooking_step.dart';
import '../models/recipe.dart';

class SmartCookingScreen extends ConsumerStatefulWidget {
  final Recipe recipe;

  const SmartCookingScreen({super.key, required this.recipe});

  @override
  ConsumerState<SmartCookingScreen> createState() => _SmartCookingScreenState();
}

class _SmartCookingScreenState extends ConsumerState<SmartCookingScreen>
    with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isTimerRunning = false;

  // Real Speech To Text Engine
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastRecognizedWords = '';
  String? _lastCommandExecuted;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _initSpeech();
    _checkAndInitTimerForStep();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speechToText.stop();
    _pulseController.dispose();
    super.dispose();
  }

  /// Initialize real speech-to-text with auto-restart for cooking hands-free mode
  Future<void> _initSpeech() async {
    try {
      final available = await _speechToText.initialize(
        onError: (error) {
          if (mounted) {
            setState(() {
              _isListening = false;
            });
            // Auto restart listening after short pause for true hands-free cooking
            if (_speechEnabled) {
              Future.delayed(const Duration(seconds: 1), _startContinuousListening);
            }
          }
        },
        onStatus: (status) {
          if (mounted) {
            setState(() {
              _isListening = status == 'listening';
            });
            if (status == 'notListening' && _speechEnabled) {
              Future.delayed(const Duration(milliseconds: 500), _startContinuousListening);
            }
          }
        },
      );

      if (mounted) {
        setState(() {
          _speechEnabled = available;
        });
        if (available) {
          _startContinuousListening();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _speechEnabled = false);
      }
    }
  }

  void _startContinuousListening() async {
    if (!_speechEnabled || _speechToText.isListening) return;

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: 'ru_RU',
        listenMode: ListenMode.confirmation,
        pauseFor: const Duration(seconds: 3),
      );
    } catch (_) {}
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.toLowerCase().trim();
    if (words.isEmpty) return;

    setState(() {
      _lastRecognizedWords = words;
    });

    _processVoiceCommand(words);
  }

  void _processVoiceCommand(String text) {
    // Next Step commands
    if (text.contains('дальше') ||
        text.contains('следующ') ||
        text.contains('вперед') ||
        text.contains('готов') ||
        text.contains('далее') ||
        text.contains('next')) {
      _executeCommand('Следующий шаг', _nextStep);
      return;
    }

    // Previous Step commands
    if (text.contains('назад') ||
        text.contains('предыдущ') ||
        text.contains('верни') ||
        text.contains('back')) {
      _executeCommand('Предыдущий шаг', _prevStep);
      return;
    }

    // Timer Start commands
    if ((text.contains('таймер') || text.contains('старт') || text.contains('запусти') || text.contains('поехали') || text.contains('включи')) &&
        !text.contains('стоп') &&
        !text.contains('пауз')) {
      if (!_isTimerRunning) {
        _executeCommand('Таймер запущен', _toggleTimer);
      }
      return;
    }

    // Timer Stop / Pause commands
    if (text.contains('стоп') ||
        text.contains('пауз') ||
        text.contains('останови') ||
        text.contains('выключи')) {
      if (_isTimerRunning) {
        _executeCommand('Таймер на паузе', _toggleTimer);
      }
      return;
    }

    // Finish commands
    if (text.contains('закончить') || text.contains('завершить') || text.contains('все готово')) {
      _executeCommand('Завершение готовки', _finishCooking);
      return;
    }
  }

  void _executeCommand(String feedback, VoidCallback action) {
    HapticFeedback.heavyImpact();
    setState(() {
      _lastCommandExecuted = feedback;
    });
    action();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          if (_lastCommandExecuted == feedback) {
            _lastCommandExecuted = null;
          }
        });
      }
    });
  }

  void _toggleManualVoice() {
    HapticFeedback.lightImpact();
    if (_isListening) {
      _speechToText.stop();
      setState(() {
        _speechEnabled = false;
        _isListening = false;
      });
    } else {
      setState(() => _speechEnabled = true);
      _startContinuousListening();
    }
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Таймер завершен'),
        content: const Text('Блюдо готово к следующему этапу. Проверьте готовность и переходите дальше.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryForeground,
            ),
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.primary),
              SizedBox(height: 10),
              Text('Блюдо готово!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Вы приготовили «${widget.recipe.title}». Продукты успешно использованы.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('+320 ₽', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800)),
                      Text('Сэкономлено', style: AppTypography.labelSmall),
                    ],
                  ),
                  Column(
                    children: [
                      Text('+0.4 кг', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800)),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.primaryForeground,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close cooking screen
              },
              child: const Text('Завершить', style: TextStyle(fontWeight: FontWeight.w700)),
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

  /// Get contextual intermediate step action image
  String _getStepImageUrl(CookingStep step) {
    if (step.imageUrl != null && step.imageUrl!.isNotEmpty) {
      return step.imageUrl!;
    }

    final lower = '${step.title} ${step.instruction}'.toLowerCase();

    // Contextual culinary action photography
    if (lower.contains('обжар') || lower.contains('сковород') || lower.contains('жар')) {
      return 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=800'; // Pan frying
    } else if (lower.contains('нареж') || lower.contains('нарезк') || lower.contains('очист') || lower.contains('кубик')) {
      return 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=800'; // Chef slicing
    } else if (lower.contains('вар') || lower.contains('кип') || lower.contains('вод') || lower.contains('паст') || lower.contains('рис')) {
      return 'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=800'; // Boiling pot
    } else if (lower.contains('запек') || lower.contains('духовк') || lower.contains('печ')) {
      return 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800'; // Oven baking
    } else if (lower.contains('подач') || lower.contains('сервиров') || lower.contains('вылож') || lower.contains('готов')) {
      return widget.recipe.imageUrl; // Finished dish plating
    }

    // Default high-quality kitchen prep visual
    return 'https://images.unsplash.com/photo-1507048821117-6573c2dfc4b9?w=800';
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.recipe.steps;
    final currentStep = steps[_currentStepIndex];
    final progress = (_currentStepIndex + 1) / steps.length;
    final stepImage = _getStepImageUrl(currentStep);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Режим готовки', style: AppTypography.titleMedium),
        actions: [
          // Voice Assistant Status Pill
          GestureDetector(
            onTap: _toggleManualVoice,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isListening
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isListening ? (1.0 + _pulseController.value * 0.25) : 1.0,
                        child: Icon(
                          _isListening ? Icons.mic_rounded : Icons.mic_off_rounded,
                          size: 16,
                          color: _isListening ? AppColors.primary : AppColors.textTertiary,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isListening ? 'Голос слушает' : 'Голос выкл',
                    style: TextStyle(
                      fontSize: 11,
                      color: _isListening ? AppColors.primary : AppColors.textTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Linear Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceMuted,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            // Voice Feedback / Command Banner
            if (_lastCommandExecuted != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Команда: $_lastCommandExecuted',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else if (_isListening && _lastRecognizedWords.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '«$_lastRecognizedWords»',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            // Scrollable Step Details & Visual Card
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Visual Intermediate Step Image Card
                    Container(
                      height: 190,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildStepImage(stepImage),

                          // Subtle Dark Gradient Overlay
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.55),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Step Tag Pill in Image
                          Positioned(
                            bottom: 12,
                            left: 14,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.camera_alt_outlined, size: 13, color: Colors.white),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Промежуточный этап #${currentStep.stepNumber}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Step Title
                    Text(
                      currentStep.title,
                      style: AppTypography.titleLarge.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Instruction (Large clear readable text)
                    Text(
                      currentStep.instruction,
                      style: AppTypography.bodyLarge.copyWith(
                        fontSize: 16,
                        height: 1.45,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Interactive Timer Card (if this step has timer)
                    if (currentStep.timerDurationSeconds != null && currentStep.timerDurationSeconds! > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isTimerRunning
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isTimerRunning ? AppColors.primary : AppColors.surface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isTimerRunning ? Icons.hourglass_top_rounded : Icons.timer_outlined,
                                color: _isTimerRunning ? Colors.white : AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatSeconds(_remainingSeconds),
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'monospace',
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  Text(
                                    _isTimerRunning ? 'Таймер активен • Скажите «Пауза»' : 'Скажите «Таймер» или нажмите',
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isTimerRunning ? AppColors.statusUrgent : AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onPressed: _toggleTimer,
                              child: Text(
                                _isTimerRunning ? 'Стоп' : 'Старт',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Parallel Task Hint
                    if (currentStep.parallelTaskHint != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.flash_on_rounded, size: 20, color: Color(0xFFF57F17)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Параллельное действие',
                                    style: TextStyle(
                                      color: Color(0xFFF57F17),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currentStep.parallelTaskHint!,
                                    style: const TextStyle(
                                      color: Color(0xFF5D4037),
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Chef Tip
                    if (currentStep.tip != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded, size: 20, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                currentStep.tip!,
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Voice Commands Cheat-sheet Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.record_voice_over_outlined, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Команды: «Дальше», «Назад», «Таймер», «Стоп»',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Actions Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
              ),
              child: Row(
                children: [
                  if (_currentStepIndex > 0) ...[
                    IconButton.filledTonal(
                      onPressed: _prevStep,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceMuted,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.all(14),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.primaryForeground,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _nextStep,
                      child: Text(
                        _currentStepIndex < steps.length - 1 ? 'Следующий шаг' : 'Завершить готовку',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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

  Widget _buildStepImage(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(color: AppColors.surfaceMuted),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.surfaceMuted,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        );
      },
      errorBuilder: (_, _, _) => Container(
        color: AppColors.surfaceMuted,
        child: const Center(
          child: Icon(Icons.restaurant_outlined, size: 36, color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
