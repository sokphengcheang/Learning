import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okchaktrong/main.dart';

void main() {
  testWidgets('Local mode supports moves and undo', (tester) async {
    await tester.pumpWidget(const ChaktrangApp());
    await tester.ensureVisible(find.text('Local'));
    await tester.tap(find.text('Local'));
    await tester.pumpAndSettle();
    final page = tester.widget<GamePage>(find.byType(GamePage));
    expect(page, isNotNull);
    await tester.ensureVisible(find.byTooltip('a3 · Ivory Fish'));
    await tester.tap(find.byTooltip('a3 · Ivory Fish'));
    await tester.pump();
    await tester.ensureVisible(find.byTooltip('a4'));
    await tester.tap(find.byTooltip('a4'));
    await tester.pumpAndSettle();
    expect(find.text('Crimson to move'), findsOneWidget);
    expect(find.text('Fish  a3–a4'), findsOneWidget);
    await tester.ensureVisible(find.text('Undo'));
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Ivory to move'), findsOneWidget);
    expect(find.byTooltip('a3 · Ivory Fish'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Rules describe promotion and limitations', (tester) async {
    await tester.pumpWidget(const ChaktrangApp());
    await tester.tap(find.text('How to play'));
    await tester.pumpAndSettle();
    expect(find.text('The art of Ouk Chaktrang'), findsOneWidget);
    expect(find.textContaining('Cambodian counting activates automatically'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Narrow display has no layout exceptions', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ChaktrangApp());
    expect(tester.takeException(), isNull);
  });
}
