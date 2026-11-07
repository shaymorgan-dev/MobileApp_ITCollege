import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'expenses.db');
    return openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('''CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE,
        password_hash TEXT
      )''');
      await db.execute('''CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT,
        icon TEXT
      )''');
      await db.execute('''CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        amount REAL,
        category_id INTEGER,
        date TEXT,
        note TEXT
      )''');
    });
  }

  String hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  Future<int?> register(String email, String password) async {
    final db = await database;
    try {
      final id = await db.insert('users', {
        'email': email,
        'password_hash': hash(password),
      });
      await _seedCategories(id);
      return id;
    } catch (_) {
      return null;
    }
  }

  Future<int?> login(String email, String password) async {
    final db = await database;
    final r = await db.query('users',
        where: 'email = ? AND password_hash = ?',
        whereArgs: [email, hash(password)]);
    if (r.isEmpty) return null;
    return r.first['id'] as int;
  }

  Future<void> _seedCategories(int userId) async {
    final db = await database;
    final cats = [
      ['Еда', 'restaurant'],
      ['Транспорт', 'directions_bus'],
      ['Развлечения', 'movie'],
      ['Покупки', 'shopping_bag'],
      ['Другое', 'more_horiz'],
    ];
    for (final c in cats) {
      await db.insert('categories', {
        'user_id': userId,
        'name': c[0],
        'icon': c[1],
      });
    }
  }

  Future<List<Map<String, Object?>>> getCategories(int userId) async {
    final db = await database;
    return db.query('categories', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<void> addTransaction(int userId, double amount,
      int categoryId, String note, DateTime date) async {
    final db = await database;
    await db.insert('transactions', {
      'user_id': userId,
      'amount': amount,
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'note': note,
    });
  }

  Future<List<Map<String, Object?>>> getTransactions(int userId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT t.id, t.amount, t.date, t.note,
             c.name as category, c.icon as icon
      FROM transactions t
      JOIN categories c ON c.id = t.category_id
      WHERE t.user_id = ?
      ORDER BY t.date DESC
    ''', [userId]);
  }

  Future<double> totalForMonth(int userId, DateTime month) async {
    final db = await database;
    final start = DateTime(month.year, month.month, 1).toIso8601String();
    final end = DateTime(month.year, month.month + 1, 1).toIso8601String();
    final r = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE user_id = ? AND date >= ? AND date < ?',
      [userId, start, end],
    );
    return (r.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Map<String, Object?>>> statsByCategory(
      int userId, DateTime month) async {
    final db = await database;
    final start = DateTime(month.year, month.month, 1).toIso8601String();
    final end = DateTime(month.year, month.month + 1, 1).toIso8601String();
    return db.rawQuery('''
      SELECT c.name as category, SUM(t.amount) as total
      FROM transactions t
      JOIN categories c ON c.id = t.category_id
      WHERE t.user_id = ? AND t.date >= ? AND t.date < ?
      GROUP BY c.id
      ORDER BY total DESC
    ''', [userId, start, end]);
  }
}