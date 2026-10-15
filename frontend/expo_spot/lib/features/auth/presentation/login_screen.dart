import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/routing/fade_scale_route.dart';
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_radii.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:expo_spot/core/widgets/warm_cream_background.dart';
import 'package:expo_spot/features/auth/application/auth_controller.dart';
import 'package:expo_spot/features/auth/presentation/widgets/expo_text_field.dart';
import 'package:expo_spot/features/auth/presentation/widgets/login_primary_button.dart';
import 'package:expo_spot/features/auth/presentation/widgets/login_social_button.dart';
import 'package:expo_spot/features/shell/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fade;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  String? _usernameError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(vsync: this);
    _entranceController.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 160, damping: 20),
        0,
        1,
        0,
      ),
    );
    _fade = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _usernameError =
          username.isEmpty ? 'validation_username_required'.tr() : null;
      _passwordError =
          password.length < 6 ? 'validation_password_min'.tr() : null;
    });
    return _usernameError == null && _passwordError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    final user = await ref.read(authControllerProvider.notifier).saveProfile(
          username: _usernameController.text,
          password: _passwordController.text,
        );

    if (!mounted || user == null) return;

    _goHome(user.name);
  }

  void _goHome(String userName) {
    Navigator.of(context).pushAndRemoveUntil(
      FadeScaleRoute(page: MainShell(userName: userName)),
      (route) => false,
    );
  }

  Future<void> _signInWithGoogle() async {
    final user = await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (!mounted || user == null) return;
    _goHome(user.name);
  }

  Future<void> _showForgotPassword() async {
    final emailController = TextEditingController(
      text: _usernameController.text.trim(),
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('forgot_password_title'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'forgot_password_sub'.tr(),
              style: AppTypography.body(context).copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            ExpoTextField(
              label: 'username'.tr(),
              controller: emailController,
              prefixIcon: Icons.alternate_email_rounded,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('forgot_password_sent'.tr())),
              );
            },
            child: Text('forgot_password_send'.tr()),
          ),
        ],
      ),
    );
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      body: WarmCreamBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'ExpoSpot',
                      style: AppTypography.display(context).copyWith(
                        color: Colors.black,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'welcome_back'.tr(),
                    textAlign: TextAlign.center,
                    style: AppTypography.display(context).copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'login_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: AppTypography.subtitle(context),
                  ),
                  const SizedBox(height: 28),
                  ExpoTextField(
                    label: 'username'.tr(),
                    controller: _usernameController,
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                  if (_usernameError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _usernameError!,
                      style: AppTypography.label(context).copyWith(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 14),
                  ExpoTextField(
                    label: 'password'.tr(),
                    controller: _passwordController,
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                    enablePasswordToggle: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_passwordError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _passwordError!,
                      style: AppTypography.label(context).copyWith(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: auth.isLoading ? null : _showForgotPassword,
                      child: Text(
                        'forgot_password'.tr(),
                        style: AppTypography.label(context).copyWith(
                          color: AppColors.keppelGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        activeColor: AppColors.keppelGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.badge),
                        ),
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          setState(() => _rememberMe = value ?? true);
                        },
                      ),
                      Expanded(
                        child: Text(
                          'remember_me'.tr(),
                          style: AppTypography.body(context),
                        ),
                      ),
                    ],
                  ),
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      auth.errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTypography.label(context).copyWith(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  LoginPrimaryButton(
                    label: 'login'.tr(),
                    isLoading: auth.isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'login_or_continue'.tr(),
                          style: AppTypography.label(context).copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GoogleSignInButton(
                    label: 'sign_in_google'.tr(),
                    isLoading: auth.isLoading,
                    onPressed: _signInWithGoogle,
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
