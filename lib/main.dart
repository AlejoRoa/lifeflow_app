import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_iron.dart';
import 'dashboard_survival.dart';
import 'onboarding_screen.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final String? moduloGuardado = prefs.getString('modulo_elegido');

  runApp(MyApp(moduloInicial: moduloGuardado));
}

class MyApp extends StatelessWidget {
  final String? moduloInicial;

  const MyApp({super.key, this.moduloInicial});

  @override
  Widget build(BuildContext context) {
    Widget pantallaDestino;

    if (moduloInicial == 'Iron') {
      pantallaDestino = DashboardIron();
    } else if (moduloInicial == 'Survival') {
      pantallaDestino = DashboardSurvival();
    } else {
      pantallaDestino = const OnboardingScreen();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LifeFlow 360',
      theme: ThemeData.dark(),
      home: SplashScreen(siguientePantalla: pantallaDestino),
    );
  }
}
