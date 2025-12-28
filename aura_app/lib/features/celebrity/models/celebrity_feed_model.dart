import 'dart:convert';

/// 셀럽 피드 모델
/// 
/// WP-3.5: 셀럽 피드 작성
/// 
/// Supabase의 feeds 테이블과 연동되는 피드 정보를 나타냅니다.
class CelebrityFeedModel {
  final String id;
  final String celebrityId;
  final String content;
  final List<String> imageUrls; // 여러 이미지 URL
  final DateTime createdAt;
  final DateTime updatedAt;

  CelebrityFeedModel({
    required this.id,
    required this.celebrityId,
    required this.content,
    this.imageUrls = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Supabase에서 받은 데이터로부터 CelebrityFeedModel 생성
  /// 
  /// [json]: Supabase에서 받은 피드 데이터
  factory CelebrityFeedModel.fromJson(Map<String, dynamic> json) {
    // image_urls는 JSONB 배열이므로 파싱 필요
    List<String> imageUrls = [];
    if (json['image_urls'] != null) {
      final imageUrlsData = json['image_urls'];
      if (imageUrlsData is List) {
        imageUrls = imageUrlsData.map((url) => url.toString()).toList();
      } else if (imageUrlsData is String) {
        // JSON 문자열인 경우 파싱
        try {
          final decoded = jsonDecode(imageUrlsData) as List;
          imageUrls = decoded.map((url) => url.toString()).toList();
        } catch (e) {
          print('⚠️ 이미지 URL 파싱 실패: $e');
        }
      }
    }

    return CelebrityFeedModel(
      id: json['id'] as String,
      celebrityId: json['celebrity_id'] as String,
      content: json['content'] as String,
      imageUrls: imageUrls,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'celebrity_id': celebrityId,
      'content': content,
      'image_urls': imageUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// CelebrityFeedModel 복사 (일부 필드만 변경)
  CelebrityFeedModel copyWith({
    String? id,
    String? celebrityId,
    String? content,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CelebrityFeedModel(
      id: id ?? this.id,
      celebrityId: celebrityId ?? this.celebrityId,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

