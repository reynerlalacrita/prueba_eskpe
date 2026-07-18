import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba_eskpe/recursos/utils.dart';
import 'package:prueba_eskpe/recursos/screens/reservas_screen.dart';

class EmpresaDetalleScreen extends StatelessWidget {
  final String nombreEmpresa;
  final String rutaAsset;
  final String telefonoEmpresa;
  final String destinoId;

  const EmpresaDetalleScreen({
    super.key,
    required this.nombreEmpresa,
    required this.rutaAsset,
    required this.telefonoEmpresa,
    required this.destinoId,
  });

  @override
  Widget build(BuildContext context) {
    // Definimos si el teléfono es válido (no vacío y distinto al número que quieres evitar)
    final bool esTelefonoValido =
        telefonoEmpresa.isNotEmpty && telefonoEmpresa != "584121234567";

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
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
                rutaAsset.isNotEmpty
                    ? rutaAsset
                    : 'assets/placeholder_playa.jpg',
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.4),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botón inteligente que se bloquea si el número no es válido
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: esTelefonoValido
                          ? () =>
                                AppUtils.abrirWhatsApp(
                                  telefonoEmpresa,
                                  nombreEmpresa,
                                ) // <--- Ahora pasas ambos
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Número de WhatsApp no disponible.",
                                  ),
                                ),
                              );
                            },
                      icon: const Icon(Icons.message, color: Colors.white),
                      label: const Text(
                        "Consultar por WhatsApp",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: esTelefonoValido
                            ? const Color(0xFF25D366)
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "Viajes Programados",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2A4F),
                    ),
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

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('viajes')
                .where('empresaId', isEqualTo: destinoId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Text(
                        "$nombreEmpresa aún no ha publicado viajes.",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;

                  dynamic rawFecha = data['fecha'];
                  String fechaTexto = "Sin fecha";
                  if (rawFecha is Timestamp) {
                    DateTime date = rawFecha.toDate();
                    fechaTexto = "${date.day}/${date.month}/${date.year}";
                  } else if (rawFecha is String) {
                    fechaTexto = rawFecha;
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

                  return _buildTarjetaViaje(
                    context,
                    docs[index].id,
                    data,
                    data['destinoId'] ?? '',
                    precioStr,
                    fechaTexto,
                    data['rutaAsset'] ?? '',
                  );
                }, childCount: docs.length),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildTarjetaViaje(
    BuildContext context,
    String viajeId,
    Map<String, dynamic> datosViaje,
    String destinoId,
    String precio,
    String fecha,
    String rutaAssetFallback,
  ) {
    if (destinoId.isEmpty) {
      return _tarjetaContenido(
        context,
        viajeId,
        datosViaje,
        "Destino Desconocido",
        precio,
        fecha,
        rutaAssetFallback,
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('destinos')
          .doc(destinoId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 110,
            margin: const EdgeInsets.only(bottom: 15, left: 20, right: 20),
            child: const Center(child: CircularProgressIndicator(color: Color(0xFF1E2A4F))),
          );
        }

        String nombre = "Cargando...";
        String ruta = rutaAssetFallback;
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.exists) {
            nombre = snapshot.data!['nombre'] ?? 'Destino Desconocido';
            String assetDestino = snapshot.data!['rutaAsset'] ?? '';
            if (assetDestino.isNotEmpty) ruta = assetDestino;
          } else {
            nombre = "Destino Desconocido";
          }
        }
        return _tarjetaContenido(
          context,
          viajeId,
          datosViaje,
          nombre,
          precio,
          fecha,
          ruta,
        );
      },
    );
  }

  Widget _tarjetaContenido(
    BuildContext context,
    String viajeId,
    Map<String, dynamic> datosViaje,
    String nombreDestino,
    String precioStr,
    String fecha,
    String rutaAsset,
  ) {
    return Container(
      height: 110,
      margin: const EdgeInsets.only(bottom: 15, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 110,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(15),
              ),
              image: DecorationImage(
                image: AssetImage(
                  rutaAsset.isNotEmpty
                      ? rutaAsset
                      : 'assets/placeholder_playa.jpg',
                ),
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
                        child: Text(
                          nombreDestino,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Text(
                        precioStr,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB8860B), fontSize: 16),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Color(0xFFB8860B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        fecha.isEmpty ? "Fechas por definir" : fecha,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
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
          ),
        ],
      ),
    );
  }
}
