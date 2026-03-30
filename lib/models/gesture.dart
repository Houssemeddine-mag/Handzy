/// Types of gestures that can be detected
enum GestureType {
  none,
  cursor,
  click,
  scrollUp,
  scrollDown,
  scrollLeft,
  scrollRight,
  back,
  recentApps
}

/// Represents a detected gesture with its properties
class DetectedGesture {
  final GestureType type;
  final double? x;
  final double? y;
  final double confidence;
  final DateTime timestamp;

  DetectedGesture({
    required this.type,
    this.x,
    this.y,
    this.confidence = 1.0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'DetectedGesture(type: $type, x: $x, y: $y, confidence: $confidence)';
}

/// Configuration for gesture detection thresholds
class GestureConfig {
  final double clickThreshold;
  final double scrollVelocityThreshold;
  final double fistThreshold;
  final int smoothingFrames;
  final double cursorSensitivity;

  const GestureConfig({
    this.clickThreshold = 0.05,
    this.scrollVelocityThreshold =
        0.05, // Lowered from 0.1 to detect scroll more easily
    this.fistThreshold = 0.15,
    this.smoothingFrames = 5,
    this.cursorSensitivity = 1.0,
  });

  GestureConfig copyWith({
    double? clickThreshold,
    double? scrollVelocityThreshold,
    double? fistThreshold,
    int? smoothingFrames,
    double? cursorSensitivity,
  }) {
    return GestureConfig(
      clickThreshold: clickThreshold ?? this.clickThreshold,
      scrollVelocityThreshold:
          scrollVelocityThreshold ?? this.scrollVelocityThreshold,
      fistThreshold: fistThreshold ?? this.fistThreshold,
      smoothingFrames: smoothingFrames ?? this.smoothingFrames,
      cursorSensitivity: cursorSensitivity ?? this.cursorSensitivity,
    );
  }
}
