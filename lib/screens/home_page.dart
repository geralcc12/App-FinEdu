// lib/screens/home_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para TextInputFormatter
import 'dart:math'; // Para max()

// Colores fijos para el tema oscuro
const Color darkScaffoldBackground = Color(0xFF121212);
const Color darkCardBackground = Color(0xFF1E1E1E); // Un poco más claro que el scaffold
const Color darkModalBackground = Color(0xFF2C2C2C); // Para el modal
const Color darkPrimaryTextColor = Colors.white;
const Color darkSecondaryTextColor = Color(0xFFB0B0B0); // Gris claro
const Color darkHintTextColor = Color(0xFF808080); // Gris más oscuro para hints
const Color darkDividerColor = Color(0xFF3A3A3A);
const Color darkInputBorderColor = Color(0xFF505050);
const Color accentColorGreen = Color(0xFF00D19A); // Verde acento principal
const Color accentColorRed = Colors.redAccent;

// Clase auxiliar para transacciones unificadas
class _UnifiedTransaction {
  final Map<String, dynamic> data;
  final String type; // 'ingreso' o 'gasto'
  final DocumentReference reference;
  final Timestamp timestamp; 

  _UnifiedTransaction({
    required this.data,
    required this.type,
    required this.reference,
    required this.timestamp,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;

  final _modalFormKey = GlobalKey<FormState>();
  final _modalDescriptionController = TextEditingController();
  final _modalAmountController = TextEditingController();
  String _modalSelectedType = 'ingreso';
  bool _isSavingTransaction = false;
  _UnifiedTransaction? _editingTransaction;

  @override
  void dispose() {
    _modalDescriptionController.dispose();
    _modalAmountController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction({_UnifiedTransaction? originalTransaction}) async {
    if (!_modalFormKey.currentState!.validate()) {
      throw Exception("Formulario inválido");
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuario no autenticado");

    final description = _modalDescriptionController.text.trim();
    final amount = double.tryParse(_modalAmountController.text.trim());

    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, ingresa un monto válido.'), backgroundColor: Colors.redAccent),
        );
      }
      throw Exception("Monto inválido");
    }

    final transactionData = {
      'userId': user.uid,
      'descripcion': description,
      'monto': amount,
      'fecha': Timestamp.now(),
    };

    try {
      String message;
      if (originalTransaction != null) {
        final newCollectionName = _modalSelectedType == 'ingreso' ? 'ingresos' : 'gastos';
        final originalCollectionName = originalTransaction.type == 'ingreso' ? 'ingresos' : 'gastos';

        if (newCollectionName != originalCollectionName) {
          await FirebaseFirestore.instance.collection(newCollectionName).add(transactionData);
          await originalTransaction.reference.delete();
        } else {
          await originalTransaction.reference.update(transactionData);
        }
        message = 'Transacción actualizada exitosamente.';
      } else {
        final collectionName = _modalSelectedType == 'ingreso' ? 'ingresos' : 'gastos';
        await FirebaseFirestore.instance.collection(collectionName).add(transactionData);
        message = '${_modalSelectedType == 'ingreso' ? "Ingreso" : "Gasto"} guardado exitosamente.';
      }
      
      if (mounted) {
        Navigator.pop(context); // Cierra el modal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
      _modalDescriptionController.clear();
      _modalAmountController.clear();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
      throw e; 
    }
  }

  void _showAddTransactionModal({_UnifiedTransaction? transactionToEdit}) {
    _editingTransaction = transactionToEdit;

    if (transactionToEdit != null) {
      _modalDescriptionController.text = transactionToEdit.data['descripcion'] ?? '';
      _modalAmountController.text = (transactionToEdit.data['monto'] as num?)?.toString() ?? '';
      _modalSelectedType = transactionToEdit.type;
    } else {
      _modalDescriptionController.clear();
      _modalAmountController.clear();
      _modalSelectedType = 'ingreso';
    }
    _isSavingTransaction = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: darkModalBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
              ),
              child: Form(
                key: _modalFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        transactionToEdit == null ? 'Nueva Transacción' : 'Editar Transacción',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: darkPrimaryTextColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ToggleButtons(
                          isSelected: [_modalSelectedType == 'ingreso', _modalSelectedType == 'gasto'],
                          onPressed: (index) {
                            modalSetState(() {
                              _modalSelectedType = index == 0 ? 'ingreso' : 'gasto';
                            });
                          },
                          borderRadius: BorderRadius.circular(8.0),
                          selectedColor: Colors.black87, 
                          color: darkPrimaryTextColor,       
                          fillColor: _modalSelectedType == 'ingreso' ? Colors.green.shade400 : Colors.red.shade300,
                          borderColor: darkInputBorderColor,
                          selectedBorderColor: _modalSelectedType == 'ingreso' ? Colors.green.shade700 : Colors.red.shade700,
                          constraints: const BoxConstraints(minHeight: 40.0),
                          children: const <Widget>[
                            Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('Ingreso')),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('Gasto')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _modalDescriptionController,
                        style: const TextStyle(color: darkPrimaryTextColor),
                        decoration: InputDecoration(
                          labelText: 'Descripción',
                          labelStyle: const TextStyle(color: darkSecondaryTextColor),
                          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: darkInputBorderColor)),
                          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: accentColorGreen)),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Por favor, ingresa una descripción.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _modalAmountController,
                        style: const TextStyle(color: darkPrimaryTextColor),
                        decoration: InputDecoration(
                          labelText: 'Monto',
                          labelStyle: const TextStyle(color: darkSecondaryTextColor),
                          prefixText: 'S/ ',
                          prefixStyle: const TextStyle(color: darkSecondaryTextColor),
                          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: darkInputBorderColor)),
                          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: accentColorGreen)),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Por favor, ingresa un monto.';
                          if (double.tryParse(value.trim()) == null || double.parse(value.trim()) <= 0) return 'Ingresa un monto válido y mayor a cero.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isSavingTransaction ? null : () async {
                          if (_modalFormKey.currentState!.validate()) {
                            modalSetState(() { _isSavingTransaction = true; });
                            try {
                              await _saveTransaction(originalTransaction: _editingTransaction);
                            } catch (e) {
                              // Errores ya se muestran en SnackBar desde _saveTransaction
                            } finally {
                              if(mounted) modalSetState(() { _isSavingTransaction = false; });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: accentColorGreen,
                          foregroundColor: Colors.black87, 
                        ),
                        child: _isSavingTransaction
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.black87)))
                            : Text(transactionToEdit == null ? 'Guardar Transacción' : 'Actualizar Transacción'),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(backgroundColor: darkScaffoldBackground, body: Center(child: CircularProgressIndicator(color: accentColorGreen)));
    }
    final uid = user.uid;

    final ingresosStream = FirebaseFirestore.instance.collection('ingresos').where('userId', isEqualTo: uid).snapshots();
    final gastosStream = FirebaseFirestore.instance.collection('gastos').where('userId', isEqualTo: uid).snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        String displayName = user.email?.split('@').first ?? 'Usuario';
        if (userSnapshot.connectionState == ConnectionState.active && userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data();
          displayName = userData?['nombre'] as String? ?? displayName;
        }

        return Scaffold(
          backgroundColor: darkScaffoldBackground,
          body: SafeArea(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: ingresosStream,
              builder: (context, snapshotIngresos) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: gastosStream,
                  builder: (context, snapshotGastos) {
                    if (userSnapshot.connectionState == ConnectionState.waiting ||
                        snapshotIngresos.connectionState == ConnectionState.waiting ||
                        snapshotGastos.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: accentColorGreen));
                    }
                    if (snapshotIngresos.hasError || snapshotGastos.hasError) {
                      return Center(child: Text('Error al cargar transacciones.', style: TextStyle(color: Colors.redAccent)));
                    }

                    final ingresosDocs = snapshotIngresos.data?.docs ?? [];
                    final gastosDocs = snapshotGastos.data?.docs ?? [];

                    final totalIngresos = ingresosDocs.fold<double>(0, (p, d) => p + ((d.data()['monto'] as num?)?.toDouble() ?? 0));
                    final totalGastos = gastosDocs.fold<double>(0, (p, d) => p + ((d.data()['monto'] as num?)?.toDouble() ?? 0));
                    final balance = totalIngresos - totalGastos;

                    List<_UnifiedTransaction> allTransactions = [];
                    ingresosDocs.forEach((doc) => allTransactions.add(_UnifiedTransaction(data: doc.data(), type: 'ingreso', reference: doc.reference, timestamp: (doc.data()['fecha'] as Timestamp?) ?? Timestamp.now())));
                    gastosDocs.forEach((doc) => allTransactions.add(_UnifiedTransaction(data: doc.data(), type: 'gasto', reference: doc.reference, timestamp: (doc.data()['fecha'] as Timestamp?) ?? Timestamp.now())));
                    allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                    int numberOfTransactions = allTransactions.length;
                    int daysWithActivity = 1;
                    if (allTransactions.isNotEmpty) {
                      Timestamp oldestTimestamp = allTransactions.last.timestamp;
                      DateTime oldestDate = oldestTimestamp.toDate();
                      DateTime today = DateTime.now();
                      DateTime oldestDateNormalized = DateTime(oldestDate.year, oldestDate.month, oldestDate.day);
                      DateTime todayNormalized = DateTime(today.year, today.month, today.day);
                      daysWithActivity = max(1, todayNormalized.difference(oldestDateNormalized).inDays + 1);
                    }

                    return Column(
                      children: [
                        _HeaderBlock(
                          nameOrEmail: displayName,
                          totalIngresos: totalIngresos, 
                          totalGastos: totalGastos,
                          balance: balance, // Pasar balance
                          numberOfTransactions: numberOfTransactions, // Pasar número de transacciones
                          daysWithActivity: daysWithActivity, // Pasar días con actividad
                          onLogout: () async => FirebaseAuth.instance.signOut(),
                        ),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            'Todas las Transacciones',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkPrimaryTextColor),
                          ),
                        ),
                        Expanded(
                          child: allTransactions.isEmpty
                              ? const Center(child: Text('No hay transacciones.', style: TextStyle(color: darkSecondaryTextColor)))
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  itemCount: allTransactions.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16, color: darkDividerColor),
                                  itemBuilder: (context, index) {
                                    final transaction = allTransactions[index];
                                    final data = transaction.data;
                                    final itemAccentColor = transaction.type == 'ingreso' ? Colors.green.shade400 : Colors.red.shade300;
                                    final fecha = (data['fecha'] as Timestamp?)?.toDate();
                                    final descripcion = '${data['descripcion'] ?? '(sin descripción)'}';
                                    final monto = (data['monto'] as num?)?.toDouble() ?? 0.0;

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                      leading: CircleAvatar(
                                        backgroundColor: itemAccentColor.withAlpha(40), 
                                        child: Icon(
                                          transaction.type == 'ingreso' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                          color: itemAccentColor,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(descripcion, style: const TextStyle(fontWeight: FontWeight.w600, color: darkPrimaryTextColor)),
                                      subtitle: Text(
                                        fecha != null ? '${fecha.day}/${fecha.month}/${fecha.year}' : 'Fecha desconocida',
                                        style: const TextStyle(color: darkSecondaryTextColor),
                                      ),
                                      trailing: Text(
                                        'S/ ${monto.toStringAsFixed(2)}',
                                        style: TextStyle(color: itemAccentColor, fontWeight: FontWeight.w700, fontSize: 15),
                                      ),
                                      onLongPress: () async {
                                        final action = await showDialog<String>(
                                          context: context,
                                          builder: (BuildContext dialogContext) {
                                            return AlertDialog(
                                              backgroundColor: darkModalBackground,
                                              title: const Text('Acción Requerida', style: TextStyle(color: darkPrimaryTextColor, fontWeight: FontWeight.bold)),
                                              content: const Text('¿Qué deseas hacer con esta transacción?', style: TextStyle(color: darkSecondaryTextColor)),
                                              actions: <Widget>[
                                                TextButton(
                                                  child: const Text('Cancelar', style: TextStyle(color: darkSecondaryTextColor)),
                                                  onPressed: () => Navigator.of(dialogContext).pop('cancel'),
                                                ),
                                                TextButton(
                                                  child: const Text('Editar', style: TextStyle(color: accentColorGreen)),
                                                  onPressed: () => Navigator.of(dialogContext).pop('edit'),
                                                ),
                                                TextButton(
                                                  child: const Text('Eliminar', style: TextStyle(color: accentColorRed)),
                                                  onPressed: () => Navigator.of(dialogContext).pop('delete'),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (action == 'edit' && mounted) {
                                          _showAddTransactionModal(transactionToEdit: transaction);
                                        } else if (action == 'delete' && mounted) {
                                          final confirmDelete = await showDialog<bool>(
                                            context: context,
                                            builder: (BuildContext confirmDialogContext) {
                                              return AlertDialog(
                                                backgroundColor: darkModalBackground,
                                                title: const Text('Confirmar Eliminación', style: TextStyle(color: darkPrimaryTextColor, fontWeight: FontWeight.bold)),
                                                content: const Text('¿Seguro que quieres eliminar esta transacción?', style: TextStyle(color: darkSecondaryTextColor)),
                                                actions: <Widget>[
                                                  TextButton(
                                                    child: const Text('No', style: TextStyle(color: darkSecondaryTextColor)),
                                                    onPressed: () => Navigator.of(confirmDialogContext).pop(false),
                                                  ),
                                                  TextButton(
                                                    child: const Text('Sí, Eliminar', style: TextStyle(color: accentColorRed, fontWeight: FontWeight.bold)),
                                                    onPressed: () => Navigator.of(confirmDialogContext).pop(true),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          if (confirmDelete == true && mounted) {
                                            await transaction.reference.delete();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Transacción eliminada'), backgroundColor: Colors.orangeAccent),
                                            );
                                          }
                                        }
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BottomNavigationBar(
                currentIndex: _navIndex,
                onTap: (i) {
                  if (i == 1) {
                    _showAddTransactionModal(); 
                  } else {
                    setState(() => _navIndex = i);
                  }
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: darkCardBackground, 
                selectedItemColor: accentColorGreen,
                unselectedItemColor: Colors.grey[600],
                showSelectedLabels: false,
                showUnselectedLabels: false,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline_rounded), label: 'Add'),
                  BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock({
    required this.nameOrEmail,
    required this.totalIngresos,
    required this.totalGastos,
    required this.balance,
    required this.numberOfTransactions,
    required this.daysWithActivity,
    required this.onLogout,
  });

  final String nameOrEmail;
  final double totalIngresos;
  final double totalGastos;
  final double balance;
  final int numberOfTransactions;
  final int daysWithActivity;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final double progressBarValue = totalIngresos > 0 ? (balance / totalIngresos).clamp(0.0, 1.0) : 0.0;
    final int progressPercentage = (progressBarValue * 100).round();
    String balanceStatusText;
    if (totalIngresos == 0 && totalGastos == 0) {
      balanceStatusText = 'Aún no hay transacciones.';
    } else if (balance >= 0) {
      balanceStatusText = 'Balance positivo de S/ ${_money(balance.abs())}.';
    } else {
      balanceStatusText = 'Balance negativo de S/ ${_money(balance.abs())}.';
    }

    final double averageDailyExpense = (daysWithActivity > 0 && totalGastos > 0) ? totalGastos / daysWithActivity : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: const [Color(0xFF00D19A), Color(0xFF02B97E)], 
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Hola, $nameOrEmail',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87) 
                    ),
              ),
              IconButton(
                onPressed: onLogout,
                icon: const Icon(Icons.logout, color: Colors.black87), 
                tooltip: 'Cerrar sesión',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  title: 'Ingresos Totales',
                  value: totalIngresos,
                  valueColor: const Color(0xFF00695C), 
                  bg: Colors.white.withAlpha(230), 
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  title: 'Gastos Totales',
                  value: totalGastos, 
                  valueColor: const Color(0xFFC62828), 
                  bg: Colors.white.withAlpha(230),  
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: Colors.white.withAlpha(210),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 48, 
                        child: Text(
                          '$progressPercentage%',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: LinearProgressIndicator(
                            value: progressBarValue,
                            minHeight: 14,
                            backgroundColor: Colors.black.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(progressBarValue >=0 ? Color(0xFF02B97E) : accentColorRed ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('de S/ ${_money(totalIngresos)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(balanceStatusText,
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: darkCardBackground, 
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _ColumnStat(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Balance Actual',
                    value: 'S/ ${_money(balance)}',
                    color: balance >= 0 ? accentColorGreen : accentColorRed,
                  ),
                ),
                _DividerV(), 
                Expanded(
                  child: _ColumnStat(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Nro. Transacciones',
                    value: numberOfTransactions.toString(),
                    color: Colors.blueAccent,
                  ),
                ),
                _DividerV(),
                Expanded(
                  child: _ColumnStat(
                    icon: Icons.today_rounded, // Usar Icons.local_atm_rounded o Icons.calendar_today_rounded
                    title: 'Gasto Prom. Diario',
                    value: 'S/ ${_money(averageDailyExpense)}',
                    color: Colors.orangeAccent,
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

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.valueColor,
    required this.bg,
  });

  final String title;
  final double value;
  final Color valueColor;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(title, style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.7), fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 8),
          Text(
            'S/ ${_money(value.abs())}', 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _ColumnStat extends StatelessWidget {
  const _ColumnStat({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withAlpha(40), 
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontSize: 11, color: darkSecondaryTextColor, height: 1.3), textAlign: TextAlign.start,),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _DividerV extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: darkDividerColor, 
    );
  }
}

String _money(double v) {
  // Asegurarse de que no se pase NaN o Infinito a toStringAsFixed
  if (v.isNaN || v.isInfinite) {
    return '0.00';
  }
  final s = v.abs().toStringAsFixed(2);
  final withSep = s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
  return withSep;
}
