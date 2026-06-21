import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba_eskpe/recursos/colores.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Guardamos el destino actual. Luego lo podrás cambiar dinámicamente.
  final String _destinoSeleccionado = 'Morrocoy';

  // Lista local de empresas (por ahora)
  final List<Map<String, String>> _empresas = [
    {'nombre': 'Posada Alfa', 'imagen': 'assets/posada.jpg'},
    {'nombre': 'Yates Express', 'imagen': 'assets/yates.jpg'},
    {'nombre': 'Rest. Mar', 'imagen': 'assets/restaurante.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCCCCCC), 
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. LOGO PRINCIPAL "ESK-PE"
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: Text(
                    'ESK-PE',
                    style: TextStyle(
                      fontFamily: 'Impact',
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Colors.black.withOpacity(0.8),
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),

              // 2. BANNER PRINCIPAL 
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  image: const DecorationImage(
                    image: AssetImage('assets/banner_principal.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == 0 ? 12 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == 0 ? const Color(0xFF2E16D1) : Colors.grey,
                    borderRadius: BorderRadius.circular(3),
                  ),
                )),
              ),

              const SizedBox(height: 25),

              // 3. SECCIÓN LUGARES - APUNTANDO A TU SUBCOLECCIÓN
              _buildSeccionTitulo("Lugares de $_destinoSeleccionado"),
              const SizedBox(height: 15),
              StreamBuilder<QuerySnapshot>(
                // AQUÍ ESTÁ EL CAMBIO: Entra a destinos -> Morrocoy -> lugares
                stream: FirebaseFirestore.instance
                    .collection('destinos')
                    .doc(_destinoSeleccionado)
                    .collection('lugares')
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
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'No hay lugares registrados para $_destinoSeleccionado.', 
                        style: const TextStyle(color: Colors.black54)
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
                          datosLugar['rutaAsset'] ?? '' // Tu ruta local: 'assets/cayo_sombrero.jpg'
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
              SizedBox(
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

              const SizedBox(height: 25),

              // 5. SECCIÓN PRONTOS - EN VIVO DESDE LA COLECCIÓN VIAJES
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.azuleskpe),
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
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled, size: 30), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined, size: 30), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 30), label: ''),
      ],
    );
  }
}