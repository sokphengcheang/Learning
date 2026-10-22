# Okchaktrong

A Flutter implementation of **Ouk Chaktrang**, Cambodian chess. Play against a computer or share a device with a friend.

## Run

Install the stable Flutter SDK and put its `bin` directory on `PATH`, then run from this directory:

```sh
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

The checked-in web target runs in a modern browser. No backend, API key, or account is required. Flutter's SDK and artifacts require `storage.googleapis.com`; packages require `pub.dev`. To generate native platform runners later, use `flutter create --platforms=android,ios .` in a separate development task with the platform's toolchain installed. Android/iOS runners are not included yet.

```sh
dart format lib test
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
```

## Play

Ivory moves first. In computer mode you play Ivory; the computer plays Crimson using a two-ply alpha-beta search with material and positional evaluation. In local mode both players use the same board. Select a piece, then a marked destination. Undo reverses a full human/computer exchange when available, or one move in local mode. Flip changes the viewing perspective. Changing modes or starting a new game confirms before clearing an active game.

## Rules and scope

The initial fish stand on ranks 3 and 6. Ivory's king starts on e1, Crimson's on d8. Boats move orthogonally; horses jump; elephants move one square diagonally or straight forward; ministers move one square diagonally. Fish move one square forward and capture diagonally, promoting to ministers on reaching the opposing fish's original rank. Moves cannot expose your king. There is no castling, double fish move, or en passant.

The app detects checkmate, stalemate, threefold repetition, and bare kings. Cambodian endgame counting is automatic (details below). **Ceremonial opening variants are not implemented.** This is a casual-play first version, not a tournament rules adjudicator. Games are kept in memory and reset on reload; online multiplayer and saved games are not included.

## Checks

The test suite covers initial placement, movement, pins, promotion for both sides, king safety, checkmate/stalemate, repetition, legal AI replies, and local UI interaction. See the onboarding report for which checks were actually executed in this environment.

## Cambodian endgame counting

Counting activates automatically rather than requiring a spoken claim. Board’s honor starts when the side to move has two or three pieces, including its king, and the opponent is not bare. Fish may still be present. The limit is 63.

When a side is a bare king and no unpromoted fish remain anywhere, pieces’ honor uses the opponent’s material, in this priority order:

| Attacking material | Limit |
| --- | ---: |
| Two boats | 7 |
| One boat | 15 |
| Two elephants | 21 |
| Two horses | 31 |
| One elephant | 43 |
| Otherwise | 63 |

Pieces’ honor starts at the total number of pieces on the board, including both kings. The engine tracks half-moves so a last-fish capture and promotion start on the correct turn. An earlier board deadline continues to apply after a transition to pieces’ honor. Captures/promotions that begin a bare-king ending establish its material count. A bare king capturing another attacking piece does not restart an already active count. A draw is declared when the counter exceeds the permitted limit; checkmate takes precedence. Undo restores the counters along with the board. The computer evaluates counting draws too.

Reference: [Fairy-Stockfish Cambodian count limits and transitions](https://github.com/fairy-stockfish/Fairy-Stockfish/blob/9f778da667f6e07dae1e85d3e2ea204fc6dee94d/src/position.cpp), with the earlier-board-deadline handling in [position.h](https://github.com/fairy-stockfish/Fairy-Stockfish/blob/9f778da667f6e07dae1e85d3e2ea204fc6dee94d/src/position.h). This app follows that digital rules convention; local tournament claim procedures may differ.

Piece glyphs use the bundled Noto Sans Symbols 2 font, licensed under the SIL Open Font License in `assets/fonts/OFL.txt`. No external font request is needed.
