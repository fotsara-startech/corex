import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Affiche un snackbar GetX uniquement si un Overlay est disponible.
/// Évite le crash "No Overlay widget found" quand appelé après une navigation.
void safeSnackbar(
  String title,
  String message, {
  Color? backgroundColor,
  Color? colorText,
  Duration duration = const Duration(seconds: 3),
}) {
  try {
    // Vérifier que le contexte de navigation GetX est disponible
    if (Get.overlayContext == null) return;
    // Vérifier que l'Overlay est bien monté
    final overlay = Overlay.maybeOf(Get.overlayContext!);
    if (overlay == null) return;

    Get.snackbar(
      title,
      message,
      backgroundColor: backgroundColor,
      colorText: colorText,
      duration: duration,
    );
  } catch (_) {
    // Silently ignore — l'Overlay n'est pas disponible
  }
}
