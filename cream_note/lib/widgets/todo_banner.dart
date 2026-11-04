import 'package:flutter/material.dart';

/// 日历上方的待办数量横幅
class TodoBanner extends StatelessWidget {
  const TodoBanner({
    super.key,
    required this.pendingCount,
    required this.onTap,
  });

  /// 未完成待办数量
  final int pendingCount;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPending = pendingCount > 0;

    return Material(
      color: hasPending
          ? scheme.primaryContainer
          : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(
                hasPending ? Icons.checklist_rounded : Icons.check_circle_outline,
                color: hasPending
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasPending ? '待办事项 $pendingCount 条' : '暂无待办事项',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: hasPending
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: hasPending
                    ? scheme.onPrimaryContainer
                    : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
