import '../models/lesson.dart';
import '../database/database_helper.dart';

class LessonHelper {
  static final LessonHelper instance = LessonHelper._init();
  LessonHelper._init();

  Future<List<Lesson>> getLessonsForCategory(String categoryId) async {
    return await DatabaseHelper.instance.getLessonsForCategory(categoryId);
  }

  Future<void> addLesson(Lesson lesson, String categoryId) async {
    await DatabaseHelper.instance.insertLesson(lesson, categoryId);
  }

  Future<void> deleteLesson(String lessonId) async {
    await DatabaseHelper.instance.deleteLesson(lessonId);
  }

  Future<void> updateLessonCompletion(String lessonId, bool isCompleted) async {
    await DatabaseHelper.instance.updateLessonCompletion(lessonId, isCompleted);
  }
}
