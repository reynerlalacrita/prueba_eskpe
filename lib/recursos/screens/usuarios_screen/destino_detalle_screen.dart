import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba_eskpe/recursos/colores.dart';
import 'package:prueba_eskpe/recursos/screens/usuarios_screen/reservas_screen.dart';

class DestinoDetalleScreen extends StatefulWidget {
  final String nombre;
  final String destinoId;
  final String rutaAsset;

  const DestinoDetalleScreen({
    super.key,
    required this.nombre,
    required this.rutaAsset,
    required this.destinoId,
  });

  @override
  State<DestinoDetalleScreen> createState() => _DestinoDetalleScreenState();
}

class _DestinoDetalleScreenState extends State<DestinoDetalleScreen> {
  String _destinoIdEfectivo = '';
  bool _cargandoId = false;

  @override
  void initState() {
    super.initState();
    _destinoIdEfectivo = widget.destinoId;
    if (_destinoIdEfectivo.isEmpty) {
      _resolverDestinoId();
    }
  }

  /// Resuelve asíncronamente el ID de destino en la colección [destinos]
  /// cuando el parámetro [destinoId] inicial es nulo o vacío.
  void _resolverDestinoId() async {
    setState(() => _cargandoId = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collectionGroup('destinos')
          .get();

      String targetNorm = _normalizar(widget.nombre);

      for (var doc in snap.docs) {
        final data = doc.data();
        String docNombre = _normalizar(data['nombre'] ?? '');
        if (docNombre == targetNorm ||
            docNombre.contains(targetNorm) ||
            targetNorm.contains(docNombre)) {
          if (mounted) {
            setState(() {
              _destinoIdEfectivo = doc.id;
              _cargandoId = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Error resolviendo destinoId: $e");
    }
    if (mounted) setState(() => _cargandoId = false);
  }

  String _normalizar(String str) {
    return str
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blancofondo,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.azuleskpe,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                ),
              ),
              background: widget.rutaAsset.startsWith('http')
                  ? Image.network(
                      widget.rutaAsset,
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(alpha: 0.3),
                      colorBlendMode: BlendMode.darken,
                    )
                  : Image.asset(
                      widget.rutaAsset.isNotEmpty ? widget.rutaAsset : 'assets/sinfoto.jpg',
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(alpha: 0.3),
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
                  const Text(
                    "Viajes Disponibles",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2A4F),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Explora las opciones de las empresas para ${widget.nombre}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          _cargandoId
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E2A4F)),
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('viajes')
                      .where('destinoId', isEqualTo: _destinoIdEfectivo)
                      .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E2A4F)),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.sailing_outlined,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
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
                delegate: SliverChildBuilderDelegate((context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  /// Formateo defensivo de fecha a partir de tipo [Timestamp].
                  String fechaTexto = 'Fechas por definir';
                  if (data['fecha'] != null) {
                    final Timestamp timestamp = data['fecha'] as Timestamp;
                    final DateTime fechaDateTime = timestamp.toDate();
                    fechaTexto =
                        "${fechaDateTime.day}/${fechaDateTime.month}/${fechaDateTime.year}";
                  }

                  String precioStr = "\$0";
                  if (data['planes'] != null &&
                      (data['planes'] as List).isNotEmpty) {
                    List planes = data['planes'];
                    double minPrice = planes
                        .map(
                          (p) =>
                              double.tryParse(p['precio']?.toString() ?? '0') ??
                              0.0,
                        )
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

                  // Carga la foto real de la empresa desde Firestore
                  final String empresaId = data['empresaId'] ?? '';
                  return FutureBuilder<DocumentSnapshot>(
                    future: empresaId.isNotEmpty
                        ? FirebaseFirestore.instance
                            .collection('usuarios')
                            .doc(empresaId)
                            .get()
                        : Future.value(null as DocumentSnapshot?),
                    builder: (context, snapEmpresa) {
                      String logoUrl = '';
                      if (snapEmpresa.connectionState == ConnectionState.waiting) {
                        logoUrl = 'loading';
                      } else {
                        try {
                          logoUrl = snapEmpresa.data?.get('fotoUrl') as String? ?? '';
                        } catch (e) {
                          logoUrl = '';
                        }
                        if (logoUrl.isEmpty) {
                          logoUrl = data['empresaLogoUrl'] ??
                              data['fotoUrl'] ??
                              data['logoUrl'] ??
                              data['rutaAsset'] ??
                              '';
                        }
                      }
                      return _buildTarjetaViaje(
                        context,
                        doc.id,
                        data,
                        data['empresaNombre'] ?? data['empresa'] ?? 'Empresa',
                        precioStr,
                        fechaTexto,
                        logoUrl,
                      );
                    },
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

  // 🛠️ SOLUCIÓN: Agregamos context, viajeId y datosViaje a los parámetros de la tarjeta
  Widget _buildTarjetaViaje(
    BuildContext context,
    String viajeId,
    Map<String, dynamic> datosViaje,
    String empresa,
    String precioStr,
    String fecha,
    String rutaAsset,
  ) {
    String puntoSalida = datosViaje['puntoSalida'] ?? 'No especificado';
    String horaSalida = datosViaje['horaSalida'] ?? 'No especificada';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ReservarViajeScreen(viajeId: viajeId, datosViaje: datosViaje),
          ),
        );
      },
      child: Container(
        height: 140,
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
            SizedBox(
              width: 110,
              height: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(15),
                ),
                child: rutaAsset == 'loading'
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1E2A4F),
                        ),
                      )
                    : (rutaAsset.startsWith('http://') ||
                            rutaAsset.startsWith('https://'))
                        ? Image.network(
                            rutaAsset,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF1E2A4F),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                                  'assets/sinfoto.jpg',
                                  fit: BoxFit.cover,
                                ),
                          )
                        : Image.asset('assets/sinfoto.jpg', fit: BoxFit.cover),
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
                            empresa,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          precioStr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB8860B),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.azul1,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          fecha,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
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
                        Text(
                          horaSalida,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
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
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                            overflow: TextOverflow.ellipsis,
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
    );
  }
}
