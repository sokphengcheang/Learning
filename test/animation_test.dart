import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okchaktrong/animated_board.dart';
import 'package:okchaktrong/game.dart';
import 'package:okchaktrong/piece_3d.dart';

void main() {
  Game position() => Game.position({
        63: const Piece(Side.white, Kind.king),
        0: const Piece(Side.black, Kind.king),
        44: const Piece(Side.white, Kind.horse),
        27: const Piece(Side.black, Kind.pawn)
      });
  testWidgets('Capture travels across the board and the captured piece fades',
      (tester) async {
    final game = position();
    late StateSetter redraw;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
                child: SizedBox(
                    width: 400,
                    child: StatefulBuilder(builder: (context, setState) {
                      redraw = setState;
                      return AnimatedBoard(
                          game: game,
                          selected: null,
                          flipped: false,
                          threeD: true,
                          animations: true,
                          legalMoves: game.legalMoves(),
                          onTap: (_) {});
                    }))))));
    expect(find.byType(Piece3D), findsNWidgets(4));
    redraw(() => game.play(const Move(44, 27)));
    await tester.pump();
    final moving = find.byKey(const ValueKey('moving-piece'));
    final start = tester.getTopLeft(moving);
    expect(find.byKey(const ValueKey('captured-piece')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    final middle = tester.getTopLeft(moving);
    expect(middle.dy, lessThan(start.dy));
    expect(middle.dx, lessThan(start.dx));
    await tester.pumpAndSettle();
    expect(moving, findsNothing);
    expect(find.byKey(const ValueKey('captured-piece')), findsNothing);
    expect(find.byType(Piece3D), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Reduced motion skips movement and capture animation',
      (tester) async {
    final game = position();
    late StateSetter redraw;
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
                body: SizedBox(
                    width: 400,
                    child: StatefulBuilder(builder: (context, setState) {
                      redraw = setState;
                      return AnimatedBoard(
                          game: game,
                          selected: null,
                          flipped: false,
                          threeD: true,
                          animations: true,
                          legalMoves: game.legalMoves(),
                          onTap: (_) {});
                    }))))));
    redraw(() => game.play(const Move(44, 27)));
    await tester.pump();
    expect(find.byKey(const ValueKey('moving-piece')), findsNothing);
    expect(find.byType(Piece3D), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Undo and flip cancel an in-progress transition', (tester) async {
    var game = position();
    final original = game.copy();
    var flipped = false;
    late StateSetter redraw;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 400,
                child: StatefulBuilder(builder: (context, setState) {
                  redraw = setState;
                  return AnimatedBoard(
                      game: game,
                      selected: null,
                      flipped: flipped,
                      threeD: true,
                      animations: true,
                      legalMoves: game.legalMoves(),
                      onTap: (_) {});
                })))));
    redraw(() => game.play(const Move(44, 27)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    redraw(() {
      game = original;
      flipped = true;
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('moving-piece')), findsNothing);
    expect(find.byType(Piece3D), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
}
