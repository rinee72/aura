/// 커뮤니티 게시글 모델
/// 
/// WP-2.5: 팬 커뮤니티 (게시글/댓글)
/// 
/// Supabase의 communities 테이블과 연동되는 게시글 정보를 나타냅니다.
class CommunityPostModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final int viewCount;
  final int commentCount; // 댓글 수 (서비스에서 계산)
  final DateTime createdAt;
  final DateTime updatedAt;

  CommunityPostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.viewCount = 0,
    this.commentCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Supabase에서 받은 데이터로부터 CommunityPostModel 생성
  /// 
  /// [json]: Supabase에서 받은 게시글 데이터
  /// [commentCount]: 댓글 수 (기본값: 0)
  factory CommunityPostModel.fromJson(
    Map<String, dynamic> json, {
    int commentCount = 0,
  }) {
    return CommunityPostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      viewCount: (json['view_count'] as int?) ?? 0,
      commentCount: commentCount,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'view_count': viewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// CommunityPostModel 복사 (일부 필드만 변경)
  CommunityPostModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    int? viewCount,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunityPostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      viewCount: viewCount ?? this.viewCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

