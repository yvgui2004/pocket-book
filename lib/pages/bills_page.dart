import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../parser.dart';
import '../theme.dart';

class BillsPage extends StatefulWidget {
  final AppState app;
  const BillsPage({super.key, required this.app});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  late int _year;
  late int _month;
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    final t = widget.app.today;
    _year = t.year;
    _month = t.month;
    _selectedDay = _defaultDay();
  }

  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  int _defaultDay() {
    for (var d = 1; d <= _daysInMonth; d++) {
      if (widget.app.totalForDay(DateTime(_year, _month, d)) > 0) return d;
    }
    final t = widget.app.today;
    if (_year == t.year && _month == t.month) return t.day;
    return 1;
  }

  void _shiftMonth(int delta) {
    setState(() {
      var m = _month + delta;
      var y = _year;
      if (m < 1) {
        m = 12;
        y--;
      } else if (m > 12) {
        m = 1;
        y++;
      }
      _year = y;
      _month = m;
      _selectedDay = _defaultDay();
    });
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
            final monthTotal = app.totalForMonth(_year, _month);
            final remain = app.budget - monthTotal;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 4, 16, 6 + bottomSafeInset(context)),
              child: Column(
                children: [
                  _header(c, app),
                  const SizedBox(height: 6),
                  _calendar(c, app),
                  _legend(c, app),
                  const SizedBox(height: 2),
                  Expanded(child: _dayDetail(c, app)),
                  const SizedBox(height: 6),
                  _summary(c, app, monthTotal, remain),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(AppColors c, AppState app) {
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
          const Spacer(),
          _monthArrow(c, Icons.chevron_left_rounded, () => _shiftMonth(-1)),
          SizedBox(
            width: 94,
            child: Text(
              '$_year年$_month月',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: c.text),
            ),
          ),
          _monthArrow(c, Icons.chevron_right_rounded, () => _shiftMonth(1)),
          const Spacer(),
          // 与左侧返回按钮等宽，保证月份居中
          const SizedBox(width: 30),
        ],
      ),
    );
  }

  Widget _monthArrow(AppColors c, IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 19, color: c.sub),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }

  Widget _calendar(AppColors c, AppState app) {
    final first = DateTime(_year, _month, 1);
    final offset = (first.weekday - 1) % 7; // Monday = 0
    final total = offset + _daysInMonth;
    final rows = ((total / 7).ceil()).clamp(5, 6);
    final today = app.today;

    return Column(
      children: [
        Row(
          children: const ['一', '二', '三', '四', '五', '六', '日']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: TextStyle(fontSize: 10, color: Color(0xFF8B9199))),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 3),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            mainAxisExtent: 46,
          ),
          itemCount: rows * 7,
          itemBuilder: (context, index) {
            final day = index - offset + 1;
            if (day < 1 || day > _daysInMonth) {
              return const SizedBox.shrink();
            }
            final date = DateTime(_year, _month, day);
            final amount = app.totalForDay(date);
            final selected = day == _selectedDay;
            final isToday = app.sameDay(date, today);
            return _dayCell(
                c, app, day, amount, selected, isToday, date);
          },
        ),
      ],
    );
  }

  Widget _dayCell(AppColors c, AppState app, int day, double amount,
      bool selected, bool isToday, DateTime date) {
    final tint = _heatTint(c, app, amount);
    final borderColor = selected ? c.accent : (tint?.border ?? c.line);
    final dayColor =
        selected ? c.accent : (tint?.text ?? (isToday ? c.accent : c.sub));

    return GestureDetector(
      onTap: () => setState(() => _selectedDay = day),
      child: Container(
        decoration: BoxDecoration(
          color: tint?.bg ?? c.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 5,
              left: 6,
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: dayColor,
                  height: 1,
                ),
              ),
            ),
            if (amount > 0)
              Positioned(
                bottom: 5,
                right: 6,
                child: Text(
                  _short(amount),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: tint?.text ?? c.text,
                    fontFeatures: tabularFigures,
                    height: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 热力档位：底色 + 同色系描边 + 同色文字
  static const _heatLight = [
    (bg: Color(0xFFD9F0E1), border: Color(0xFFB9E1C9), text: Color(0xFF17663F)),
    (bg: Color(0xFFF7E8BC), border: Color(0xFFE8D398), text: Color(0xFF7A5600)),
    (bg: Color(0xFFFAD9BF), border: Color(0xFFEFC29E), text: Color(0xFF9A4A0F)),
    (bg: Color(0xFFF9CFD0), border: Color(0xFFECB1B3), text: Color(0xFF9E2222)),
  ];

  static const _heatDark = [
    (bg: Color(0xFF1B3D2B), border: Color(0xFF2A5A3E), text: Color(0xFF7ED9A6)),
    (bg: Color(0xFF3A3018), border: Color(0xFF55461F), text: Color(0xFFE8C766)),
    (bg: Color(0xFF43261A), border: Color(0xFF5F3722), text: Color(0xFFF2A06A)),
    (bg: Color(0xFF442025), border: Color(0xFF6A2E34), text: Color(0xFFF19A9A)),
  ];

  ({Color bg, Color border, Color text})? _heatTint(
      AppColors c, AppState app, double amount) {
    if (amount <= 0) return null;
    final p = amount / (app.budget / 30);
    final i = p <= 0.5 ? 0 : (p <= 1 ? 1 : (p <= 1.5 ? 2 : 3));
    return (c.isDark ? _heatDark : _heatLight)[i];
  }

  Widget _legend(AppColors c, AppState app) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Text('低', style: TextStyle(fontSize: 10, color: c.sub)),
          const SizedBox(width: 4),
          _legendDot(c.isDark ? const Color(0xFF1B3D2B) : const Color(0xFFD9F0E1)),
          _legendDot(c.isDark ? const Color(0xFF3A3018) : const Color(0xFFF7E8BC)),
          _legendDot(c.isDark ? const Color(0xFF43261A) : const Color(0xFFFAD9BF)),
          _legendDot(c.isDark ? const Color(0xFF442025) : const Color(0xFFF9CFD0)),
          Text('高', style: TextStyle(fontSize: 10, color: c.sub)),
          const Spacer(),
          Text(
            '按日预算 ¥${(app.budget / 30).round()}',
            style: TextStyle(fontSize: 10, color: c.sub),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 9,
      height: 9,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _dayDetail(AppColors c, AppState app) {
    final date = DateTime(_year, _month, _selectedDay);
    final items = app.entriesForDay(date).reversed.toList();
    final total = app.totalForDay(date);
    final canAdd = !date.isAfter(app.today);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$_month月$_selectedDay日 周${weekdayName(date)}',
              style: TextStyle(fontSize: 11, color: c.sub),
            ),
            Text(
              money(total),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.text,
                fontFeatures: tabularFigures,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text('这天没有记录',
                      style: TextStyle(fontSize: 12, color: c.sub)),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  itemBuilder: (context, i) =>
                      _entryTile(c, app, items[i]),
                ),
        ),
        if (canAdd)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showAddSheet(app, date),
              icon: Icon(Icons.add_rounded, size: 16, color: c.accent),
              label: Text('补记一笔',
                  style: TextStyle(fontSize: 12, color: c.accent)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
      ],
    );
  }

  void _showAddSheet(AppState app, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEntrySheet(app: app, date: date),
    );
  }

  Widget _entryTile(AppColors c, AppState app, Entry e) {
    return Dismissible(
      key: ValueKey('b-${e.id}'),
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
        height: 32,
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
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 14, color: c.sub),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(
      AppColors c, AppState app, double monthTotal, double remain) {
    final pct =
        app.budget <= 0 ? 0.0 : (monthTotal / app.budget).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('本月已花', style: TextStyle(fontSize: 12, color: c.sub)),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '¥${_trim(monthTotal)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.text,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                    TextSpan(
                      text: ' / ¥${_trim(app.budget)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: c.sub,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: c.line,
              valueColor:
                  AlwaysStoppedAnimation(remain < 0 ? c.warn : c.accent),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                        text: '剩余 ',
                        style: TextStyle(fontSize: 11, color: c.sub)),
                    TextSpan(
                      text: remain < 0
                          ? '已超支 ${money(-remain)}'
                          : money(remain),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: remain < 0 ? c.warn : c.text,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '日均 ${money(monthTotal / 30)}',
                style: TextStyle(
                  fontSize: 11,
                  color: c.sub,
                  fontFeatures: tabularFigures,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _short(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return '${k.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}k';
    }
    return v.round().toString();
  }

  String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

class _AddEntrySheet extends StatefulWidget {
  final AppState app;
  final DateTime date;
  const _AddEntrySheet({required this.app, required this.date});

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
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
    await widget.app.addEntriesTo(widget.date, _parsed);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.date.month}月${widget.date.day}日 周${weekdayName(widget.date)} 补记',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: c.text),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: TextStyle(fontSize: 13, color: c.text),
                decoration: InputDecoration(
                  hintText: '炒饭10 奶茶5',
                  hintStyle: TextStyle(fontSize: 13, color: c.sub),
                  isDense: true,
                  filled: true,
                  fillColor: c.bg,
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
            if (_parsed.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _parsed
                    .map((p) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.ok ? c.accentSoft : c.warnSoft,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            p.ok
                                ? '${p.name} ${money(p.amount)}'
                                : '${p.name} 无法识别',
                            style: TextStyle(
                              fontSize: 11,
                              color: p.ok ? c.accent : c.warn,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: FilledButton(
                onPressed: _allOk ? _submit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: c.accentStrong,
                  disabledBackgroundColor: c.line,
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
        ),
      ),
    );
  }
}