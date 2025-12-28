import '../../../core/supabase_config.dart';
import '../../auth/models/user_model.dart';

/// 셀럽 서비스
/// 
/// WP-2.3: 셀럽 프로필 및 구독 시스템
/// 
/// Supabase의 users 테이블에서 셀럽 정보를 조회하는 서비스입니다.
class CelebrityService {
  /// 전체 셀럽 목록 조회 (구독자 수 포함)
  /// 
  /// [limit]: 조회할 셀럽 수 (기본값: 50)
  /// [offset]: 시작 위치 (기본값: 0)
  /// 
  /// Returns: 셀럽 목록과 각 셀럽의 구독자 수
  /// Throws: 셀럽 조회 실패 시
  static Future<List<CelebrityWithSubscriberCount>> getCelebrities({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final client = SupabaseConfig.client;

      // 셀럽 목록 조회
      final celebrities = await client
          .from('users')
          .select()
          .eq('role', 'celebrity')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final celebritiesList = (celebrities as List)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // 각 셀럽의 구독자 수 조회
      final result = <CelebrityWithSubscriberCount>[];
      for (final celebrity in celebritiesList) {
        try {
          final subscriberCount = await _getSubscriberCount(celebrity.id);
          result.add(CelebrityWithSubscriberCount(
            celebrity: celebrity,
            subscriberCount: subscriberCount,
          ));
        } catch (e) {
          print('⚠️ 셀럽 구독자 수 조회 실패 (${celebrity.id}): $e');
          // 구독자 수 조회 실패 시에도 셀럽 정보는 포함
          result.add(CelebrityWithSubscriberCount(
            celebrity: celebrity,
            subscriberCount: 0,
          ));
        }
      }

      print('✅ 셀럽 목록 조회 성공: ${result.length}개');
      return result;
    } catch (e) {
      print('❌ 셀럽 목록 조회 실패: $e');
      rethrow;
    }
  }

  /// 셀럽 프로필 상세 조회 (구독자 수 포함)
  /// 
  /// [celebrityId]: 셀럽 ID
  /// 
  /// Returns: 셀럽 프로필 정보와 구독자 수
  /// Throws: 셀럽 조회 실패 시
  static Future<CelebrityWithSubscriberCount?> getCelebrityProfile(
    String celebrityId,
  ) async {
    try {
      final client = SupabaseConfig.client;

      final response = await client
          .from('users')
          .select()
          .eq('id', celebrityId)
          .eq('role', 'celebrity')
          .maybeSingle();

      if (response != null) {
        final celebrity = UserModel.fromJson(response);
        final subscriberCount = await _getSubscriberCount(celebrityId);

        print('✅ 셀럽 프로필 조회 성공: $celebrityId (구독자: $subscriberCount명)');
        return CelebrityWithSubscriberCount(
          celebrity: celebrity,
          subscriberCount: subscriberCount,
        );
      }

      return null;
    } catch (e) {
      print('❌ 셀럽 프로필 조회 실패: $e');
      rethrow;
    }
  }

  /// 셀럽 검색 (이름으로 검색)
  /// 
  /// [query]: 검색어 (셀럽 이름)
  /// [limit]: 조회할 셀럽 수 (기본값: 20)
  /// 
  /// Returns: 검색된 셀럽 목록과 각 셀럽의 구독자 수
  /// Throws: 검색 실패 시
  static Future<List<CelebrityWithSubscriberCount>> searchCelebrities({
    required String query,
    int limit = 20,
  }) async {
    try {
      final client = SupabaseConfig.client;
      final searchQuery = query.trim();

      if (searchQuery.isEmpty) {
        return [];
      }

      // display_name으로만 검색 (이메일 검색 제거)
      final celebrities = await client
          .from('users')
          .select()
          .eq('role', 'celebrity')
          .ilike('display_name', '%$searchQuery%')
          .limit(limit);

      final celebritiesList = (celebrities as List)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // 각 셀럽의 구독자 수 조회
      final result = <CelebrityWithSubscriberCount>[];
      for (final celebrity in celebritiesList) {
        try {
          final subscriberCount = await _getSubscriberCount(celebrity.id);
          result.add(CelebrityWithSubscriberCount(
            celebrity: celebrity,
            subscriberCount: subscriberCount,
          ));
        } catch (e) {
          print('⚠️ 셀럽 구독자 수 조회 실패 (${celebrity.id}): $e');
          result.add(CelebrityWithSubscriberCount(
            celebrity: celebrity,
            subscriberCount: 0,
          ));
        }
      }

      print('✅ 셀럽 검색 성공: "$searchQuery" - ${result.length}개');
      return result;
    } catch (e) {
      print('❌ 셀럽 검색 실패: $e');
      rethrow;
    }
  }

  /// 셀럽의 구독자 수 조회
  /// 
  /// [celebrityId]: 셀럽 ID
  /// 
  /// Returns: 구독자 수
  static Future<int> _getSubscriberCount(String celebrityId) async {
    try {
      final client = SupabaseConfig.client;

      // 구독 목록을 조회하여 개수 계산
      final response = await client
          .from('subscriptions')
          .select('id')
          .eq('celebrity_id', celebrityId);

      final count = (response as List).length;
      return count;
    } catch (e) {
      print('⚠️ 구독자 수 조회 실패 ($celebrityId): $e');
      // 에러 발생 시 0 반환
      return 0;
    }
  }
}

/// 셀럽 정보와 구독자 수를 함께 담는 클래스
class CelebrityWithSubscriberCount {
  final UserModel celebrity;
  final int subscriberCount;

  CelebrityWithSubscriberCount({
    required this.celebrity,
    required this.subscriberCount,
  });
}

