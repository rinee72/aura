/// Auth Feature 진입점
/// 
/// 이 파일은 auth feature의 모든 public API를 export합니다.
/// 다른 feature에서 auth 관련 기능을 사용할 때는 이 파일을 import하세요.
/// 
/// 예시:
/// ```dart
/// import 'package:aura_app/features/auth/auth.dart';
/// 
/// final authProvider = Provider.of<AuthProvider>(context);
/// ```
library;

// Models
export 'models/user_model.dart';

// Providers
export 'providers/auth_provider.dart';

// Services
export 'services/user_service.dart';

// Screens
export 'screens/login_screen.dart';
export 'screens/signup_screen.dart';
export 'screens/role_selection_screen.dart';
