import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gesture_service.dart';
import '../services/accessibility_service.dart';
import '../widgets/status_card.dart';
import '../widgets/gesture_visualizer.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final gestureService = context.read<GestureService>();
    final accessibilityService = context.read<AccessibilityService>();

    gestureService.setAccessibilityService(accessibilityService);

    await accessibilityService.checkServiceEnabled();
    await gestureService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FingerTip Gesture Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer2<GestureService, AccessibilityService>(
        builder: (context, gestureService, accessibilityService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Cards
                StatusCard(
                  title: 'Accessibility Service',
                  isEnabled: accessibilityService.isEnabled,
                  icon: Icons.accessibility_new,
                  onTap: () async {
                    if (!accessibilityService.isEnabled) {
                      await accessibilityService.openAccessibilitySettings();
                    }
                  },
                ),
                const SizedBox(height: 12),

                StatusCard(
                  title: 'Gesture Detection',
                  isEnabled: gestureService.isRunning,
                  icon: Icons.pan_tool,
                  subtitle: gestureService.isRunning
                      ? '${gestureService.currentFps.toStringAsFixed(1)} FPS'
                      : 'Not running',
                ),
                const SizedBox(height: 12),

                // Current Gesture Info
                if (gestureService.currentGesture != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Gesture',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Type: ${gestureService.currentGesture!.type.name}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (gestureService.currentGesture!.x != null)
                            Text(
                              'Position: (${gestureService.currentGesture!.x!.toStringAsFixed(3)}, ${gestureService.currentGesture!.y!.toStringAsFixed(3)})',
                              style: const TextStyle(fontSize: 14),
                            ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Hand Visualizer
                if (gestureService.currentLandmarks != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Hand Landmarks',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureVisualizer(
                            landmarks: gestureService.currentLandmarks!,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Control Buttons
                if (!accessibilityService.isEnabled)
                  ElevatedButton.icon(
                    onPressed: () async {
                      await accessibilityService.openAccessibilitySettings();
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Enable Accessibility Service'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.orange,
                    ),
                  )
                else if (!gestureService.isRunning)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final started = await gestureService.start();
                      if (!started && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Failed to start. Check permissions.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Gesture Control'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () async {
                      await gestureService.stop();
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Gesture Control'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.red,
                    ),
                  ),

                const SizedBox(height: 16),

                // Gesture Instructions
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Gesture Guide:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('👆 Move Cursor: Point with index finger'),
                        Text('👌 Click: Pinch thumb and index together'),
                        Text('✊ Scroll Up: Fist + move hand up'),
                        Text('✊ Scroll Down: Fist + move hand down'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
