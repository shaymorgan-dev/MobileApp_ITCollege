import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const canvas = Color(0xFFF5F7F3);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1D302B);
  static const muted = Color(0xFF7C8B85);
  static const forest = Color(0xFF194D3C);
  static const forestDark = Color(0xFF12372D);
  static const mint = Color(0xFFDCEEE4);
  static const lime = Color(0xFFD4F078);
  static const line = Color(0xFFE7ECE7);
  static const coral = Color(0xFFE9846A);
  static const lavender = Color(0xFFA695D2);
  static const sky = Color(0xFF78AFC0);
  static const amber = Color(0xFFDEA856);
}

IconData categoryIcon(String name) {
  return switch (name) {
    'restaurant' => Icons.restaurant_rounded,
    'directions_bus' => Icons.directions_bus_rounded,
    'movie' => Icons.local_activity_rounded,
    'shopping_bag' => Icons.shopping_bag_rounded,
    _ => Icons.more_horiz_rounded,
  };
}

Color categoryColor(String name) {
  return switch (name) {
    'restaurant' => AppColors.coral,
    'directions_bus' => AppColors.sky,
    'movie' => AppColors.lavender,
    'shopping_bag' => AppColors.amber,
    _ => AppColors.forest,
  };
}

String formatMoney(num amount) {
  final value = amount % 1 == 0
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
  return '$value ₽';
}

String formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

const russianMonths = [
  'январь',
  'февраль',
  'март',
  'апрель',
  'май',
  'июнь',
  'июль',
  'август',
  'сентябрь',
  'октябрь',
  'ноябрь',
  'декабрь',
];

String formatMonth(DateTime date) =>
    '${russianMonths[date.month - 1]} ${date.year}';
