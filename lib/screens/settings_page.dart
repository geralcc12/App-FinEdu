import 'package:aplicaciones_moviles/screens/achievements_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reminders_page.dart';

const Color darkScaffoldBackground = Color(0xFF121212);
const Color darkCardBackground = Color(0xFF1E1E1E);
const Color darkPrimaryTextColor = Colors.white;
const Color darkSecondaryTextColor = Color(0xFFB0B0B0);
const Color accentColorGreen = Color(0xFF00D19A);

const String _kDarkModeEnabledKey = 'dark_mode_enabled';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _darkModeEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkModeEnabled = prefs.getBool(_kDarkModeEnabledKey) ?? true;
    });
  }

  Future<void> _saveBoolSetting(String key, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
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
          if (_currentUser != null) ...[
            _buildSectionTitle(context, 'Cuenta'),
            ListTile(
              leading: const Icon(Icons.email_outlined, color: darkSecondaryTextColor),
              title: const Text('Email', style: TextStyle(color: darkPrimaryTextColor)),
              subtitle: Text(_currentUser!.email ?? 'No disponible', style: const TextStyle(color: darkSecondaryTextColor)),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
              onTap: _logout,
            ),
          ],

          const Divider(color: Colors.grey),

          // --- SECCIÓN DE GAMIFICACIÓN ---
          _buildSectionTitle(context, 'Progreso'),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined, color: darkSecondaryTextColor),
            title: const Text('Mis Logros', style: TextStyle(color: darkPrimaryTextColor)),
            subtitle: const Text('Consulta tus medallas y progreso', style: TextStyle(color: darkSecondaryTextColor)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: darkSecondaryTextColor, size: 16),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AchievementsPage()));
            },
          ),
          
          const Divider(color: Colors.grey),

          _buildSectionTitle(context, 'Notificaciones'),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined, color: darkSecondaryTextColor),
            title: const Text('Gestionar Recordatorios', style: TextStyle(color: darkPrimaryTextColor)),
            subtitle: const Text('Programa tus recordatorios de pagos y ahorros', style: TextStyle(color: darkSecondaryTextColor)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: darkSecondaryTextColor, size: 16),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RemindersPage()));
            },
          ),

          const Divider(color: Colors.grey),
          _buildSectionTitle(context, 'Apariencia'),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined, color: darkSecondaryTextColor),
            title: const Text('Moneda Principal', style: TextStyle(color: darkPrimaryTextColor)),
            trailing: const Text('S/ (PEN)', style: TextStyle(color: darkSecondaryTextColor, fontSize: 16)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cambio de moneda no implementado')));
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
