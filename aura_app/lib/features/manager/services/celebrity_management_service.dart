import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_config.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/user_service.dart';
import '../../../shared/utils/permission_checker.dart';
import '../../fan/services/subscription_service.dart';

/// 셀럽 계정 관리 서비스
/// 
/// WP-4.4: 셀럽 계정 관리
/// 
/// 매니저가 셀럽 계정을 관리하고 프로필을 수정할 수 있는 서비스입니다.
class CelebrityManagementService {
  /// 모든 셀럽 목록 조회
  /// 
  /// [limit]: 조회할 셀럽 수 (기본값: 50)
  /// [offset]: 시작 위치 (기본값: 0)
  /// [searchQuery]: 검색어 (이름, 이메일) (선택)
  /// [sortBy]: 정렬 기준 ('name', 'subscribers', 'recent_activity') (기본값: 'name')
  /// [orderBy]: 정렬 순서 ('asc', 'desc') (기본값: 'asc')
  /// 
  /// Returns: 셀럽 목록 (통계 정보 포함)
  /// Throws: 권한 없음, 조회 실패 시
  static Future<List<CelebrityWithStats>> getAllCelebrities({
    int limit = 50,
    int offset = 0,
    String? searchQuery,
    String sortBy = 'name',
    String orderBy = 'asc',
  }) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 현재 사용자 정보 조회
      final userResponse = await client
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final user = UserModel.fromJson(userResponse);

      // 권한 검증: 매니저만 셀럽 목록 조회 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('셀럽 목록 조회는 매니저만 가능합니다.');
      }

      // 쿼리 구성
      dynamic query = client
          .from('users')
          .select()
          .eq('role', 'celebrity');

      // 검색 필터 적용 (클라이언트 사이드 필터링으로 변경)
      // Supabase의 or() 필터가 불안정할 수 있으므로, 더 넓은 범위에서 조회 후 클라이언트에서 필터링
      final search = searchQuery?.trim();
      if (search != null && search.isNotEmpty) {
        // 검색어가 있으면 더 넓은 범위에서 조회 (클라이언트 사이드 필터링을 위해)
        // display_name 또는 email에 검색어가 포함된 경우를 찾기 위해
        // 일단 더 많은 데이터를 가져온 후 필터링
        final fetchLimit = limit * 3; // 검색 시 더 넓은 범위 조회
        query = query.range(0, offset + fetchLimit - 1);
      } else {
        query = query.range(offset, offset + limit - 1);
      }

      // 정렬 적용
      if (sortBy == 'name') {
        query = query.order('display_name', ascending: orderBy == 'asc');
      } else if (sortBy == 'subscribers') {
        // 구독자 수는 클라이언트에서 정렬 (서버 사이드 정렬은 복잡함)
        query = query.order('created_at', ascending: false);
      } else if (sortBy == 'recent_activity') {
        query = query.order('updated_at', ascending: orderBy == 'asc');
      } else {
        query = query.order('display_name', ascending: true);
      }

      final response = await query;
      final celebritiesData = response as List;

      // 각 셀럽의 통계 정보 조회
      var result = <CelebrityWithStats>[];
      for (final celebrityJson in celebritiesData) {
        final celebrity = UserModel.fromJson(celebrityJson as Map<String, dynamic>);
        
        // 검색 필터링 (클라이언트 사이드)
        if (search != null && search.isNotEmpty) {
          final displayName = (celebrity.displayName ?? '').toLowerCase();
          final email = celebrity.email.toLowerCase();
          final searchLower = search.toLowerCase();
          
          if (!displayName.contains(searchLower) && !email.contains(searchLower)) {
            continue; // 검색어와 일치하지 않으면 제외
          }
        }
        
        try {
          final stats = await getCelebrityStats(celebrity.id);
          result.add(CelebrityWithStats(
            celebrity: celebrity,
            stats: stats,
          ));
        } catch (e) {
          print('⚠️ 셀럽 통계 조회 실패 (${celebrity.id}): $e');
          // 통계 조회 실패 시에도 셀럽 정보는 포함
          result.add(CelebrityWithStats(
            celebrity: celebrity,
            stats: CelebrityStats(
              subscriberCount: 0,
              answerCount: 0,
              feedCount: 0,
              lastActivityAt: celebrity.updatedAt,
            ),
          ));
        }
      }

      // 구독자 수 기준 정렬 (서버 사이드 정렬이 필요한 경우)
      if (sortBy == 'subscribers') {
        result.sort((a, b) {
          final comparison = a.stats.subscriberCount.compareTo(b.stats.subscriberCount);
          return orderBy == 'asc' ? comparison : -comparison;
        });
      }

      // 검색 필터링 후 페이지네이션 적용
      if (search != null && search.isNotEmpty) {
        // offset과 limit 적용
        final startIndex = offset;
        final endIndex = offset + limit;
        if (startIndex < result.length) {
          result = result.sublist(
            startIndex,
            endIndex > result.length ? result.length : endIndex,
          );
        } else {
          result = [];
        }
      }

      print('✅ 셀럽 목록 조회 성공: ${result.length}개');
      return result;
    } catch (e) {
      print('❌ 셀럽 목록 조회 실패: $e');
      rethrow;
    }
  }

  /// 특정 셀럽 프로필 조회
  /// 
  /// [celebrityId]: 셀럽 ID
  /// 
  /// Returns: 셀럽 프로필 정보와 통계
  /// Throws: 권한 없음, 셀럽 조회 실패 시
  static Future<CelebrityWithStats?> getCelebrityProfile(String celebrityId) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 현재 사용자 정보 조회
      final userResponse = await client
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final user = UserModel.fromJson(userResponse);

      // 권한 검증: 매니저만 셀럽 프로필 조회 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('셀럽 프로필 조회는 매니저만 가능합니다.');
      }

      // 셀럽 정보 조회
      final celebrityResponse = await client
          .from('users')
          .select()
          .eq('id', celebrityId)
          .eq('role', 'celebrity')
          .maybeSingle();

      if (celebrityResponse == null) {
        return null;
      }

      final celebrity = UserModel.fromJson(celebrityResponse);
      final stats = await getCelebrityStats(celebrityId);

      print('✅ 셀럽 프로필 조회 성공: $celebrityId');
      return CelebrityWithStats(
        celebrity: celebrity,
        stats: stats,
      );
    } catch (e) {
      print('❌ 셀럽 프로필 조회 실패: $e');
      rethrow;
    }
  }

  /// 셀럽 프로필 수정
  /// 
  /// [celebrityId]: 셀럽 ID
  /// [displayName]: 표시 이름 (선택)
  /// [bio]: 자기소개 (선택)
  /// [avatarUrl]: 프로필 이미지 URL (선택)
  /// 
  /// Returns: 수정된 셀럽 프로필 정보
  /// Throws: 권한 없음, 프로필 수정 실패 시
  static Future<UserModel> updateCelebrityProfile({
    required String celebrityId,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 현재 사용자 정보 조회
      final userResponse = await client
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final user = UserModel.fromJson(userResponse);

      // 권한 검증: 매니저만 셀럽 프로필 수정 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('셀럽 프로필 수정은 매니저만 가능합니다.');
      }

      // 셀럽 존재 여부 확인
      final celebrityResponse = await client
          .from('users')
          .select()
          .eq('id', celebrityId)
          .eq('role', 'celebrity')
          .maybeSingle();

      if (celebrityResponse == null) {
        throw Exception('셀럽을 찾을 수 없습니다.');
      }

      // 프로필 업데이트
      await UserService.updateUserProfile(
        userId: celebrityId,
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      // 업데이트된 프로필 조회
      final updatedResponse = await client
          .from('users')
          .select()
          .eq('id', celebrityId)
          .single();

      final updatedCelebrity = UserModel.fromJson(updatedResponse);

      print('✅ 셀럽 프로필 수정 성공: $celebrityId');
      return updatedCelebrity;
    } catch (e) {
      print('❌ 셀럽 프로필 수정 실패: $e');
      rethrow;
    }
  }

  /// 셀럽 프로필 이미지 업로드
  /// 
  /// [celebrityId]: 셀럽 ID
  /// [imageFile]: 업로드할 이미지 파일
  /// 
  /// Returns: 업로드된 이미지의 공개 URL
  /// Throws: 권한 없음, 이미지 업로드 실패 시
  static Future<String> updateCelebrityProfileImage({
    required String celebrityId,
    required File imageFile,
  }) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 현재 사용자 정보 조회
      final userResponse = await client
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final user = UserModel.fromJson(userResponse);

      // 권한 검증: 매니저만 셀럽 프로필 이미지 업로드 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('셀럽 프로필 이미지 업로드는 매니저만 가능합니다.');
      }

      // 셀럽 존재 여부 확인
      final celebrityResponse = await client
          .from('users')
          .select()
          .eq('id', celebrityId)
          .eq('role', 'celebrity')
          .maybeSingle();

      if (celebrityResponse == null) {
        throw Exception('셀럽을 찾을 수 없습니다.');
      }

      // CelebrityProfileService의 이미지 업로드 로직 재사용
      // 하지만 권한 검증을 우회하기 위해 직접 구현
      // 이미지 크기 제한 (5MB)
      final fileSize = await imageFile.length();
      const maxSize = 5 * 1024 * 1024; // 5MB
      if (fileSize > maxSize) {
        throw Exception('이미지 크기는 5MB 이하여야 합니다.');
      }

      // 파일 확장자 확인
      final fileName = imageFile.path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
        throw Exception('지원하지 않는 이미지 형식입니다. (jpg, jpeg, png, gif, webp만 가능)');
      }

      // Supabase Storage에 업로드
      final fileExtension = fileName.split('.').last;
      final storagePath = '$celebrityId.$fileExtension';

      // 기존 이미지가 있으면 삭제
      try {
        final existingFiles = await client.storage
            .from('avatars')
            .list();
        
        for (final file in existingFiles) {
          if (file.name.startsWith('$celebrityId.')) {
            await client.storage
                .from('avatars')
                .remove([file.name]);
          }
        }
      } catch (e) {
        print('⚠️ 기존 이미지 삭제 실패 (무시): $e');
      }

      // 새 이미지 업로드
      await client.storage
          .from('avatars')
          .upload(
            storagePath,
            imageFile,
            fileOptions: const FileOptions(
              upsert: true,
            ),
          );

      // 공개 URL 가져오기
      final publicUrl = client.storage
          .from('avatars')
          .getPublicUrl(storagePath);

      // 프로필에 이미지 URL 업데이트
      await UserService.updateUserProfile(
        userId: celebrityId,
        avatarUrl: publicUrl,
      );

      print('✅ 셀럽 프로필 이미지 업로드 성공: $celebrityId');
      return publicUrl;
    } catch (e) {
      print('❌ 셀럽 프로필 이미지 업로드 실패: $e');
      rethrow;
    }
  }

  /// 셀럽 프로필 이미지 삭제
  /// 
  /// [celebrityId]: 셀럽 ID
  /// 
  /// Throws: 권한 없음, 이미지 삭제 실패 시
  static Future<void> deleteCelebrityProfileImage(String celebrityId) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 현재 사용자 정보 조회
      final userResponse = await client
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final user = UserModel.fromJson(userResponse);

      // 권한 검증: 매니저만 셀럽 프로필 이미지 삭제 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('셀럽 프로필 이미지 삭제는 매니저만 가능합니다.');
      }

      // Storage에서 이미지 삭제
      try {
        final existingFiles = await client.storage
            .from('avatars')
            .list();
        
        for (final file in existingFiles) {
          if (file.name.startsWith('$celebrityId.')) {
            await client.storage
                .from('avatars')
                .remove([file.name]);
          }
        }
      } catch (e) {
        print('⚠️ 이미지 삭제 실패 (무시): $e');
      }

      // 프로필에서 이미지 URL 제거
      await UserService.updateUserProfile(
        userId: celebrityId,
        avatarUrl: null,
      );

      print('✅ 셀럽 프로필 이미지 삭제 성공: $celebrityId');
    } catch (e) {
      print('❌ 셀럽 프로필 이미지 삭제 실패: $e');
      rethrow;
    }
  }

  /// 셀럽 통계 조회
  /// 
  /// [celebrityId]: 셀럽 ID
  /// 
  /// Returns: 셀럽 통계 정보 (구독자 수, 답변 수, 피드 수, 최근 활동 일시)
  /// Throws: 통계 조회 실패 시
  static Future<CelebrityStats> getCelebrityStats(String celebrityId) async {
    try {
      final client = SupabaseConfig.client;

      // 구독자 수 조회
      int subscriberCount = 0;
      try {
        subscriberCount = await SubscriptionService.getSubscriberCount(celebrityId);
      } catch (e) {
        print('⚠️ 구독자 수 조회 실패: $e');
      }

      // 답변 수 조회
      int answerCount = 0;
      try {
        final answersResponse = await client
            .from('answers')
            .select('id')
            .eq('celebrity_id', celebrityId);
        answerCount = (answersResponse as List).length;
      } catch (e) {
        print('⚠️ 답변 수 조회 실패: $e');
      }

      // 피드 수 조회
      int feedCount = 0;
      try {
        final feedsResponse = await client
            .from('feeds')
            .select('id')
            .eq('celebrity_id', celebrityId);
        feedCount = (feedsResponse as List).length;
      } catch (e) {
        print('⚠️ 피드 수 조회 실패: $e');
      }

      // 최근 활동 일시 조회 (답변 또는 피드 중 가장 최근)
      DateTime? lastActivityAt;
      try {
        // 최근 답변 일시
        final recentAnswerResponse = await client
            .from('answers')
            .select('created_at')
            .eq('celebrity_id', celebrityId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        // 최근 피드 일시
        final recentFeedResponse = await client
            .from('feeds')
            .select('created_at')
            .eq('celebrity_id', celebrityId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        DateTime? answerDate;
        DateTime? feedDate;

        if (recentAnswerResponse != null) {
          answerDate = DateTime.parse(recentAnswerResponse['created_at'] as String);
        }
        if (recentFeedResponse != null) {
          feedDate = DateTime.parse(recentFeedResponse['created_at'] as String);
        }

        // 가장 최근 활동 일시 선택
        if (answerDate != null && feedDate != null) {
          lastActivityAt = answerDate.isAfter(feedDate) ? answerDate : feedDate;
        } else if (answerDate != null) {
          lastActivityAt = answerDate;
        } else if (feedDate != null) {
          lastActivityAt = feedDate;
        }

        // 활동이 없으면 프로필 업데이트 일시 사용
        if (lastActivityAt == null) {
          final userResponse = await client
              .from('users')
              .select('updated_at')
              .eq('id', celebrityId)
              .maybeSingle();
          if (userResponse != null) {
            lastActivityAt = DateTime.parse(userResponse['updated_at'] as String);
          }
        }
      } catch (e) {
        print('⚠️ 최근 활동 일시 조회 실패: $e');
      }

      return CelebrityStats(
        subscriberCount: subscriberCount,
        answerCount: answerCount,
        feedCount: feedCount,
        lastActivityAt: lastActivityAt,
      );
    } catch (e) {
      print('❌ 셀럽 통계 조회 실패: $e');
      rethrow;
    }
  }
}

/// 셀럽 정보와 통계를 함께 담는 클래스
class CelebrityWithStats {
  final UserModel celebrity;
  final CelebrityStats stats;

  CelebrityWithStats({
    required this.celebrity,
    required this.stats,
  });
}

/// 셀럽 통계 정보
class CelebrityStats {
  final int subscriberCount;
  final int answerCount;
  final int feedCount;
  final DateTime? lastActivityAt;

  CelebrityStats({
    required this.subscriberCount,
    required this.answerCount,
    required this.feedCount,
    this.lastActivityAt,
  });
}

