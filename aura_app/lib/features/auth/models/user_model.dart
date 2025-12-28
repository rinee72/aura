/// 사용자 모델
/// 
/// Supabase Auth의 User와 연동되는 사용자 정보를 나타냅니다.
/// WP-1.3: 사용자 프로필 및 역할 관리 시스템
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String? role; // 'fan', 'celebrity', 'manager'
  final String? bio; // 자기소개
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.role,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Supabase에서 받은 데이터로부터 UserModel 생성
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'role': role,
      'bio': bio,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// UserModel 복사 (일부 필드만 변경)
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? role,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
