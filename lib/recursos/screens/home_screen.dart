import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- Para saber quién está logueado
import 'package:prueba_eskpe/recursos/colores.dart';
import 'package:prueba_eskpe/recursos/screens/admin_panel_screen.dart'; // <--- Ruta del admin panel
import 'package:carousel_slider/carousel_slider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String rol = 'usuario'; // Por defecto es usuario normal por seguridad
  bool cargandoRol = true;

  final List<Map<String, String>> _empresas = [
    {'nombre': 'Posada Alfa', 'imagen': 'assets/posada.jpg'},
    {'nombre': 'Yates Express', 'imagen': 'assets/yates.jpg'},
    {'nombre': 'Rest. Mar', 'imagen': 'assets/restaurante.jpg'},
  ];

  @override
  void initState() {
    super.initState();
    _obtenerRolDesdeFirebase();
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
      debugPrint("Error obteniendo rol: $e");
    }
    setState(() => cargandoRol = false);
  }

  @override
  Widget build(BuildContext context) {
    // Mientras verifica si eres admin, muestra un cargando
    if (cargandoRol) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2E16D1))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFCCCCCC), 
      
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0), // 👈 AQUÍ MANEJAS LA ALTURA (Prueba con 75 o 80)
        child: AppBar(
          backgroundColor: AppColors.azul1, 
          elevation: 3,
          centerTitle: true,
          // Metemos un Padding en el title por si quieres ajustar la posición vertical del texto en la nueva barra
          title: const Padding(
            padding: EdgeInsets.only(top: 10.0), // 👈 Si la barra es más alta, esto baja el logo para que quede centrado fino
            child: Text(
              'ESK-PE',
              style: TextStyle(
                fontFamily: 'Impact',
                fontSize: 40, // Le subí de 36 a 38 ya que ahora tienes más espacio
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 💡 NOTA: Se eliminó el logo en Padding que estaba aquí arriba.
              //carrusel de fotos abajo
            // Dentro de tu Column en HomeScreen:
CarouselSlider(
  options: CarouselOptions(
    height: 200.0, // Ajusta a la altura que necesites
    autoPlay: true, // Para que se mueva solo
    enlargeCenterPage: true, // La foto del centro se ve más grande
    viewportFraction: 0.9, // Qué tanto espacio ocupa la foto
  ),
  items: ['assets/playa1.jpg', 'assets/playa2.jpg', 'assets/playa3.jpg'].map((i) {
    return Builder(
      builder: (BuildContext context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
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
              const SizedBox(height: 5), // Espacio inicial debajo de la nueva AppBar

              
             

              const SizedBox(height: 25),

              // 3. SECCIÓN LUGARES (Manteniendo tus destinos intactos)
              _buildSeccionTitulo("Destinos"),
              const SizedBox(height: 15),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                .collectionGroup('destinos') 
                .limit(7)
                .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Error al cargar lugares...'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF2E16D1)));
                  }

                  final docsLugares = snapshot.data?.docs ?? [];

                  if (docsLugares.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'No hay lugares registrados', 
                        style: TextStyle(color: Colors.black54)
                      ),
                    );
                  }

                  return SizedBox(
                    height: 140, 
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: docsLugares.length,
                      itemBuilder: (context, index) {
                        final datosLugar = docsLugares[index].data() as Map<String, dynamic>;
                        
                        return _buildItemCircular(
                          datosLugar['nombre'] ?? 'Sin nombre', 
                          datosLugar['rutaAsset'] ?? '' 
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // 4. SECCIÓN EMPRESAS (Local)
              _buildSeccionTitulo("Empresas"),
              const SizedBox(height: 15),

              Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15), // Espacio interno arriba y abajo de los círculos
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 115, 111, 129), // 👈 EL COLOR DE FONDO (Puedes usar Colors.white, Colors.grey[800], etc.)
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05), // Sombra suave para que despegue del fondo gris
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SizedBox(
                height: 140, 
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _empresas.length,
                  itemBuilder: (context, index) {
                    return _buildItemCircular(_empresas[index]['nombre']!, _empresas[index]['imagen']!);
                  },
                ),
              ),
           ),
      
              const SizedBox(height: 25),

              // 5. SECCIÓN PRONTOS
              _buildSeccionTitulo("Prontos"),
              const SizedBox(height: 15),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('viajes').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Text('Error...');
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF2E16D1)));
                  }

                  final docsViajes = snapshot.data?.docs ?? [];
                  if (docsViajes.isEmpty) return const Text('No hay viajes.');

                  return SizedBox(
                    height: 210, 
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: docsViajes.length,
                      itemBuilder: (context, index) {
                        final datosViaje = docsViajes[index].data() as Map<String, dynamic>;
                        return _buildTarjetaViaje(
                          datosViaje['nombre'] ?? 'Sin destino',
                          datosViaje['precio']?.toString() ?? '0',
                          datosViaje['fecha'] ?? 'Próximamente',
                          datosViaje['rutaAsset'] ?? '', 
                        );
                      },
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 100), 
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSeccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.azuleskpe),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.azuleskpe),
        ],
      ),
    );
  }

  Widget _buildItemCircular(String nombre, String rutaAsset) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              border: Border.all(color: Colors.white, width: 2,),
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: AssetImage(rutaAsset.isNotEmpty ? rutaAsset : 'assets/placeholder_playa.jpg'), 
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nombre,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaViaje(String destino, String precio, String fecha, String rutaAsset) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              image: DecorationImage(
                image: AssetImage(rutaAsset.isNotEmpty ? rutaAsset : 'assets/placeholder_playa.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(destino, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(fecha, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1),
                const SizedBox(height: 6),
                Text('\$$precio', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2E16D1))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      showSelectedLabels: false,
      showUnselectedLabels: false,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black38,
      currentIndex: 0, 
      onTap: (index) {
        if (index == 2 && rol == 'admin') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminScreen()),
          );
        }
      },
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home_filled, size: 30), label: ''),
        const BottomNavigationBarItem(icon: Icon(Icons.search, size: 30), label: ''),
        
        if (rol == 'admin')
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 30), label: ''),
      ],
    );
  }
}