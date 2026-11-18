import 'dart:async';

import 'package:flutter/material.dart';

import 'app_state.dart';
import 'pages/today_page.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = AppState();
  await app.load();
  runApp(PocketBookApp(app: app));
}

class PocketBookApp extends StatefulWidget {
  final AppState app;
  const PocketBookApp({super.key, required this.app});

  @override
  State<PocketBookApp> createState() => _PocketBookAppState();
}

class _PocketBookAppState extends State<PocketBookApp> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && widget.app.themeMode == 'auto') setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  ThemeMode _mode() {
    switch (widget.app.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        final h = DateTime.now().hour;
        final isDay =
            h >= widget.app.dayStartHour && h < widget.app.nightStartHour;
        return isDay ? ThemeMode.light : ThemeMode.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.app,
      builder: (context, _) {
        return MaterialApp(
          title: '记账',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(AppColors.light),
          darkTheme: buildAppTheme(AppColors.dark),
          themeMode: _mode(),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(widget.app.fontScale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: TodayPage(app: widget.app),
        );
      },
    );
  }
}