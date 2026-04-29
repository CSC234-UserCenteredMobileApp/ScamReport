import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '_auth_scaffold.dart';
import '_error_banner.dart';
import '_password_field.dart';
import 'auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _acceptedTos = false;
  bool _acceptedPrivacy = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  bool get _consentGiven => _acceptedTos && _acceptedPrivacy;

  Future<void> _submit() async {
    if (!_consentGiven) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).registerWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _displayNameController.text,
          );
      // TODO: write a consent_records row via a future ConsentRepository.
      if (mounted) context.go('/');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mapFirebaseError(e.code));
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit = _consentGiven && !_busy;
    return AuthScaffold(
      tagline: 'Create your account',
      children: [
        AbsorbPointer(
          absorbing: _busy,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _displayNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Display name (optional)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                PasswordField(
                  controller: _passwordController,
                  label: 'Password',
                  helperText: 'At least 6 characters.',
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) {
                    if ((v ?? '').isEmpty) return 'Please enter a password.';
                    if ((v ?? '').length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirmController,
                  label: 'Confirm password',
                  validator: (v) => v == _passwordController.text
                      ? null
                      : 'Passwords do not match.',
                ),
                const SizedBox(height: 16),
                _ConsentBlock(
                  acceptedTos: _acceptedTos,
                  acceptedPrivacy: _acceptedPrivacy,
                  onChangedTos: (v) => setState(() => _acceptedTos = v ?? false),
                  onChangedPrivacy: (v) =>
                      setState(() => _acceptedPrivacy = v ?? false),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  ErrorBanner(message: _error!),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: canSubmit ? _submit : null,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create account'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            GestureDetector(
              onTap: _busy ? null : () => context.go('/login'),
              child: Text(
                'Sign in',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConsentBlock extends StatefulWidget {
  const _ConsentBlock({
    required this.acceptedTos,
    required this.acceptedPrivacy,
    required this.onChangedTos,
    required this.onChangedPrivacy,
  });

  final bool acceptedTos;
  final bool acceptedPrivacy;
  final ValueChanged<bool?> onChangedTos;
  final ValueChanged<bool?> onChangedPrivacy;

  @override
  State<_ConsentBlock> createState() => _ConsentBlockState();
}

class _ConsentBlockState extends State<_ConsentBlock> {
  late final TapGestureRecognizer _tosRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _tosRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push('/terms');
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push('/privacy');
  }

  @override
  void dispose() {
    _tosRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final linkStyle = TextStyle(
      color: cs.primary,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: widget.acceptedTos,
            onChanged: widget.onChangedTos,
            title: Text.rich(TextSpan(children: [
              const TextSpan(text: 'I accept the '),
              TextSpan(
                text: 'Terms of Service',
                style: linkStyle,
                recognizer: _tosRecognizer,
              ),
              const TextSpan(text: '.'),
            ])),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          CheckboxListTile(
            value: widget.acceptedPrivacy,
            onChanged: widget.onChangedPrivacy,
            title: Text.rich(TextSpan(children: [
              const TextSpan(text: 'I accept the '),
              TextSpan(
                text: 'Privacy Policy',
                style: linkStyle,
                recognizer: _privacyRecognizer,
              ),
              const TextSpan(text: '.'),
            ])),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
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

String _mapFirebaseError(String code) {
  switch (code) {
    case 'invalid-email':
      return 'That email looks invalid.';
    case 'email-already-in-use':
      return 'An account with that email already exists.';
    case 'weak-password':
      return 'Password is too weak. Use at least 6 characters.';
    case 'operation-not-allowed':
      return 'Email sign-in is not enabled. Contact support.';
    case 'network-request-failed':
      return 'Network error. Check your connection.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
