import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/category.dart';
import '../models/lesson.dart';
import '../models/note.dart';
import '../helpers/lesson_helper.dart';
import '../helpers/note_helper.dart';
import '../utils/youtube_utils.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  String? _errorMessage;
  final _noteController = TextEditingController();
  List<Note> _notes = [];
  bool _isLoadingNotes = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.lesson.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        forceHD: true,
        useHybridComposition: true,
      ),
    );

    _controller.addListener(() {
      if (_controller.value.isReady && !_isPlayerReady) {
        setState(() {
          _isPlayerReady = true;
        });
      }
    });

    _loadNotes();
  }

  @override
  void dispose() {
    _controller.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoadingNotes = true;
    });

    try {
      final notes = await NoteHelper.instance.getNotesForLesson(
        widget.lesson.id,
      );
      setState(() {
        _notes = notes;
        _isLoadingNotes = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingNotes = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تحميل الملاحظات')),
        );
      }
    }
  }

  Future<void> _saveNote() async {
    if (_noteController.text.trim().isEmpty) return;

    try {
      final note = Note(
        id: 'note_${DateTime.now().millisecondsSinceEpoch}',
        lessonId: widget.lesson.id,
        content: _noteController.text.trim(),
        createdAt: DateTime.now(),
      );

      await NoteHelper.instance.addNote(note);
      _noteController.clear();
      await _loadNotes();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ الملاحظة بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء حفظ الملاحظة')),
        );
      }
    }
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await NoteHelper.instance.deleteNote(noteId);
      await _loadNotes();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف الملاحظة بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء حذف الملاحظة')),
        );
      }
    }
  }

  Future<void> _copyNoteToClipboard(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ الملاحظة إلى الحافظة')),
      );
    }
  }

  Future<void> _toggleLessonCompletion() async {
    final newValue = !widget.lesson.isCompleted;
    await LessonHelper.instance.updateLessonCompletion(
      widget.lesson.id,
      newValue,
    );
    setState(() {
      widget.lesson.isCompleted = newValue;
    });
  }

  Future<void> _copyAllNotes() async {
    if (_notes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا توجد ملاحظات للنسخ')));
      return;
    }

    final allNotes = StringBuffer();
    for (var i = 0; i < _notes.length; i++) {
      allNotes.writeln('${i + 1}- ${_notes[i].content}');
    }

    await Clipboard.setData(ClipboardData(text: allNotes.toString()));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم نسخ جميع الملاحظات')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          appBar: orientation == Orientation.portrait
              ? AppBar(
                  title: Text(widget.lesson.title),
                  actions: [
                    IconButton(
                      icon: Icon(
                        widget.lesson.isCompleted
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        color: widget.lesson.isCompleted
                            ? Colors.green.shade700
                            : null,
                      ),
                      onPressed: _toggleLessonCompletion,
                    ),
                  ],
                )
              : null,
          body: orientation == Orientation.portrait
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.4,
                        margin: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              YoutubePlayer(
                                controller: _controller,
                                showVideoProgressIndicator: true,
                                progressIndicatorColor: Colors.blue,
                                progressColors: const ProgressBarColors(
                                  playedColor: Colors.blue,
                                  handleColor: Colors.blueAccent,
                                ),
                                onReady: () {
                                  setState(() {
                                    _isPlayerReady = true;
                                    _errorMessage = null;
                                  });
                                },
                                onEnded: (data) {
                                  _toggleLessonCompletion();
                                },
                              ),
                              if (!_isPlayerReady)
                                const CircularProgressIndicator(),
                              if (_errorMessage != null)
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _errorMessage = null;
                                            _isPlayerReady = false;
                                          });
                                          _controller.load(
                                            widget.lesson.videoId,
                                          );
                                        },
                                        child: const Text('إعادة المحاولة'),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.lesson.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.lesson.description,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      _buildNotesSection(),
                    ],
                  ),
                )
              : YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.blue,
                  progressColors: const ProgressBarColors(
                    playedColor: Colors.blue,
                    handleColor: Colors.blueAccent,
                  ),
                  onReady: () {
                    setState(() {
                      _isPlayerReady = true;
                      _errorMessage = null;
                    });
                  },
                  onEnded: (data) {
                    _toggleLessonCompletion();
                  },
                ),
        );
      },
    );
  }

  Widget _buildNotesSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الملاحظات', style: Theme.of(context).textTheme.titleLarge),
              if (_notes.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy_all),
                  onPressed: _copyAllNotes,
                  tooltip: 'نسخ جميع الملاحظات',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'اكتب ملاحظتك هنا...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _saveNote, child: const Text('حفظ')),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingNotes)
            const Center(child: CircularProgressIndicator())
          else if (_notes.isEmpty)
            const Center(child: Text('لا توجد ملاحظات'))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () =>
                                      _copyNoteToClipboard(note.content),
                                  tooltip: 'نسخ الملاحظة',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteNote(note.id),
                                  tooltip: 'حذف الملاحظة',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(note.content),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
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
                            categoryId: widget.lesson.categoryId,
                          );
                          await LessonHelper.instance.addLesson(
                            lesson,
                            widget.lesson.categoryId,
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

    if (result == true && mounted) {
      Navigator.pop(context);
    }
  }
}
