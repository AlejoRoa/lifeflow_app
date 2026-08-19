import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'export_service.dart';
import 'onboarding_screen.dart';

class Habito {
  String titulo;
  String hora;
  bool completado;
  String frecuencia; // 'Diario', 'Semanal', 'Mensual'

  Habito({
    required this.titulo,
    required this.hora,
    this.completado = false,
    this.frecuencia = 'Diario',
  });

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'hora': hora,
        'completado': completado,
        'frecuencia': frecuencia,
      };

  factory Habito.fromJson(Map<String, dynamic> json) => Habito(
        titulo: json['titulo'],
        hora: json['hora'],
        completado: json['completado'] ?? false,
        frecuencia: json['frecuencia'] ?? 'Diario',
      );
}

class DashboardIron extends StatefulWidget {
  const DashboardIron({Key? key}) : super(key: key);

  @override
  _DashboardIronState createState() => _DashboardIronState();
}

class _DashboardIronState extends State<DashboardIron>
    with WidgetsBindingObserver {
  static const int _duracionInicial = 25 * 60;
  int _segundosRestantes = _duracionInicial;
  Timer? _timer;
  bool _estaCorriendo = false;
  bool _sesionInterrumpida = false;

  List<Habito> _habitos = [];

  final TextEditingController _habitoController = TextEditingController();
  TimeOfDay _horaSeleccionada = const TimeOfDay(hour: 8, minute: 0);
  String _frecuenciaSeleccionada = 'Diario'; // Frecuencia por defecto

  @override
  void initState() {
    super.initState();
    WidgetsBindingObserverUtils.addObserver(this);
    _cargarHabitos();
  }

  @override
  void dispose() {
    WidgetsBindingObserverUtils.removeObserver(this);
    _timer?.cancel();
    _habitoController.dispose();
    super.dispose();
  }

  void _cargarHabitos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? habitosString = prefs.getString('lista_habitos');
    if (habitosString != null) {
      final List<dynamic> jsonList = jsonDecode(habitosString);
      setState(() {
        _habitos = jsonList.map((item) => Habito.fromJson(item)).toList();
      });
    }
  }

  void _guardarHabitos() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(
      _habitos.map((h) => h.toJson()).toList(),
    );
    await prefs.setString('lista_habitos', jsonString);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _estaCorriendo) {
      _pausarTimer();
      setState(() {
        _sesionInterrumpida = true;
      });
    }
  }

  void _iniciarTimer() {
    setState(() {
      _estaCorriendo = true;
      _sesionInterrumpida = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes > 0) {
        setState(() => _segundosRestantes--);
      } else {
        _pausarTimer();
      }
    });
  }

  void _pausarTimer() {
    _timer?.cancel();
    setState(() => _estaCorriendo = false);
  }

  void _reiniciarTimer() {
    _pausarTimer();
    setState(() {
      _segundosRestantes = _duracionInicial;
      _sesionInterrumpida = false;
    });
  }

  Future<void> _seleccionarHora(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
    );
    if (picked != null) {
      setState(() {
        _horaSeleccionada = picked;
      });
    }
  }

  void _agregarHabito() {
    if (_habitoController.text.trim().isNotEmpty) {
      final horaFormateada = _horaSeleccionada.format(context);
      setState(() {
        _habitos.add(
          Habito(
            titulo: _habitoController.text.trim(),
            hora: horaFormateada,
            completado: false,
            frecuencia: _frecuenciaSeleccionada,
          ),
        );
        _habitoController.clear();
      });
      _guardarHabitos();
    }
  }

  void _toggleHabito(Habito habito) {
    setState(() {
      habito.completado = !habito.completado;
    });
    _guardarHabitos();
  }

  void _eliminarHabito(Habito habito) {
    setState(() {
      _habitos.remove(habito);
    });
    _guardarHabitos();
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

  String _obtenerNombreMes(int mes) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return meses[mes - 1];
  }

  String _formatearTiempo(int segundos) {
    final m = (segundos ~/ 60).toString().padLeft(2, '0');
    final s = (segundos % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  void _mostrarOpcionesExportacion() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1B26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Exportar e Imprimir Plantilla",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Selecciona el formato de seguimiento que deseas generar:",
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.today, color: Colors.purpleAccent),
                title: const Text("Plantilla Diaria",
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text("Detalle horario y observaciones del día",
                    style: TextStyle(color: Colors.grey)),
                onTap: () {
                  Navigator.pop(context);
                  _generarPDF('Diario');
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.view_week, color: Colors.purpleAccent),
                title: const Text("Plantilla Semanal",
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text("Control de 7 días (Lunes a Domingo)",
                    style: TextStyle(color: Colors.grey)),
                onTap: () {
                  Navigator.pop(context);
                  _generarPDF('Semanal');
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month,
                    color: Colors.purpleAccent),
                title: const Text("Plantilla Mensual",
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text("Matriz completa de 31 días",
                    style: TextStyle(color: Colors.grey)),
                onTap: () {
                  Navigator.pop(context);
                  _generarPDF('Mensual');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _generarPDF(String tipo) {
    final fechaActual = DateTime.now();
    final String mesAno =
        "${_obtenerNombreMes(fechaActual.month)} ${fechaActual.year}";

    final habitosFiltrados = _habitos
        .where((h) => h.frecuencia == tipo)
        .map((h) => h.titulo)
        .toList();

    final List<String> listaExportar = habitosFiltrados.isNotEmpty
        ? habitosFiltrados
        : _habitos.map((h) => h.titulo).toList();

    ExportService.exportarHabitosIron(
      mesAno: mesAno,
      habitos: listaExportar.isNotEmpty
          ? listaExportar
          : ['Ejercicio físico', 'Lectura enfocada', 'Meditación'],
      tipoFrecuencia: tipo,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtrado de hábitos según la frecuencia seleccionada en el Dropdown
    final habitosFiltrados =
        _habitos.where((h) => h.frecuencia == _frecuenciaSeleccionada).toList();

    final int completadosFiltrados =
        habitosFiltrados.where((h) => h.completado).length;

    final double porcentajeRacha = habitosFiltrados.isEmpty
        ? 0
        : (completadosFiltrados / habitosFiltrados.length);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      appBar: AppBar(
        title: const Text(
          "Disciplina de Hierro",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Colors.purpleAccent),
            tooltip: "Exportar e Imprimir",
            onPressed: _mostrarOpcionesExportacion,
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: "Cambiar Módulo",
            onPressed: _reiniciarRuta,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Temporizador
            Card(
              color: const Color(0xFF1A1B26),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "TEMPORIZADOR DE ENFOQUE",
                      style: TextStyle(
                        color: Colors.purpleAccent,
                        letterSpacing: 1.5,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatearTiempo(_segundosRestantes),
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_sesionInterrumpida)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade900.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "⚠️ Sesión interrumpida por segundo plano",
                          style: TextStyle(color: Colors.amber, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _estaCorriendo
                                ? Colors.orange[800]
                                : Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          icon: Icon(
                            _estaCorriendo ? Icons.pause : Icons.play_arrow,
                          ),
                          label: Text(_estaCorriendo ? "Pausar" : "Iniciar"),
                          onPressed:
                              _estaCorriendo ? _pausarTimer : _iniciarTimer,
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[300],
                            side: BorderSide(color: Colors.grey.shade700),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text("Reiniciar"),
                          onPressed: _reiniciarTimer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Registro de hábitos
            Card(
              color: const Color(0xFF1A1B26),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "MIS HÁBITOS",
                          style: TextStyle(
                            color: Colors.purpleAccent,
                            letterSpacing: 1.5,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "$completadosFiltrados/${habitosFiltrados.length} Completados",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: porcentajeRacha,
                        backgroundColor: Colors.grey[800],
                        color: Colors.deepPurpleAccent,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Selector de Frecuencia
                    Row(
                      children: [
                        const Text("Frecuencia: ",
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _frecuenciaSeleccionada,
                          dropdownColor: const Color(0xFF1A1B26),
                          style: const TextStyle(
                              color: Colors.purpleAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                          underline:
                              Container(height: 1, color: Colors.purpleAccent),
                          items: ['Diario', 'Semanal', 'Mensual']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(
                                  () => _frecuenciaSeleccionada = newValue);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _habitoController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Nuevo hábito...",
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              isDense: true,
                              filled: true,
                              fillColor: const Color(0xFF0D0E15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _seleccionarHora(context),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Colors.deepPurple.shade900.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.purpleAccent,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _horaSeleccionada.format(context),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.purpleAccent,
                            size: 32,
                          ),
                          onPressed: _agregarHabito,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    habitosFiltrados.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                "No tienes hábitos en '$_frecuenciaSeleccionada'. ¡Agrega uno arriba!",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: habitosFiltrados.length,
                            itemBuilder: (context, index) {
                              final habito = habitosFiltrados[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D0E15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: Checkbox(
                                    value: habito.completado,
                                    activeColor: Colors.deepPurpleAccent,
                                    onChanged: (_) => _toggleHabito(habito),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          habito.titulo,
                                          style: TextStyle(
                                            color: habito.completado
                                                ? Colors.grey[600]
                                                : Colors.white,
                                            decoration: habito.completado
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.shade900,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          habito.frecuencia,
                                          style: const TextStyle(
                                              color: Colors.purpleAccent,
                                              fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    "⏰ ${habito.hora}",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red[400],
                                      size: 20,
                                    ),
                                    onPressed: () => _eliminarHabito(habito),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WidgetsBindingObserverUtils {
  static void addObserver(WidgetsBindingObserver observer) {
    WidgetsBinding.instance.addObserver(observer);
  }

  static void removeObserver(WidgetsBindingObserver observer) {
    WidgetsBinding.instance.removeObserver(observer);
  }
}
