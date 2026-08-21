import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _remember = true;

  @override
  void initState() {
    super.initState();
    final remembered = context.read<AuthController>().rememberedEmail;
    _email.text = remembered ?? AppConfig.demoEmail;
    _password.text = AppConfig.demoPassword;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Enter your email and password to sign in.'),
          ),
        );
      return;
    }
    final auth = context.read<AuthController>();
    final ok = await auth.login(
      email: _email.text,
      password: _password.text,
      rememberDevice: _remember,
    );
    if (!ok && mounted) {
      final msg = auth.loginError?.message ?? 'Login failed.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final busy = context.select<AuthController, bool>((a) => a.isLoginBusy);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageMargin,
              vertical: AppSpacing.stackXl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.stackLg),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      border: Border.all(color: scheme.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ambientShadow,
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        const AppLogo(size: 116, showTagline: false),
                        AppSpacing.gapLg,
                        Text(
                          'Site Assistant',
                          style: AppTypography.headlineLg.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Buildings built on teamwork',
                          style: AppTypography.bodyMd.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        AppSpacing.gapXl,
                        AppTextField(
                          label: 'Email address',
                          controller: _email,
                          hint: 'e.g. j.smith@baxall.co.uk',
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        AppSpacing.gapLg,
                        AppTextField(
                          label: 'Password',
                          controller: _password,
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          suffix: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: scheme.outline,
                            ),
                          ),
                          trailingLabel: TextButton(
                            onPressed: () {},
                            child: Text(
                              'Forgot?',
                              style: AppTypography.labelMd.copyWith(
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.gapMd,
                        _RememberRow(
                          value: _remember,
                          onChanged: (v) => setState(() => _remember = v),
                        ),
                        AppSpacing.gapLg,
                        PrimaryButton(
                          label: 'SIGN IN TO SITE',
                          icon: Icons.login_rounded,
                          busy: busy,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapXl,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.secondary,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wb_sunny_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'HIGH-CONTRAST MODE ACTIVE FOR SITE USE',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RememberRow extends StatelessWidget {
  const _RememberRow({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: scheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          'Remember device',
          style: AppTypography.labelLg.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
