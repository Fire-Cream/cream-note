import 'dart:convert';

/// 报告类型
enum ReportType {
  /// 日报 - 按天
  daily,

  /// 周报 - 按周（以周一为一周开始）
  weekly,

  /// 月报 - 按月
  monthly;

  String get label => switch (this) {
        ReportType.daily => '日报',
        ReportType.weekly => '周报',
        ReportType.monthly => '月报',
      };
}

/// 一篇报告
class Report {
  Report({
    required this.type,
    required this.periodStart,
    required this.content,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// 报告类型
  final ReportType type;

  /// 周期起点（日报=当天0点，周报=当周周一，月报=当月1日）
  final DateTime periodStart;

  /// 报告正文
  String content;

  /// 最后修改时间
  DateTime updatedAt;

  /// 存储键，如 `d:2026-03-05` / `w:2026-03-02` / `m:2026-03`
  String get storageKey {
    final y = periodStart.year.toString().padLeft(4, '0');
    final m = periodStart.month.toString().padLeft(2, '0');
    final d = periodStart.day.toString().padLeft(2, '0');
    return switch (type) {
      ReportType.daily => 'd:$y-$m-$d',
      ReportType.weekly => 'w:$y-$m-$d',
      ReportType.monthly => 'm:$y-$m',
    };
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'periodStart': periodStart.millisecondsSinceEpoch,
        'content': content,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        type: ReportType.values.firstWhere(
          (t) => t.name == json['type'] as String?,
          orElse: () => ReportType.daily,
        ),
        periodStart: DateTime.fromMillisecondsSinceEpoch(
          (json['periodStart'] as num?)?.toInt() ?? 0,
        ),
        content: json['content'] as String? ?? '',
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['updatedAt'] as num?)?.toInt() ?? 0,
        ),
      );

  static String encodeMap(Map<String, Report> map) => jsonEncode(
        map.map((k, v) => MapEntry(k, v.toJson())),
      );

  static Map<String, Report> decodeMap(String source) {
    if (source.isEmpty) return {};
    final raw = jsonDecode(source) as Map<String, dynamic>;
    return raw.map(
      (k, v) => MapEntry(k, Report.fromJson(v as Map<String, dynamic>)),
    );
  }
}
