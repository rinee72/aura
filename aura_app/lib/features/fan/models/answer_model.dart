/// 답변 모델
/// 
/// WP-2.4: 답변 피드 (Q&A 연결)
/// 
/// Supabase의 answers 테이블과 연동되는 답변 정보를 나타냅니다.
class AnswerModel {
  final String id;
  final String questionId;
  final String celebrityId;
  final String content;
  final bool isDraft;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnswerModel({
    required this.id,
    required this.questionId,
    required this.celebrityId,
    required this.content,
    this.isDraft = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Supabase에서 받은 데이터로부터 AnswerModel 생성
  /// 
  /// [json]: Supabase에서 받은 답변 데이터
  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      celebrityId: json['celebrity_id'] as String,
      content: json['content'] as String,
      isDraft: (json['is_draft'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'celebrity_id': celebrityId,
      'content': content,
      'is_draft': isDraft,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// AnswerModel 복사 (일부 필드만 변경)
  AnswerModel copyWith({
    String? id,
    String? questionId,
    String? celebrityId,
    String? content,
    bool? isDraft,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnswerModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      celebrityId: celebrityId ?? this.celebrityId,
      content: content ?? this.content,
      isDraft: isDraft ?? this.isDraft,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 공개된 답변 여부
  bool get isPublished => !isDraft;
}
