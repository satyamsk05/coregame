import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/phone_app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable immersive sticky fullscreen mode to hide status bar & navigation bars on mobile
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const CoreGameApp());
  });
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  const MyCustomScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class CoreGameApp extends StatelessWidget {
  const CoreGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CORE Game',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MyCustomScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C853), // Green theme seed
          primary: const Color(0xFF00C853),
          secondary: const Color(0xFFFF5252),
          background: const Color(0xFFEBEBEB),
        ),
        textTheme: GoogleFonts.pressStart2pTextTheme(
          ThemeData.light().textTheme, // Base text style
        ).copyWith(
          // We override default bodyText to a clean bold sans-serif font for input fields,
          // while headers can use blocky fonts.
          bodyLarge: const TextStyle(fontFamily: 'Roboto', color: Colors.black),
          bodyMedium: const TextStyle(fontFamily: 'Roboto', color: Colors.black),
        ),
      ),
      home: const PhoneAppShell(),
    );
  }
}
