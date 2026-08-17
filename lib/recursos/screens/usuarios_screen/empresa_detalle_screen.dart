import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba_eskpe/recursos/colores.dart';
import 'package:prueba_eskpe/recursos/utils.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:prueba_eskpe/recursos/screens/usuarios_screen/reservas_screen.dart';

class EmpresaDetalleScreen extends StatefulWidget {
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
  State<EmpresaDetalleScreen> createState() => _EmpresaDetalleScreenState();
}

class _EmpresaDetalleScreenState extends State<EmpresaDetalleScreen> {
  String _descripcion = '';
  String _portadaUrl = '';
  List<String> _imagenesEmpresa = [];
  bool _cargandoDatos = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosEmpresa();
  }

  Future<void> _cargarDatosEmpresa() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.destinoId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _descripcion = data['descripcion'] ?? '';
          _portadaUrl = data['portadaUrl'] ?? '';
          if (data['imagenesEmpresa'] != null) {
            _imagenesEmpresa = List<String>.from(data['imagenesEmpresa']);
          }
          _cargandoDatos = false;
        });
      } else {
        setState(() => _cargandoDatos = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _cargandoDatos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esTelefonoValido =
        widget.telefonoEmpresa.isNotEmpty &&
        widget.telefonoEmpresa != "584121234567";

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
              titlePadding: const EdgeInsets.only(left: 110, bottom: 16),
              title: Text(
                widget.nombreEmpresa,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                ),
              ),
              background: _cargandoDatos
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        // Cover photo (portadaUrl)
                        if (_portadaUrl.isNotEmpty)
                          Image.network(
                            _portadaUrl,
                            fit: BoxFit.cover,
                            color: Colors.black.withOpacity(0.3),
                            colorBlendMode: BlendMode.darken,
                          )
                        else
                          Container(color: AppColors.azuleskpe),
                        // Circular Logo on the bottom left
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  widget.rutaAsset.startsWith('http')
                                  ? NetworkImage(widget.rutaAsset)
                                        as ImageProvider
                                  : AssetImage(
                                      widget.rutaAsset.isNotEmpty
                                          ? widget.rutaAsset
                                          : 'assets/sinfoto.jpg',
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: esTelefonoValido
                          ? () => AppUtils.abrirWhatsApp(
                              widget.telefonoEmpresa,
                              widget.nombreEmpresa,
                            )
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
                  if (_descripcion.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      "Acerca de nosotros",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E2A4F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _descripcion,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                  if (_imagenesEmpresa.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 200.0,
                        viewportFraction: 0.9,
                        enlargeCenterPage: true,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 4),
                      ),
                      items: _imagenesEmpresa.map((url) {
                        return Builder(
                          builder: (BuildContext context) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ],
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
                    "Descubre todo lo que ${widget.nombreEmpresa} tiene para ti",
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
                .where('empresaId', isEqualTo: widget.destinoId)
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
                        "${widget.nombreEmpresa} aún no ha publicado viajes.",
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
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E2A4F)),
            ),
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
                child:
                    (rutaAsset.startsWith('http://') ||
                        rutaAsset.startsWith('https://'))
                    ? Image.network(
                        rutaAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                              'assets/sinfoto.jpg',
                              fit: BoxFit.cover,
                            ),
                      )
                    : Image.asset(
                        rutaAsset.isNotEmpty ? rutaAsset : 'assets/sinfoto.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                              'assets/sinfoto.jpg',
                              fit: BoxFit.cover,
                            ),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                          fecha.isEmpty ? "Fechas por definir" : fecha,
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
