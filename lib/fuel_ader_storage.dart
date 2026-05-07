import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const String fuelAderPrefsKey = 'fuel_ader_meses_v2';

const List<String> aderMesesOrden = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

class AderFuelMes {
  final String mes;
  final int anio;
  final double local;
  final double nacional;

  const AderFuelMes({
    required this.mes,
    required this.anio,
    required this.local,
    required this.nacional,
  });

  String get id {
    final month = (aderMesesOrden.indexOf(mes.toLowerCase()) + 1).clamp(1, 12);
    return '$anio-${month.toString().padLeft(2, '0')}';
  }

  String get label => '${mes.toLowerCase()} $anio';

  Map<String, dynamic> toJson() => {
        'mes': mes.toLowerCase(),
        'anio': anio,
        'local': local,
        'nacional': nacional,
      };

  factory AderFuelMes.fromJson(String fallbackKey, Map<String, dynamic> json) {
    final fallbackParts = fallbackKey.split('-');
    final fallbackYear = fallbackParts.isNotEmpty ? int.tryParse(fallbackParts.first) : null;
    final fallbackMonthNumber = fallbackParts.length > 1 ? int.tryParse(fallbackParts[1]) : null;
    final fallbackMonth = fallbackMonthNumber == null
        ? fallbackKey.toLowerCase()
        : aderMesesOrden[(fallbackMonthNumber - 1).clamp(0, 11)];

    return AderFuelMes(
      mes: (json['mes'] ?? fallbackMonth).toString().toLowerCase(),
      anio: _toInt(json['anio'], fallbackYear ?? DateTime.now().year),
      local: _toDouble(json['local']),
      nacional: _toDouble(json['nacional']),
    );
  }
}

double _toDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? fallback;
  return fallback;
}

int _toInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int mesIndex(String mes) {
  final i = aderMesesOrden.indexOf(mes.toLowerCase());
  return i < 0 ? 99 : i;
}

Map<String, AderFuelMes> defaultFuelAderMeses() {
  return {
    '2026-04': const AderFuelMes(
      mes: 'abril',
      anio: 2026,
      local: 1.701,
      nacional: 2.992,
    ),
  };
}

List<AderFuelMes> ordenarFuelMeses(Map<String, AderFuelMes> meses) {
  final values = meses.values.toList();

  values.sort((a, b) {
    final yearCompare = a.anio.compareTo(b.anio);
    if (yearCompare != 0) return yearCompare;
    return mesIndex(a.mes).compareTo(mesIndex(b.mes));
  });

  return values;
}

AderFuelMes? ultimoFuelMes(Map<String, AderFuelMes> meses) {
  final ordenados = ordenarFuelMeses(meses);
  if (ordenados.isEmpty) return null;
  return ordenados.last;
}

Future<Map<String, AderFuelMes>> cargarFuelAderMeses() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(fuelAderPrefsKey);

  if (raw == null || raw.trim().isEmpty) {
    return defaultFuelAderMeses();
  }

  try {
    final decoded = jsonDecode(raw);

    if (decoded is! Map) {
      return defaultFuelAderMeses();
    }

    final result = <String, AderFuelMes>{};

    decoded.forEach((key, value) {
      final item = AderFuelMes.fromJson(
        key.toString(),
        Map<String, dynamic>.from(value),
      );
      result[item.id] = item;
    });

    if (result.isEmpty) {
      return defaultFuelAderMeses();
    }

    return result;
  } catch (_) {
    return defaultFuelAderMeses();
  }
}

Future<void> guardarFuelAderMeses(Map<String, AderFuelMes> meses) async {
  final prefs = await SharedPreferences.getInstance();

  final encoded = jsonEncode(
    meses.map((key, value) => MapEntry(value.id, value.toJson())),
  );

  await prefs.setString(fuelAderPrefsKey, encoded);
}

double? parseMoneyLike(String value) {
  var clean = value.replaceAll('€', '').replaceAll(' ', '');

  if (clean.contains(',')) {
    clean = clean.replaceAll('.', '').replaceAll(',', '.');
  }

  return double.tryParse(clean);
}

String fmt2(double value) => value.toStringAsFixed(2).replaceAll('.', ',');
String fmt3(double value) => value.toStringAsFixed(3).replaceAll('.', ',');
String fuelTo4Digits(double value) => (value * 1000).round().toString();

class AderResultado {
  final double coste;
  final AderFuelMes mesFuel;
  final double fuelLocal;
  final double fuelNacional;
  final double totalLocal;
  final double totalNacional;

  const AderResultado({
    required this.coste,
    required this.mesFuel,
    required this.fuelLocal,
    required this.fuelNacional,
    required this.totalLocal,
    required this.totalNacional,
  });
}

AderResultado? calcularAderFuel(String costeText, AderFuelMes? mesFuel) {
  if (mesFuel == null) return null;

  final coste = parseMoneyLike(costeText);
  if (coste == null || coste <= 0) return null;

  final fuelLocal = coste * mesFuel.local / 100;
  final fuelNacional = coste * mesFuel.nacional / 100;

  return AderResultado(
    coste: coste,
    mesFuel: mesFuel,
    fuelLocal: fuelLocal,
    fuelNacional: fuelNacional,
    totalLocal: coste + fuelLocal,
    totalNacional: coste + fuelNacional,
  );
}
