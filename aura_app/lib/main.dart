import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/supabase_config.dart';
import 'core/environment.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/providers/auth_provider.dart';

/// WP-0.4: 환경 분리 시스템 통합
/// 
/// 앱 실행 시 dart-define으로 전달된 환경 값에 따라 적절한 설정을 로드합니다.
/// 
/// 사용법:
/// ```bash
/// # 개발 환경
/// flutter run --dart-define=ENVIRONMENT=development
/// 
/// # 스테이징 환경
/// flutter run --dart-define=ENVIRONMENT=staging
/// 
/// # 프로덕션 환경
/// flutter run --dart-define=ENVIRONMENT=production
/// ```
void main() async {
  // Flutter 바인딩 초기화 (비동기 작업 전 필수)
  WidgetsFlutterBinding.ensureInitialized();
  
  // WP-0.4: 환경 초기화 (dart-define에서 환경 값 읽기)
  try {
    await AppEnvironment.initializeFromDartDefine();
    print('✅ 환경 설정 완료: ${AppEnvironment.environmentName}');
  } catch (e) {
    print('⚠️ 환경 초기화 실패: $e');
    print('   기본 환경(development)을 사용합니다.');
    // 기본 환경으로 계속 진행
  }
  
  // 에러 처리: Supabase 초기화 실패 시 앱 크래시 방지
  try {
    // Supabase 초기화 (환경별 설정 사용)
    await SupabaseConfig.initialize();
    
    // 연결 테스트 (Health Check)
    final isConnected = await SupabaseConfig.checkConnection();
    
    if (isConnected) {
      print('✅ Supabase 연결 테스트 성공');
      print('   환경: ${AppEnvironment.environmentName}');
      print('   WP-0.2 Scenario 0.2-11: 연결 성공 검증 완료');
      print('   WP-0.4: 환경별 연결 확인 완료');
    } else {
      print('⚠️ Supabase 연결 테스트 실패 - 앱은 계속 실행됩니다');
      print('   환경: ${AppEnvironment.environmentName}');
      
      // 상세한 연결 상태 확인
      final connectionStatus = await SupabaseConfig.checkConnectionDetailed();
      print('   연결 상태 상세: ${connectionStatus.toString()}');
      
      if (connectionStatus.isNetworkError) {
        print('   ⚠️ 네트워크 오류가 감지되었습니다.');
        print('   해결 방법:');
        print('   1. 인터넷 연결 확인');
        print('   2. VPN 설정 확인');
        print('   3. 방화벽 설정 확인');
        print('   4. Supabase 프로젝트 상태 확인');
        print('   5. 환경별 설정 파일 확인 (.env.${AppEnvironment.environmentName})');
      }
    }
  } on SupabaseConfigException catch (e) {
    // 환경 변수 오류 등 설정 관련 에러
    print('❌ Supabase 설정 오류: $e');
    print('⚠️ 환경별 설정 파일을 확인하세요.');
    print('   환경: ${AppEnvironment.environmentName}');
    print('   설정 파일: .env.${AppEnvironment.environmentName}');
    print('   또는 기본 .env 파일을 사용할 수 있습니다.');
    print('   WP-0.2 Scenario 0.2-10: 환경 변수 없음 실패 케이스 검증');
    // 개발 환경에서는 앱을 계속 실행 (프로덕션에서는 다르게 처리 가능)
  } catch (e, stackTrace) {
    // 기타 예외
    print('❌ Supabase 초기화 중 예상치 못한 오류: $e');
    print('   스택 트레이스: $stackTrace');
    print('⚠️ 앱은 계속 실행되지만 Supabase 기능은 사용할 수 없습니다.');
  }
  
  // 시스템 UI 오버레이 스타일 설정 (선택사항)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // WP-0.4: 환경별 앱 제목 사용
    final appTitle = AppEnvironment.appTitle;
    
    // WP-1.2: AuthProvider를 전역으로 제공
    // WP-1.4: Go Router를 사용한 역할 기반 라우팅
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      builder: (context, _) {
        // AuthProvider 인스턴스 가져오기
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        // Go Router 생성 (한 번만 생성, refreshListenable로 등록)
        final router = AppRouter.createRouter(authProvider);
        
        return MaterialApp.router(
          title: appTitle,
          // WP-0.5: 디자인 시스템 테마 적용
          theme: AppTheme.lightTheme,
          routerConfig: router,
        );
      },
    );
  }
}

