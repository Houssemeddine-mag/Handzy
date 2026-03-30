import 'dart:math';
import '../models/hand_landmark.dart';
import '../models/gesture.dart';

/// Interprets hand landmarks and detects gestures
class GestureInterpreter {
  final GestureConfig config;
  final List<HandLandmarks> _landmarkHistory = [];
  final int _maxHistorySize = 10;

  bool _wasThumbMiddlePinching = false;
  DateTime? _thumbMiddlePinchStartTime;
  bool _recentAppsTriggered = false;

  GestureInterpreter({GestureConfig? config})
      : config = config ?? const GestureConfig();

  /// Process hand landmarks and detect gesture
  DetectedGesture interpretGesture(HandLandmarks landmarks) {
    // Add to history for smoothing and velocity calculation
    _landmarkHistory.add(landmarks);
    if (_landmarkHistory.length > _maxHistorySize) {
      _landmarkHistory.removeAt(0);
    }

    // Default: cursor movement
    final smoothedPosition = _getSmoothCursorPosition(landmarks);
    // Check for back and recent apps (thumb + middle pinch)
    if (_isThumbMiddlePinch(landmarks)) {
      if (!_wasThumbMiddlePinching) {
        _wasThumbMiddlePinching = true;
        _thumbMiddlePinchStartTime = DateTime.now();
        _recentAppsTriggered = false;
      } else {
        if (!_recentAppsTriggered && _thumbMiddlePinchStartTime != null) {
          if (DateTime.now().difference(_thumbMiddlePinchStartTime!) >=
              const Duration(seconds: 3)) {
            _recentAppsTriggered = true;
            return DetectedGesture(
                type: GestureType.recentApps, confidence: 1.0);
          }
        }
      }
      return DetectedGesture(type: GestureType.none, confidence: 1.0);
    } else {
      if (_wasThumbMiddlePinching) {
        _wasThumbMiddlePinching = false;
        if (!_recentAppsTriggered && _thumbMiddlePinchStartTime != null) {
          if (DateTime.now().difference(_thumbMiddlePinchStartTime!) >
              const Duration(milliseconds: 100)) {
            return DetectedGesture(type: GestureType.back, confidence: 1.0);
          }
        }
      }
    }
    // Check for click gesture (pinch)
    if (_isClickGesture(landmarks)) {
      return DetectedGesture(
        type: GestureType.click,
        x: smoothedPosition['x'],
        y: smoothedPosition['y'],
        confidence: 0.9,
      );
    }

    // Check for scroll gestures (fist + movement)
    final scrollType = _detectScroll(landmarks);
    if (scrollType != GestureType.none) {
      return DetectedGesture(
        type: scrollType,
        confidence: 0.85,
      );
    }

    // Check for horizontal scroll gestures (fist + movement)
    final hScrollType = _detectHorizontalScroll(landmarks);
    if (hScrollType != GestureType.none) {
      return DetectedGesture(
        type: hScrollType,
        confidence: 0.85,
      );
    }

    return DetectedGesture(
      type: GestureType.cursor,
      x: smoothedPosition['x'],
      y: smoothedPosition['y'],
      confidence: 1.0,
    );
  }

  /// Check if thumb tip and index tip are close enough for a click
  bool _isClickGesture(HandLandmarks landmarks) {
    final thumbTip = landmarks.thumbTip;
    final indexTip = landmarks.indexTip;

    final distance = _euclideanDistance(
      thumbTip.x,
      thumbTip.y,
      indexTip.x,
      indexTip.y,
    );

    // Using a more forgiving threshold 0.08 instead of config.clickThreshold (0.05)
    return distance < 0.08;
  }

  /// Detect scroll gestures (fist + Y-axis movement)
  GestureType _detectScroll(HandLandmarks landmarks) {
    if (!_isIndexMiddlePinch(landmarks)) {
      return GestureType.none;
    }

    if (_landmarkHistory.length < 3) {
      return GestureType.none;
    }

    // Calculate Y-axis velocity of wrist
    final currentWrist = landmarks.wrist;
    final previousWrist = _landmarkHistory[_landmarkHistory.length - 3].wrist;
    final yVelocity = currentWrist.y - previousWrist.y;

    if (yVelocity.abs() < config.scrollVelocityThreshold * 1.5) {
      return GestureType.none;
    }

    // Negative Y velocity = moving up on screen = scroll up
    return yVelocity < 0 ? GestureType.scrollUp : GestureType.scrollDown;
  }

  /// Detect horizontal scroll gestures (fist + X-axis movement)
  GestureType _detectHorizontalScroll(HandLandmarks landmarks) {
    if (!_isFist(landmarks)) {
      return GestureType.none;
    }

    if (_landmarkHistory.length < 3) {
      return GestureType.none;
    }

    final currentWrist = landmarks.wrist;
    final previousWrist = _landmarkHistory[_landmarkHistory.length - 3].wrist;
    final xVelocity = currentWrist.x - previousWrist.x;

    if (xVelocity.abs() < config.scrollVelocityThreshold * 1.5) {
      return GestureType.none;
    }

    // Negative X velocity = moving left on screen
    return xVelocity < 0 ? GestureType.scrollLeft : GestureType.scrollRight;
  }

  /// Check if Thumb Tip is touching Middle Tip
  bool _isThumbMiddlePinch(HandLandmarks landmarks) {
    final thumbTip = landmarks.thumbTip;
    final middleTip = landmarks.middleTip;

    final distance = _euclideanDistance(
      thumbTip.x,
      thumbTip.y,
      middleTip.x,
      middleTip.y,
    );

    return distance < 0.08;
  }

  /// Check if Index Tip is touching Middle Tip (Scroll Mode)
  bool _isIndexMiddlePinch(HandLandmarks landmarks) {
    final indexTip = landmarks.indexTip;
    final middleTip = landmarks.middleTip;

    final distance = _euclideanDistance(
      indexTip.x,
      indexTip.y,
      middleTip.x,
      middleTip.y,
    );

    return distance < 0.08;
  }

  /// Check if all fingers are closed (fist detection)
  bool _isFist(HandLandmarks landmarks) {
    final wrist = landmarks.wrist;

    // Check if a finger is folded by seeing if its Tip is closer to the Wrist than its PIP joint
    bool isFingerFolded(int tipIndex, int pipIndex) {
      final tip = landmarks.landmarks[tipIndex];
      final pip = landmarks.landmarks[pipIndex];

      final tipDist = _euclideanDistance(wrist.x, wrist.y, tip.x, tip.y);
      final pipDist = _euclideanDistance(wrist.x, wrist.y, pip.x, pip.y);

      return tipDist < pipDist;
    }

    // A fist is when the 4 main fingers are folded
    return isFingerFolded(LandmarkIndex.indexTip, LandmarkIndex.indexPIP) &&
        isFingerFolded(LandmarkIndex.middleTip, LandmarkIndex.middlePIP) &&
        isFingerFolded(LandmarkIndex.ringTip, LandmarkIndex.ringPIP) &&
        isFingerFolded(LandmarkIndex.pinkyTip, LandmarkIndex.pinkyPIP);
  }

  /// Get smoothed cursor position using moving average
  Map<String, double> _getSmoothCursorPosition(HandLandmarks landmarks) {
    if (_landmarkHistory.isEmpty) return {'x': 0.5, 'y': 0.5};

    // Moving average over last N frames
    double sumX = 0;
    double sumY = 0;
    final framesToAverage =
        min(config.smoothingFrames, _landmarkHistory.length);

    for (int i = _landmarkHistory.length - framesToAverage;
        i < _landmarkHistory.length;
        i++) {
      final tip = _landmarkHistory[i].indexTip;
      sumX += tip.x;
      sumY += tip.y;
    }

    double rawX = sumX / framesToAverage;
    double rawY = sumY / framesToAverage;

    // Normalizing so that smaller central camera area covers the full screen
    double mapCoordinate(double val, double minLimit, double maxLimit) {
      double mapped = (val - minLimit) / (maxLimit - minLimit);
      return mapped.clamp(0.0, 1.0);
    }

    // By setting minLimit significantly above 0.0, we make it easy to reach the TOP of the screen (y=0)
    // By setting maxLimit below 1.0, we make it easy to reach the BOTTOM of the screen (y=1)
    return {
      'x': mapCoordinate(rawX, 0.20, 0.80),
      'y': mapCoordinate(rawY, 0.20, 0.85),
    };
  }

  /// Calculate Euclidean distance between two points
  double _euclideanDistance(double x1, double y1, double x2, double y2) {
    return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
  }

  /// Reset history (useful when restarting detection)
  void reset() {
    _landmarkHistory.clear();
  }
}
