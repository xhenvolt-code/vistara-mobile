import 'package:flutter/material.dart';

import '../services/vistara_api.dart';
import '../theme/app_theme.dart';
import '../widgets/preview_notice.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({required this.api, this.sessionError, super.key});

  final VistaraApi api;
  final String? sessionError;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isResettingPassword = false;
  bool _isBusy = false;
  String? _error;
  String? _message;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isBusy = true;
      _error = null;
      _message = null;
    });

    try {
      if (_isResettingPassword) {
        await widget.api.requestPasswordReset(_emailController.text);
        if (!mounted) return;
        setState(() {
          _message =
              'If an account exists for that email, password-reset '
              'instructions have been sent.';
        });
        return;
      }

      if (_isSignUp) {
        final session = await widget.api.signUp(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (!mounted) return;
        if (session != null) {
          Navigator.of(context).pop(session);
        } else {
          setState(() {
            _message =
                'Your account request was accepted. Check your email if '
                'verification is required, then sign in.';
            _isSignUp = false;
            _passwordController.clear();
          });
        }
      } else {
        final session = await widget.api.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (mounted) Navigator.of(context).pop(session);
      }
    } on VistaraApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _changeMode({required bool signUp, required bool resetPassword}) {
    setState(() {
      _isSignUp = signUp;
      _isResettingPassword = resetPassword;
      _error = null;
      _message = null;
    });
    _formKey.currentState?.reset();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isResettingPassword
        ? 'Reset your password'
        : _isSignUp
        ? 'Create your account'
        : 'Welcome back';

    return Scaffold(
      appBar: AppBar(title: const Text('Vistara account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isResettingPassword
                                ? 'Enter your email and we’ll send password '
                                      'reset instructions if an account exists.'
                                : _isSignUp
                                ? 'Create an account to keep your Vistara '
                                      'access and purchases together.'
                                : 'Sign in with your Vistara email and '
                                      'password.',
                            style: const TextStyle(
                              color: AppTheme.muted,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_isSignUp) ...[
                            TextFormField(
                              key: const ValueKey('account-name'),
                              controller: _nameController,
                              maxLength: 80,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.name],
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                counterText: '',
                              ),
                              validator: (value) {
                                if (!_isSignUp) return null;
                                if (value == null || value.trim().length < 2) {
                                  return 'Enter a name with at least 2 characters.';
                                }
                                if (value.trim().length > 80) {
                                  return 'Name must be 80 characters or fewer.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            key: const ValueKey('account-email'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'you@example.com',
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(email)) {
                                return 'Enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          if (!_isResettingPassword) ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              key: const ValueKey('account-password'),
                              controller: _passwordController,
                              obscureText: true,
                              maxLength: 128,
                              autofillHints: [
                                _isSignUp
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                counterText: '',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter your password.';
                                }
                                if (_isSignUp && value.length < 12) {
                                  return 'Use at least 12 characters.';
                                }
                                if (value.length > 128) {
                                  return 'Password must be 128 characters or fewer.';
                                }
                                return null;
                              },
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              _error!,
                              style: const TextStyle(color: Color(0xFFFF9C9C)),
                            ),
                          ],
                          if (_error == null &&
                              widget.sessionError != null &&
                              !_isResettingPassword) ...[
                            const SizedBox(height: 14),
                            Text(
                              widget.sessionError!,
                              style: const TextStyle(color: Color(0xFFFF9C9C)),
                            ),
                          ],
                          if (_message != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              _message!,
                              style: const TextStyle(color: AppTheme.accent),
                            ),
                          ],
                          if (!widget.api.isConfigured) ...[
                            const SizedBox(height: 18),
                            const PreviewNotice(
                              title: 'Vistara server not configured',
                              message:
                                  'Set VISTARA_API_BASE_URL when building the '
                                  'app to enable account sign-in and password '
                                  'recovery.',
                            ),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 48,
                            child: FilledButton(
                              onPressed: _isBusy || !widget.api.isConfigured
                                  ? null
                                  : _submit,
                              child: Text(
                                _isBusy
                                    ? 'Please wait...'
                                    : _isResettingPassword
                                    ? 'Send reset instructions'
                                    : _isSignUp
                                    ? 'Create account'
                                    : 'Sign in',
                              ),
                            ),
                          ),
                          if (!_isSignUp && !_isResettingPassword)
                            Align(
                              alignment: Alignment.center,
                              child: TextButton(
                                onPressed: () => _changeMode(
                                  signUp: false,
                                  resetPassword: true,
                                ),
                                child: const Text('Forgot password?'),
                              ),
                            ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _changeMode(
                              signUp: !_isSignUp,
                              resetPassword: false,
                            ),
                            child: Text(
                              _isResettingPassword
                                  ? 'Back to sign in'
                                  : _isSignUp
                                  ? 'Already have an account? Sign in'
                                  : 'New to Vistara? Create an account',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
