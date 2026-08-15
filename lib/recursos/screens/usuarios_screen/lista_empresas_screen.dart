//todas las empresas de la aplicacion
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba_eskpe/recursos/colores.dart';
import 'package:prueba_eskpe/recursos/screens/usuarios_screen/empresa_detalle_screen.dart';

class ListaEmpresasScreen extends StatelessWidget {
  const ListaEmpresasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Todas las Empresas",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.azuleskpe,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: AppColors.blancofondo,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .where('rol', isEqualTo: 'empresa')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay empresas disponibles"));
          }

          final docs = snapshot.data!.docs;

          // Usamos un GridView para que se vea más profesional que una lista simple
          // ... (mantiene tus importaciones y la clase hasta el itemBuilder)

          return GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.85,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              // 🛠️ AQUÍ ESTÁ EL CAMBIO: Extraemos la URL de la imagen del perfil/logo de la empresa (o el asset local como fallback)
              final String nombreSeguro = data['nombres'] ?? 'Sin nombre';
              final String rutaSegura =
                  data['fotoUrl'] ??
                  data['logoUrl'] ??
                  data['fotoPerfilUrl'] ??
                  data['imagenUrl'] ??
                  data['photoURL'] ??
                  data['rutaAsset'] ??
                  '';

              return _buildTarjetaDestino(
                context,
                nombreSeguro,
                rutaSegura,
                docs[index].id,
                data['telefono'] ?? '584263211350',
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTarjetaDestino(
    BuildContext context,
    String nombre,
    String ruta,
    String id,
    String telefono,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmpresaDetalleScreen(
              nombreEmpresa: nombre,
              rutaAsset: ruta,
              telefonoEmpresa: telefono,
              destinoId: id,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio:
                  1.2, // Relación de aspecto más horizontal para no cortar logos
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: _buildImagenEmpresa(ruta),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagenEmpresa(String ruta) {
    if (ruta.startsWith('http://') || ruta.startsWith('https://')) {
      return Image.network(
        ruta,
        fit: BoxFit.cover,
        width: double.infinity, // Mantenemos esto para que llene el espacio
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        // 👇 Reemplazo del ícono por la imagen local si hay error en la red
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/sinfoto.jpg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (ruta.isNotEmpty) {
      return Image.asset(
        ruta,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // 👇 Reemplazo del ícono por la imagen local si la ruta del asset falla
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/sinfoto.jpg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else {
      // 👇 Reemplazo del ícono por la imagen local si la ruta está completamente vacía
      return Image.asset(
        'assets/sinfoto.jpg',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
  }
}
