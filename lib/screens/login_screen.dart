import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _error;

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _password.text;
    if (email.isEmpty || pass.length < 4) {
      setState(() => _error = 'Введите email и пароль (мин. 4 символа)');
      return;
    }
    final db = DatabaseHelper.instance;
    int? uid;
    if (_isRegister) {
      uid = await db.register(email, pass);
      if (uid == null) {
        setState(() => _error = 'Пользователь уже существует');
        return;
      }
    } else {
      uid = await db.login(email, pass);
      if (uid == null) {
        setState(() => _error = 'Неверный email или пароль');
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', uid);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isRegister ? 'Регистрация' : 'Вход')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet,
                size: 80, color: Colors.teal),
            const SizedBox(height: 24),
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                  labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Пароль', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(_isRegister ? 'Зарегистрироваться' : 'Войти'),
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _isRegister = !_isRegister;
                _error = null;
              }),
              child: Text(_isRegister
                  ? 'У меня уже есть аккаунт'
                  : 'Создать аккаунт'),
            ),
          ],
        ),
      ),
    );
  }
}