import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_theme.dart';
import '../db/database_helper.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isRegister = false;
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 4) {
      setState(() => _error = 'Введите email и пароль (не менее 4 символов)');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final db = DatabaseHelper.instance;
      final userId = _isRegister
          ? await db.register(email, password)
          : await db.login(email, password);
      if (userId == null) {
        setState(() {
          _error = _isRegister
              ? 'Аккаунт с таким email уже существует'
              : 'Проверьте email и пароль';
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', userId);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.forest,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.forest.withValues(alpha: 0.18),
                            blurRadius: 20,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 35,
                        color: AppColors.lime,
                      ),
                    ),
                  ),
                  const SizedBox(height: 27),
                  Text(
                    _isRegister ? 'Начнём вместе' : 'С возвращением',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRegister
                        ? 'Создайте аккаунт и возьмите расходы под контроль'
                        : 'Войдите, чтобы увидеть свои расходы',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 31),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                  ),
                  const SizedBox(height: 13),
                  TextField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: [
                      _isRegister
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    onSubmitted: (_) => _loading ? null : _submit(),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Показать пароль'
                            : 'Скрыть пароль',
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 13),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.coral,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isRegister ? 'Создать аккаунт' : 'Войти'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                            _isRegister = !_isRegister;
                            _error = null;
                          }),
                    child: Text(
                      _isRegister
                          ? 'Уже есть аккаунт? Войти'
                          : 'Создать новый аккаунт',
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: AppColors.muted,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Данные расходов хранятся на устройстве',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
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
