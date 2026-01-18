import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../services/auth_service.dart';
import '../../services/widgets/common/custom_text_field.dart';
import '../../services/widgets/common/custom_button.dart';
import '../../services/widgets/common/loading_overlay.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _identityVerified = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _firstNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyIdentity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await _authService.verifyIdentity(
        phone: _phoneController.text.trim(),
        firstName: _firstNameController.text.trim(),
      );

      if (success) {
        setState(() {
          _identityVerified = true;
        });
      } else {
        setState(() {
          _error = AppLocalizations.of(context)!.verifyIdentityError;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await _authService.resetPasswordByPhone(
        phone: _phoneController.text.trim(),
        firstName: _firstNameController.text.trim(),
        newPassword: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (success && mounted) {
        Helpers.showSuccessSnackBar(
          context,
          AppLocalizations.of(context)!.passwordResetSuccess,
        );
        context.go('/login');
      } else {
        setState(() {
          _error = AppLocalizations.of(context)!.resetPasswordError;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.forgotPasswordTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    _identityVerified
                        ? AppLocalizations.of(context)!.newPasswordTitle
                        : AppLocalizations.of(context)!.verifyIdentityTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _identityVerified
                        ? AppLocalizations.of(context)!.newPasswordSubtitle
                        : AppLocalizations.of(context)!.verifyIdentitySubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Error message
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (!_identityVerified) ...[
                    // Phone field
                    CustomTextField(
                      controller: _phoneController,
                      label: AppLocalizations.of(context)!.phoneLabel,
                      hintText: AppLocalizations.of(context)!.phoneHint,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.phoneRequired;
                        }
                        if (!Helpers.isValidPhone(value)) {
                          return AppLocalizations.of(context)!.phoneInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // First name field
                    CustomTextField(
                      controller: _firstNameController,
                      label: AppLocalizations.of(context)!.firstNameLabel,
                      hintText: AppLocalizations.of(context)!.firstNameHint,
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _verifyIdentity(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.firstNameRequiredSimple;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: AppLocalizations.of(context)!.verifyIdentityAction,
                      onPressed: _verifyIdentity,
                      isLoading: _isLoading,
                    ),
                  ] else ...[
                    // New password fields
                    CustomTextField(
                      controller: _passwordController,
                      label: AppLocalizations.of(context)!.newPasswordLabel,
                      hintText: AppLocalizations.of(context)!.newPasswordHint,
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.passwordRequired;
                        }
                        if (value.length < 8) {
                          return AppLocalizations.of(context)!.passwordTooShort;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: AppLocalizations.of(context)!.confirmPasswordLabel,
                      hintText: AppLocalizations.of(context)!.confirmPasswordHint,
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _resetPassword(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.confirmPasswordRequired;
                        }
                        if (value != _passwordController.text) {
                          return AppLocalizations.of(context)!.passwordMismatch;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: AppLocalizations.of(context)!.resetPasswordAction,
                      onPressed: _resetPassword,
                      isLoading: _isLoading,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
