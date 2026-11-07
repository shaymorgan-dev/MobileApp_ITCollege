import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class HistoryScreen extends StatefulWidget {
  final int userId;
  const HistoryScreen({super.key, required this.userId});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, Object?>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await DatabaseHelper.instance.getTransactions(widget.userId);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return const Center(child: Text('Нет расходов. Добавьте первый!'));
    }
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final t = _items[i];
        final date = DateTime.parse(t['date'] as String);
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.attach_money)),
          title: Text(t['category'] as String),
          subtitle: Text(
              '${date.day}.${date.month}.${date.year}  ${t['note'] ?? ''}'),
          trailing: Text(
            '${(t['amount'] as num).toStringAsFixed(2)} ₽',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.red),
          ),
        );
      },
    );
  }
}