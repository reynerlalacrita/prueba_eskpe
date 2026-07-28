//todos los viajes prontos a salir
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListaViajesScreen extends StatelessWidget {
  const ListaViajesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Todos los Viajes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E2A4F),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F7),
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
              
              return _buildTarjetaViaje(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildTarjetaViaje(Map<String, dynamic> data) {
    String destinoId = data['destinoId'] ?? '';
    
    if (destinoId.isEmpty) {
      return _tarjetaContenido(data, "Destino Desconocido", data['rutaAsset'] ?? '');
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('destinos').doc(destinoId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 140,
            margin: const EdgeInsets.only(bottom: 15),
            child: const Center(child: CircularProgressIndicator(color: Color(0xFF1E2A4F))),
          );
        }

        String nombre = "Cargando...";
        String ruta = data['rutaAsset'] ?? '';
        
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.exists) {
            nombre = snapshot.data!['nombre'] ?? 'Destino Desconocido';
            String assetDestino = snapshot.data!['rutaAsset'] ?? '';
            if (assetDestino.isNotEmpty) ruta = assetDestino;
          } else {
            nombre = "Destino Desconocido";
          }
        }
        
        return _tarjetaContenido(data, nombre, ruta);
      },
    );
  }

  Widget _tarjetaContenido(Map<String, dynamic> data, String nombreDestino, String rutaAsset) {
    String fechaStr = 'Fecha no disponible';
    if (data['fecha'] != null) {
      final Timestamp timestamp = data['fecha'] as Timestamp;
      final DateTime dt = timestamp.toDate();
      fechaStr = "${dt.day}/${dt.month}/${dt.year}";
    }

    String precioStr = "\$0";
    if (data['planes'] != null && (data['planes'] as List).isNotEmpty) {
      List planes = data['planes'];
      double minPrice = planes.map((p) => double.tryParse(p['precio']?.toString() ?? '0') ?? 0.0).reduce((a, b) => a < b ? a : b);
      precioStr = "Desde \$${minPrice.toStringAsFixed(minPrice.truncateToDouble() == minPrice ? 0 : 2)}";
    } else {
      String precio = data['precioPorPuesto']?.toString() ?? data['precio']?.toString() ?? '0';
      precioStr = "\$$precio";
    }

    String empresaNombre = data['empresaNombre'] ?? data['empresa'] ?? 'Agencia de Viajes';

    return Container(
      height: 140,
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
              width: 120, height: 140, fit: BoxFit.cover),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(empresaNombre, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(nombreDestino, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E2A4F)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 5),
                      Expanded(child: Text(fechaStr, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  Text(precioStr, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB8860B), fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}