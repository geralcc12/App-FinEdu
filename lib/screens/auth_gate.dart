import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'auth_page.dart';

// Colores (para el loader)
const Color darkScaffoldBackground = Color(0xFF121212);
const Color accentColorGreen = Color(0xFF00D19A);

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras se determina el estado de auth, se muestra un loader.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: darkScaffoldBackground,
            body: Center(child: CircularProgressIndicator(color: accentColorGreen)),
          );
        }

        // Si el usuario está logueado, muestra HomePage.
        if (snapshot.hasData) {
          return const HomePage();
        }

        // Si no, muestra AuthPage para que inicie sesión o se registre.
        return const AuthPage();
      },
    );
  }
}
