import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/lesson.dart';
import '../models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('lessons.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'المقرر العلمي'
      )
    ''');

    await db.execute('''
      CREATE TABLE lessons (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        video_id TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        lesson_id TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (lesson_id) REFERENCES lessons (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE notes (
          id TEXT PRIMARY KEY,
          lesson_id TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (lesson_id) REFERENCES lessons (id)
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE categories ADD COLUMN type TEXT NOT NULL DEFAULT "المقرر العلمي"',
      );
    }
  }

  // Category operations
  Future<String> insertCategory(Category category) async {
    final db = await database;
    await db.insert('categories', {
      'id': category.id,
      'name': category.name,
      'type': category.type,
    });
    return category.id;
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) {
      return Category(
        id: maps[i]['id'],
        name: maps[i]['name'],
        type: maps[i]['type'] ?? 'المقرر العلمي',
        lessons: [], // Will be populated separately
      );
    });
  }

  // Lesson operations
  Future<String> insertLesson(Lesson lesson, String categoryId) async {
    final db = await database;
    await db.insert('lessons', {
      'id': lesson.id,
      'category_id': categoryId,
      'title': lesson.title,
      'description': lesson.description,
      'video_id': lesson.videoId,
      'is_completed': lesson.isCompleted ? 1 : 0,
    });
    return lesson.id;
  }

  Future<List<Lesson>> getLessonsForCategory(String categoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lessons',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return List.generate(maps.length, (i) {
      return Lesson(
        id: maps[i]['id'],
        title: maps[i]['title'],
        description: maps[i]['description'],
        videoId: maps[i]['video_id'],
        categoryId: maps[i]['category_id'],
        isCompleted: maps[i]['is_completed'] == 1,
      );
    });
  }

  Future<void> updateLessonCompletion(String lessonId, bool isCompleted) async {
    final db = await database;
    await db.update(
      'lessons',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [lessonId],
    );
  }

  Future<void> deleteCategory(String categoryId) async {
    final db = await database;
    await db.delete(
      'lessons',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    await db.delete('categories', where: 'id = ?', whereArgs: [categoryId]);
  }

  Future<void> deleteLesson(String lessonId) async {
    final db = await database;
    await db.delete('lessons', where: 'id = ?', whereArgs: [lessonId]);
  }

  // Note operations
  Future<String> insertNote(Note note) async {
    final db = await database;
    await db.insert('notes', {
      'id': note.id,
      'lesson_id': note.lessonId,
      'content': note.content,
      'created_at': note.createdAt.millisecondsSinceEpoch,
    });
    return note.id;
  }

  Future<List<Note>> getNotesForLesson(String lessonId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) {
      return Note(
        id: maps[i]['id'],
        lessonId: maps[i]['lesson_id'],
        content: maps[i]['content'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['created_at']),
      );
    });
  }

  Future<void> deleteNote(String noteId) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [noteId]);
  }
}
