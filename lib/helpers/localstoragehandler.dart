import '../models/taskmodel.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart' as path;
import 'package:flutter/widgets.dart';

///Class that manages local storage via SQL (Not to be confused with SharedPreferences / NSUserDefaults)
///
///This class is made into a singleton and interacts with the sqflite package to deal with 
///locally storage. Contains methods to initialise, add, update and delete records.
///For this POC, the create table method is a little hardcoded to create a table that caters
///to storing the TaskModel. 
class LocalStorageHandler {

  static final LocalStorageHandler _instance = LocalStorageHandler._internal();
  late sqflite.Database _database;
  bool _isDBInitialised = false;

  factory LocalStorageHandler() {
    return _instance;
  }

  LocalStorageHandler._internal();

///Initialise database
  Future<void> initialiseDatabase() async {
    WidgetsFlutterBinding.ensureInitialized();

    final db = await sqflite
        .openDatabase(path.join(await sqflite.getDatabasesPath(), 'tasks_db'),
            onCreate: ((db, version) {
      // print("Database created, version is: $version");
      return;
    }), onConfigure: (database) {
      // print("Database opened");
      _database = database;
      _isDBInitialised = true;
      return;
    }, version: 1);
  }

///Initialise table. 
///
///Despite the parameters, this function presently is hardcoded to create a table based on 
///the TaskModel class. 
  Future<void> initialiseTable(String tableName) async {
    if (!_isDBInitialised) {
      print("Warning: " +
          "Database is not yet initialised. Have you tried calling 'initialiseDatabase()' yet?");
      return;
    }

    final db = _database;

    String sqlStatement =
        'CREATE TABLE $tableName(id STRING PRIMARY KEY, title TEXT, details TEXT, assigneeId INTEGER, isCompleted INTEGER, status INTEGER)';

    await db.execute(sqlStatement).whenComplete(() {
      print("Table creation completed");
    }).onError((error, stackTrace) {
      print("Table creation error: $error");
    });
  }

///Get data from the tablename provided in the param.
  Future<List<TaskModel>> getDataFromTable(String tableName) async {
    if (!_isDBInitialised) {
      print("Warning: " +
          "Database is not yet initialised. Have you tried calling 'initialiseDatabase()' yet?");
      return List<TaskModel>.empty();
    }

    final db = _database;

    final List<Map<String, dynamic>> maps = await db.query(tableName);

    return List.generate(maps.length, (i) {
      return TaskModel.fromMap(maps[i]);
    });
  }

///Insert data into the table.
  Future<void> insertDataIntoTable(
      String tableName, TaskModel taskModel) async {
    if (!_isDBInitialised) {
      print("Warning: " +
          "Database is not yet initialised. Have you tried calling 'initialiseDatabase()' yet?");
      return;
    }
    final db = _database;

    int affected = await db
        .insert(tableName, taskModel.toMap(),
            conflictAlgorithm: sqflite.ConflictAlgorithm.replace)
        .onError((error, stackTrace) {
      print("Error adding data into table: $error");
      return 0;
    });

    print("INSERT: $affected rows affected");
  }

///Update data in table with the new details.
  Future<void> updateDataInTable(String tableName, TaskModel taskModel) async {
    if (!_isDBInitialised) {
      print("Warning: " +
          "Database is not yet initialised. Have you tried calling 'initialiseDatabase()' yet?");
      return;
    }

    final db = _database;

    int affected = await db.update(tableName, taskModel.toMap(),
        where: 'id = ?',
        whereArgs: [taskModel.id]).onError((error, stackTrace) {
      print("Error updating data into table: $error");
      return 0;
    });

    print("UPDATE: $affected rows affected");
  }

///To remove data from the table
  Future<void> removeDataFromTable(
      String tableName, TaskModel taskModel) async {
    if (!_isDBInitialised) {
      print("Warning: " +
          "Database is not yet initialised. Have you tried calling 'initialiseDatabase()' yet?");
      return;
    }

    final db = _database;

    int affected = await db.delete(tableName,
        where: 'id = ?',
        whereArgs: [taskModel.id]).onError((error, stackTrace) {
      print("Error removing data from table: $error");
      return 0;
    });

    print("DELETE: $affected rows affected");
  }

//To completely clear the table.
  Future<void> clearTable(String tableName) async {
    if (!_isDBInitialised) {
      print("Warning: " +
          "Database is not yet initialised. Have you tried calling 'initialiseDatabase()' yet?");
      return;
    }

    final db = _database;
    var statement = 'DELETE FROM $tableName';

    await db.execute(statement).onError((error, stackTrace) {
      print("Error trying to clear table: $error");
    });
  }
}
