import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service to communicate with native AccessibilityService
class AccessibilityService extends ChangeNotifier {
  static const MethodChannel _channel =
      MethodChannel('com.fingertip.app/accessibility');

  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  /// Check if accessibility service is enabled
  Future<bool> checkServiceEnabled() async {
    try {
      final result = await _channel.invokeMethod('isServiceEnabled');
      _isEnabled = result == true;
      notifyListeners();
      return _isEnabled;
    } on PlatformException catch (e) {
      debugPrint('Failed to check accessibility service: ${e.message}');
      return false;
    }
  }

  /// Open accessibility settings
  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      debugPrint('Failed to open accessibility settings: ${e.message}');
    }
  }

  /// Perform click at position
  Future<bool> performClick(double x, double y) async {
    try {
      final result = await _channel.invokeMethod('performClick', {
        'x': x,
        'y': y,
      });
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Failed to perform click: ${e.message}');
      return false;
    }
  }

  /// Perform scroll gesture
  Future<bool> performScroll(String direction) async {
    try {
      final result = await _channel.invokeMethod('performScroll', {
        'direction': direction,
      });
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Failed to perform scroll: ${e.message}');
      return false;
    }
  }

  /// Perform a system global action like BACK or RECENTS
  Future<bool> performGlobalAction(String action) async {
    try {
      final result = await _channel.invokeMethod('performGlobalAction', {
        'action': action,
      });
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Failed to perform global action $action: ${e.message}');
      return false;
    }
  }

  /// Update cursor position (for overlay)
  Future<bool> updateCursorPosition(double x, double y) async {
    try {
      final result = await _channel.invokeMethod('updateCursorPosition', {
        'x': x,
        'y': y,
      });
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Failed to update cursor: ${e.message}');
      return false;
    }
  }

  /// Check overlay permission
  Future<bool> hasOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod('hasOverlayPermission');
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Failed to check overlay permission: ${e.message}');
      return false;
    }
  }

  /// Request overlay permission
  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } on PlatformException catch (e) {
      debugPrint('Failed to request overlay permission: ${e.message}');
    }
  }

  /// Show cursor overlay
  Future<bool> showCursorOverlay() async {
    try {
      final result = await _channel.invokeMethod('showCursorOverlay');
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Failed to show cursor overlay: ${e.message}');
      return false;
    }
  }

  /// Hide cursor overlay
  Future<bool> hideCursorOverlay() async {
    try {
      final result = await _channel.invokeMethod('hideCursorOverlay');
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Failed to hide cursor overlay: ${e.message}');
      return false;
    }
  }
}
