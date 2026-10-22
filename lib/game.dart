import 'dart:math';
import 'counting.dart';

enum Side { white, black }

extension SideInfo on Side {
  Side get other => this == Side.white ? Side.black : Side.white;
  int get forward => this == Side.white ? -1 : 1;
  String get label => this == Side.white ? 'Ivory' : 'Crimson';
}

enum Kind { king, boat, horse, elephant, minister, pawn }

class Piece {
  final Side side;
  final Kind kind;
  const Piece(this.side, this.kind);
  String get symbol => const {
        Kind.king: '♚',
        Kind.boat: '♜',
        Kind.horse: '♞',
        Kind.elephant: '♝',
        Kind.minister: '♛',
        Kind.pawn: '♟',
      }[kind]!;
  String get name => const {
        Kind.king: 'King',
        Kind.boat: 'Boat',
        Kind.horse: 'Horse',
        Kind.elephant: 'Elephant',
        Kind.minister: 'Minister',
        Kind.pawn: 'Fish',
      }[kind]!;
}

class Move {
  final int from, to;
  const Move(this.from, this.to);
  String get notation => '${squareName(from)}–${squareName(to)}';
}

String squareName(int square) => '${'abcdefgh'[square % 8]}${8 - square ~/ 8}';

class Game {
  List<Piece?> board;
  Side turn;
  Move? lastMove;
  int ply;
  final Map<String, int> repetitions;
  EndgameCount? counting;
  Game._(this.board, this.turn, this.lastMove, this.ply, this.repetitions);
  factory Game() {
    final b = List<Piece?>.filled(64, null);
    const back = [
      Kind.boat,
      Kind.horse,
      Kind.elephant,
      Kind.minister,
      Kind.king,
      Kind.elephant,
      Kind.horse,
      Kind.boat
    ];
    for (var c = 0; c < 8; c++) {
      b[56 + c] = Piece(Side.white, back[c]);
      b[c] = Piece(Side.black, back[7 - c]);
      b[40 + c] = const Piece(Side.white, Kind.pawn);
      b[16 + c] = const Piece(Side.black, Kind.pawn);
    }
    final g = Game._(b, Side.white, null, 0, {});
    g.repetitions[g.key] = 1;
    return g;
  }
  // Useful for analysis and tests; row 0 is rank 8.
  factory Game.position(Map<int, Piece> pieces, {Side turn = Side.white}) {
    final b = List<Piece?>.filled(64, null);
    pieces.forEach((i, p) => b[i] = p);
    final g = Game._(b, turn, null, 0, {});
    g.counting = EndgameCount.advance(null, b, turn, tick: false);
    return g;
  }
  Game copy() =>
      Game._(List.of(board), turn, lastMove, ply, Map.of(repetitions))
        ..counting = counting;
  String get key =>
      '${turn.index}:${board.map((p) => p == null ? '.' : '${p.side.index}${p.kind.index}').join(',')}';
  bool _inside(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;
  Iterable<int> attacks(int from) sync* {
    final p = board[from];
    if (p == null) return;
    final r = from ~/ 8, c = from % 8;
    if (p.kind == Kind.boat) {
      for (final d in const [
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1]
      ]) {
        var nr = r + d[0], nc = c + d[1];
        while (_inside(nr, nc)) {
          final to = nr * 8 + nc;
          yield to;
          if (board[to] != null) break;
          nr += d[0];
          nc += d[1];
        }
      }
      return;
    }
    final List<List<int>> deltas;
    switch (p.kind) {
      case Kind.king:
        deltas = const [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
          [1, 1],
          [1, -1],
          [-1, 1],
          [-1, -1]
        ];
      case Kind.horse:
        deltas = const [
          [2, 1],
          [2, -1],
          [-2, 1],
          [-2, -1],
          [1, 2],
          [1, -2],
          [-1, 2],
          [-1, -2]
        ];
      case Kind.elephant:
        deltas = [
          [1, 1],
          [1, -1],
          [-1, 1],
          [-1, -1],
          [p.side.forward, 0]
        ];
      case Kind.minister:
        deltas = const [
          [1, 1],
          [1, -1],
          [-1, 1],
          [-1, -1]
        ];
      case Kind.pawn:
        deltas = [
          [p.side.forward, 1],
          [p.side.forward, -1]
        ];
      case Kind.boat:
        return;
    }
    for (final d in deltas) {
      if (_inside(r + d[0], c + d[1])) yield (r + d[0]) * 8 + c + d[1];
    }
  }

  bool inCheck(Side side) {
    final king =
        board.indexWhere((p) => p?.kind == Kind.king && p?.side == side);
    if (king < 0) return true;
    for (var i = 0; i < 64; i++) {
      if (board[i]?.side == side.other && attacks(i).contains(king))
        return true;
    }
    return false;
  }

  List<Move> legalMoves() {
    final result = <Move>[];
    for (var i = 0; i < 64; i++) {
      final p = board[i];
      if (p == null || p.side != turn) continue;
      final targets = <int>[];
      if (p.kind == Kind.pawn) {
        final next = i + p.side.forward * 8;
        if (next >= 0 && next < 64 && board[next] == null) targets.add(next);
        targets.addAll(attacks(i).where((j) => board[j]?.side == turn.other));
      } else {
        targets.addAll(attacks(i));
      }
      for (final to in targets) {
        if (board[to]?.side == turn || board[to]?.kind == Kind.king) continue;
        final move = Move(i, to);
        final next = copy().._apply(move);
        if (!next.inCheck(turn)) result.add(move);
      }
    }
    return result;
  }

  void _apply(Move m) {
    final p = board[m.from]!;
    final captured = board[m.to];
    final promotionRow = p.side == Side.white ? 2 : 5;
    board[m.to] = p.kind == Kind.pawn && m.to ~/ 8 == promotionRow
        ? Piece(p.side, Kind.minister)
        : p;
    board[m.from] = null;
    lastMove = m;
    turn = turn.other;
    ply++;
    counting = EndgameCount.advance(counting, board, turn,
        capture: captured != null,
        capturedFish: captured?.kind == Kind.pawn,
        promotion: p.kind == Kind.pawn && board[m.to]?.kind == Kind.minister);
  }

  void play(Move m) {
    if (outcome != null ||
        !legalMoves().any((x) => x.from == m.from && x.to == m.to)) {
      throw ArgumentError('Illegal move');
    }
    _apply(m);
    repetitions.update(key, (n) => n + 1, ifAbsent: () => 1);
  }

  String? get outcome {
    if (legalMoves().isEmpty) {
      return inCheck(turn)
          ? '${turn.other.label} wins by checkmate'
          : 'Draw by stalemate';
    }
    if (counting?.expired ?? false) return 'Draw by endgame counting';
    if ((repetitions[key] ?? 0) >= 3) return 'Draw by repetition';
    if (board.whereType<Piece>().every((p) => p.kind == Kind.king))
      return 'Draw — bare kings';
    return null;
  }
}

class Computer {
  final Random random;
  Computer({int? seed}) : random = Random(seed);
  static const values = {
    Kind.king: 20000,
    Kind.boat: 500,
    Kind.horse: 300,
    Kind.elephant: 220,
    Kind.minister: 150,
    Kind.pawn: 100
  };
  Move? choose(Game game, {int depth = 2}) {
    final moves = game.legalMoves()..shuffle(random);
    if (game.outcome != null || moves.isEmpty) return null;
    Move? best;
    var score = -1000000;
    for (final m in moves) {
      final next = game.copy().._apply(m);
      final value = -_search(next, depth - 1, -1000000, 1000000);
      if (value > score) {
        score = value;
        best = m;
      }
    }
    return best;
  }

  int _search(Game g, int depth, int alpha, int beta) {
    final moves = g.legalMoves();
    if (moves.isEmpty) return g.inCheck(g.turn) ? -100000 - depth : 0;
    if ((g.counting?.expired ?? false) || (g.repetitions[g.key] ?? 0) >= 3)
      return 0;
    if (depth <= 0) {
      var total = 0;
      for (var i = 0; i < 64; i++) {
        final p = g.board[i];
        if (p == null) continue;
        final advance = p.side == Side.white ? 7 - i ~/ 8 : i ~/ 8;
        final central = (3.5 - (i % 8 - 3.5).abs()).round() * 3;
        final value =
            values[p.kind]! + (p.kind == Kind.pawn ? advance * 8 : central);
        total += p.side == g.turn ? value : -value;
      }
      return total;
    }
    moves.sort((a, b) => (values[g.board[b.to]?.kind] ?? 0)
        .compareTo(values[g.board[a.to]?.kind] ?? 0));
    for (final m in moves) {
      final next = g.copy().._apply(m);
      final score = -_search(next, depth - 1, -beta, -alpha);
      if (score >= beta) return beta;
      if (score > alpha) alpha = score;
    }
    return alpha;
  }
}
