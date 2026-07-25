import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';
import '../models/notebook.dart';
import '../models/tag.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sanket_notes.db');

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notebooks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        notebookId INTEGER,
        FOREIGN KEY (notebookId) REFERENCES notebooks (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tags(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE note_tags(
        noteId INTEGER,
        tagId INTEGER,
        PRIMARY KEY (noteId, tagId),
        FOREIGN KEY (noteId) REFERENCES notes (id) ON DELETE CASCADE,
        FOREIGN KEY (tagId) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Notes CRUD ---
  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  Future<List<Note>> getNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes', orderBy: 'updatedAt DESC');
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  Future<List<Note>> getNotesByNotebook(int notebookId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'notebookId = ?',
      whereArgs: [notebookId],
      orderBy: 'updatedAt DESC'
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // --- Notebooks CRUD ---
  Future<int> insertNotebook(Notebook notebook) async {
    final db = await database;
    return await db.insert('notebooks', notebook.toMap());
  }

  Future<List<Notebook>> getNotebooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notebooks');
    return List.generate(maps.length, (i) => Notebook.fromMap(maps[i]));
  }

  Future<int> updateNotebook(Notebook notebook) async {
    final db = await database;
    return await db.update('notebooks', notebook.toMap(), where: 'id = ?', whereArgs: [notebook.id]);
  }

  Future<int> deleteNotebook(int id) async {
    final db = await database;
    return await db.delete('notebooks', where: 'id = ?', whereArgs: [id]);
  }

  // --- Tags CRUD ---
  Future<int> insertTag(Tag tag) async {
    final db = await database;
    return await db.insert('tags', tag.toMap());
  }

  Future<List<Tag>> getTags() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tags');
    return List.generate(maps.length, (i) => Tag.fromMap(maps[i]));
  }

  Future<int> updateTag(Tag tag) async {
    final db = await database;
    return await db.update('tags', tag.toMap(), where: 'id = ?', whereArgs: [tag.id]);
  }

  Future<int> deleteTag(int id) async {
    final db = await database;
    return await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  // --- Note-Tag Relationship ---
  Future<void> assignTagToNote(int noteId, int tagId) async {
    final db = await database;
    await db.insert('note_tags', {'noteId': noteId, 'tagId': tagId}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeTagFromNote(int noteId, int tagId) async {
    final db = await database;
    await db.delete('note_tags', where: 'noteId = ? AND tagId = ?', whereArgs: [noteId, tagId]);
  }

  Future<List<Tag>> getTagsForNote(int noteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT tags.* FROM tags
      INNER JOIN note_tags ON tags.id = note_tags.tagId
      WHERE note_tags.noteId = ?
    ''', [noteId]);
    return List.generate(maps.length, (i) => Tag.fromMap(maps[i]));
  }

  Future<List<Note>> getNotesForTag(int tagId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT notes.* FROM notes
      INNER JOIN note_tags ON notes.id = note_tags.noteId
      WHERE note_tags.tagId = ?
      ORDER BY notes.updatedAt DESC
    ''', [tagId]);
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }
}
