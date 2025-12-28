import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

/// 회원가입 화면
/// 
/// WP-1.2: Supabase Auth 기본 연동 및 회원가입/로그인
/// 
/// 사용자가 이메일/비밀번호로 계정을 생성할 수 있는 화면입니다.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // 화면이 처음 표시될 때 에러 메시지 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        // 회원가입 시도 중이 아닐 때만 에러 메시지 초기화
        if (!authProvider.isLoading) {
          authProvider.clearError();
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 이름 유효성 검증
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이름을 입력해주세요.';
    }
    final trimmedValue = value.trim();
    if (trimmedValue.length < 2) {
      return '이름은 최소 2자 이상이어야 합니다.';
    }
    if (trimmedValue.length > 50) {
      return '이름은 50자 이하여야 합니다.';
    }
    // 특수문자 제한 (한글, 영문, 숫자, 공백만 허용)
    final nameRegex = RegExp(r'^[가-힣a-zA-Z0-9\s]+$');
    if (!nameRegex.hasMatch(trimmedValue)) {
      return '이름은 한글, 영문, 숫자만 사용할 수 있습니다.';
    }
    return null;
  }

  /// 이메일 유효성 검증
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요.';
    }
    final trimmedEmail = value.trim();
    
    // 이메일 길이 제한
    if (trimmedEmail.length > 255) {
      return '이메일은 255자 이하여야 합니다.';
    }
    
    // 이메일 형식 검증 (더 엄격한 패턴)
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      return '올바른 이메일 형식이 아닙니다.';
    }
    
    // 연속된 점(..) 제한
    if (trimmedEmail.contains('..')) {
      return '이메일 형식이 올바르지 않습니다.';
    }
    
    // @ 앞뒤로 점이 오는 경우 제한
    if (trimmedEmail.startsWith('.') || 
        trimmedEmail.startsWith('@') || 
        trimmedEmail.endsWith('.') || 
        trimmedEmail.endsWith('@')) {
      return '이메일 형식이 올바르지 않습니다.';
    }
    
    return null;
  }

  /// 비밀번호 유효성 검증
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }
    if (value.length < 8) {
      return '비밀번호는 최소 8자 이상이어야 합니다.';
    }
    if (value.length > 128) {
      return '비밀번호는 128자 이하여야 합니다.';
    }
    // 비밀번호 강도 검사 (영문, 숫자 포함)
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    
    if (!hasLetter || !hasNumber) {
      return '비밀번호는 영문과 숫자를 포함해야 합니다.';
    }
    
    return null;
  }

  /// 비밀번호 확인 검증
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력해주세요.';
    }
    if (value != _passwordController.text) {
      return '비밀번호가 일치하지 않습니다.';
    }
    return null;
  }

  /// 회원가입 처리
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      // 회원가입 성공
      if (mounted) {
        // 이메일 확인이 필요한 경우와 즉시 로그인되는 경우를 구분
        // 세션이 있으면 즉시 로그인된 것으로 간주 (프로필이 없어도 세션이 있으면 OK)
        final hasSession = authProvider.supabaseUser != null;
        
        if (hasSession) {
          // 즉시 로그인된 경우 (이메일 확인 불필요)
          // WP-1.3: 역할 선택 화면으로 이동
          // WP-1.4: Go Router 사용
          context.go('/role-selection');
        } else {
          // 이메일 확인이 필요한 경우
          context.go('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('회원가입이 완료되었습니다. 이메일을 확인해주세요.'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      // 에러는 AuthProvider에서 처리되므로 여기서는 표시만
      if (mounted) {
        final errorMessage = authProvider.errorMessage ?? '회원가입에 실패했습니다.';
        
        // 이메일 중복 에러인 경우 다이얼로그로 표시하고 로그인 화면으로 이동 옵션 제공
        if (errorMessage.contains('이미 등록된 이메일')) {
          _showEmailAlreadyRegisteredDialog(context, errorMessage);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  /// 이메일 중복 에러 다이얼로그 표시
  void _showEmailAlreadyRegisteredDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('이메일 중복'),
          content: Text(message.split('\n').first), // 첫 줄만 표시
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go('/login');
              },
              child: const Text('로그인 화면으로'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 제목
                Text(
                  'AURA에 오신 것을 환영합니다',
                  style: AppTypography.h2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '셀럽과 팬이 건강하게 소통하는 플랫폼',
                  style: AppTypography.body1.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                // 이름 입력
                CustomTextField(
                  label: '이름',
                  hint: '이름을 입력하세요',
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: _validateName,
                  prefixIcon: const Icon(Icons.person),
                ),
                const SizedBox(height: AppSpacing.md),

                // 이메일 입력
                CustomTextField(
                  label: '이메일',
                  hint: 'example@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                  prefixIcon: const Icon(Icons.email),
                ),
                const SizedBox(height: AppSpacing.md),

                // 비밀번호 입력
                CustomTextField(
                  label: '비밀번호',
                  hint: '최소 6자 이상',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  validator: _validatePassword,
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 비밀번호 확인 입력
                CustomTextField(
                  label: '비밀번호 확인',
                  hint: '비밀번호를 다시 입력하세요',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  validator: _validateConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  onSubmitted: (_) => _handleSignUp(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 에러 메시지 표시
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    if (authProvider.errorMessage != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  authProvider.errorMessage!,
                                  style: AppTypography.body2.copyWith(
                                    color: Colors.red[700],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => authProvider.clearError(),
                                color: Colors.red[700],
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // 회원가입 버튼
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return CustomButton(
                      label: '회원가입',
                      onPressed: authProvider.isLoading ? null : _handleSignUp,
                      isLoading: authProvider.isLoading,
                      isFullWidth: true,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // 로그인 링크
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '이미 계정이 있으신가요? ',
                      style: AppTypography.body1,
                    ),
                    TextButton(
                      onPressed: () {
                        // 로그인 페이지로 이동하기 전에 에러 메시지 초기화
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        authProvider.clearError();
                        context.go('/login');
                      },
                      child: const Text('로그인'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
