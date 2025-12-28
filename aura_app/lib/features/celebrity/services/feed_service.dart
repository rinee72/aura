import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_config.dart';
import '../models/celebrity_feed_model.dart';
import '../../auth/models/user_model.dart';
import '../../../shared/utils/permission_checker.dart';
import '../../../shared/utils/profanity_filter.dart';

/// 셀럽 피드 서비스
/// 
/// WP-3.5: 셀럽 피드 작성
/// 
/// 셀럽이 일반 피드를 작성하고 이미지를 업로드할 수 있는 서비스입니다.
class FeedService {
  /// 피드 생성
  /// 
  /// [content]: 피드 내용
  /// [imageFiles]: 업로드할 이미지 파일 목록 (최대 5개)
  /// 
  /// Returns: 생성된 피드
  /// Throws: 권한 없음, 피드 생성 실패 시
  static Future<CelebrityFeedModel> createFeed({
    required String content,
    List<File>? imageFiles,
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

      // 권한 검증: 셀럽만 피드 작성 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleCelebrity);
      } catch (e) {
        throw Exception('피드 작성은 셀럽만 가능합니다.');
      }

      // 욕설 필터링
      if (ProfanityFilter.containsProfanity(content)) {
        throw Exception('부적절한 내용이 포함되어 있습니다. 다시 작성해주세요.');
      }

      // 이미지 업로드 (있는 경우)
      List<String> imageUrls = [];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        // 최대 5개 제한
        if (imageFiles.length > 5) {
          throw Exception('이미지는 최대 5개까지 업로드할 수 있습니다.');
        }

        imageUrls = await uploadFeedImages(imageFiles, user.id);
      }

      // 피드 데이터 생성
      final feedData = <String, dynamic>{
        'celebrity_id': user.id,
        'content': content.trim(),
        'image_urls': imageUrls.isNotEmpty ? imageUrls : null,
      };

      final response = await client
          .from('feeds')
          .insert(feedData)
          .select()
          .single();

      final feed = CelebrityFeedModel.fromJson(response);
      print('✅ 피드 생성 성공: ${feed.id}');
      return feed;
    } catch (e) {
      print('❌ 피드 생성 실패: $e');
      rethrow;
    }
  }

  /// 피드 수정
  /// 
  /// [feedId]: 피드 ID
  /// [content]: 수정할 피드 내용
  /// [imageFiles]: 새로 업로드할 이미지 파일 목록 (기존 이미지와 교체)
  /// 
  /// Returns: 수정된 피드
  /// Throws: 권한 없음, 피드 수정 실패 시
  static Future<CelebrityFeedModel> updateFeed({
    required String feedId,
    required String content,
    List<File>? imageFiles,
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

      // 권한 검증: 셀럽만 피드 수정 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleCelebrity);
      } catch (e) {
        throw Exception('피드 수정은 셀럽만 가능합니다.');
      }

      // 기존 피드 조회 (작성자 확인)
      final existingFeed = await getFeedById(feedId);
      if (existingFeed == null) {
        throw Exception('피드를 찾을 수 없습니다.');
      }

      if (existingFeed.celebrityId != user.id) {
        throw Exception('자신의 피드만 수정할 수 있습니다.');
      }

      // 욕설 필터링
      if (ProfanityFilter.containsProfanity(content)) {
        throw Exception('부적절한 내용이 포함되어 있습니다. 다시 작성해주세요.');
      }

      // 이미지 URL 목록 구성
      // 기존 이미지 URL 유지 + 새로 업로드할 이미지
      List<String> imageUrls = List.from(existingFeed.imageUrls);

      // 새 이미지 업로드 (있는 경우)
      if (imageFiles != null && imageFiles.isNotEmpty) {
        // 최대 5개 제한 (기존 이미지 + 새 이미지 합계)
        if (imageUrls.length + imageFiles.length > 5) {
          throw Exception('이미지는 최대 5개까지 업로드할 수 있습니다. (현재: ${imageUrls.length}개, 추가: ${imageFiles.length}개)');
        }

        final newImageUrls = await uploadFeedImages(imageFiles, user.id);
        imageUrls.addAll(newImageUrls);
      }

      // 피드 데이터 업데이트
      final updateData = <String, dynamic>{
        'content': content.trim(),
        'image_urls': imageUrls.isNotEmpty ? imageUrls : null,
      };

      final response = await client
          .from('feeds')
          .update(updateData)
          .eq('id', feedId)
          .eq('celebrity_id', user.id) // 작성자만 수정 가능
          .select()
          .single();

      final feed = CelebrityFeedModel.fromJson(response);
      print('✅ 피드 수정 성공: ${feed.id}');
      return feed;
    } catch (e) {
      print('❌ 피드 수정 실패: $e');
      rethrow;
    }
  }

  /// 피드 삭제
  /// 
  /// [feedId]: 피드 ID
  /// 
  /// Throws: 권한 없음, 피드 삭제 실패 시
  static Future<void> deleteFeed(String feedId) async {
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

      // 권한 검증: 셀럽만 피드 삭제 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleCelebrity);
      } catch (e) {
        throw Exception('피드 삭제는 셀럽만 가능합니다.');
      }

      // 기존 피드 조회 (이미지 URL 확인)
      final existingFeed = await getFeedById(feedId);
      if (existingFeed == null) {
        throw Exception('피드를 찾을 수 없습니다.');
      }

      if (existingFeed.celebrityId != user.id) {
        throw Exception('자신의 피드만 삭제할 수 있습니다.');
      }

      // 이미지 삭제 (Storage에서)
      if (existingFeed.imageUrls.isNotEmpty) {
        try {
          await deleteFeedImages(existingFeed.imageUrls);
        } catch (e) {
          print('⚠️ 이미지 삭제 실패 (무시): $e');
        }
      }

      // 피드 삭제
      await client
          .from('feeds')
          .delete()
          .eq('id', feedId)
          .eq('celebrity_id', user.id); // 작성자만 삭제 가능

      print('✅ 피드 삭제 성공: $feedId');
    } catch (e) {
      print('❌ 피드 삭제 실패: $e');
      rethrow;
    }
  }

  /// 내 피드 목록 조회
  /// 
  /// [limit]: 조회할 피드 수 (기본값: 20)
  /// [offset]: 시작 위치 (기본값: 0)
  /// 
  /// Returns: 내 피드 목록
  /// Throws: 권한 없음, 피드 조회 실패 시
  static Future<List<CelebrityFeedModel>> getMyFeeds({
    int limit = 20,
    int offset = 0,
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

      // 권한 검증: 셀럽만 피드 조회 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleCelebrity);
      } catch (e) {
        throw Exception('피드 조회는 셀럽만 가능합니다.');
      }

      // 내 피드 목록 조회
      final response = await client
          .from('feeds')
          .select()
          .eq('celebrity_id', user.id)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final feedsData = response as List;
      final feeds = feedsData
          .map((json) => CelebrityFeedModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ 내 피드 목록 조회 성공: ${feeds.length}개');
      return feeds;
    } catch (e) {
      print('❌ 내 피드 목록 조회 실패: $e');
      rethrow;
    }
  }

  /// 피드 상세 조회
  /// 
  /// [feedId]: 피드 ID
  /// 
  /// Returns: 피드 정보 (없으면 null)
  /// Throws: 피드 조회 실패 시
  static Future<CelebrityFeedModel?> getFeedById(String feedId) async {
    try {
      final client = SupabaseConfig.client;

      final response = await client
          .from('feeds')
          .select()
          .eq('id', feedId)
          .maybeSingle();

      if (response != null) {
        return CelebrityFeedModel.fromJson(response);
      }

      return null;
    } catch (e) {
      print('❌ 피드 조회 실패: $e');
      rethrow;
    }
  }

  /// 피드 이미지 업로드
  /// 
  /// [imageFiles]: 업로드할 이미지 파일 목록
  /// [userId]: 사용자 ID (저장 경로에 사용)
  /// 
  /// Returns: 업로드된 이미지 URL 목록
  /// Throws: 이미지 업로드 실패 시
  static Future<List<String>> uploadFeedImages(
    List<File> imageFiles,
    String userId,
  ) async {
    try {
      final client = SupabaseConfig.client;
      final imageUrls = <String>[];

      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];

        // 이미지 크기 제한 (5MB)
        final fileSize = await imageFile.length();
        const maxSize = 5 * 1024 * 1024; // 5MB
        if (fileSize > maxSize) {
          throw Exception('이미지 크기는 5MB 이하여야 합니다. (${i + 1}번째 이미지)');
        }

        // 파일 확장자 확인
        final fileName = imageFile.path.split('/').last;
        final extension = fileName.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
          throw Exception('지원하지 않는 이미지 형식입니다. (jpg, jpeg, png, gif, webp만 가능)');
        }

        // Supabase Storage에 업로드
        // 경로: {userId}/{timestamp}_{index}.{extension}
        // 주의: .from('feeds')로 버킷을 지정했으므로 storagePath에는 버킷 이름을 포함하지 않음
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileExtension = fileName.split('.').last;
        final storagePath = '$userId/${timestamp}_$i.$fileExtension';

        await client.storage
            .from('feeds')
            .upload(
              storagePath,
              imageFile,
              fileOptions: const FileOptions(
                upsert: true,
                cacheControl: '3600',
              ),
            );

        // 공개 URL 생성
        final publicUrl = client.storage
            .from('feeds')
            .getPublicUrl(storagePath);

        imageUrls.add(publicUrl);
      }

      print('✅ 피드 이미지 업로드 성공: ${imageUrls.length}개');
      return imageUrls;
    } catch (e) {
      print('❌ 피드 이미지 업로드 실패: $e');
      rethrow;
    }
  }

  /// 피드 이미지 삭제
  /// 
  /// [imageUrls]: 삭제할 이미지 URL 목록
  /// 
  /// Throws: 이미지 삭제 실패 시
  static Future<void> deleteFeedImages(List<String> imageUrls) async {
    try {
      final client = SupabaseConfig.client;

      for (final imageUrl in imageUrls) {
        try {
          // URL에서 경로 추출
          // 예: https://xxx.supabase.co/storage/v1/object/public/feeds/xxx/xxx.jpg
          // -> feeds/xxx/xxx.jpg
          final uri = Uri.parse(imageUrl);
          final pathSegments = uri.pathSegments;
          
          // 'public' 다음의 경로 찾기
          final publicIndex = pathSegments.indexOf('public');
          if (publicIndex != -1 && publicIndex < pathSegments.length - 1) {
            final storagePath = pathSegments.sublist(publicIndex + 1).join('/');
            await client.storage
                .from('feeds')
                .remove([storagePath]);
          }
        } catch (e) {
          print('⚠️ 이미지 삭제 실패 (무시): $imageUrl - $e');
        }
      }

      print('✅ 피드 이미지 삭제 성공: ${imageUrls.length}개');
    } catch (e) {
      print('❌ 피드 이미지 삭제 실패: $e');
      rethrow;
    }
  }
}

