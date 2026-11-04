import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// 设置页（底部导航最后一项）
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = SettingsService.instance;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        // ── 显示 ──
        _GroupLabel('显示'),
        _Card(
          children: [
            ValueListenableBuilder<ThemeMode>(
              valueListenable: settings.themeMode,
              builder: (context, mode, _) => _DropdownRow(
                icon: Icons.palette_outlined,
                label: '主题',
                value: mode == ThemeMode.dark ? '深色' : '浅色',
                items: const ['浅色', '深色'],
                onChanged: (v) => settings.setThemeMode(
                  v == '深色' ? ThemeMode.dark : ThemeMode.light,
                ),
              ),
            ),
            _divider(scheme),
            ValueListenableBuilder<bool>(
              valueListenable: settings.showWeekNumbers,
              builder: (context, v, _) => _ToggleRow(
                icon: Icons.view_column_outlined,
                label: '显示周数',
                value: v,
                onChanged: settings.setShowWeekNumbers,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ── 常规 ──
        _GroupLabel('常规'),
        _Card(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: settings.confirmDelete,
              builder: (context, v, _) => _ToggleRow(
                icon: Icons.delete_outline_rounded,
                label: '删除前确认',
                value: v,
                onChanged: settings.setConfirmDelete,
              ),
            ),
            _divider(scheme),
            ValueListenableBuilder<bool>(
              valueListenable: settings.pinUnfinished,
              builder: (context, v, _) => _ToggleRow(
                icon: Icons.push_pin_outlined,
                label: '未完成项置顶',
                value: v,
                onChanged: settings.setPinUnfinished,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ── 关于 ──
        _GroupLabel('关于'),
        _Card(
          children: [
            _InfoRow(icon: Icons.info_outline_rounded, label: '应用', value: '时笺'),
            _divider(scheme),
            _InfoRow(icon: Icons.verified_outlined, label: '版本', value: '1.0.0'),
          ],
        ),
      ],
    );
  }

  Widget _divider(ColorScheme scheme) =>
      Divider(height: 1, indent: 44, color: scheme.outlineVariant);
}

// ═══════════════════════════════════
//  通用组件
// ═══════════════════════════════════

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(children: children),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  const _DropdownRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 19, color: scheme.onSurfaceVariant),
          const SizedBox(width: 11),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: value,
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              underline: const SizedBox(),
              isDense: true,
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
              dropdownColor: scheme.surfaceContainerLow,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 19, color: scheme.onSurfaceVariant),
          const SizedBox(width: 11),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Switch(value: value, onChanged: onChanged),
          SizedBox(
            width: 32,
            child: Text(
              value ? 'On' : 'Off',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 19, color: scheme.onSurfaceVariant),
          const SizedBox(width: 11),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(value, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
