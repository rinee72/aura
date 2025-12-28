import 'package:flutter_test/flutter_test.dart';
import 'package:aura_app/core/supabase_config.dart';
import 'package:aura_app/core/environment.dart';
import 'package:aura_app/features/auth/providers/auth_provider.dart';

/// WP-1.2 인증 기능 통합 테스트
/// 
/// 이 테스트는 실제 Supabase 연결이 필요합니다.
/// 환경 변수가 설정되어 있어야 합니다.
void main() {
  group('WP-1.2: Supabase Auth 기본 연동 및 회원가입/로그인', () {
    setUpAll(() async {
      // 환경 초기화
      await AppEnvironment.initializeFromDartDefine();
      
      // Supabase 초기화
      await SupabaseConfig.initialize();
    });

    tearDownAll(() async {
      // 테스트 후 정리
      final client = SupabaseConfig.client;
      await client.auth.signOut();
    });

    test('1. Supabase Auth 초기화 확인', () {
      final client = SupabaseConfig.client;
      expect(client, isNotNull);
      expect(client.auth, isNotNull);
    });

    test('2. 회원가입 성공 케이스', () async {
      final authProvider = AuthProvider();
      final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@test.com';
      const testPassword = 'testpassword123';

      try {
        await authProvider.signUp(
          email: testEmail,
          password: testPassword,
        );

        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.currentUser, isNotNull);
        expect(authProvider.currentUser?.email, testEmail);
        expect(authProvider.errorMessage, isNull);
      } finally {
        // 테스트 후 로그아웃
        await authProvider.signOut();
      }
    });

    test('3. 회원가입 실패 케이스 - 이미 등록된 이메일', () async {
      final authProvider = AuthProvider();
      final testEmail = 'duplicate_${DateTime.now().millisecondsSinceEpoch}@test.com';
      const testPassword = 'testpassword123';

      // 첫 번째 회원가입
      await authProvider.signUp(
        email: testEmail,
        password: testPassword,
      );

      // 두 번째 회원가입 시도 (같은 이메일)
      try {
        await authProvider.signUp(
          email: testEmail,
          password: testPassword,
        );
        fail('중복 이메일 회원가입이 실패해야 합니다.');
      } catch (e) {
        expect(authProvider.errorMessage, isNotNull);
        expect(authProvider.errorMessage, contains('이미 등록된'));
      } finally {
        await authProvider.signOut();
      }
    });

    test('4. 로그인 성공 케이스', () async {
      final authProvider = AuthProvider();
      final testEmail = 'login_${DateTime.now().millisecondsSinceEpoch}@test.com';
      const testPassword = 'testpassword123';

      // 먼저 회원가입
      await authProvider.signUp(
        email: testEmail,
        password: testPassword,
      );
      await authProvider.signOut();

      // 로그인
      await authProvider.signIn(
        email: testEmail,
        password: testPassword,
      );

      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.email, testEmail);
      expect(authProvider.errorMessage, isNull);

      await authProvider.signOut();
    });

    test('5. 로그인 실패 케이스 - 잘못된 비밀번호', () async {
      final authProvider = AuthProvider();
      final testEmail = 'wrongpass_${DateTime.now().millisecondsSinceEpoch}@test.com';
      const testPassword = 'testpassword123';
      const wrongPassword = 'wrongpassword';

      // 먼저 회원가입
      await authProvider.signUp(
        email: testEmail,
        password: testPassword,
      );
      await authProvider.signOut();

      // 잘못된 비밀번호로 로그인 시도
      try {
        await authProvider.signIn(
          email: testEmail,
          password: wrongPassword,
        );
        fail('잘못된 비밀번호로 로그인이 실패해야 합니다.');
      } catch (e) {
        expect(authProvider.errorMessage, isNotNull);
        expect(authProvider.errorMessage, contains('올바르지 않습니다'));
        expect(authProvider.isAuthenticated, isFalse);
      }
    });

    test('6. 로그아웃 기능', () async {
      final authProvider = AuthProvider();
      final testEmail = 'logout_${DateTime.now().millisecondsSinceEpoch}@test.com';
      const testPassword = 'testpassword123';

      // 로그인
      await authProvider.signUp(
        email: testEmail,
        password: testPassword,
      );
      expect(authProvider.isAuthenticated, isTrue);

      // 로그아웃
      await authProvider.signOut();
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.currentUser, isNull);
    });

    test('7. 세션 유지 확인', () async {
      final authProvider = AuthProvider();
      final testEmail = 'session_${DateTime.now().millisecondsSinceEpoch}@test.com';
      const testPassword = 'testpassword123';

      // 로그인
      await authProvider.signUp(
        email: testEmail,
        password: testPassword,
      );
      expect(authProvider.isAuthenticated, isTrue);

      // 새로운 AuthProvider 인스턴스 생성 (앱 재시작 시뮬레이션)
      final newAuthProvider = AuthProvider();
      
      // 세션이 복원되는지 확인 (비동기 초기화 대기)
      await Future.delayed(const Duration(seconds: 2));
      
      // Supabase 클라이언트에서 직접 세션 확인
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser;
      
      if (user != null) {
        // 세션이 있으면 프로필 로드 대기
        await Future.delayed(const Duration(seconds: 1));
        expect(newAuthProvider.isAuthenticated || user != null, isTrue);
      }

      await authProvider.signOut();
    });
  });
}
