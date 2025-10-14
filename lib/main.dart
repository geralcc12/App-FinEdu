// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart'; 
import 'screens/auth_page.dart';
import 'package:google_fonts/google_fonts.dart';

// --- IMPORTS AÑADIDOS/REACTIVADOS ---
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/notification_service.dart'; // El servicio de notificaciones que creamos

void main() async {
  // Asegurar que los bindings de Flutter están inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- CONFIGURACIÓN DE SERVICIOS ---
  // Inicializar el servicio de notificaciones y pedir permisos
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();

  // Inicializar la localización para formato de fechas en español
  await initializeDateFormatting('es_ES', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Colors.indigo; 
    final poppins = GoogleFonts.poppinsTextTheme();

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
      textTheme: poppins,
      // ... (resto del tema sin cambios)
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      textTheme: poppins,
      // ... (resto del tema sin cambios)
    );

    return MaterialApp(
      title: 'FinEdu',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, 
      theme: lightTheme, 
      darkTheme: darkTheme, 

      // --- SOPORTE DE LOCALIZACIÓN REACTIVADO ---
      localizationsDelegates: const [ 
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [ 
        Locale('en', ''), // Inglés
        Locale('es', 'ES'), // Español
      ],

      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthPage(),
      },
    );
  }
}
