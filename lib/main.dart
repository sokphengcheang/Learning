import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'game.dart';

const ink = Color(0xff263b32);
const cream = Color(0xfff5f2e9);
const gold = Color(0xffab793d);
void main() => runApp(const ChaktrangApp());
Move? calculateMove(Game g) => Computer().choose(g);

class ChaktrangApp extends StatelessWidget {
  const ChaktrangApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Ouk Chaktrang',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: cream,
            colorScheme: ColorScheme.fromSeed(seedColor: ink, primary: ink),
            textTheme: const TextTheme(bodyMedium: TextStyle(color: ink))),
        home: const GamePage(),
      );
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  Game game = Game();
  final history = <Game>[];
  final moves = <String>[];
  int? selected;
  bool againstComputer = true, thinking = false, flipped = false;
  int generation = 0;
  Timer? timer;
  List<Move> get legal => game.legalMoves();
  String? get result => game.outcome;
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void reset() {
    timer?.cancel();
    generation++;
    setState(() {
      game = Game();
      history.clear();
      moves.clear();
      selected = null;
      thinking = false;
    });
  }

  void commit(Move m) {
    final piece = game.board[m.from]!;
    history.add(game.copy());
    moves.add('${piece.name}  ${m.notation}');
    game.play(m);
    selected = null;
  }

  void tap(int square) {
    if (thinking ||
        result != null ||
        (againstComputer && game.turn == Side.black)) return;
    Move? chosen;
    for (final m in legal) {
      if (m.from == selected && m.to == square) {
        chosen = m;
        break;
      }
    }
    if (chosen != null) {
      setState(() => commit(chosen!));
      scheduleComputer();
    } else {
      setState(() => selected =
          game.board[square]?.side == game.turn && selected != square
              ? square
              : null);
    }
  }

  void scheduleComputer() {
    if (!againstComputer || game.turn != Side.black || result != null) return;
    setState(() => thinking = true);
    final ticket = generation;
    timer = Timer(const Duration(milliseconds: 350), () async {
      final move = await compute(calculateMove, game.copy());
      if (!mounted || generation != ticket) return;
      setState(() {
        if (move != null) commit(move);
        thinking = false;
      });
    });
  }

  void undo() {
    if (history.isEmpty) return;
    timer?.cancel();
    generation++;
    setState(() {
      game = history.removeLast();
      moves.removeLast();
      if (againstComputer && game.turn == Side.black && history.isNotEmpty) {
        game = history.removeLast();
        moves.removeLast();
      }
      selected = null;
      thinking = false;
    });
  }

  Future<void> newGame() async {
    if (moves.isNotEmpty) {
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
                  title: const Text('Start a new game?'),
                  content: const Text('Your current game will be cleared.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Keep playing')),
                    FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('New game'))
                  ]));
      if (confirmed != true || !mounted) return;
    }
    reset();
  }

  void rules() => showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
            title: const Text('The art of Ouk Chaktrang'),
            content: const SingleChildScrollView(
                child: Text(
                    'Ivory moves first. Win by checkmating the opposing king.\n\n'
                    'King · One square in any direction. No castling.\n\n'
                    'Boat · Any distance horizontally or vertically.\n\n'
                    'Horse · An L-shaped jump, as in international chess.\n\n'
                    'Elephant · One square diagonally, or one square straight forward.\n\n'
                    'Minister · One square diagonally.\n\n'
                    'Fish · One square forward; captures one square diagonally forward. No double step or en passant. '
                    'Promotes automatically to a minister on the sixth rank (Ivory: rank 6; Crimson: rank 3).\n\n'
                    'Stalemate, threefold repetition, and bare kings are draws in this app. '
                    'Cambodian counting activates automatically: board’s honor is 63 moves when a side has at most three pieces (king included). '
                    'For a bare king with no unpromoted fish left, pieces’ honor uses 7/15 for two/one boats, 21 for two elephants, '
                    '31 for two horses, 43 for one elephant, otherwise 63. Counting begins at the total pieces on the board. '
                    'The earlier board deadline still applies. Checkmate takes priority over a counting draw. '
                    'Ceremonial opening variants are not implemented.\n\n'
                    'Computer mode: you play Ivory. Local mode: share the device; use Flip board as needed.')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Let’s play'))
            ],
          ));
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 950;
    return Scaffold(
        body: SafeArea(
            child: SingleChildScrollView(
                child: Center(
                    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1240),
      child: Padding(
          padding: EdgeInsets.all(wide ? 40 : 20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: ink, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.castle_outlined,
                      color: cream, size: 25)),
              const SizedBox(width: 12),
              const Expanded(
                  child: Text('OKCHAKTRONG',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                          color: ink))),
              TextButton.icon(
                  onPressed: rules,
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: const Text('How to play'))
            ]),
            const SizedBox(height: 38),
            const Text('A timeless game.\nYour next move.',
                style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 42,
                    height: 1.12,
                    color: ink)),
            const SizedBox(height: 12),
            const Text('Ouk Chaktrang • Cambodian chess',
                style: TextStyle(fontSize: 15, color: Color(0xff747b6c))),
            const SizedBox(height: 30),
            if (wide)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 7, child: boardPanel()),
                const SizedBox(width: 32),
                Expanded(flex: 4, child: sidebar())
              ])
            else ...[boardPanel(), const SizedBox(height: 24), sidebar()],
            const SizedBox(height: 28),
            const Center(
                child: Text(
                    'ROOTED IN TRADITION. MADE FOR YOUR NEXT CHALLENGE.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.7,
                        color: Color(0xff7d8477)))),
          ])),
    )))));
  }

  Widget player(Side side) {
    final active = game.turn == side && result == null;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(children: [
          CircleAvatar(
              backgroundColor: side == Side.white
                  ? const Color(0xffe5d8bb)
                  : const Color(0xff8b3c35),
              child: Text(side == Side.white ? '♚' : '♟',
                  style: TextStyle(
                      fontFamily: 'ChaktrangSymbols',
                      fontSize: 25,
                      color: side == Side.white ? ink : cream))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(side == Side.white ? 'Ivory' : 'Crimson',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: ink)),
                Text(
                    side == Side.white
                        ? (againstComputer ? 'You' : 'Player one')
                        : (againstComputer ? 'Computer' : 'Player two'),
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xff7d8477)))
              ])),
          if (active)
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xffe3e8d9),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(thinking ? 'Thinking…' : 'To move',
                    style: const TextStyle(fontSize: 12, color: ink))),
        ]));
  }

  Widget boardPanel() => Column(children: [
        player(flipped ? Side.white : Side.black),
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: ink,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 25,
                      offset: Offset(0, 10))
                ]),
            child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(builder: (context, constraints) {
                  final size = constraints.maxWidth / 8;
                  final destinations = legal
                      .where((m) => m.from == selected)
                      .map((m) => m.to)
                      .toSet();
                  return Column(
                      children: List.generate(
                          8,
                          (row) => Expanded(
                              child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: List.generate(8, (col) {
                                    final square = flipped
                                        ? 63 - (row * 8 + col)
                                        : row * 8 + col;
                                    final p = game.board[square];
                                    final last =
                                        game.lastMove?.from == square ||
                                            game.lastMove?.to == square;
                                    final check = p?.kind == Kind.king &&
                                        p?.side == game.turn &&
                                        game.inCheck(game.turn);
                                    final bg = selected == square
                                        ? const Color(0xffcfac65)
                                        : check
                                            ? const Color(0xffce8370)
                                            : last
                                                ? const Color(0xffbec29b)
                                                : (row + col).isEven
                                                    ? const Color(0xffece5d3)
                                                    : const Color(0xffa8b3a0);
                                    return Expanded(
                                        child: Semantics(
                                            label:
                                                '${squareName(square)}, ${p == null ? 'empty' : '${p.side.label} ${p.name}'}${destinations.contains(square) ? ', legal destination' : ''}',
                                            button: true,
                                            selected: selected == square,
                                            child: Tooltip(
                                                message:
                                                    '${squareName(square)}${p == null ? '' : ' · ${p.side.label} ${p.name}'}',
                                                child: Material(
                                                    color: bg,
                                                    child: InkWell(
                                                        onTap: () =>
                                                            tap(square),
                                                        child: Stack(
                                                            alignment: Alignment
                                                                .center,
                                                            children: [
                                                              if (p != null)
                                                                ExcludeSemantics(
                                                                    child: Text(
                                                                        p
                                                                            .symbol,
                                                                        style: TextStyle(
                                                                            fontFamily:
                                                                                'ChaktrangSymbols',
                                                                            fontSize: size * .76,
                                                                            height: 1.1,
                                                                            color: p.side == Side.white ? const Color(0xfffffbec) : const Color(0xff873f37),
                                                                            shadows: const [
                                                                              Shadow(color: Color(0xff3f4b37), blurRadius: 1, offset: Offset(0, 1))
                                                                            ]))),
                                                              if (destinations
                                                                  .contains(
                                                                      square))
                                                                Container(
                                                                    width: p == null
                                                                        ? size *
                                                                            .23
                                                                        : size *
                                                                            .88,
                                                                    height: p ==
                                                                            null
                                                                        ? size *
                                                                            .23
                                                                        : size *
                                                                            .88,
                                                                    decoration: BoxDecoration(
                                                                        shape: BoxShape
                                                                            .circle,
                                                                        color: p ==
                                                                                null
                                                                            ? const Color(
                                                                                0x66304b36)
                                                                            : null,
                                                                        border: p ==
                                                                                null
                                                                            ? null
                                                                            : Border.all(
                                                                                color: ink.withValues(alpha: .5),
                                                                                width: 3))),
                                                              if (col == 0)
                                                                Positioned(
                                                                    top: 3,
                                                                    left: 4,
                                                                    child: Text(
                                                                        '${8 - square ~/ 8}',
                                                                        style: const TextStyle(
                                                                            fontSize:
                                                                                9,
                                                                            color:
                                                                                ink))),
                                                              if (row == 7)
                                                                Positioned(
                                                                    bottom: 2,
                                                                    right: 4,
                                                                    child: Text(
                                                                        'abcdefgh'[
                                                                            square %
                                                                                8],
                                                                        style: const TextStyle(
                                                                            fontSize:
                                                                                9,
                                                                            color:
                                                                                ink))),
                                                            ]))))));
                                  })))));
                }))),
        player(flipped ? Side.black : Side.white)
      ]);
  Widget sidebar() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .7),
                border: Border.all(color: const Color(0xffe1e2d7)),
                borderRadius: BorderRadius.circular(16)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('THE MATCH',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: gold)),
                  const SizedBox(height: 18),
                  SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                            value: true,
                            label: Text('Computer'),
                            icon: Icon(Icons.smart_toy_outlined, size: 17)),
                        ButtonSegment(
                            value: false,
                            label: Text('Local'),
                            icon: Icon(Icons.people_outline, size: 17))
                      ],
                      selected: {
                        againstComputer
                      },
                      onSelectionChanged: (v) async {
                        if (v.first == againstComputer) return;
                        if (moves.isNotEmpty) {
                          final ok = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                      title: const Text('Switch game mode?'),
                                      content: const Text(
                                          'This starts a fresh game.'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(c, false),
                                            child: const Text('Cancel')),
                                        FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(c, true),
                                            child: const Text('Switch'))
                                      ]));
                          if (ok != true || !mounted) return;
                        }
                        againstComputer = v.first;
                        reset();
                      }),
                  const SizedBox(height: 24),
                  Text(
                      result ??
                          (thinking
                              ? 'A moment of strategy…'
                              : game.inCheck(game.turn)
                                  ? '${game.turn.label} is in check'
                                  : '${game.turn.label} to move'),
                      style: const TextStyle(
                          fontFamily: 'serif', fontSize: 25, color: ink)),
                  const SizedBox(height: 8),
                  Text(
                      result != null
                          ? 'A good game. Ready for another?'
                          : thinking
                              ? 'The computer is considering its reply.'
                              : selected == null
                                  ? 'Select a piece to see its legal moves.'
                                  : 'Choose a highlighted square to move.',
                      style: const TextStyle(
                          color: Color(0xff747b6c), height: 1.5)),
                  if (game.counting != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                        liveRegion: true,
                        child: Text(game.counting!.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, color: gold))),
                    const SizedBox(height: 4),
                    const Text('Automatic Cambodian endgame count',
                        style: TextStyle(fontSize: 12)),
                  ],
                  const SizedBox(height: 22),
                  FilledButton.icon(
                      onPressed: newGame,
                      icon: const Icon(Icons.add, size: 19),
                      label: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('New game'))),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: TextButton.icon(
                            onPressed: history.isEmpty ? null : undo,
                            icon: const Icon(Icons.undo, size: 17),
                            label: const Text('Undo'))),
                    Expanded(
                        child: TextButton.icon(
                            onPressed: () => setState(() => flipped = !flipped),
                            icon: const Icon(Icons.flip_camera_android_outlined,
                                size: 17),
                            label: const Text('Flip board')))
                  ]),
                ])),
        const SizedBox(height: 24),
        Row(children: [
          const Text('MOVE JOURNAL',
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: ink)),
          const Spacer(),
          Text('${moves.length} plies',
              style: const TextStyle(fontSize: 12, color: Color(0xff7d8477)))
        ]),
        const SizedBox(height: 14),
        Container(
            height: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffdddeda)),
                borderRadius: BorderRadius.circular(12)),
            child: moves.isEmpty
                ? const Center(
                    child: Text('Every game begins\nwith a possibility.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 19,
                            height: 1.5,
                            color: Color(0xff89907e))))
                : ListView.builder(
                    reverse: true,
                    itemCount: (moves.length / 2).ceil(),
                    itemBuilder: (c, index) {
                      final i = ((moves.length / 2).ceil() - 1 - index) * 2;
                      return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(children: [
                            SizedBox(
                                width: 30,
                                child: Text('${i ~/ 2 + 1}.',
                                    style: const TextStyle(color: gold))),
                            Expanded(
                                child: Text(moves[i],
                                    style: const TextStyle(fontSize: 12))),
                            Expanded(
                                child: Text(
                                    i + 1 < moves.length ? moves[i + 1] : '…',
                                    style: const TextStyle(fontSize: 12)))
                          ]));
                    })),
        const SizedBox(height: 18),
        const Text(
            'A thoughtful pace. An ancient tradition.\nTake your time — there’s no clock.',
            style:
                TextStyle(fontSize: 12, height: 1.7, color: Color(0xff7d8477))),
      ]);
}
