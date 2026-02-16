  import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../services/app_settings.dart';
import 'ir_device_detail_screen.dart';

class IRConfigurationScreen extends StatefulWidget {
  const IRConfigurationScreen({super.key});

  @override
  State<IRConfigurationScreen> createState() => _IRConfigurationScreenState();
}

class _IRConfigurationScreenState extends State<IRConfigurationScreen> with WidgetsBindingObserver, RouteAware {
  final AppSettings _settings = AppSettings();
  List<String> _savedDevices = [];
  Map<String, List<String>> _deviceTouches = {};
  final RouteObserver<PageRoute> _routeObserver = RouteObserver<PageRoute>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings.addListener(_onSettingsChanged);
    _refreshDevices();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
    _refreshDevices();
  }
  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDevices();
    }
  }

  @override
  void didPopNext() {
    // Appelé quand on revient sur cet écran depuis un autre écran
    _refreshDevices();
  }

  @override
  void didPush() {
    // Appelé quand cet écran est poussé sur la pile
  }

  @override
  void didPop() {
    // Appelé quand cet écran est retiré de la pile
  }

  @override
  void didPushNext() {
    // Appelé quand un nouvel écran est poussé par-dessus celui-ci
  }

  void _onSettingsChanged() {
    _refreshDevices();
  }

  Future<Map<String, dynamic>> _getDeviceData(String device) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceDataStr = prefs.getString('deviceData_$device');
    if (deviceDataStr != null && deviceDataStr.isNotEmpty && deviceDataStr.startsWith('{')) {
      try {
        return Map<String, dynamic>.from(jsonDecode(deviceDataStr));
      } catch (_) {}
    }
    return {};
  }

  Future<void> _refreshDevices() async {
    print('📥 Début du rafraîchissement...');
    final prefs = await SharedPreferences.getInstance();
    final devices = prefs.getStringList('savedDevices') ?? [];
    print('📱 Périphériques trouvés: $devices');
    final touchesMap = <String, List<String>>{};
    for (final device in devices) {
      final deviceDataStr = prefs.getString('deviceData_$device');
      print('🔍 deviceData_$device: $deviceDataStr');
      if (deviceDataStr != null) {
        try {
          final deviceData = deviceDataStr.isNotEmpty ? (deviceDataStr.startsWith('{') ? jsonDecode(deviceDataStr) : {}) : {};
          final touchesRaw = deviceData['touches'];
          final touches = touchesRaw is List ? touchesRaw.map((e) => e.toString()).toList() : <String>[];
          print('✨ Touches pour $device: $touches');
          touchesMap[device] = touches;
        } catch (e) {
          print('❌ Erreur pour $device: $e');
          touchesMap[device] = [];
        }
      } else {
        touchesMap[device] = [];
      }
    }
    if (mounted) {
      setState(() {
        _savedDevices = devices;
        _deviceTouches = touchesMap;
      });
      print('✅ setState appelé - _deviceTouches: $_deviceTouches');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Forcer le rafraîchissement à chaque build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshDevices();
      }
    });
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          _settings.text('config_ir'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: _savedDevices.isEmpty
                  ? Center(child: Text(_settings.text('no_device_registered')))
                  : ListView.builder(
                      itemCount: _savedDevices.length,
                      itemBuilder: (context, index) {
                        final device = _savedDevices[index];
                        final touches = _deviceTouches[device] ?? [];
                        return Card(
                          child: ListTile(
                            leading: Icon(Icons.devices),
                            title: Text(device),
                            subtitle: touches.isEmpty
                                ? Text(_settings.text('no_action_saved'))
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: touches.map((t) => Text('• $t')).toList(),
                                  ),
                            onTap: () async {
                              // Récupérer les données avant la navigation
                              final deviceData = await _getDeviceData(device);
                              // Navigation vers le détail et rafraîchissement au retour
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => IRDeviceDetailScreen(
                                    deviceName: device,
                                    deviceData: deviceData,
                                  ),
                                ),
                              );
                              // Forcer le rafraîchissement après retour
                              print('🔄 Rafraîchissement après retour...');
                              await _refreshDevices();
                              print('✅ Rafraîchissement terminé');
                            },
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.add_circle),
              label: Text(_settings.text('add_device')),
              onPressed: () {
                // TODO: Implémenter l'ajout de périphérique
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedIRCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _AnimatedIRCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_AnimatedIRCard> createState() => _AnimatedIRCardState();
}

class _AnimatedIRCardState extends State<_AnimatedIRCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withOpacity(0.3),
                spreadRadius: 0,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

