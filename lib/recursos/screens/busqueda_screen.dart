import 'package:flutter/material.dart';

class BusquedaScreen extends StatefulWidget {
  const BusquedaScreen({super.key});

  @override
  State<BusquedaScreen> createState() => _BusquedaScreenState();
}

class _BusquedaScreenState extends State<BusquedaScreen> {
  // 1. Variable de estado para controlar la lista de búsquedas
  List<String> _busquedasRecientes = [
    "Cayo Sombrero",
    "Los Roques",
  ];

  // Método para eliminar una búsqueda
  void _eliminarBusqueda(String busqueda) {
    setState(() {
      _busquedasRecientes.remove(busqueda);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Buscar destinos", style: TextStyle(color: Colors.white)), 
        backgroundColor: const Color(0xFF1E2A4F),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            
            // BARRA DE BÚSQUEDA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Escribe el nombre del lugar...",
                  hintStyle: const TextStyle(color: Colors.black45),
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30), 
                    borderSide: BorderSide(color: Colors.grey.shade300)
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30), 
                    borderSide: BorderSide(color: Colors.grey.shade300)
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30), 
                    borderSide: const BorderSide(color: Color(0xFF1E2A4F))
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // FILTROS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  _buildFiltroChip("Presupuesto"),
                  const SizedBox(width: 10),
                  _buildFiltroChip("Duración"),
                  const SizedBox(width: 10),
                  _buildFiltroChip("Tipo"),
                  const SizedBox(width: 10),
                  _buildFiltroChip("Clima"),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // BÚSQUEDAS RECIENTES (Se oculta si la lista está vacía)
            if (_busquedasRecientes.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0),
                child: Text(
                  "Búsquedas Recientes", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
              const SizedBox(height: 5),
              // Generamos la lista dinámicamente
              ..._busquedasRecientes.map((busqueda) => _buildBusquedaReciente(busqueda)),
              const SizedBox(height: 25),
            ],

            // SUGERENCIAS PARA TI
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: Text(
                "Sugerencias para ti", 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
            ),
            const SizedBox(height: 10),
            _buildSugerencia("Cayo Sombrero", 'assets/placeholder_playa.jpg'),
            _buildSugerencia("Isla de Plata", 'assets/placeholder_playa.jpg'),
            _buildSugerencia("Los Roques", 'assets/placeholder_playa.jpg'),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildFiltroChip(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        texto, 
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  // Diseño actualizado con botón para borrar
  Widget _buildBusquedaReciente(String texto) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: const Icon(Icons.history, color: Colors.black54),
      title: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: IconButton(
        icon: const Icon(Icons.close, color: Colors.grey, size: 20),
        onPressed: () => _eliminarBusqueda(texto), // 👈 Llama a la función de borrado
      ),
      onTap: () {
        // Lógica futura al tocar la búsqueda
      },
    );
  }

  Widget _buildSugerencia(String texto, String rutaImagen) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: CircleAvatar(
        radius: 18,
        backgroundImage: AssetImage(rutaImagen),
        backgroundColor: Colors.grey.shade200,
      ),
      title: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      onTap: () {
        // Lógica futura al tocar una sugerencia
      },
    );
  }
}