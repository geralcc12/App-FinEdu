import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // Para TextInputFormatter

// Colores (ajusta según tu tema si es necesario, o usa un tema centralizado)
const Color darkScaffoldBackground = Color(0xFF121212);
const Color darkCardBackground = Color(0xFF1E1E1E);
const Color darkPrimaryTextColor = Colors.white;
const Color darkSecondaryTextColor = Color(0xFFB0B0B0);
const Color accentColorGreen = Color(0xFF00D19A);
const Color accentColorRed = Colors.redAccent;
const Color darkInputBorderColor = Color(0xFF505050);
const Color darkModalBackground = Color(0xFF2C2C2C); // Definición añadida aquí


class AddEditTransactionPage extends StatefulWidget {
  final DocumentSnapshot? transactionToEdit; // Recibe el DocumentSnapshot para editar

  const AddEditTransactionPage({super.key, this.transactionToEdit});

  @override
  _AddEditTransactionPageState createState() => _AddEditTransactionPageState();
}

class _AddEditTransactionPageState extends State<AddEditTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  String _transactionType = 'gasto'; // Valor por defecto
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _amountController = TextEditingController();

    if (widget.transactionToEdit != null) {
      final data = widget.transactionToEdit!.data() as Map<String, dynamic>?;
      _descriptionController.text = data?['descripcion'] ?? '';
      _amountController.text = (data?['monto'] as num?)?.toStringAsFixed(2) ?? '';
      _transactionType = widget.transactionToEdit!.reference.parent.id == 'ingresos' ? 'ingreso' : 'gasto';
      _selectedDate = (data?['fecha'] as Timestamp?)?.toDate() ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) { 
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: accentColorGreen,
              onPrimary: Colors.black,
              surface: darkCardBackground,
              onSurface: darkPrimaryTextColor,
            ),
            dialogBackgroundColor: darkModalBackground, // Ahora debería resolverse correctamente
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado.'), backgroundColor: Colors.redAccent),
        );
      }
      setState(() => _isSaving = false);
      return;
    }

    final description = _descriptionController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, ingresa un monto válido.'), backgroundColor: Colors.redAccent),
        );
      }
      setState(() => _isSaving = false);
      return;
    }

    final transactionData = {
      'userId': user.uid,
      'descripcion': description,
      'monto': amount,
      'fecha': Timestamp.fromDate(_selectedDate),
    };

    try {
      String message;
      if (widget.transactionToEdit != null) {
        final originalCollectionName = widget.transactionToEdit!.reference.parent.id;
        final newCollectionName = _transactionType == 'ingreso' ? 'ingresos' : 'gastos';

        if (newCollectionName != originalCollectionName) {
          await FirebaseFirestore.instance.collection(newCollectionName).add(transactionData);
          await widget.transactionToEdit!.reference.delete();
        } else {
          await widget.transactionToEdit!.reference.update(transactionData);
        }
        message = 'Transacción actualizada exitosamente.';
      } else {
        final collectionName = _transactionType == 'ingreso' ? 'ingresos' : 'gastos';
        await FirebaseFirestore.instance.collection(collectionName).add(transactionData);
        message = '${_transactionType == 'ingreso' ? "Ingreso" : "Gasto"} guardado exitosamente.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: accentColorGreen),
        );
        Navigator.of(context).pop(); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkScaffoldBackground,
      appBar: AppBar(
        title: Text(
          widget.transactionToEdit == null ? 'Agregar Transacción' : 'Editar Transacción',
          style: const TextStyle(color: darkPrimaryTextColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: darkCardBackground,
        elevation: 1,
        iconTheme: const IconThemeData(color: darkPrimaryTextColor),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_circle_outline_rounded),
              tooltip: 'Guardar',
              iconSize: 28,
              onPressed: _saveTransaction,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: ToggleButtons(
                  isSelected: [_transactionType == 'ingreso', _transactionType == 'gasto'],
                  onPressed: (index) {
                    setState(() {
                      _transactionType = index == 0 ? 'ingreso' : 'gasto';
                    });
                  },
                  borderRadius: BorderRadius.circular(10.0),
                  selectedColor: Colors.black, 
                  color: darkPrimaryTextColor, 
                  fillColor: _transactionType == 'ingreso' ? accentColorGreen.withAlpha(200) : accentColorRed.withAlpha(200), 
                  selectedBorderColor: _transactionType == 'ingreso' ? accentColorGreen : accentColorRed,
                  borderColor: darkInputBorderColor,
                  constraints: const BoxConstraints(minHeight: 45.0, minWidth: 120.0),
                  children: const <Widget>[
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Ingreso', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Gasto', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: darkPrimaryTextColor),
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ej: Salario, Comida, Transporte',
                  labelStyle: const TextStyle(color: darkSecondaryTextColor),
                  hintStyle: const TextStyle(color: darkSecondaryTextColor),
                  filled: true,
                  fillColor: darkCardBackground.withAlpha(100),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: accentColorGreen)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, ingresa una descripción.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                style: const TextStyle(color: darkPrimaryTextColor, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Monto',
                  hintText: '0.00',
                  labelStyle: const TextStyle(color: darkSecondaryTextColor),
                  hintStyle: const TextStyle(color: darkSecondaryTextColor),
                  prefixText: 'S/ ',
                  prefixStyle: const TextStyle(color: darkPrimaryTextColor, fontSize: 18, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: darkCardBackground.withAlpha(100),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: accentColorGreen)),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, ingresa un monto.';
                  }
                  final n = double.tryParse(value.trim());
                  if (n == null || n <= 0) {
                    return 'Ingresa un monto válido y mayor a cero.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: darkCardBackground.withAlpha(100),
                  borderRadius: BorderRadius.circular(10)
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.calendar_today_rounded, color: darkSecondaryTextColor),
                  title: Text(
                    'Fecha: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(color: darkPrimaryTextColor, fontSize: 16),
                  ),
                  trailing: const Icon(Icons.edit_calendar_outlined, color: accentColorGreen, size: 24),
                  onTap: () => _selectDate(context),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
