import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_theme.dart';
import '../db/database_helper.dart';
import 'add_expense_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _userId = 0;
  int _tab = 0;
  double _total = 0;
  double _budget = 0;
  bool _loading = true;
  List<Map<String, Object?>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _budgetKey(DateTime date) =>
      'monthly_budget_${_userId}_${date.year}_${date.month}';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    final now = DateTime.now();
    final total = await DatabaseHelper.instance.totalForMonth(userId, now);
    final transactions =
        await DatabaseHelper.instance.getTransactions(userId);
    if (!mounted) return;
    setState(() {
      _userId = userId;
      _total = total;
      _budget = prefs.getDouble(_budgetKey(now)) ?? 0;
      _transactions = transactions;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _openAddExpense() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => AddExpenseScreen(userId: _userId)),
    );
    if (mounted) await _load();
  }

  Future<void> _setBudget() async {
    final controller = TextEditingController(
      text: _budget > 0 ? _budget.toStringAsFixed(0) : '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Бюджет на месяц'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Сумма',
            prefixIcon: Icon(Icons.currency_ruble_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;

    final amount = double.tryParse(result.replaceAll(',', '.'));
    if (amount == null || !amount.isFinite || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите сумму больше нуля')),
      );
      return;
    }

    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_budgetKey(now), amount);
    if (!mounted) return;
    setState(() => _budget = amount);
  }

  List<Map<String, Object?>> get _monthTransactions {
    final now = DateTime.now();
    return _transactions.where((transaction) {
      final date = DateTime.parse(transaction['date'] as String);
      return date.year == now.year && date.month == now.month;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.forest),
        ),
      );
    }

    final titles = ['Обзор', 'История', 'Аналитика'];
    final pages = [
      _dashboard(),
      HistoryScreen(userId: _userId),
      StatsScreen(userId: _userId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.forest,
                size: 20,
              ),
            ),
            const SizedBox(width: 11),
            Text(titles[_tab]),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Выйти из аккаунта',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: pages[_tab],
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: _openAddExpense,
              backgroundColor: AppColors.lime,
              foregroundColor: AppColors.ink,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Добавить расход',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.mint,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'История',
          ),
          NavigationDestination(
            icon: Icon(Icons.donut_large_outlined),
            selectedIcon: Icon(Icons.donut_large_rounded),
            label: 'Аналитика',
          ),
        ],
      ),
    );
  }

  Widget _dashboard() {
    final now = DateTime.now();
    final monthTransactions = _monthTransactions;
    final recent = monthTransactions.take(3).toList();
    final progress =
        _budget > 0 ? (_total / _budget).clamp(0.0, 1.0).toDouble() : 0.0;
    final remaining = _budget - _total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        Text(
          'Ваши финансы,',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          'под контролем',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.forest,
              ),
        ),
        const SizedBox(height: 7),
        Text(
          formatMonth(now),
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 22),
        _summaryCard(now, monthTransactions.length),
        const SizedBox(height: 16),
        _budgetCard(progress, remaining),
        const SizedBox(height: 27),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Последние расходы',
                style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () => setState(() => _tab = 1),
              child: const Text('Все'),
            ),
          ],
        ),
        const SizedBox(height: 5),
        if (recent.isEmpty)
          _emptyRecent()
        else
          ...recent.map(_expenseTile),
      ],
    );
  }

  Widget _summaryCard(DateTime month, int transactionCount) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.forest, AppColors.forestDark],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'РАСХОДЫ ЗА МЕСЯЦ',
                  style: TextStyle(
                    color: Color(0xFFD0DED7),
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.trending_down_rounded,
                color: AppColors.lime.withValues(alpha: 0.95),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formatMoney(_total),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFFD0DED7),
                size: 17,
              ),
              const SizedBox(width: 7),
              Text(
                formatMonth(month),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFFD0DED7),
                size: 17,
              ),
              const SizedBox(width: 7),
              Text(
                '$transactionCount ${_expenseWord(transactionCount)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _budgetCard(double progress, double remaining) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Бюджет на месяц',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: _budget > 0 ? 'Изменить бюджет' : 'Задать бюджет',
                onPressed: _setBudget,
                icon: Icon(
                  _budget > 0 ? Icons.edit_outlined : Icons.add_rounded,
                  color: AppColors.forest,
                ),
              ),
            ],
          ),
          if (_budget <= 0)
            Padding(
              padding: const EdgeInsets.only(left: 52, right: 8, bottom: 4),
              child: Text(
                'Задайте лимит, чтобы следить за расходами',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else ...[
            const SizedBox(height: 11),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                backgroundColor: AppColors.canvas,
                valueColor: AlwaysStoppedAnimation(
                  remaining >= 0 ? AppColors.forest : AppColors.coral,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    remaining >= 0
                        ? 'Осталось ${formatMoney(remaining)}'
                        : 'Превышено на ${formatMoney(remaining.abs())}',
                    style: TextStyle(
                      color: remaining >= 0 ? AppColors.muted : AppColors.coral,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'из ${formatMoney(_budget)}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyRecent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: const Row(
        children: [
          Icon(Icons.spa_outlined, color: AppColors.forest, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Пока нет расходов за этот месяц. Добавьте первый!',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expenseTile(Map<String, Object?> transaction) {
    final iconName = transaction['icon'] as String? ?? 'more_horiz';
    final color = categoryColor(iconName);
    final note = (transaction['note'] as String?)?.trim() ?? '';
    final date = DateTime.parse(transaction['date'] as String);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _categoryAvatar(iconName, color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['category'] as String,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note.isEmpty ? formatDate(date) : note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '−${formatMoney(transaction['amount'] as num)}',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryAvatar(String icon, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(categoryIcon(icon), color: color, size: 21),
    );
  }

  String _expenseWord(int count) {
    final lastTwo = count % 100;
    if (lastTwo >= 11 && lastTwo <= 14) return 'расходов';
    return switch (count % 10) {
      1 => 'расход',
      2 || 3 || 4 => 'расхода',
      _ => 'расходов',
    };
  }
}
