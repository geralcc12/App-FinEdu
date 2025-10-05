import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'auth_page.dart';

// --- WIDGET "GUARDIÁN" MOVIDO AQUÍ ---

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00D19A))),
          );
        }
        if (snapshot.hasData) {
          return const HomePage();
        }
        return const AuthPage();
      },
    );
  }
}

// --- PANTALLA DE SPLASH ---

const Color splashScreenBackground = Color(0xFF121212);
const Color coinColor = Color(0xFFFFD700);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<_Coin> _coins;
  final int _numberOfCoins = 20;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _coins = List.generate(_numberOfCoins, (index) {
      return _Coin(
        startX: _random.nextDouble(),
        startDelay: Duration(milliseconds: _random.nextInt(1500)),
        fallDuration: Duration(milliseconds: 1000 + _random.nextInt(1500)),
        size: 20.0 + _random.nextDouble() * 20.0,
      );
    });

    _animationController.forward();

    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthGate()), // Ahora encontrará AuthGate en este mismo archivo
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: splashScreenBackground,
      body: Stack(
        children: [
          // Animación de monedas
          ..._coins.map((coin) {
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final double elapsed = (_animationController.value * _animationController.duration!.inMilliseconds) - coin.startDelay.inMilliseconds;
                double progress = 0.0;
                if (elapsed > 0) {
                  progress = elapsed / coin.fallDuration.inMilliseconds;
                  progress = progress.clamp(0.0, 1.0);
                }

                if (progress == 0 && _animationController.value < 1.0) {
                     return const SizedBox.shrink();
                }

                return Positioned(
                  top: progress * MediaQuery.of(context).size.height - coin.size,
                  left: coin.startX * MediaQuery.of(context).size.width - (coin.size / 2),
                  child: Icon(
                    Icons.monetization_on_outlined,
                    color: coinColor.withOpacity(0.8),
                    size: coin.size,
                  ),
                );
              },
            );
          }).toList(),

          // Logo o Nombre de la App (Centrado)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.savings_rounded, color: coinColor, size: 80),
                const SizedBox(height: 20),
                const Text(
                  'FinEdu',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                       Shadow(blurRadius: 10.0, color: coinColor, offset: Offset(0,0))
                    ]
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tu asistente financiero personal',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Coin {
  final double startX;
  final Duration startDelay;
  final Duration fallDuration;
  final double size;

  _Coin({
    required this.startX,
    required this.startDelay,
    required this.fallDuration,
    required this.size,
  });
}
