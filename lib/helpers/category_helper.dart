import '../models/category.dart';
import '../models/lesson.dart';
import '../database/database_helper.dart';

class CategoryHelper {
  static final CategoryHelper instance = CategoryHelper._init();
  CategoryHelper._init();

  Future<List<Category>> getAllCategories() async {
    final categories = await DatabaseHelper.instance.getAllCategories();
    for (var category in categories) {
      category.lessons = await DatabaseHelper.instance.getLessonsForCategory(
        category.id,
      );
    }
    return categories;
  }

  Future<void> addCategory(Category category) async {
    await DatabaseHelper.instance.insertCategory(category);
  }

  Future<void> deleteCategory(String categoryId) async {
    await DatabaseHelper.instance.deleteCategory(categoryId);
  }

  Future<void> reloadDefaultCategories() async {
    // Get existing categories and lessons
    final existingCategories = await DatabaseHelper.instance.getAllCategories();
    final existingCategoryIds = existingCategories.map((c) => c.id).toSet();
    final existingLessons = <String, Set<String>>{};

    for (var category in existingCategories) {
      final lessons = await DatabaseHelper.instance.getLessonsForCategory(
        category.id,
      );
      existingLessons[category.id] = lessons.map((l) => l.id).toSet();
    }

    // Define default categories and lessons
    final defaultCategories = [
      Category(
        id: 'cat_1',
        name: 'أساسيات البرمجة',
        type: 'المقرر العلمي',
        lessons: [
          Lesson(
            id: 'lesson_1_1',
            title: 'مقدمة في البرمجة',
            description: 'تعرف على أساسيات البرمجة والمفاهيم الأساسية',
            videoId: 'bVOrIqeJ3XE',
            categoryId: 'cat_1',
          ),
          Lesson(
            id: 'lesson_1_2',
            title: 'المتغيرات والأنواع',
            description: 'تعلم كيفية استخدام المتغيرات والأنواع المختلفة',
            videoId: 'bVOrIqeJ3XE',
            categoryId: 'cat_1',
          ),
        ],
      ),
      Category(
        id: 'cat_2',
        name: 'تطوير تطبيقات الموبايل',
        type: 'المقرر العلمي',
        lessons: [
          Lesson(
            id: 'lesson_2_1',
            title: 'مقدمة في Flutter',
            description: 'تعرف على إطار عمل Flutter وأساسياته',
            videoId: 'bVOrIqeJ3XE',
            categoryId: 'cat_2',
          ),
          Lesson(
            id: 'lesson_2_2',
            title: 'تصميم واجهات المستخدم',
            description: 'تعلم كيفية تصميم واجهات المستخدم الجميلة',
            videoId: 'bVOrIqeJ3XE',
            categoryId: 'cat_2',
          ),
        ],
      ),
      Category(
        id: 'cat_3',
        name: 'قواعد البيانات',
        type: 'المقرر العلمي',
        lessons: [
          Lesson(
            id: 'lesson_3_1',
            title: 'مقدمة في SQLite',
            description: 'تعرف على قواعد البيانات SQLite',
            videoId: 'bVOrIqeJ3XE',
            categoryId: 'cat_3',
          ),
          Lesson(
            id: 'lesson_3_2',
            title: 'عمليات CRUD',
            description: 'تعلم عمليات إنشاء وقراءة وتحديث وحذف البيانات',
            videoId: 'bVOrIqeJ3XE',
            categoryId: 'cat_3',
          ),
        ],
      ),
      // فئات المقرر المهاري العملي
      Category(
        id: 'cat_4',
        name: 'الذكاء الاصطناعي',
        type: 'المقرر المهاري العملي',
        lessons: [
          Lesson(
            id: 'lesson_4_1',
            title: 'مقدمة في الذكاء الاصطناعي',
            description: 'تعرف على أساسيات الذكاء الاصطناعي',
            videoId: 'bVOrIqeJ3XE',
            categoryId: 'cat_4',
          ),
          Lesson(
            id: 'lesson_4_2',
            title: 'تعلم الآلة',
            description: 'تعلم أساسيات تعلم الآلة وتطبيقاته',
            videoId: 'bVOrIqeJ3XE',
            categoryId: 'cat_4',
          ),
        ],
      ),
      Category(
        id: 'cat_5',
        name: 'تطوير الويب',
        type: 'المقرر المهاري العملي',
        lessons: [
          Lesson(
            id: 'lesson_5_1',
            title: 'HTML و CSS',
            description: 'تعلم أساسيات تطوير الويب',
            videoId: 'bVOrIqeJ3XE',
            categoryId: 'cat_5',
          ),
          Lesson(
            id: 'lesson_5_2',
            title: 'JavaScript',
            description: 'تعلم برمجة JavaScript وتطبيقاتها',
            videoId: 'bVOrIqeJ3XE',
            categoryId: 'cat_5',
          ),
        ],
      ),
    ];

    // Add missing categories and their lessons
    for (var category in defaultCategories) {
      if (!existingCategoryIds.contains(category.id)) {
        // Add new category
        await DatabaseHelper.instance.insertCategory(category);
        // Add all lessons for new category
        for (var lesson in category.lessons) {
          await DatabaseHelper.instance.insertLesson(lesson, category.id);
        }
      } else {
        // Category exists, check for missing lessons
        final existingLessonIds = existingLessons[category.id] ?? {};
        for (var lesson in category.lessons) {
          if (!existingLessonIds.contains(lesson.id)) {
            // Add only missing lessons
            await DatabaseHelper.instance.insertLesson(lesson, category.id);
          }
        }
      }
    }
  }
}
