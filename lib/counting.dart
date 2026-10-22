import 'game.dart' show Piece, Kind, Side, SideInfo;

/// Cambodian counting, using half-moves internally to preserve whose turn it is.
/// A separate board counter survives the transition to bare-king counting.
class EndgameCount {
  final Side defender;
  final int limit;
  final int plies;
  final int? boardPlies;
  final bool piecesHonor;
  const EndgameCount(
      {required this.defender,
      required this.limit,
      required this.plies,
      required this.boardPlies,
      required this.piecesHonor});

  bool get boardDeadlineFirst =>
      boardPlies != null && 126 - boardPlies! < limit * 2 - plies;
  int get effectiveLimit => boardDeadlineFirst ? 63 : limit;
  int get effectivePlies => boardDeadlineFirst ? boardPlies! : plies;
  bool get expired => effectivePlies > effectiveLimit * 2;
  String get label =>
      '${piecesHonor && !boardDeadlineFirst ? 'Pieces’ honor' : 'Board’s honor'} · '
      '${effectivePlies ~/ 2}${effectivePlies.isOdd ? '½' : ''} / $effectiveLimit';

  static int? limitFor(List<Piece?> board, Side defender) {
    final all = board.whereType<Piece>().toList();
    final own = all.where((p) => p.side == defender).length;
    final enemy = all.where((p) => p.side == defender.other).toList();
    if (own > 3 || enemy.length <= 1) return null;
    if (own > 1) return 63;
    if (all.any((p) => p.kind == Kind.pawn)) return null;
    int n(Kind kind) => enemy.where((p) => p.kind == kind).length;
    if (n(Kind.boat) > 1) return 7;
    if (n(Kind.boat) == 1) return 15;
    if (n(Kind.elephant) > 1) return 21;
    if (n(Kind.horse) > 1) return 31;
    if (n(Kind.elephant) == 1) return 43;
    return 63;
  }

  /// Mirrors the Cambodian transitions, including last-fish capture by a bare
  /// king. Automatic activation is the app's policy; no verbal claim is needed.
  static EndgameCount? advance(
      EndgameCount? previous, List<Piece?> board, Side nextTurn,
      {bool capture = false,
      bool promotion = false,
      bool capturedFish = false,
      bool tick = true}) {
    final pieces = board.whereType<Piece>().toList();
    int own(Side s) => pieces.where((p) => p.side == s).length;
    var state = previous == null
        ? null
        : EndgameCount(
            defender: previous.defender,
            limit: previous.limit,
            plies: previous.plies + (tick ? 1 : 0),
            boardPlies: previous.boardPlies == null
                ? null
                : previous.boardPlies! + (tick ? 1 : 0),
            piecesHonor: previous.piecesHonor);
    EndgameCount start(Side side, int limit, int offset) {
      final bare = own(side) == 1;
      return EndgameCount(
          defender: side,
          limit: limit,
          plies: bare ? 2 * pieces.length + offset : 0,
          boardPlies: state?.boardPlies ?? (bare ? null : 0),
          piecesHonor: bare);
    }

    final mover = nextTurn.other;
    final moverLimit = limitFor(board, mover);
    if (capturedFish && own(mover) == 1 && moverLimit != null) {
      state = start(mover, moverLimit, -1);
    }
    final nextLimit = limitFor(board, nextTurn);
    if ((state == null || ((capture || promotion) && own(nextTurn) == 1)) &&
        nextLimit != null) {
      state = start(nextTurn, nextLimit, 0);
    }
    return state;
  }
}
