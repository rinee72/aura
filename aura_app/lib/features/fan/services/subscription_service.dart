import '../../../core/supabase_config.dart';
import '../../auth/models/user_model.dart';

/// 구독 서비스
/// 
/// WP-2.3: 셀럽 프로필 및 구독 시스템
/// 
/// Supabase의 subscriptions 테이블에서 구독 정보를 관리하는 서비스입니다.
class SubscriptionService {
  /// 셀럽 구독
  /// 
  /// [celebrityId]: 구독할 셀럽 ID
  /// 
  /// Returns: 구독 성공 여부
  /// Throws: 구독 실패 시
  static Future<bool> subscribe(String celebrityId) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 자기 자신 구독 방지 (DB CHECK 제약조건으로도 방지되지만 클라이언트에서도 확인)
      if (currentUser.id == celebrityId) {
        throw Exception('자기 자신을 구독할 수 없습니다.');
      }

      // 구독 생성 (UNIQUE 제약조건으로 중복 방지)
      await client.from('subscriptions').insert({
        'fan_id': currentUser.id,
        'celebrity_id': celebrityId,
      });

      print('✅ 구독 성공: $celebrityId');
      return true;
    } catch (e) {
      // 중복 구독 시 에러는 조용히 무시 (이미 구독 중)
      if (e.toString().contains('duplicate') || 
          e.toString().contains('unique constraint')) {
        print('ℹ️ 이미 구독 중인 셀럽입니다: $celebrityId');
        return true;
      }
      print('❌ 구독 실패: $e');
      rethrow;
    }
  }

  /// 셀럽 구독 취소
  /// 
  /// [celebrityId]: 구독 취소할 셀럽 ID
  /// 
  /// Returns: 구독 취소 성공 여부
  /// Throws: 구독 취소 실패 시
  static Future<bool> unsubscribe(String celebrityId) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      await client
          .from('subscriptions')
          .delete()
          .eq('fan_id', currentUser.id)
          .eq('celebrity_id', celebrityId);

      print('✅ 구독 취소 성공: $celebrityId');
      return true;
    } catch (e) {
      print('❌ 구독 취소 실패: $e');
      rethrow;
    }
  }

  /// 구독 상태 확인
  /// 
  /// [celebrityId]: 셀럽 ID
  /// 
  /// Returns: 구독 중이면 true, 아니면 false
  static Future<bool> isSubscribed(String celebrityId) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        return false;
      }

      final response = await client
          .from('subscriptions')
          .select('id')
          .eq('fan_id', currentUser.id)
          .eq('celebrity_id', celebrityId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('⚠️ 구독 상태 확인 실패: $e');
      return false;
    }
  }

  /// 내 구독 목록 조회
  /// 
  /// Returns: 구독한 셀럽 목록
  /// Throws: 구독 목록 조회 실패 시
  static Future<List<UserModel>> getMySubscriptions() async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 구독한 셀럽 정보 조회 (JOIN 사용)
      // subscriptions 테이블의 celebrity_id가 users 테이블의 id를 참조합니다
      final response = await client
          .from('subscriptions')
          .select('celebrity_id, users!celebrity_id(*)')
          .eq('fan_id', currentUser.id);

      final subscriptions = <UserModel>[];
      for (final item in response as List) {
        final data = item as Map<String, dynamic>;
        final usersData = data['users'] as Map<String, dynamic>?;
        
        if (usersData != null) {
          subscriptions.add(UserModel.fromJson(usersData));
        }
      }

      print('✅ 내 구독 목록 조회 성공: ${subscriptions.length}개');
      return subscriptions;
    } catch (e) {
      print('❌ 내 구독 목록 조회 실패: $e');
      rethrow;
    }
  }

  /// 구독한 셀럽 ID 목록 조회 (간단한 버전)
  /// 
  /// Returns: 구독한 셀럽 ID 목록
  static Future<Set<String>> getMySubscribedCelebrityIds() async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        return {};
      }

      final response = await client
          .from('subscriptions')
          .select('celebrity_id')
          .eq('fan_id', currentUser.id);

      final celebrityIds = (response as List)
          .map((item) => (item as Map<String, dynamic>)['celebrity_id'] as String)
          .toSet();

      return celebrityIds;
    } catch (e) {
      print('⚠️ 구독한 셀럽 ID 목록 조회 실패: $e');
      return {};
    }
  }

  /// 셀럽의 구독자 수 조회
  /// 
  /// [celebrityId]: 셀럽 ID
  /// 
  /// Returns: 구독자 수
  /// Throws: 구독자 수 조회 실패 시
  static Future<int> getSubscriberCount(String celebrityId) async {
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

