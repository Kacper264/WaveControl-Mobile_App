import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import '../services/app_settings.dart';
import 'dart:async';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../theme/app_theme.dart';
import '../widgets/ios_widgets.dart';

class MqttControlPage extends StatefulWidget {
  const MqttControlPage({super.key});

  @override
  State<MqttControlPage> createState() => _MqttControlPageState();
}

class _MqttControlPageState extends State<MqttControlPage> {
  final MQTTService _mqtt = MQTTService();
  final AppSettings _settings = AppSettings();
  double _historyHeight = 180;
  static const double _minHistoryHeight = 120;
  bool _isHistoryOpen = true;
  OverlayEntry? _toastEntry;

  @override
  void initState() {
    super.initState();
    _mqtt.addListener(_onMqttChanged);
    _settings.addListener(_onSettingsChanged);
    _mqtt.connect();
  }

  @override
  void dispose() {
    _hideToast();
    _mqtt.removeListener(_onMqttChanged);
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onMqttChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _hideToast() {
    _toastEntry?.remove();
    _toastEntry = null;
  }

  void _showToast(
    String message, {
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {    // Déterminer le type de notification et vérifier les paramètres
    bool shouldShow = true;
    if (backgroundColor == AppTheme.successGreen) {
      shouldShow = _settings.enableSuccessNotifications;
    } else if (backgroundColor == AppTheme.errorRed) {
      shouldShow = _settings.enableErrorNotifications;
    }

    if (!shouldShow) return;
    _hideToast();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? (isDark ? AppTheme.darkElevated : Colors.grey[900]!);

    _toastEntry = OverlayEntry(
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                builder: (context, value, child) => Transform.translate(
                  offset: Offset(0, -10 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppTheme.cardShadow(isDark),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_toastEntry!);

    Future.delayed(duration, () {
      if (mounted) {
        _hideToast();
      }
    });
  }

  // Affiche le dialog de sélection de couleur
  Future<void> _showColorPicker(String topic, Color currentColor) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_settings.text('choose_color')),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (Color color) {
                // Envoie la couleur immédiatement quand elle change
                _mqtt.setRgbColor(topic, color.red, color.green, color.blue);
              },
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
              labelTypes: const [],  // Cache les labels RGB/HSV
              pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(10)),
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
  }

  // Affiche le dialog de réglage de la luminosité
  Future<void> _showBrightnessSlider(String topic, int currentBrightness) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(_settings.text('adjust_brightness')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${currentBrightness}%'),
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
                      _mqtt.setBrightness(topic, currentBrightness);
                    },
                  ),
                ],
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

  Future<void> _send(String topic, String msg) async {
    final success = await _mqtt.publishMessage(topic, msg);

    _showToast(
      success
          ? '${_settings.text('command_sent')} $msg'
          : '${_settings.text('command_failed')} $msg',
      backgroundColor: success ? AppTheme.successGreen : AppTheme.errorRed,
      icon: success ? Icons.check_circle_rounded : Icons.error_rounded,
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxHistoryHeight = MediaQuery.of(context).size.height * 0.45;
    final historyHeight = _historyHeight.clamp(_minHistoryHeight, maxHistoryHeight);
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          _settings.text('test_request'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: IOSStatusBadge(
              text: _mqtt.isConnected ? _settings.text('connected') : _settings.text('disconnected'),
              color: _mqtt.isConnected ? AppTheme.successGreen : AppTheme.errorRed,
              icon: _mqtt.isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: !_mqtt.isConnected
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 64,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _settings.text('not_connected_mqtt'),
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _mqtt.deviceStates.values.length,
              itemBuilder: (context, index) {
                final device = _mqtt.deviceStates.values.toList()[index];
                final topic = device.topic;
                final name = device.friendlyName ?? topic;
                final state = device.state;
                final isLamp = !topic.contains('prise');
                final displayColor = isLamp ? device.displayColor : null;
                final brightness = isLamp ? device.brightness : 0;
                final statusColor = state == 'ON'
                    ? AppTheme.successGreen
                    : (state == 'OFF' ? (isDark ? Colors.grey[500]! : Colors.grey[700]!) : AppTheme.warningOrange);

                return IOSCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IOSStatusBadge(
                            text: state,
                            color: statusColor,
                            icon: state == 'ON'
                                ? Icons.power_rounded
                                : (state == 'OFF' ? Icons.power_off_rounded : Icons.help_outline_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        topic,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (isLamp && displayColor != null) ...[
                            GestureDetector(
                              onTap: () {
                                if (state == 'ON') {
                                  _showColorPicker(
                                    topic,
                                    Color(int.parse(displayColor.replaceFirst('#', '0xFF'))),
                                  );
                                }
                              },
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Color(int.parse(displayColor.replaceFirst('#', '0xFF'))),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (isLamp && brightness > 0) ...[
                            GestureDetector(
                              onTap: () {
                                if (state == 'ON') {
                                  _showBrightnessSlider(topic, brightness);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkElevated : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$brightness%',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          const Spacer(),
                          _buildActionButton(
                            label: 'ON',
                            color: AppTheme.successGreen,
                            onPressed: () => _send(topic, 'ON'),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            label: 'OFF',
                            color: isDark ? AppTheme.darkElevated : Colors.grey,
                            onPressed: () => _send(topic, 'OFF'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isHistoryOpen)
            IOSCard(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (details) {
                      setState(() {
                        _historyHeight = (_historyHeight - details.delta.dy)
                            .clamp(_minHistoryHeight, maxHistoryHeight);
                      });
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.black12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              _settings.text('history'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_mqtt.history.length}',
                              style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 12),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: historyHeight,
                    child: _mqtt.history.isEmpty
                        ? Center(child: Text(_settings.text('no_history')))
                        : ListView.builder(
                            itemCount: _mqtt.history.length,
                            itemBuilder: (context, index) {
                              final h = _mqtt.history[index];
                              final timeText = h.timestamp.toLocal().toString().split('.')[0];
                              final directionText = h.isIncoming ? 'Recu' : 'Envoye';
                              final directionIcon = h.isIncoming ? Icons.call_received_rounded : Icons.call_made_rounded;
                              final directionColor = h.isIncoming ? AppTheme.secondaryBlue : AppTheme.primaryPurple;
                              final statusIcon = h.success ? Icons.check_circle_rounded : Icons.error_rounded;
                              final statusColor = h.success ? AppTheme.successGreen : AppTheme.errorRed;
                              final errorText = h.error != null ? '${_settings.text('error_text')}: ${h.error}' : null;
                              final subtitle = errorText == null
                                  ? '${h.message}  •  $directionText  •  $timeText'
                                  : '${h.message}  •  $directionText  •  $timeText\n$errorText';

                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(directionIcon, color: directionColor, size: 18),
                                title: Text(
                                  h.topic,
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                                ),
                                subtitle: Text(
                                  subtitle,
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Icon(statusIcon, color: statusColor, size: 16),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => _mqtt.clearHistory(),
                          child: Text(
                            _settings.text('clear_history'),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isHistoryOpen = false;
                            });
                          },
                          child: Text(
                            _settings.text('close_history'),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (!_isHistoryOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: IOSButton(
                text: 'Ouvrir l\'historique',
                icon: Icons.history_rounded,
                color: AppTheme.secondaryBlue,
                onPressed: () {
                  setState(() {
                    _isHistoryOpen = true;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}
