import 'package:flutter_test/flutter_test.dart';
import 'package:okchaktrong/counting.dart';
import 'package:okchaktrong/game.dart';

void main() {
  const wk = Piece(Side.white, Kind.king), bk = Piece(Side.black, Kind.king);
  List<Piece?> pieces(List<Kind> attacking,
          {List<Kind> defending = const []}) =>
      [
        wk,
        bk,
        ...attacking.map((k) => Piece(Side.black, k)),
        ...defending.map((k) => Piece(Side.white, k))
      ];
  test('Cambodian bare-king limits use strongest applicable material', () {
    final cases = <List<Kind>, int>{
      [Kind.boat, Kind.boat]: 7,
      [Kind.boat]: 15,
      [Kind.elephant, Kind.elephant]: 21,
      [Kind.horse, Kind.horse]: 31,
      [Kind.elephant]: 43,
      [Kind.horse]: 63,
      [Kind.minister]: 63,
      [Kind.boat, Kind.elephant, Kind.horse]: 15,
      [Kind.elephant, Kind.horse, Kind.horse]: 31,
    };
    cases.forEach((material, limit) =>
        expect(EndgameCount.limitFor(pieces(material), Side.white), limit));
  });
  test('Board honor allows fish and requires at most three own pieces', () {
    expect(
        EndgameCount.limitFor(
            pieces([Kind.boat], defending: [Kind.pawn, Kind.horse]),
            Side.white),
        63);
    expect(
        EndgameCount.limitFor(
            pieces([Kind.boat],
                defending: [Kind.pawn, Kind.horse, Kind.minister]),
            Side.white),
        isNull);
    expect(
        EndgameCount.limitFor(pieces([], defending: [Kind.boat]), Side.white),
        isNull);
    expect(EndgameCount.limitFor(pieces([Kind.boat, Kind.pawn]), Side.white),
        isNull);
  });
  test('Bare-king count starts at total pieces, not zero', () {
    final c = EndgameCount.advance(null, pieces([Kind.boat]), Side.white,
        tick: false)!;
    expect(c.plies, 6);
    expect(c.limit, 15);
    expect(c.piecesHonor, isTrue);
    expect(c.boardPlies, isNull);
  });
  test('Half-move boundary expires only after the final permitted count', () {
    const c = EndgameCount(
        defender: Side.white,
        limit: 15,
        plies: 30,
        boardPlies: null,
        piecesHonor: true);
    expect(c.expired, isFalse);
    final next = EndgameCount.advance(c, pieces([Kind.boat]), Side.black)!;
    expect(next.expired, isTrue);
  });
  test('Earlier board deadline survives transition to pieces honor', () {
    const c = EndgameCount(
        defender: Side.white,
        limit: 63,
        plies: 124,
        boardPlies: 124,
        piecesHonor: false);
    final next = EndgameCount.advance(c, pieces([Kind.boat]), Side.white,
        capture: true)!;
    expect(next.limit, 15);
    expect(next.plies, 6);
    expect(next.boardPlies, 125);
    expect(next.effectiveLimit, 63);
    final last = EndgameCount.advance(next, pieces([Kind.boat]), Side.black)!;
    expect(last.expired, isFalse);
    expect(EndgameCount.advance(last, pieces([Kind.boat]), Side.white)!.expired,
        isTrue);
  });
  test('Bare king taking the last fish starts on the proper half-move', () {
    final c = EndgameCount.advance(null, pieces([Kind.boat]), Side.black,
        capture: true, capturedFish: true)!;
    expect(c.defender, Side.white);
    expect(c.plies, 5);
    expect(c.limit, 15);
  });
  test('Bare king capturing a boat does not restart an active count', () {
    const c = EndgameCount(
        defender: Side.white,
        limit: 7,
        plies: 10,
        boardPlies: null,
        piecesHonor: true);
    final next = EndgameCount.advance(c, pieces([Kind.boat]), Side.black,
        capture: true)!;
    expect(next.limit, 7);
    expect(next.plies, 11);
    final reply = EndgameCount.advance(next, pieces([Kind.boat]), Side.white)!;
    expect(reply.limit, 7);
    expect(reply.plies, 12);
  });
  test('Copies preserve counts without sharing mutable game state', () {
    final g =
        Game.position({63: wk, 0: bk, 8: const Piece(Side.black, Kind.boat)});
    final copy = g.copy();
    expect(copy.counting, g.counting);
    copy.play(const Move(63, 62));
    expect(copy.counting!.plies, g.counting!.plies + 1);
    expect(g.board[63], wk);
  });
  test('Counting draw is terminal and AI returns no move', () {
    final g =
        Game.position({63: wk, 0: bk, 8: const Piece(Side.black, Kind.boat)});
    g.counting = const EndgameCount(
        defender: Side.white,
        limit: 15,
        plies: 31,
        boardPlies: null,
        piecesHonor: true);
    expect(g.outcome, 'Draw by endgame counting');
    expect(Computer().choose(g), isNull);
    expect(() => g.play(const Move(63, 62)), throwsArgumentError);
  });
  test('Checkmate takes precedence over expired count', () {
    final g = Game.position({
      0: bk,
      18: wk,
      8: const Piece(Side.white, Kind.boat),
      9: const Piece(Side.white, Kind.boat)
    }, turn: Side.black);
    g.counting = const EndgameCount(
        defender: Side.black,
        limit: 7,
        plies: 15,
        boardPlies: null,
        piecesHonor: true);
    expect(g.outcome, 'Ivory wins by checkmate');
  });
  test('Promotion of the last fish activates bare-king counting', () {
    final g =
        Game.position({63: wk, 0: bk, 24: const Piece(Side.white, Kind.pawn)});
    expect(g.counting, isNull);
    g.play(const Move(24, 16));
    expect(g.counting!.defender, Side.black);
    expect(g.counting!.piecesHonor, isTrue);
    expect(g.counting!.plies, 6);
    expect(g.counting!.limit, 63);
  });
  test('Bare-king last-fish capture reaches the game counter', () {
    final g = Game.position({
      35: wk,
      0: bk,
      8: const Piece(Side.black, Kind.boat),
      27: const Piece(Side.black, Kind.pawn)
    });
    expect(g.counting, isNull);
    g.play(const Move(35, 27));
    expect(g.counting!.defender, Side.white);
    expect(g.counting!.plies, 5);
    expect(g.counting!.limit, 15);
  });
  test('New game starts without counting',
      () => expect(Game().counting, isNull));
}
