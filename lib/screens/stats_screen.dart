import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/database_helper.dart';

class StatsScreen extends StatefulWidget {
  final int userId;
  const StatsScreen({super.key, required this.userId});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Map<String, Object?>> _data = [];
  double _total = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseHelper.instance
        .statsByCategory(widget.userId, DateTime.now());
    double total = 0;
    for (final d in data) {
      total += (d['total'] as num).toDouble();
    }
    if (!mounted) return;
    setState(() {
      _data = data;
      _total = total;
      _loading = false;
    });
  }

  Color _color(int i) {
    final colors = [
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.blue,
      Colors.red,
      Colors.green
    ];
    return colors[i % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) {
      return const Center(child: Text('Нет данных за этот месяц'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: PieChart(
              PieChartData(
                sections: List.generate(_data.length, (i) {
                  final d = _data[i];
                  final val = (d['total'] as num).toDouble();
                  final pct = _total == 0 ? 0 : (val / _total * 100);
                  return PieChartSectionData(
                    value: val,
                    color: _color(i),
                    title: '${pct.toStringAsFixed(0)}%',
                    radius: 85,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  );
                }),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_data.length, (i) {
            final d = _data[i];
            return ListTile(
              leading: Container(
                  width: 16, height: 16, color: _color(i)),
              title: Text(d['category'] as String),
              trailing: Text(
                  '${(d['total'] as num).toStringAsFixed(2)} ₽'),
            );
          }),
          const Divider(),
          ListTile(
            title: const Text('Итого',
                style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              '${_total.toStringAsFixed(2)} ₽',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.teal),
            ),
          ),
        ],
      ),
    );
  }
}