import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

/// 로그인 화면
/// 
/// WP-1.2: Supabase Auth 기본 연동 및 회원가입/로그인
/// 
/// 사용자가 이메일/비밀번호로 로그인할 수 있는 화면입니다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // 화면이 처음 표시될 때 에러 메시지 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        // 로그인 시도 중이 아닐 때만 에러 메시지 초기화
        if (!authProvider.isLoading) {
          authProvider.clearError();
        }
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 이메일 유효성 검증
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요.';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return '올바른 이메일 형식이 아닙니다.';
    }
    return null;
  }

  /// 비밀번호 유효성 검증
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }
    return null;
  }

  /// 로그인 처리
  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 로그인 성공
      // WP-1.4: Go Router의 redirect가 역할에 따라 자동으로 적절한 화면으로 리다이렉트함
      if (mounted) {
        context.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 에러는 AuthProvider에서 처리되므로 여기서는 표시만
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? '로그인에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
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
                  hint: '비밀번호를 입력하세요',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
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
                  onSubmitted: (_) => _handleSignIn(),
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

                // 로그인 버튼
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return CustomButton(
                      label: '로그인',
                      onPressed: authProvider.isLoading ? null : _handleSignIn,
                      isLoading: authProvider.isLoading,
                      isFullWidth: true,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // 회원가입 링크
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '계정이 없으신가요? ',
                      style: AppTypography.body1,
                    ),
                    TextButton(
                      onPressed: () {
                        // 회원가입 페이지로 이동하기 전에 에러 메시지 초기화
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        authProvider.clearError();
                        context.push('/signup');
                      },
                      child: const Text('회원가입'),
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
