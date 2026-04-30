import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/prediction.dart';

/// RF08 – Almacenamiento Local (Offline) using SQLite via sqflite.
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dexia.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE avistamientos (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            imagenPath  TEXT    NOT NULL,
            especieNombre     TEXT NOT NULL,
            especieCientifico TEXT NOT NULL,
            especieId         TEXT NOT NULL,
            confianza   REAL    NOT NULL,
            fechaHora   TEXT    NOT NULL,
            synced      INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  /// Insert a new sighting and return the record with the assigned [id].
  Future<Avistamiento> insertAvistamiento(Avistamiento av) async {
    final db = await database;
    final id = await db.insert('avistamientos', av.toMap());
    return av.copyWith(id: id);
  }

  /// Returns all sightings ordered by most recent first.
  Future<List<Avistamiento>> getAllAvistamientos() async {
    final db = await database;
    final rows = await db.query(
      'avistamientos',
      orderBy: 'fechaHora DESC',
    );
    return rows.map(Avistamiento.fromMap).toList();
  }

  /// Returns only records not yet synced to the cloud (RF09 – future use).
  Future<List<Avistamiento>> getUnsynced() async {
    final db = await database;
    final rows =
        await db.query('avistamientos', where: 'synced = 0');
    return rows.map(Avistamiento.fromMap).toList();
  }

  /// Mark a sighting as synced (RF09 – future use).
  Future<void> markSynced(int id) async {
    final db = await database;
    await db.update(
      'avistamientos',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAvistamiento(int id) async {
    final db = await database;
    await db.delete('avistamientos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async => _db?.close();
}
