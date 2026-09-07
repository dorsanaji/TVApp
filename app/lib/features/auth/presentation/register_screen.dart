import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/avatar_picker.dart';
import '../../../router/app_router.dart';

/// FR-01 §5.1 — registration.
///
/// Collects all six fields the brief lists, with the two optional ones marked
/// as such. A duplicate username is rejected with a message naming
/// the offending field rather than a generic failure.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _bio = TextEditingController();

  bool _obscure = true;
  bool _busy = false;

  /// FR-01 lists the profile picture as optional, so this stays null unless
  /// the user chooses one.
  String? _avatarPath;

  /// Server-side errors keyed by field, so a duplicate username highlights the
  /// username box rather than appearing as a detached banner.
  final Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _username,
      _password,
      _bio,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(_fieldErrors.clear);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);

    final result = await ref
        .read(authRepositoryProvider)
        .register(
          firstName: _firstName.text,
          lastName: _lastName.text,
          username: _username.text,
          password: _password.text,
          bio: _bio.text.isEmpty ? null : _bio.text,
          avatarPath: _avatarPath,
        );

    if (!mounted) return;
    setState(() => _busy = false);

    final failure = result.failureOrNull;
    if (failure == null) {
      context.go(AppRoutes.home);
      return;
    }

    if (failure is ValidationFailure && failure.field != null) {
      setState(() => _fieldErrors[failure.field!] = failure.message);
      _formKey.currentState?.validate();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ثبت‌نام')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: AvatarPicker(
                    path: _avatarPath,
                    initial: _firstName.text.isEmpty
                        ? null
                        : _firstName.text.characters.first,
                    onChanged: (path) => setState(() => _avatarPath = path),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstName,
                        decoration: const InputDecoration(labelText: 'نام'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'نام را وارد کنید'
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _lastName,
                        decoration: const InputDecoration(
                          labelText: 'نام خانوادگی',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'نام خانوادگی را وارد کنید'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _username,
                  decoration: const InputDecoration(
                    labelText: 'شناسه (نام کاربری)',
                    helperText: 'با همین شناسه وارد می‌شوید',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: (v) {
                    if (_fieldErrors['username'] != null) {
                      return _fieldErrors['username'];
                    }
                    if (v == null || v.trim().length < 3) {
                      return 'شناسه باید حداقل ۳ نویسه باشد';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'رمز عبور',
                    helperText: 'حداقل ۸ نویسه',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 8)
                      ? 'رمز عبور باید حداقل ۸ نویسه باشد'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _bio,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات کوتاه (اختیاری)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('ثبت‌نام'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
