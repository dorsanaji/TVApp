import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/services/emailjs_sender.dart';

/// FR-03 §5.3 — password recovery via email.
///
/// Two steps: request a code, then use it to set a new password. The code is
/// hashed at rest, expires after 15 minutes, and is consumed on use.
///
/// **On delivery.** See `email_sender.dart`: an app with no server cannot send
/// mail without shipping credentials that anyone could extract from the APK
/// (NFR-15). The whole flow is implemented; only the transport is pluggable.
/// While the development sender is in use, the code is shown on screen and
/// labelled as such, so the requirement is demonstrable end to end.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;
  String? _error;
  String? _debugCode;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'ایمیل را وارد کنید');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    await ref.read(authRepositoryProvider).requestPasswordReset(_email.text);
    if (!mounted) return;

    // Show the code on screen only when email delivery did not happen —
    // either EmailJS is unconfigured, or the send failed. When it did arrive,
    // printing it defeats the point of emailing it.
    final sender = ref.read(emailSenderProvider);
    final delivered =
        sender is EmailSenderWithFallback && sender.lastDeliverySucceeded;

    setState(() {
      _busy = false;
      _codeSent = true;
      _debugCode = delivered
          ? null
          : ref.read(debugEmailSenderProvider).lastCode;
    });
  }

  Future<void> _reset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await ref
        .read(authRepositoryProvider)
        .resetPassword(
          email: _email.text,
          code: _code.text,
          newPassword: _password.text,
        );

    if (!mounted) return;

    final failure = result.failureOrNull;
    setState(() {
      _busy = false;
      _error = failure?.message;
    });

    if (failure == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رمز عبور با موفقیت تغییر کرد')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('بازیابی رمز عبور')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _codeSent && _debugCode == null
                      ? 'کد بازیابی به ایمیل شما ارسال شد. صندوق ورودی و پوشه‌ی هرزنامه را بررسی کنید.'
                      : 'ایمیل حساب خود را وارد کنید تا کد بازیابی برای شما ارسال شود.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _email,
                  enabled: !_codeSent,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'ایمیل',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                if (_codeSent) ...[
                  if (_debugCode != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Card(
                      color: theme.colorScheme.tertiaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              EmailJsSender.isConfigured
                                  ? 'ارسال ایمیل ناموفق بود — کد را از اینجا بردارید'
                                  : 'حالت توسعه — ارسال ایمیل پیکربندی نشده است',
                              style: theme.textTheme.labelSmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            SelectableText(
                              'کد بازیابی: $_debugCode',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'کد بازیابی',
                      prefixIcon: Icon(Icons.pin_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'کد بازیابی را وارد کنید'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'رمز عبور جدید',
                      helperText: 'حداقل ۸ نویسه',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) => (v == null || v.length < 8)
                        ? 'رمز عبور باید حداقل ۸ نویسه باشد'
                        : null,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: _busy ? null : (_codeSent ? _reset : _requestCode),
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_codeSent ? 'تغییر رمز عبور' : 'ارسال کد بازیابی'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
