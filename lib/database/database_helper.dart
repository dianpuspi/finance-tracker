import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static sql.Database? _database;
  static const String dbName = 'finance_tracker.db';
  static const int dbVersion = 1;

  // Tables
  static const String tableUsers = 'users';
  static const String tableTransactions = 'transactions';

  // Columns
  static const String colId = 'id';
  static const String colName = 'name';
  static const String colUsername = 'username';
  static const String colPassword = 'password';
  static const String colType = 'type';
  static const String colAmount = 'amount';
  static const String colCategory = 'category';
  static const String colDescription = 'description';
  static const String colDateTime = 'date_time';
  static const String colUserId = 'user_id';

  Future<sql.Database> get database async {
    if (_database != null) return _database!;
    
    _database = await _initDatabase();
    return _database!;
  }

  Future<sql.Database> _initDatabase() async {
    final path = join(await sql.getDatabasesPath(), dbName);
    
    return await sql.openDatabase(
      path,
      version: dbVersion,
      onCreate: (db, version) async {
        // Create users table
        await db.execute('''
          CREATE TABLE $tableUsers (
            $colId INTEGER PRIMARY KEY AUTOINCREMENT,
            $colName TEXT NOT NULL,
            $colUsername TEXT UNIQUE NOT NULL,
            $colPassword TEXT NOT NULL
          )
        ''');

        // Create transactions table
        await db.execute('''
          CREATE TABLE $tableTransactions (
            $colId INTEGER PRIMARY KEY AUTOINCREMENT,
            $colType TEXT NOT NULL CHECK($colType IN ('income', 'expense')),
            $colAmount REAL NOT NULL,
            $colCategory TEXT NOT NULL,
            $colDescription TEXT NOT NULL,
            $colDateTime TEXT NOT NULL,
            $colUserId INTEGER NOT NULL,
            FOREIGN KEY ($colUserId) REFERENCES $tableUsers($colId) ON DELETE CASCADE
          )
        ''');

        // Create indexes
        await db.execute('CREATE INDEX idx_user_id ON $tableTransactions($colUserId)');
        await db.execute('CREATE INDEX idx_transaction_date ON $tableTransactions($colDateTime)');
        await db.execute('CREATE INDEX idx_username ON $tableUsers($colUsername)');
      },
    );
  }

  // ========== USER CRUD ==========
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert(tableUsers, user.toMap());
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query(
      tableUsers,
      where: '$colUsername = ?',
      whereArgs: [username],
    );
    
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query(
      tableUsers,
      where: '$colId = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      tableUsers,
      user.toMap(),
      where: '$colId = ?',
      whereArgs: [int.parse(user.id)],
    );
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query(tableUsers);
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  Future<int> updateUserPassword(int userId, String newPassword) async {
    final db = await database;
    return await db.update(
      tableUsers,
      {colPassword: newPassword},
      where: '$colId = ?',
      whereArgs: [userId],
    );
  }

  // ========== TRANSACTION CRUD ==========
  Future<int> insertTransaction(Transaction transaction, int userId) async {
    final db = await database;
    final map = transaction.toMap();
    map[colUserId] = userId;
    return await db.insert(tableTransactions, map);
  }

  Future<List<Transaction>> getTransactionsByUserId(int userId, {String? type}) async {
    final db = await database;
    
    String where = '$colUserId = ?';
    List<Object?> whereArgs = [userId];
    
    if (type != null) {
      where += ' AND $colType = ?';
      whereArgs.add(type);
    }
    
    final maps = await db.query(
      tableTransactions,
      where: where,
      whereArgs: whereArgs,
      orderBy: '$colDateTime DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  Future<Transaction?> getTransactionById(String id) async {
    final db = await database;
    final maps = await db.query(
      tableTransactions,
      where: '$colId = ?',
      whereArgs: [int.parse(id)],
    );
    
    if (maps.isNotEmpty) {
      return Transaction.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await database;
    return await db.update(
      tableTransactions,
      transaction.toMap(),
      where: '$colId = ?',
      whereArgs: [int.parse(transaction.id)],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete(
      tableTransactions,
      where: '$colId = ?',
      whereArgs: [int.parse(id)],
    );
  }

  // ========== ANALYTICS ==========
  Future<double> getTotalByType(int userId, String type) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM($colAmount) as total 
      FROM $tableTransactions 
      WHERE $colUserId = ? AND $colType = ?
    ''', [userId, type]);
    
    return result.first['total'] as double? ?? 0.0;
  }

  Future<Map<String, double>> getCategoryTotals(int userId, String type) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT $colCategory, SUM($colAmount) as total
      FROM $tableTransactions
      WHERE $colUserId = ? AND $colType = ?
      GROUP BY $colCategory
      ORDER BY total DESC
    ''', [userId, type]);
    
    final Map<String, double> totals = {};
    for (var row in result) {
      totals[row[colCategory] as String] = row['total'] as double;
    }
    return totals;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}