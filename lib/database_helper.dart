import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'smart_home.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tạo bảng cho dữ liệu phòng
        await db.execute('''
          CREATE TABLE room_data (
            roomId TEXT PRIMARY KEY,
            temperature REAL,
            humidity REAL,
            light INTEGER,
            ac INTEGER,
            lastUpdate TEXT
          )
        ''');

        // Tạo bảng cho cảnh báo cháy
        await db.execute('''
          CREATE TABLE fire_alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            time TEXT,
            phone TEXT,
            status TEXT
          )
        ''');

        // Tạo bảng cho lịch sử kiểm soát ra vào
        await db.execute('''
          CREATE TABLE access_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            time TEXT,
            card TEXT,
            status TEXT
          )
        ''');
      },
    );
  }

  // Room Data
  Future<void> insertRoomData(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('room_data', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getRoomData(String roomId) async {
    final db = await database;
    final result = await db.query('room_data', where: 'roomId = ?', whereArgs: [roomId]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> updateDeviceState(String roomId, String device, int state) async {
    final db = await database;
    await db.update(
      'room_data',
      {device: state},
      where: 'roomId = ?',
      whereArgs: [roomId],
    );
  }

  // Fire Alerts
  Future<void> insertFireAlert(Map<String, String> alert) async {
    final db = await database;
    await db.insert('fire_alerts', alert);
  }

  Future<List<Map<String, dynamic>>> getFireAlerts() async {
    final db = await database;
    return await db.query('fire_alerts');
  }

  // Access History
  Future<void> insertAccessHistory(Map<String, String> entry) async {
    final db = await database;
    await db.insert('access_history', entry);
  }

  Future<List<Map<String, dynamic>>> getAccessHistory() async {
    final db = await database;
    return await db.query('access_history');
  }

  // Đóng database (tùy chọn, nếu cần)
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}