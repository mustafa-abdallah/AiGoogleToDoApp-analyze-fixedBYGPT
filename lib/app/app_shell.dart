import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/habits/screens/habits_screen.dart';
import '../features/library/screens/library_screen.dart';
import '../features/notes/screens/notes_list_screen.dart';
import '../features/tasks/screens/tasks_screen.dart';

/// موفر التبويب النشط المشترك في كافة شاشات التطبيق
final currentTabProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _pages = <Widget>[
    DashboardScreen(),
    NotesListScreen(),
    TasksScreen(),
    HabitsScreen(),
    LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(currentTabProvider);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: index,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: dark ? const Color(0xFF282D3F) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) =>
              ref.read(currentTabProvider.notifier).state = i,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.article_outlined),
              selectedIcon: Icon(Icons.article_rounded),
              label: 'الملاحظات',
            ),
            NavigationDestination(
              icon: Icon(Icons.task_alt_outlined),
              selectedIcon: Icon(Icons.task_alt_rounded),
              label: 'المهام',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_fire_department_outlined),
              selectedIcon: Icon(Icons.local_fire_department_rounded),
              label: 'العادات',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'المكتبة',
            ),
          ],
        ),
      ),
    );
  }
}
