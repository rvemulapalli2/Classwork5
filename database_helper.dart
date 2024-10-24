import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'aquarium_settings.db');
    return await openDatabase(
      path,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE settings(id INTEGER PRIMARY KEY, fishCount INTEGER, fishSpeed REAL, fishColor INTEGER)',
        );
      },
      version: 1,
    );
  }

  Future<void> saveSettings(
      int fishCount, double fishSpeed, int fishColor) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'id': 1,
        'fishCount': fishCount,
        'fishSpeed': fishSpeed,
        'fishColor': fishColor
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> settings =
        await db.query('settings', where: 'id = ?', whereArgs: [1]);

    if (settings.isNotEmpty) {
      return settings.first;
    }
    return null;
  }

  Future<void> clearSettings() async {
    final db = await database;
    await db.delete('settings');
  }
}
