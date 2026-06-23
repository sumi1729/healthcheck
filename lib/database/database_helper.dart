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

  /// 既存レコードを id で更新。
  Future<int> update(HealthRecord record) async {
    final db = await database;
    return db.update(
      'health_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  /// 既存レコードを id で削除。
  Future<int> delete(int id) async {
    final db = await database;
    return db.delete(
      'health_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 指定範囲（両端含む）のレコードを日時昇順で取得。
  /// 実績画面では業務日を解決するため文脈を含む広めの範囲を渡す。
  Future<List<HealthRecord>> getRecordsInRange(
      DateTime startInclusive, DateTime endInclusive) async {
    final db = await database;
    final maps = await db.query(
      'health_records',
      where: 'date_time >= ? AND date_time <= ?',
      whereArgs: [
        startInclusive.millisecondsSinceEpoch,
        endInclusive.millisecondsSinceEpoch,
      ],
      orderBy: 'date_time ASC',
    );
    return maps.map(HealthRecord.fromMap).toList();
  }

  /// 指定時刻以前で最新の「就寝」または「起床」レコード。
  /// 中途覚醒の登録可否判定（直前の睡眠境界）に使用。なければ null。
  Future<HealthRecord?> getLatestSleepBoundaryBefore(DateTime t) async {
    final db = await database;
    final maps = await db.query(
      'health_records',
      where: 'date_time <= ? AND event_type IN (?, ?)',
      whereArgs: [t.millisecondsSinceEpoch, EventType.sleep, EventType.wakeUp],
      orderBy: 'date_time DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return HealthRecord.fromMap(maps.first);
  }
}
