import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/audio_service.dart';
import 'services/download_service.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AudioService>(
          create: (_) => AudioService(),
        ),
        Provider<DownloadService>(
          create: (_) => DownloadService(),
        ),
      ],
      child: MaterialApp(
        title: 'MP3 Player',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.light(
            primary: const Color(0xFF1E88E5), // Azul principal
            onPrimary: Colors.white,
            secondary: const Color(0xFF64B5F6), // Azul secundario
            onSecondary: Colors.white,
            surface: Colors.white,
            background: Colors.white,
            error: Colors.red,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF1E88E5),
            onPrimary: Colors.white,
            secondary: const Color(0xFF64B5F6),
            onSecondary: Colors.white,
            surface: const Color(0xFF121212),
            background: const Color(0xFF121212),
            error: Colors.red,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
} 