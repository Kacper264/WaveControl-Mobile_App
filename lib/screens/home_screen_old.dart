import 'package:flutter/material.dart';
import 'configuration_screen.dart';
import 'IR_configuration_screen.dart';
import 'mqtt_control_page.dart';
import 'monitoring_screen.dart';
import 'settings_screen.dart';
import 'package:battery_plus/battery_plus.dart';
import '../services/mqtt_service.dart';
import '../services/app_settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MQTTService _mqtt = MQTTService();
  final Battery _battery = Battery();
  final AppSettings _settings = AppSettings();
  int _batteryLevel = 100;

  @override
  void initState() {
    super.initState();
    _mqtt.addListener(_onMqttChanged);
    _settings.addListener(_onSettingsChanged);
    _readBatteryLevel();
  }

  @override
  void dispose() {
    _mqtt.removeListener(_onMqttChanged);
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onMqttChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _readBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      if (!mounted) return;
      setState(() => _batteryLevel = level);
    } catch (e) {
      // ignore errors, keep placeholder
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8C5CF6), Color(0xFF4D9FFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.watch,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'WaveControl',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF8C5CF6),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Icon(
                    _mqtt.isConnected ? Icons.wifi : Icons.wifi_off,
                    color: _mqtt.isConnected ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _mqtt.isConnected ? _settings.text('connected') : _settings.text('disconnected'),
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  // Small battery indicator (shows actual level)
                  Row(
                    children: [
                      Icon(
                        Icons.battery_full,
                        color: isDark ? Colors.white70 : Colors.black54,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_batteryLevel%',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20.0,
                crossAxisSpacing: 20.0,
                children: [
                  _buildGradientButton(
                    icon: Icons.build,
                    label: _settings.text('configuration'),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8C5CF6), Color(0xFF4D9FFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(_settings.text('configuration')),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const IRConfigurationScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text('Infra Rouge'),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const ConfigurationScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text('Configuration des mouvements'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  _buildGradientButton(
                    icon: Icons.monitor,
                    label: _settings.text('monitoring'),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8C5CF6), Color(0xFF4D9FFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MonitoringScreen(),
                        ),
                      );
                    },
                  ),
                  _buildGradientButton(
                    icon: Icons.refresh,
                    label: _settings.text('RECONNECT'),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8C5CF6), Color(0xFF4D9FFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      MQTTService().publishMessage('home/matter/request', 'test');
                    },
                  ),
                  _buildGradientButton(
                    icon: Icons.send,
                    label: _settings.text('test_request'),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8C5CF6), Color(0xFF4D9FFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MqttControlPage(),
                        ),
                      );
                    },
                  ),
                  _buildGradientButton(
                    icon: Icons.settings,
                    label: _settings.text('settings'),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8C5CF6), Color(0xFF4D9FFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return _AnimatedGradientButton(
      icon: icon,
      label: label,
      gradient: gradient,
      onTap: onTap,
    );
  }
}

class _AnimatedGradientButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _AnimatedGradientButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<_AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}