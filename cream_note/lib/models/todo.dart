import 'dart:convert';

/// 一条待办事项
class Todo {
  Todo({
    required this.id,
    required this.title,
    this.done = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 唯一标识
  final String id;

  /// 待办内容
  String title;

  /// 是否已完成
  bool done;

  /// 创建时间
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'done': done,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        done: json['done'] as bool? ?? false,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['createdAt'] as num?)?.toInt() ?? 0,
        ),
      );

  static String encodeList(List<Todo> list) =>
      jsonEncode(list.map((t) => t.toJson()).toList());

  static List<Todo> decodeList(String source) {
    if (source.isEmpty) return [];
    final raw = jsonDecode(source) as List<dynamic>;
    return raw
        .map((e) => Todo.fromJson(e as Map<String, dynamic>))
        .toList(growable: true);
  }
}
