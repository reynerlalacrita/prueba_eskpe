import 'package:flutter/material.dart';
import 'package:prueba_eskpe/recursos/screens/admin_panel_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Datos de prueba para simular tus listas
  final List<Map<String, String>> _lugares = [
    {'nombre': 'Tucacas', 'imagen': 'assets/tucacas.jpg'},
    {'nombre': 'Morrocoy', 'imagen': 'assets/morrocoy.jpg'},
    {'nombre': 'Chichiriviche', 'imagen': 'assets/chichi.jpg'},
    {'nombre': 'Cata', 'imagen': 'assets/cata.jpg'},
  ];

  final List<Map<String, String>> _empresas = [
    {'nombre': 'Posada Alfa', 'imagen': 'assets/posada.jpg'},
    {'nombre': 'Yates Express', 'imagen': 'assets/yates.jpg'},
    {'nombre': 'Rest. Mar', 'imagen': 'assets/restaurante.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCCCCCC), // Fondo gris claro similar a tu diseño
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

              // 2. BANNER PRINCIPAL (Slider de arriba de Navidad/Playa)
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
              // Indicador de puntitos simple
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

              // Dentro del Scaffold de tu HomeScreen:
                FloatingActionButton(
                backgroundColor: const Color(0xFF2E16D1),
                child: const Icon(Icons.add, color: Colors.white),
                onPressed: () async {
                  // Abre el panel y espera a recibir los datos del nuevo objeto
                  final resultado = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                  );

                  if (resultado != null) {
                    setState(() {
                      if (resultado['tipo'] == 'empresa') {
                        _empresas.add({
                          'nombre': resultado['nombre'],
                          'imagen': '', // Guardas la referencia temporal o ruta de archivo
                          'file': resultado['imagenFile'], // Añades el File real de la foto seleccionada
                        });
                      } else if (resultado['tipo'] == 'viaje') {
                        // Repites el proceso para agregar el viaje a la lista de abajo
                      }
                    });
                  }
                },
              ),

              // 3. SECCIÓN SECTOR LUGARES (Horizontal)
              _buildSeccionTitulo("Lugares"),
              const SizedBox(height: 15),
              SizedBox(
                height: 140, // Alto fijo para que quepan los círculos y el texto abajo
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _lugares.length,
                  itemBuilder: (context, index) {
                    return _buildItemCircular(_lugares[index]['nombre']!, _lugares[index]['imagen']!);
                  },
                ),
              ),

              const SizedBox(height: 20),

              // 4. NUEVA SECCIÓN EMPRESAS (Horizontal - Exactamente lo que pediste)
              _buildSeccionTitulo("Empresas"),
              const SizedBox(height: 15),
              SizedBox(
                height: 140, // Reutiliza el mismo alto y comportamiento
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

              // 5. SECCIÓN PRONTOS / PROXIMAMENTE
              _buildSeccionTitulo("Prontos"),
              const SizedBox(height: 15),
              // Aquí irían tus tarjetas cuadradas de abajo (Playa los Indios, Cayo Sombrero)
              
              const SizedBox(height: 100), // Espacio para que no lo tape la barra inferior
            ],
          ),
        ),
      ),
      
      // 6. BARRA DE NAVEGACIÓN INFERIOR (BottomNavigationBar)
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // Widget auxiliar para los títulos de sección con la flechita
  Widget _buildSeccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold, 
              color: Color(0xFF7B1FA2), // Color morado de tu diseño
            ),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF7B1FA2)),
        ],
      ),
    );
  }

  // Widget auxiliar para construir cada círculo deslizable
  Widget _buildItemCircular(String nombre, String rutaImagen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: const DecorationImage(
                image: AssetImage('assets/placeholder_playa.jpg'), // Cambia por tu rutaImagen
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nombre,
            style: const TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.w500, 
              color: Color(0xFF7B1FA2),
            ),
          ),
        ],
      ),
    );
  }

  // Widget de la barra inferior
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