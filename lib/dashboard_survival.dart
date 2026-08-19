import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'export_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

// Modelo para Gastos Diarios
class Transaccion {
  final String concepto;
  final double monto;
  final String categoria;
  final DateTime fecha;

  Transaccion({
    required this.concepto,
    required this.monto,
    required this.categoria,
    required this.fecha,
  });

  Map<String, dynamic> toJson() => {
        'concepto': concepto,
        'monto': monto,
        'categoria': categoria,
        'fecha': fecha.toIso8601String(),
      };

  factory Transaccion.fromJson(Map<String, dynamic> json) => Transaccion(
        concepto: json['concepto'],
        monto: json['monto'].toDouble(),
        categoria: json['categoria'],
        fecha: DateTime.parse(json['fecha']),
      );
}

// Modelo para Gastos Fijos
class GastoFijo {
  final String concepto;
  final double monto;

  GastoFijo({required this.concepto, required this.monto});

  Map<String, dynamic> toJson() => {'concepto': concepto, 'monto': monto};

  factory GastoFijo.fromJson(Map<String, dynamic> json) =>
      GastoFijo(concepto: json['concepto'], monto: json['monto'].toDouble());
}

class DashboardSurvival extends StatefulWidget {
  const DashboardSurvival({super.key});

  @override
  _DashboardSurvivalState createState() => _DashboardSurvivalState();
}

class _DashboardSurvivalState extends State<DashboardSurvival> {
  final NumberFormat _formatoCOP = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );
  // Parámetros de Presupuesto Base
  double _ingresos = 0.0;
  int _diasRestantes = 30;
  double _porcentajeAhorro = 10.0; // Porcentaje por defecto (10%)

  List<Transaccion> _gastos = [];
  List<GastoFijo> _gastosFijosList = [];

  // Controladores
  final TextEditingController _conceptoController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();

  final TextEditingController _fijoConceptoCtrl = TextEditingController();
  final TextEditingController _fijoMontoCtrl = TextEditingController();

  String _categoriaSeleccionada = "Comida";

  final Map<String, IconData> _categoriasInfo = {
    "Comida": Icons.restaurant,
    "Transporte": Icons.directions_bus,
    "Ocio": Icons.sports_esports,
    "Servicios": Icons.bolt,
  };

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // --- PERSISTENCIA LOCAL ---
  void _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ingresos = prefs.getDouble('sueldo_ingresos') ?? 0.0;
      _diasRestantes = prefs.getInt('dias_restantes') ?? 30;
      _porcentajeAhorro = prefs.getDouble('porcentaje_ahorro') ?? 10.0;

      // Cargar lista de gastos diarios
      final String? gastosString = prefs.getString('lista_gastos');
      if (gastosString != null) {
        final List<dynamic> jsonList = jsonDecode(gastosString);
        _gastos = jsonList.map((item) => Transaccion.fromJson(item)).toList();
      }

      // Cargar lista de gastos fijos
      final String? fijosString = prefs.getString('lista_gastos_fijos');
      if (fijosString != null) {
        final List<dynamic> jsonList = jsonDecode(fijosString);
        _gastosFijosList =
            jsonList.map((item) => GastoFijo.fromJson(item)).toList();
      }
    });
  }

  void _guardarConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sueldo_ingresos', _ingresos);
    await prefs.setInt('dias_restantes', _diasRestantes);
    await prefs.setDouble('porcentaje_ahorro', _porcentajeAhorro);
  }

  void _guardarGastos() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(
      _gastos.map((g) => g.toJson()).toList(),
    );
    await prefs.setString('lista_gastos', jsonString);
  }

  void _guardarGastosFijos() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(
      _gastosFijosList.map((gf) => gf.toJson()).toList(),
    );
    await prefs.setString('lista_gastos_fijos', jsonString);
  }

  // --- CÁLCULOS FINANCIEROS Y DE AHORRO ---
  double get _totalGastosFijos =>
      _gastosFijosList.fold(0.0, (sum, item) => sum + item.monto);
  double get _ingresoNetoSinFijos =>
      (_ingresos - _totalGastosFijos) > 0 ? (_ingresos - _totalGastosFijos) : 0;

  // Ahorro
  double get _montoAhorroRecomendado =>
      _ingresoNetoSinFijos * (_porcentajeAhorro / 100);

  // Dinero disponible real para gastos después de descontar fijos Y ahorro
  double get _dineroDisponibleGastos =>
      _ingresoNetoSinFijos - _montoAhorroRecomendado;

  double get _limiteQuincenal => _dineroDisponibleGastos / 2;
  double get _limiteDiario =>
      _diasRestantes > 0 ? (_dineroDisponibleGastos / _diasRestantes) : 0;
  double get _gastosTotales =>
      _gastos.fold(0.0, (sum, item) => sum + item.monto);
  double get _saldoRestante => _dineroDisponibleGastos - _gastosTotales;

  // --- GESTIÓN DE GASTOS FIJOS ---
  void _agregarGastoFijo() {
    final monto = double.tryParse(_fijoMontoCtrl.text);
    final concepto = _fijoConceptoCtrl.text.trim();

    if (monto != null && monto > 0 && concepto.isNotEmpty) {
      setState(() {
        _gastosFijosList.add(GastoFijo(concepto: concepto, monto: monto));
        _fijoConceptoCtrl.clear();
        _fijoMontoCtrl.clear();
      });
      _guardarGastosFijos();
    }
  }

  void _eliminarGastoFijo(int index) {
    setState(() {
      _gastosFijosList.removeAt(index);
    });
    _guardarGastosFijos();
  }

  // --- MODAL CONFIGURACIÓN DE SUELDO Y AHORRO ---
  void _abrirDialogoConfiguracion() {
    final ingresosCtrl = TextEditingController(
      text: _ingresos > 0 ? _ingresos.toStringAsFixed(0) : "",
    );
    final diasCtrl = TextEditingController(text: _diasRestantes.toString());
    final ahorroCtrl = TextEditingController(
      text: _porcentajeAhorro.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Color(0xFF1A1B26),
              title: Text(
                "Ajustar Presupuesto y Ahorro",
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: ingresosCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Sueldo / Ingreso Mensual (\$)",
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.greenAccent),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: diasCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Días Restantes del Mes",
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.greenAccent),
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Porcentaje de Ahorro Deseado (%)",
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [5, 10, 15, 20, 30].map((pct) {
                        final isSel = (double.tryParse(ahorroCtrl.text) ?? 0) ==
                            pct.toDouble();
                        return ChoiceChip(
                          label: Text("$pct%"),
                          selected: isSel,
                          selectedColor: Colors.amberAccent,
                          backgroundColor: Color(0xFF0D0E15),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.black : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) {
                            setModalState(() {
                              ahorroCtrl.text = pct.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: ahorroCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Otro porcentaje personalizado (%)",
                        labelStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.amberAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                  ),
                  child: Text("Guardar"),
                  onPressed: () {
                    setState(() {
                      _ingresos = double.tryParse(ingresosCtrl.text) ?? 0.0;
                      _diasRestantes = int.tryParse(diasCtrl.text) ?? 30;
                      _porcentajeAhorro =
                          double.tryParse(ahorroCtrl.text) ?? 10.0;
                    });
                    _guardarConfiguracion();
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _registrarGasto() {
    final monto = double.tryParse(_montoController.text);
    final concepto = _conceptoController.text.trim();

    if (monto != null && monto > 0 && concepto.isNotEmpty) {
      setState(() {
        _gastos.insert(
          0,
          Transaccion(
            concepto: concepto,
            monto: monto,
            categoria: _categoriaSeleccionada,
            fecha: DateTime.now(),
          ),
        );
        _montoController.clear();
        _conceptoController.clear();
      });
      _guardarGastos();
    }
  }

  void _eliminarGasto(int index) {
    setState(() {
      _gastos.removeAt(index);
    });
    _guardarGastos();
  }

  void _reiniciarRuta() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pilar_seleccionado');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Color(0xFF0D0E15),
        appBar: AppBar(
          title: Text(
            "Survival Finances",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green.shade900,
          actions: [
            // Menú para exportar
            PopupMenuButton<String>(
              icon: Icon(Icons.ios_share),
              tooltip: "Exportar Reporte",
              onSelected: (value) {
                if (value == 'pdf') {
                  ExportService.exportarPDF(
                    ingresos: _ingresos,
                    totalFijos: _totalGastosFijos,
                    ahorroRecomendado: _montoAhorroRecomendado,
                    disponibleGastos: _dineroDisponibleGastos,
                    limiteDiario: _limiteDiario,
                    gastosFijos: _gastosFijosList,
                    transacciones: _gastos,
                  );
                } else if (value == 'excel') {
                  ExportService.exportarExcel(
                    ingresos: _ingresos,
                    totalFijos: _totalGastosFijos,
                    ahorroRecomendado: _montoAhorroRecomendado,
                    disponibleGastos: _dineroDisponibleGastos,
                    limiteDiario: _limiteDiario,
                    gastosFijos: _gastosFijosList,
                    transacciones: _gastos,
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text('Exportar a PDF'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'excel',
                  child: Row(
                    children: [
                      Icon(
                        Icons.table_chart,
                        color: Colors.greenAccent,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text('Exportar a Excel'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: _abrirDialogoConfiguracion,
            ),
            IconButton(icon: Icon(Icons.swap_horiz), onPressed: _reiniciarRuta),
          ],
          bottom: TabBar(
            indicatorColor: Colors.greenAccent,
            labelColor: Colors.greenAccent,
            unselectedLabelColor: Colors.grey[400],
            tabs: [
              Tab(
                icon: Icon(Icons.analytics_outlined),
                text: "Presupuesto Diario",
              ),
              Tab(icon: Icon(Icons.receipt_long), text: "Gastos Fijos"),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildTabPresupuesto(), _buildTabGastosFijos()],
        ),
      ),
    );
  }

  // --- PESTAÑA 1: PRESUPUESTO, AHORRO Y REGISTRO DIARIO ---
  Widget _buildTabPresupuesto() {
    final double consumoRatio = _limiteDiario > 0
        ? (_gastosTotales / _limiteDiario).clamp(0.0, 1.0)
        : 0.0;
    final bool excedeLimite =
        _limiteDiario > 0 && _gastosTotales > _limiteDiario;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_ingresos == 0)
            InkWell(
              onTap: _abrirDialogoConfiguracion,
              child: Container(
                margin: EdgeInsets.only(bottom: 15),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Toca aquí para ingresar tu sueldo mensual y configurar tu ahorro.",
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Tarjeta Principal (Límite Diario)
          Card(
            color: Color(0xFF1A1B26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: excedeLimite ? Colors.redAccent : Colors.green.shade600,
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "LÍMITE DIARIO RECOMENDADO",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Días rest: $_diasRestantes",
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    _formatoCOP.format(_limiteDiario),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Consumo hoy: ${_formatoCOP.format(_gastosTotales)}",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "${(consumoRatio * 100).toStringAsFixed(0)}%",
                            style: TextStyle(
                              color: excedeLimite
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: consumoRatio,
                          backgroundColor: Colors.grey[800],
                          color: excedeLimite
                              ? Colors.redAccent
                              : Colors.greenAccent,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Divider(color: Colors.white12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Disponible para Gastos Hoy:",
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                      Text(
                        _formatoCOP.format(_saldoRestante),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  if (excedeLimite)
                    Container(
                      margin: EdgeInsets.only(top: 12),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Alerta: Se ha excedido el límite presupuestado para la jornada.",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 15),

          // Tarjeta Exclusiva de Recomendación de Ahorro
          Card(
            color: Color(0xFF1A1B26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Colors.amber.shade700.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.savings,
                            color: Colors.amberAccent,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "META DE AHORRO (${_porcentajeAhorro.toStringAsFixed(0)}%)",
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: _abrirDialogoConfiguracion,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Cambiar %",
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Ahorro Mensual Recomendado:",
                        style: TextStyle(color: Colors.grey[300], fontSize: 12),
                      ),
                      Text(
                        _formatoCOP.format(_montoAhorroRecomendado),
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 15),

          // Tarjeta Resumen Mensual Libre / Quincenal
          Card(
            color: Color(0xFF1A1B26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        "DISPONIBLE GASTOS MENSUAL",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatoCOP.format(_dineroDisponibleGastos),
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(height: 30, width: 1, color: Colors.white12),
                  Column(
                    children: [
                      Text(
                        "LÍMITE QUINCENAL RECOM.",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatoCOP.format(_limiteQuincenal),
                        style: TextStyle(
                          color: Colors.lightBlueAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Formulario Registro de Gasto
          Card(
            color: Color(0xFF1A1B26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "REGISTRO RÁPIDO DE GASTO",
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 15),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categoriasInfo.keys.map((cat) {
                        final isSelected = _categoriaSeleccionada == cat;
                        return Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            avatar: Icon(
                              _categoriasInfo[cat],
                              size: 16,
                              color: isSelected ? Colors.black : Colors.white70,
                            ),
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: Colors.greenAccent,
                            backgroundColor: Color(0xFF0D0E15),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _categoriaSeleccionada = cat);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _conceptoController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Ej. Pasajes, Café...",
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            isDense: true,
                            filled: true,
                            fillColor: Color(0xFF0D0E15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _montoController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Monto (\$)",
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            isDense: true,
                            filled: true,
                            fillColor: Color(0xFF0D0E15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(Icons.add, color: Colors.white),
                      label: Text(
                        "Registrar Movimiento",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _registrarGasto,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Historial Reciente
          Text(
            "HISTORIAL RECIENTE",
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 10),
          _gastos.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      "No hay movimientos registrados hoy",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _gastos.length,
                  itemBuilder: (context, index) {
                    final item = _gastos[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1B26),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _categoriasInfo[item.categoria] ??
                                Icons.attach_money,
                            color: Colors.greenAccent,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item.concepto,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "${item.categoria} • Hoy",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "-${_formatoCOP.format(item.monto)}",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.grey[600],
                                size: 16,
                              ),
                              onPressed: () => _eliminarGasto(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // --- PESTAÑA 2: GESTIÓN DE GASTOS FIJOS (DESGLOSE) ---
  Widget _buildTabGastosFijos() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Gastos Fijos
          Card(
            color: Color(0xFF1A1B26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TOTAL GASTOS FIJOS",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        _formatoCOP.format(_totalGastosFijos),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.house_siding,
                      color: Colors.redAccent,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Formulario para agregar Gasto Fijo
          Card(
            color: Color(0xFF1A1B26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AGREGAR GASTO FIJO (MENSUAL)",
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _fijoConceptoCtrl,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Ej. Arriendo, Internet...",
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            isDense: true,
                            filled: true,
                            fillColor: Color(0xFF0D0E15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _fijoMontoCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Monto (\$)",
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            isDense: true,
                            filled: true,
                            fillColor: Color(0xFF0D0E15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(Icons.add, color: Colors.white),
                      label: Text(
                        "Agregar a Gastos Fijos",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _agregarGastoFijo,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          Text(
            "DETALLE DE MIS GASTOS FIJOS",
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 10),

          _gastosFijosList.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      "No has registrado gastos fijos aún.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _gastosFijosList.length,
                  itemBuilder: (context, index) {
                    final item = _gastosFijosList[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1B26),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.push_pin,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          item.concepto,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "Gasto mensual recurrente",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatoCOP.format(item.monto),
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.grey[500],
                                size: 18,
                              ),
                              onPressed: () => _eliminarGastoFijo(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
