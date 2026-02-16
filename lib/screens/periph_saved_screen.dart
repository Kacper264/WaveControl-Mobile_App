import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../widgets/ios_widgets.dart';
import '../services/mqtt_service.dart';
import '../services/app_settings.dart';
import 'ir_device_detail_screen.dart';

class PeriphSavedScreen extends StatefulWidget {
  const PeriphSavedScreen({super.key});

  @override
  State<PeriphSavedScreen> createState() => _PeriphSavedScreenState();
}

class _PeriphSavedScreenState extends State<PeriphSavedScreen> {
  final MQTTService _mqtt = MQTTService();
  final AppSettings _settings = AppSettings();
  bool _isLoading = true;
  List<Map<String, dynamic>> _savedDevices = [];
  String? _statusMessage;
  String? _statusType; // success | error | info
  String? _lastProcessedMessageId;
  String? _awaitingButtonForDevice; // Device name awaiting first button press

  @override
  void initState() {
    super.initState();
    _mqtt.addListener(_onMqttChanged);
    _loadSavedDevices();
  }

  @override
  void dispose() {
    _mqtt.removeListener(_onMqttChanged);
    super.dispose();
  }

  void _onMqttChanged() {
    final messages = _mqtt.recentMessages;
    debugPrint('>>> _onMqttChanged called, messages count: ${messages.length}');
    
    if (messages.isNotEmpty) {
      final lastMessage = messages.first;
      debugPrint('>>> Last message topic: ${lastMessage.topic}');
      debugPrint('>>> Last message payload: ${lastMessage.message}');
      
      final messageId = '${lastMessage.topic}_${lastMessage.message}_${lastMessage.timestamp}';
      if (_lastProcessedMessageId != messageId) {
        debugPrint('>>> Processing new message');
        _lastProcessedMessageId = messageId;
        _handleMqttMessage(lastMessage.topic, lastMessage.message);
      } else {
        debugPrint('>>> Message already processed, skipping');
      }
    }
  }

  void _handleMqttMessage(String topic, String payload) {
    debugPrint('>>> MQTT Message - Topic: $topic');
    debugPrint('>>> Payload: $payload');
    
    if (topic == 'home/IR/feedback' || topic == 'home/remote/new') {
      debugPrint('>>> Topic matched home/IR/feedback or home/remote/new!');
      try {
        final jsonData = jsonDecode(payload);
        debugPrint('>>> JSON decoded: $jsonData');
        
        // Vérifier le status si présent
        final status = jsonData['status'];
        debugPrint('>>> Status: $status');
        
        if (status == 'saved_list') {
          debugPrint('>>> Status is saved_list!');
          final telecommandes = jsonData['telecommandes'] as Map<String, dynamic>;
          debugPrint('>>> Telecommandes: $telecommandes');
          
          final devices = <Map<String, dynamic>>[];
          
          telecommandes.forEach((name, data) {
            debugPrint('>>> Adding device: $name with data: $data');
            devices.add({
              'name': name,
              'touches': List<String>.from(data['touches'] ?? []),
              'count': data['count'] ?? 0,
            });
          });
          
          debugPrint('>>> Total devices: ${devices.length}');
          
          if (mounted) {
            setState(() {
              _savedDevices = devices;
              _isLoading = false;
              _statusMessage = _settings.text('remotes_loaded');
              _statusType = 'success';
            });
            debugPrint('>>> State updated!');
          }
          
          // Vérifier si un bouton a été appris pour le device en attente
          if (_awaitingButtonForDevice != null) {
            final device = telecommandes[_awaitingButtonForDevice];
            if (device != null) {
              final touches = device['touches'] as List?;
              if (touches != null && touches.isNotEmpty) {
                debugPrint('>>> Bouton reçu pour $_awaitingButtonForDevice!');
                _awaitingButtonForDevice = null;
                
                // Afficher le checkmark vert
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(_settings.text('button_saved')),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          }
        } else if (status == 'created' || (topic == 'home/remote/new' && (status == null || status.toString() == 'null'))) {
          // Nouvelle télécommande créée via home/IR/feedback ou home/remote/new
          final deviceName = jsonData['telecommande'] as String?;
          debugPrint('>>> Status created or home/remote/new, device: $deviceName');
          debugPrint('>>> Current devices: ${_savedDevices.map((d) => d['name']).toList()}');
          
          if (deviceName != null && !_savedDevices.any((d) => d['name'] == deviceName)) {
            debugPrint('>>> Adding new device: $deviceName');
            if (mounted) {
              setState(() {
                _savedDevices.add({
                  'name': deviceName,
                  'touches': <String>[],
                  'count': 0,
                });
                _statusMessage = '${_settings.text('remote_created')} "$deviceName"';
                _statusType = 'success';
                _awaitingButtonForDevice = deviceName;
              });
              debugPrint('>>> Device added to list!');
            }
          } else {
            debugPrint('>>> Device already exists or invalid name');
          }
        } else if (status == 'learned') {
          // Une nouvelle action a été apprise, recharger la liste
          debugPrint('>>> Action learned, reloading devices...');
          _loadSavedDevices();
        } else if (status == 'deleted' || status == 'removed') {
          // Un périphérique a été supprimé, recharger la liste
          debugPrint('>>> Device deleted, reloading devices...');
          _loadSavedDevices();
        } else if (status == 'removed_button' || status == 'removed_remote') {
          // Une action ou un périphérique a été supprimé, recharger la liste
          debugPrint('>>> Item removed, reloading devices...');
          _loadSavedDevices();
        } else if (status != null && status != 'saved_list') {
          // Autre changement détecté, recharger par sécurité
          debugPrint('>>> Status changed: $status, reloading devices...');
          _loadSavedDevices();
        }
      } catch (e) {
        debugPrint('>>> ERROR parsing MQTT: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _statusMessage = '${_settings.text('error_loading')}: $e';
            _statusType = 'error';
          });
        }
      }
    } else {
      debugPrint('>>> Topic NOT matched: $topic');
    }
  }

  void _deleteDevice(String deviceName) {
    debugPrint('Deleting device: $deviceName');
    _mqtt.publishMessage('home/IR/remove/remote', deviceName);
    
    // Retirer localement en attente de la réponse du serveur
    setState(() {
      _savedDevices.removeWhere((d) => d['name'] == deviceName);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_settings.text('remote_deleted_with_name')} "$deviceName"'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _loadSavedDevices() {
    debugPrint('Sending MQTT request: home/remote/saved with message "saved"');
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _statusType = null;
    });
    _mqtt.publishMessage('home/remote/saved', 'saved');
  }

  void _showAddDeviceDialog() {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        title: Text(_settings.text('add_remote_dialog')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: _settings.text('remote_name_hint'),
            filled: true,
            fillColor: isDark ? AppTheme.darkBackground : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_settings.text('cancel')),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                // Vérifier que la télécommande n'existe pas déjà
                if (_savedDevices.any((d) => d['name'] == controller.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_settings.text('remote_exists')),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                final message = json.encode({
                  'telecommande': controller.text,
                });
                _mqtt.publishMessage('home/remote/new', message);
              }
            },
            child: Text(_settings.text('add')),
          ),
        ],
      ),
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
          _settings.text('saved_peripherals'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadSavedDevices,
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
            tooltip: 'Actualiser',
          ),
        ],
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
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryPurple),
                  )
                : _savedDevices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.devices_other_rounded,
                              size: 64,
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _settings.text('no_device_registered'),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _savedDevices.length,
                        itemBuilder: (context, index) {
                          final device = _savedDevices[index];
                          return Dismissible(
                            key: Key(device['name']),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              margin: const EdgeInsets.only(bottom: 12),
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
                                  backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
                                  title: Text('${_settings.text('delete')} "${device['name']}" ?'),
                                  content: Text(_settings.text('delete_remote_message')),
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
                              _deleteDevice(device['name']);
                            },
                            child: GestureDetector(
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                await Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) => IRDeviceDetailScreen(
                                      deviceName: device['name'],
                                      deviceData: device,
                                    ),
                                    transitionsBuilder: (_, anim, __, child) => SlideTransition(
                                      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                                          .chain(CurveTween(curve: Curves.easeInOut))
                                          .animate(anim),
                                      child: child,
                                    ),
                                  ),
                                );
                                // Rafraîchir après retour
                                _loadSavedDevices();
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: IOSCard(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: AppTheme.warningOrange.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.settings_remote,
                                              color: AppTheme.warningOrange,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  device['name'],
                                                  style: Theme.of(context).textTheme.titleMedium,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${device['count']} touche${device['count'] != 1 ? 's' : ''}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: isDark ? Colors.white54 : Colors.black38,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        children: (device['touches'] as List<String>)
                                            .map((touch) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppTheme.warningOrange.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                touch,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppTheme.warningOrange,
                                                ),
                                              ),
                                            ))
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            ),
                          );
                        },
                      ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: IOSButton(
                text: _settings.text('add_remote_dialog'),
                icon: Icons.add_rounded,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showAddDeviceDialog();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
