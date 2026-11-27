import 'package:flutter/material.dart';

import '../app_theme.dart';
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
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseHelper.instance.getCategories(
      widget.userId,
    );
    if (!mounted) return;
    setState(() {
      _categories = categories;
      if (categories.isNotEmpty) {
        _categoryId = categories.first['id'] as int;
      }
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme
              .copyWith(primary: AppColors.forest, surface: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    if (amount == null || !amount.isFinite || amount <= 0) {
      setState(() => _error = 'Введите сумму больше нуля');
      return;
    }
    if (_categoryId == null) {
      setState(() => _error = 'Выберите категорию');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _saving = true;
    });

    try {
      await DatabaseHelper.instance.addTransaction(
        widget.userId,
        amount,
        _categoryId!,
        _note.text.trim(),
        _date,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Новый расход'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.forest),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Сколько потратили?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amount,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0',
                        prefixIcon: Icon(Icons.currency_ruble_rounded),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      'Категория',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (_categories.isEmpty)
                      const Text(
                        'Категории не найдены. Перезайдите в аккаунт и попробуйте снова.',
                        style: TextStyle(color: AppColors.coral),
                      )
                    else
                      Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: _categories.map(_categoryChip).toList(),
                      ),
                    const SizedBox(height: 23),
                    Text(
                      'Дата',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    _datePickerTile(),
                    const SizedBox(height: 23),
                    Text(
                      'Комментарий',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _note,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        hintText: 'Например, обед с коллегами',
                        prefixIcon: Icon(Icons.notes_rounded),
                        counterText: '',
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.coral,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: FilledButton.icon(
            onPressed: _loading || _saving || _categories.isEmpty
                ? null
                : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_saving ? 'Сохраняем…' : 'Сохранить расход'),
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(Map<String, Object?> category) {
    final id = category['id'] as int;
    final selected = _categoryId == id;
    final name = category['icon'] as String? ?? 'more_horiz';
    final color = categoryColor(name);

    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(categoryIcon(name), size: 18, color: color),
      label: Text(category['name'] as String),
      labelStyle: TextStyle(
        color: selected ? AppColors.forest : AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.mint,
      side: BorderSide(color: selected ? AppColors.forest : AppColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (_) => setState(() {
        _categoryId = id;
        _error = null;
      }),
    );
  }

  Widget _datePickerTile() {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.forest,
                size: 19,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  formatDate(_date),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
