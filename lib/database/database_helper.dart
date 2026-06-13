import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/health_record.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  Database? _database;

  DatabaseHelper._();
  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = join(await getDatabasesPath(), 'healthcheck.db');
    return openDatabase(dbPath, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE health_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_type TEXT NOT NULL,
        date_time INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insert(HealthRecord record) async {
    final db = await database;
    return db.insert('health_records', record.toMap());
  }

  Future<List<HealthRecord>> getRecordsForDate(DateTime date) async {
    final db = await database;
    final start = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;
    final maps = await db.query(
      'health_records',
      where: 'date_time >= ? AND date_time <= ?',
      whereArgs: [start, end],
      orderBy: 'date_time ASC',
    );
    return maps.map(HealthRecord.fromMap).toList();
  }
}
