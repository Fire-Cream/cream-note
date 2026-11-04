import 'package:flutter/material.dart';

import '../models/report.dart';
import '../services/storage_service.dart';
import '../utils/date_util.dart';
import 'report_edit_page.dart';

/// 日报 / 周报 / 月报 列表页
class ReportListPage extends StatefulWidget {
  const ReportListPage({
    super.key,
    required this.type,
    this.onCountChanged,
  });

  final ReportType type;

  /// 报告数量变化时回调（刷新侧边栏计数）
  final VoidCallback? onCountChanged;

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage> {
  final _storage = StorageService.instance;
  List<Report> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    StorageService.dataRevision.addListener(_load);
  }

  @override
  void dispose() {
    StorageService.dataRevision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final all = await _storage.loadReports();
    if (!mounted) return;
    setState(() {
      _reports = all.values
          .where((r) => r.type == widget.type)
          .toList()
        ..sort((a, b) => b.periodStart.compareTo(a.periodStart));
      _loading = false;
    });
  }

  /// 当前周期起点
  DateTime get _currentPeriodStart {
    final now = DateTime.now();
    return switch (widget.type) {
      ReportType.daily => DateUtil.dateOnly(now),
      ReportType.weekly => DateUtil.mondayOfWeek(now),
      ReportType.monthly => DateTime(now.year, now.month),
    };
  }

  String _periodLabel(Report r) => switch (widget.type) {
        ReportType.daily =>
          '${DateUtil.dayLabel(r.periodStart)} ${DateUtil.weekdayLabel(r.periodStart)}',
        ReportType.weekly => DateUtil.weekRangeLabel(r.periodStart),
        ReportType.monthly => DateUtil.monthLabel(r.periodStart),
      };

  Color get _accent => switch (widget.type) {
        ReportType.daily => const Color(0xFF43A047),
        ReportType.weekly => const Color(0xFFF57C00),
        ReportType.monthly => const Color(0xFF8E6BD8),
      };

  String get _emptyText => switch (widget.type) {
        ReportType.daily => '还没有日报',
        ReportType.weekly => '还没有周报',
        ReportType.monthly => '还没有月报',
      };

  Future<void> _openEditor({Report? existing}) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportEditPage(
          type: widget.type,
          periodStart: existing?.periodStart ?? _currentPeriodStart,
        ),
      ),
    );
    if (mounted) {
      _load();
      widget.onCountChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? _EmptyState(
                  text: _emptyText,
                  accent: _accent,
                  onWrite: () => _openEditor(),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final r = _reports[index];
                    final preview = r.content.trim();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openEditor(existing: r),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _periodLabel(r),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: scheme.outline,
                                    ),
                                  ],
                                ),
                                if (preview.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    preview,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: scheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _reports.isEmpty
          ? null
          : FloatingActionButton(
              heroTag: 'report_fab_${widget.type.name}',
              onPressed: () => _openEditor(),
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              child: const Icon(Icons.edit_note_rounded),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.text,
    required this.accent,
    required this.onWrite,
  });

  final String text;
  final Color accent;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 56,
            color: scheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onWrite,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('写一篇'),
          ),
        ],
      ),
    );
  }
}
