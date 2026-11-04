import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/report.dart';
import '../models/todo.dart';

/// 本地持久化服务（基于 shared_preferences 存 JSON）
///
/// 每次数据变更递增 [dataRevision]，页面监听它即可实时刷新。
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  /// 数据版本号，任何写操作都会递增
  static final dataRevision = ValueNotifier<int>(0);

  static void _notify() => dataRevision.value++;

  static const _reportsKey = 'cream_note_reports';
  static const _todosKey = 'cream_note_todos';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sp async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ─── 报告 ───

  Future<Map<String, Report>> loadReports() async {
    final sp = await _sp;
    return Report.decodeMap(sp.getString(_reportsKey) ?? '');
  }

  Future<void> saveReport(Report report) async {
    final sp = await _sp;
    final map = await loadReports();
    map[report.storageKey] = report;
    await sp.setString(_reportsKey, Report.encodeMap(map));
    _notify();
  }

  Future<void> deleteReport(String storageKey) async {
    final sp = await _sp;
    final map = await loadReports();
    map.remove(storageKey);
    await sp.setString(_reportsKey, Report.encodeMap(map));
    _notify();
  }

  // ─── 待办 ───

  Future<List<Todo>> loadTodos() async {
    final sp = await _sp;
    return Todo.decodeList(sp.getString(_todosKey) ?? '');
  }

  Future<void> saveTodos(List<Todo> todos) async {
    final sp = await _sp;
    await sp.setString(_todosKey, Todo.encodeList(todos));
    _notify();
  }

  Future<void> addTodo(Todo todo) async {
    final todos = await loadTodos();
    todos.add(todo);
    await saveTodos(todos);
  }

  Future<void> updateTodo(Todo todo) async {
    final todos = await loadTodos();
    final i = todos.indexWhere((t) => t.id == todo.id);
    if (i >= 0) {
      todos[i] = todo;
      await saveTodos(todos);
    }
  }

  Future<void> deleteTodo(String id) async {
    final todos = await loadTodos();
    todos.removeWhere((t) => t.id == id);
    await saveTodos(todos);
  }
}
