import 'lesson.dart';

class Category {
  final String id;
  final String name;
  final String type;
  List<Lesson> lessons;

  Category({
    required this.id,
    required this.name,
    this.type = 'المقرر العلمي',
    List<Lesson>? lessons,
  }) : lessons = lessons ?? [];

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'type': type};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      type: map['type'] ?? 'المقرر العلمي',
      lessons: [],
    );
  }
}
