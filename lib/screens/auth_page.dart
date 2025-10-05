// lib/screens/auth_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Colores
const Color darkScaffoldBackground = Color(0xFF121212);
const Color darkCardBackground = Color(0xFF1E1E1E);
const Color darkPrimaryTextColor = Colors.white;
const Color darkSecondaryTextColor = Color(0xFFB0B0B0);
const Color accentColorGreen = Color(0xFF00D19A);
const Color coinColor = Color(0xFFFFD700);

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  bool _showPass = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
        await FirebaseFirestore.instance.collection('usuarios').doc(cred.user!.uid).set({
          'nombre': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'fechaRegistro': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // --- MEJORA: Mensajes de error de Firebase en Español ---
      String errorMessage = 'Ocurrió un error inesperado.';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No se encontró un usuario con ese correo electrónico.';
          break;
        case 'wrong-password':
          errorMessage = 'La contraseña es incorrecta. Por favor, inténtalo de nuevo.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Este correo electrónico ya está registrado. Intenta iniciar sesión.';
          break;
        case 'invalid-email':
          errorMessage = 'El formato del correo electrónico no es válido.';
          break;
        case 'weak-password':
          errorMessage = 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
          break;
        default:
          errorMessage = 'Error de autenticación: ${e.code}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage, style: const TextStyle(color: darkPrimaryTextColor)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkScaffoldBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(Icons.savings_rounded, color: coinColor, size: 60),
                  const SizedBox(height: 12),
                  const Text('FinEdu', textAlign: TextAlign.center, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: darkPrimaryTextColor)),
                  const SizedBox(height: 8),
                  Text(_isLogin ? 'Bienvenido de Nuevo' : 'Crea tu Cuenta', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: darkSecondaryTextColor)),
                  const SizedBox(height: 40),
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _inputDecoration('Nombre Completo', Icons.person_outline_rounded),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre completo' : null,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: darkPrimaryTextColor),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('Correo Electrónico', Icons.email_outlined),
                    validator: (v) => (v == null || !v.trim().contains('@')) ? 'Ingresa un correo válido' : null,
                    style: const TextStyle(color: darkPrimaryTextColor),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: !_showPass,
                    decoration: _inputDecoration('Contraseña', Icons.lock_outline_rounded).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: darkSecondaryTextColor),
                        onPressed: () => setState(() => _showPass = !_showPass),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                    style: const TextStyle(color: darkPrimaryTextColor),
                  ),
                  const SizedBox(height: 12),
                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funcionalidad no implementada aún.')));
                        },
                        child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: darkSecondaryTextColor, fontSize: 14)),
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: accentColorGreen, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87))
                        : Text(_isLogin ? 'Iniciar Sesión' : 'Crear Cuenta', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _loading ? null : () => setState(() {
                      _isLogin = !_isLogin;
                      _formKey.currentState?.reset();
                      _nameCtrl.clear();
                      _emailCtrl.clear();
                      _passCtrl.clear();
                    }),
                    child: Text(_isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia Sesión', style: const TextStyle(color: accentColorGreen, fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: darkSecondaryTextColor),
      hintText: labelText,
      hintStyle: const TextStyle(color: darkSecondaryTextColor),
      prefixIcon: Icon(icon, color: darkSecondaryTextColor, size: 20),
      filled: true,
      fillColor: darkCardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade800, width: 0.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentColorGreen, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.redAccent.shade100, width: 1)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      errorStyle: TextStyle(color: Colors.redAccent.shade100),
    );
  }
}
