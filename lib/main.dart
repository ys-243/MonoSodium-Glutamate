import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:plannus/services/auth_service.dart';
import 'package:plannus/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ThemeController themeController = ThemeController();
  await themeController.loadTheme();

  await dotenv.load(fileName: '.env');
  
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];

  if (supabaseUrl == null || supabaseUrl.isEmpty) {
    throw Exception('Supabase URL is not set in the .env file.');
  }

  if (supabaseKey == null || supabaseKey.isEmpty) {
    throw Exception('Supabase Publishable Key is not set in the .env file.');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey,
  );
  
  runApp(
    ProviderScope(
      child: PlanNUSApp(
        themeController: themeController
      ),
    ),
  );
}

class PlanNUSApp extends StatelessWidget {
  final ThemeController themeController;
  
  const PlanNUSApp({
    super.key,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      child: AuthService(
        themeController: themeController
      ),

      builder: (context, child) {
        return MaterialApp(
          title: 'PlanNUS',
          debugShowCheckedModeBanner: false,
          
          // Light mode
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
            ),
          ),

          // Dark mode
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
            ),
          ),

          // Controls whether light or dark mode is used
          themeMode: themeController.themeMode,

          home: child,
        );
      },
    );
  }
}