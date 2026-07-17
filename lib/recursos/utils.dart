import 'package:url_launcher/url_launcher.dart';

class AppUtils {
  static Future<void> abrirWhatsApp(String numeroTelefono, String nombreEmpresa) async {
    // Codificamos el mensaje para asegurar que los espacios y caracteres funcionen en la URL
    String mensaje = Uri.encodeComponent("Hola, estoy interesado en los viajes de $nombreEmpresa.");
    final Uri whatsappUrl = Uri.parse("https://wa.me/$numeroTelefono?text=$mensaje");
    
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'No se pudo abrir WhatsApp';
    }
  }
}