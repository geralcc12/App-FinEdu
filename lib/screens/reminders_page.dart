import 'package:flutter/material.dart';
import 'add_reminder_page.dart'; // Página que crearemos a continuación

// Colores (puedes tenerlos en un archivo central)
const Color darkScaffoldBackground = Color(0xFF121212);
const Color darkCardBackground = Color(0xFF1E1E1E);
const Color darkPrimaryTextColor = Colors.white;
const Color darkSecondaryTextColor = Color(0xFFB0B0B0);
const Color accentColorGreen = Color(0xFF00D19A);

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  _RemindersPageState createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  // Por ahora, una lista vacía. La llenaremos desde la memoria del teléfono más adelante.
  final List<dynamic> _reminders = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkScaffoldBackground,
      appBar: AppBar(
        title: const Text('Recordatorios', style: TextStyle(color: darkPrimaryTextColor, fontWeight: FontWeight.bold)),
        backgroundColor: darkCardBackground,
        elevation: 1,
        iconTheme: const IconThemeData(color: darkPrimaryTextColor),
      ),
      body: _reminders.isEmpty
          ? _buildEmptyState()
          : _buildRemindersList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar a la página para añadir un nuevo recordatorio
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddReminderPage()),
          );
        },
        backgroundColor: accentColorGreen,
        child: const Icon(Icons.add_alert_rounded, color: Colors.black),
        tooltip: 'Nuevo Recordatorio',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined, size: 80, color: darkSecondaryTextColor),
          const SizedBox(height: 20),
          const Text(
            'No tienes recordatorios',
            style: TextStyle(color: darkPrimaryTextColor, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Crea un nuevo recordatorio para\nfechas de pago, ahorros y más.',
            textAlign: TextAlign.center,
            style: TextStyle(color: darkSecondaryTextColor.withOpacity(0.8), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersList() {
    // Esta es la vista que se mostrará cuando tengamos recordatorios guardados.
    return ListView.builder(
      itemCount: _reminders.length,
      itemBuilder: (context, index) {
        // Aquí construiremos cada item de la lista
        return ListTile(
          title: Text('Recordatorio ${index + 1}'),
        );
      },
    );
  }
}
