import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prueba_eskpe/recursos/colores.dart';
import 'package:prueba_eskpe/recursos/screens/admin_panel_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:prueba_eskpe/recursos/screens/busqueda_screen.dart';
import 'package:prueba_eskpe/recursos/screens/usuario_screen.dart';
import 'package:prueba_eskpe/recursos/screens/destino_detalle_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String rol = 'usuario';
  bool cargandoRol = true;
  int _indiceActual = 0;

  final List<Map<String, String>> _empresas = [
    {'nombre': 'Posada Alfa', 'imagen': 'assets/posada.jpg'},
    {'nombre': 'Yates Express', 'imagen': 'assets/yates.jpg'},
    {'nombre': 'Rest. Mar', 'imagen': 'assets/restaurante.jpg'},
  ];

  late final List<Widget> _pantallas;

  @override
  void initState() {
    super.initState();
    _obtenerRolDesdeFirebase();
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
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('usuarios').doc(usuarioActual.uid).get();
        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> datos = doc.data() as Map<String, dynamic>;
          setState(() {
            rol = datos['rol'] ?? 'usuario';
            cargandoRol = false;
          });
          return;
        }
      }
    } catch (e) { debugPrint("Error: $e"); }
    setState(() => cargandoRol = false);
  }

  @override
  Widget build(BuildContext context) {
    if (cargandoRol) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF2E16D1))));

    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco según el nuevo diseño
      appBar: _indiceActual == 0 ? _buildAppBar() : null,
      body: _pantallas[_indiceActual],
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: const Color(0xFF1E2A4F), // Azul oscuro para combinar
        unselectedItemColor: Colors.black38,
        currentIndex: _indiceActual,
        onTap: (index) {
          if (index == 2 && rol == 'admin') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminScreen()));
          } else {
            setState(() => _indiceActual = index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled, size: 30), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search, size: 30), label: 'Buscar'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 30), label: 'Usuario'),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60.0),
      child: AppBar(
        backgroundColor: const Color(0xFF1E2A4F), // Azul oscuro
        elevation: 0, // Sin sombra dura para que se vea más moderno
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: Text('ESK-PE', style: TextStyle(fontFamily: 'Impact', fontSize: 36, fontStyle: FontStyle.italic, color: Colors.white, letterSpacing: 2)),
        ),
      ),
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
            // Carrusel ajustado al nuevo estilo
            CarouselSlider(
              options: CarouselOptions(height: 180.0, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.85),
              items: ['assets/playa1.jpg', 'assets/playa2.jpg', 'assets/playa3.jpg'].map((i) {
                return Builder(builder: (context) {
                  return Container(
                    width: MediaQuery.of(context).size.width, 
                    margin: const EdgeInsets.symmetric(horizontal: 5.0), 
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15), 
                      image: DecorationImage(image: AssetImage(i), fit: BoxFit.cover)
                    )
                  );
                });
              }).toList(),
            ),
            const SizedBox(height: 25),
            
            _buildSeccionTitulo("Destinos"),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collectionGroup('destinos').limit(7).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return SizedBox(
                  height: 120, 
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15), 
                    scrollDirection: Axis.horizontal, 
                    itemCount: docs.length, 
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return _buildItemDestino(data['nombre'] ?? '', data['rutaAsset'] ?? '');
                    }
                  )
                );
              },
            ),
            
            const SizedBox(height: 15),
            _buildSeccionTitulo("Empresas"),
            const SizedBox(height: 10),
            // Eliminado el recuadro gris de fondo para mantenerlo limpio
            SizedBox(
              height: 120, 
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15), 
                scrollDirection: Axis.horizontal, 
                itemCount: _empresas.length, 
                itemBuilder: (context, index) => _buildItemEmpresa(_empresas[index]['nombre']!, _empresas[index]['imagen']!)
              )
            ),
            
            const SizedBox(height: 20),
            _buildSeccionTitulo("Prontos"),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('viajes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                // Cambio visual: Lista apilada verticalmente como en tu diseño
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 0), 
                  shrinkWrap: true, // Permite que se interegrue al SingleChildScrollView
                  physics: const NeverScrollableScrollPhysics(), // Evita doble scroll
                  itemCount: docs.length, 
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildTarjetaViaje(data['nombre'] ?? '', data['precio']?.toString() ?? '0', data['fecha'] ?? '', data['rutaAsset'] ?? '');
                  }
                );
              },
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS VISUALES ACTUALIZADOS ---

  Widget _buildSeccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0), 
      child: Row(
        children: [
          Text(titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E2A4F))), 
          const Icon(Icons.chevron_right, size: 24, color: Color(0xFF1E2A4F))
        ]
      )
    );
  }

  // Diseño de Destinos: Círculo perfecto con borde
  Widget _buildItemDestino(String nombre, String rutaAsset) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => DestinoDetalleScreen(nombre: nombre, rutaAsset: rutaAsset)));
        },
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1E2A4F), width: 2), // Borde azul oscuro
                image: DecorationImage(
                  image: AssetImage(rutaAsset.isNotEmpty ? rutaAsset : 'assets/placeholder_playa.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // Diseño de Empresas: Tarjeta blanca limpia con sombra suave
  Widget _buildItemEmpresa(String nombre, String rutaAsset) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(rutaAsset.isNotEmpty ? rutaAsset : 'assets/placeholder.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(nombre, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // Diseño de Prontos: Tarjeta horizontal con botón
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
          // Imagen del lado izquierdo
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
          // Contenido del lado derecho
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
                      Text('\$$precio', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB8860B), fontSize: 16)), // Color dorado
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Color(0xFFB8860B)),
                      const SizedBox(width: 5),
                      Text(fecha.isEmpty ? "Hoy - 2 hrs" : fecha, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Color(0xFFB8860B)),
                          SizedBox(width: 5),
                          Text("Hoy - 1 hrs", style: TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2A4F), // Botón azul oscuro
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