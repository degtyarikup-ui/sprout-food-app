class FamilyMember {
  final String id;
  final String name;
  final String? avatarUrl;
  final String role; // 'Создатель', 'Партнер', 'Семья'
  final bool isOnline;
  final DateTime joinedAt;

  const FamilyMember({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.role = 'Партнер',
    this.isOnline = true,
    required this.joinedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'role': role,
        'isOnline': isOnline,
        'joinedAt': joinedAt.toIso8601String(),
      };

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Участник',
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'Партнер',
      isOnline: json['isOnline'] as bool? ?? true,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class FamilyGroup {
  final String id;
  final String name;
  final String inviteCode; // e.g. 'SPROUT-882'
  final List<FamilyMember> members;
  final DateTime createdAt;

  const FamilyGroup({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.members,
    required this.createdAt,
  });

  String get inviteTelegramLink =>
      'https://t.me/sprout_food_app_bot?startapp=join_$inviteCode';

  FamilyGroup copyWith({
    String? id,
    String? name,
    String? inviteCode,
    List<FamilyMember>? members,
    DateTime? createdAt,
  }) {
    return FamilyGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'inviteCode': inviteCode,
        'members': members.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory FamilyGroup.fromJson(Map<String, dynamic> json) {
    return FamilyGroup(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Наша семья',
      inviteCode: json['inviteCode'] as String? ?? 'SPROUT-777',
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => FamilyMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
