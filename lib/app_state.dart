import 'package:flutter/foundation.dart';

import 'db.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  List<Entry> entries = [];
  double budget = 1200;
  String themeMode = 'auto'; // auto | system | light | dark
  int dayStartHour = 7;
  int nightStartHour = 19;
  double fontScale = 1.0;
  bool loaded = false;

  Future<void> load() async {
    entries = await DB.loadEntries();
    final s = await DB.loadSettings();
    budget = double.tryParse(s['budget'] ?? '') ?? 1200;
    themeMode = s['themeMode'] ?? 'auto';
    dayStartHour = int.tryParse(s['dayStartHour'] ?? '') ?? 7;
    nightStartHour = int.tryParse(s['nightStartHour'] ?? '') ?? 19;
    fontScale = double.tryParse(s['fontScale'] ?? '') ?? 1.0;
    loaded = true;
    notifyListeners();
  }

  DateTime get today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Entry> entriesForDay(DateTime d) =>
      entries.where((e) => sameDay(e.date, d)).toList();

  double totalForDay(DateTime d) =>
      entriesForDay(d).fold(0.0, (s, e) => s + e.amount);

  double totalForMonth(int year, int month) => entries
      .where((e) => e.date.year == year && e.date.month == month)
      .fold(0.0, (s, e) => s + e.amount);

  List<Entry> get todayEntries => entriesForDay(today);
  double get todayTotal => totalForDay(today);
  double get monthTotal => totalForMonth(today.year, today.month);
  double get remain => budget - monthTotal;

  int get daysInMonth => DateTime(today.year, today.month + 1, 0).day;
  int get daysLeft => daysInMonth - today.day + 1;
  double get daily => remain / daysLeft;
  double get todayLeft => daily - todayTotal;

  /// 日预算：月预算均摊到本月天数
  double get dayBudget => budget / daysInMonth;

  /// 本月日均消费 = 本月已花 ÷ 已过天数
  double get monthAvg => monthTotal / today.day;

  // 本周：从每月 1 号起每 7 天一段，月底不足 7 天也算一段
  int get weekBlockStart => ((today.day - 1) ~/ 7) * 7 + 1;
  int get weekBlockEnd {
    final end = weekBlockStart + 6;
    return end > daysInMonth ? daysInMonth : end;
  }

  int get weekDaysCount => weekBlockEnd - weekBlockStart + 1;
  int get weekElapsed => today.day - weekBlockStart + 1;
  int get weekDaysLeft => weekBlockEnd - today.day + 1;
  double get weekBudget => dayBudget * weekDaysCount;

  double get weekTotal => entries
      .where((e) =>
          e.date.year == today.year &&
          e.date.month == today.month &&
          e.date.day >= weekBlockStart &&
          e.date.day <= weekBlockEnd)
      .fold(0.0, (s, e) => s + e.amount);

  double get weekRemain => weekBudget - weekTotal;
  double get weekDaily => weekRemain / weekDaysLeft;
  double get weekAvg => weekTotal / weekElapsed;

  Future<void> addEntries(List<ParseItem> items) => addEntriesTo(today, items);

  Future<void> addEntriesTo(DateTime date, List<ParseItem> items) async {
    for (final it in items.where((i) => i.ok)) {
      final e = await DB.insertEntry(
        Entry(name: it.name, amount: it.amount, date: date),
      );
      entries.add(e);
    }
    notifyListeners();
  }

  Future<void> deleteEntry(int id) async {
    entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await DB.deleteEntry(id);
  }

  Future<void> setBudget(double v) async {
    budget = v;
    await DB.saveSetting('budget', v.toString());
    notifyListeners();
  }

  Future<void> setThemeMode(String v) async {
    themeMode = v;
    await DB.saveSetting('themeMode', v);
    notifyListeners();
  }

  Future<void> setDayNight(int dayHour, int nightHour) async {
    dayStartHour = dayHour;
    nightStartHour = nightHour;
    await DB.saveSetting('dayStartHour', dayHour.toString());
    await DB.saveSetting('nightStartHour', nightHour.toString());
    notifyListeners();
  }

  Future<void> setFontScale(double v) async {
    fontScale = v;
    await DB.saveSetting('fontScale', v.toString());
    notifyListeners();
  }
}