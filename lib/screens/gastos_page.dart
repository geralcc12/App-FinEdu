// lib/screens/gastos_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Colores fijos para el tema oscuro (copiados de home_page.dart para este ejemplo)
// Idealmente, estos estarían en un archivo de tema compartido.
const Color darkScaffoldBackground = Color(0xFF121212);
const Color darkCardBackground = Color(0xFF1E1E1E);
const Color darkPrimaryTextColor = Colors.white;
const Color darkSecondaryTextColor = Color(0xFFB0B0B0);
const Color accentColorGreen = Color(0xFF00D19A); // Usado para el progress indicator
const Color accentColorRed = Colors.redAccent; // Usado para el texto de monto de gasto

class GastosPage extends StatelessWidget {
  const GastosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: darkScaffoldBackground,
        appBar: AppBar(
          title: const Text('Mis Gastos', style: TextStyle(color: darkPrimaryTextColor)),
          backgroundColor: darkCardBackground,
          iconTheme: const IconThemeData(color: darkPrimaryTextColor),
        ),
        body: const Center(
          child: Text(
            'Usuario no autenticado. Por favor, inicie sesión.',
            style: TextStyle(color: darkSecondaryTextColor),
          ),
        ),
      );
    }

    final uid = user.uid;

    return Scaffold(
      backgroundColor: darkScaffoldBackground,
      appBar: AppBar(
        title: const Text('Mis Gastos', style: TextStyle(color: darkPrimaryTextColor)),
        backgroundColor: darkCardBackground,
        iconTheme: const IconThemeData(color: darkPrimaryTextColor),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('gastos')
            .where('userId', isEqualTo: uid)
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentColorGreen));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar los gastos: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No hay gastos registrados.',
                style: TextStyle(color: darkSecondaryTextColor),
              ),
            );
          }

          final gastosDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: gastosDocs.length,
            itemBuilder: (context, index) {
              final gastoData = gastosDocs[index].data();
              final monto = (gastoData['monto'] as num?)?.toDouble() ?? 0.0;
              final descripcion = gastoData['descripcion'] as String? ?? 'Sin descripción';
              // Formatear la fecha de forma segura
              String fechaFormateada = 'Fecha no disponible';
              if (gastoData['fecha'] is Timestamp) {
                final fecha = (gastoData['fecha'] as Timestamp).toDate();
                fechaFormateada = '${fecha.day}/${fecha.month}/${fecha.year}';
              }
              
              return Card(
                color: darkCardBackground,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  title: Text(
                    descripcion,
                    style: const TextStyle(color: darkPrimaryTextColor, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    fechaFormateada,
                    style: const TextStyle(color: darkSecondaryTextColor),
                  ),
                  trailing: Text(
                    '- S/ ${monto.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: accentColorRed,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  // Podrías añadir onTap aquí para editar/eliminar si la lógica de _UnifiedTransaction y _showAddTransactionModal se generaliza
                  // onTap: () {
                  //   // Lógica para editar/ver detalle del gasto
                  //   // Podrías reutilizar _showAddTransactionModal si lo adaptas o pasas los datos necesarios
                  // },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
