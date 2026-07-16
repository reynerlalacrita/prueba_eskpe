//todos los viajes prontos a salir
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListaProntosScreen extends StatelessWidget {
  const ListaProntosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Viajes Prontos a Salir"),
        backgroundColor: const Color(0xFF1E2A4F),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('viajes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay viajes próximos"));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              
              // Formatear la fecha
              String fechaTexto = 'Fecha no disponible';
              if (data['fecha'] != null) {
                final Timestamp timestamp = data['fecha'] as Timestamp;
                final DateTime dt = timestamp.toDate();
                fechaTexto = "${dt.day}/${dt.month}/${dt.year}";
              }

              return _buildTarjetaViajeCompleta(
                data['nombre'] ?? 'Sin nombre',
                data['precio']?.toString() ?? '0',
                fechaTexto,
                data['rutaAsset'] ?? ''
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTarjetaViajeCompleta(String destino, String precio, String fecha, String rutaAsset) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
            child: Image.asset(rutaAsset.isNotEmpty ? rutaAsset : 'assets/playa1.jpg', 
              width: 120, height: 120, fit: BoxFit.cover),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(destino, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 5),
                  Text("Fecha: $fecha", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text("Precio: \$$precio", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB8860B))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}