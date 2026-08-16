import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prueba_eskpe/recursos/colores.dart';
import 'package:prueba_eskpe/recursos/screens/empresas_screens/agregar_viajes_screen.dart';
import 'package:prueba_eskpe/recursos/screens/empresas_screens/editar_viaje_screen.dart';
import 'package:prueba_eskpe/recursos/screens/empresas_screens/solicitudes_viaje_screen.dart';
import 'package:prueba_eskpe/recursos/screens/login_screen.dart';
import 'package:prueba_eskpe/recursos/screens/empresas_screens/mis_datos_empresa_screen.dart';
import 'package:prueba_eskpe/recursos/fcm_service.dart';

class HomeEmpresaScreen extends StatefulWidget {
  const HomeEmpresaScreen({super.key});

  @override
  State<HomeEmpresaScreen> createState() => _HomeEmpresaScreenState();
}

class _HomeEmpresaScreenState extends State<HomeEmpresaScreen> {
  String _nombreEmpresa = 'Mi Empresa';
  String _rifEmpresa = '';
  String _fotoUrl = '';
  bool _cargandoDatos = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosEmpresa();
    FCMService.inicializarFCM();
  }

  Future<void> _cargarDatosEmpresa() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _nombreEmpresa = data['nombres'] ?? data['razon_social'] ?? data['nombre'] ?? 'Mi Empresa';
            _rifEmpresa = data['documento'] ?? data['cedula'] ?? data['rif'] ?? '';
            _fotoUrl = data['fotoUrl'] ?? data['logoUrl'] ?? data['imagenPerfil'] ?? '';
            _cargandoDatos = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error al cargar datos de empresa: $e");
      if (mounted) setState(() => _cargandoDatos = false);
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Estás seguro de que deseas salir del panel de empresa?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA53030)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Cerrar Sesión", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _eliminarViaje(String viajeId, String nombreDestino) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Eliminar Viaje"),
        content: Text("¿Seguro que deseas eliminar el viaje hacia \"$nombreDestino\"? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('viajes').doc(viajeId).delete();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Viaje eliminado correctamente"), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error al eliminar: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          "Panel de Empresa",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.azuleskpe,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            tooltip: "Mis Datos",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MisDatosEmpresaScreen()),
              ).then((_) {
                _cargarDatosEmpresa();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: "Cerrar Sesión",
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      // floatingActionButton removido
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con bienvenida a la empresa
            _buildCompanyHeader(),

            const SizedBox(height: 20),

            // Tarjetas de Acceso Rápido
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const Text(
                "Gestión Rápida",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2A4F),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickAccessGrid(context),

            const SizedBox(height: 25),

            // Título Sección de Viajes Publicados
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Mis Viajes Publicados",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2A4F),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Lista de Viajes de la Empresa
            _buildViajesStream(user),

            const SizedBox(height: 20), // Ajuste de espacio al final
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.azuleskpe,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: _fotoUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      _fotoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.business_rounded, color: Colors.white, size: 36),
                    ),
                  )
                : const Icon(Icons.business_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _cargandoDatos ? "Cargando empresa..." : _nombreEmpresa,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.lightBlueAccent, size: 16),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _rifEmpresa.isNotEmpty ? "RIF: $_rifEmpresa" : "Cuenta de Empresa Aliada",
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          // Botón Grande 1: Agregar Viaje Nuevo
          Expanded(
            child: _buildActionCard(
              context: context,
              icon: Icons.add_location_alt_rounded,
              color: AppColors.azulEskpe,
              title: "Publicar Viaje",
              subtitle: "Agregar nuevo destino y cupos",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AgregarViajeScreen()),
                );
              },
            ),
          ),
          const SizedBox(width: 15),
          // Botón Grande 2: Perfil de Datos
          Expanded(
            child: _buildActionCard(
              context: context,
              icon: Icons.assignment_outlined,
              color: const Color(0xFF4A3AFF),
              title: "Mis Datos",
              subtitle: "Configuración de la cuenta",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MisDatosEmpresaScreen()),
                ).then((_) {
                  _cargarDatosEmpresa();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1E2A4F),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViajesStream(User? user) {
    if (user == null) {
      return const Center(child: Text("Sin usuario autenticado."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('viajes')
          .where('empresaId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30.0),
              child: CircularProgressIndicator(color: Color(0xFF1E2A4F)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("Error al cargar viajes: ${snapshot.error}"),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final viajes = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: viajes.length,
          itemBuilder: (context, index) {
            final doc = viajes[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildTarjetaViaje(context, doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.directions_bus_filled_outlined, size: 70, color: Colors.grey.shade400),
          const SizedBox(height: 15),
          const Text(
            "Aún no tienes viajes publicados",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "Toca el botón 'Publicar Viaje' para comenzar a ofrecer tus servicios a los clientes.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulEskpe,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AgregarViajeScreen()),
              );
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Publicar mi primer viaje", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaViaje(BuildContext context, String viajeId, Map<String, dynamic> data) {
    String destinoId = data['destinoId'] ?? '';

    if (destinoId.isEmpty) {
      return _tarjetaContenido(context, viajeId, data, "Destino Desconocido", data['rutaAsset'] ?? '');
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('destinos').doc(destinoId).get(),
      builder: (context, snapshot) {
        String nombre = "Cargando...";
        String ruta = data['rutaAsset'] ?? '';

        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.exists) {
            nombre = snapshot.data!['nombre'] ?? 'Destino Desconocido';
            String assetDestino = snapshot.data!['rutaAsset'] ?? '';
            if (assetDestino.isNotEmpty) ruta = assetDestino;
          } else {
            nombre = "Destino Desconocido";
          }
        }

        return _tarjetaContenido(context, viajeId, data, nombre, ruta);
      },
    );
  }

  Widget _tarjetaContenido(
    BuildContext context,
    String viajeId,
    Map<String, dynamic> data,
    String nombreDestino,
    String rutaAsset,
  ) {
    String fechaStr = 'Fecha no definida';
    if (data['fecha'] != null) {
      final dt = (data['fecha'] as Timestamp).toDate();
      fechaStr = "${dt.day}/${dt.month}/${dt.year}";
    }

    String horaSalida = data['horaSalida'] ?? 'Por definir';
    String puntoSalida = data['puntoSalida'] ?? 'Por definir';

    String precioStr = "\$0";
    if (data['planes'] != null && (data['planes'] as List).isNotEmpty) {
      List planes = data['planes'];
      double minPrice = planes
          .map((p) => double.tryParse(p['precio']?.toString() ?? '0') ?? 0.0)
          .reduce((a, b) => a < b ? a : b);
      precioStr = "Desde \$${minPrice.toStringAsFixed(minPrice.truncateToDouble() == minPrice ? 0 : 2)}";
    } else {
      String precio = data['precioPorPuesto']?.toString() ?? data['precio']?.toString() ?? '0';
      precioStr = "\$$precio";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: rutaAsset.startsWith('http')
                          ? Image.network(
                              rutaAsset,
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 110,
                                height: 110,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image_not_supported, color: Colors.grey),
                              ),
                            )
                          : Image.asset(
                              rutaAsset.isNotEmpty ? rutaAsset : 'assets/sinfoto.jpg',
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 110,
                                height: 110,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image_not_supported, color: Colors.grey),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _buildBadgeReservasPendientes(viajeId),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0, right: 12.0, bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              nombreDestino,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E2A4F)),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onSelected: (value) {
                              if (value == 'editar') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditarViajeScreen(viajeId: viajeId, datosViaje: data),
                                  ),
                                );
                              } else if (value == 'solicitudes') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SolicitudesViajeScreen(viajeId: viajeId, nombreViaje: nombreDestino),
                                  ),
                                );
                              } else if (value == 'eliminar') {
                                _eliminarViaje(viajeId, nombreDestino);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'solicitudes',
                                child: Row(
                                  children: [
                                    Icon(Icons.people_outline, color: Color(0xFF4A3AFF), size: 20),
                                    SizedBox(width: 10),
                                    Text("Ver Solicitudes"),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'editar',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, color: Colors.orange, size: 20),
                                    SizedBox(width: 10),
                                    Text("Editar Viaje"),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'eliminar',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    SizedBox(width: 10),
                                    Text("Eliminar Viaje", style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(fechaStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(width: 12),
                          const Icon(Icons.attach_money, size: 14, color: Color(0xFFB8860B)),
                          Text(precioStr, style: const TextStyle(fontSize: 13, color: Color(0xFFB8860B), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(horaSalida, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(puntoSalida, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Puestos: ${data['puestosDisponibles'] ?? 0}/${data['puestosTotales'] ?? 0}",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1, indent: 15, endIndent: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SolicitudesViajeScreen(viajeId: viajeId, nombreViaje: nombreDestino),
                      ),
                    );
                  },
                  icon: const Icon(Icons.assignment_turned_in_outlined, size: 16, color: Color(0xFF4A3AFF)),
                  label: const Text("Solicitudes", style: TextStyle(color: Color(0xFF4A3AFF), fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditarViajeScreen(viajeId: viajeId, datosViaje: data),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                  label: const Text("Editar", style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBadgeReservasPendientes(String viajeId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservaciones')
          .where('viajeId', isEqualTo: viajeId)
          .where('estado', isEqualTo: 'Pendiente')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(); 
        }
        int cantidadPendientes = snapshot.data!.docs.length;
        
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Text(
            cantidadPendientes.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
