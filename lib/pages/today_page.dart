import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../parser.dart';
import '../theme.dart';
import 'bills_page.dart';
import 'settings_page.dart';

class TodayPage extends StatefulWidget {
  final AppState app;
  const TodayPage({super.key, required this.app});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<ParseItem> _parsed = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    final text = _controller.text.trim();
    setState(() => _parsed = text.isEmpty ? [] : parseInput(text));
  }

  bool get _allOk => _parsed.isNotEmpty && _parsed.every((p) => p.ok);

  Future<void> _submit() async {
    if (!_allOk) return;
    await widget.app.addEntries(_parsed);
    _controller.clear();
    _focus.unfocus();
    if (mounted) setState(() => _parsed = []);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.app,
          builder: (context, _) {
            final app = widget.app;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 4, 16, 6 + bottomSafeInset(context)),
              child: Column(
                children: [
                  _header(c, app),
                  const SizedBox(height: 8),
                  _todayRow(c, app),
                  const SizedBox(height: 10),
                  _budgetCard(c, app),
                  const SizedBox(height: 10),
                  _infoGrid(c, app),
                  const SizedBox(height: 6),
                  Expanded(child: _list(c, app)),
                  if (_parsed.isNotEmpty) _parsePreview(c, app),
                  _inputBar(c, app),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(AppColors c, AppState app) {
    final today = app.today;
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          Text(
            '${today.month}月${today.day}日',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: c.text),
          ),
          const SizedBox(width: 5),
          Text('周${weekdayName(today)}',
              style: TextStyle(fontSize: 13, color: c.sub)),
          const Spacer(),
          _iconBtn(c, Icons.list_alt_rounded, '账单', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BillsPage(app: app)),
            );
          }),
          _iconBtn(c, Icons.tune_rounded, '设置', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsPage(app: app)),
            );
          }),
        ],
      ),
    );
  }

  Widget _iconBtn(AppColors c, IconData icon, String tip, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      tooltip: tip,
      icon: Icon(icon, size: 20, color: c.sub),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
    );
  }

  Widget _todayRow(AppColors c, AppState app) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('今日已花',
                  style: TextStyle(fontSize: 11, color: c.sub)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  money(app.todayTotal),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: _todayColor(c, app),
                    fontFeatures: tabularFigures,
                    letterSpacing: -0.6,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('今日剩余', style: TextStyle(fontSize: 11, color: c.sub)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                money(app.todayLeft),
                maxLines: 1,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: app.todayLeft < 0 ? c.warn : c.text,
                  fontFeatures: tabularFigures,
                  letterSpacing: -0.4,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _todayColor(AppColors c, AppState app) {
    if (app.remain < 0 || app.todayTotal > app.daily * 2) return c.warn;
    if (app.todayTotal > app.daily) {
      return c.isDark ? const Color(0xFFF0A64A) : const Color(0xFFC2740B);
    }
    return c.text;
  }

  Widget _budgetCard(AppColors c, AppState app) {
    final monthPct = app.budget <= 0
        ? 0.0
        : (app.monthTotal / app.budget).clamp(0.0, 1.0);
    final weekPct = app.weekBudget <= 0
        ? 0.0
        : (app.weekTotal / app.weekBudget).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _budgetRow(c, '本月已花', app.monthTotal, app.budget, app.remain),
          const SizedBox(height: 9),
          _bar(c, monthPct, app.remain < 0),
          const SizedBox(height: 12),
          _budgetRow(c, '本周已花', app.weekTotal, app.weekBudget, app.weekRemain),
          const SizedBox(height: 9),
          _bar(c, weekPct, app.weekRemain < 0),
        ],
      ),
    );
  }

  Widget _budgetRow(
      AppColors c, String label, double spent, double budget, double remain) {
    final over = remain < 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: c.sub)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¥${_trim(spent)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.text,
                fontFeatures: tabularFigures,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '/ ¥${_trim(budget)}',
              style: TextStyle(
                fontSize: 12,
                color: c.sub,
                fontFeatures: tabularFigures,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: over ? c.warnSoft : c.accentSoft,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                over ? '超支 ${(-remain).round()}' : '余 ${remain.round()}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: over ? c.warn : c.accent,
                  fontFeatures: tabularFigures,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bar(AppColors c, double pct, bool over) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: pct,
        minHeight: 6,
        backgroundColor: c.line,
        valueColor: AlwaysStoppedAnimation(over ? c.warn : c.accent),
      ),
    );
  }

  Widget _infoGrid(AppColors c, AppState app) {
    return Column(
      children: [
        _infoRow(c, '本月余', app.daysLeft, app.daily, app.monthAvg,
            dailyNegative: app.remain < 0),
        const SizedBox(height: 4),
        _infoRow(c, '本周余', app.weekDaysLeft, app.weekDaily, app.weekAvg,
            dailyNegative: app.weekRemain < 0),
      ],
    );
  }

  Widget _infoRow(AppColors c, String label, int daysLeft, double daily,
      double avg, {required bool dailyNegative}) {
    final base = TextStyle(fontSize: 11, color: c.sub);
    final strong = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: c.text,
      fontFeatures: tabularFigures,
    );
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text.rich(
            TextSpan(style: base, children: [
              TextSpan(text: '$label '),
              TextSpan(text: '$daysLeft', style: strong),
              const TextSpan(text: ' 天'),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 6,
          child: Text.rich(
            TextSpan(style: base, children: [
              const TextSpan(text: '每日可用 '),
              TextSpan(
                text: money(daily),
                style: dailyNegative
                    ? strong.copyWith(color: c.warn)
                    : strong,
              ),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 6,
          child: Text.rich(
            TextSpan(style: base, children: [
              const TextSpan(text: '日均消费 '),
              TextSpan(text: money(avg), style: strong),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _list(AppColors c, AppState app) {
    final items = app.todayEntries.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('今日', style: TextStyle(fontSize: 11, color: c.sub)),
            Text(
              money(app.todayTotal),
              style: TextStyle(
                fontSize: 11,
                color: c.sub,
                fontFeatures: tabularFigures,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('今天还没有记录',
                          style: TextStyle(fontSize: 12, color: c.sub)),
                      const SizedBox(height: 4),
                      Text('在下方输入「炒饭10 奶茶5」开始',
                          style: TextStyle(fontSize: 11, color: c.sub)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  itemBuilder: (context, i) =>
                      _entryTile(c, app, items[i]),
                ),
        ),
      ],
    );
  }

  Widget _entryTile(AppColors c, AppState app, Entry e) {
    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: c.warn,
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Text('删除',
            style: TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      onDismissed: (_) {
        if (e.id != null) app.deleteEntry(e.id!);
      },
      child: SizedBox(
        height: 34,
        child: Row(
          children: [
            Expanded(
              child: Text(
                e.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: c.text),
              ),
            ),
            Text(
              money(e.amount),
              style: TextStyle(
                fontSize: 13,
                color: c.text,
                fontFeatures: tabularFigures,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('左滑条目可删除'),
                    duration: Duration(milliseconds: 1500),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Icon(Icons.close_rounded, size: 14, color: c.sub),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _parsePreview(AppColors c, AppState app) {
    final add = _parsed.fold(0.0, (s, p) => s + (p.ok ? p.amount : 0));
    final after = app.daily - app.todayTotal - add;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ..._parsed.map((p) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: p.ok ? c.accentSoft : c.warnSoft,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  p.ok ? '${p.name} ${money(p.amount)}' : '${p.name} 无法识别',
                  style: TextStyle(
                    fontSize: 11,
                    color: p.ok ? c.accent : c.warn,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )),
          if (_allOk)
            Text(
              after >= 0
                  ? '记上后今日还剩 ${money(after)}'
                  : '记上后今日超支 ${money(-after)}',
              style: TextStyle(
                fontSize: 10,
                color: after >= 0 ? c.sub : c.warn,
                fontFeatures: tabularFigures,
              ),
            ),
        ],
      ),
    );
  }

  Widget _inputBar(AppColors c, AppState app) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 38,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: TextStyle(fontSize: 13, color: c.text),
              decoration: InputDecoration(
                hintText: '炒饭10 奶茶5',
                hintStyle: TextStyle(fontSize: 13, color: c.sub),
                isDense: true,
                filled: true,
                fillColor: c.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.accent, width: 1.2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 38,
          child: FilledButton(
            onPressed: _allOk ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: c.accentStrong,
              disabledBackgroundColor: c.line,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              '记上',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _allOk ? Colors.white : c.sub,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}