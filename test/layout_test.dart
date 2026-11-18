import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_book/app_state.dart';
import 'package:pocket_book/models.dart';
import 'package:pocket_book/pages/bills_page.dart';
import 'package:pocket_book/pages/today_page.dart';
import 'package:pocket_book/theme.dart';

AppState demoState() {
  final app = AppState();
  final t = app.today;
  app.entries = [
    Entry(name: '炒饭', amount: 10, date: t),
    Entry(name: '奶茶', amount: 5, date: t),
    Entry(name: '食堂', amount: 300, date: DateTime(t.year, t.month, 1)),
    Entry(name: '超市', amount: 88, date: DateTime(t.year, t.month, 3)),
  ];
  return app;
}

Widget host(Widget page, double scale) => MaterialApp(
      theme: buildAppTheme(AppColors.light),
      home: page,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
    );

Future<void> pump(WidgetTester tester, Widget page, Size size,
    {double scale = 1.0}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(host(page, scale));
  await tester.pump();
}

void main() {
  const sizes = [Size(320, 640), Size(360, 720), Size(412, 915), Size(600, 900)];

  for (final size in sizes) {
    for (final scale in [0.9, 1.0]) {
      testWidgets('今日页 $size ×$scale 不溢出', (tester) async {
        final app = demoState();
        app.fontScale = scale;
        await pump(tester, TodayPage(app: app), size, scale: scale);
        expect(tester.takeException(), isNull);
      });

      testWidgets('账单页 $size ×$scale 不溢出', (tester) async {
        final app = demoState();
        app.fontScale = scale;
        await pump(tester, BillsPage(app: app), size, scale: scale);
        expect(tester.takeException(), isNull);
      });
    }
  }
}