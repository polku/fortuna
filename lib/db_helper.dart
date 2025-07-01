import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  DbHelper._privateConstructor();
  static final DbHelper instance = DbHelper._privateConstructor();

  static const int _dbVersion = 2;

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
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE operations(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            isin TEXT NOT NULL,
            date INTEGER NOT NULL,
            value_unit REAL NOT NULL,
            quantity REAL NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE operations RENAME TO operations_old');
          await db.execute('''
            CREATE TABLE operations(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              isin TEXT NOT NULL,
              date INTEGER NOT NULL,
              value_unit REAL NOT NULL,
              quantity REAL NOT NULL
            )
          ''');
          await db.execute('''
            INSERT INTO operations(id, isin, date, value_unit, quantity)
            SELECT id, isin, date, value_unit, 1 FROM operations_old
          ''');
          await db.execute('DROP TABLE operations_old');
        }
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
        'SELECT isin, SUM(quantity) as quantity, '
        'SUM(value_unit * quantity) as cost '
        'FROM operations GROUP BY isin');
  }
}
