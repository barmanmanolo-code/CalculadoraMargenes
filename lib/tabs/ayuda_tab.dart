import 'package:flutter/material.dart';

class AyudaTab extends StatelessWidget {
  const AyudaTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Ayuda de uso',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 16),
            _HelpSection(
              title: '1. Calculadora',
              body:
                  'En la pestaña Calculadora introduce el coste proveedor. La app calcula automáticamente el precio de venta y el REVAO según los márgenes configurados en la tabla de ventas.\n\n'
                  'Si el coste viene ya con fuel incluido, la etiqueta cambiará a “Coste proveedor con fuel incluido”. Esto ocurre cuando seleccionas un importe desde ADER.',
            ),
            _HelpSection(
              title: '2. Resultados por rol',
              body:
                  'Cada bloque muestra un rol de aprobación: Sin aprobación, Supervisor, Manager o Senior Manager.\n\n'
                  'Para cada rol se muestra el margen mínimo, el margen máximo si existe, la venta calculada y el REVAO correspondiente.',
            ),
            _HelpSection(
              title: '3. Botón ADER',
              body:
                  'El botón ADER agrupa las funciones relacionadas con fuel.\n\n'
                  'Importe con fuel: calcula el coste con suplemento fuel para Local y Nacional. Puedes pulsar Seleccionar para enviar ese importe directamente al campo Coste proveedor de la calculadora.\n\n'
                  'Plantilla correo: genera el texto de correo para Local y Nacional con el cálculo de fuel incluido. Puedes copiar la plantilla y pegarla donde necesites.\n\n'
                  'Modificar fuel: permite añadir, actualizar o eliminar los porcentajes fuel por mes y año.',
            ),
            _HelpSection(
              title: '4. Tabla Ventas',
              body:
                  'En Tabla Ventas puedes modificar los rangos de venta y los márgenes por rol.\n\n'
                  'Pulsa el lápiz verde para editar una fila. Los campos vacíos o con valor 0 no se muestran mientras no estás editando, para que la tabla quede más limpia.\n\n'
                  'Al borrar un rango, la app pregunta confirmación antes de eliminarlo.',
            ),
            _HelpSection(
              title: '5. Guardado automático',
              body:
                  'Los cambios de Tabla Ventas y de los porcentajes Fuel se guardan automáticamente en el navegador mediante SharedPreferences.\n\n'
                  'Cuando cierres y abras la app, se recuperan los últimos datos guardados.',
            ),
            _HelpSection(
              title: '6. Fuel por mes y año',
              body:
                  'El fuel se guarda por mes y año. Por ejemplo, abril 2026 y abril 2027 son registros distintos.\n\n'
                  'La app usa automáticamente el último mes registrado según año y orden natural de los meses.',
            ),
            _HelpSection(
              title: '7. Flujo recomendado',
              body:
                  'Primero introduce el coste proveedor.\n\n'
                  'Si necesitas fuel, pulsa ADER > Importe con fuel y selecciona Local o Nacional.\n\n'
                  'Después revisa los resultados de venta y REVAO en la calculadora.\n\n'
                  'Si necesitas enviar texto al proveedor, usa ADER > Plantilla correo.',
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final String title;
  final String body;

  const _HelpSection({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(fontSize: 14, height: 1.35),
          ),
        ],
      ),
    );
  }
}
