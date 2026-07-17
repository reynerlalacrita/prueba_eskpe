import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prueba_eskpe/recursos/colores.dart';
import 'package:prueba_eskpe/recursos/screens/admin_panel_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:prueba_eskpe/recursos/screens/busqueda_screen.dart';
import 'package:prueba_eskpe/recursos/screens/usuario_screen.dart';
import 'package:prueba_eskpe/recursos/screens/destino_detalle_screen.dart';
import 'package:prueba_eskpe/recursos/screens/empresa_detalle_screen.dart';
import 'package:prueba_eskpe/recursos/screens/lista_destinos_screen.dart';
import 'package:prueba_eskpe/recursos/screens/lista_empresas_screen.dart';
import 'package:prueba_eskpe/recursos/screens/lista_prontos_screen.dart';

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
    {'nombre': 'Alfa Tours', 'imagen': 'assets/AlfaTours.jpg'},
    {'nombre': 'Yates Express', 'imagen': 'assets/YateExpress.jpg'},
    {'nombre': 'Caracas Tours', 'imagen': 'assets/CaracasTours.jpg'},
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
      backgroundColor: Colors.white, 
      appBar: _indiceActual == 0 ? _buildAppBar() : null,
      body: _pantallas[_indiceActual],
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: const Color(0xFF1E2A4F), 
        unselectedItemColor: Colors.black38,
        currentIndex: _indiceActual,
        // 🛠️ SE ELIMINÓ EL IF: Ahora cambia directamente de índice y renderiza UsuarioScreen
        onTap: (index) {
          setState(() {
            _indiceActual = index;
          });
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
        backgroundColor: const Color(0xFF1E2A4F), 
        elevation: 0, 
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
            
            _buildSeccionTitulo("Destinos", () {
  Navigator.push(context, MaterialPageRoute(builder: (context) => const ListaDestinosScreen()));
}),
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
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildItemDestino(data['nombre'] ?? '', data['rutaAsset'] ?? '', doc.id);
                    }
                  )
                );
              },
            ),
            
            const SizedBox(height: 15),
            _buildSeccionTitulo("Empresas", () {
  Navigator.push(context, MaterialPageRoute(builder: (context) => const ListaEmpresasScreen()));
}),
            const SizedBox(height: 10),
            SizedBox(
              height: 120, 
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15), 
                scrollDirection: Axis.horizontal, 
                itemCount: _empresas.length, 
                itemBuilder: (context, index) {
              final empresa = _empresas[index]; // Obtenemos el objeto empresa
              
              return _buildItemEmpresa(
                empresa['nombre'] ?? 'Sin nombre',    // 1. Nombre
                empresa['imagen'] ?? '',             // 2. Imagen
                empresa['telefono'] ?? '584121234567', // 3. Teléfono (o valor por defecto)
                empresa['id'] ?? 'sin_id',           // 4. ID (debes asegurarte que venga en tu objeto)
              );
            },
              )
            ),
            const SizedBox(height: 20),
            _buildSeccionTitulo("Prontos", () {
  Navigator.push(context, MaterialPageRoute(builder: (context) => const ListaProntosScreen()));
}),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('viajes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 0), 
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(), 
                  itemCount: docs.length, 
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    String fechaTexto = '';
                     if (data['fecha'] != null) {
                      final Timestamp timestamp = data['fecha'] as Timestamp;
                      final DateTime fechaDateTime = timestamp.toDate();
                      fechaTexto = "${fechaDateTime.day}/${fechaDateTime.month}/${fechaDateTime.year}";
                    }
                    return _buildTarjetaViaje(data['nombre'] ?? '', data['precio']?.toString() ?? '0', fechaTexto, data['rutaAsset'] ?? '');
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

  Widget _buildSeccionTitulo(String titulo, VoidCallback onTap) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0),
    child: GestureDetector(
      onTap: onTap, // Llamamos a la función que pasamos como parámetro
      child: Row(
        children: [
          Text(titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E2A4F))),
          const SizedBox(width: 5), // Un poco de espacio
          const Icon(Icons.chevron_right, size: 24, color: Color(0xFF1E2A4F))
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
          Navigator.push(context, MaterialPageRoute(builder: (context) => DestinoDetalleScreen(nombre: nombre, rutaAsset: rutaAsset, destinoId: destinoId,)));
        },
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1E2A4F), width: 2), 
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

  // Diseño de Empresas: Tarjeta interactiva para ir a los detalles
  Widget _buildItemEmpresa(String nombre, String rutaAsset, String telefono, String id) { 
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          // 2. Ahora pasa los datos obligatorios aquí
          builder: (context) => EmpresaDetalleScreen(
            nombreEmpresa: nombre,
            rutaAsset: rutaAsset,
            telefonoEmpresa: telefono, // <--- El teléfono que recibes
            destinoId: id,            // <--- El ID que recibes
          ),
        ),
      );
    },
      child: Container(
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
      ),
    );
  }

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