import 'package:flutter/material.dart';

import 'fuel_ader_storage.dart';
import 'models.dart';
import 'storage.dart';
import 'tabs/ayuda_tab.dart';
import 'tabs/calculadora_tab.dart';
import 'tabs/tabla_ventas_tab.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora de Ventas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Calculadora de Ventas'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _costeController = TextEditingController();

  List<VentaRango> _tablaVentas = defaultTablaVentas();
  Map<String, AderFuelMes> _fuelMeses = defaultFuelAderMeses();
  bool _costeConFuelIncluido = false;
  String? _costeBaseParaAder;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _cargarTabla();
    _cargarFuelMeses();
  }

  Future<void> _cargarTabla() async {
    final tablaGuardada = await cargarTablaVentas();
    if (!mounted) return;

    setState(() {
      _tablaVentas = tablaGuardada;
    });
  }

  Future<void> _guardarTabla() async {
    await guardarTablaVentas(_tablaVentas);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _cargarFuelMeses() async {
    final meses = await cargarFuelAderMeses();
    if (!mounted) return;

    setState(() {
      _fuelMeses = meses;
    });
  }

  void _onFuelMesesChanged(Map<String, AderFuelMes> meses) {
    setState(() {
      _fuelMeses = meses;
    });
  }

  void _marcarCosteManual() {
    setState(() {
      _costeConFuelIncluido = false;
      _costeBaseParaAder = null;
    });
  }

  void _usarCosteConFuel(String coste) {
    _costeBaseParaAder ??= _costeController.text;

    _costeController.text = coste;

    setState(() {
      _costeConFuelIncluido = true;
      _selectedIndex = 0;
    });
  }

  @override
  void dispose() {
    _costeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Calculadora',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_chart_outlined),
            selectedIcon: Icon(Icons.table_chart),
            label: 'Tabla',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help),
            label: 'Ayuda',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          CalculadoraTab(
            tablaVentas: _tablaVentas,
            fuelMeses: _fuelMeses,
            costeController: _costeController,
            costeConFuelIncluido: _costeConFuelIncluido,
            costeBaseParaAder: _costeBaseParaAder,
            onCosteManualChanged: _marcarCosteManual,
            onUsarCosteConFuel: _usarCosteConFuel,
            onFuelMesesChanged: _onFuelMesesChanged,
            onTablaChanged: _guardarTabla,
          ),
          TablaVentasTab(
            tablaVentas: _tablaVentas,
            onTablaChanged: _guardarTabla,
          ),
          const AyudaTab(),
        ],
      ),
    );
  }
}
