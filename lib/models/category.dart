import 'lesson.dart';

class Category {
  final String id;
  final String name;
  List<Lesson> lessons;

  Category({required this.id, required this.name, List<Lesson>? lessons})
    : lessons = lessons ?? [];

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(id: map['id'], name: map['name'], lessons: []);
  }
}
