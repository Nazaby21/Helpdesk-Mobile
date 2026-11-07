import 'package:flutter/material.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_spacing.dart';
import '../../../../app/constants/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authController,
  });

  final AuthController authController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await widget.authController.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AnimatedBuilder(
                animation: widget.authController,
                builder: (context, _) {
                  final state = widget.authController.state;

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: AppSpacing.borderRadius2Xl,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1,
                      ),
                      boxShadow: const [AppSpacing.shadowMd],
                    ),
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Logo / Icon
                          Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(25),
                                borderRadius: AppSpacing.borderRadiusXl,
                              ),
                              child: const Icon(
                                Icons.confirmation_number_outlined,
                                color: AppColors.primary,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Heading
                          Text(
                            'Sign In to Helpdesk',
                            textAlign: TextAlign.center,
                            style: AppTypography.headlineSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Enter your corporate email and password to access your support dashboard.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),

                          // Error alert
                          if (state.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF380C0C)
                                    : AppColors.errorBg,
                                borderRadius: AppSpacing.borderRadiusLg,
                                border: Border.all(color: AppColors.errorInput),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      state.errorMessage!,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.error,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],

                          // Email field
                          AppTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'name@company.com',
                            isRequired: true,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!val.contains('@') || !val.contains('.')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Password field
                          AppTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: '••••••••',
                            isRequired: true,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                            onSubmitted: (_) => _handleLogin(),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Password is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.xxl),

                          // Submit Button
                          AppButton(
                            text: 'Sign In',
                            onPressed: _handleLogin,
                            isLoading: state.isLoading,
                            size: AppButtonSize.lg,
                            isFullWidth: true,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
