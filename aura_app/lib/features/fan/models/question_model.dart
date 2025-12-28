/// 질문 모델
/// 
/// WP-2.1: 질문 작성 및 기본 목록 화면
/// WP-2.2: 질문 좋아요 기능 및 정렬
/// 
/// Supabase의 questions 테이블과 연동되는 질문 정보를 나타냅니다.
class QuestionModel {
  final String id;
  final String userId;
  final String content;
  final int likeCount;
  final bool isLiked; // 현재 사용자가 이 질문에 좋아요를 눌렀는지 여부
  final bool isHidden;
  final String? hiddenReason;
  final DateTime? hiddenAt;
  final String? hiddenBy;
  final String status; // 'pending' or 'answered'
  final DateTime createdAt;
  final DateTime updatedAt;

  QuestionModel({
    required this.id,
    required this.userId,
    required this.content,
    this.likeCount = 0,
    this.isLiked = false,
    this.isHidden = false,
    this.hiddenReason,
    this.hiddenAt,
    this.hiddenBy,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Supabase에서 받은 데이터로부터 QuestionModel 생성
  /// 
  /// [json]: Supabase에서 받은 질문 데이터
  /// [isLiked]: 현재 사용자가 이 질문에 좋아요를 눌렀는지 여부 (기본값: false)
  factory QuestionModel.fromJson(
    Map<String, dynamic> json, {
    bool isLiked = false,
  }) {
    return QuestionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      likeCount: (json['like_count'] as int?) ?? 0,
      isLiked: isLiked,
      isHidden: (json['is_hidden'] as bool?) ?? false,
      hiddenReason: json['hidden_reason'] as String?,
      hiddenAt: json['hidden_at'] != null
          ? DateTime.parse(json['hidden_at'] as String)
          : null,
      hiddenBy: json['hidden_by'] as String?,
      status: (json['status'] as String?) ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'like_count': likeCount,
      'is_hidden': isHidden,
      'hidden_reason': hiddenReason,
      'hidden_at': hiddenAt?.toIso8601String(),
      'hidden_by': hiddenBy,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// QuestionModel 복사 (일부 필드만 변경)
  QuestionModel copyWith({
    String? id,
    String? userId,
    String? content,
    int? likeCount,
    bool? isLiked,
    bool? isHidden,
    String? hiddenReason,
    DateTime? hiddenAt,
    String? hiddenBy,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      isHidden: isHidden ?? this.isHidden,
      hiddenReason: hiddenReason ?? this.hiddenReason,
      hiddenAt: hiddenAt ?? this.hiddenAt,
      hiddenBy: hiddenBy ?? this.hiddenBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 답변 완료 여부
  bool get isAnswered => status == 'answered';

  /// 공개 질문 여부
  bool get isPublic => !isHidden;
}

