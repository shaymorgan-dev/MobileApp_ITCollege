import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../db/database_helper.dart';

class StatsScreen extends StatefulWidget {
  final int userId;

  const StatsScreen({super.key, required this.userId});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static const _chartColors = [
    AppColors.forest,
    AppColors.coral,
    AppColors.sky,
    AppColors.lavender,
    AppColors.amber,
  ];

  late DateTime _month;
  List<Map<String, Object?>> _data = [];
  double _total = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _load();
  }

  Future<void> _load() async {
    final month = _month;
    final data = await DatabaseHelper.instance.statsByCategory(
      widget.userId,
      month,
    );
    final total = data.fold<double>(
      0,
      (sum, item) => sum + (item['total'] as num).toDouble(),
    );
    if (!mounted || month.year != _month.year || month.month != _month.month) {
      return;
    }
    setState(() {
      _data = data;
      _total = total;
      _loading = false;
    });
  }

  Future<void> _changeMonth(int offset) async {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
      _loading = true;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = _month.year == now.year && _month.month == now.month;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 28),
      children: [
        Text(
          'Ваши привычки',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 5),
        Text(
          'Расходы по категориям',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 17),
        _monthSelector(isCurrentMonth),
        const SizedBox(height: 18),
        if (_loading)
          const SizedBox(
            height: 260,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.forest),
            ),
          )
        else if (_data.isEmpty)
          _emptyState()
        else ...[
          _chartCard(),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(17, 8, 17, 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(children: List.generate(_data.length, _legendItem)),
          ),
        ],
      ],
    );
  }

  Widget _monthSelector(bool isCurrentMonth) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Предыдущий месяц',
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              formatMonth(_month),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Следующий месяц',
            onPressed: isCurrentMonth ? null : () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget _chartCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: ClipRect(
                    child: PieChart(
                      PieChartData(
                        sections: List.generate(_data.length, (index) {
                          final amount =
                              (_data[index]['total'] as num).toDouble();
                          final percent = amount / _total * 100;
                          return PieChartSectionData(
                            value: amount,
                            color: _chartColors[index % _chartColors.length],
                            title: percent >= 8 ? '${percent.round()}%' : '',
                            radius: 68,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        }),
                        sectionsSpace: 3,
                        centerSpaceRadius: 48,
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'ИТОГО',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatMoney(_total),
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Распределение трат за месяц',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _legendItem(int index) {
    final item = _data[index];
    final amount = (item['total'] as num).toDouble();
    final percent = _total == 0 ? 0 : amount / _total * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: _chartColors[index % _chartColors.length],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              item['category'] as String,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${percent.round()}%',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatMoney(amount),
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 34),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.donut_large_rounded,
              color: AppColors.forest,
              size: 28,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Пока нет данных',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Добавьте расходы за этот месяц — здесь появится наглядная статистика.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
