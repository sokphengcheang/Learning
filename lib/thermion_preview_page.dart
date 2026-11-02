import 'package:flutter/material.dart';
import 'package:thermion_flutter/thermion_flutter.dart' hide Transform;
import 'package:vector_math/vector_math_64.dart';

/// Isolated renderer smoke test. The chess UI keeps using AnimatedBoard until
/// this scene is verified on Web, Android, and iOS.
class ThermionPreviewPage extends StatelessWidget {
  const ThermionPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D engine preview'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ViewerWidget(
              assetPath: 'assets/thermion/cube.glb',
              transformToUnitCube: true,
              initialCameraPosition: Vector3(0, 0, 6),
              background: const Color(0xff171a20),
              manipulatorType: ManipulatorType.ORBIT,
              initial: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Thermion renderer test. Drag to orbit and pinch or scroll '
                  'to zoom. The sample cube is temporary; the Cambodian '
                  'chessboard model will replace it after platform validation.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
