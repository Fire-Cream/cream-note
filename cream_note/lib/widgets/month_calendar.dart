import 'package:flutter/material.dart';

import '../utils/date_util.dart';

/// 月历：左侧周数列、日报点、周报周条、今天/选中高亮
///
/// - 单击日期 = 选中
/// - 双击日期 = 写当天日报
/// - 双击周数 = 写该周周报
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.dailyDates,
    required this.weeklyMondays,
    required this.onDaySelected,
    required this.onDayDoubleTap,
    required this.onWeekDoubleTap,
    this.showWeekNumbers = true,
  });

  /// 当前展示的月份（取年月即可）
  final DateTime month;

  /// 当前选中的日期
  final DateTime selectedDate;

  /// 有日报的日期集合（dateOnly）
  final Set<DateTime> dailyDates;

  /// 有周报的周一集合
  final Set<DateTime> weeklyMondays;

  /// 单击日期
  final ValueChanged<DateTime> onDaySelected;

  /// 双击日期（写日报）
  final ValueChanged<DateTime> onDayDoubleTap;

  /// 双击周数（写周报），传入该周的周一
  final ValueChanged<DateTime> onWeekDoubleTap;

  /// 是否显示周数列
  final bool showWeekNumbers;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final grid = DateUtil.monthGrid(month);
    final today = DateUtil.dateOnly(DateTime.now());

    return Column(
      children: [
        // 表头：周 + 星期
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              // 周列表头
              if (showWeekNumbers)
                SizedBox(
                  width: 36,
                  child: Center(
                    child: Text(
                      '周',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              for (int i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      DateUtil.weekdayNames[i],
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // 日期网格
        for (final week in grid)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _WeekRow(
              week: week,
              month: month,
              today: today,
              selectedDate: selectedDate,
              dailyDates: dailyDates,
              hasWeekly: weeklyMondays.contains(DateUtil.dateOnly(week.first)),
              showWeekNumbers: showWeekNumbers,
              onDaySelected: onDaySelected,
              onDayDoubleTap: onDayDoubleTap,
              onWeekDoubleTap: onWeekDoubleTap,
            ),
          ),
      ],
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.week,
    required this.month,
    required this.today,
    required this.selectedDate,
    required this.dailyDates,
    required this.hasWeekly,
    required this.showWeekNumbers,
    required this.onDaySelected,
    required this.onDayDoubleTap,
    required this.onWeekDoubleTap,
  });

  final List<DateTime> week;
  final DateTime month;
  final DateTime today;
  final DateTime selectedDate;
  final Set<DateTime> dailyDates;
  final bool hasWeekly;
  final bool showWeekNumbers;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onDayDoubleTap;
  final ValueChanged<DateTime> onWeekDoubleTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final monday = DateUtil.dateOnly(week.first);
    final weekNum = DateUtil.weekNumber(week.first);

    return Container(
      decoration: hasWeekly
          ? BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // 周数列
          if (showWeekNumbers)
            GestureDetector(
              onDoubleTap: () => onWeekDoubleTap(monday),
              child: Tooltip(
                message: '第$weekNum周 · 双击写周报',
                child: Container(
                  width: 36,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hasWeekly
                        ? const Color(0xFFFFE0B2)
                        : scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$weekNum',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasWeekly
                          ? const Color(0xFFE65100)
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          // 日期列
          for (final day in week)
            Expanded(
              child: _DayCell(
                day: day,
                inMonth: day.month == month.month && day.year == month.year,
                isToday: DateUtil.isSameDay(day, today),
                isSelected: DateUtil.isSameDay(day, selectedDate),
                hasDaily: dailyDates.contains(DateUtil.dateOnly(day)),
                onTap: () => onDaySelected(DateUtil.dateOnly(day)),
                onDoubleTap: () => onDayDoubleTap(DateUtil.dateOnly(day)),
                scheme: scheme,
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.hasDaily,
    required this.onTap,
    required this.onDoubleTap,
    required this.scheme,
  });

  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final bool hasDaily;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final Color numberColor;
    if (isSelected) {
      numberColor = scheme.onPrimary;
    } else if (!inMonth) {
      numberColor = scheme.onSurfaceVariant.withValues(alpha: 0.35);
    } else if (isToday) {
      numberColor = scheme.primary;
    } else {
      numberColor = scheme.onSurface;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Tooltip(
        message: '${DateUtil.dayLabel(day)} · 双击写日报',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? scheme.primary
                      : isToday
                          ? scheme.primary.withValues(alpha: 0.12)
                          : null,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected
                      ? Border.all(
                          color: scheme.primary.withValues(alpha: 0.45),
                          width: 1.2,
                        )
                      : null,
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                    color: numberColor,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // 日报标识
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: hasDaily
                      ? (inMonth
                          ? const Color(0xFF43A047)
                          : const Color(0xFF43A047).withValues(alpha: 0.35))
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
