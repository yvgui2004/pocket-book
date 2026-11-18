import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 底部系统栏需要的安全间距。
///
/// Android 全面屏手势下，部分机型不把底部手势条算进 MediaQuery.padding，
/// 导致 SafeArea 让不出位置，底部控件被系统手势条压住。这里取
/// padding / viewPadding / systemGestureInsets 三者的最大值兜底。
/// 调用方需要把 SafeArea 的 bottom 关掉，自己用这个值做底部内边距。
double bottomSafeInset(BuildContext context) {
  final mq = MediaQuery.of(context);
  if (mq.viewInsets.bottom > 0) return mq.padding.bottom; // 键盘弹起时由 Scaffold 处理
  return math.max(
    mq.padding.bottom,
    math.max(mq.viewPadding.bottom, mq.systemGestureInsets.bottom),
  );
}

class AppColors {
  final Color bg;
  final Color surface;
  final Color text;
  final Color sub;
  final Color line;
  final Color accent;
  final Color accentStrong;
  final Color accentSoft;
  final Color warn;
  final Color warnSoft;
  final bool isDark;

  const AppColors({
    required this.bg,
    required this.surface,
    required this.text,
    required this.sub,
    required this.line,
    required this.accent,
    required this.accentStrong,
    required this.accentSoft,
    required this.warn,
    required this.warnSoft,
    required this.isDark,
  });

  static const light = AppColors(
    bg: Color(0xFFF5F6F8),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF17191C),
    sub: Color(0xFF8B9199),
    line: Color(0xFFE8EAED),
    accent: Color(0xFF4F6BFF),
    accentStrong: Color(0xFF3D57E8),
    accentSoft: Color(0xFFEDF0FF),
    warn: Color(0xFFE5484D),
    warnSoft: Color(0xFFFDECEC),
    isDark: false,
  );

  static const dark = AppColors(
    bg: Color(0xFF0F1115),
    surface: Color(0xFF181B20),
    text: Color(0xFFE6E8EB),
    sub: Color(0xFF8B9199),
    line: Color(0xFF262A31),
    accent: Color(0xFF6B85FF),
    accentStrong: Color(0xFF85A0FF),
    accentSoft: Color(0xFF1B2340),
    warn: Color(0xFFFF6369),
    warnSoft: Color(0xFF3A1F22),
    isDark: true,
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

ThemeData buildAppTheme(AppColors c) {
  final brightness = c.isDark ? Brightness.dark : Brightness.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
      surface: c.surface,
    ).copyWith(
      primary: c.accent,
      error: c.warn,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.isDark ? const Color(0xFF2A2D33) : const Color(0xFF202329),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );
}

/// 数字用等宽字形，列表里上下对齐不跳动。
const tabularFigures = <FontFeature>[FontFeature.tabularFigures()];

String money(double v) =>
    '${v < 0 ? '-' : ''}¥${v.abs().toStringAsFixed(2)}';

String weekdayName(DateTime d) =>
    const ['一', '二', '三', '四', '五', '六', '日'][d.weekday - 1];