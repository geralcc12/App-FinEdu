// lib/screens/auth_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  bool _isLogin = true; // Default to login, will be set by splash choice
  bool _loading = false;
  bool _showPass = false;
  bool _showSplash = true; // Start with splash screen

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      if (_isLogin) {
        // LOGIN
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      } else {
        // REGISTRO
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(cred.user!.uid)
            .set({
          'nombre': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'fechaRegistro': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return; // Verificar si el widget sigue montado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Ocurrió un error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildSplashContent(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3), // #F1FFF3,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // IMAGEN SVG
            SvgPicture.asset(
              'lib/assets/logo.svg', // RUTA A TU SVG
              height: 114, 
              width: 109,
            ),
            const SizedBox(height: 2), // Espacio entre logo y texto FinEdu

            // TEXTO FINEDU
            Text(
              'FinEdu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 52.14,
                color: Color(0xFF00D09E), // #00D09E
                fontWeight: FontWeight.bold, // Puedes ajustar el grosor si lo deseas
              ),
            ),
            const SizedBox(height: 10), // Espacio entre texto FinEdu y botones

            // BOTÓN LOGIN
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLogin = true;
                  _showSplash = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00D09E), 
                foregroundColor: Color( 0xFF093030), 
                textStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                minimumSize: Size(207, 45)
              ),
              child: const Text('Login'),
            ),
            const SizedBox(height: 12),

            // BOTÓN SIGN UP
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLogin = false;
                  _showSplash = false;
                });
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xffdff7e2), 
                  foregroundColor: Color( 0xFF093030), 
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  minimumSize: Size(207, 45)
              ),
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthForm(BuildContext context) {
    // COLORES
    const bgPanel   = Color(0xFFF1FFF3); // panel superior redondeado (mint claro)
    const primary   = Color(0xFF00D09E); // verde principal
    const textDark  = Color(0xFF0E2C2C);
    const inputFill = Color(0xFFDFF7E2);
    const linkBlue  = Color(0xFF2F80ED);

    // Altura del área “verde” donde va el título
    const double headerHeight = 140;

    return Scaffold(
      // OJO: dejamos el Scaffold SIN color; el fondo es el gradient que ponemos en el Stack
      body: SafeArea(
        top: false, // para que el verde cubra hasta el tope de la pantalla
        child: Stack(
          children: [
            // 1) FONDO COMPLETO VERDE (gradient)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF04D6A3), Color(0xFF00C497)],
                  ),
                ),
              ),
            ),

            // 2) TÍTULO sobre el fondo verde
            Positioned(
              top: MediaQuery.of(context).padding.top + 44,
              left: 0, right: 0,
              child: Center(
                child: Text(
                  _isLogin ? 'Bienvenido' : 'Crear Cuenta', // Título dinámico
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0E2C2C),
                  ),
                ),
              ),
            ),

            // 3) PANEL #F1FFF3 QUE SE MONTA SOBRE EL FONDO VERDE
            Positioned.fill(
              top: headerHeight,
              child: Container(
                decoration: const BoxDecoration(
                  color: bgPanel,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(68),
                    topRight: Radius.circular(68),
                  ),
                  // sombra muy suave para “despegar” el panel si quieres
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000), // 10% negro
                      blurRadius: 24,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),

                // 4) CONTENIDO DEL FORMULARIO
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(38, 95, 38, 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch, // Mantenemos stretch para los TextFields
                      children: [
                        // CAMPO NOMBRE COMPLETO (SOLO PARA REGISTRO)
                        if (!_isLogin) ...[
                          const Text('Nombre Completo',
                              style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              hintText: 'Tu nombre completo',
                              filled: true,
                              fillColor: inputFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            ),
                            validator: (v) => 
                              (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre completo' : null,
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                        ],

                        const Text('Username Or Email',
                            style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'example@example.com',
                            filled: true,
                            fillColor: inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          ),
                          validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Ingresa tu correo' : null,
                        ),
                        const SizedBox(height: 16),

                        const Text('Password',
                            style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: !_showPass,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            filled: true,
                            fillColor: inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _showPass = !_showPass),
                              icon: Icon(
                                _showPass ? Icons.visibility_off : Icons.visibility,
                                color: textDark.withAlpha((255 * 0.6).round()),
                              ),
                              splashRadius: 18,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                            if (v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 95),

                        // Botón Principal (Log In / Sign Up)
                        Center( 
                          child: SizedBox(
                            height: 45,
                            width: 207,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.black,
                                shape: const StadiumBorder(),
                                textStyle: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(_isLogin ? 'Log In' : 'Sign Up'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Center(
                          child: TextButton(
                            onPressed: () {}, // TODO: recovery
                            style: TextButton.styleFrom(
                              foregroundColor: textDark,
                              textStyle: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            child: const Text('Forgot Password?'),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Botón para cambiar entre Log In / Sign Up (o crear cuenta)
                        Center( 
                          child: SizedBox(
                            height: 45,
                            width: 207,
                            child: ElevatedButton(
                              onPressed: _loading ? null : () {
                                setState(() {
                                  _isLogin = !_isLogin; // Cambia entre login y registro
                                  _formKey.currentState?.reset(); // Opcional: resetea el form
                                  _nameCtrl.clear();
                                  _emailCtrl.clear();
                                  _passCtrl.clear();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: inputFill,
                                foregroundColor: textDark,
                                elevation: 0,
                                shape: const StadiumBorder(),
                                textStyle: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              child: Text(_isLogin ? 'Create Account' : 'Already have an account? Log In'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return _buildSplashContent(context);
    } else {
      return _buildAuthForm(context);
    }
  }
}
