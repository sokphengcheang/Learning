import 'package:flutter_test/flutter_test.dart';
import 'package:okchaktrong/game.dart';

void main() {
  const wk = Piece(Side.white, Kind.king);
  const bk = Piece(Side.black, Kind.king);
  bool can(Game g, int from, int to) =>
      g.legalMoves().any((m) => m.from == from && m.to == to);
  test('Initial placement and legal opening moves', () {
    final g = Game();
    expect(g.board.whereType<Piece>().length, 32);
    expect(g.board[60]?.kind, Kind.king);
    expect(g.board[3]?.kind, Kind.king);
    expect(g.board[59]?.kind, Kind.minister);
    expect(g.board[4]?.kind, Kind.minister);
    expect(g.board[48], isNull);
    expect(can(g, 40, 32), isTrue);
    expect(can(g, 40, 24), isFalse);
    expect(g.legalMoves().length, 23);
  });
  test('Elephant moves diagonally and forward, but not backwards straight', () {
    final g = Game.position(
        {60: wk, 3: bk, 35: const Piece(Side.white, Kind.elephant)});
    final targets =
        g.legalMoves().where((m) => m.from == 35).map((m) => m.to).toSet();
    expect(targets, {26, 28, 42, 44, 27});
  });
  test('Minister cannot move like an international queen', () {
    final g = Game.position(
        {60: wk, 3: bk, 35: const Piece(Side.white, Kind.minister)});
    expect(g.legalMoves().where((m) => m.from == 35).map((m) => m.to).toSet(),
        {26, 28, 42, 44});
  });
  test('Fish captures diagonally and promotes at the sixth rank', () {
    final g = Game.position({
      60: wk,
      3: bk,
      24: const Piece(Side.white, Kind.pawn),
      17: const Piece(Side.black, Kind.horse)
    });
    expect(can(g, 24, 17), isTrue);
    expect(can(g, 24, 16), isTrue);
    g.play(const Move(24, 17));
    expect(g.board[17]?.kind, Kind.minister);
    expect(g.board[24], isNull);
    expect(g.turn, Side.black);
  });
  test('Crimson fish promotes at rank three', () {
    final g = Game.position(
        {60: wk, 3: bk, 32: const Piece(Side.black, Kind.pawn)},
        turn: Side.black);
    g.play(const Move(32, 40));
    expect(g.board[40]?.kind, Kind.minister);
  });
  test('Pinned pieces cannot expose the king', () {
    final g = Game.position({
      60: wk,
      0: bk,
      52: const Piece(Side.white, Kind.boat),
      4: const Piece(Side.black, Kind.boat)
    });
    expect(can(g, 52, 51), isFalse);
    expect(can(g, 52, 44), isTrue);
    expect(can(g, 52, 4), isTrue);
  });
  test('Kings cannot move adjacent or capture one another', () {
    final g = Game.position({60: wk, 44: bk});
    expect(can(g, 60, 52), isFalse);
    expect(can(g, 60, 51), isFalse);
    expect(can(g, 60, 59), isTrue);
  });
  test('Horse jumps over pieces; boat cannot', () {
    final g = Game();
    expect(can(g, 57, 51), isTrue);
    expect(can(g, 56, 32), isFalse);
  });
  test('Checkmate and stalemate are distinct', () {
    final mate = Game.position({
      0: bk,
      18: wk,
      8: const Piece(Side.white, Kind.boat),
      9: const Piece(Side.white, Kind.boat)
    }, turn: Side.black);
    expect(mate.outcome, 'Ivory wins by checkmate');
    final stale = Game.position({
      0: bk,
      18: wk,
      17: const Piece(Side.white, Kind.boat),
      10: const Piece(Side.white, Kind.boat)
    }, turn: Side.black);
    expect(stale.outcome, 'Draw by stalemate');
  });
  test('Repeated positions draw after three occurrences', () {
    final g = Game.position({
      60: wk,
      4: bk,
      56: const Piece(Side.white, Kind.boat),
      0: const Piece(Side.black, Kind.boat)
    });
    g.repetitions[g.key] = 1;
    for (var i = 0; i < 2; i++) {
      g.play(const Move(60, 61));
      g.play(const Move(4, 5));
      g.play(const Move(61, 60));
      g.play(const Move(5, 4));
    }
    expect(g.outcome, 'Draw by repetition');
  });
  test('Computer returns legal moves without mutating the position', () {
    final g = Game();
    final key = g.key;
    final m = Computer(seed: 7).choose(g, depth: 1)!;
    expect(can(g, m.from, m.to), isTrue);
    expect(g.key, key);
  });
  test('Computer takes an unprotected boat', () {
    final g = Game.position({
      63: wk,
      0: bk,
      35: const Piece(Side.black, Kind.boat),
      39: const Piece(Side.white, Kind.boat)
    }, turn: Side.black);
    final m = Computer(seed: 2).choose(g, depth: 2)!;
    expect(m.from, 35);
    expect(m.to, 39);
  });
  test('Illegal moves leave the board intact', () {
    final g = Game();
    final key = g.key;
    expect(() => g.play(const Move(40, 24)), throwsArgumentError);
    expect(g.key, key);
  });
}
