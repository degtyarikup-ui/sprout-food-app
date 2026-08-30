class AuthUser {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String authProviderType; // 'google' or 'telegram'
  final String? username;

  const AuthUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.authProviderType = 'google',
    this.username,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'authProviderType': authProviderType,
      'username': username,
    };
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Пользователь Sprout',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      authProviderType: json['authProviderType'] as String? ?? 'google',
      username: json['username'] as String?,
    );
  }
}
