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

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _costeController = TextEditingController();

  List<VentaRango> _tablaVentas = defaultTablaVentas();
  Map<String, AderFuelMes> _fuelMeses = defaultFuelAderMeses();
  bool _costeConFuelIncluido = false;
  String? _costeBaseParaAder;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    });

    _tabController.animateTo(0);
  }

  @override
  void dispose() {
    _costeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Tab _compactTab(String text) {
    return Tab(height: 36, text: text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.deepPurple.shade900,
              unselectedLabelColor: Colors.black54,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: [
                _compactTab('Calculadora'),
                _compactTab('Tabla Ventas'),
                _compactTab('Ayuda'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
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
