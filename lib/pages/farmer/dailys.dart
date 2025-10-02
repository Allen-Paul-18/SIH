import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DailysPage extends StatefulWidget {
  const DailysPage({Key? key}) : super(key: key);

  @override
  State<DailysPage> createState() => _DailysPageState();
}

class _DailysPageState extends State<DailysPage> {
  final TextEditingController _taskController = TextEditingController();
  List<Task> _tasks = [];
  TaskFilter _currentFilter = TaskFilter.all;
  String _selectedCategory = 'Daily';

  final List<String> _categories = [
    'Daily',
    'Weekly',
    'Livestock',
    'Equipment',
    'Feeding',
    'Health',
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  // Load tasks from SharedPreferences
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      final List<dynamic> decoded = json.decode(tasksJson);
      setState(() {
        _tasks = decoded.map((item) => Task.fromJson(item)).toList();
      });
    }
  }

  // Save tasks to SharedPreferences
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString('tasks', encoded);
  }

  // Add new task
  void _addTask() {
    if (_taskController.text.trim().isEmpty) return;

    setState(() {
      _tasks.add(Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _taskController.text.trim(),
        category: _selectedCategory,
        isCompleted: false,
        isUrgent: false,
        createdAt: DateTime.now(),
      ));
      _taskController.clear();
    });
    _saveTasks();
  }

  // Remove task with confirmation
  void _removeTask(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _tasks.removeWhere((task) => task.id == id);
              });
              _saveTasks();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Toggle task completion
  void _toggleComplete(String id) {
    setState(() {
      final index = _tasks.indexWhere((task) => task.id == id);
      if (index != -1) {
        _tasks[index].isCompleted = !_tasks[index].isCompleted;
        // Move completed tasks to bottom
        if (_tasks[index].isCompleted) {
          final task = _tasks.removeAt(index);
          _tasks.add(task);
        }
      }
    });
    _saveTasks();
  }

  // Toggle urgent status
  void _toggleUrgent(String id) {
    setState(() {
      final index = _tasks.indexWhere((task) => task.id == id);
      if (index != -1) {
        _tasks[index].isUrgent = !_tasks[index].isUrgent;
      }
    });
    _saveTasks();
  }

  // Edit task
  void _editTask(Task task) {
    final controller = TextEditingController(text: task.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Task'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Task Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  final index = _tasks.indexWhere((t) => t.id == task.id);
                  if (index != -1) {
                    _tasks[index].title = controller.text.trim();
                  }
                });
                _saveTasks();
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Get filtered tasks
  List<Task> get _filteredTasks {
    List<Task> filtered = _tasks;

    switch (_currentFilter) {
      case TaskFilter.pending:
        filtered = filtered.where((t) => !t.isCompleted).toList();
        break;
      case TaskFilter.completed:
        filtered = filtered.where((t) => t.isCompleted).toList();
        break;
      case TaskFilter.urgent:
        filtered = filtered.where((t) => t.isUrgent && !t.isCompleted).toList();
        break;
      case TaskFilter.all:
        break;
    }

    return filtered;
  }

  // Group tasks by category
  Map<String, List<Task>> get _groupedTasks {
    final filtered = _filteredTasks;
    final Map<String, List<Task>> grouped = {};

    for (var task in filtered) {
      if (!grouped.containsKey(task.category)) {
        grouped[task.category] = [];
      }
      grouped[task.category]!.add(task);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Tasks'),
        backgroundColor: Colors.green[700],
        elevation: 0,
        actions: [
          PopupMenuButton<TaskFilter>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) {
              setState(() {
                _currentFilter = filter;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TaskFilter.all,
                child: Text('All Tasks'),
              ),
              const PopupMenuItem(
                value: TaskFilter.pending,
                child: Text('Pending Only'),
              ),
              const PopupMenuItem(
                value: TaskFilter.completed,
                child: Text('Completed Only'),
              ),
              const PopupMenuItem(
                value: TaskFilter.urgent,
                child: Text('Urgent Only'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Add Task Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green[700],
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _taskController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter task name...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.add_task, color: Colors.white),
                        ),
                        onSubmitted: (_) => _addTask(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Category Selection
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          backgroundColor: Colors.white.withOpacity(0.2),
                          selectedColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.green[700] : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Filter: ${_currentFilter.toString().split('.').last.toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                Text(
                  '${_filteredTasks.length} tasks',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Tasks List
          Expanded(
            child: _filteredTasks.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks yet!',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a task to get started',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
                : ReorderableListView(
              padding: const EdgeInsets.all(16),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final filtered = _filteredTasks;
                  final task = filtered.removeAt(oldIndex);
                  filtered.insert(newIndex, task);

                  // Update the main list
                  _tasks.clear();
                  for (var category in _groupedTasks.keys) {
                    _tasks.addAll(_groupedTasks[category]!);
                  }
                });
                _saveTasks();
              },
              children: _groupedTasks.entries.map((entry) {
                return ExpansionTile(
                  key: Key(entry.key),
                  initiallyExpanded: true,
                  leading: Icon(
                    _getCategoryIcon(entry.key),
                    color: Colors.green[700],
                  ),
                  title: Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text('${entry.value.length} tasks'),
                  children: entry.value.map((task) {
                    return TaskItem(
                      key: Key(task.id),
                      task: task,
                      onToggle: () => _toggleComplete(task.id),
                      onDelete: () => _removeTask(task.id),
                      onEdit: () => _editTask(task),
                      onToggleUrgent: () => _toggleUrgent(task.id),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Daily':
        return Icons.today;
      case 'Weekly':
        return Icons.calendar_month;
      case 'Livestock':
        return Icons.pets;
      case 'Equipment':
        return Icons.build;
      case 'Feeding':
        return Icons.restaurant;
      case 'Health':
        return Icons.medical_services;
      default:
        return Icons.task;
    }
  }
}

// Task Item Widget
class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onToggleUrgent;

  const TaskItem({
    Key? key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onToggleUrgent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: const Text('Are you sure?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 8, left: 16),
        decoration: BoxDecoration(
          color: task.isUrgent
              ? Colors.red[50]
              : (task.isCompleted ? Colors.grey[100] : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task.isUrgent
                ? Colors.red[300]!
                : (task.isCompleted ? Colors.grey[300]! : Colors.grey[200]!),
            width: task.isUrgent ? 2 : 1,
          ),
          boxShadow: task.isUrgent
              ? [
            BoxShadow(
              color: Colors.red.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (_) => onToggle(),
            activeColor: Colors.green[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? Colors.grey : Colors.black87,
              fontWeight: task.isUrgent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: task.isUrgent
              ? Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red[700]),
              const SizedBox(width: 4),
              Text(
                'URGENT',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  task.isUrgent ? Icons.priority_high : Icons.flag_outlined,
                  color: task.isUrgent ? Colors.red[700] : Colors.grey,
                ),
                onPressed: onToggleUrgent,
                tooltip: 'Mark as urgent',
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                onPressed: onEdit,
                tooltip: 'Edit task',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Delete task',
              ),
            ],
          ),
          onTap: onEdit,
        ),
      ),
    );
  }
}

// Task Model
class Task {
  String id;
  String title;
  String category;
  bool isCompleted;
  bool isUrgent;
  DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.category,
    required this.isCompleted,
    required this.isUrgent,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'isCompleted': isCompleted,
    'isUrgent': isUrgent,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    category: json['category'],
    isCompleted: json['isCompleted'],
    isUrgent: json['isUrgent'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

// Filter Enum
enum TaskFilter { all, pending, completed, urgent }