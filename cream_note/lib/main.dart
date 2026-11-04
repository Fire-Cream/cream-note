import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'pages/home_page.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.instance.load();

  // 桌面端初始化 window_manager
  await windowManager.ensureInitialized();
  const options = WindowOptions(
    size: Size(420, 640),
    minimumSize: Size(420, 480),
    title: '时笺',
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const CreamNoteApp());
}

class CreamNoteApp extends StatelessWidget {
  const CreamNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SettingsService.instance.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: '时笺',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: const HomePage(),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3B82F6),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Microsoft YaHei',
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF0F1F5)
          : const Color(0xFF111318),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
      ),
    );
  }
}
