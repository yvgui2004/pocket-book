import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class DB {
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'pocket_book.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL
          )
        ''');
        await db.execute(
            'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
      },
    );
    return _db!;
  }

  static Future<List<Entry>> loadEntries() async {
    final db = await instance;
    final rows = await db.query('entries', orderBy: 'date ASC, id ASC');
    return rows.map(Entry.fromMap).toList();
  }

  static Future<Entry> insertEntry(Entry e) async {
    final db = await instance;
    final map = e.toMap()..remove('id');
    final id = await db.insert('entries', map);
    return Entry(id: id, name: e.name, amount: e.amount, date: e.date);
  }

  static Future<void> deleteEntry(int id) async {
    final db = await instance;
    await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Map<String, String>> loadSettings() async {
    final db = await instance;
    final rows = await db.query('settings');
    return {
      for (final r in rows) r['key'] as String: r['value'] as String,
    };
  }

  static Future<void> saveSetting(String key, String value) async {
    final db = await instance;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}