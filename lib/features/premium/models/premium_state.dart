class PremiumState {
  final bool isPremium;
  final String? planName; // 'Месячный', 'Годовой'
  final DateTime? expiresAt;

  const PremiumState({
    this.isPremium = false,
    this.planName,
    this.expiresAt,
  });

  PremiumState copyWith({
    bool? isPremium,
    String? planName,
    DateTime? expiresAt,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      planName: planName ?? this.planName,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPremium': isPremium,
      'planName': planName,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory PremiumState.fromJson(Map<String, dynamic> json) {
    return PremiumState(
      isPremium: json['isPremium'] as bool? ?? false,
      planName: json['planName'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
    );
  }
}
