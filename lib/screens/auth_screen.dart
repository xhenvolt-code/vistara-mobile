import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  static const _googleServerClientId = String.fromEnvironment(
    'VISTARA_GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '516759701042-1j43chkqtgl8hf49j0cql8gf34sun3e9.apps.googleusercontent.com',
  );
  static final Future<void> _googleSignInInitialization = GoogleSignIn.instance
      .initialize(serverClientId: _googleServerClientId);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isResettingPassword = false;
  bool _isBusy = false;
  String? _error;
  String? _message;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isBusy = true;
      _error = null;
      _message = null;
    });

    try {
      await _googleSignInInitialization;
      final googleSignIn = GoogleSignIn.instance;
      if (!googleSignIn.supportsAuthenticate()) {
        throw const VistaraApiException(
          'Google sign-in is not available on this device.',
        );
      }

      final account = await googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const VistaraApiException(
          'Google did not return an identity token. Check the Google '
          'sign-in configuration and try again.',
        );
      }

      final session = await widget.api.signInWithGoogle(idToken: idToken);
      if (mounted) Navigator.of(context).pop(session);
    } on GoogleSignInException catch (error) {
      if (!mounted || error.code == GoogleSignInExceptionCode.canceled) return;
      setState(() {
        _error =
            error.description ??
            'Google sign-in could not be completed. Check the app’s Google '
                'OAuth client and Android signing certificate configuration.';
      });
    } on VistaraApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

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
                            style: TextStyle(
                              color: context.vistara.muted,
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
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          if (_error == null &&
                              widget.sessionError != null &&
                              !_isResettingPassword) ...[
                            const SizedBox(height: 14),
                            Text(
                              widget.sessionError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          if (_message != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              _message!,
                              style: TextStyle(color: context.vistara.accent),
                            ),
                          ],
                          if (!widget.api.isConfigured) ...[
                            const SizedBox(height: 18),
                            const PreviewNotice(
                              title: 'Vistara server not configured',
                              message:
                                  'Use a connected Vistara API origin to '
                                  'enable account sign-in and password recovery.',
                            ),
                          ],
                          if (!_isResettingPassword) ...[
                            const SizedBox(height: 18),
                            SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: _isBusy || !widget.api.isConfigured
                                    ? null
                                    : _signInWithGoogle,
                                icon: const Icon(Icons.account_circle_outlined),
                                label: const Text('Continue with Google'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'or continue with email',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: context.vistara.muted),
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
