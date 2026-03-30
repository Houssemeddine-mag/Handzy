import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gesture_service.dart';
import '../models/gesture.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _clickThreshold;
  late double _scrollVelocityThreshold;
  late double _fistThreshold;
  late int _smoothingFrames;
  late double _cursorSensitivity;

  @override
  void initState() {
    super.initState();
    final config = context.read<GestureService>().config;
    _clickThreshold = config.clickThreshold;
    _scrollVelocityThreshold = config.scrollVelocityThreshold;
    _fistThreshold = config.fistThreshold;
    _smoothingFrames = config.smoothingFrames;
    _cursorSensitivity = config.cursorSensitivity;
  }

  void _saveSettings() {
    final gestureService = context.read<GestureService>();
    gestureService.updateConfig(
      GestureConfig(
        clickThreshold: _clickThreshold,
        scrollVelocityThreshold: _scrollVelocityThreshold,
        fistThreshold: _fistThreshold,
        smoothingFrames: _smoothingFrames,
        cursorSensitivity: _cursorSensitivity,
      ),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved!')));

    Navigator.pop(context);
  }

  void _resetToDefaults() {
    setState(() {
      _clickThreshold = 0.05;
      _scrollVelocityThreshold = 0.1;
      _fistThreshold = 0.15;
      _smoothingFrames = 5;
      _cursorSensitivity = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('SAVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gesture Thresholds',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Click Threshold
                  Text(
                    'Click Threshold: ${_clickThreshold.toStringAsFixed(3)}',
                  ),
                  Slider(
                    value: _clickThreshold,
                    min: 0.01,
                    max: 0.15,
                    divisions: 140,
                    onChanged: (value) {
                      setState(() => _clickThreshold = value);
                    },
                  ),
                  const Text(
                    'Distance between thumb and index for click detection',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Scroll Velocity Threshold
                  Text(
                    'Scroll Velocity: ${_scrollVelocityThreshold.toStringAsFixed(3)}',
                  ),
                  Slider(
                    value: _scrollVelocityThreshold,
                    min: 0.05,
                    max: 0.3,
                    divisions: 50,
                    onChanged: (value) {
                      setState(() => _scrollVelocityThreshold = value);
                    },
                  ),
                  const Text(
                    'Minimum hand movement speed to trigger scroll',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Fist Threshold
                  Text('Fist Detection: ${_fistThreshold.toStringAsFixed(3)}'),
                  Slider(
                    value: _fistThreshold,
                    min: 0.1,
                    max: 0.3,
                    divisions: 40,
                    onChanged: (value) {
                      setState(() => _fistThreshold = value);
                    },
                  ),
                  const Text(
                    'Maximum distance from wrist to detect closed fist',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Smoothing Frames
                  Text('Smoothing Frames: $_smoothingFrames'),
                  Slider(
                    value: _smoothingFrames.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (value) {
                      setState(() => _smoothingFrames = value.round());
                    },
                  ),
                  const Text(
                    'Number of frames to average for smooth cursor movement',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Cursor Sensitivity
                  Text(
                    'Cursor Sensitivity: ${_cursorSensitivity.toStringAsFixed(2)}x',
                  ),
                  Slider(
                    value: _cursorSensitivity,
                    min: 0.5,
                    max: 2.0,
                    divisions: 30,
                    onChanged: (value) {
                      setState(() => _cursorSensitivity = value);
                    },
                  ),
                  const Text(
                    'Cursor movement speed multiplier',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.restore),
            label: const Text('Reset to Defaults'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),

          const SizedBox(height: 16),

          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '💡 Tips:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Lower click threshold = easier to trigger clicks'),
                  Text('• Higher smoothing = smoother but slower cursor'),
                  Text('• Increase sensitivity for faster cursor movement'),
                  Text('• Adjust thresholds based on your hand size'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
