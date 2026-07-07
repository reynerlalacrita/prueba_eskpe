import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmpresaDetalleScreen extends StatelessWidget {
  final String nombreEmpresa;
  final String rutaAsset;

  const EmpresaDetalleScreen({super.key, required this.nombreEmpresa, required this.rutaAsset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Encabezado con la imagen (logo de la empresa o foto representativa)
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E2A4F),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                nombreEmpresa,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                ),
              ),
              background: Image.asset(
                rutaAsset.isNotEmpty ? rutaAsset : 'assets/placeholder.png',
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.4), // Filtro un poco más oscuro
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),
          
          // Texto descriptivo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Viajes Programados",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E2A4F)),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Descubre todo lo que $nombreEmpresa tiene para ti",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Lista de viajes desde Firebase FILTRADOS POR EMPRESA
          StreamBuilder<QuerySnapshot>(
            // AQUÍ LA MAGIA: filtramos usando 'empresa' en lugar de 'nombre'
            stream: FirebaseFirestore.instance
                .collection('viajes')
                .where('empresa', isEqualTo: nombreEmpresa) 
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
                          Icon(Icons.directions_boat_filled_outlined, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 15),
                          Text(
                            "$nombreEmpresa aún no ha publicado viajes.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
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
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildTarjetaViaje(
                      data['nombre'] ?? 'Destino Desconocido', // Ahora mostramos el nombre del destino
                      data['precio']?.toString() ?? '0',
                      data['fecha'] ?? '',
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

  // Tarjeta de viaje para EmpresaDetalleScreen
  Widget _buildTarjetaViaje(String destino, String precio, String fecha, String rutaAsset) {
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
                      Text(destino, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('\$$precio', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB8860B), fontSize: 16)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Color(0xFFB8860B)),
                      const SizedBox(width: 5),
                      Text(fecha.isEmpty ? "Fechas por definir" : fecha, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2A4F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text("Reservar", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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