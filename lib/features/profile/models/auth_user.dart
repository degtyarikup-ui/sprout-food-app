class AuthUser {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;

  const AuthUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
    };
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Пользователь Sprout',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
    );
  }
}
