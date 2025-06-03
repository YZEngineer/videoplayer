import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/lesson.dart';
import '../helpers/lesson_helper.dart';
import '../utils/youtube_utils.dart';
import 'lesson_detail_screen.dart';

class CategoryLessonsScreen extends StatefulWidget {
  final Category category;

  const CategoryLessonsScreen({super.key, required this.category});

  @override
  State<CategoryLessonsScreen> createState() => _CategoryLessonsScreenState();
}

class _CategoryLessonsScreenState extends State<CategoryLessonsScreen> {
  late List<Lesson> _lessons;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _lessons = List.from(widget.category.lessons);
  }

  Future<void> _updateLessonCompletion(Lesson lesson, bool isCompleted) async {
    await LessonHelper.instance.updateLessonCompletion(lesson.id, isCompleted);
    setState(() {
      lesson.isCompleted = isCompleted;
    });
  }

  Future<void> _loadLessons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final lessons = await LessonHelper.instance.getLessonsForCategory(
        widget.category.id,
      );
      setState(() {
        _lessons = lessons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تحميل الدروس')),
        );
      }
    }
  }

  Future<void> _deleteLesson(Lesson lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الدرس'),
        content: const Text('هل أنت متأكد من حذف هذا الدرس؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await LessonHelper.instance.deleteLesson(lesson.id);
        await _loadLessons();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم حذف الدرس بنجاح')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ أثناء حذف الدرس')),
          );
        }
      }
    }
  }

  Future<void> _showAddLessonDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final videoIdController = TextEditingController();
    bool isLoading = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إضافة درس جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الدرس',
                    hintText: 'أدخل عنوان الدرس',
                  ),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'وصف الدرس',
                    hintText: 'أدخل وصف الدرس',
                  ),
                  maxLines: 3,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: videoIdController,
                  decoration: const InputDecoration(
                    labelText: 'رابط الفيديو',
                    hintText: 'أدخل رابط الفيديو من YouTube',
                  ),
                  enabled: !isLoading,
                ),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (titleController.text.isNotEmpty &&
                          descriptionController.text.isNotEmpty &&
                          videoIdController.text.isNotEmpty) {
                        setState(() => isLoading = true);
                        try {
                          final videoId = YoutubeUtils.extractVideoId(
                            videoIdController.text,
                          );
                          if (videoId == null) {
                            throw Exception('رابط الفيديو غير صالح');
                          }

                          final lesson = Lesson(
                            id: 'lesson_${DateTime.now().millisecondsSinceEpoch}',
                            title: titleController.text,
                            description: descriptionController.text,
                            videoId: videoId,
                            categoryId: widget.category.id,
                          );
                          await LessonHelper.instance.addLesson(
                            lesson,
                            widget.category.id,
                          );
                          if (mounted) {
                            Navigator.pop(context, true);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        } finally {
                          setState(() => isLoading = false);
                        }
                      }
                    },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _loadLessons();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLessons),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLessonDialog(context),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lessons.isEmpty
          ? const Center(child: Text('لا توجد دروس متاحة'))
          : ListView.builder(
              itemCount: _lessons.length,
              itemBuilder: (context, index) {
                final lesson = _lessons[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: lesson.isCompleted ? Colors.green.shade50 : null,
                  child: ListTile(
                    leading: Icon(
                      lesson.isCompleted
                          ? Icons.check_circle
                          : Icons.play_circle_outline,
                      color: lesson.isCompleted ? Colors.green.shade700 : null,
                    ),
                    title: Text(
                      lesson.title,
                      style: TextStyle(
                        color: lesson.isCompleted
                            ? Colors.green.shade700
                            : null,
                        fontWeight: lesson.isCompleted ? FontWeight.bold : null,
                      ),
                    ),
                    subtitle: Text(
                      lesson.description,
                      style: TextStyle(
                        color: lesson.isCompleted
                            ? Colors.green.shade700
                            : null,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteLesson(lesson),
                          tooltip: 'حذف الدرس',
                        ),
                        const Icon(Icons.arrow_forward_ios),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LessonDetailScreen(lesson: lesson),
                        ),
                      ).then((_) => _loadLessons());
                    },
                  ),
                );
              },
            ),
    );
  }
}
