import 'package:flutter/material.dart';

import '../fuel_ader_storage.dart';
import '../models.dart';
import '../widgets/ader_actions_button.dart';

class CalculadoraTab extends StatefulWidget {
  final List<VentaRango> tablaVentas;
  final Map<String, AderFuelMes> fuelMeses;
  final TextEditingController costeController;
  final bool costeConFuelIncluido;
  final VoidCallback onCosteManualChanged;
  final ValueChanged<String> onUsarCosteConFuel;
  final ValueChanged<Map<String, AderFuelMes>> onFuelMesesChanged;
  final VoidCallback onTablaChanged;

  const CalculadoraTab({
    super.key,
    required this.tablaVentas,
    required this.fuelMeses,
    required this.costeController,
    required this.costeConFuelIncluido,
    required this.onCosteManualChanged,
    required this.onUsarCosteConFuel,
    required this.onFuelMesesChanged,
    required this.onTablaChanged,
  });

  @override
  State<CalculadoraTab> createState() => _CalculadoraTabState();
}

class _CalculadoraTabState extends State<CalculadoraTab> {
  String? _errorTexto;
  VentaRango? _rangoSeleccionado;
  List<ResultadoCategoria> _resultados = [];
  double? _costeActual;

  @override
  void initState() {
    super.initState();
    widget.costeController.addListener(_actualizarDesdeController);
    _actualizarDesdeController();
  }

  @override
  void didUpdateWidget(covariant CalculadoraTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.costeController != widget.costeController) {
      oldWidget.costeController.removeListener(_actualizarDesdeController);
      widget.costeController.addListener(_actualizarDesdeController);
    }

    _actualizarDesdeController();
  }

  @override
  void dispose() {
    widget.costeController.removeListener(_actualizarDesdeController);
    super.dispose();
  }

  void _actualizarDesdeController() {
    final value = widget.costeController.text;

    setState(() {
      if (value.trim().isEmpty) {
        _costeActual = null;
        _errorTexto = null;
        _rangoSeleccionado = null;
        _resultados = [];
        return;
      }

      final parsed = parseMoneyLike(value);

      if (parsed == null || parsed <= 0) {
        _costeActual = null;
        _errorTexto = 'Introduce un coste válido mayor que cero';
        _rangoSeleccionado = null;
        _resultados = [];
        return;
      }

      _costeActual = parsed;
      _errorTexto = null;
      _rangoSeleccionado = buscarRangoPorCoste(parsed, widget.tablaVentas);
      _resultados = calcularResultados(parsed, _rangoSeleccionado!);
    });
  }

  void _aceptarDebajoMin(int index) {
    setState(() => _resultados[index].aceptadoDebajoMin = true);
  }

  void _editarMargenes(String nombre) {
    if (_rangoSeleccionado == null) return;

    MargenRango? margen;
    bool esSinAprobacion = false;
    String titulo;

    switch (nombre) {
      case 'Sin aprobación':
        esSinAprobacion = true;
        titulo = 'Editar Sin aprobación';
        break;
      case 'Supervisor':
        margen = _rangoSeleccionado!.supervisor;
        titulo = 'Editar Supervisor';
        break;
      case 'Manager':
        margen = _rangoSeleccionado!.manager;
        titulo = 'Editar Manager';
        break;
      case 'Senior Manager':
        margen = _rangoSeleccionado!.seniorManager;
        titulo = 'Editar Senior Manager';
        break;
      default:
        return;
    }

    if (!esSinAprobacion && margen == null) return;

    final minActual = esSinAprobacion ? _rangoSeleccionado!.sinAprobacion! : margen!.min;
    final maxActual = esSinAprobacion ? _rangoSeleccionado!.sinAprobacion! : margen!.max;

    final minCtrl = TextEditingController(text: _formatDouble(minActual));
    final maxCtrl = TextEditingController(text: _formatDouble(maxActual));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: esSinAprobacion ? 'Margen %' : 'Mínimo %'),
            ),
            if (!esSinAprobacion)
              TextField(
                controller: maxCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Máximo %'),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final min = double.tryParse(minCtrl.text.replaceAll(',', '.'));
              final max = esSinAprobacion ? min : double.tryParse(maxCtrl.text.replaceAll(',', '.'));

              if (min != null && max != null) {
                setState(() {
                  if (esSinAprobacion) {
                    _rangoSeleccionado!.sinAprobacion = min;
                  } else {
                    margen!.min = min;
                    margen.max = max;
                  }

                  if (_costeActual != null) {
                    _rangoSeleccionado = buscarRangoPorCoste(_costeActual!, widget.tablaVentas);
                    _resultados = calcularResultados(_costeActual!, _rangoSeleccionado!);
                  }
                });

                widget.onTablaChanged();
              }

              Navigator.of(context).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  String _formatDouble(double v) => v.toStringAsFixed(2).replaceAll('.', ',');
  String _formatMoney(double v) => '€ ${_formatDouble(v)}';

  @override
  Widget build(BuildContext context) {
    final labelCoste = widget.costeConFuelIncluido
        ? 'Coste proveedor con fuel incluido'
        : 'Coste proveedor';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(labelCoste, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: widget.costeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Coste en €',
                        border: const OutlineInputBorder(),
                        errorText: _errorTexto,
                        prefixText: '€ ',
                      ),
                      onChanged: (_) => widget.onCosteManualChanged(),
                    ),
                  ],
                ),
              ),
              AderActionsButton(
                fuelMeses: widget.fuelMeses,
                costeController: widget.costeController,
                onUsarCosteConFuel: widget.onUsarCosteConFuel,
                onFuelMesesChanged: widget.onFuelMesesChanged,
              ),
              if (_rangoSeleccionado != null)
                SizedBox(
                  width: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rango seleccionado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('${_rangoSeleccionado!.ventaDesde.toInt()} – ${_rangoSeleccionado!.ventaHasta?.toInt() ?? '∞'}'),
                    ],
                  ),
                ),
            ],
          ),
          if (_resultados.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Resultados por rol', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: _resultados.asMap().entries.map((entry) {
                  final index = entry.key;
                  final r = entry.value;
                  final color = r.color;
                  final warning = r.estaPorDebajo && !r.aceptadoDebajoMin;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: color.withOpacity(0.10),
                      border: Border.all(color: warning ? Colors.red : color.withOpacity(0.4)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => _editarMargenes(r.nombre),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  minimumSize: const Size(0, 32),
                                ),
                                child: const Text('Editar margen', style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  r.nombre,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: color.darken(0.1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  r.margenMin == r.margenMax
                                      ? 'Margen: ${_formatDouble(r.margenMin)}%'
                                      : 'Mín: ${_formatDouble(r.margenMin)}%',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Expanded(
                                child: SelectableText(
                                  'Venta: ${_formatMoney(r.ventaMin)}',
                                  style: const TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Revao: ${_formatMoney(r.revaoMin)}',
                                  style: const TextStyle(fontSize: 12),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                          if (r.margenMin != r.margenMax) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(child: Text('Máx: ${_formatDouble(r.margenMax)}%', style: const TextStyle(fontSize: 12))),
                                Expanded(
                                  child: SelectableText(
                                    'Venta: ${_formatMoney(r.ventaMax)}',
                                    style: const TextStyle(fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Revao: ${_formatMoney(r.revaoMax)}',
                                    style: const TextStyle(fontSize: 12),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (warning) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Margen por debajo del mínimo. Aceptar para usar.',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                minimumSize: const Size(0, 32),
                              ),
                              onPressed: () => _aceptarDebajoMin(index),
                              child: const Text('Aceptar', style: TextStyle(fontSize: 12, color: Colors.white)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ] else if (_errorTexto == null)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text('Introduce un coste para ver los resultados.'),
            ),
        ],
      ),
    );
  }
}
