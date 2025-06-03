import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/lesson.dart';
import '../helpers/category_helper.dart';
import 'lessons_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if database is empty
      final categories = await CategoryHelper.instance.getAllCategories();
      if (categories.isEmpty) {
        // Add initial data
        await CategoryHelper.instance.reloadDefaultCategories();
      }
      await _loadCategories();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryHelper.instance.getAllCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  bool _isCategoryCompleted(Category category) {
    return category.lessons.every((lesson) => lesson.isCompleted);
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الفئة'),
        content: const Text(
          'هل أنت متأكد من حذف هذه الفئة؟ سيتم حذف جميع الدروس المرتبطة بها.',
        ),
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
        await CategoryHelper.instance.deleteCategory(category.id);
        await _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم حذف الفئة بنجاح')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ أثناء حذف الفئة')),
          );
        }
      }
    }
  }

  Future<void> _reloadDefaultLessons() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تحميل الدروس الافتراضية'),
        content: const Text(
          'سيتم إضافة الدروس الافتراضية المفقودة فقط. الدروس التي أضفتها لن تتأثر.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إعادة التحميل'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await CategoryHelper.instance.reloadDefaultCategories();
        await _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إعادة تحميل الدروس الافتراضية بنجاح'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ أثناء إعادة تحميل الدروس الافتراضية'),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الفئات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _reloadDefaultLessons,
            tooltip: 'إعادة تحميل الدروس الافتراضية',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? const Center(child: Text('لا توجد فئات متاحة'))
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isCompleted = _isCategoryCompleted(category);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: isCompleted ? Colors.green.shade50 : null,
                  child: ListTile(
                    leading: Icon(
                      Icons.folder,
                      color: isCompleted ? Colors.green.shade700 : null,
                    ),
                    title: Text(
                      category.name,
                      style: TextStyle(
                        color: isCompleted ? Colors.green.shade700 : null,
                        fontWeight: isCompleted ? FontWeight.bold : null,
                      ),
                    ),
                    subtitle: Text(
                      '${category.lessons.length} دروس',
                      style: TextStyle(
                        color: isCompleted ? Colors.green.shade700 : null,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteCategory(category),
                          tooltip: 'حذف الفئة',
                        ),
                        const Icon(Icons.arrow_forward_ios),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CategoryLessonsScreen(category: category),
                        ),
                      ).then((_) => _loadCategories());
                    },
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final nameController = TextEditingController();
    bool isLoading = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إضافة فئة جديدة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الفئة',
                  hintText: 'أدخل اسم الفئة',
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
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.isNotEmpty) {
                        setState(() => isLoading = true);
                        try {
                          final category = Category(
                            id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                            name: nameController.text,
                            lessons: [],
                          );
                          await CategoryHelper.instance.addCategory(category);
                          if (mounted) {
                            Navigator.pop(context, true);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('حدث خطأ أثناء إضافة الفئة'),
                              ),
                            );
                          }
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
      await _loadCategories();
    }
  }
}
