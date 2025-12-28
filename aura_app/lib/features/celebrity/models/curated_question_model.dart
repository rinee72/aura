import '../../fan/models/question_model.dart';
import '../../auth/models/user_model.dart';

/// 질문 큐레이션 모델
/// 
/// WP-3.1: 질문 큐레이션 대시보드
/// 
/// 셀럽이 확인할 수 있는 정제된 질문 정보를 나타냅니다.
/// 질문 정보 + 좋아요 수 + 답변 상태 + 작성자 정보를 포함합니다.
class CuratedQuestionModel {
  final QuestionModel question;
  final UserModel? author; // 작성자 정보 (선택)

  CuratedQuestionModel({
    required this.question,
    this.author,
  });

  /// QuestionModel로부터 CuratedQuestionModel 생성
  /// 
  /// [question]: 질문 모델
  /// [author]: 작성자 정보 (선택)
  factory CuratedQuestionModel.fromQuestion({
    required QuestionModel question,
    UserModel? author,
  }) {
    return CuratedQuestionModel(
      question: question,
      author: author,
    );
  }

  /// CuratedQuestionModel 복사 (일부 필드만 변경)
  CuratedQuestionModel copyWith({
    QuestionModel? question,
    UserModel? author,
  }) {
    return CuratedQuestionModel(
      question: question ?? this.question,
      author: author ?? this.author,
    );
  }

  /// 질문 ID
  String get id => question.id;

  /// 질문 내용
  String get content => question.content;

  /// 좋아요 수
  int get likeCount => question.likeCount;

  /// 답변 상태 ('pending' or 'answered')
  String get status => question.status;

  /// 답변 완료 여부
  bool get isAnswered => question.isAnswered;

  /// 작성 시간
  DateTime get createdAt => question.createdAt;

  /// 작성자 ID
  String get userId => question.userId;
}

