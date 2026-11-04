import 'package:flutter_test/flutter_test.dart';

import 'package:cream_note/main.dart';

void main() {
  testWidgets('App renders home page with bottom nav', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CreamNoteApp());
    // 底部导航标签
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('待办'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });
}
