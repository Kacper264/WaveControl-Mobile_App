import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/mqtt_service.dart';
import 'services/app_settings.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Verrouiller l'orientation en mode portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Configuration iOS-style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
    ),
  );
  
  // Charger les préférences avant de lancer l'app
  final settings = AppSettings();
  await Future.delayed(const Duration(milliseconds: 100)); // Laisser le temps de charger
  
  runApp(const MyApp());

  // Connect MQTT and request device list at app launch
  MQTTService().connect(
    server: settings.mqttServer,
    port: settings.mqttPort,
    username: settings.mqttUsername,
    password: settings.mqttPassword,
  ).then((connected) {
    if (connected) {
      MQTTService().publishMessage('home/matter/request', 'test');
    }
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppSettings _settings = AppSettings();

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WaveControl',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _settings.themeMode,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
