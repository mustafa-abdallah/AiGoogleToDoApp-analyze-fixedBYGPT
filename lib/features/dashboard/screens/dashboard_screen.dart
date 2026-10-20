import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/habit_schedule.dart';
import '../../../database/database.dart';
import '../../../repositories/notes_repository.dart';
import '../../../repositories/providers.dart';
import '../../habits/providers/habits_providers.dart';
import '../../notes/screens/note_editor_screen.dart';
import '../../settings/providers/settings_providers.dart';
import '../../settings/screens/settings_screen.dart';
import '../../tasks/providers/tasks_providers.dart';

final _recentNotesProvider = StreamProvider.autoDispose<List<Note>>(
    (ref) => ref.watch(notesRepositoryProvider).watch(const NotesFilter()));

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final todayKey = formatDate(now);
    final endOfToday = DateTime(now.year, now.month, now.day + 1);

    // Tasks state
    final tasks = ref.watch(activeTasksProvider).valueOrNull ?? const <Task>[];
    final todayTasks = tasks
        .where((t) => t.dueAt != null && t.dueAt!.isBefore(endOfToday))
        .toList();
    final dueNow = todayTasks.length;

    // Habits state
    final habits = ref.watch(habitsProvider).valueOrNull ?? const <Habit>[];
    final logs = ref.watch(habitLogsProvider).valueOrNull ?? const <HabitLog>[];
    final schedules =
        ref.watch(habitSchedulesProvider).valueOrNull ?? const <String, List<HabitSchedule>>{};
    final todayDate = DateTime(now.year, now.month, now.day);
    final excusedToday = {
      for (final l in logs)
        if (l.date == todayKey && l.status == 'excused') l.habitId
    };
    final doneIds = {
      for (final l in logs)
        if (l.date == todayKey && l.status == 'done') l.habitId
    };
    final dueHabits = habits
        .where((h) =>
            h.pausedAt == null &&
            !excusedToday.contains(h.id) &&
            scheduledOnDate(spansOf(schedules[h.id]), todayDate))
        .toList();
    final doneTodayCount = dueHabits.where((h) => doneIds.contains(h.id)).length;

    // Notes state
    final notes = ref.watch(_recentNotesProvider).valueOrNull ?? const <Note>[];

    // Backup state
    final backup = ref.watch(lastBackupProvider);
    final showBackupHint = backup.hasValue &&
        (backup.value == null || now.difference(backup.value!).inDays >= 7);

    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // App Bar علوي أنيق بهوية التطبيق
          SliverAppBar(
            floating: true,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kAmber.withAlpha(dark ? 30 : 40),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kAmber.withAlpha(60)),
                  ),
                  child: const Text(
                    'معرفتي',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: kAmber,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kEmerald.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 6, color: kEmerald),
                      SizedBox(width: 4),
                      Text(
                        'Local-First',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: kEmerald,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'الإعدادات والنسخ الاحتياطي',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. بطاقة الترحيب الفخمة (Welcome Hero Banner)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: dark
                          ? [
                              const Color(0xFF1E2230),
                              const Color(0xFF141722),
                              kAmber.withAlpha(25),
                            ]
                          : [
                              Colors.white,
                              const Color(0xFFFFFBEB),
                              kAmber.withAlpha(30),
                            ],
                    ),
                    border: Border.all(
                      color: dark ? kAmber.withAlpha(50) : kAmber.withAlpha(80),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(dark ? 60 : 15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 14, color: kAmber),
                          const SizedBox(width: 6),
                          Text(
                            formatDate(now),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kAmber,
                            ),
                          ),
                          const Text(' · ', style: TextStyle(color: kAmber)),
                          const Text(
                            'المساحة الموحدة',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أهلاً بك يا حاج مصطفى',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: dark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'مساحتك الموحدة لإدارة المعرفة والإنتاجية والاستمرارية. تابع مهامك، ثبت عاداتك، ودوّن ملاحظاتك بحرية وخصوصية تامة.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: dark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kAmber,
                              foregroundColor: const Color(0xFF1A1608),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('ملاحظة جديدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () async {
                              final repo = ref.read(notesRepositoryProvider);
                              final id = await repo.create();
                              if (context.mounted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: id)),
                                );
                              }
                            },
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: dark ? Colors.white : const Color(0xFF0F172A),
                              side: BorderSide(color: dark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 18, color: kEmerald),
                            label: const Text('مهام اليوم', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              ref.read(currentTabProvider.notifier).state = 2;
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (showBackupHint) ...[
                  _BackupHint(last: backup.value),
                  const SizedBox(height: 16),
                ],

                // 2. بطاقات الإحصائيات (Stat Cards Strip) - تدعم اللمس للتنقل السريع
                Row(
                  children: [
                    Expanded(
                      child: _ModernStatCard(
                        icon: Icons.task_alt_rounded,
                        color: kSky,
                        value: '$dueNow',
                        title: 'مهام اليوم',
                        subtitle: 'من ${tasks.length} نشطة',
                        onTap: () => ref.read(currentTabProvider.notifier).state = 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ModernStatCard(
                        icon: Icons.local_fire_department_rounded,
                        color: kOrange,
                        value: '$doneTodayCount/${dueHabits.length}',
                        title: 'عادات اليوم',
                        subtitle: habits.isEmpty ? 'أضف عادة' : (dueHabits.isEmpty ? 'مكتملة' : 'قيد الإنجاز'),
                        onTap: () => ref.read(currentTabProvider.notifier).state = 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ModernStatCard(
                        icon: Icons.article_rounded,
                        color: kAmber,
                        value: '${notes.length}',
                        title: 'الملاحظات',
                        subtitle: 'مخزنة محلياً',
                        onTap: () => ref.read(currentTabProvider.notifier).state = 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ModernStatCard(
                        icon: Icons.offline_bolt_rounded,
                        color: kEmerald,
                        value: '100%',
                        title: 'العمل بدون إنترنت',
                        subtitle: 'قاعدة بيانات Drift',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 3. قسم مهام اليوم (Today's Tasks)
                _SectionHeader(
                  title: 'مهام اليوم والمتأخرة',
                  icon: Icons.check_circle_outline,
                  color: kSky,
                  count: todayTasks.length,
                ),
                const SizedBox(height: 10),
                if (todayTasks.isEmpty)
                  _EmptyCard(
                    message: 'رائع! لا توجد مهام مستحقة لليوم.',
                    icon: Icons.done_all_rounded,
                    color: kEmerald,
                  )
                else
                  ...todayTasks.take(4).map((t) => _TaskMiniCard(task: t)),

                const SizedBox(height: 24),

                // 4. قسم عادات اليوم (Today's Habits)
                _SectionHeader(
                  title: 'عادات اليوم وسلاسل الاستمرارية',
                  icon: Icons.local_fire_department_outlined,
                  color: kOrange,
                  count: dueHabits.length,
                ),
                const SizedBox(height: 10),
                if (dueHabits.isEmpty)
                  _EmptyCard(
                    message: habits.isEmpty ? 'لم تقم بإضافة أي عادات بعد.' : 'أنجزت جميع عادات اليوم!',
                    icon: Icons.celebration_outlined,
                    color: kOrange,
                  )
                else
                  ...dueHabits.take(3).map((h) => _HabitMiniCard(
                        habit: h,
                        isDone: doneIds.contains(h.id),
                      )),

                const SizedBox(height: 24),

                // 5. قسم آخر الملاحظات (Recent Notes)
                _SectionHeader(
                  title: 'آخر الملاحظات المسجلة',
                  icon: Icons.article_outlined,
                  color: kAmber,
                  count: notes.length,
                ),
                const SizedBox(height: 10),
                if (notes.isEmpty)
                  _EmptyCard(
                    message: 'لا توجد ملاحظات مسجلة بعد. اضغط + لكتابة أول ملاحظة.',
                    icon: Icons.edit_note,
                    color: kAmber,
                  )
                else
                  ...notes.take(3).map((n) => _NoteMiniCard(note: n)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
  });

  final String title;
  final IconData icon;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  const _ModernStatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF181B26) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? const Color(0xFF282D3F) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withAlpha(dark ? 40 : 30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskMiniCard extends ConsumerWidget {
  const _TaskMiniCard({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final repo = ref.read(tasksRepositoryProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF181B26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? const Color(0xFF282D3F) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () async {
              await repo.toggle(task);
            },
            borderRadius: BorderRadius.circular(8),
            child: Icon(
              task.completedAt != null
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: task.completedAt != null ? kEmerald : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                decoration: task.completedAt != null ? TextDecoration.lineThrough : null,
                color: task.completedAt != null ? Colors.grey : null,
              ),
            ),
          ),
          if (task.priority > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: task.priority == 2 ? kRose.withAlpha(30) : kAmber.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                task.priority == 2 ? 'عاجل' : 'متوسط',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: task.priority == 2 ? kRose : kAmber,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HabitMiniCard extends ConsumerWidget {
  const _HabitMiniCard({required this.habit, required this.isDone});
  final Habit habit;
  final bool isDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final repo = ref.read(habitsRepositoryProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF181B26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? const Color(0xFF282D3F) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDone ? kEmerald.withAlpha(30) : kOrange.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDone ? Icons.check_rounded : Icons.local_fire_department_rounded,
              color: isDone ? kEmerald : kOrange,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              habit.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: Icon(
              isDone ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: isDone ? kEmerald : Colors.grey,
            ),
            onPressed: () async {
              final today = formatDate(DateTime.now());
              await repo.toggleDay(habit.id, today);
            },
          ),
        ],
      ),
    );
  }
}

class _NoteMiniCard extends StatelessWidget {
  const _NoteMiniCard({required this.note});
  final Note note;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF181B26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? const Color(0xFF282D3F) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          note.title.isEmpty ? 'بدون عنوان' : note.title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          formatDateTime(note.updatedAt),
          style: TextStyle(
            fontSize: 11,
            color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        trailing: const Icon(Icons.chevron_left, size: 20, color: Colors.grey),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: note.id)),
          );
        },
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message, required this.icon, required this.color});
  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF141722) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? const Color(0xFF282D3F) : const Color(0xFFE2E8F0),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupHint extends StatelessWidget {
  const _BackupHint({required this.last});
  final DateTime? last;

  @override
  Widget build(BuildContext context) {
    final days = last == null ? null : DateTime.now().difference(last!).inDays;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kRose.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kRose.withAlpha(50)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: kRose, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  days == null
                      ? 'لم تقم بعمل نسخة احتياطية بعد'
                      : 'آخر نسخة احتياطية كانت قبل $days يوماً',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kRose),
                ),
                const SizedBox(height: 2),
                const Text(
                  'بياناتك مخزنة محلياً على هذا الهاتف فقط — قم بحفظ نسخة آمنة.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 14, color: kRose),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
