import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game.dart';
import 'piece_3d.dart';

class AnimatedBoard extends StatefulWidget {
  final Game game;
  final int? selected;
  final bool flipped, threeD, animations;
  final List<Move> legalMoves;
  final ValueChanged<int> onTap;
  const AnimatedBoard(
      {super.key,
      required this.game,
      required this.selected,
      required this.flipped,
      required this.threeD,
      required this.animations,
      required this.legalMoves,
      required this.onTap});
  @override
  State<AnimatedBoard> createState() => _AnimatedBoardState();
}

class _AnimatedBoardState extends State<AnimatedBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 480));
  Move? moving;
  Piece? captured;
  bool get animate =>
      widget.animations && !MediaQuery.disableAnimationsOf(context);
  @override
  void didUpdateWidget(covariant AnimatedBoard old) {
    super.didUpdateWidget(old);
    final move = widget.game.lastMove;
    if (widget.game != old.game || widget.game.ply != old.game.ply) {
      // Game is mutable during a move; the previous snapshot is kept separately.
      _transition(move);
    } else if (widget.game.ply != previousPly) {
      _transition(move);
    }
    if (old.flipped != widget.flipped ||
        old.threeD != widget.threeD ||
        !animate) {
      motion.stop();
      moving = null;
      captured = null;
    }
    previousPly = widget.game.ply;
    previousBoard = List.of(widget.game.board);
  }

  int previousPly = 0;
  List<Piece?> previousBoard = [];
  @override
  void initState() {
    super.initState();
    previousPly = widget.game.ply;
    previousBoard = List.of(widget.game.board);
  }

  void _transition(Move? move) {
    motion.stop();
    moving = null;
    captured = null;
    if (animate &&
        move != null &&
        widget.game.ply == previousPly + 1 &&
        previousBoard[move.from] != null &&
        widget.game.board[move.from] == null) {
      moving = move;
      captured = previousBoard[move.to];
      motion.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!animate) {
      motion.stop();
      moving = null;
      captured = null;
    }
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destinations = widget.legalMoves
        .where((m) => m.from == widget.selected)
        .map((m) => m.to)
        .toSet();
    final duration =
        animate ? const Duration(milliseconds: 240) : Duration.zero;
    final check = widget.game.inCheck(widget.game.turn);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.threeD ? 1 : 0),
      duration: duration,
      builder: (context, tilt, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .0012)
            ..rotateX(-.23 * tilt),
          child: DecoratedBox(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xff493522).withValues(alpha: .28),
                        blurRadius: 22,
                        offset: Offset(0, 16 + 8 * tilt))
                  ]),
              child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xff9b7447),
                            Color(0xff3d291d),
                            Color(0xff7c5634)
                          ]),
                      border: Border(
                          bottom: BorderSide(
                              color: const Color(0xff39271c),
                              width: 4 + 7 * tilt))),
                  child: child))),
      child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(builder: (context, constraints) {
            final s = constraints.maxWidth / 8;
            Offset location(int sq) {
              final index = widget.flipped ? 63 - sq : sq;
              return Offset(index % 8 * s, index ~/ 8 * s);
            }

            Widget piece(Piece p, int sq, {double lift = 0}) => Transform
                .translate(
                    offset: Offset(0, -lift),
                    child: widget.threeD
                        ? Piece3D(
                            piece: p, size: s, selected: widget.selected == sq)
                        : Center(
                            child: Text(p.symbol,
                                style: TextStyle(
                                    fontFamily: 'ChaktrangSymbols',
                                    fontSize: s * .76,
                                    height: 1.1,
                                    color: p.side == Side.white
                                        ? const Color(0xfffffbec)
                                        : const Color(0xff873f37),
                                    shadows: const [
                                      Shadow(
                                          color: Color(0xff3f4b37),
                                          blurRadius: 1,
                                          offset: Offset(0, 1))
                                    ]))));
            return AnimatedBuilder(
                animation: motion,
                builder: (context, _) {
                  final inFlight = moving != null && motion.isAnimating;
                  final t = Curves.easeInOutCubic.transform(motion.value);
                  return Stack(clipBehavior: Clip.none, children: [
                    for (var square = 0; square < 64; square++)
                      Positioned(
                          left: location(square).dx,
                          top: location(square).dy,
                          width: s,
                          height: s,
                          child: AnimatedContainer(
                              duration: duration,
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: widget.selected == square
                                          ? const [
                                              Color(0xffecd298),
                                              Color(0xffc39c58)
                                            ]
                                          : check &&
                                                  widget.game.board[square]
                                                          ?.kind ==
                                                      Kind.king &&
                                                  widget.game.board[square]
                                                          ?.side ==
                                                      widget.game.turn
                                              ? const [
                                                  Color(0xffd68a78),
                                                  Color(0xffb06050)
                                                ]
                                              : widget.game.lastMove
                                                              ?.from ==
                                                          square ||
                                                      widget.game.lastMove
                                                              ?.to ==
                                                          square
                                                  ? const [
                                                      Color(0xffd1c594),
                                                      Color(0xffb5a875)
                                                    ]
                                                  : ((square ~/ 8 +
                                                                  square % 8) %
                                                              2 ==
                                                          0)
                                                      ? const [
                                                          Color(0xffefe0bc),
                                                          Color(0xffdbc69b)
                                                        ]
                                                      : const [
                                                          Color(0xff88977c),
                                                          Color(0xff65765e)
                                                        ]),
                                  border: Border.all(
                                      color: const Color(0xff42331f)
                                          .withValues(alpha: .12),
                                      width: .5)),
                              child: Stack(children: [
                                if (square % 8 == (widget.flipped ? 7 : 0))
                                  Positioned(
                                      top: 3,
                                      left: 3,
                                      child: Text('${8 - square ~/ 8}',
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: const Color(0xff28382d)
                                                  .withValues(alpha: .7)))),
                                if (square ~/ 8 == (widget.flipped ? 0 : 7))
                                  Positioned(
                                      bottom: 2,
                                      right: 3,
                                      child: Text('abcdefgh'[square % 8],
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: const Color(0xff28382d)
                                                  .withValues(alpha: .7)))),
                                if (destinations.contains(square))
                                  Center(
                                      child: Container(
                                          width:
                                              widget.game.board[square] == null
                                                  ? s * .19
                                                  : s * .83,
                                          height:
                                              widget.game.board[square] == null
                                                  ? s * .19
                                                  : s * .83,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  widget.game.board[square] ==
                                                          null
                                                      ? const Color(0x77304b36)
                                                      : null,
                                              border: widget
                                                          .game.board[square] ==
                                                      null
                                                  ? null
                                                  : Border.all(
                                                      color:
                                                          const Color(0xffebbd6b),
                                                      width: 3)))),
                              ]))),
                    for (var square = 0; square < 64; square++)
                      if (widget.game.board[square] != null &&
                          !(inFlight && moving!.to == square))
                        Positioned(
                            key: ValueKey('piece-$square'),
                            left: location(square).dx,
                            top: location(square).dy,
                            width: s,
                            height: s,
                            child: IgnorePointer(
                                child: ExcludeSemantics(
                                    child: TweenAnimationBuilder<double>(
                                        tween: Tween(
                                            end: widget.selected == square
                                                ? 1
                                                : 0),
                                        duration: duration,
                                        builder: (context, value, _) =>
                                            Transform.scale(
                                                scale: 1 + .07 * value,
                                                child: piece(
                                                    widget.game.board[square]!,
                                                    square,
                                                    lift: s * .10 * value)))))),
                    if (inFlight && captured != null)
                      Positioned(
                          key: const ValueKey('captured-piece'),
                          left: location(moving!.to).dx,
                          top: location(moving!.to).dy,
                          width: s,
                          height: s,
                          child: IgnorePointer(
                              child: Opacity(
                                  opacity: (1 - motion.value * 1.7).clamp(0, 1),
                                  child: Transform.scale(
                                      scale: 1 - motion.value * .5,
                                      child: piece(captured!, moving!.to))))),
                    if (inFlight)
                      Positioned(
                          key: const ValueKey('moving-piece'),
                          left: Offset.lerp(location(moving!.from),
                                  location(moving!.to), t)!
                              .dx,
                          top: Offset.lerp(location(moving!.from),
                                  location(moving!.to), t)!
                              .dy,
                          width: s,
                          height: s,
                          child: IgnorePointer(
                              child: ExcludeSemantics(
                                  child: piece(widget.game.board[moving!.to]!,
                                      moving!.to,
                                      lift: math.sin(t * math.pi) * s * .32)))),
                    // Hit targets stay on the board plane, independent of visual lift.
                    for (var square = 0; square < 64; square++)
                      Positioned(
                          left: location(square).dx,
                          top: location(square).dy,
                          width: s,
                          height: s,
                          child: Semantics(
                              label:
                                  '${squareName(square)}, ${widget.game.board[square] == null ? 'empty' : '${widget.game.board[square]!.side.label} ${widget.game.board[square]!.name}'}${destinations.contains(square) ? ', legal destination' : ''}',
                              button: true,
                              selected: widget.selected == square,
                              child: Tooltip(
                                  message:
                                      '${squareName(square)}${widget.game.board[square] == null ? '' : ' · ${widget.game.board[square]!.side.label} ${widget.game.board[square]!.name}'}',
                                  child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                          onTap: () => inFlight
                                              ? null
                                              : widget.onTap(square))))))
                  ]);
                });
          })),
    );
  }
}
