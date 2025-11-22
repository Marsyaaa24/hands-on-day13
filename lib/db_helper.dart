import 'package:flutter_note/models/note_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static const String _databaseName = "notes.db";
  static const String _tableName = "notes";
  static const int _databaseVersion = 1;

  DbHelper._privateConstructor();
  static final DbHelper instance = DbHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initialDatabase();
    return _database!;
  }

  Future<Database> _initialDatabase() async {
    return await openDatabase(
      join(await getDatabasesPath(), _databaseName),
      version: _databaseVersion,
      onCreate: (db, version) async {
        await createTable(db);
      },
    );
  }

  Future createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        note_id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        pinned INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<int> insertItem(NoteModel note) async {
    final db = await database;
    return await db.insert(
      _tableName,
      note.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateItem(NoteModel note) async {
    final db = await database;

    final newData = note.toJson();

    newData['updated_at'] = DateTime.now().toIso8601String();

    return await db.update(
      _tableName,
      newData,
      where: "note_id = ?",
      whereArgs: [note.noteId],
    );
  }

  Future<int> updateNote(NoteModel note) => updateItem(note);


  Future<int> deleteNote(int id) async {
    final db = await database;

    return await db.delete(
      _tableName,
      where: "note_id = ?",
      whereArgs: [id],
    );
  }

  Future<List<NoteModel>> fetchNotes() async {
    final db = await database;

    final maps = await db.query(
      _tableName,
      orderBy: "pinned DESC, created_at DESC",
    );

    if (maps.isEmpty) return [];

    return List.generate(
      maps.length,
      (i) => NoteModel.fromJson(maps[i]),
    );
  }
}
