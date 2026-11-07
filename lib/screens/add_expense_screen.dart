import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class AddExpenseScreen extends StatefulWidget {
  final int userId;
  const AddExpenseScreen({super.key, required this.userId});
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  int? _categoryId;
  List<Map<String, Object?>> _categories = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await DatabaseHelper.instance.getCategories(widget.userId);
    setState(() {
      _categories = cats;
      if (cats.isNotEmpty) _categoryId = cats.first['id'] as int;
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Введите корректную сумму');
      return;
    }
    if (_categoryId == null) {
      setState(() => _error = 'Выберите категорию');
      return;
    }
    await DatabaseHelper.instance.addTransaction(
      widget.userId,
      amount,
      _categoryId!,
      _note.text.trim(),
      _date,
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  IconData _icon(String name) {
    switch (name) {
      case 'restaurant': return Icons.restaurant;
      case 'directions_bus': return Icons.directions_bus;
      case 'movie': return Icons.movie;
      case 'shopping_bag': return Icons.shopping_bag;
      default: return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новый расход')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Сумма, ₽', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text('Категория',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _categories.map((c) {
                final selected = _categoryId == c['id'];
                return ChoiceChip(
                  label: Text(c['name'] as String),
                  avatar: Icon(_icon(c['icon'] as String), size: 18),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _categoryId = c['id'] as int),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                  'Дата: ${_date.day}.${_date.month}.${_date.year}'),
              trailing: const Icon(Icons.edit),
              onTap: _pickDate,
            ),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                  labelText: 'Комментарий (необязательно)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: _save, child: const Text('Сохранить')),
            ),
          ],
        ),
      ),
    );
  }
}