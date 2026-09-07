import 'package:sqflite/sqflite.dart';

import 'notification_database_service.dart';

/// Service managing persistent key-value app settings via SQLite (SQFlite).
/// Provides robust local SQLite database persistence.
class SettingsDatabaseService {
  SettingsDatabaseService._();
  static final SettingsDatabaseService instance = SettingsDatabaseService._();

  Future<Database> get _db => NotificationDatabaseService.instance.database;

  static const String _table = NotificationDatabaseService.tableSettings;

  /// Saves a boolean setting in the SQLite database.
  Future<void> setBool(String key, bool value) async {
    final db = await _db;
    await db.insert(
      _table,
      {
        'key': key,
        'value': value ? '1' : '0',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves a boolean setting from the SQLite database.
  /// Returns null if the key has not been set yet.
  Future<bool?> getBool(String key) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      _table,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] == '1';
    }
    return null;
  }

  /// Saves a string setting in the SQLite database.
  Future<void> setString(String key, String value) async {
    final db = await _db;
    await db.insert(
      _table,
      {
        'key': key,
        'value': value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves a string setting from the SQLite database.
  Future<String?> getString(String key) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      _table,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  /// Removes a setting key from the SQLite database.
  Future<int> remove(String key) async {
    final db = await _db;
    return await db.delete(
      _table,
      where: 'key = ?',
      whereArgs: [key],
    );
  }
}
