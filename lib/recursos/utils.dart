import 'package:url_launcher/url_launcher.dart';

class AppUtils {
  /// Normaliza un número de teléfono venezolano a formato internacional
  /// para que WhatsApp pueda abrirlo correctamente.
  static String _normalizarTelefono(String numero) {
    // Eliminar espacios, guiones y paréntesis
    String limpio = numero.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Si ya tiene '+', quitarlo (wa.me no usa '+')
    if (limpio.startsWith('+')) {
      limpio = limpio.substring(1);
    }

    // Si empieza con '0' (formato local venezolano: 0414...), reemplazar con 58
    if (limpio.startsWith('0')) {
      limpio = '58${limpio.substring(1)}';
    }

    return limpio;
  }

  static Future<void> abrirWhatsApp(
    String numeroTelefono,
    String nombreEmpresa,
  ) async {
    final String numeroNormalizado = _normalizarTelefono(numeroTelefono);
    // Codificamos el mensaje para asegurar que los espacios y caracteres funcionen en la URL
    String mensaje = Uri.encodeComponent(
      "Hola, estoy interesado en los viajes de $nombreEmpresa.",
    );
    final Uri whatsappUrl = Uri.parse(
      "https://wa.me/$numeroNormalizado?text=$mensaje",
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'No se pudo abrir WhatsApp';
    }
  }
}
