import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '_auth_scaffold.dart';
import '_error_banner.dart';
import 'auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(
            _emailController.text.trim(),
          );
      if (mounted) setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // Don't reveal account existence — treat as success.
        if (mounted) setState(() => _sent = true);
      } else if (e.code == 'invalid-email') {
        if (mounted) setState(() => _error = 'That email looks invalid.');
      } else {
        if (mounted) {
          setState(() => _error = 'Something went wrong. Please try again.');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthScaffold(
      tagline: 'Reset your password',
      children: [
        if (_sent) ...[
          const Icon(Icons.mark_email_read_outlined, size: 48),
          const SizedBox(height: 16),
          Text(
            'Check your inbox',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a password reset link to ${_emailController.text.trim()}. '
            'Check your spam folder if it doesn\'t arrive.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/login');
              }
            },
            child: const Text('Back to sign in'),
          ),
        ] else ...[
          AbsorbPointer(
            absorbing: _busy,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enter the email address linked to your account and we\'ll send you a reset link.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: _emailValidator,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    ErrorBanner(message: _error!),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send reset link'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

String? _emailValidator(String? v) {
  final value = (v ?? '').trim();
  if (value.isEmpty) return 'Please enter your email.';
  if (!value.contains('@') || !value.contains('.')) {
    return 'That email looks invalid.';
  }
  return null;
}
