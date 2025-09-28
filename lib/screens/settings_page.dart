import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <--- AÑADIDO

const Color darkScaffoldBackground = Color(0xFF121212);
const Color darkCardBackground = Color(0xFF1E1E1E);
const Color darkPrimaryTextColor = Colors.white;
const Color darkSecondaryTextColor = Color(0xFFB0B0B0);
const Color accentColorGreen = Color(0xFF00D19A);

// Claves para SharedPreferences
const String _kNotificationsEnabledKey = 'notifications_enabled';
const String _kDarkModeEnabledKey = 'dark_mode_enabled';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _notificationsEnabled = true; 
  bool _darkModeEnabled = true; 

  @override
  void initState() {
    super.initState();
    _loadSettings(); // <--- AÑADIDO: Cargar configuraciones al iniciar
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool(_kNotificationsEnabledKey) ?? true; // Valor por defecto true si no existe
      _darkModeEnabled = prefs.getBool(_kDarkModeEnabledKey) ?? true;       // Valor por defecto true si no existe
    });
  }

  Future<void> _saveBoolSetting(String key, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkScaffoldBackground,
      appBar: AppBar(
        title: const Text('Configuración', style: TextStyle(color: darkPrimaryTextColor, fontWeight: FontWeight.bold)),
        backgroundColor: darkCardBackground,
        elevation: 1,
        iconTheme: const IconThemeData(color: darkPrimaryTextColor),
      ),
      body: ListView(
        children: <Widget>[
          if (_currentUser != null)
            _buildSectionTitle(context, 'Cuenta'),
          if (_currentUser != null)
            ListTile(
              leading: const Icon(Icons.email_outlined, color: darkSecondaryTextColor),
              title: const Text('Email', style: TextStyle(color: darkPrimaryTextColor)),
              subtitle: Text(_currentUser!.email ?? 'No disponible', style: const TextStyle(color: darkSecondaryTextColor)),
            ),
          if (_currentUser != null)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
              onTap: _logout,
            ),
          
          const Divider(color: Colors.grey),
          _buildSectionTitle(context, 'Notificaciones'),
          SwitchListTile(
            title: const Text('Recordatorios de Gastos', style: TextStyle(color: darkPrimaryTextColor)),
            subtitle: const Text('Recibir notificaciones para registrar gastos', style: TextStyle(color: darkSecondaryTextColor)),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _saveBoolSetting(_kNotificationsEnabledKey, value); // <--- AÑADIDO: Guardar cambio
              // Todavía mostramos el SnackBar porque la funcionalidad de notificación no está implementada
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Recordatorios ${value ? "activados" : "desactivados"}')),
              );
            },
            secondary: const Icon(Icons.notifications_outlined, color: darkSecondaryTextColor),
            activeColor: accentColorGreen,
          ),

          const Divider(color: Colors.grey),
          _buildSectionTitle(context, 'Apariencia'),
           ListTile(
            leading: const Icon(Icons.color_lens_outlined, color: darkSecondaryTextColor),
            title: const Text('Moneda Principal', style: TextStyle(color: darkPrimaryTextColor)),
            trailing: const Text('S/ (PEN)', style: TextStyle(color: darkSecondaryTextColor, fontSize: 16)),
            onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cambio de moneda no implementado')),
                );
            },
          ),
          SwitchListTile(
            title: const Text('Tema Oscuro', style: TextStyle(color: darkPrimaryTextColor)),
            value: _darkModeEnabled,
            onChanged: (bool value) {
              setState(() {
                _darkModeEnabled = value;
              });
              _saveBoolSetting(_kDarkModeEnabledKey, value); // <--- AÑADIDO: Guardar cambio
              // Aquí iría la lógica real para cambiar el tema de la app (necesitaría un gestor de temas)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tema oscuro ${value ? "activado" : "desactivado"} (Cambio visual no implementado)')),
              );
            },
            secondary: const Icon(Icons.dark_mode_outlined, color: darkSecondaryTextColor),
            activeColor: accentColorGreen,
          ),
          
          const Divider(color: Colors.grey),
          _buildSectionTitle(context, 'Acerca de'),
          ListTile(
            leading: const Icon(Icons.info_outline, color: darkSecondaryTextColor),
            title: const Text('Acerca de FinEdu', style: TextStyle(color: darkPrimaryTextColor)),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: darkCardBackground,
                    title: const Text('Acerca de FinEdu', style: TextStyle(color: darkPrimaryTextColor)),
                    content: const Text(
                      'FinEdu es una aplicación para ayudarte a gestionar tus finanzas personales y fomentar el ahorro.\n\nVersión: 1.0.0 (Estudiante Edition)',
                      style: TextStyle(color: darkSecondaryTextColor),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cerrar', style: TextStyle(color: accentColorGreen)),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
           ListTile(
            leading: const Icon(Icons.help_outline, color: darkSecondaryTextColor),
            title: const Text('Ayuda y Soporte', style: TextStyle(color: darkPrimaryTextColor)),
            onTap: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sección de ayuda no implementada aún.')),
                );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: accentColorGreen,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
