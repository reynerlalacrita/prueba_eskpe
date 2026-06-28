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
      backgroundColor: const Color(0xFFCCCCCC),
      appBar: _indiceActual == 0 ? _buildAppBar() : null,
      body: _pantallas[_indiceActual],
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: Colors.black,
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
        backgroundColor: AppColors.azul1,
        elevation: 3,
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: Text('ESK-PE', style: TextStyle(fontFamily: 'Impact', fontSize: 40, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.white, letterSpacing: 2)),
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
            CarouselSlider(
              options: CarouselOptions(height: 200.0, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.9),
              items: ['assets/playa1.jpg', 'assets/playa2.jpg', 'assets/playa3.jpg'].map((i) {
                return Builder(builder: (context) {
                  return Container(width: MediaQuery.of(context).size.width, margin: const EdgeInsets.symmetric(horizontal: 5.0), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), image: DecorationImage(image: AssetImage(i), fit: BoxFit.cover)));
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
                return SizedBox(height: 140, child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 15), scrollDirection: Axis.horizontal, itemCount: docs.length, itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _buildItemCircular(data['nombre'] ?? '', data['rutaAsset'] ?? '');
                }));
              },
            ),
            const SizedBox(height: 25),
            _buildSeccionTitulo("Empresas"),
            const SizedBox(height: 15),
            Container(color: const Color.fromARGB(255, 115, 111, 129), child: SizedBox(height: 140, child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 15), scrollDirection: Axis.horizontal, itemCount: _empresas.length, itemBuilder: (context, index) => _buildItemCircular(_empresas[index]['nombre']!, _empresas[index]['imagen']!)))),
            const SizedBox(height: 25),
            _buildSeccionTitulo("Prontos"),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('viajes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return SizedBox(height: 210, child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 15), scrollDirection: Axis.horizontal, itemCount: docs.length, itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _buildTarjetaViaje(data['nombre'] ?? '', data['precio']?.toString() ?? '0', data['fecha'] ?? '', data['rutaAsset'] ?? '');
                }));
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionTitulo(String titulo) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0), child: Row(children: [Text(titulo, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.azuleskpe)), const SizedBox(width: 5), const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.azuleskpe)]));
  }

  Widget _buildItemCircular(String nombre, String rutaAsset) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10.0),
    child: Column(
      children: [
        // Envolvemos el contenedor en Material e InkWell para el efecto de toque
        Material(
          color: Colors.transparent, // Color base del Material
          child: InkWell(
            borderRadius: BorderRadius.circular(12), // Hace que la onda respete tus bordes
            onTap: () {
              // Navegación a la pantalla de detalles
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DestinoDetalleScreen(nombre: nombre, rutaAsset: rutaAsset),
                ),
              );
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage(rutaAsset.isNotEmpty ? rutaAsset : 'assets/placeholder_playa.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

  Widget _buildTarjetaViaje(String destino, String precio, String fecha, String rutaAsset) {
    return Container(width: 160, margin: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(children: [Container(height: 110, decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), image: DecorationImage(image: AssetImage(rutaAsset.isNotEmpty ? rutaAsset : 'assets/placeholder_playa.jpg'), fit: BoxFit.cover))), Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(destino, style: const TextStyle(fontWeight: FontWeight.bold)), Text(fecha, style: const TextStyle(fontSize: 12)), Text('\$$precio', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E16D1)))]))]));
  }
}