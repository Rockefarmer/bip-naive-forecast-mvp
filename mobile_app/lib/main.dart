import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'package:device_preview/device_preview.dart'; // Import this
import 'package:flutter/foundation.dart'; // For kReleaseMode

void main() {
  runApp(
    DevicePreview(
      // Only enable Device Preview in debug mode, not when you ship to the store
      enabled: !kReleaseMode, 
      builder: (context) => const MyApp(), // Wrap your app
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
// REQUIRED: These 3 lines connect your app to the previewer
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      
      title: 'Rockefarmer Labs',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.latoTextTheme(
          Theme.of(context).textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
