const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

// 1. Notificación a la Empresa cuando se crea una reserva
exports.notificarNuevaReserva = onDocumentCreated("reservaciones/{reservaId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const data = snap.data();
  const empresaId = data.empresaId;
  const nombreViaje = data.viajeNombre || "un viaje";

  if (!empresaId) return;

  const empresaDoc = await db.collection("usuarios").doc(empresaId).get();
  if (!empresaDoc.exists) return;

  const fcmToken = empresaDoc.data().fcmToken;
  if (!fcmToken) return;

  const payload = {
    notification: {
      title: "Nueva Reserva",
      body: `Tienes una reservación PENDIENTE para el viaje ${nombreViaje}`,
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      tipo: "NUEVA_RESERVA",
      reservaId: event.params.reservaId,
      viajeId: data.viajeId || ""
    },
    token: fcmToken
  };

  return messaging.send(payload);
});

// 2. Notificación al Usuario cuando cambia el estado de la reserva
exports.notificarCambioEstadoReserva = onDocumentUpdated("reservaciones/{reservaId}", async (event) => {
  const change = event.data;
  if (!change) return;

  const dataAnterior = change.before.data();
  const dataNueva = change.after.data();

  if (dataAnterior.estado === dataNueva.estado) return;

  if (dataNueva.estado !== "Aceptada" && dataNueva.estado !== "Rechazada" && dataNueva.estado !== "Cancelada") return;

  const usuarioId = dataNueva.usuarioId;
  const nombreViaje = dataNueva.viajeNombre || "tu viaje";

  if (!usuarioId) return;

  const usuarioDoc = await db.collection("usuarios").doc(usuarioId).get();
  if (!usuarioDoc.exists) return;

  const fcmToken = usuarioDoc.data().fcmToken;
  if (!fcmToken) return;

  const payload = {
    notification: {
      title: `Reserva ${dataNueva.estado}`,
      body: `Tu reserva para ${nombreViaje} ha sido ${dataNueva.estado.toLowerCase()}.`,
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      tipo: "ESTADO_RESERVA",
      reservaId: event.params.reservaId
    },
    token: fcmToken
  };

  return messaging.send(payload);
});
