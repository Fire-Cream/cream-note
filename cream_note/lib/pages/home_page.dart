import 'package:flutter/material.dart';

import '../models/report.dart';
import '../services/storage_service.dart';
import 'calendar_page.dart';
import 'report_list_page.dart';
import 'settings_page.dart';
import 'todo_page.dart';

/// 应用外壳：底部导航栏布局（手机 App 风格）
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  int _dailyCount = 0;
  int _weeklyCount = 0;
  int _monthlyCount = 0;
  int _todoCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final reports = await StorageService.instance.loadReports();
    final todos = await StorageService.instance.loadTodos();
    if (!mounted) return;
    setState(() {
      _dailyCount =
          reports.values.where((r) => r.type == ReportType.daily).length;
      _weeklyCount =
          reports.values.where((r) => r.type == ReportType.weekly).length;
      _monthlyCount =
          reports.values.where((r) => r.type == ReportType.monthly).length;
      _todoCount = todos.where((t) => !t.done).length;
    });
  }

  void _goToTodos() => setState(() => _index = 4);

  void _onNavigate(int i) {
    setState(() => _index = i);
    if (i != 5) _loadCounts(); // 设置页不刷新计数
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F1F5),
      body: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: IndexedStack(
          index: _index,
          children: [
            CalendarPage(onOpenTodos: _goToTodos),
            ReportListPage(type: ReportType.daily, onCountChanged: _loadCounts),
            ReportListPage(type: ReportType.weekly, onCountChanged: _loadCounts),
            ReportListPage(
                type: ReportType.monthly, onCountChanged: _loadCounts),
            TodoPage(onCountChanged: _loadCounts),
            const SettingsPage(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onNavigate,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.12),
        height: 62,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: '首页',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _dailyCount > 0,
              label: Text('$_dailyCount'),
              child: const Icon(Icons.edit_note_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _dailyCount > 0,
              label: Text('$_dailyCount'),
              child: const Icon(Icons.edit_note_rounded),
            ),
            label: '日报',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _weeklyCount > 0,
              label: Text('$_weeklyCount'),
              child: const Icon(Icons.view_week_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _weeklyCount > 0,
              label: Text('$_weeklyCount'),
              child: const Icon(Icons.view_week_rounded),
            ),
            label: '周报',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _monthlyCount > 0,
              label: Text('$_monthlyCount'),
              child: const Icon(Icons.calendar_view_month_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _monthlyCount > 0,
              label: Text('$_monthlyCount'),
              child: const Icon(Icons.calendar_view_month_rounded),
            ),
            label: '月报',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _todoCount > 0,
              label: Text('$_todoCount'),
              child: const Icon(Icons.checklist_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _todoCount > 0,
              label: Text('$_todoCount'),
              child: const Icon(Icons.checklist_rounded),
            ),
            label: '待办',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
