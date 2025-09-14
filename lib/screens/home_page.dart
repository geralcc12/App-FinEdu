import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Justo después de signOut, evita construir con user null
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final uid = user.uid;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('usuarios').doc(uid).get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        String titleText = user.email ?? 'Mis finanzas';
        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data();
          if (data != null && data['nombre'] != null && (data['nombre'] as String).isNotEmpty) {
            titleText = data['nombre'];
          }
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(titleText),
              actions: [
                IconButton(
                  tooltip: 'Cerrar sesión',
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    // No navegues: el StreamBuilder en main.dart redibuja AuthPage
                  },
                  icon: const Icon(Icons.logout),
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Ingresos'),
                  Tab(text: 'Gastos'),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                _TransactionTab(collection: 'ingresos', accent: Colors.green),
                _TransactionTab(collection: 'gastos', accent: Colors.red),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TransactionTab extends StatelessWidget {
  final String collection;
  final Color accent;
  const _TransactionTab({required this.collection, required this.accent});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final query = FirebaseFirestore.instance
        .collection(collection)
        .where('userId', isEqualTo: uid)
        .orderBy('fecha', descending: true);

    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            debugPrint('Error al cargar $collection: ${snap.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error al cargar $collection:\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            final emptyText = (collection == 'gastos') ? 'Sin gastos' : 'Sin ingresos';
            return Center(child: Text(emptyText));
          }

          final total = docs.fold<double>(
            0,
                (p, d) => p + ((d.data()['monto'] as num?)?.toDouble() ?? 0),
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total de $collection:', style: const TextStyle(fontSize: 16)),
                    Text(
                      'S/ ${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (context, i) {
                    final data = docs[i].data();
                    final fecha = (data['fecha'] as Timestamp?)?.toDate();
                    final descripcion = data['descripcion'] ?? '(sin descripción)';
                    final monto = (data['monto'] as num?)?.toStringAsFixed(2) ?? '0.00';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: accent.withOpacity(.15),
                        child: Icon(Icons.receipt_long, color: accent),
                      ),
                      title: Text(descripcion),
                      subtitle: Text(
                        fecha != null ? '${fecha.day}/${fecha.month}/${fecha.year}' : '',
                      ),
                      trailing: Text(
                        'S/ $monto',
                        style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                      ),
                      onLongPress: () async {
                        await docs[i].reference.delete();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Eliminado')));
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accent,
        onPressed: () => _showAddDialog(context, collection, accent),
        label: Text('Agregar ${collection.substring(0, collection.length - 1)}'),
        icon: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showAddDialog(BuildContext context, String collection, Color accent) {
    final montoCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nuevo ${collection.substring(0, collection.length - 1)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: montoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Monto (S/)'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      final monto = double.tryParse(
                        montoCtrl.text.replaceAll(',', '.'),
                      ) ??
                          0;
                      if (uid == null) return;
                      if (monto <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Ingresa un monto válido')),
                        );
                        return;
                      }
                      setState(() => saving = true);
                      try {
                        await FirebaseFirestore.instance.collection(collection).add({
                          'userId': uid,
                          'monto': monto,
                          'descripcion': descCtrl.text.trim(),
                          'fecha': FieldValue.serverTimestamp(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Error al guardar: $e')),
                        );
                      } finally {
                        if (ctx.mounted) setState(() => saving = false);
                      }
                    },
                    icon: saving
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.check),
                    label: Text(saving ? 'Guardando...' : 'Guardar'),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
