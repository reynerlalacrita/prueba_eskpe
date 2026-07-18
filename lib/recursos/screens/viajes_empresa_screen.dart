import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prueba_eskpe/recursos/screens/solicitudes_viaje_screen.dart';
import 'package:prueba_eskpe/recursos/screens/editar_viaje_screen.dart';

class ViajesEmpresaScreen extends StatelessWidget {
  const ViajesEmpresaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Mis Viajes Publicados"), backgroundColor: const Color(0xFF1E2A4F)),
        body: const Center(child: Text("Inicia sesión para ver tus viajes.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text("Mis Viajes Publicados", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E2A4F),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('viajes')
            .where('empresaId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1E2A4F)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final viajes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: viajes.length,
            itemBuilder: (context, index) {
              final data = viajes[index].data() as Map<String, dynamic>;
              return _buildTarjetaViaje(context, viajes[index].id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_boat_filled_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          const Text(
            "No tienes viajes publicados",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text(
            "Agrega un nuevo viaje para que los usuarios puedan reservarlo.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaViaje(BuildContext context, String viajeId, Map<String, dynamic> data) {
    String destinoId = data['destinoId'] ?? '';

    if (destinoId.isEmpty) {
      return _tarjetaContenido(context, viajeId, data, "Destino Desconocido", data['rutaAsset'] ?? '');
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('destinos').doc(destinoId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 120,
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
        
        return _tarjetaContenido(context, viajeId, data, nombre, ruta);
      },
    );
  }

  Widget _tarjetaContenido(BuildContext context, String viajeId, Map<String, dynamic> data, String nombreDestino, String rutaAsset) {
    String fechaStr = 'Fecha no definida';
    if (data['fecha'] != null) {
      final dt = (data['fecha'] as Timestamp).toDate();
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SolicitudesViajeScreen(
              viajeId: viajeId,
              nombreViaje: nombreDestino,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
              child: Image.asset(
                rutaAsset.isNotEmpty 
                    ? rutaAsset 
                    : 'assets/placeholder_playa.jpg',
                width: 100,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            nombreDestino,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E2A4F)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditarViajeScreen(viajeId: viajeId, datosViaje: data),
                              ),
                            );
                          },
                          child: const Icon(Icons.edit, color: Colors.grey, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(fechaStr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(width: 15),
                        const Icon(Icons.attach_money, size: 14, color: Color(0xFFB8860B)),
                        Text(precioStr, style: const TextStyle(color: Color(0xFFB8860B), fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Disponibles:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text("${data['puestosDisponibles'] ?? 0}/${data['puestosTotales'] ?? 0}", 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A3AFF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Text("Ver solicitudes", style: TextStyle(color: Color(0xFF4A3AFF), fontSize: 12, fontWeight: FontWeight.bold)),
                              SizedBox(width: 5),
                              Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF4A3AFF)),
                            ],
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
