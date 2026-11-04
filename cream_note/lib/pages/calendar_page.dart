import 'package:flutter/material.dart';

import '../models/report.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../utils/date_util.dart';
import '../widgets/month_calendar.dart';
import 'report_edit_page.dart';

/// 首页 — 日历视图
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.onOpenTodos});

  final VoidCallback onOpenTodos;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _storage = StorageService.instance;

  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  Map<String, Report> _reports = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDate = DateUtil.dateOnly(now);
    _load();
    StorageService.dataRevision.addListener(_load);
  }

  @override
  void dispose() {
    StorageService.dataRevision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final reports = await _storage.loadReports();
    if (!mounted) return;
    setState(() => _reports = reports);
  }

  Set<DateTime> get _dailyDates => _reports.values
      .where((r) => r.type == ReportType.daily)
      .map((r) => DateUtil.dateOnly(r.periodStart))
      .toSet();

  Set<DateTime> get _weeklyMondays => _reports.values
      .where((r) => r.type == ReportType.weekly)
      .map((r) => DateUtil.dateOnly(r.periodStart))
      .toSet();

  bool get _hasMonthlyReport {
    final key = Report(
      type: ReportType.monthly,
      periodStart: DateTime(_visibleMonth.year, _visibleMonth.month),
      content: '',
    ).storageKey;
    return _reports.containsKey(key);
  }

  // ─── 交互 ───

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      final now = DateTime.now();
      if (_visibleMonth.year == now.year && _visibleMonth.month == now.month) {
        _selectedDate = DateUtil.dateOnly(now);
      } else {
        _selectedDate = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
      }
    });
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDate = day;
      if (day.month != _visibleMonth.month || day.year != _visibleMonth.year) {
        _visibleMonth = DateTime(day.year, day.month);
      }
    });
  }

  Future<void> _openReport(ReportType type, DateTime anchor) async {
    final DateTime periodStart = switch (type) {
      ReportType.daily => anchor,
      ReportType.weekly => DateUtil.mondayOfWeek(anchor),
      ReportType.monthly => DateTime(_visibleMonth.year, _visibleMonth.month),
    };

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportEditPage(type: type, periodStart: periodStart),
      ),
    );
    // dataRevision 会自动触发 _load
  }

  // ─── UI ───

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
        children: [
          // 月份切换 + 月报入口
          _MonthHeader(
            month: _visibleMonth,
            hasMonthlyReport: _hasMonthlyReport,
            onPrev: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
            onMonthlyTap: () => _openReport(
              ReportType.monthly,
              DateTime(_visibleMonth.year, _visibleMonth.month),
            ),
          ),
          const SizedBox(height: 6),

          // 月历
          ValueListenableBuilder<bool>(
            valueListenable: SettingsService.instance.showWeekNumbers,
            builder: (context, showWeekNumbers, _) => MonthCalendar(
              month: _visibleMonth,
              selectedDate: _selectedDate,
              dailyDates: _dailyDates,
              weeklyMondays: _weeklyMondays,
              showWeekNumbers: showWeekNumbers,
              onDaySelected: _onDaySelected,
              onDayDoubleTap: (day) => _openReport(ReportType.daily, day),
              onWeekDoubleTap: (monday) =>
                  _openReport(ReportType.weekly, monday),
            ),
          ),
          const SizedBox(height: 10),

          // 图例
          Center(
            child: Wrap(
              spacing: 14,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: const [
                _LegendDot(color: Color(0xFF43A047), label: '日报'),
                _LegendDot(color: Color(0xFFFFB74D), label: '周报'),
                _LegendDot(color: Color(0xFF8E6BD8), label: '月报'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 月份切换头 ───

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.hasMonthlyReport,
    required this.onPrev,
    required this.onNext,
    required this.onMonthlyTap,
  });

  final DateTime month;
  final bool hasMonthlyReport;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onMonthlyTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left_rounded),
          iconSize: 22,
          style: IconButton.styleFrom(
            backgroundColor: scheme.surfaceContainerLow,
            padding: const EdgeInsets.all(6),
          ),
        ),
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: onMonthlyTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateUtil.monthLabel(month),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: hasMonthlyReport ? '编辑本月月报' : '写本月月报',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: hasMonthlyReport
                            ? const Color(0xFF8E6BD8).withValues(alpha: 0.15)
                            : scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                        border: hasMonthlyReport
                            ? null
                            : Border.all(color: scheme.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasMonthlyReport
                                ? Icons.event_available_rounded
                                : Icons.edit_calendar_outlined,
                            size: 12,
                            color: hasMonthlyReport
                                ? const Color(0xFF8E6BD8)
                                : scheme.outline,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '月报',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: hasMonthlyReport
                                  ? const Color(0xFF8E6BD8)
                                  : scheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
          iconSize: 22,
          style: IconButton.styleFrom(
            backgroundColor: scheme.surfaceContainerLow,
            padding: const EdgeInsets.all(6),
          ),
        ),
      ],
    );
  }
}

// ─── 图例 ───

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
