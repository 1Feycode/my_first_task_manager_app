import 'package:flutter/material.dart';

import '../models/task.dart';
import '../screens/add_task_screen.dart';
import '../screens/task_details_screen.dart';
import '../services/storage_service.dart';
import '../utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static List<Task> filterTasks(String filter, List<Task> tasks) {
    switch (filter) {
      case 'Pending':
        return tasks.where((task) => !task.isCompleted).toList();
      case 'Completed':
        return tasks.where((task) => task.isCompleted).toList();
      case 'All':
      default:
        return tasks;
    }
  }

  static Map<String, int> calculateTaskStats(List<Task> tasks) {
    return {
      'total': tasks.length,
      'pending': tasks.where((task) => !task.isCompleted).length,
      'completed': tasks.where((task) => task.isCompleted).length,
    };
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  final List<Task> _tasks = [];
  bool _isLoading = false;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final savedTasks = await _storageService.loadTasks();

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _tasks
        ..clear()
        ..addAll(savedTasks);
    });
  }

  Future<void> _saveTasks() async {
    await _storageService.saveTasks(_tasks);
  }

  Future<void> _openAddTaskScreen() async {
    final Task? newTask = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );

    if (!mounted || newTask == null) {
      return;
    }

    setState(() {
      _tasks.insert(0, newTask);
    });

    await _saveTasks();
  }

  Future<void> _openTaskDetails(Task task) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)),
    );

    if (!mounted || result == null) {
      return;
    }

    final action = result['action'] as String?;
    final updatedTask = result['task'] as Task?;

    setState(() {
      if (action == 'delete') {
        _tasks.removeWhere((item) => item.id == result['taskId']);
      } else if (action == 'updated' && updatedTask != null) {
        final index = _tasks.indexWhere((item) => item.id == updatedTask.id);
        if (index != -1) {
          _tasks[index] = updatedTask;
        }
      }
    });

    await _saveTasks();
  }

  Future<void> _toggleTaskStatus(Task task) async {
    setState(() {
      final index = _tasks.indexWhere((item) => item.id == task.id);
      if (index != -1) {
        _tasks[index].isCompleted = !_tasks[index].isCompleted;
      }
    });

    await _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    final showLoadingState = _isLoading && _tasks.isEmpty;

    if (showLoadingState) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
          ),
        ),
      );
    }

    final filteredTasks = HomeScreen.filterTasks(_selectedFilter, _tasks);
    final stats = HomeScreen.calculateTaskStats(_tasks);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HomeHeader(),
              const SizedBox(height: 24),
              const _MeetingCard(),
              const SizedBox(height: 28),
              const _ProjectsSection(),
              const SizedBox(height: 28),
              const _PrioritySection(),
              const SizedBox(height: 28),
              _StatsSummary(stats: stats),
              const SizedBox(height: 18),
              _FilterSelector(
                selectedFilter: _selectedFilter,
                onFilterChanged: (value) {
                  setState(() {
                    _selectedFilter = value;
                  });
                },
              ),
              const SizedBox(height: 18),
              _TasksSection(
                tasks: filteredTasks,
                onTaskTap: _openTaskDetails,
                onToggleTask: _toggleTaskStatus,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTaskScreen,
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 3,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.paleOrange,
          child: Icon(Icons.person_rounded, color: AppColors.darkOrange),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning,',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              SizedBox(height: 3),
              Text(
                'Feyisa',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _HeaderIconButton(icon: Icons.search_rounded, label: 'Search'),
        const SizedBox(width: 8),
        _HeaderIconButton(
          icon: Icons.notifications_none_rounded,
          label: 'Notifications',
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      tooltip: label,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
      ),
      icon: Icon(icon),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  const _MeetingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.orange, AppColors.darkOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkOrange.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "TODAY'S MEETING",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Meeting with\nOrvex Team',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      '10:30 AM  ·  45 min',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.groups_2_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(title: 'Your Projects', action: 'See All'),
        const SizedBox(height: 14),
        SizedBox(
          height: 154,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _ProjectCard(
                name: 'Website Redesign',
                category: 'DESIGN',
                progress: 0.72,
                color: AppColors.blue,
                icon: Icons.web_rounded,
              ),
              SizedBox(width: 12),
              _ProjectCard(
                name: 'Mobile App',
                category: 'DEVELOPMENT',
                progress: 0.48,
                color: AppColors.teal,
                icon: Icons.phone_iphone_rounded,
              ),
              SizedBox(width: 20),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.name,
    required this.category,
    required this.progress,
    required this.color,
    required this.icon,
  });

  final String name;
  final String category;
  final double progress;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            category,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrioritySection extends StatelessWidget {
  const _PrioritySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(title: 'Priority Projects'),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(
              child: _PriorityCard(
                name: 'Brand\nRefresh',
                icon: Icons.palette_outlined,
                color: AppColors.paleOrange,
                iconColor: AppColors.darkOrange,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _PriorityCard(
                name: 'Q4\nCampaign',
                icon: Icons.campaign_outlined,
                color: Color(0xFFE1EFFB),
                iconColor: AppColors.blue,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _PriorityCard(
                name: 'Client\nPortal',
                icon: Icons.dashboard_customize_outlined,
                color: Color(0xFFDDF2EE),
                iconColor: AppColors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PriorityCard extends StatelessWidget {
  const _PriorityCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  final String name;
  final IconData icon;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSummary extends StatelessWidget {
  const _StatsSummary({required this.stats});

  final Map<String, int> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total',
            value: '${stats['total']}',
            color: AppColors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Pending',
            value: '${stats['pending']}',
            color: AppColors.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Completed',
            value: '${stats['completed']}',
            color: AppColors.teal,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSelector extends StatelessWidget {
  const _FilterSelector({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Pending', 'Completed'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((filter) {
        final isSelected = filter == selectedFilter;
        return ChoiceChip(
          label: Text(filter),
          selected: isSelected,
          onSelected: (_) => onFilterChanged(filter),
          selectedColor: AppColors.orange,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(color: isSelected ? AppColors.orange : AppColors.line),
        );
      }).toList(),
    );
  }
}

class _TasksSection extends StatelessWidget {
  const _TasksSection({
    required this.tasks,
    required this.onTaskTap,
    required this.onToggleTask,
  });

  final List<Task> tasks;
  final Future<void> Function(Task task) onTaskTap;
  final void Function(Task task) onToggleTask;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(title: "Today's Tasks", action: 'See All'),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: const Text(
              'No tasks yet. Add your first task!',
              style: TextStyle(color: AppColors.muted),
            ),
          )
        else
          ...tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TaskCard(
                task: task,
                onTaskTap: () => onTaskTap(task),
                onToggleTask: () => onToggleTask(task),
              ),
            ),
          ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onTaskTap,
    required this.onToggleTask,
  });

  final Task task;
  final VoidCallback onTaskTap;
  final VoidCallback onToggleTask;

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(task.priority);
    final statusColor = task.isCompleted ? AppColors.teal : AppColors.blue;
    final statusLabel = task.isCompleted ? 'Completed' : 'In progress';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: task.isCompleted ? const Color(0xFFF7F7F7) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.isCompleted ? AppColors.teal.withValues(alpha: 0.4) : AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTaskTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        task.dueDate,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 5,
                    children: [
                      _TaskBadge(label: task.priority, color: priorityColor),
                      _TaskBadge(label: statusLabel, color: statusColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Checkbox(
            value: task.isCompleted,
            activeColor: AppColors.orange,
            onChanged: (_) => onToggleTask(),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return AppColors.darkOrange;
      case 'Medium':
        return const Color(0xFFB77A1B);
      case 'Low':
        return AppColors.teal;
      default:
        return AppColors.muted;
    }
  }
}

class _TaskBadge extends StatelessWidget {
  const _TaskBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              color: AppColors.darkOrange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
