import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../fuel_ader_storage.dart';
import '../tabs/editor_fuel_tab.dart';

enum AderAction {
  importeFuel,
  plantillaCorreo,
  modificarFuel,
}

class AderActionsButton extends StatelessWidget {
  final Map<String, AderFuelMes> fuelMeses;
  final TextEditingController costeController;
  final ValueChanged<String> onUsarCosteConFuel;
  final ValueChanged<Map<String, AderFuelMes>> onFuelMesesChanged;

  const AderActionsButton({
    super.key,
    required this.fuelMeses,
    required this.costeController,
    required this.onUsarCosteConFuel,
    required this.onFuelMesesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AderAction>(
      tooltip: 'ADER',
      onSelected: (action) {
        switch (action) {
          case AderAction.importeFuel:
            _mostrarImporteConFuel(context);
            break;
          case AderAction.plantillaCorreo:
            _mostrarPlantillaCorreo(context);
            break;
          case AderAction.modificarFuel:
            _mostrarEditorFuel(context);
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: AderAction.importeFuel,
          child: ListTile(
            leading: Icon(Icons.local_gas_station),
            title: Text('Importe con fuel'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: AderAction.plantillaCorreo,
          child: ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('Plantilla correo'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: AderAction.modificarFuel,
          child: ListTile(
            leading: Icon(Icons.edit_calendar_outlined),
            title: Text('Modificar fuel'),
            dense: true,
          ),
        ),
      ],
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.green.shade700,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_gas_station, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'ADER',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _mostrarImporteConFuel(BuildContext context) {
    final mesFuel = ultimoFuelMes(fuelMeses);
    final res = calcularAderFuel(costeController.text, mesFuel);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(mesFuel == null ? 'Importe con fuel' : 'Importe con fuel - ${mesFuel.label}'),
        content: mesFuel == null
            ? const Text('Añade un mes Fuel para poder calcular ADER.')
            : res == null
                ? const Text('Introduce primero un coste proveedor válido.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FuelResultRow(
                        title: 'Local',
                        percent: mesFuel.local,
                        fuel: res.fuelLocal,
                        total: res.totalLocal,
                        color: Colors.green.shade700,
                        onSelect: () {
                          Navigator.of(context).pop();
                          onUsarCosteConFuel(fmt2(res.totalLocal));
                        },
                      ),
                      const SizedBox(height: 12),
                      _FuelResultRow(
                        title: 'Nacional',
                        percent: mesFuel.nacional,
                        fuel: res.fuelNacional,
                        total: res.totalNacional,
                        color: Colors.teal.shade700,
                        onSelect: () {
                          Navigator.of(context).pop();
                          onUsarCosteConFuel(fmt2(res.totalNacional));
                        },
                      ),
                    ],
                  ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarPlantillaCorreo(BuildContext context) {
    final mesFuel = ultimoFuelMes(fuelMeses);
    final res = calcularAderFuel(costeController.text, mesFuel);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(mesFuel == null ? 'Plantilla correo' : 'Plantilla correo - ${mesFuel.label}'),
        content: mesFuel == null
            ? const Text('Añade un mes Fuel para poder generar la plantilla.')
            : res == null
                ? const Text('Introduce primero un coste proveedor válido.')
                : SizedBox(
                    width: 860,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _PlantillaPanel(
                            title: 'Local',
                            color: Colors.green.shade700,
                            text: _textoLocal(res),
                            onCopy: () => _copiar(context, _textoLocal(res), 'Plantilla Local copiada.'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PlantillaPanel(
                            title: 'Nacional',
                            color: Colors.teal.shade700,
                            text: _textoNacional(res),
                            onCopy: () => _copiar(context, _textoNacional(res), 'Plantilla Nacional copiada.'),
                          ),
                        ),
                      ],
                    ),
                  ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarEditorFuel(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 920,
          height: 620,
          child: EditorFuelTab(
            meses: fuelMeses,
            onMesesChanged: onFuelMesesChanged,
          ),
        ),
      ),
    );
  }

  void _copiar(BuildContext context, String texto, String mensaje) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), duration: const Duration(seconds: 2)),
    );
  }

  String _textoBase() {
    return 'Buenos días,\n\n'
        'Por favor proceder con el servicio conforme a lo acordado.\n'
        'Os rogamos que trasladéis las siguientes indicaciones al conductor, '
        'con el objetivo de garantizar una correcta ejecución del servicio '
        'y evitar posibles incidencias:\n'
        '- Es imprescindible informar de inmediato de cualquier retraso, '
        'incidencia o discrepancia con respecto a lo solicitado o prealertado, '
        'para poder gestionarlo con la mayor agilidad posible y evitar '
        'afectaciones al servicio.';
  }

  String _textoLocal(AderResultado r) {
    return '${_textoBase()}\n\n'
        'Porcentaje aplicado: ${r.mesFuel.local.toStringAsFixed(3)}\n'
        'Para locales < 75 Km y vehículos < 3500kg.\n\n'
        'Cuyo importe es:\n'
        '${fmt2(r.coste)} ofertado + ${fmt3(r.fuelLocal)} fuel = '
        '${fmt2(r.totalLocal)} € + IVA\n\n'
        'Por favor si no es correcto, indicadlo antes de facturar.\n\n'
        'Manolo.';
  }

  String _textoNacional(AderResultado r) {
    return '${_textoBase()}\n\n'
        'Porcentaje aplicado: ${r.mesFuel.nacional.toStringAsFixed(3)}\n'
        'Para nacionales o locales > 75 Km y vehículos ≥ 3500kg.\n\n'
        'Cuyo importe es:\n'
        '${fmt2(r.coste)} ofertado + ${fmt3(r.fuelNacional)} fuel = '
        '${fmt2(r.totalNacional)} € + IVA\n\n'
        'Por favor si no es correcto, indicadlo antes de facturar.\n\n'
        'Manolo.';
  }
}

class _FuelResultRow extends StatelessWidget {
  final String title;
  final double percent;
  final double fuel;
  final double total;
  final Color color;
  final VoidCallback onSelect;

  const _FuelResultRow({
    required this.title,
    required this.percent,
    required this.fuel,
    required this.total,
    required this.color,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: DefaultTextStyle(
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Porcentaje: ${fmt3(percent)}%'),
                  Text('Fuel: ${fmt3(fuel)} €'),
                  Text('Total: ${fmt2(total)} €'),
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: onSelect,
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
            child: const Text('Seleccionar'),
          ),
        ],
      ),
    );
  }
}

class _PlantillaPanel extends StatelessWidget {
  final String title;
  final Color color;
  final String text;
  final VoidCallback onCopy;

  const _PlantillaPanel({
    required this.title,
    required this.color,
    required this.text,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 430,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        border: Border.all(color: color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: color.withOpacity(0.20)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  text,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.35),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy, size: 17),
              label: Text('Copiar $title'),
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
