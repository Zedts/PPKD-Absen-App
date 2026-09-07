import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/app_notification_model.dart';

/// Database service managing persistent notifications in SQLite via SQFlite.
/// Located in `core/database/` per architecture guidelines.
class NotificationDatabaseService {
  NotificationDatabaseService._();
  static final NotificationDatabaseService instance =
      NotificationDatabaseService._();

  static const String _dbName = 'ppkd_absen.db';
  static const int _dbVersion = 1;
  static const String tableNotifications = 'notifications';
  static const String tableSettings = 'app_settings';

  final _changeController = StreamController<void>.broadcast();
  Stream<void> get onDatabaseChanged => _changeController.stream;

  void notifyDatabaseChanged() {
    if (!_changeController.isClosed) {
      _changeController.add(null);
    }
  }

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableNotifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await _createSettingsTable(db);

    // Insert initial "Selamat Datang" dummy notification on first run
    await db.insert(tableNotifications, {
      'title': 'Selamat Datang di PPKD Absensi!',
      'message':
          'Aplikasi presensi siap digunakan. Pastikan GPS aktif dan berada di radius kantor untuk melakukan absensi.',
      'type': 'welcome',
      'timestamp': DateTime.now().toIso8601String(),
      'is_read': 0,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSettingsTable(db);
    }
  }

  Future<void> _onOpen(Database db) async {
    await _createSettingsTable(db);
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSettings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// Fetches all notifications ordered from newest to oldest.
  Future<List<AppNotificationModel>> getAllNotifications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableNotifications,
      orderBy: 'id DESC',
    );
    return maps.map((m) => AppNotificationModel.fromMap(m)).toList();
  }

  /// Inserts a new notification and returns its generated integer ID.
  Future<int> insertNotification(AppNotificationModel notification) async {
    final db = await database;
    final id = await db.insert(
      tableNotifications,
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyDatabaseChanged();
    return id;
  }

  /// Marks a specific notification as read (`is_read = 1`).
  Future<int> markAsRead(int id) async {
    final db = await database;
    final res = await db.update(
      tableNotifications,
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyDatabaseChanged();
    return res;
  }

  /// Deletes all notifications from the database.
  Future<int> deleteAllNotifications() async {
    final db = await database;
    final res = await db.delete(tableNotifications);
    notifyDatabaseChanged();
    return res;
  }

  /// Returns the count of unread notifications (`is_read = 0`).
  Future<int> getUnreadCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM $tableNotifications WHERE is_read = 0',
    ));
    return count ?? 0;
  }
}
