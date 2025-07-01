import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  DbHelper._privateConstructor();
  static final DbHelper instance = DbHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'investments.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE operations(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            isin TEXT NOT NULL,
            date INTEGER NOT NULL,
            value_unit REAL NOT NULL,
            quantity REAL NOT NULL DEFAULT 1
          )
        ''');
      },
    );
  }

  Future<int> insertOperation(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('operations', row);
  }

  Future<List<Map<String, dynamic>>> getOperations() async {
    final db = await database;
    return await db.query('operations', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getPositions() async {
    final db = await database;
    return await db.rawQuery(
        'SELECT isin, SUM(quantity) as quantity FROM operations GROUP BY isin');
  }
}
