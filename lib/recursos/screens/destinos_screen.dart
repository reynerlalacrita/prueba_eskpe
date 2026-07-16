import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🛠️ Importación de Firestore
import 'package:prueba_eskpe/recursos/screens/home_screen.dart';
import 'package:prueba_eskpe/recursos/screens/destino_detalle_screen.dart';

class DestinosScreen extends StatefulWidget {
  const DestinosScreen({super.key});

  @override
  State<DestinosScreen> createState() => _DestinosScreenState();
}

class _DestinosScreenState extends State<DestinosScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 🛠️ Escuchamos los cambios del buscador para actualizar la lista en tiempo real
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    child: const Text("Omitir", style: TextStyle(fontSize: 16, color: Color(0xFF1E2A4F))),
                  ),
                ],
              ),
            ),      
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
            
            Expanded(
              // 🛠️ Conexión con Firebase Firestore a la colección 'destinos'
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('destinos').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF1E2A4F)));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No hay destinos disponibles por ahora."));
                  }

                  // Obtenemos los documentos originales de Firebase
                  var documentosDestinos = snapshot.data!.docs;

                  // 🛠️ LÓGICA DE BÚSQUEDA AUTOMÁTICA
                  String query = _searchController.text.toLowerCase();
                  if (query.isNotEmpty) {
                    documentosDestinos = documentosDestinos.where((doc) {
                      final datos = doc.data() as Map<String, dynamic>;
                      final String nombreDestino = (datos['nombre'] ?? '').toString().toLowerCase();
                      return nombreDestino.contains(query);
                    }).toList();
                  }

                  if (documentosDestinos.isEmpty) {
                    return const Center(child: Text("No se encontraron resultados."));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, 
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: documentosDestinos.length,
                    itemBuilder: (context, index) {
                      // Extraemos la información de cada destino
                      final docData = documentosDestinos[index].data() as Map<String, dynamic>;
                      final String nombre = docData['nombre'] ?? 'Destino';
                      // Buscamos el campo de imagen (sea 'imagenUrl' o 'rutaAsset' en tu Firebase)
                      final String imagen = docData['imagenUrl'] ?? docData['rutaAsset'] ?? '';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DestinoDetalleScreen(
                                destinoId: documentosDestinos[index].id,
                                nombre: nombre,
                                rutaAsset: imagen, // Pasamos la URL al detalle
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              // 🛠️ Si el String empieza con http es red (Firebase), de lo contrario es local asset
                              image: (imagen.startsWith('http') 
                                  ? NetworkImage(imagen) 
                                  : AssetImage(imagen.isNotEmpty ? imagen : 'assets/background_road.jpg')) as ImageProvider, 
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.black.withOpacity(0.3),
                                )
                              ), 
                              Text(
                                nombre,
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const Positioned(bottom: 10, child: Icon(Icons.location_on, color: Color.fromARGB(255, 193, 0, 0), size: 30)),
                            ],
                          ),
                        ),
                      );
                    },
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