class Lesson {
  final String id;
  final String title;
  final String description;
  final String videoId;
  final String categoryId;
  bool isCompleted;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.videoId,
    required this.categoryId,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'video_id': videoId,
      'category_id': categoryId,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      videoId: map['video_id'],
      categoryId: map['category_id'],
      isCompleted: map['is_completed'] == 1,
    );
  }
}
