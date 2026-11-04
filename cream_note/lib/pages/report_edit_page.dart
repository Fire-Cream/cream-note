import 'package:flutter/material.dart';

import '../models/report.dart';
import '../services/storage_service.dart';
import '../utils/date_util.dart';

/// 报告编辑页：写/编辑/删除 日报、周报、月报
class ReportEditPage extends StatefulWidget {
  const ReportEditPage({
    super.key,
    required this.type,
    required this.periodStart,
  });

  final ReportType type;

  /// 周期起点（日报=当天，周报=周一，月报=当月1日）
  final DateTime periodStart;

  @override
  State<ReportEditPage> createState() => _ReportEditPageState();
}

class _ReportEditPageState extends State<ReportEditPage> {
  final _storage = StorageService.instance;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  Report? _existing;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final reports = await _storage.loadReports();
    final report = reports[_tempReport.storageKey];
    if (!mounted) return;
    setState(() {
      _existing = report;
      _controller.text = report?.content ?? '';
      _loading = false;
    });
  }

  /// 用于计算 storageKey 的临时对象
  Report get _tempReport => Report(
        type: widget.type,
        periodStart: widget.periodStart,
        content: '',
      );

  String get _title => '写${widget.type.label}';

  String get _periodLabel => switch (widget.type) {
        ReportType.daily =>
          '${DateUtil.yearLabel(widget.periodStart)}${DateUtil.dayLabel(widget.periodStart)} ${DateUtil.weekdayLabel(widget.periodStart)}',
        ReportType.weekly =>
          '${DateUtil.yearLabel(widget.periodStart)}${DateUtil.weekRangeLabel(widget.periodStart)}',
        ReportType.monthly => DateUtil.monthLabel(widget.periodStart),
      };

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('内容不能为空')),
      );
      return;
    }

    setState(() => _saving = true);

    final report = Report(
      type: widget.type,
      periodStart: widget.periodStart,
      content: text,
    );
    await _storage.saveReport(report);

    if (!mounted) return;
    setState(() {
      _existing = report;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.type.label}已保存')),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除${widget.type.label}？'),
        content: const Text('删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _storage.deleteReport(_tempReport.storageKey);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Color get _accent => switch (widget.type) {
        ReportType.daily => const Color(0xFF43A047),
        ReportType.weekly => const Color(0xFFF57C00),
        ReportType.monthly => const Color(0xFF8E6BD8),
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: scheme.surface,
        actions: [
          if (_existing != null)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除',
            ),
          IconButton(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            tooltip: '保存',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 周期提示条
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_note_rounded, size: 18, color: _accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _periodLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 编辑区
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: '写下你的${widget.type.label}…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: scheme.outlineVariant,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: scheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: scheme.primary,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: scheme.surfaceContainerLow,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: const TextStyle(fontSize: 15, height: 1.6),
                    ),
                  ),
                ),
                // 底部保存按钮
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _saving ? '保存中…' : '保存',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
