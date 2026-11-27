import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Расходы',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.forest,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.forest,
          secondary: AppColors.lime,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: AppColors.ink,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
          titleLarge: TextStyle(
            color: AppColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: AppColors.ink, fontSize: 16),
          bodyMedium: TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.ink,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          hintStyle: const TextStyle(color: AppColors.muted, fontSize: 15),
          labelStyle: const TextStyle(color: AppColors.muted, fontSize: 15),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.forest,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
