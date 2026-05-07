import 'package:flutter/material.dart';

import '../fuel_ader_storage.dart';

class EditorFuelTab extends StatefulWidget {
  final Map<String, AderFuelMes> meses;
  final ValueChanged<Map<String, AderFuelMes>> onMesesChanged;

  const EditorFuelTab({
    super.key,
    required this.meses,
    required this.onMesesChanged,
  });

  @override
  State<EditorFuelTab> createState() => _EditorFuelTabState();
}

class _EditorFuelTabState extends State<EditorFuelTab> {
  final TextEditingController _mesCtrl = TextEditingController();
  final TextEditingController _anioCtrl = TextEditingController(
    text: DateTime.now().year.toString(),
  );
  final TextEditingController _localCtrl = TextEditingController();
  final TextEditingController _nacionalCtrl = TextEditingController();

  late Map<String, AderFuelMes> _meses;

  String? _selectedId;

  bool _mesValid = true;
  bool _anioValid = true;
  bool _localValid = true;
  bool _nacionalValid = true;

  @override
  void initState() {
    super.initState();
    _meses = Map<String, AderFuelMes>.from(widget.meses);
  }

  @override
  void didUpdateWidget(covariant EditorFuelTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.meses != widget.meses) {
      _meses = Map<String, AderFuelMes>.from(widget.meses);
    }
  }

  @override
  void dispose() {
    _mesCtrl.dispose();
    _anioCtrl.dispose();
    _localCtrl.dispose();
    _nacionalCtrl.dispose();
    super.dispose();
  }

  double? _parseNum(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  void _validate() {
    setState(() {
      _mesValid = _mesCtrl.text.trim().isNotEmpty;
      _anioValid = int.tryParse(_anioCtrl.text.trim()) != null;
      _localValid = _parseNum(_localCtrl.text) != null;
      _nacionalValid = _parseNum(_nacionalCtrl.text) != null;
    });
  }

  bool _allValid() {
    _validate();
    return _mesValid && _anioValid && _localValid && _nacionalValid;
  }

  Future<void> _save(Map<String, AderFuelMes> meses) async {
    await guardarFuelAderMeses(meses);

    if (!mounted) return;

    setState(() {
      _meses = Map<String, AderFuelMes>.from(meses);
    });

    widget.onMesesChanged(_meses);
  }

  Future<void> _addOrUpdate() async {
    if (!_allValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa los campos en rojo.')),
      );
      return;
    }

    final item = AderFuelMes(
      mes: _mesCtrl.text.trim().toLowerCase(),
      anio: int.parse(_anioCtrl.text.trim()),
      local: _parseNum(_localCtrl.text)!,
      nacional: _parseNum(_nacionalCtrl.text)!,
    );

    final nuevos = Map<String, AderFuelMes>.from(_meses);
    nuevos[item.id] = item;

    await _save(nuevos);

    if (!mounted) return;

    setState(() {
      _selectedId = item.id;
      _clearInputs();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fuel guardado: ${item.label}')),
    );
  }

  void _loadSelectedToInputs(String id) {
    final item = _meses[id];
    if (item == null) return;

    setState(() {
      _selectedId = id;
      _mesCtrl.text = item.mes;
      _anioCtrl.text = item.anio.toString();
      _localCtrl.text = fmt3(item.local);
      _nacionalCtrl.text = fmt3(item.nacional);
      _mesValid = true;
      _anioValid = true;
      _localValid = true;
      _nacionalValid = true;
    });
  }

  Future<void> _deleteSelected() async {
    final id = _selectedId;
    if (id == null) return;

    final item = _meses[id];
    if (item == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mes Fuel'),
        content: Text("¿Seguro que quieres eliminar '${item.label}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final nuevos = Map<String, AderFuelMes>.from(_meses);
    nuevos.remove(id);

    await _save(nuevos);

    if (!mounted) return;

    setState(() {
      _selectedId = null;
      _clearInputs();
    });
  }

  void _clearInputs() {
    _mesCtrl.clear();
    _anioCtrl.text = DateTime.now().year.toString();
    _localCtrl.clear();
    _nacionalCtrl.clear();
    _mesValid = true;
    _anioValid = true;
    _localValid = true;
    _nacionalValid = true;
  }

  InputDecoration _decoration(String label, bool valid) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
      errorText: valid ? null : 'Revisar',
    );
  }

  @override
  Widget build(BuildContext context) {
    final mesesOrdenados = ordenarFuelMeses(_meses);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 160,
                child: TextField(
                  controller: _mesCtrl,
                  decoration: _decoration('Mes', _mesValid),
                  onChanged: (_) => _validate(),
                ),
              ),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _anioCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Año', _anioValid),
                  onChanged: (_) => _validate(),
                ),
              ),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _localCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _decoration('Local (%)', _localValid),
                  onChanged: (_) => _validate(),
                ),
              ),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _nacionalCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _decoration('Nacional (%)', _nacionalValid),
                  onChanged: (_) => _validate(),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addOrUpdate,
                icon: const Icon(Icons.add),
                label: const Text('Añadir / Actualizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _selectedId == null
                    ? null
                    : () => _loadSelectedToInputs(_selectedId!),
                icon: const Icon(Icons.edit),
                label: const Text('Modificar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _selectedId == null ? null : _deleteSelected,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: mesesOrdenados.isEmpty
                ? const Center(
                    child: Text('No hay meses Fuel guardados.'),
                  )
                : SingleChildScrollView(
                    child: DataTable(
                      showCheckboxColumn: false,
                      headingRowColor: WidgetStatePropertyAll(Colors.green.shade50),
                      columns: const [
                        DataColumn(label: Text('Mes')),
                        DataColumn(label: Text('Año')),
                        DataColumn(label: Text('Local')),
                        DataColumn(label: Text('Nacional')),
                      ],
                      rows: mesesOrdenados.map((item) {
                        final selected = _selectedId == item.id;

                        return DataRow(
                          selected: selected,
                          onSelectChanged: (_) {
                            setState(() {
                              _selectedId = selected ? null : item.id;
                            });
                          },
                          cells: [
                            DataCell(Text(item.mes)),
                            DataCell(Text(item.anio.toString())),
                            DataCell(Text(fmt3(item.local))),
                            DataCell(Text(fmt3(item.nacional))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
