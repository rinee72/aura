import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_config.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/user_service.dart';
import '../../../shared/utils/permission_checker.dart';

/// 팬 프로필 서비스
/// 
/// 팬이 자신의 프로필 정보를 관리할 수 있는 서비스입니다.
class FanProfileService {
  /// 내 프로필 조회
  /// 
  /// Returns: 현재 사용자의 프로필 정보
  /// Throws: 권한 없음, 프로필 조회 실패 시
  static Future<UserModel> getMyProfile() async {
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

      // 권한 검증: 팬만 프로필 관리 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleFan);
      } catch (e) {
        throw Exception('프로필 관리는 팬만 가능합니다.');
      }

      print('✅ 프로필 조회 성공: ${user.id}');
      return user;
    } catch (e) {
      print('❌ 프로필 조회 실패: $e');
      rethrow;
    }
  }

  /// 프로필 정보 수정
  /// 
  /// [displayName]: 표시 이름 (선택)
  /// [bio]: 자기소개 (선택)
  /// 
  /// Returns: 수정된 프로필 정보
  /// Throws: 권한 없음, 프로필 수정 실패 시
  static Future<UserModel> updateProfile({
    String? displayName,
    String? bio,
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

      // 권한 검증: 팬만 프로필 수정 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleFan);
      } catch (e) {
        throw Exception('프로필 수정은 팬만 가능합니다.');
      }

      // 프로필 업데이트
      await UserService.updateUserProfile(
        userId: user.id,
        displayName: displayName,
        bio: bio,
      );

      // 업데이트된 프로필 조회
      final updatedResponse = await client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      final updatedUser = UserModel.fromJson(updatedResponse);

      print('✅ 프로필 수정 성공: ${updatedUser.id}');
      return updatedUser;
    } catch (e) {
      print('❌ 프로필 수정 실패: $e');
      rethrow;
    }
  }

  /// 프로필 이미지 업로드
  /// 
  /// [imageFile]: 업로드할 이미지 파일
  /// 
  /// Returns: 업로드된 이미지의 공개 URL
  /// Throws: 권한 없음, 이미지 업로드 실패 시
  static Future<String> updateProfileImage(File imageFile) async {
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

      // 권한 검증: 팬만 프로필 이미지 업로드 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleFan);
      } catch (e) {
        throw Exception('프로필 이미지 업로드는 팬만 가능합니다.');
      }

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
      // 경로: avatars/{userId}.{extension}
      final fileExtension = fileName.split('.').last;
      final storagePath = '${user.id}.$fileExtension';

      // 기존 이미지가 있으면 삭제
      try {
        final existingFiles = await client.storage
            .from('avatars')
            .list();
        
        // 같은 사용자의 기존 이미지 찾기 및 삭제
        for (final file in existingFiles) {
          if (file.name.startsWith('${user.id}.')) {
            await client.storage
                .from('avatars')
                .remove([file.name]);
          }
        }
      } catch (e) {
        // 기존 이미지가 없거나 삭제 실패해도 계속 진행
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
              cacheControl: '3600',
            ),
          );

      // 공개 URL 생성
      final publicUrl = client.storage
          .from('avatars')
          .getPublicUrl(storagePath);

      // 프로필에 이미지 URL 업데이트
      await UserService.updateUserProfile(
        userId: user.id,
        avatarUrl: publicUrl,
      );

      print('✅ 프로필 이미지 업로드 성공: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ 프로필 이미지 업로드 실패: $e');
      rethrow;
    }
  }

  /// 프로필 이미지 삭제
  /// 
  /// Returns: 삭제 성공 여부
  /// Throws: 권한 없음, 이미지 삭제 실패 시
  static Future<void> deleteProfileImage() async {
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

      // 권한 검증: 팬만 프로필 이미지 삭제 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleFan);
      } catch (e) {
        throw Exception('프로필 이미지 삭제는 팬만 가능합니다.');
      }

      // Supabase Storage에서 이미지 삭제
      try {
        final existingFiles = await client.storage
            .from('avatars')
            .list();
        
        // 같은 사용자의 이미지 찾기 및 삭제
        for (final file in existingFiles) {
          if (file.name.startsWith('${user.id}.')) {
            await client.storage
                .from('avatars')
                .remove([file.name]);
            print('✅ Storage에서 이미지 삭제 성공: ${file.name}');
          }
        }
      } catch (e) {
        // 이미지가 없거나 삭제 실패해도 계속 진행 (DB 업데이트는 수행)
        print('⚠️ Storage 이미지 삭제 실패 (무시): $e');
      }

      // 프로필에서 이미지 URL 제거 (null로 명시적으로 설정)
      await client
          .from('users')
          .update({
            'avatar_url': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      print('✅ 프로필 이미지 삭제 성공: ${user.id}');
    } catch (e) {
      print('❌ 프로필 이미지 삭제 실패: $e');
      rethrow;
    }
  }
}

