import 'package:flutter/material.dart';

double toDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? fallback;
  return fallback;
}

class MargenRango {
  double min;
  double max;

  MargenRango(this.min, this.max);

  Map<String, dynamic> toJson() => {
        'min': min,
        'max': max,
      };

  factory MargenRango.fromJson(Map<String, dynamic> json) {
    return MargenRango(
      toDouble(json['min']),
      toDouble(json['max']),
    );
  }
}

class VentaRango {
  double ventaDesde;
  double? ventaHasta;
  double? sinAprobacion;
  MargenRango? supervisor;
  MargenRango? manager;
  MargenRango? seniorManager;

  VentaRango({
    required this.ventaDesde,
    this.ventaHasta,
    this.sinAprobacion,
    this.supervisor,
    this.manager,
    this.seniorManager,
  });

  Map<String, dynamic> toJson() => {
        'ventaDesde': ventaDesde,
        'ventaHasta': ventaHasta,
        'sinAprobacion': sinAprobacion,
        'supervisor': supervisor?.toJson(),
        'manager': manager?.toJson(),
        'seniorManager': seniorManager?.toJson(),
      };

  factory VentaRango.fromJson(Map<String, dynamic> json) {
    return VentaRango(
      ventaDesde: toDouble(json['ventaDesde']),
      ventaHasta: json['ventaHasta'] == null ? null : toDouble(json['ventaHasta']),
      sinAprobacion: json['sinAprobacion'] == null ? null : toDouble(json['sinAprobacion']),
      supervisor: json['supervisor'] == null
          ? null
          : MargenRango.fromJson(Map<String, dynamic>.from(json['supervisor'])),
      manager: json['manager'] == null
          ? null
          : MargenRango.fromJson(Map<String, dynamic>.from(json['manager'])),
      seniorManager: json['seniorManager'] == null
          ? null
          : MargenRango.fromJson(Map<String, dynamic>.from(json['seniorManager'])),
    );
  }
}

class ResultadoCategoria {
  final String nombre;
  final double coste;
  final double margenMin;
  final double margenMax;
  double margenActual;
  final Color color;
  bool aceptadoDebajoMin;

  ResultadoCategoria({
    required this.nombre,
    required this.coste,
    required this.margenMin,
    required this.margenMax,
    required this.margenActual,
    required this.color,
    this.aceptadoDebajoMin = false,
  });

  bool get estaPorDebajo => margenActual < margenMin;
  double get ventaMin => calcularVenta(coste, margenMin);
  double get ventaMax => calcularVenta(coste, margenMax);
  double get revaoMin => calcularRevao(coste, ventaMin);
  double get revaoMax => calcularRevao(coste, ventaMax);
}

List<VentaRango> defaultTablaVentas() {
  return [
    VentaRango(ventaDesde: 0, ventaHasta: 99, sinAprobacion: 35),
    VentaRango(ventaDesde: 100, ventaHasta: 249, sinAprobacion: 30),
    VentaRango(ventaDesde: 250, ventaHasta: 849, sinAprobacion: 25),
    VentaRango(
      ventaDesde: 850,
      ventaHasta: 1749,
      sinAprobacion: 22.5,
      supervisor: MargenRango(20, 22.4),
    ),
    VentaRango(
      ventaDesde: 1750,
      ventaHasta: 2249,
      sinAprobacion: 20,
      supervisor: MargenRango(17.5, 19.9),
    ),
    VentaRango(
      ventaDesde: 2250,
      ventaHasta: 3499,
      sinAprobacion: 20,
      supervisor: MargenRango(15, 19.9),
    ),
    VentaRango(
      ventaDesde: 3500,
      ventaHasta: 5499,
      sinAprobacion: 20,
      supervisor: MargenRango(15, 19.9),
      manager: MargenRango(12.5, 14.9),
    ),
    VentaRango(
      ventaDesde: 5500,
      ventaHasta: 9999,
      sinAprobacion: 20,
      supervisor: MargenRango(15, 19.9),
      manager: MargenRango(12.6, 14.9),
      seniorManager: MargenRango(10, 12.5),
    ),
    VentaRango(
      ventaDesde: 10000,
      ventaHasta: null,
      sinAprobacion: 15,
      seniorManager: MargenRango(10, 12.5),
    ),
  ];
}

VentaRango buscarRangoPorCoste(double coste, List<VentaRango> tablaVentas) {
  for (final rango in tablaVentas) {
    final venta = calcularVenta(coste, rango.sinAprobacion ?? 0);

    if (rango.ventaHasta == null || venta <= rango.ventaHasta!) {
      return rango;
    }
  }

  return tablaVentas.last;
}

double calcularVenta(double coste, double margen) {
  return coste / (1 - margen / 100);
}

double calcularRevao(double coste, double venta) {
  return venta - coste;
}

List<ResultadoCategoria> calcularResultados(double coste, VentaRango rango) {
  final resultados = <ResultadoCategoria>[];

  resultados.add(ResultadoCategoria(
    nombre: 'Sin aprobación',
    coste: coste,
    margenMin: rango.sinAprobacion!,
    margenMax: rango.sinAprobacion!,
    margenActual: rango.sinAprobacion!,
    color: Colors.blue.shade700,
  ));

  if (rango.supervisor != null) {
    resultados.add(ResultadoCategoria(
      nombre: 'Supervisor',
      coste: coste,
      margenMin: rango.supervisor!.min,
      margenMax: rango.supervisor!.max,
      margenActual: rango.supervisor!.min,
      color: Colors.orange.shade700,
    ));
  }

  if (rango.manager != null) {
    resultados.add(ResultadoCategoria(
      nombre: 'Manager',
      coste: coste,
      margenMin: rango.manager!.min,
      margenMax: rango.manager!.max,
      margenActual: rango.manager!.min,
      color: Colors.green.shade700,
    ));
  }

  if (rango.seniorManager != null) {
    resultados.add(ResultadoCategoria(
      nombre: 'Senior Manager',
      coste: coste,
      margenMin: rango.seniorManager!.min,
      margenMax: rango.seniorManager!.max,
      margenActual: rango.seniorManager!.min,
      color: Colors.teal.shade700,
    ));
  }

  return resultados;
}

extension ColorTools on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}
