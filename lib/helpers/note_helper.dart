import '../models/note.dart';
import '../database/database_helper.dart';

class NoteHelper {
  static final NoteHelper instance = NoteHelper._init();
  NoteHelper._init();

  Future<List<Note>> getNotesForLesson(String lessonId) async {
    return await DatabaseHelper.instance.getNotesForLesson(lessonId);
  }

  Future<void> addNote(Note note) async {
    await DatabaseHelper.instance.insertNote(note);
  }

  Future<void> deleteNote(String noteId) async {
    await DatabaseHelper.instance.deleteNote(noteId);
  }
}
