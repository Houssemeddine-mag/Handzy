import 'package:flutter/material.dart';
import '../models/hand_landmark.dart';

class GestureVisualizer extends StatelessWidget {
  final HandLandmarks landmarks;
  final double size;

  const GestureVisualizer({Key? key, required this.landmarks, this.size = 300})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(painter: HandLandmarkPainter(landmarks)),
    );
  }
}

class HandLandmarkPainter extends CustomPainter {
  final HandLandmarks landmarks;

  HandLandmarkPainter(this.landmarks);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw connections between landmarks
    final connections = [
      // Thumb
      [0, 1], [1, 2], [2, 3], [3, 4],
      // Index finger
      [0, 5], [5, 6], [6, 7], [7, 8],
      // Middle finger
      [0, 9], [9, 10], [10, 11], [11, 12],
      // Ring finger
      [0, 13], [13, 14], [14, 15], [15, 16],
      // Pinky
      [0, 17], [17, 18], [18, 19], [19, 20],
      // Palm
      [5, 9], [9, 13], [13, 17],
    ];

    for (final connection in connections) {
      final start = landmarks.landmarks[connection[0]];
      final end = landmarks.landmarks[connection[1]];

      canvas.drawLine(
        Offset(start.x * size.width, start.y * size.height),
        Offset(end.x * size.width, end.y * size.height),
        linePaint,
      );
    }

    // Draw landmarks
    for (final landmark in landmarks.landmarks) {
      final offset = Offset(landmark.x * size.width, landmark.y * size.height);

      // Highlight special landmarks
      if (landmark.id == LandmarkIndex.thumbTip) {
        paint.color = Colors.red;
        canvas.drawCircle(offset, 6, paint);
      } else if (landmark.id == LandmarkIndex.indexTip) {
        paint.color = Colors.green;
        canvas.drawCircle(offset, 6, paint);
      } else if (landmark.id == LandmarkIndex.wrist) {
        paint.color = Colors.purple;
        canvas.drawCircle(offset, 6, paint);
      } else {
        paint.color = Colors.blue;
        canvas.drawCircle(offset, 4, paint);
      }
    }

    // Draw legend
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final legends = [
      {'color': Colors.red, 'text': 'Thumb Tip'},
      {'color': Colors.green, 'text': 'Index Tip'},
      {'color': Colors.purple, 'text': 'Wrist'},
    ];

    double yOffset = 10;
    for (final legend in legends) {
      // Draw color circle
      paint.color = legend['color'] as Color;
      canvas.drawCircle(Offset(10, yOffset), 4, paint);

      // Draw text
      textPainter.text = TextSpan(
        text: ' ${legend['text']}',
        style: const TextStyle(color: Colors.black87, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(20, yOffset - 6));

      yOffset += 15;
    }
  }

  @override
  bool shouldRepaint(HandLandmarkPainter oldDelegate) {
    return true;
  }
}
