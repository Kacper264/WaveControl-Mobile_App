import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../theme/app_theme.dart';
import '../services/mqtt_service.dart';
import '../services/app_settings.dart';
import '../models/device_state.dart';
import '../widgets/ios_widgets.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({Key? key}) : super(key: key);

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  final MQTTService _mqtt = MQTTService();
  final AppSettings _settings = AppSettings();

  @override
  void initState() {
    super.initState();
    _mqtt.connect();
    _mqtt.addListener(_onMqttChanged);
    _settings.addListener(_onSettingsChanged);
  }

  void _onMqttChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _mqtt.removeListener(_onMqttChanged);
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  bool _isLamp(DeviceState ds) {
    final topic = ds.topic.toLowerCase();
    final name = (ds.friendlyName ?? '').toLowerCase();
    return topic.contains('lum') || name.contains('lum') || name.contains('light');
  }


  String _deviceTypeLabel(DeviceState ds) {
    if (_isLamp(ds)) return _settings.text('light');
    final topic = ds.topic.toLowerCase();
    final name = (ds.friendlyName ?? '').toLowerCase();
    if (topic.contains('prise') || name.contains('prise') || name.contains('plug') || name.contains('switch')) {
      return _settings.text('socket');
    }
    return _settings.text('device');
  }

  void _showLightControlDialog(BuildContext context, DeviceState device) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int currentBrightness = device.brightness;
    Color currentColor = Color(int.parse(device.displayColor.replaceFirst('#', '0xFF')));
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
              title: Text(device.friendlyName ?? device.topic),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Titre Couleur
                    Text(
                      _settings.text('choose_color'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    // Color Picker
                    ColorPicker(
                      pickerColor: currentColor,
                      onColorChanged: (Color color) {
                        setState(() {
                          currentColor = color;
                        });
                        _mqtt.setRgbColor(device.topic, color.red, color.green, color.blue);
                      },
                      enableAlpha: false,
                      displayThumbColor: true,
                      paletteType: PaletteType.hsvWithHue,
                      labelTypes: const [],
                      pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    const SizedBox(height: 24),
                    // Titre Luminosité
                    Text(
                      _settings.text('adjust_brightness'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    // Pourcentage
                    Text(
                      '${currentBrightness}%',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    // Slider Luminosité
                    Slider(
                      value: currentBrightness.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '${currentBrightness}%',
                      onChanged: (double value) {
                        setState(() {
                          currentBrightness = value.round();
                        });
                        _mqtt.setBrightness(device.topic, currentBrightness);
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(_settings.text('close')),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show all devices received, regardless of their state
    final devices = _mqtt.isConnected ? _mqtt.deviceStates.values.toList() : <DeviceState>[];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          _settings.text('monitoring'),
          style: theme.textTheme.titleLarge,
        ),
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: devices.isEmpty
            ? Center(
                child: Text(
                  _settings.text('no_device'),
                  style: theme.textTheme.headlineMedium,
                ),
              )
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final ds = devices[index];
                  final name = ds.friendlyName ?? ds.topic;
                  final isOn = ds.state.toUpperCase() == 'ON';
                  final typeLabel = _deviceTypeLabel(ds);
                  final timeText = '${ds.lastUpdated.hour.toString().padLeft(2, '0')}:${ds.lastUpdated.minute.toString().padLeft(2, '0')}';
                  Color iconBg;
                  try {
                    iconBg = Color(int.parse(ds.displayColor.replaceFirst('#', '0xFF')));
                  } catch (_) {
                    iconBg = isDark ? AppTheme.darkElevated : AppTheme.primaryPurple;
                  }

                  // Sélectionner l'icône en fonction du type et de l'état
                  IconData displayIcon;
                  if (_isLamp(ds)) {
                    displayIcon = isOn ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded;
                  } else {
                    displayIcon = Icons.electrical_services_rounded;
                  }

                  // Couleur de l'icône : selon l'état
                  Color iconColor;
                  if (_isLamp(ds)) {
                    iconColor = isOn ? iconBg : (isDark ? Colors.grey[600]! : Colors.grey[400]!);
                  } else {
                    // Pour les prises : vert si allumée, gris si éteinte
                    iconColor = isOn ? AppTheme.successGreen : (isDark ? Colors.grey[600]! : Colors.grey[400]!);
                  }

                  return IOSCard(
                    padding: const EdgeInsets.all(12),
                    child: GestureDetector(
                      onTap: _isLamp(ds) ? () => _showLightControlDialog(context, ds) : null,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Grand icône en haut
                          Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isOn 
                                  ? iconBg.withOpacity(0.15)
                                  : (isDark ? Colors.grey[800] : Colors.grey[200]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                displayIcon,
                                size: 32,
                                color: iconColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Nom et type
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                style: theme.textTheme.titleMedium,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                typeLabel,
                                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Badge statut
                          IOSStatusBadge(
                            text: isOn ? _settings.text('on') : _settings.text('off'),
                            color: isOn ? AppTheme.successGreen : AppTheme.errorRed,
                            icon: isOn ? Icons.power_rounded : Icons.power_off_rounded,
                          ),
                          const SizedBox(height: 6),
                          // Infos additionnelles
                          if (_isLamp(ds))
                            Text(
                              '${_settings.text('brightness')} : ${ds.brightness}%',
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 4),
                          Text(
                            timeText,
                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10, color: isDark ? Colors.white54 : Colors.black45),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
