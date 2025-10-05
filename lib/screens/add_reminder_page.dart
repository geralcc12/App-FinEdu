import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

// Colores
const Color darkScaffoldBackground = Color(0xFF121212);
const Color darkCardBackground = Color(0xFF1E1E1E);
const Color darkPrimaryTextColor = Colors.white;
const Color darkSecondaryTextColor = Color(0xFFB0B0B0);
const Color accentColorGreen = Color(0xFF00D19A);
const Color darkInputBorderColor = Color(0xFF505050); // <--- AÑADIDO: La constante que faltaba

class AddReminderPage extends StatefulWidget {
  const AddReminderPage({super.key});

  @override
  _AddReminderPageState createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede programar un recordatorio en el pasado.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _isSaving = false);
      return;
    }

    final notificationService = NotificationService();
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await notificationService.scheduleNotification(
      id: id,
      title: 'Recordatorio de FinEdu',
      body: _titleController.text.trim(),
      scheduledDate: scheduledDateTime,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recordatorio guardado exitosamente.'),
          backgroundColor: accentColorGreen,
          duration: Duration(seconds: 2),
        ),
      );

      // Espera a que el SnackBar sea visible antes de volver
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkScaffoldBackground,
      appBar: AppBar(
        title: const Text('Nuevo Recordatorio', style: TextStyle(color: darkPrimaryTextColor, fontWeight: FontWeight.bold)),
        backgroundColor: darkCardBackground,
        elevation: 1,
        iconTheme: const IconThemeData(color: darkPrimaryTextColor),
        actions: [
          _isSaving
            ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
            : IconButton(
                icon: const Icon(Icons.check_circle_outline_rounded),
                onPressed: _saveReminder,
                tooltip: 'Guardar',
              ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: <Widget>[
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration('Título del recordatorio', 'Ej: Pagar tarjeta de crédito'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Por favor, ingresa un título.' : null,
              style: const TextStyle(color: darkPrimaryTextColor),
            ),
            const SizedBox(height: 20),
            _buildDateTimePicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Container(
      decoration: BoxDecoration(
        color: darkCardBackground.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today_rounded, color: darkSecondaryTextColor),
            title: const Text('Fecha', style: TextStyle(color: darkPrimaryTextColor)),
            trailing: Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: const TextStyle(color: accentColorGreen, fontSize: 16)),
            onTap: () => _selectDate(context),
          ),
          const Divider(height: 1, color: darkInputBorderColor), // <-- AHORA FUNCIONARÁ
          ListTile(
            leading: const Icon(Icons.access_time_filled_rounded, color: darkSecondaryTextColor),
            title: const Text('Hora', style: TextStyle(color: darkPrimaryTextColor)),
            trailing: Text(_selectedTime.format(context), style: const TextStyle(color: accentColorGreen, fontSize: 16)),
            onTap: () => _selectTime(context),
          ),
        ],
      ),
    );
  }
  
  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: darkSecondaryTextColor),
      hintStyle: const TextStyle(color: darkSecondaryTextColor),
      filled: true,
      fillColor: darkCardBackground.withAlpha(100),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: accentColorGreen)),
    );
  }
}
