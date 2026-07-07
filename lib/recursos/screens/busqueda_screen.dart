import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba_eskpe/recursos/screens/destino_detalle_screen.dart'; // 👈 1. IMPORTANTE: Importamos Firestore

class BusquedaScreen extends StatefulWidget {
  const BusquedaScreen({super.key});

  @override
  State<BusquedaScreen> createState() => _BusquedaScreenState();
}

class _BusquedaScreenState extends State<BusquedaScreen> {
  // Variable de estado para controlar la lista de búsquedas
  final List<String> _busquedasRecientes = [];

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
              ..._busquedasRecientes.map((busqueda) => _buildBusquedaReciente(busqueda)),
              const SizedBox(height: 25),
            ],

            // SUGERENCIAS PARA TI (Ahora dinámicas desde Firebase 🌟)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: Text(
                "Sugerencias para ti", 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              // Usamos collectionGroup igual que en la Home por si tus destinos están en subcolecciones
              stream: FirebaseFirestore.instance
                  .collectionGroup('destinos')
                  .limit(5) // Limitamos a 5 sugerencias iniciales para no saturar
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(15.0),
                    child: Text('Error al cargar sugerencias...'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: Color(0xFF1E2A4F)),
                    ),
                  );
                }

                final docsSugerencias = snapshot.data?.docs ?? [];

                if (docsSugerencias.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.0),
                    child: Text('No hay sugerencias disponibles', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true, // 👈 OBLIGATORIO: Evita que explote dentro del SingleChildScrollView
                  physics: const NeverScrollableScrollPhysics(), // 👈 OBLIGATORIO: Deja que el scroll lo mande el padre
                  itemCount: docsSugerencias.length,
                  itemBuilder: (context, index) {
                    final datosSugerencia = docsSugerencias[index].data() as Map<String, dynamic>;
                    
                    return _buildSugerencia(
                      datosSugerencia['nombre'] ?? 'Sin nombre', 
                      datosSugerencia['rutaAsset'] ?? ''
                    );
                  },
                );
              },
            ),
            
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

  Widget _buildBusquedaReciente(String texto) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: const Icon(Icons.history, color: Colors.black54),
      title: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: IconButton(
        icon: const Icon(Icons.close, color: Colors.grey, size: 20),
        onPressed: () => _eliminarBusqueda(texto),
      ),
      onTap: () {},
    );
  }

  Widget _buildSugerencia(String nombre, String rutaAsset) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: CircleAvatar(
        radius: 18,
        // 🛠️ Controlamos si el String de la ruta viene vacío de Firebase para que no tire error de Asset
        backgroundImage: AssetImage(rutaAsset.isNotEmpty ? rutaAsset : 'assets/placeholder_playa.jpg'),
        backgroundColor: Colors.grey.shade200,
      ),
      title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      onTap: () {
      Navigator.push(
        context,
       MaterialPageRoute(builder: (context) => DestinoDetalleScreen(nombre: nombre, rutaAsset: rutaAsset)),
       ); // Lógica futura al tocar una sugerencia
      },
    );
  }
}