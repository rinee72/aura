/// 커뮤니티 댓글 모델
/// 
/// WP-2.5: 팬 커뮤니티 (게시글/댓글)
/// 
/// Supabase의 community_comments 테이블과 연동되는 댓글 정보를 나타냅니다.
class CommunityCommentModel {
  final String id;
  final String communityId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommunityCommentModel({
    required this.id,
    required this.communityId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Supabase에서 받은 데이터로부터 CommunityCommentModel 생성
  /// 
  /// [json]: Supabase에서 받은 댓글 데이터
  factory CommunityCommentModel.fromJson(Map<String, dynamic> json) {
    return CommunityCommentModel(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'community_id': communityId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// CommunityCommentModel 복사 (일부 필드만 변경)
  CommunityCommentModel copyWith({
    String? id,
    String? communityId,
    String? userId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunityCommentModel(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

