import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/chat_message.dart';
import 'models/settings.dart';
import 'models/chat_session.dart';
import 'screens/splash_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(ChatSessionAdapter());
  
  runApp(
    const ProviderScope(
      child: ZapChatApp(),
    ),
  );
}

class ZapChatApp extends ConsumerStatefulWidget {
  const ZapChatApp({super.key});

  @override
  ConsumerState<ZapChatApp> createState() => _ZapChatAppState();
}

class _ZapChatAppState extends ConsumerState<ZapChatApp> {
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    
    return MaterialApp(
      title: 'ZapChat',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(settings),
      darkTheme: _buildDarkTheme(settings),
      themeMode: settings.themeMode,
      home: _isInitialized 
          ? const ChatScreen() 
          : SplashScreen(
              onInitializationComplete: () {
                setState(() {
                  _isInitialized = true;
                });
              },
            ),
      routes: {
        '/settings': (context) => const SettingsScreen(),
        '/chat': (context) => const ChatScreen(),
      },
    );
  }

  ThemeData _buildLightTheme(AppSettings settings) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: settings.primaryColor,
        secondary: settings.secondaryColor,
        surface: Colors.white,
        background: const Color(0xFFFAF9F6),
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1B1E),
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1B1E),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme(AppSettings settings) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: settings.primaryColor,
        secondary: settings.secondaryColor,
        surface: const Color(0xFF1A1B1E),
        background: const Color(0xFF0F0F0F),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1A1B1E),
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}