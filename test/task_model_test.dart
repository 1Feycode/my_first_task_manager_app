import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/models/task.dart';
import 'package:task_manager/screens/home_screen.dart';

void main() {
  test('Task model stores expected values and defaults to not completed', () {
    final task = Task(
      id: '1',
      title: 'Write project plan',
      description: 'Draft a simple plan for the sprint',
      dueDate: '2026-11-12',
      priority: 'High',
    );

    expect(task.id, '1');
    expect(task.title, 'Write project plan');
    expect(task.description, 'Draft a simple plan for the sprint');
    expect(task.dueDate, '2026-11-12');
    expect(task.priority, 'High');
    expect(task.isCompleted, isFalse);
  });

  test('Home screen filter and stats logic returns the expected task counts', () {
    final tasks = [
      Task(id: '1', title: 'Task 1', description: '', dueDate: 'Today', priority: 'High'),
      Task(id: '2', title: 'Task 2', description: '', dueDate: 'Tomorrow', priority: 'Medium', isCompleted: true),
      Task(id: '3', title: 'Task 3', description: '', dueDate: 'Thu 12', priority: 'Low'),
    ];

    final allTasks = HomeScreen.filterTasks('All', tasks);
    final pendingTasks = HomeScreen.filterTasks('Pending', tasks);
    final completedTasks = HomeScreen.filterTasks('Completed', tasks);
    final stats = HomeScreen.calculateTaskStats(tasks);

    expect(allTasks.length, 3);
    expect(pendingTasks.length, 2);
    expect(completedTasks.length, 1);
    expect(stats['total'], 3);
    expect(stats['pending'], 2);
    expect(stats['completed'], 1);
  });

  test('Task JSON serialization round-trips correctly', () {
    const jsonMap = {
      'id': '42',
      'title': 'Read chapter',
      'description': 'Finish the chapter before dinner',
      'dueDate': '2026-11-12',
      'priority': 'Medium',
      'isCompleted': true,
    };

    final task = Task.fromJson(jsonMap);
    final encoded = task.toJson();

    expect(task.id, '42');
    expect(task.isCompleted, isTrue);
    expect(encoded['title'], 'Read chapter');
    expect(Task.fromJson(encoded).title, 'Read chapter');
  });
}
