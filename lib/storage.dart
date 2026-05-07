import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

const String tablaVentasPrefsKey = 'tabla_ventas_guardada_v1';

Future<List<VentaRango>> cargarTablaVentas() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(tablaVentasPrefsKey);

  if (raw == null || raw.trim().isEmpty) {
    return defaultTablaVentas();
  }

  try {
    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      return defaultTablaVentas();
    }

    final tabla = decoded
        .map((item) => VentaRango.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    if (tabla.isEmpty) {
      return defaultTablaVentas();
    }

    return tabla;
  } catch (_) {
    return defaultTablaVentas();
  }
}

Future<void> guardarTablaVentas(List<VentaRango> tablaVentas) async {
  final prefs = await SharedPreferences.getInstance();
  final encoded = jsonEncode(tablaVentas.map((r) => r.toJson()).toList());
  await prefs.setString(tablaVentasPrefsKey, encoded);
}
