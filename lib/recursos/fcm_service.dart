import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FCMService {
  static Future<void> inicializarFCM() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();

      if (token != null) {
        await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set(
          {'fcmToken': token},
          SetOptions(merge: true),
        );
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set(
          {'fcmToken': newToken},
          SetOptions(merge: true),
        );
      });
    }

    // Configurar el listener para cuando la app está en segundo plano o cerrada y el usuario toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Notificación tocada con datos: ${message.data}");
    });
  }
}
