import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/hand_landmark.dart';

/// Service to communicate with native MediaPipe implementation
class MediaPipeService {
  static const MethodChannel _channel =
      MethodChannel('com.fingertip.app/mediapipe');

  static const EventChannel _landmarksChannel =
      EventChannel('com.fingertip.app/landmarks');

  Stream<HandLandmarks>? _landmarksStream;

  /// Initialize MediaPipe hand tracking
  Future<bool> initialize() async {
    try {
      final result = await _channel.invokeMethod('initialize');
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Failed to initialize MediaPipe: ${e.message}');
      return false;
    }
  }

  /// Start hand tracking
  Future<bool> startTracking() async {
    try {
      final result = await _channel.invokeMethod('startTracking');
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Failed to start tracking: ${e.message}');
      return false;
    }
  }

  /// Stop hand tracking
  Future<bool> stopTracking() async {
    try {
      final result = await _channel.invokeMethod('stopTracking');
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Failed to stop tracking: ${e.message}');
      return false;
    }
  }

  /// Get stream of hand landmarks
  Stream<HandLandmarks> getLandmarksStream() {
    _landmarksStream ??= _landmarksChannel
        .receiveBroadcastStream()
        .map((event) {
          if (event is Map) {
            final landmarks = event['landmarks'] as List?;
            if (landmarks != null && landmarks.isNotEmpty) {
              return HandLandmarks.fromList(landmarks);
            }
          }
          throw Exception('Invalid landmarks data');
        })
        .handleError((error) {
          debugPrint('Landmarks stream error: $error');
        });

    return _landmarksStream!;
  }

  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    try {
      final result = await _channel.invokeMethod('hasCameraPermission');
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Failed to check camera permission: ${e.message}');
      return false;
    }
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    try {
      final result = await _channel.invokeMethod('requestCameraPermission');
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Failed to request camera permission: ${e.message}');
      return false;
    }
  }

  /// Release resources
  Future<void> dispose() async {
    try {
      await stopTracking();
      await _channel.invokeMethod('dispose');
    } on PlatformException catch (e) {
      debugPrint('Failed to dispose MediaPipe: ${e.message}');
    }
  }
}
