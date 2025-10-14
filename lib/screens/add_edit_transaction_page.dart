import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Colores y Constantes
const Color darkScaffoldBackground = Color(0xFF121212);
const Color darkCardBackground = Color(0xFF1E1E1E);
const Color darkPrimaryTextColor = Colors.white;
const Color darkSecondaryTextColor = Color(0xFFB0B0B0);
const Color accentColorGreen = Color(0xFF00D19A);
const Color accentColorRed = Colors.redAccent;
const Color darkInputBorderColor = Color(0xFF505050);
const Color darkModalBackground = Color(0xFF2C2C2C);

// Mapas de Categorías con Iconos
const Map<String, IconData> categoriasGastoConIcono = {
  'Comida': Icons.fastfood_rounded,
  'Transporte': Icons.directions_car_filled_rounded,
  'Alojamiento': Icons.hotel_rounded,
  'Servicios': Icons.receipt_long_rounded,
  'Entretenimiento': Icons.sports_esports_rounded,
  'Salud': Icons.local_hospital_rounded,
  'Educación': Icons.school_rounded,
  'Ropa': Icons.checkroom_rounded,
  'Compras': Icons.shopping_bag_rounded,
  'Otros': Icons.more_horiz_rounded,
};

const Map<String, IconData> categoriasIngresoConIcono = {
  'Salario': Icons.work_rounded,
  'Bonificación': Icons.add_card_rounded,
  'Ventas': Icons.store_rounded,
  'Inversiones': Icons.trending_up_rounded,
  'Regalo': Icons.card_giftcard_rounded,
  'Otros': Icons.more_horiz_rounded,
};

class AddEditTransactionPage extends StatefulWidget {
  final DocumentSnapshot? transactionToEdit;
  const AddEditTransactionPage({super.key, this.transactionToEdit});

  @override
  _AddEditTransactionPageState createState() => _AddEditTransactionPageState();
}

class _AddEditTransactionPageState extends State<AddEditTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  String _transactionType = 'gasto';
  String? _selectedCategory;
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
      _selectedCategory = data?['categoria'] as String?;
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
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: accentColorGreen, onPrimary: Colors.black, surface: darkCardBackground, onSurface: darkPrimaryTextColor),
          dialogBackgroundColor: darkModalBackground,
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _showCategoryPicker() async {
    final categoriesMap = _transactionType == 'gasto' ? categoriasGastoConIcono : categoriasIngresoConIcono;
    final categories = categoriesMap.keys.toList();

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: darkModalBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: categories.length,
          itemBuilder: (BuildContext context, int index) {
            final category = categories[index];
            final icon = categoriesMap[category];
            return ListTile(
              leading: Icon(icon, color: darkSecondaryTextColor),
              title: Text(category, style: const TextStyle(color: darkPrimaryTextColor)),
              onTap: () => Navigator.of(context).pop(category),
              trailing: _selectedCategory == category ? const Icon(Icons.check_circle_rounded, color: accentColorGreen) : null,
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() => _selectedCategory = selected);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecciona una categoría.'), backgroundColor: Colors.redAccent));
      return;
    }
    
    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Usuario no autenticado.')));
      setState(() => _isSaving = false);
      return;
    }

    final transactionData = {
      'userId': user.uid,
      'descripcion': _descriptionController.text.trim(),
      'monto': double.parse(_amountController.text.trim()),
      'fecha': Timestamp.fromDate(_selectedDate),
      'categoria': _selectedCategory,
    };

    try {
      final collectionName = _transactionType == 'ingreso' ? 'ingresos' : 'gastos'; // <-- LA VARIABLE CORRECTA
      String message;

      if (widget.transactionToEdit != null) {
        final originalCollectionName = widget.transactionToEdit!.reference.parent.id;

        // --- CORRECCIÓN DEL ERROR ---
        if (collectionName != originalCollectionName) {
          await FirebaseFirestore.instance.collection(collectionName).add(transactionData);
          await widget.transactionToEdit!.reference.delete();
        } else {
          await widget.transactionToEdit!.reference.update(transactionData);
        }
        message = 'Transacción actualizada exitosamente.';
      } else {
        await FirebaseFirestore.instance.collection(collectionName).add(transactionData);
        message = '${_transactionType == 'ingreso' ? "Ingreso" : "Gasto"} guardado exitosamente.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: accentColorGreen));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: ${e.toString()}'), backgroundColor: Colors.redAccent));
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
        title: Text(widget.transactionToEdit == null ? 'Agregar Transacción' : 'Editar Transacción', style: const TextStyle(color: darkPrimaryTextColor, fontWeight: FontWeight.bold)),
        backgroundColor: darkCardBackground,
        elevation: 1,
        iconTheme: const IconThemeData(color: darkPrimaryTextColor),
        actions: [
          _isSaving
            ? const Padding(padding: EdgeInsets.all(16.0), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))))
            : IconButton(icon: const Icon(Icons.check_circle_outline_rounded), tooltip: 'Guardar', iconSize: 28, onPressed: _saveTransaction),
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
                      _selectedCategory = null;
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
                decoration: _inputDecoration('Descripción', 'Ej: Salario, Comida, Transporte'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Por favor, ingresa una descripción.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                style: const TextStyle(color: darkPrimaryTextColor, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: _inputDecoration('Monto', '0.00').copyWith(prefixText: 'S/ ', prefixStyle: const TextStyle(color: darkPrimaryTextColor, fontSize: 18, fontWeight: FontWeight.bold)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Por favor, ingresa un monto.';
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Ingresa un monto válido y mayor a cero.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildCategorySelector(),
              const SizedBox(height: 16),
              _buildDateSelector(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    IconData? currentIcon;
    if (_selectedCategory != null) {
      currentIcon = (_transactionType == 'gasto' ? categoriasGastoConIcono : categoriasIngresoConIcono)[_selectedCategory];
    }

    return Container(
      decoration: BoxDecoration(color: darkCardBackground.withAlpha(100), borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(currentIcon ?? Icons.category_outlined, color: darkSecondaryTextColor),
        title: Text(_selectedCategory ?? 'Seleccionar Categoría', style: TextStyle(color: _selectedCategory == null ? darkSecondaryTextColor : darkPrimaryTextColor, fontSize: 16)),
        trailing: const Icon(Icons.arrow_drop_down_rounded, color: accentColorGreen, size: 28),
        onTap: _showCategoryPicker,
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      decoration: BoxDecoration(color: darkCardBackground.withAlpha(100), borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.calendar_today_rounded, color: darkSecondaryTextColor),
        title: Text('Fecha: ${DateFormat("dd/MM/yyyy").format(_selectedDate)}', style: const TextStyle(color: darkPrimaryTextColor, fontSize: 16)),
        trailing: const Icon(Icons.edit_calendar_outlined, color: accentColorGreen, size: 24),
        onTap: () => _selectDate(context),
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
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: accentColorRed)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: accentColorRed, width: 1.5)),
    );
  }
}
