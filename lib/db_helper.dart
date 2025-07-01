import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  DbHelper._privateConstructor();
  static final DbHelper instance = DbHelper._privateConstructor();

  static const int _dbVersion = 3;

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
        await db.execute('''
          CREATE TABLE assets(
            isin TEXT PRIMARY KEY,
            ticker TEXT,
            name TEXT,
            price REAL,
            last_update INTEGER
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
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS assets(
              isin TEXT PRIMARY KEY,
              ticker TEXT,
              name TEXT,
              price REAL,
              last_update INTEGER
            )
          ''');
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
        'SELECT o.isin, SUM(o.quantity) as quantity, '
        'SUM(o.value_unit * o.quantity) as cost, '
        'a.price, a.ticker, a.name, a.last_update '
        'FROM operations o '
        'LEFT JOIN assets a ON o.isin = a.isin '
        'GROUP BY o.isin');
  }

  Future<void> upsertAsset(
      String isin, String ticker, String name, double price, int timestamp) async {
    final db = await database;
    await db.insert(
      'assets',
      {
        'isin': isin,
        'ticker': ticker,
        'name': name,
        'price': price,
        'last_update': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getAsset(String isin) async {
    final db = await database;
    final res = await db.query('assets', where: 'isin = ?', whereArgs: [isin]);
    if (res.isEmpty) return null;
    return res.first;
  }

  Future<List<Map<String, dynamic>>> getAllAssets() async {
    final db = await database;
    return db.query('assets');
  }
}
