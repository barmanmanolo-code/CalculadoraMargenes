import 'package:flutter/material.dart';

import '../models.dart';

class TablaVentasTab extends StatefulWidget {
  final List<VentaRango> tablaVentas;
  final VoidCallback onTablaChanged;

  const TablaVentasTab({
    super.key,
    required this.tablaVentas,
    required this.onTablaChanged,
  });

  @override
  State<TablaVentasTab> createState() => _TablaVentasTabState();
}

class _TablaVentasTabState extends State<TablaVentasTab> {
  int _editingIndex = -1;

  String _fmt(double? v) {
    if (v == null || v == 0) return '';
    return v.toStringAsFixed(2).replaceAll('.', ',');
  }

  void _recalcularDesde() {
    double siguiente = 0;

    for (final r in widget.tablaVentas) {
      r.ventaDesde = siguiente;

      if (r.ventaHasta != null) {
        if (r.ventaHasta! < r.ventaDesde) r.ventaHasta = r.ventaDesde;
        siguiente = r.ventaHasta! + 1;
      } else {
        break;
      }
    }
  }

  Future<void> _eliminarRango(int index) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar rango'),
        content: const Text('¿Seguro que quieres borrar este rango?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      widget.tablaVentas.removeAt(index);

      if (_editingIndex == index) _editingIndex = -1;
      if (_editingIndex > index) _editingIndex--;

      _recalcularDesde();
    });

    widget.onTablaChanged();
  }

  void _anadirRango() {
    final ultimo = widget.tablaVentas.isNotEmpty ? widget.tablaVentas.last : null;
    final nuevoDesde = ultimo == null
        ? 0.0
        : ((ultimo.ventaHasta ?? ultimo.ventaDesde) + 1).toDouble();

    setState(() {
      widget.tablaVentas.add(VentaRango(
        ventaDesde: nuevoDesde,
        ventaHasta: nuevoDesde + 99,
        sinAprobacion: 0,
        supervisor: MargenRango(0, 0),
        manager: MargenRango(0, 0),
        seniorManager: MargenRango(0, 0),
      ));

      _editingIndex = widget.tablaVentas.length - 1;
    });

    widget.onTablaChanged();
  }

  static const double _wRango = 100;
  static const double _wHasta = 90;
  static const double _wSinAp = 96;
  static const double _wMin = 72;
  static const double _wMax = 72;
  static const double _wAccion = 82;

  Color get _sinApColor => Colors.blue.shade700;
  Color get _supervisorColor => Colors.orange.shade700;
  Color get _managerColor => Colors.green.shade700;
  Color get _seniorColor => Colors.teal.shade700;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tabla márgenes de contribución',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const Divider(height: 2, thickness: 2),
                      ...widget.tablaVentas.asMap().entries.map(
                            (e) => _buildFila(
                              e.key,
                              e.value,
                              _editingIndex == e.key,
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _anadirRango,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir rango'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _groupHeader('Rango', _wRango + _wHasta, Colors.grey.shade700),
              _groupHeader('Sin aprobación', _wSinAp, _sinApColor),
              _groupHeader('Supervisor', _wMin + _wMax, _supervisorColor),
              _groupHeader('Manager', _wMin + _wMax, _managerColor),
              _groupHeader('Senior Manager', _wMin + _wMax, _seniorColor),
              _groupHeader('', _wAccion, Colors.grey.shade700),
            ],
          ),
          Row(
            children: [
              _subHeader('Desde', _wRango),
              _subHeader('Hasta', _wHasta),
              _subHeader('%', _wSinAp, color: _sinApColor),
              _subHeader('Mín', _wMin, color: _supervisorColor),
              _subHeader('Máx', _wMax, color: _supervisorColor),
              _subHeader('Mín', _wMin, color: _managerColor),
              _subHeader('Máx', _wMax, color: _managerColor),
              _subHeader('Mín', _wMin, color: _seniorColor),
              _subHeader('Máx', _wMax, color: _seniorColor),
              _subHeader('', _wAccion),
            ],
          ),
        ],
      ),
    );
  }

  Widget _groupHeader(String text, double width, Color color) {
    return Container(
      width: width,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color.darken(0.1),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _subHeader(String text, double width, {Color? color}) {
    final c = color ?? Colors.black54;

    return Container(
      width: width,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color == null ? Colors.grey.shade50 : color.withOpacity(0.07),
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: c,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFila(int index, VentaRango rango, bool isEditing) {
    final bg = isEditing
        ? Colors.blue.shade50
        : (index.isEven ? Colors.white : Colors.grey.shade50);

    final hasta = rango.ventaHasta == null ? '∞' : rango.ventaHasta!.toInt().toString();

    return Container(
      color: bg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: _wRango,
                  child: Text(
                    '${rango.ventaDesde.toInt()} – $hasta',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                _buildCell(
                  width: _wHasta,
                  enabled: isEditing,
                  value: rango.ventaHasta == null
                      ? ''
                      : (rango.ventaHasta! + 1).toStringAsFixed(0),
                  color: Colors.grey.shade700,
                  onChanged: (v) {
                    final p = double.tryParse(v.replaceAll(',', '.'));

                    if (p != null) {
                      rango.ventaHasta = p - 1;
                    } else if (v.trim().isEmpty) {
                      rango.ventaHasta = null;
                    }

                    setState(() => _recalcularDesde());
                    widget.onTablaChanged();
                  },
                ),
                _buildCell(
                  width: _wSinAp,
                  enabled: isEditing,
                  value: _fmt(rango.sinAprobacion),
                  color: _sinApColor,
                  onChanged: (v) {
                    final p = double.tryParse(v.replaceAll(',', '.'));

                    setState(() {
                      rango.sinAprobacion = p ?? 0;
                    });

                    widget.onTablaChanged();
                  },
                ),
                _buildCell(
                  width: _wMin,
                  enabled: isEditing,
                  value: _fmt(rango.supervisor?.min),
                  color: _supervisorColor,
                  onChanged: (v) {
                    final p = double.tryParse(v.replaceAll(',', '.'));

                    setState(() {
                      rango.supervisor ??= MargenRango(0, 0);
                      rango.supervisor!.min = p ?? 0;
                    });

                    widget.onTablaChanged();
                  },
                ),
                _buildCell(
                  width: _wMax,
                  enabled: isEditing,
                  value: _fmt(rango.supervisor?.max),
                  color: _supervisorColor,
                  onChanged: (v) {
                    final p = double.tryParse(v.replaceAll(',', '.'));

                    setState(() {
                      rango.supervisor ??= MargenRango(0, 0);
                      rango.supervisor!.max = p ?? 0;
                    });

                    widget.onTablaChanged();
                  },
                ),
                _buildCell(
                  width: _wMin,
                  enabled: isEditing,
                  value: _fmt(rango.manager?.min),
                  color: _managerColor,
                  onChanged: (v) {
                    final p = double.tryParse(v.replaceAll(',', '.'));

                    setState(() {
                      rango.manager ??= MargenRango(0, 0);
                      rango.manager!.min = p ?? 0;
                    });

                    widget.onTablaChanged();
                  },
                ),
                _buildCell(
                  width: _wMax,
                  enabled: isEditing,
                  value: _fmt(rango.manager?.max),
                  color: _managerColor,
                  onChanged: (v) {
                    final p = double.tryParse(v.replaceAll(',', '.'));

                    setState(() {
                      rango.manager ??= MargenRango(0, 0);
                      rango.manager!.max = p ?? 0;
                    });

                    widget.onTablaChanged();
                  },
                ),
                _buildCell(
                  width: _wMin,
                  enabled: isEditing,
                  value: _fmt(rango.seniorManager?.min),
                  color: _seniorColor,
                  onChanged: (v) {
                    final p = double.tryParse(v.replaceAll(',', '.'));

                    setState(() {
                      rango.seniorManager ??= MargenRango(0, 0);
                      rango.seniorManager!.min = p ?? 0;
                    });

                    widget.onTablaChanged();
                  },
                ),
                _buildCell(
                  width: _wMax,
                  enabled: isEditing,
                  value: _fmt(rango.seniorManager?.max),
                  color: _seniorColor,
                  onChanged: (v) {
                    final p = double.tryParse(v.replaceAll(',', '.'));

                    setState(() {
                      rango.seniorManager ??= MargenRango(0, 0);
                      rango.seniorManager!.max = p ?? 0;
                    });

                    widget.onTablaChanged();
                  },
                ),
                SizedBox(
                  width: _wAccion,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isEditing)
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: () => setState(() => _editingIndex = index),
                          tooltip: 'Editar',
                        )
                      else
                        IconButton(
                          icon: Icon(
                            Icons.check_circle,
                            color: Colors.green.shade700,
                            size: 22,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: () {
                            setState(() => _editingIndex = -1);
                            widget.onTablaChanged();
                          },
                          tooltip: 'Guardar',
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () => _eliminarRango(index),
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildCell({
    required double width,
    required bool enabled,
    required String value,
    required ValueChanged<String> onChanged,
    required Color color,
  }) {
    final isBlank = value.trim().isEmpty;

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: enabled
            ? _EditableCell(
                initialValue: value,
                color: color,
                onChanged: onChanged,
              )
            : isBlank
                ? const SizedBox(height: 34)
                : Container(
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: color.withOpacity(0.28)),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color.darken(0.08),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
      ),
    );
  }
}

class _EditableCell extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final Color color;

  const _EditableCell({
    required this.initialValue,
    required this.onChanged,
    required this.color,
  });

  @override
  State<_EditableCell> createState() => _EditableCellState();
}

class _EditableCellState extends State<_EditableCell> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: TextField(
        controller: _ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: widget.color.darken(0.08),
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: widget.color.withOpacity(0.08),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: widget.color.withOpacity(0.28)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: widget.color.withOpacity(0.28)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: widget.color, width: 1.5),
          ),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
