import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/gesture_service.dart';
import 'services/accessibility_service.dart';

void main() {
  runApp(const FingerTipApp());
}

class FingerTipApp extends StatelessWidget {
  const FingerTipApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GestureService()),
        ChangeNotifierProvider(create: (_) => AccessibilityService()),
      ],
      child: MaterialApp(
        title: 'FingerTip',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
