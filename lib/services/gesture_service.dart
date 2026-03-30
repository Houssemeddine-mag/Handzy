import 'dart:async';
import 'package:flutter/material.dart';
import '../models/hand_landmark.dart';
import '../models/gesture.dart';
import '../utils/gesture_interpreter.dart';
import 'mediapipe_service.dart';
import 'accessibility_service.dart';

/// Main service that coordinates gesture detection and execution
class GestureService extends ChangeNotifier {
  final MediaPipeService _mediaPipeService = MediaPipeService();
  AccessibilityService? _accessibilityService;
  late GestureInterpreter _gestureInterpreter;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  HandLandmarks? _currentLandmarks;
  HandLandmarks? get currentLandmarks => _currentLandmarks;

  DetectedGesture? _currentGesture;
  DetectedGesture? get currentGesture => _currentGesture;

  StreamSubscription<HandLandmarks>? _landmarksSubscription;

  int _frameCount = 0;
  DateTime _lastFrameTime = DateTime.now();
  double _currentFps = 0;
  double get currentFps => _currentFps;

  GestureConfig _config = const GestureConfig();
  GestureConfig get config => _config;

  DateTime _lastClickTime = DateTime.now();
  DateTime _lastScrollTime = DateTime.now();
  static const Duration _clickDebounceTime = Duration(milliseconds: 300);
  static const Duration _scrollDebounceTime = Duration(milliseconds: 500);

  GestureService() {
    _gestureInterpreter = GestureInterpreter(config: _config);
  }

  void setAccessibilityService(AccessibilityService service) {
    _accessibilityService = service;
  }

  void updateConfig(GestureConfig newConfig) {
    _config = newConfig;
    _gestureInterpreter = GestureInterpreter(config: _config);
    notifyListeners();
  }

  Future<bool> initialize() async {
    final mediaPipeInit = await _mediaPipeService.initialize();
    if (_accessibilityService == null) {
      debugPrint('Warning: AccessibilityService not set');
      return mediaPipeInit;
    }
    final accessibilityCheck =
        await _accessibilityService!.checkServiceEnabled();
    return mediaPipeInit && accessibilityCheck;
  }

  Future<bool> start() async {
    if (_isRunning) return true;

    if (_accessibilityService == null) {
      debugPrint('AccessibilityService not initialized');
      return false;
    }

    final hasCameraPermission = await _mediaPipeService.hasCameraPermission();
    if (!hasCameraPermission) {
      final granted = await _mediaPipeService.requestCameraPermission();
      if (!granted) {
        debugPrint('Camera permission not granted');
        return false;
      }
    }

    final hasOverlayPermission =
        await _accessibilityService!.hasOverlayPermission();
    if (!hasOverlayPermission) {
      await _accessibilityService!.requestOverlayPermission();
      return false;
    }

    final started = await _mediaPipeService.startTracking();
    if (!started) {
      debugPrint('Failed to start MediaPipe tracking');
      return false;
    }

    await _accessibilityService!.showCursorOverlay();

    _landmarksSubscription = _mediaPipeService.getLandmarksStream().listen(
      _onLandmarksReceived,
      onError: (error) {
        debugPrint('Landmarks stream error: $error');
        stop();
      },
    );

    _isRunning = true;
    _gestureInterpreter.reset();
    notifyListeners();
    return true;
  }

  Future<void> stop() async {
    if (!_isRunning) return;

    await _landmarksSubscription?.cancel();
    _landmarksSubscription = null;

    await _mediaPipeService.stopTracking();
    if (_accessibilityService != null) {
      await _accessibilityService!.hideCursorOverlay();
    }

    _isRunning = false;
    _currentLandmarks = null;
    _currentGesture = null;
    notifyListeners();
  }

  void _onLandmarksReceived(HandLandmarks landmarks) {
    _currentLandmarks = landmarks;

    _frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(_lastFrameTime);
    if (elapsed.inMilliseconds >= 1000) {
      _currentFps = _frameCount / (elapsed.inMilliseconds / 1000);
      _frameCount = 0;
      _lastFrameTime = now;
    }

    final gesture = _gestureInterpreter.interpretGesture(landmarks);
    _currentGesture = gesture;

    _executeGesture(gesture);

    notifyListeners();
  }

  Future<void> _executeGesture(DetectedGesture gesture) async {
    if (_accessibilityService == null) return;

    switch (gesture.type) {
      case GestureType.cursor:
        if (gesture.x != null && gesture.y != null) {
          await _accessibilityService!.updateCursorPosition(
            gesture.x!,
            gesture.y!,
          );
        }
        break;

      case GestureType.click:
        final now = DateTime.now();
        if (now.difference(_lastClickTime) > _clickDebounceTime) {
          if (gesture.x != null && gesture.y != null) {
            await _accessibilityService!.performClick(
              gesture.x!,
              gesture.y!,
            );
            _lastClickTime = now;
            debugPrint('Click performed at (${gesture.x}, ${gesture.y})');
          }
        }
        break;

      case GestureType.scrollUp:
        final now = DateTime.now();
        if (now.difference(_lastScrollTime) > _scrollDebounceTime) {
          await _accessibilityService!.performScroll('up');
          debugPrint('Scroll up performed');
          _lastScrollTime = now;
        }
        break;

      case GestureType.scrollDown:
        final now = DateTime.now();
        if (now.difference(_lastScrollTime) > _scrollDebounceTime) {
          await _accessibilityService!.performScroll('down');
          debugPrint('Scroll down performed');
          _lastScrollTime = now;
        }
        break;

      case GestureType.scrollLeft:
        final now = DateTime.now();
        if (now.difference(_lastScrollTime) > _scrollDebounceTime) {
          await _accessibilityService!.performScroll('left');
          debugPrint('Scroll left performed');
          _lastScrollTime = now;
        }
        break;

      case GestureType.scrollRight:
        final now = DateTime.now();
        if (now.difference(_lastScrollTime) > _scrollDebounceTime) {
          await _accessibilityService!.performScroll('right');
          debugPrint('Scroll right performed');
          _lastScrollTime = now;
        }
        break;

      case GestureType.back:
        await _accessibilityService!.performGlobalAction('BACK');
        debugPrint('Back action performed');
        break;

      case GestureType.recentApps:
        await _accessibilityService!.performGlobalAction('RECENTS');
        debugPrint('Recent Apps action performed');
        break;

      case GestureType.none:
        break;
    }
  }

  @override
  void dispose() {
    stop();
    _mediaPipeService.dispose();
    super.dispose();
  }
}
