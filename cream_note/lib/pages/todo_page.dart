import 'package:flutter/material.dart';

import '../models/todo.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';

/// 待办事项页
class TodoPage extends StatefulWidget {
  const TodoPage({super.key, this.onCountChanged});

  /// 待办数量变化时回调（刷新侧边栏计数）
  final VoidCallback? onCountChanged;

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final _storage = StorageService.instance;
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();

  List<Todo> _todos = [];
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
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final todos = await _storage.loadTodos();
    if (!mounted) return;
    setState(() {
      _todos = todos;
      _loading = false;
    });
    widget.onCountChanged?.call();
  }

  int get _pendingCount => _todos.where((t) => !t.done).length;

  Future<void> _add() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final todo = Todo(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: text,
    );
    await _storage.addTodo(todo);
    _inputController.clear();
    _inputFocus.requestFocus();
    await _load();
  }

  Future<void> _toggle(Todo todo) async {
    todo.done = !todo.done;
    await _storage.updateTodo(todo);
    await _load();
  }

  Future<void> _delete(Todo todo) async {
    // 删除前确认
    if (SettingsService.instance.confirmDelete.value) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('删除待办？'),
          content: Text('「${todo.title}」将被删除。'),
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
      if (confirmed != true || !mounted) return;
    }

    await _storage.deleteTodo(todo.id);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已删除'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () async {
            await _storage.addTodo(todo);
            await _load();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // 未完成项置顶：开则未完成在前、已完成在后；关则全按创建时间倒序
    final pinOn = SettingsService.instance.pinUnfinished.value;
    final pending = _todos.where((t) => !t.done).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final done = _todos.where((t) => t.done).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 置顶关闭时合并为单一列表
    final List<Todo> sortedAll;
    if (pinOn) {
      sortedAll = [...pending, ...done];
    } else {
      sortedAll = [..._todos]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    // 创建时间格式：MM-dd HH:mm
    String fmtTime(DateTime dt) {
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$m-$d $h:$min';
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('待办事项'),
        backgroundColor: scheme.surface,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 数量统计
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        '未完成 $_pendingCount 条',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '共 ${_todos.length} 条',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // 列表
                Expanded(
                  child: _todos.isEmpty
                      ? Center(
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
                                '还没有待办事项',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          children: pinOn
                              ? [
                                  for (final t in pending)
                                    _buildTile(t, fmtTime),
                                  if (done.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          4, 18, 4, 8),
                                      child: Text(
                                        '已完成 ${done.length}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: scheme.outline,
                                        ),
                                      ),
                                    ),
                                    for (final t in done)
                                      _buildTile(t, fmtTime),
                                  ],
                                ]
                              : [
                                  for (final t in sortedAll)
                                    _buildTile(t, fmtTime),
                                ],
                        ),
                ),

                // 底部输入栏
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    border: Border(
                      top: BorderSide(color: scheme.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          focusNode: _inputFocus,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _add(),
                          decoration: InputDecoration(
                            hintText: '添加待办事项…',
                            isDense: true,
                            filled: true,
                            fillColor: scheme.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: scheme.outlineVariant,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: scheme.outlineVariant,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: scheme.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _add,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 13,
                          ),
                        ),
                        child: const Text('添加'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTile(Todo todo, String Function(DateTime) fmtTime) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Dismissible(
        key: ValueKey(todo.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (_) => _delete(todo),
        child: Material(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _toggle(todo),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: todo.done,
                    onChanged: (_) => _toggle(todo),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo.title,
                          style: TextStyle(
                            fontSize: 15,
                            decoration: todo.done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: todo.done
                                ? scheme.outline
                                : scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fmtTime(todo.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _delete(todo),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: scheme.outline,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
