import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_survival.dart';
import 'dashboard_iron.dart'; // O la ruta real de tu pantalla de Iron

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  void _seleccionarModulo(BuildContext context, String pilar) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pilar_seleccionado', pilar);

    if (!context.mounted) return;

    if (pilar == 'Iron') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DashboardIron(),
        ),
      );
    } else if (pilar == 'Survival') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardSurvival(),
        ),
      );
    }
  }

  void _mostrarAvisoProximamente(BuildContext context, String nombreModulo) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_clock, color: Colors.amberAccent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "El $nombreModulo estará disponible próximamente.",
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF161B26),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.teal.shade700.withOpacity(0.5)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B101D),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono superior central
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade900.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.teal.shade400.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: Colors.teal.shade300,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 24),

                // Título y Subtítulo
                const Text(
                  "Selecciona tu Módulo",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Elige el modo de gestión que deseas utilizar",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // 1. IRON DISCIPLINE (DISPONIBLE)
                _buildCardModulo(
                  context: context,
                  titulo: "Iron Discipline",
                  descripcion:
                      "Crea Hábitos, alarmas matutinas y enfoque profundo.",
                  icono: Icons.shield_outlined,
                  disponible: true,
                  onTap: () => _seleccionarModulo(context, 'Iron'),
                ),
                const SizedBox(height: 16),

// 2. SURVIVAL FINANCES (DISPONIBLE)
                _buildCardModulo(
                  context: context,
                  titulo: "Survival Finances",
                  descripcion:
                      "Gestión de gastos prioritarios y liquidación acelerada de deudas.",
                  icono: Icons.bolt_outlined,
                  disponible: true,
                  onTap: () => _seleccionarModulo(context, 'Survival'),
                ),
                const SizedBox(height: 16),

// 3. MIND CARE PROTOCOL (PRÓXIMAMENTE)
                _buildCardModulo(
                  context: context,
                  titulo: "Mind Care Protocol",
                  descripcion:
                      "Seguimiento del estado de ánimo, bitácoras de salud mental y bienestar emocional.",
                  icono: Icons.psychology_outlined,
                  disponible: false,
                  onTap: () =>
                      _mostrarAvisoProximamente(context, "Mind Care Protocol"),
                ),
                const SizedBox(height: 16),

// 4. SKILL TREE (PRÓXIMAMENTE)
                _buildCardModulo(
                  context: context,
                  titulo: "Skill Tree",
                  descripcion:
                      "Perfil de habilidades blandas y portafolio conductual basado en tu disciplina.",
                  icono: Icons.account_tree_outlined,
                  disponible: false,
                  onTap: () => _mostrarAvisoProximamente(context, "Skill Tree"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardModulo({
    required BuildContext context,
    required String titulo,
    required String descripcion,
    required IconData icono,
    required bool disponible,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: disponible ? 1.0 : 0.55,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF121827),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: disponible
                  ? Colors.teal.shade500.withOpacity(0.6)
                  : Colors.grey.shade800,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              // Contenedor del icono
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: disponible
                      ? Colors.teal.shade900.withOpacity(0.4)
                      : Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icono,
                  color: disponible ? Colors.teal.shade300 : Colors.grey[500],
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),

              // Título, descripción y badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (!disponible) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade900.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.amber.shade700.withOpacity(0.5),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              "PRÓXIMAMENTE",
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Icono derecho (Chevron o Candado)
              Icon(
                disponible ? Icons.chevron_right : Icons.lock_outline_rounded,
                color: disponible ? Colors.teal.shade300 : Colors.grey[600],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
