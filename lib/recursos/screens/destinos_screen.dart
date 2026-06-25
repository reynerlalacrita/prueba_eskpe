import 'package:flutter/material.dart';
import 'package:prueba_eskpe/recursos/screens/home_screen.dart';

class DestinosScreen extends StatefulWidget {
  const DestinosScreen({super.key});

  @override
  State<DestinosScreen> createState() => _DestinosScreenState();
}

class _DestinosScreenState extends State<DestinosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _destinos = ['Tucacas', 'Morrocoy', 'Chichiriviche', 'Cata'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Selecciona un destino"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (context) => const HomeScreen())
              );
            },
            child: const Text("Omitir"),
          ),
        ],
      ),
      body: Column(
        children: [
          // BARRA DE BÚSQUEDA INTEGRADA
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar destino...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) {
                // Aquí puedes agregar la lógica para filtrar tu lista _destinos
                print("Buscando: $value");
              },
            ),
          ),
          
          // LISTA DE DESTINOS
          Expanded(
            child: ListView.builder(
              itemCount: _destinos.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Color.fromRGBO(32, 32, 188, 1)),
                  title: Text(_destinos[index]),
                  onTap: () => print("Destino seleccionado: ${_destinos[index]}"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}