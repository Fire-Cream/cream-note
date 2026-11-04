import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用设置（本地持久化）
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  /// 主题模式
  final themeMode = ValueNotifier(ThemeMode.light);

  /// 删除前确认
  final confirmDelete = ValueNotifier(true);

  /// 显示周数列
  final showWeekNumbers = ValueNotifier(true);

  /// 未完成项置顶（待办列表中未完成排在最前）
  final pinUnfinished = ValueNotifier(true);

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sp async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// 启动时加载
  Future<void> load() async {
    final sp = await _sp;
    themeMode.value = switch (sp.getString('themeMode')) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    confirmDelete.value = sp.getBool('confirmDelete') ?? true;
    showWeekNumbers.value = sp.getBool('showWeekNumbers') ?? true;
    pinUnfinished.value = sp.getBool('pinUnfinished') ?? true;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final sp = await _sp;
    await sp.setString('themeMode', mode.name);
  }

  Future<void> setConfirmDelete(bool v) async {
    confirmDelete.value = v;
    final sp = await _sp;
    await sp.setBool('confirmDelete', v);
  }

  Future<void> setShowWeekNumbers(bool v) async {
    showWeekNumbers.value = v;
    final sp = await _sp;
    await sp.setBool('showWeekNumbers', v);
  }

  Future<void> setPinUnfinished(bool v) async {
    pinUnfinished.value = v;
    final sp = await _sp;
    await sp.setBool('pinUnfinished', v);
  }
}
