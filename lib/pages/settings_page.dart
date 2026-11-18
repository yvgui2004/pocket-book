import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';

class SettingsPage extends StatelessWidget {
  final AppState app;
  const SettingsPage({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            return ListView(
              padding: EdgeInsets.fromLTRB(
                  16, 4, 16, 24 + bottomSafeInset(context)),
              children: [
                _header(context, c),
                const SizedBox(height: 10),
                _group(c, [
                  _row(c, '每月预算',
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('¥${_trim(app.budget)}',
                        style: TextStyle(
                            fontSize: 13,
                            color: c.sub,
                            fontFeatures: tabularFigures)),
                    Icon(Icons.chevron_right_rounded, size: 16, color: c.sub),
                  ]),
                      onTap: () => _editBudget(context)),
                  _row(c, '字体大小',
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_fontName(app.fontScale),
                        style: TextStyle(fontSize: 13, color: c.sub)),
                    Icon(Icons.chevron_right_rounded, size: 16, color: c.sub),
                  ]),
                      onTap: () => _cycleFont(app)),
                ]),
                const SizedBox(height: 12),
                _group(c, [
                  _themeRow(c, '跟随系统', 'system'),
                  _themeRow(c, '自动按时间', 'auto'),
                  if (app.themeMode == 'auto')
                    _row(c, '日间时段',
                        sub: true,
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(
                              '${_hh(app.dayStartHour)}:00 — ${_hh(app.nightStartHour)}:00',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: c.sub,
                                  fontFeatures: tabularFigures)),
                          Icon(Icons.chevron_right_rounded,
                              size: 16, color: c.sub),
                        ]),
                        onTap: () => _editDayNight(context)),
                  _themeRow(c, '浅色', 'light'),
                  _themeRow(c, '深色', 'dark'),
                ]),
                const SizedBox(height: 12),
                _group(c, [
                  _row(c, '关于',
                      trailing: Text('版本 1.0.7',
                          style: TextStyle(fontSize: 13, color: c.sub))),
                ]),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '热力按每月预算的 1/30 作为每日基准：绿色低于一半，黄色接近日预算，橙色超出，红色严重超支。\n自动模式下按设定的日间时段切换浅色和深色。',
                    style: TextStyle(
                        fontSize: 11, color: c.sub, height: 1.6),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppColors c) {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.chevron_left_rounded, size: 24, color: c.sub),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
          const SizedBox(width: 4),
          Text('设置',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: c.text)),
        ],
      ),
    );
  }

  Widget _group(AppColors c, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _row(
    AppColors c,
    String label, {
    required Widget trailing,
    VoidCallback? onTap,
    bool sub = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: EdgeInsets.only(left: sub ? 28 : 14, right: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: c.line, width: 0.6),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: sub ? 12 : 13,
                color: sub ? c.sub : c.text,
              ),
            ),
            const Spacer(),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _themeRow(AppColors c, String label, String mode) {
    return _row(
      c,
      label,
      onTap: () => app.setThemeMode(mode),
      trailing: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: app.themeMode == mode ? c.accent : c.line,
            width: 1.5,
          ),
        ),
        child: app.themeMode == mode
            ? Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.accent,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  String _fontName(double v) {
    if (v <= 0.95) return '小';
    if (v <= 1.05) return '标准';
    if (v <= 1.2) return '大';
    return '特大';
  }

  void _cycleFont(AppState app) {
    const next = [1.0, 1.15, 1.3, 0.9];
    final i = next.indexWhere((v) => (v - app.fontScale).abs() < 0.01);
    app.setFontScale(next[(i + 1) % next.length]);
  }

  Future<void> _editBudget(BuildContext context) async {
    final controller =
        TextEditingController(text: app.budget.toStringAsFixed(0));
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('每月预算', style: TextStyle(fontSize: 15)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(prefixText: '¥ '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              Navigator.pop(ctx, v != null && v > 0 ? v : null);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (value != null) app.setBudget(value);
  }

  Future<void> _editDayNight(BuildContext context) async {
    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: app.dayStartHour, minute: 0),
      helpText: '日间开始',
    );
    if (start == null || !context.mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: app.nightStartHour, minute: 0),
      helpText: '夜间开始',
    );
    if (end == null) return;
    await app.setDayNight(start.hour, end.hour);
  }

  String _hh(int h) => h.toString().padLeft(2, '0');

  String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}