import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game.dart';

/// A turned solid of revolution, projected and lit face by face on the canvas.
/// No external renderer or model downloads are needed.
class Piece3D extends StatelessWidget {
  final Piece piece;
  final double size;
  final bool selected;
  const Piece3D(
      {super.key,
      required this.piece,
      required this.size,
      this.selected = false});
  @override
  Widget build(BuildContext context) => RepaintBoundary(
      child: CustomPaint(
          size: Size.square(size), painter: _PiecePainter(piece, selected)));
}

class _PiecePainter extends CustomPainter {
  final Piece piece;
  final bool selected;
  _PiecePainter(this.piece, this.selected);
  static const profiles = <Kind, List<Offset>>{
    Kind.pawn: [
      Offset(.23, 0),
      Offset(.27, .04),
      Offset(.27, .08),
      Offset(.20, .12),
      Offset(.15, .22),
      Offset(.11, .33),
      Offset(.15, .38),
      Offset(.16, .43),
      Offset(.13, .49),
      Offset(0, .53)
    ],
    Kind.boat: [
      Offset(.27, 0),
      Offset(.30, .04),
      Offset(.30, .09),
      Offset(.23, .13),
      Offset(.18, .18),
      Offset(.18, .48),
      Offset(.25, .52),
      Offset(.25, .61),
      Offset(.19, .63)
    ],
    Kind.horse: [
      Offset(.25, 0),
      Offset(.28, .04),
      Offset(.28, .09),
      Offset(.21, .14),
      Offset(.15, .23),
      Offset(.12, .30),
      Offset(0, .32)
    ],
    Kind.elephant: [
      Offset(.25, 0),
      Offset(.28, .04),
      Offset(.28, .09),
      Offset(.21, .14),
      Offset(.14, .32),
      Offset(.19, .37),
      Offset(.16, .43),
      Offset(.19, .49),
      Offset(.12, .57),
      Offset(0, .69)
    ],
    Kind.minister: [
      Offset(.25, 0),
      Offset(.28, .04),
      Offset(.28, .09),
      Offset(.21, .14),
      Offset(.12, .37),
      Offset(.18, .42),
      Offset(.18, .46),
      Offset(.10, .50),
      Offset(.14, .56),
      Offset(.10, .62),
      Offset(0, .65)
    ],
    Kind.king: [
      Offset(.27, 0),
      Offset(.30, .04),
      Offset(.30, .09),
      Offset(.22, .14),
      Offset(.13, .42),
      Offset(.20, .47),
      Offset(.20, .51),
      Offset(.12, .54),
      Offset(.16, .61),
      Offset(.11, .69),
      Offset(.06, .74),
      Offset(0, .81)
    ],
  };
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final center = Offset(s * .5, s * .87);
    final base = piece.side == Side.white
        ? const Color(0xffead8ad)
        : const Color(0xffa94e39);
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: selected ? .16 : .28)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .04);
    canvas.drawOval(
        Rect.fromCenter(
            center: center + Offset(s * .06, s * .025),
            width: s * .64,
            height: s * .19),
        shadow);
    Offset project(double r, double h, double a) =>
        center + Offset(r * math.cos(a) * s, (r * math.sin(a) * .33 - h) * s);
    final faces = <({Path path, double depth, double light})>[];
    final profile = profiles[piece.kind]!;
    const segments = 24;
    for (var i = 0; i < profile.length - 1; i++) {
      final low = profile[i], high = profile[i + 1];
      for (var j = 0; j < segments; j++) {
        final a = j * 2 * math.pi / segments,
            b = (j + 1) * 2 * math.pi / segments;
        final mid = (a + b) / 2;
        final slope = low.dx - high.dx;
        final height = high.dy - low.dy;
        final norm = math.sqrt(height * height + slope * slope);
        final light = (.65 +
                (-math.cos(mid) * .40 - math.sin(mid) * .20) * height / norm +
                slope / norm * .34)
            .clamp(.22, 1.25);
        final path = Path()
          ..moveTo(
              project(low.dx, low.dy, a).dx, project(low.dx, low.dy, a).dy);
        for (final v in [
          project(low.dx, low.dy, b),
          project(high.dx, high.dy, b),
          project(high.dx, high.dy, a)
        ]) {
          path.lineTo(v.dx, v.dy);
        }
        path.close();
        faces.add((
          path: path,
          depth:
              math.sin(mid) * (low.dx + high.dx) / 2 + (low.dy + high.dy) * .12,
          light: light
        ));
      }
    }
    faces.sort((a, b) => a.depth.compareTo(b.depth));
    for (final face in faces) {
      final color = Color.fromARGB(
          255,
          (base.r * 255 * face.light).round().clamp(0, 255),
          (base.g * 255 * face.light).round().clamp(0, 255),
          (base.b * 255 * face.light).round().clamp(0, 255));
      canvas.drawPath(face.path, Paint()..color = color);
      // A matching hairline prevents gaps between adjacent projected faces.
      canvas.drawPath(
          face.path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = .35);
    }
    if (piece.kind == Kind.horse) {
      final path = Path()
        ..moveTo(.36, .66)
        ..lineTo(.39, .43)
        ..lineTo(.35, .29)
        ..lineTo(.48, .15)
        ..lineTo(.48, .08)
        ..lineTo(.56, .14)
        ..lineTo(.65, .14)
        ..lineTo(.73, .32)
        ..lineTo(.68, .39)
        ..lineTo(.57, .34)
        ..lineTo(.57, .49)
        ..lineTo(.68, .66)
        ..close();
      final matrix = Matrix4.diagonal3Values(s, s, 1);
      final head = path.transform(matrix.storage);
      canvas.drawPath(head.shift(Offset(s * .035, s * .015)),
          Paint()..color = Color.lerp(base, Colors.black, .55)!);
      canvas.drawPath(
          head,
          Paint()
            ..shader = LinearGradient(colors: [
              Color.lerp(base, Colors.white, .3)!,
              base,
              Color.lerp(base, Colors.black, .35)!
            ]).createShader(Rect.fromLTWH(s * .35, s * .08, s * .38, s * .58)));
      canvas.drawCircle(Offset(s * .61, s * .235), s * .018,
          Paint()..color = const Color(0xff30251c));
    }
    if (piece.kind == Kind.boat) {
      for (var i = 0; i < 5; i++) {
        final x = .27 + i * .105;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(s * x, s * .20, s * .065, s * .10),
                Radius.circular(s * .01)),
            Paint()..color = Color.lerp(base, Colors.white, .15)!);
      }
    }
    if (selected) {
      canvas.drawOval(
          Rect.fromCenter(
              center: center + Offset(0, s * .02),
              width: s * .68,
              height: s * .20),
          Paint()
            ..color = const Color(0xffdcb46c)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _PiecePainter old) =>
      old.piece.kind != piece.kind ||
      old.piece.side != piece.side ||
      old.selected != selected;
}
