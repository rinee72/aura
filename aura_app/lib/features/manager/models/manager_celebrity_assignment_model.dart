/// 매니저-셀럽 담당 관계 모델
/// 
/// WP-4.2 확장: 매니저-셀럽 관계 명시적 관리
/// 
/// Supabase의 manager_celebrity_assignments 테이블과 연동되는 담당 관계 정보를 나타냅니다.
class ManagerCelebrityAssignmentModel {
  final String id;
  final String managerId;
  final String celebrityId;
  final DateTime assignedAt;
  final String? assignedBy;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ManagerCelebrityAssignmentModel({
    required this.id,
    required this.managerId,
    required this.celebrityId,
    required this.assignedAt,
    this.assignedBy,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Supabase에서 받은 데이터로부터 ManagerCelebrityAssignmentModel 생성
  /// 
  /// [json]: Supabase에서 받은 담당 관계 데이터
  factory ManagerCelebrityAssignmentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ManagerCelebrityAssignmentModel(
      id: json['id'] as String,
      managerId: json['manager_id'] as String,
      celebrityId: json['celebrity_id'] as String,
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      assignedBy: json['assigned_by'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'manager_id': managerId,
      'celebrity_id': celebrityId,
      'assigned_at': assignedAt.toIso8601String(),
      'assigned_by': assignedBy,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// ManagerCelebrityAssignmentModel 복사 (일부 필드만 변경)
  ManagerCelebrityAssignmentModel copyWith({
    String? id,
    String? managerId,
    String? celebrityId,
    DateTime? assignedAt,
    String? assignedBy,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ManagerCelebrityAssignmentModel(
      id: id ?? this.id,
      managerId: managerId ?? this.managerId,
      celebrityId: celebrityId ?? this.celebrityId,
      assignedAt: assignedAt ?? this.assignedAt,
      assignedBy: assignedBy ?? this.assignedBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

