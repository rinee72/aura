import 'answer_model.dart';
import 'question_model.dart';
import '../../auth/models/user_model.dart';

/// Q&A 모델
/// 
/// WP-2.4: 답변 피드 (Q&A 연결)
/// 
/// 질문과 답변, 그리고 관련된 사용자 정보를 함께 담는 클래스입니다.
class QAModel {
  final QuestionModel question;
  final AnswerModel answer;
  final UserModel? questionAuthor; // 질문 작성자 (팬)
  final UserModel? celebrity; // 답변 작성자 (셀럽)

  QAModel({
    required this.question,
    required this.answer,
    this.questionAuthor,
    this.celebrity,
  });

  /// JSON 데이터로부터 QAModel 생성
  /// 
  /// [questionJson]: 질문 데이터
  /// [answerJson]: 답변 데이터
  /// [questionAuthorJson]: 질문 작성자 데이터 (optional)
  /// [celebrityJson]: 답변 작성자 데이터 (optional)
  /// [isLiked]: 현재 사용자가 질문에 좋아요를 눌렀는지 여부
  factory QAModel.fromJson({
    required Map<String, dynamic> questionJson,
    required Map<String, dynamic> answerJson,
    Map<String, dynamic>? questionAuthorJson,
    Map<String, dynamic>? celebrityJson,
    bool isLiked = false,
  }) {
    return QAModel(
      question: QuestionModel.fromJson(questionJson, isLiked: isLiked),
      answer: AnswerModel.fromJson(answerJson),
      questionAuthor: questionAuthorJson != null
          ? UserModel.fromJson(questionAuthorJson)
          : null,
      celebrity: celebrityJson != null
          ? UserModel.fromJson(celebrityJson)
          : null,
    );
  }
}
