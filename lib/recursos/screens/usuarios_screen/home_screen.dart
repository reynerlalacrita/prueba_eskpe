import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prueba_eskpe/recursos/colores.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:prueba_eskpe/recursos/screens/usuarios_screen/busqueda_screen.dart';
import 'package:prueba_eskpe/recursos/screens/usuarios_screen/destino_detalle_screen.dart';
import 'package:prueba_eskpe/recursos/screens/usuarios_screen/empresa_detalle_screen.dart';
import 'package:prueba_eskpe/recursos/screens/usuarios_screen/lista_destinos_screen.dart';
import 'package:prueba_eskpe/recursos/screens/usuarios_screen/lista_empresas_screen.dart';
import 'package:prueba_eskpe/recursos/screens/usuarios_screen/lista_viajes_screen.dart';
import 'package:prueba_eskpe/recursos/screens/usuarios_screen/reservas_screen.dart';
import 'package:prueba_eskpe/recursos/screens/usuarios_screen/usuario_screen.dart';
import 'package:prueba_eskpe/recursos/fcm_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String rol = 'usuario';
  bool cargandoRol = true;
  int _indiceActual = 0;

  late final List<Widget> _pantallas;

  @override
  void initState() {
    super.initState();
    _obtenerRolDesdeFirebase();
    FCMService.inicializarFCM();
    _pantallas = [
      _buildCuerpoHome(),
      const BusquedaScreen(),
      const UsuarioScreen(),
    ];
  }

  void _obtenerRolDesdeFirebase() async {
    try {
      User? usuarioActual = FirebaseAuth.instance.currentUser;
      if (usuarioActual != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(usuarioActual.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> datos = doc.data() as Map<String, dynamic>;
          setState(() {
            rol = datos['rol'] ?? 'usuario';
            cargandoRol = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => cargandoRol = false);
  }

  @override
  Widget build(BuildContext context) {
    if (cargandoRol)
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2E16D1)),
        ),
      );

    return Scaffold(
      backgroundColor: Color(0xFFECEEEF),
      appBar: _indiceActual == 0 ? _buildAppBar() : null,
      body: _pantallas[_indiceActual],
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: AppColors.azuleskpe,
        unselectedItemColor: Colors.black38,
        currentIndex: _indiceActual,
        // 🛠️ SE ELIMINÓ EL IF: Ahora cambia directamente de índice y renderiza UsuarioScreen
        onTap: (index) {
          setState(() {
            _indiceActual = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_filled, size: 30),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search, size: 30),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: _buildBadgeNavegacionUsuario(),
            label: 'Usuario',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60.0),
      child: AppBar(
        backgroundColor: AppColors.azuleskpe,
        elevation: 0,
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: Text(
            'ESK-PE',
            style: TextStyle(
              fontFamily: 'Impact',
              fontSize: 36,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeNavegacionUsuario() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Icon(Icons.person_outline, size: 30);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservaciones')
          .where('usuarioId', isEqualTo: user.uid)
          .where('estado', whereIn: ['Aceptada', 'Rechazada', 'Cancelada'])
          .where('leida', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Icon(Icons.person_outline, size: 30);
        }

        return Stack(
          children: [
            const Icon(Icons.person_outline, size: 30),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCuerpoHome() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            CarouselSlider(
              options: CarouselOptions(
                height: 180.0,
                autoPlay: true,
                enlargeCenterPage: true,
                viewportFraction: 0.85,
              ),
              items:
                  [
                    'assets/playa1.jpg',
                    'assets/choroni1.jpg',
                    'assets/playa3.jpg',
                  ].map((i) {
                    return Builder(
                      builder: (context) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            image: DecorationImage(
                              image: AssetImage(i),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
            ),
            const SizedBox(height: 25),

            _buildSeccionTitulo("Destinos", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListaDestinosScreen(),
                ),
              );
            }),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('destinos')
                  .limit(7)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return SizedBox(
                  height: 160,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildItemDestino(
                        data['nombre'] ?? '',
                        data['rutaAsset'] ?? '',
                        doc.id,
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 15),
            _buildSeccionTitulo("Empresas", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListaEmpresasScreen(),
                ),
              );
            }),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .where('rol', isEqualTo: 'empresa')
                  .limit(7)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "No hay empresas registradas aún.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return SizedBox(
                  height: 130,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final String logoUrl =
                          data['fotoUrl'] ??
                          data['logoUrl'] ??
                          data['fotoPerfilUrl'] ??
                          data['imagenUrl'] ??
                          data['photoURL'] ??
                          data['rutaAsset'] ??
                          '';
                      return _buildItemEmpresa(
                        data['nombres'] ?? 'Sin nombre',
                        logoUrl,
                        data['telefono'] ?? '584121234567',
                        doc.id,
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildSeccionTitulo("Viajes", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListaViajesScreen(),
                ),
              );
            }),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('viajes')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildTarjetaViaje(doc.id, data);
                  },
                );
              },
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionTitulo(String titulo, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.azul4,
              ),
            ),
            const SizedBox(width: 5), // Un poco de espacio
            const Icon(Icons.chevron_right, size: 24, color: AppColors.azul2),
          ],
        ),
      ),
    );
  }

  Widget _buildItemDestino(String nombre, String rutaAsset, String destinoId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DestinoDetalleScreen(
                nombre: nombre,
                rutaAsset: rutaAsset,
                destinoId: destinoId,
              ),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: rutaAsset.startsWith('http')
                      ? NetworkImage(rutaAsset) as ImageProvider
                      : AssetImage(
                          rutaAsset.isNotEmpty
                              ? rutaAsset
                              : 'assets/sinfoto.jpg',
                        ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 108,
              child: Text(
                nombre,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Diseño de Empresas: Tarjeta interactiva para ir a los detalles
  Widget _buildItemEmpresa(
    String nombre,
    String rutaAsset,
    String telefono,
    String id,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmpresaDetalleScreen(
              nombreEmpresa: nombre,
              rutaAsset: rutaAsset,
              telefonoEmpresa: telefono,
              destinoId: id,
            ),
          ),
        );
      },
      child: Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: _buildImagenLogoEmpresa(rutaAsset)),
              Expanded(
                flex: 1,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método actualizado para usar 'sinfoto.jpg' en lugar del ícono
  Widget _buildImagenLogoEmpresa(String ruta) {
    if (ruta.startsWith('http://') || ruta.startsWith('https://')) {
      return Image.network(
        ruta,
        fit: BoxFit.cover, // Para que rellene el cuadrado sin deformarse
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/sinfoto.jpg', fit: BoxFit.cover),
      );
    } else if (ruta.isNotEmpty) {
      return Image.asset(
        ruta,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/sinfoto.jpg', fit: BoxFit.cover),
      );
    } else {
      // Si la ruta está vacía, mostramos la imagen por defecto
      return Image.asset('assets/sinfoto.jpg', fit: BoxFit.cover);
    }
  }

  Widget _buildTarjetaViaje(String viajeId, Map<String, dynamic> data) {
    String destinoId = data['destinoId'] ?? '';

    if (destinoId.isEmpty) {
      return _tarjetaContenido(
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
            height: 110,
            margin: const EdgeInsets.only(bottom: 15, left: 20, right: 20),
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

        return _tarjetaContenido(viajeId, data, nombre, ruta);
      },
    );
  }

  Widget _tarjetaContenido(
    String viajeId,
    Map<String, dynamic> data,
    String nombreDestino,
    String rutaAsset,
  ) {
    String fechaStr = 'Fecha no definida';
    if (data['fecha'] != null) {
      final dt = (data['fecha'] as Timestamp).toDate();
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
        height: 145,
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
                child: _buildImagenViaje(rutaAsset),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      empresaNombre,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                          fechaStr,
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
