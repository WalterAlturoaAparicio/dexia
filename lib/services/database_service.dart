import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/prediction.dart';

/// RF08 – Almacenamiento Local (Offline) usando SQLite.
/// v2: agrega columnas latitud, longitud, direccion (RF05).
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
      version: 2,
      onCreate: (db, _) => _createV2(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migración v1 → v2: agregar columnas GPS
          await db.execute(
              'ALTER TABLE avistamientos ADD COLUMN latitud  REAL');
          await db.execute(
              'ALTER TABLE avistamientos ADD COLUMN longitud REAL');
          await db.execute(
              'ALTER TABLE avistamientos ADD COLUMN direccion TEXT');
        }
      },
    );
  }

  Future<void> _createV2(Database db) async {
    await db.execute('''
      CREATE TABLE avistamientos (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        imagenPath        TEXT    NOT NULL,
        especieNombre     TEXT    NOT NULL,
        especieCientifico TEXT    NOT NULL,
        especieId         TEXT    NOT NULL,
        confianza         REAL    NOT NULL,
        fechaHora         TEXT    NOT NULL,
        synced            INTEGER NOT NULL DEFAULT 0,
        latitud           REAL,
        longitud          REAL,
        direccion         TEXT
      )
    ''');
  }

  /// Inserta un avistamiento y devuelve el registro con su [id] asignado.
  Future<Avistamiento> insertAvistamiento(Avistamiento av) async {
    final db = await database;
    final id = await db.insert('avistamientos', av.toMap());
    return av.copyWith(id: id);
  }

  /// Todos los avistamientos, más recientes primero.
  Future<List<Avistamiento>> getAllAvistamientos() async {
    final db = await database;
    final rows =
        await db.query('avistamientos', orderBy: 'fechaHora DESC');
    return rows.map(Avistamiento.fromMap).toList();
  }

  /// Solo los que tienen coordenadas GPS (para el mapa, RF06).
  Future<List<Avistamiento>> getConUbicacion() async {
    final db = await database;
    final rows = await db.query(
      'avistamientos',
      where: 'latitud IS NOT NULL AND longitud IS NOT NULL',
      orderBy: 'fechaHora DESC',
    );
    return rows.map(Avistamiento.fromMap).toList();
  }

  /// Pendientes de sincronizar con el backend (RF09 – futuro).
  Future<List<Avistamiento>> getUnsynced() async {
    final db = await database;
    final rows =
        await db.query('avistamientos', where: 'synced = 0');
    return rows.map(Avistamiento.fromMap).toList();
  }

  Future<void> markSynced(int id) async {
    final db = await database;
    await db.update('avistamientos', {'synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAvistamiento(int id) async {
    final db = await database;
    await db
        .delete('avistamientos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async => _db?.close();
}
