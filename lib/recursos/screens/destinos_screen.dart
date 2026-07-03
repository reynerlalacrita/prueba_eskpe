import 'package:flutter/material.dart';
import 'package:prueba_eskpe/recursos/screens/home_screen.dart';

class DestinosScreen extends StatefulWidget {
  const DestinosScreen({super.key});

  @override
  State<DestinosScreen> createState() => _DestinosScreenState();
}

class _DestinosScreenState extends State<DestinosScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Lista de ejemplo con nombres y rutas de imágenes
  final List<Map<String, String>> _destinos = [
    {'nombre': 'Tucacas', 'imagen': 'assets/tucacas.jpg'},
    {'nombre': 'Morrocoy', 'imagen': 'assets/morrocoy.jpg'},
    {'nombre': 'Chichiriviche', 'imagen': 'assets/chichiriviche.jpg'},
    {'nombre': 'Cata', 'imagen': 'assets/cata.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Empuja el título a la izquierda y el botón a la derecha
        children: [
          const Text(
            "Selecciona un destino",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (context) => const HomeScreen())
              );
            },
            child: const Text("Omitir", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    ),      
            // Barra de búsqueda con tu diseño
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Buscar destino...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            
            // Cuadrícula de tarjetas
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columnas como en la imagen
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.8,
                ),
                itemCount: _destinos.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      // AQUÍ LLAMARÁS A TU NUEVA PANTALLA MÁS ADELANTE
                      print("Navegar a: ${_destinos[index]['nombre']}");
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: AssetImage(_destinos[index]['imagen']!), 
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(color: Colors.black.withOpacity(0.3)), // Filtro oscuro para leer mejor el texto
                          Text(
                            _destinos[index]['nombre']!,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const Positioned(top: 10, child: Icon(Icons.location_on, color: Colors.blue, size: 30)),
                          const Positioned(bottom: 10, child: Icon(Icons.location_on, color: Colors.blue, size: 30)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}