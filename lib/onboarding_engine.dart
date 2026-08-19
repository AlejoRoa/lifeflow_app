import 'package:shared_preferences/shared_preferences.dart';

class OnboardingEngine {
  // Repositorio de datos de impacto para el módulo de Foco / Disciplina
  final List<String> datosDisciplina = [
    "¿Sabías que? El cerebro tarda 23 minutos en recuperar la concentración tras una distracción digital.",
    "El 80% de los jóvenes revisa su teléfono en los primeros 15 minutos al despertar.",
    "Procrastinar las tareas clave aumenta tus niveles de cortisol (estrés) en un 40%."
  ];

  // Repositorio de datos de impacto para el módulo de Finanzas de Supervivencia
  final List<String> datosFinanzas = [
    "¿Sabías que? Los 'gastos hormiga' silenciosos consumen hasta el 12% de tu ingreso mensual.",
    "Pagar de forma digital reduce el dolor psicológico de gastar, aumentando las compras compulsivas.",
    "El 70% de las personas reporta que el descontrol financiero es su mayor causa de ansiedad diaria."
  ];

  /// Registra la elección directa del usuario en la memoria local del dispositivo
  Future<void> registrarSeleccionDirecta(String moduloClave) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Guardamos la ruta del módulo prioritario ('Iron' o 'Survival')
    await prefs.setString('modulo_elegido', moduloClave);
    
    // Confirmamos que el proceso de autoselección se completó exitosamente
    await prefs.setBool('isCompleted', true);
    
    print('--> [Engine] Módulo asignado y guardado localmente: $moduloClave');
  }
}