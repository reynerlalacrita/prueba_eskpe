import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba_eskpe/recursos/screens/reservas_screen.dart'; // Asegúrate de que este archivo tenga el widget 'ReservarViajeScreen'

class DestinoDetalleScreen extends StatelessWidget {
  final String nombre;
  final String destinoId;
  final String rutaAsset;

  const DestinoDetalleScreen({super.key, required this.nombre, required this.rutaAsset, required this.destinoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Encabezado con la imagen del destino
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E2A4F),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                ),
              ),
              background: Image.asset(
                rutaAsset.isNotEmpty ? rutaAsset : 'assets/placeholder_playa.jpg',
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.3),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),
          
          // Cuerpo con los viajes de Firebase
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Viajes Disponibles",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E2A4F)),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Explora las opciones de las empresas para $nombre",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Lista de viajes desde Firebase
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('viajes')
                .where('destinoId', isEqualTo: destinoId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF1E2A4F))),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        children: [
                          Icon(Icons.sailing_outlined, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 15),
                          const Text(
                            "Aún no hay viajes programados para este destino.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    // Convertimos la fecha de forma segura
                    String fechaTexto = 'Fechas por definir';
                    if (data['fecha'] != null) {
                      final Timestamp timestamp = data['fecha'] as Timestamp;
                      final DateTime fechaDateTime = timestamp.toDate();
                      fechaTexto = "${fechaDateTime.day}/${fechaDateTime.month}/${fechaDateTime.year}";
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

                    // 🛠️ SOLUCIÓN: Pasamos el context, el doc.id y el mapa de datos completo
                    return _buildTarjetaViaje(
                      context,
                      doc.id, 
                      data,
                      data['empresaNombre'] ?? data['empresa'] ?? 'Empresa', // Compatible con ambos campos
                      precioStr,
                      fechaTexto,
                      data['rutaAsset'] ?? '',
                    );
                  },
                  childCount: docs.length,
                ),
              );
            },
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // 🛠️ SOLUCIÓN: Agregamos context, viajeId y datosViaje a los parámetros de la tarjeta
  Widget _buildTarjetaViaje(
    BuildContext context, 
    String viajeId, 
    Map<String, dynamic> datosViaje, 
    String empresa, 
    String precioStr, 
    String fecha, 
    String rutaAsset
  ) {
    return Container(
      height: 110,
      margin: const EdgeInsets.only(bottom: 15, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 110,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
              image: DecorationImage(
                image: AssetImage(rutaAsset.isNotEmpty ? rutaAsset : 'assets/placeholder_playa.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(empresa, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 5),
                      Text(precioStr, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB8860B), fontSize: 16)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Color(0xFFB8860B)),
                      const SizedBox(width: 5),
                      Text(fecha, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // TODO: Navegar a la futura screen de detalles del viaje
                        },
                        child: const Text(
                          "Ver detalles >", 
                          style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}