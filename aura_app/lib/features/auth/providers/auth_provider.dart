import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_config.dart';
import '../../../core/environment.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

/// 인증 상태를 관리하는 Provider
/// 
/// WP-1.2: Supabase Auth 기본 연동 및 회원가입/로그인
/// 
/// - 로그인 상태 관리
/// - 세션 유지
/// - 회원가입/로그인/로그아웃 기능
class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _pendingDisplayName; // 회원가입 시 입력한 이름 (역할 선택 화면에서 사용)

  /// 현재 로그인한 사용자
  UserModel? get currentUser => _currentUser;

  /// 로딩 중 여부
  bool get isLoading => _isLoading;

  /// 에러 메시지
  String? get errorMessage => _errorMessage;

  /// 로그인 상태
  bool get isAuthenticated => _currentUser != null;

  /// Supabase Auth의 현재 사용자
  User? get supabaseUser => SupabaseConfig.client.auth.currentUser;

  /// 회원가입 시 입력한 이름 (역할 선택 화면에서 사용)
  String? get pendingDisplayName => _pendingDisplayName;

  /// pendingDisplayName 초기화
  void clearPendingDisplayName() {
    _pendingDisplayName = null;
  }

  StreamSubscription<AuthState>? _authStateSubscription;

  AuthProvider() {
    _initializeAuth();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  /// 인증 상태 초기화
  /// 
  /// 앱 시작 시 세션을 확인하고, 유효한 세션이 있으면 사용자 정보를 로드합니다.
  /// WP-1.2: 세션 관리 및 JWT 기반 인증 상태 유지
  Future<void> _initializeAuth() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Supabase가 초기화되지 않았으면 초기화를 시도하지 않음
      if (!SupabaseConfig.isInitialized) {
        _errorMessage = 'Supabase가 초기화되지 않았습니다. '
            '.env.development 파일을 확인하고 Supabase 프로젝트 정보를 설정하세요.';
        print('⚠️ AuthProvider 초기화 스킵: Supabase가 초기화되지 않음');
        return;
      }

      final client = SupabaseConfig.client;
      
      // 세션 복원 확인 (Supabase Flutter는 자동으로 세션을 복원함)
      final user = client.auth.currentUser;

      if (user != null) {
        // 세션이 있으면 사용자 프로필 정보 로드
        await _loadUserProfile(user.id);
      }
    } catch (e) {
      _errorMessage = '인증 상태 초기화 중 오류가 발생했습니다: $e';
      print('❌ AuthProvider 초기화 오류: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Auth 상태 변경 리스너 등록 (Supabase가 초기화된 경우에만)
    if (SupabaseConfig.isInitialized) {
      try {
        _authStateSubscription ??= SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        print('🔐 Auth 상태 변경: $event');

        if (event == AuthChangeEvent.signedIn && session != null) {
          // 로그인 성공 시 사용자 프로필 로드
          // 비동기 작업이므로 await 없이 호출하되, 내부에서 에러 처리됨
          _loadUserProfile(session.user.id).catchError((error) {
            print('❌ 사용자 프로필 로드 오류 (onAuthStateChange): $error');
          });
          
          // OAuth 로그인 완료 시 로딩 상태 해제
          if (_isLoading) {
            _isLoading = false;
            notifyListeners();
          }
        } else if (event == AuthChangeEvent.signedOut) {
          // 로그아웃 시 상태 초기화
          _currentUser = null;
          _errorMessage = null;
          notifyListeners();
        } else if (event == AuthChangeEvent.tokenRefreshed && session != null) {
          // 토큰 갱신 시 (세션 유지)
          print('✅ 토큰이 갱신되었습니다. 세션이 유지됩니다.');
          // 프로필은 이미 로드되어 있으므로 별도 처리 불필요
        } else if (event == AuthChangeEvent.userUpdated && session != null) {
          // 사용자 정보 업데이트 시
          _loadUserProfile(session.user.id);
        }
        });
      } catch (e) {
        print('⚠️ Auth 상태 변경 리스너 등록 실패: $e');
      }
    }
  }

  /// 사용자 프로필 정보 로드
  /// 
  /// Supabase의 users 테이블에서 사용자 정보를 조회합니다.
  /// WP-1.3: UserService를 사용하여 프로필 조회
  Future<void> _loadUserProfile(String userId) async {
    try {
      // UserService를 사용하여 프로필 조회
      final profile = await UserService.getCurrentUserProfile();

      if (profile != null) {
        _currentUser = profile;
        _errorMessage = null;
      } else {
        // 프로필이 없는 경우 (역할 선택 전 상태)
        // Supabase Auth의 기본 정보만 사용
        final client = SupabaseConfig.client;
        final authUser = client.auth.currentUser;
        if (authUser != null) {
          final now = DateTime.now();
          // authUser.createdAt은 DateTime이지만, 안전하게 처리
          DateTime createdAt;
          try {
            if (authUser.createdAt is DateTime) {
              createdAt = authUser.createdAt as DateTime;
            } else {
              createdAt = DateTime.tryParse(authUser.createdAt.toString()) ?? now;
            }
          } catch (e) {
            createdAt = now;
          }
          
          DateTime updatedAt;
          try {
            if (authUser.updatedAt != null) {
              if (authUser.updatedAt is DateTime) {
                updatedAt = authUser.updatedAt as DateTime;
              } else {
                updatedAt = DateTime.tryParse(authUser.updatedAt.toString()) ?? now;
              }
            } else {
              updatedAt = now;
            }
          } catch (e) {
            updatedAt = now;
          }
          
          _currentUser = UserModel(
            id: authUser.id,
            email: authUser.email ?? '',
            createdAt: createdAt,
            updatedAt: updatedAt,
          );
        }
      }
    } catch (e) {
      print('⚠️ 사용자 프로필 로드 실패: $e');
      // 프로필 로드 실패해도 로그인 상태는 유지
      final client = SupabaseConfig.client;
      final authUser = client.auth.currentUser;
      if (authUser != null) {
        final now = DateTime.now();
        // authUser.createdAt은 DateTime이지만, 안전하게 처리
        DateTime createdAt;
        try {
          if (authUser.createdAt is DateTime) {
            createdAt = authUser.createdAt as DateTime;
          } else {
            createdAt = DateTime.tryParse(authUser.createdAt.toString()) ?? now;
          }
        } catch (e) {
          createdAt = now;
        }
        
        DateTime updatedAt;
        try {
          if (authUser.updatedAt != null) {
            if (authUser.updatedAt is DateTime) {
              updatedAt = authUser.updatedAt as DateTime;
            } else {
              updatedAt = DateTime.tryParse(authUser.updatedAt.toString()) ?? now;
            }
          } else {
            updatedAt = now;
          }
        } catch (e) {
          updatedAt = now;
        }
        
        _currentUser = UserModel(
          id: authUser.id,
          email: authUser.email ?? '',
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
      }
    } finally {
      notifyListeners();
    }
  }

  /// 회원가입
  /// 
  /// [email]: 이메일 주소
  /// [password]: 비밀번호
  /// [displayName]: 표시 이름 (필수)
  /// 
  /// Throws: [AuthException] 회원가입 실패 시
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (!SupabaseConfig.isInitialized) {
      _errorMessage = 'Supabase가 초기화되지 않았습니다. '
          '.env.development 파일을 확인하고 Supabase 프로젝트 정보를 설정하세요.';
      throw Exception(_errorMessage);
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // 이름 유효성 검사
      final trimmedDisplayName = displayName.trim();
      if (trimmedDisplayName.isEmpty) {
        _errorMessage = '이름을 입력해주세요.';
        throw Exception(_errorMessage);
      }
      if (trimmedDisplayName.length < 2) {
        _errorMessage = '이름은 최소 2자 이상이어야 합니다.';
        throw Exception(_errorMessage);
      }
      if (trimmedDisplayName.length > 50) {
        _errorMessage = '이름은 50자 이하여야 합니다.';
        throw Exception(_errorMessage);
      }

      // 이메일 유효성 검사
      final trimmedEmail = email.trim();
      if (trimmedEmail.isEmpty) {
        _errorMessage = '이메일을 입력해주세요.';
        throw Exception(_errorMessage);
      }
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(trimmedEmail)) {
        _errorMessage = '올바른 이메일 형식이 아닙니다.';
        throw Exception(_errorMessage);
      }

      // 비밀번호 유효성 검사
      if (password.isEmpty) {
        _errorMessage = '비밀번호를 입력해주세요.';
        throw Exception(_errorMessage);
      }
      if (password.length < 8) {
        _errorMessage = '비밀번호는 최소 8자 이상이어야 합니다.';
        throw Exception(_errorMessage);
      }
      if (password.length > 128) {
        _errorMessage = '비밀번호는 128자 이하여야 합니다.';
        throw Exception(_errorMessage);
      }

      final client = SupabaseConfig.client;
      
      // 이메일 중복 체크 (public.users 테이블 확인)
      // 주의: auth.users에도 이메일이 있을 수 있으므로 
      // signUp 시도 후 에러 처리도 함께 수행합니다.
      print('🔍 회원가입 전 이메일 중복 체크 시작: $trimmedEmail');
      final isEmailAlreadyExists = await UserService.isEmailExists(trimmedEmail);
      print('🔍 이메일 중복 체크 결과: $isEmailAlreadyExists');
      
      if (isEmailAlreadyExists) {
        print('❌ 중복된 이메일로 회원가입 시도 차단: $trimmedEmail');
        _errorMessage = '이미 등록된 이메일입니다.\n로그인 화면으로 이동하시겠습니까?';
        throw Exception(_errorMessage);
      }
      
      print('✅ 이메일 중복 체크 통과: $trimmedEmail');
      
      // displayName을 상태로 저장하여 역할 선택 화면에서 사용할 수 있도록 함
      _pendingDisplayName = trimmedDisplayName;

      // 회원가입 시도
      // Supabase Auth도 중복 이메일 체크를 수행하므로, 
      // 여기서 에러가 발생하면 _getErrorMessage에서 처리됩니다.
      // emailRedirectTo를 설정하여 이메일 확인 후 리다이렉트할 URL 지정
      final response = await client.auth.signUp(
        email: trimmedEmail.toLowerCase(), // 소문자로 통일
        password: password,
        emailRedirectTo: _getRedirectUrl(), // 이메일 확인 후 리다이렉트 URL
      );

      if (response.user != null) {
        // 회원가입 성공
        // 이메일 확인이 필요한 경우 세션이 없을 수 있음
        final session = response.session;
        
        if (session != null) {
          // 세션이 있으면 즉시 로그인됨 (이메일 확인 불필요)
          // WP-1.3: 프로필은 역할 선택 화면에서 생성하므로 여기서는 생성하지 않음
          // 역할 선택 화면으로 이동
          // 사용자 프로필은 아직 없으므로 로드하지 않음
        } else {
          // 이메일 확인이 필요한 경우
          // 세션은 없지만 사용자는 생성됨
          print('ℹ️ 이메일 확인이 필요합니다. 이메일을 확인해주세요.');
          // 이 경우 사용자는 아직 로그인되지 않은 상태
          // 이메일 확인 후 자동으로 로그인됨 (onAuthStateChange에서 처리)
        }
      } else {
        throw Exception('회원가입 응답에 사용자 정보가 없습니다.');
      }
    } on AuthException catch (e) {
      _errorMessage = _getErrorMessage(e);
      rethrow;
    } catch (e) {
      _errorMessage = '회원가입 중 오류가 발생했습니다: $e';
      throw Exception(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 로그인
  /// 
  /// [email]: 이메일 주소
  /// [password]: 비밀번호
  /// 
  /// Throws: [AuthException] 로그인 실패 시
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (!SupabaseConfig.isInitialized) {
      _errorMessage = 'Supabase가 초기화되지 않았습니다. '
          '.env.development 파일을 확인하고 Supabase 프로젝트 정보를 설정하세요.';
      throw Exception(_errorMessage);
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final client = SupabaseConfig.client;
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // 로그인 성공 시 사용자 프로필 로드
        await _loadUserProfile(response.user!.id);
      } else {
        throw Exception('로그인 응답에 사용자 정보가 없습니다.');
      }
    } on AuthException catch (e) {
      _errorMessage = _getErrorMessage(e);
      rethrow;
    } catch (e) {
      _errorMessage = '로그인 중 오류가 발생했습니다: $e';
      throw Exception(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    if (!SupabaseConfig.isInitialized) {
      // 초기화되지 않았어도 로그아웃은 가능 (이미 로그아웃된 상태로 간주)
      _currentUser = null;
      _errorMessage = null;
      return;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final client = SupabaseConfig.client;
      await client.auth.signOut();

      _currentUser = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '로그아웃 중 오류가 발생했습니다: $e';
      print('❌ 로그아웃 오류: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 사용자 프로필 새로고침
  /// 
  /// WP-1.3: 역할 변경 등으로 프로필이 업데이트된 경우 호출
  Future<void> refreshUserProfile() async {
    if (!SupabaseConfig.isInitialized) {
      print('⚠️ 프로필 새로고침 스킵: Supabase가 초기화되지 않음');
      return;
    }
    
    final client = SupabaseConfig.client;
    final user = client.auth.currentUser;
    if (user != null) {
      await _loadUserProfile(user.id);
    }
  }

  /// 사용자 역할 업데이트
  /// 
  /// WP-1.3: 역할 선택 화면에서 호출
  /// [role]: 새로운 역할 ('fan', 'celebrity', 'manager')
  Future<void> updateUserRole(String role) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final client = SupabaseConfig.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      await UserService.updateUserRole(
        userId: user.id,
        role: role,
      );

      // 프로필 새로고침
      await refreshUserProfile();
    } catch (e) {
      _errorMessage = '역할 업데이트 중 오류가 발생했습니다: $e';
      print('❌ 역할 업데이트 오류: $_errorMessage');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 에러 메시지 초기화
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Google 소셜 로그인
  /// 
  /// WP-1.6: 소셜 로그인 연동
  /// 
  /// Supabase의 OAuth 기능을 사용하여 Google 로그인을 수행합니다.
  /// 
  /// Throws: [AuthException] 로그인 실패 시
  Future<void> signInWithGoogle() async {
    if (!SupabaseConfig.isInitialized) {
      _errorMessage = 'Supabase가 초기화되지 않았습니다. '
          '.env.development 파일을 확인하고 Supabase 프로젝트 정보를 설정하세요.';
      throw Exception(_errorMessage);
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final client = SupabaseConfig.client;
      
      // Supabase OAuth를 통한 Google 로그인
      // 웹에서는 리다이렉트, 모바일에서는 딥링크를 사용합니다.
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _getRedirectUrl(),
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      // OAuth 로그인은 비동기적으로 완료되므로,
      // onAuthStateChange 리스너에서 실제 로그인 완료를 감지합니다.
      // signInWithOAuth는 URL을 여는 작업만 수행하므로 여기서는 완료된 것으로 간주합니다.
      // 실제 로그인 완료는 onAuthStateChange에서 감지되며, 그때 로딩 상태가 해제됩니다.
    } on AuthException catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      
      // Provider가 활성화되지 않은 경우를 명확히 처리
      print('❌ Google 로그인 오류: ${e.statusCode} - ${e.message}');
      if (_errorMessage != null && _errorMessage!.contains('활성화되지 않았습니다')) {
        print('💡 해결 방법: Supabase Dashboard > Authentication > Providers에서 Google Provider 활성화');
      }
      
      rethrow;
    } catch (e) {
      _errorMessage = 'Google 로그인 중 오류가 발생했습니다: $e';
      _isLoading = false;
      notifyListeners();
      
      print('❌ Google 로그인 예상치 못한 오류: $e');
      throw Exception(_errorMessage);
    }
  }

  /// Apple 소셜 로그인 (iOS/macOS 전용)
  /// 
  /// WP-1.6: 소셜 로그인 연동
  /// 
  /// Supabase의 OAuth 기능을 사용하여 Apple 로그인을 수행합니다.
  /// iOS/macOS에서만 지원됩니다.
  /// 
  /// Throws: [AuthException] 로그인 실패 시
  Future<void> signInWithApple() async {
    if (!SupabaseConfig.isInitialized) {
      _errorMessage = 'Supabase가 초기화되지 않았습니다. '
          '.env.development 파일을 확인하고 Supabase 프로젝트 정보를 설정하세요.';
      throw Exception(_errorMessage);
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final client = SupabaseConfig.client;
      
      // Supabase OAuth를 통한 Apple 로그인
      await client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: _getRedirectUrl(),
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      // OAuth 로그인은 비동기적으로 완료되므로,
      // onAuthStateChange 리스너에서 실제 로그인 완료를 감지합니다.
      // signInWithOAuth는 URL을 여는 작업만 수행하므로 여기서는 완료된 것으로 간주합니다.
      // 실제 로그인 완료는 onAuthStateChange에서 감지되며, 그때 로딩 상태가 해제됩니다.
    } on AuthException catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      
      // Provider가 활성화되지 않은 경우를 명확히 처리
      print('❌ Apple 로그인 오류: ${e.statusCode} - ${e.message}');
      if (_errorMessage != null && _errorMessage!.contains('활성화되지 않았습니다')) {
        print('💡 해결 방법: Supabase Dashboard > Authentication > Providers에서 Apple Provider 활성화');
      }
      
      rethrow;
    } catch (e) {
      _errorMessage = 'Apple 로그인 중 오류가 발생했습니다: $e';
      _isLoading = false;
      notifyListeners();
      
      print('❌ Apple 로그인 예상치 못한 오류: $e');
      throw Exception(_errorMessage);
    }
  }

  /// OAuth 리다이렉트 URL 생성
  /// 
  /// 플랫폼에 따라 적절한 리다이렉트 URL을 반환합니다.
  /// 
  /// 주의: Supabase Dashboard > Authentication > URL Configuration에서
  /// 리다이렉트 URL을 등록해야 합니다.
  /// 
  /// 웹: https://your-domain.com/auth/callback
  /// 모바일: com.aura.app://login-callback (URL 스킴)
  String _getRedirectUrl() {
    // SupabaseConfig에서 URL 가져오기
    final baseUrl = AppEnvironment.supabaseUrl;
    
    // 기본 OAuth 콜백 URL
    // 실제로는 Supabase Dashboard에서 설정한 리다이렉트 URL과 일치해야 합니다.
    return '$baseUrl/auth/v1/callback';
  }

  /// Supabase AuthException을 사용자 친화적인 메시지로 변환
  String _getErrorMessage(AuthException e) {
    final message = e.message.toLowerCase();
    
    // Provider가 활성화되지 않은 경우 처리
    if (message.contains('provider is not enabled') || 
        message.contains('unsupported provider') ||
        e.statusCode == 'validation_failed' && message.contains('provider')) {
      return '소셜 로그인 제공자가 활성화되지 않았습니다.\n'
          'Supabase Dashboard > Authentication > Providers에서 Google/Apple Provider를 활성화해주세요.';
    }
    
    // 이메일 중복 관련 에러 메시지 (다양한 형태로 올 수 있음)
    if (message.contains('user already registered') ||
        message.contains('email already exists') ||
        message.contains('already registered') ||
        message.contains('email address is already registered') ||
        e.statusCode == 'signup_disabled') {
      return '이미 등록된 이메일입니다.\n로그인 화면으로 이동하시겠습니까?';
    }
    
    // Supabase Auth 에러 코드에 따른 메시지 변환
    switch (e.statusCode) {
      case 'invalid_credentials':
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      case 'email_not_confirmed':
        return '이메일 인증이 완료되지 않았습니다. 이메일을 확인해주세요.';
      case 'user_not_found':
        return '등록되지 않은 이메일입니다.';
      case 'email_already_registered':
      case 'user_already_registered':
        return '이미 등록된 이메일입니다.\n로그인 화면으로 이동하시겠습니까?';
      case 'weak_password':
        return '비밀번호가 너무 약합니다. 영문, 숫자를 포함하여 8자 이상의 비밀번호를 사용해주세요.';
      case 'invalid_email':
        return '올바른 이메일 형식이 아닙니다.';
      case 'validation_failed':
        // validation_failed의 경우 메시지 내용을 확인
        if (message.contains('provider')) {
          return '소셜 로그인 제공자가 활성화되지 않았습니다.\n'
              'Supabase Dashboard > Authentication > Providers에서 Google/Apple Provider를 활성화해주세요.';
        }
        if (message.contains('email') && message.contains('already')) {
          return '이미 등록된 이메일입니다.\n로그인 화면으로 이동하시겠습니까?';
        }
        return e.message.isNotEmpty ? e.message : '입력값 검증에 실패했습니다.';
      default:
        // 기본 에러 메시지에서도 이메일 중복 관련 키워드 확인
        if (message.contains('already') && (message.contains('email') || message.contains('user'))) {
          return '이미 등록된 이메일입니다.\n로그인 화면으로 이동하시겠습니까?';
        }
        return e.message.isNotEmpty ? e.message : '인증 중 오류가 발생했습니다.';
    }
  }
}
