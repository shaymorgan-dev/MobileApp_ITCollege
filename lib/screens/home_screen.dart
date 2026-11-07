import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';
import 'add_expense_screen.dart';
import 'history_screen.dart';
import 'stats_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _userId = 0;
  int _tab = 0;
  double _total = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id') ?? 0;
    final total =
        await DatabaseHelper.instance.totalForMonth(_userId, DateTime.now());
    if (!mounted) return;
    setState(() {
      _total = total;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pages = [
      _dashboard(),
      HistoryScreen(userId: _userId),
      StatsScreen(userId: _userId),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои расходы'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: pages[_tab],
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddExpenseScreen(userId: _userId)),
                );
                _load();
                setState(() {});
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) async {
          setState(() => _tab = i);
          if (i == 0) await _load();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.list), label: 'История'),
          NavigationDestination(
              icon: Icon(Icons.pie_chart), label: 'Статистика'),
        ],
      ),
    );
  }

  Widget _dashboard() {
    final now = DateTime.now();
    const months = ['январь','февраль','март','апрель','май','июнь',
        'июль','август','сентябрь','октябрь','ноябрь','декабрь'];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${months[now.month - 1]} ${now.year}',
              style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Потрачено за месяц', style: TextStyle(fontSize: 16)),
          Text('${_total.toStringAsFixed(2)} ₽',
              style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal)),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Как добавить расход?',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                      'Нажмите «+» внизу, выберите категорию и введите сумму.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}