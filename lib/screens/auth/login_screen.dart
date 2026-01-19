import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/widgets/common/custom_text_field.dart';
import '../../services/widgets/common/custom_button.dart';
import '../../services/widgets/common/loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final l10n = AppLocalizations.of(context)!;
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          child: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      // Logo
                      Center(
                        child: Image.asset(
                          'assets/logo.jpg',
                          height: 120,
                          width: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Title
                      Text(
                        l10n.loginWelcome,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.loginSubtitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      // Error message
                      if (authProvider.error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  authProvider.error!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Identifier field
                      CustomTextField(
                        controller: _identifierController,
                        label: l10n.loginIdentifierLabel,
                        hintText: l10n.loginIdentifierHint,
                        prefixIcon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.loginIdentifierRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Code PIN field
                      CustomTextField(
                        controller: _passwordController,
                        label: l10n.loginPinLabel,
                        hintText: l10n.loginPinHint,
                        prefixIcon: Icons.lock_outline,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleLogin(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.loginPinRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Forgot PIN
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: Text(l10n.forgotPin),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Login button
                      CustomButton(
                        text: l10n.loginAction,
                        onPressed: _handleLogin,
                        isLoading: authProvider.isLoading,
                      ),
                      const SizedBox(height: 24),
                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              l10n.orSeparator,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Register button
                      CustomButton(
                        text: l10n.createAccount,
                        onPressed: () => context.push('/register'),
                        isOutlined: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
