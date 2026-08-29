class CookingStep {
  final int stepNumber;
  final String title;
  final String instruction;
  final int? timerDurationSeconds; // Auto-timer
  final String? parallelTaskHint;   // "Пока вода закипает, нарежьте курицу"
  final String? tip;                // Chef tip
  final String? familyVariantNote;  // "Для детской порции отложите часть соуса до перца"

  const CookingStep({
    required this.stepNumber,
    required this.title,
    required this.instruction,
    this.timerDurationSeconds,
    this.parallelTaskHint,
    this.tip,
    this.familyVariantNote,
  });

  CookingStep copyWith({
    int? stepNumber,
    String? title,
    String? instruction,
    int? timerDurationSeconds,
    String? parallelTaskHint,
    String? tip,
    String? familyVariantNote,
  }) {
    return CookingStep(
      stepNumber: stepNumber ?? this.stepNumber,
      title: title ?? this.title,
      instruction: instruction ?? this.instruction,
      timerDurationSeconds: timerDurationSeconds ?? this.timerDurationSeconds,
      parallelTaskHint: parallelTaskHint ?? this.parallelTaskHint,
      tip: tip ?? this.tip,
      familyVariantNote: familyVariantNote ?? this.familyVariantNote,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepNumber': stepNumber,
      'title': title,
      'instruction': instruction,
      'timerDurationSeconds': timerDurationSeconds,
      'parallelTaskHint': parallelTaskHint,
      'tip': tip,
      'familyVariantNote': familyVariantNote,
    };
  }

  factory CookingStep.fromJson(Map<String, dynamic> json) {
    return CookingStep(
      stepNumber: json['stepNumber'] as int,
      title: json['title'] as String,
      instruction: json['instruction'] as String,
      timerDurationSeconds: json['timerDurationSeconds'] as int?,
      parallelTaskHint: json['parallelTaskHint'] as String?,
      tip: json['tip'] as String?,
      familyVariantNote: json['familyVariantNote'] as String?,
    );
  }
}
