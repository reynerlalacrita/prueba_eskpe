//todos los viajes prontos a salir
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba_eskpe/recursos/colores.dart';
import 'package:prueba_eskpe/recursos/screens/usuarios_screen/reservas_screen.dart';

class ListaViajesScreen extends StatelessWidget {
  const ListaViajesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Todos los Viajes",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.azuleskpe,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: AppColors.blancofondo,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('viajes')
            .where(
              'fecha',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                ),
              ),
            )
            .snapshots(),
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
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _buildTarjetaViaje(context, doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildTarjetaViaje(
    BuildContext context,
    String viajeId,
    Map<String, dynamic> data,
  ) {
    String destinoId = data['destinoId'] ?? '';

    if (destinoId.isEmpty) {
      return _tarjetaContenido(
        context,
        viajeId,
        data,
        "Destino Desconocido",
        data['rutaAsset'] ?? '',
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
            height: 140,
            margin: const EdgeInsets.only(bottom: 15),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E2A4F)),
            ),
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

  Widget _tarjetaContenido(
    BuildContext context,
    String viajeId,
    Map<String, dynamic> data,
    String nombreDestino,
    String rutaAsset,
  ) {
    String fechaStr = 'Fecha no disponible';
    if (data['fecha'] != null) {
      final Timestamp timestamp = data['fecha'] as Timestamp;
      final DateTime dt = timestamp.toDate();
      fechaStr = "${dt.day}/${dt.month}/${dt.year}";
    }

    String precioStr = "\$0";
    if (data['planes'] != null && (data['planes'] as List).isNotEmpty) {
      List planes = data['planes'];
      double minPrice = planes
          .map((p) => double.tryParse(p['precio']?.toString() ?? '0') ?? 0.0)
          .reduce((a, b) => a < b ? a : b);
      precioStr =
          "Desde \$${minPrice.toStringAsFixed(minPrice.truncateToDouble() == minPrice ? 0 : 2)}";
    } else {
      String precio =
          data['precioPorPuesto']?.toString() ??
          data['precio']?.toString() ??
          '0';
      precioStr = "\$$precio";
    }

    String empresaNombre =
        data['empresaNombre'] ?? data['empresa'] ?? 'Agencia de Viajes';
    String puntoSalida = data['puntoSalida'] ?? 'No especificado';
    String horaSalida = data['horaSalida'] ?? 'No especificada';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ReservarViajeScreen(viajeId: viajeId, datosViaje: data),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(15),
                ),
                child: _buildImagenViaje(
                  rutaAsset,
                  width: 110,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        empresaNombre,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        nombreDestino,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF1E2A4F),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppColors.azul1,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              fechaStr,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.azul3,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              horaSalida,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Color.fromARGB(255, 219, 3, 3),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              puntoSalida,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            precioStr,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB8860B),
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            "Ver detalles >",
                            style: TextStyle(
                              color: AppColors.azuleskpe,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagenViaje(
    String ruta, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (ruta.startsWith('http://') || ruta.startsWith('https://')) {
      return Image.network(
        ruta,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/sinfoto.jpg',
          width: width,
          height: height,
          fit: fit,
        ),
      );
    } else if (ruta.isNotEmpty) {
      return Image.asset(
        ruta,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/sinfoto.jpg',
          width: width,
          height: height,
          fit: fit,
        ),
      );
    } else {
      return Image.asset(
        'assets/sinfoto.jpg',
        width: width,
        height: height,
        fit: fit,
      );
    }
  }
}
