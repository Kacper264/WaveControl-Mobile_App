import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/mqtt_service.dart';
import '../services/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/ios_widgets.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class IRDeviceDetailScreen extends StatefulWidget {
  final String deviceName;
  final Map<String, dynamic> deviceData;

  const IRDeviceDetailScreen({
    required this.deviceName,
    required this.deviceData,
  });

  @override
  State<IRDeviceDetailScreen> createState() => _IRDeviceDetailScreenState();
}

class _IRDeviceDetailScreenState extends State<IRDeviceDetailScreen> {
    // Sauvegarde la liste des touches dans SharedPreferences
    Future<void> _saveTouches() async {
      final prefs = await SharedPreferences.getInstance();
      final deviceData = Map<String, dynamic>.from(widget.deviceData);
      deviceData['touches'] = _touches;
      prefs.setString('deviceData_${widget.deviceName}', json.encode(deviceData));
    }

    // Supprime une touche via MQTT
    Future<void> _deleteTouch(String touch) async {
      final message = json.encode({
        'telecommande': widget.deviceName,
        'touche': touch,
      });
      _mqtt.publishMessage('home/IR/remove/button', message);
      
      // Retirer localement en attente de la réponse du serveur
      setState(() {
        _touches.remove(touch);
      });
      await _saveTouches();
      
      _showToast(
        _settings.text('action_deleted'),
        backgroundColor: AppTheme.errorRed,
        icon: Icons.delete_rounded,
      );
    }
  final MQTTService _mqtt = MQTTService();
  final AppSettings _settings = AppSettings();
  late List<String> _touches;
  String? _statusMessage;
  String? _statusType;
  bool _isLearning = false;
  String? _lastProcessedMessageId;
  OverlayEntry? _toastEntry;

  @override
  void initState() {
    super.initState();
    _touches = List<String>.from(widget.deviceData['touches'] ?? []);
    _mqtt.addListener(_onMqttChanged);
  }

  @override
  void dispose() {
    _mqtt.removeListener(_onMqttChanged);
    _hideToast();
    super.dispose();
  }

  void _hideToast() {
    _toastEntry?.remove();
    _toastEntry = null;
  }

  void _showToast(
    String message, {
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    // Déterminer le type de notification et vérifier les paramètres
    bool shouldShow = true;
    if (backgroundColor == AppTheme.successGreen) {
      shouldShow = _settings.enableSuccessNotifications;
    } else if (backgroundColor == AppTheme.errorRed) {
      shouldShow = _settings.enableErrorNotifications;
    } else if (backgroundColor == AppTheme.warningOrange) {
      shouldShow = _settings.enableLearningNotifications;
    }

    if (!shouldShow) return;

    _hideToast();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? AppTheme.darkCard : Colors.white);
    final textColor = backgroundColor != null ? Colors.white : (isDark ? Colors.white : Colors.black87);

    final entry = OverlayEntry(
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -10 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppTheme.cardShadow(isDark),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: textColor, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          message,
                          style: TextStyle(
                            color: textColor,
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

    Overlay.of(context).insert(entry);
    _toastEntry = entry;

    Future.delayed(duration, () {
      if (_toastEntry == entry) {
        _hideToast();
      }
    });
  }

  void _onMqttChanged() {
    if (!mounted) return;
    final messages = _mqtt.recentMessages;
    if (messages.isEmpty) return;

    final lastMessage = messages.first;
    final messageId = '${lastMessage.topic}-${lastMessage.timestamp}';
    
    if (_lastProcessedMessageId == messageId) return;
    _lastProcessedMessageId = messageId;

    _handleMqttMessage(lastMessage.topic, lastMessage.message);
  }

  void _handleMqttMessage(String topic, String payload) {
    if (topic != 'home/IR/feedback') return;

    try {
      final jsonData = json.decode(payload);
      
      if (jsonData['status'] == 'learned') {
        final deviceName = jsonData['telecommande'] as String?;
        final touche = jsonData['touche'] as String?;

        if (deviceName == widget.deviceName && touche != null) {
          if (!_touches.contains(touche)) {
            setState(() {
              _touches.add(touche);
              _isLearning = false;
              _statusMessage = '${_settings.text('action_added_success')} "$touche"';
              _statusType = 'success';
            });

            // Sauvegarde dans SharedPreferences
            _saveTouches();

            _showToast(
              '${_settings.text('action_added_success')} "$touche"',
              backgroundColor: AppTheme.successGreen,
              icon: Icons.check_circle_rounded,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing MQTT: $e');
    }

  }

  void _startLearning(String toucheName) {
    setState(() {
      _isLearning = true;
      _statusMessage = _settings.text('waiting_ir_command');
      _statusType = 'info';
    });

    _showToast(
      _settings.text('point_remote_and_press'),
      backgroundColor: AppTheme.warningOrange,
      icon: Icons.lightbulb_rounded,
      duration: const Duration(seconds: 6),
    );

    // Publish le message pour demander l'apprentissage
    final message = json.encode({
      'telecommande': widget.deviceName,
      'touche': toucheName,
    });
    _mqtt.publishMessage('home/remote/new', message);
  }

  void _showAddTouchDialog() {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: AppTheme.cardShadow(isDark),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.flash_on_rounded,
                            color: AppTheme.secondaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _settings.text('new_ir_action'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ex: power, volume_up, mute',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isDark ? Colors.white54 : Colors.black54,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: _settings.text('action_name'),
                        filled: true,
                        fillColor: isDark ? AppTheme.darkBackground : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white70 : Colors.black87,
                              side: BorderSide(
                                color: (isDark ? Colors.white : Colors.black).withOpacity(0.15),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(_settings.text('cancel')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final actionName = controller.text.trim();
                              if (actionName.isEmpty) {
                                _showToast(
                                  _settings.text('enter_name'),
                                  backgroundColor: AppTheme.errorRed,
                                  icon: Icons.error_rounded,
                                );
                                return;
                              }
                              if (_touches.contains(actionName)) {
                                _showToast(
                                  _settings.text('action_exists'),
                                  backgroundColor: AppTheme.errorRed,
                                  icon: Icons.error_rounded,
                                );
                                return;
                              }
                              Navigator.pop(context);
                              _startLearning(actionName);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(_settings.text('add')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        title: Text(
          widget.deviceName,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Message de statut
            if (_statusMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusType == 'success'
                      ? AppTheme.successGreen.withOpacity(0.1)
                      : _statusType == 'error'
                          ? AppTheme.errorRed.withOpacity(0.1)
                          : AppTheme.secondaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _statusType == 'success'
                        ? AppTheme.successGreen.withOpacity(0.3)
                        : _statusType == 'error'
                            ? AppTheme.errorRed.withOpacity(0.3)
                            : AppTheme.secondaryBlue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _statusType == 'success'
                          ? Icons.check_circle_rounded
                          : _statusType == 'error'
                              ? Icons.error_rounded
                              : Icons.info_rounded,
                      color: _statusType == 'success'
                          ? AppTheme.successGreen
                          : _statusType == 'error'
                              ? AppTheme.errorRed
                              : AppTheme.secondaryBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Liste des actions
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _touches.length,
                itemBuilder: (context, index) {
                  final touch = _touches[index];
                  return Dismissible(
                    key: Key(touch),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkCard
                              : Colors.white,
                          title: Text('${_settings.text('delete')} "$touch" ?'),
                          content: Text(_settings.text('delete_action_message')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(_settings.text('cancel')),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(_settings.text('delete'), style: const TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ) ?? false;
                    },
                    onDismissed: (direction) {
                      _deleteTouch(touch);
                    },
                    child: GestureDetector(
                      onTap: () {
                        // Envoyer l'action au replay
                        final message = json.encode({
                          'telecommande': widget.deviceName,
                          'touche': touch,
                        });
                        _mqtt.publishMessage('home/IR/replay', message);
                        
                        // Afficher un SnackBar de confirmation
                        _showToast(
                          '${_settings.text('action_sent_success')} "$touch"',
                          backgroundColor: AppTheme.successGreen,
                          icon: Icons.check_circle_rounded,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppTheme.cardShadow(isDark),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    touch,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _settings.text('swipe_to_delete'),
                                    style: TextStyle(
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.touch_app_rounded,
                                color: AppTheme.secondaryBlue,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bouton ajouter action
            Padding(
              padding: const EdgeInsets.all(16),
              child: IOSButton(
                text: _settings.text('add_action'),
                icon: Icons.add_rounded,
                onPressed: _isLearning ? null : _showAddTouchDialog,
                color: _isLearning ? Colors.grey : AppTheme.secondaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
