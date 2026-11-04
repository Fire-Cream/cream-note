/// 日期工具（周一为一周的第一天）
class DateUtil {
  DateUtil._();

  static const weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  /// 只保留年月日
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 本周的周一
  static DateTime mondayOfWeek(DateTime d) {
    final date = dateOnly(d);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  /// 某月第一天
  static DateTime firstDayOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  /// 某月天数
  static int daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;

  /// 生成月历网格（始终从周一开始，返回 6 周 × 7 天）
  static List<List<DateTime>> monthGrid(DateTime month) {
    final first = firstDayOfMonth(month);
    final gridStart = mondayOfWeek(first);
    return List.generate(6, (week) {
      return List.generate(
        7,
        (day) => gridStart.add(Duration(days: week * 7 + day)),
      );
    });
  }

  /// ISO 周数（一年中的第几周）
  ///
  /// 规则：包含当年第一个周四的那一周为第 1 周。
  static int weekNumber(DateTime date) {
    // 找到所在周的周四
    final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
    final jan1 = DateTime(thursday.year, 1, 1);
    // 当年第一个周四
    final firstThursday =
        jan1.add(Duration(days: DateTime.thursday - jan1.weekday));
    return 1 + (thursday.difference(firstThursday).inDays / 7).floor();
  }

  /// 格式化为 `2026年3月`
  static String monthLabel(DateTime d) => '${d.year}年${d.month}月';

  /// 格式化为 `3月5日`
  static String dayLabel(DateTime d) => '${d.month}月${d.day}日';

  /// 格式化为 `2026年`
  static String yearLabel(DateTime d) => '${d.year}年';

  /// 周几（周一 … 周日）
  static String weekdayLabel(DateTime d) => weekdayNames[d.weekday - 1];

  /// 周报周期：`3月2日 - 3月8日`
  static String weekRangeLabel(DateTime anyDayInWeek) {
    final monday = mondayOfWeek(anyDayInWeek);
    final sunday = monday.add(const Duration(days: 6));
    return '${dayLabel(monday)} - ${dayLabel(sunday)}';
  }

  /// 是否同一天
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// 是否同一周
  static bool isSameWeek(DateTime a, DateTime b) =>
      mondayOfWeek(a) == mondayOfWeek(b);
}
