import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/ios_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppSettings _settings = AppSettings();
  late final TextEditingController _mqttServerController;
  late final TextEditingController _mqttPortController;
  late final TextEditingController _mqttUsernameController;
  late final TextEditingController _mqttPasswordController;

  @override
  void initState() {
    super.initState();
    _mqttServerController = TextEditingController(text: _settings.mqttServer);
    _mqttPortController = TextEditingController(text: _settings.mqttPort.toString());
    _mqttUsernameController = TextEditingController(text: _settings.mqttUsername);
    _mqttPasswordController = TextEditingController(text: _settings.mqttPassword);
    _settings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _mqttServerController.dispose();
    _mqttPortController.dispose();
    _mqttUsernameController.dispose();
    _mqttPasswordController.dispose();
    super.dispose();
  }

  String _getLanguageName(String langCode) {
    switch (langCode) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      case 'de':
        return 'Deutsch';
      case 'zh':
        return '中文';
      default:
        return langCode;
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
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          _settings.text('settings'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 8),
          // MQTT Configuration
          IOSCard(
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.wifi, color: AppTheme.secondaryBlue, size: 22),
                ),
                title: Text(
                  _settings.text('mqtt_connection'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                  ),
                ),
                subtitle: Text(
                  _settings.text('mqtt_subtitle'),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                    letterSpacing: -0.2,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white30 : Colors.black26,
                  size: 24,
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showMqttDialog();
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Language
          IOSCard(
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.language, color: AppTheme.primaryPurple, size: 22),
                ),
                title: Text(
                  _settings.text('language'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                  ),
                ),
                subtitle: Text(
                  _getLanguageName(_settings.language),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                    letterSpacing: -0.2,
                  ),
                ),
                trailing: DropdownButton<String>(
                  value: _settings.language,
                  underline: SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      HapticFeedback.lightImpact();
                      _settings.setLanguage(newValue);
                    }
                  },
                  items: <String>['en', 'fr', 'es', 'de', 'zh']
                    .map<DropdownMenuItem<String>>((String value) {
                      String label = _getLanguageName(value);
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(label),
                      );
                    })
                    .toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Theme
          IOSCard(
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: AppTheme.warningOrange,
                    size: 22,
                  ),
                ),
                title: Text(
                  _settings.text('theme'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                  ),
                ),
                subtitle: Text(
                  _settings.isDarkMode ? _settings.text('dark_mode') : _settings.text('light_mode'),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                    letterSpacing: -0.2,
                  ),
                ),
                trailing: Switch(
                  value: _settings.isDarkMode,
                  activeColor: AppTheme.warningOrange,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    _settings.toggleTheme();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // User Mode
          IOSCard(
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _settings.userMode == UserMode.developer 
                        ? Icons.code_rounded
                        : _settings.userMode == UserMode.technician
                            ? Icons.engineering_rounded
                            : Icons.person_rounded,
                    color: AppTheme.secondaryBlue,
                    size: 22,
                  ),
                ),
                title: Text(
                  _settings.text('user_mode'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                  ),
                ),
                subtitle: Text(
                  _settings.getUserModeLabel(),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                    letterSpacing: -0.2,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white30 : Colors.black26,
                  size: 24,
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showUserModeDialog();
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Access Passwords - Only for Developer and Technician
          if (_settings.userMode != UserMode.user)
            ...[
              IOSCard(
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.lock, color: AppTheme.errorRed, size: 22),
                    ),
                    title: Text(
                      _settings.text('passwords'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.3,
                      ),
                    ),
                    subtitle: Text(
                      _settings.text('passwords_subtitle'),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                        letterSpacing: -0.2,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: isDark ? Colors.white30 : Colors.black26,
                      size: 24,
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showChangePasswordsDialog();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          
          // Notifications
          IOSCard(
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.notifications, color: AppTheme.successGreen, size: 22),
                ),
                title: Text(
                  _settings.text('notifications'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                  ),
                ),
                subtitle: Text(
                  _settings.text('notifications_subtitle'),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                    letterSpacing: -0.2,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white30 : Colors.black26,
                  size: 24,
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showNotificationSettings();
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // About
          IOSCard(
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.info, color: AppTheme.errorRed, size: 22),
                ),
                title: Text(
                  _settings.text('about'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                  ),
                ),
                subtitle: Text(
                  _settings.text('about_subtitle'),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                    letterSpacing: -0.2,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white30 : Colors.black26,
                  size: 24,
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showAboutDialog();
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showMqttDialog() {
    _mqttPasswordController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MqttDialog(
        settings: _settings,
        serverController: _mqttServerController,
        portController: _mqttPortController,
        usernameController: _mqttUsernameController,
        passwordController: _mqttPasswordController,
      ),
    );
  }

  Future<void> _confirmAndSetUserMode(UserMode mode) async {
    if (_settings.userMode == mode) {
      return;
    }

    if (mode == UserMode.user) {
      await _settings.setUserMode(mode);
      return;
    }

    final allowed = await _showModePasswordDialog(mode);
    if (!allowed) return;

    await _settings.setUserMode(mode);
  }

  Future<bool> _showModePasswordDialog(UserMode mode) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PasswordPromptSheet(
        settings: _settings,
        mode: mode,
      ),
    );
    return result ?? false;
  }

  void _showChangePasswordsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChangePasswordsSheet(
        settings: _settings,
      ),
    );
  }

  void _showUserModeDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AnimatedBuilder(
        animation: _settings,
        builder: (context, _) => IOSCard(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _settings.text('user_mode'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Mode Développeur
                _buildModeOption(
                  context,
                  mode: UserMode.developer,
                  icon: Icons.code_rounded,
                  title: _settings.text('mode_developer'),
                  description: _settings.text('mode_developer_desc'),
                  color: AppTheme.primaryPurple,
                ),
                const SizedBox(height: 12),
                
                // Mode Technicien
                _buildModeOption(
                  context,
                  mode: UserMode.technician,
                  icon: Icons.engineering_rounded,
                  title: _settings.text('mode_technician'),
                  description: _settings.text('mode_technician_desc'),
                  color: AppTheme.secondaryBlue,
                ),
                const SizedBox(height: 12),
                
                // Mode Utilisateur
                _buildModeOption(
                  context,
                  mode: UserMode.user,
                  icon: Icons.person_rounded,
                  title: _settings.text('mode_user'),
                  description: _settings.text('mode_user_desc'),
                  color: AppTheme.successGreen,
                ),
                const SizedBox(height: 20),
                
                IOSButton(
                  text: _settings.text('close'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context, {
    required UserMode mode,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _settings.userMode == mode;
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? color.withOpacity(0.15)
            : (isDark ? AppTheme.darkCard.withOpacity(0.5) : Colors.white.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            HapticFeedback.mediumImpact();
            await _confirmAndSetUserMode(mode);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: color,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.notifications_active_rounded, 
                          color: AppTheme.successGreen, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _settings.text('notification_settings_title'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              _settings.text('notification_settings_subtitle'),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildModernNotificationCard(
                    title: _settings.text('success_notifications'),
                    subtitle: _settings.text('success_notif_desc'),
                    icon: Icons.check_circle_rounded,
                    color: AppTheme.successGreen,
                    value: _settings.enableSuccessNotifications,
                    onChanged: (value) {
                      _settings.setSuccessNotificationsEnabled(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildModernNotificationCard(
                    title: _settings.text('error_notifications'),
                    subtitle: _settings.text('error_notif_desc'),
                    icon: Icons.error_rounded,
                    color: AppTheme.errorRed,
                    value: _settings.enableErrorNotifications,
                    onChanged: (value) {
                      _settings.setErrorNotificationsEnabled(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildModernNotificationCard(
                    title: _settings.text('learning_notifications'),
                    subtitle: _settings.text('learning_ir_in_progress'),
                    icon: Icons.lightbulb_rounded,
                    color: AppTheme.warningOrange,
                    value: _settings.enableLearningNotifications,
                    onChanged: (value) {
                      _settings.setLearningNotificationsEnabled(value);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernNotificationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IOSCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.08),
              color.withOpacity(0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: color.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onChanged(!value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: Switch(
                      value: value,
                      onChanged: onChanged,
                      activeColor: color,
                      activeTrackColor: color.withOpacity(0.3),
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

  void _showAboutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IOSCard(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WaveControl',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version: 2.0.0',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.black54,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _settings.text('app_description'),
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.5,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '© 2026 WaveControl',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.24),
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 20),
              IOSButton(
                text: _settings.text('close'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordPromptSheet extends StatefulWidget {
  final AppSettings settings;
  final UserMode mode;

  const _PasswordPromptSheet({
    required this.settings,
    required this.mode,
  });

  @override
  State<_PasswordPromptSheet> createState() => _PasswordPromptSheetState();
}

class _PasswordPromptSheetState extends State<_PasswordPromptSheet> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = widget.mode == UserMode.developer
        ? widget.settings.text('developer_password')
        : widget.settings.text('technician_password');

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: IOSCard(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 16),
              IOSTextField(
                label: widget.settings.text('enter_password'),
                controller: _controller,
                prefixIcon: Icons.lock,
                obscureText: !_showPassword,
                suffixIcon: _showPassword ? Icons.visibility_off : Icons.visibility,
                onSuffixTap: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
                keyboardType: TextInputType.number,
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: TextStyle(
                    color: AppTheme.errorRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: IOSButton(
                      text: widget.settings.text('cancel'),
                      secondary: true,
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: IOSButton(
                      text: widget.settings.text('validate'),
                      onPressed: () {
                        final isValid = widget.settings.verifyModePassword(
                          widget.mode,
                          _controller.text.trim(),
                        );
                        if (!isValid) {
                          setState(() {
                            _errorText = widget.settings.text('wrong_password');
                          });
                          return;
                        }
                        Navigator.pop(context, true);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordsSheet extends StatefulWidget {
  final AppSettings settings;

  const _ChangePasswordsSheet({
    required this.settings,
  });

  @override
  State<_ChangePasswordsSheet> createState() => _ChangePasswordsSheetState();
}

class _ChangePasswordsSheetState extends State<_ChangePasswordsSheet> {
  late final TextEditingController _devCurrentController;
  late final TextEditingController _devNewController;
  late final TextEditingController _techCurrentController;
  late final TextEditingController _techNewController;
  String? _errorText;
  UserMode _selectedTarget = UserMode.developer;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;

  @override
  void initState() {
    super.initState();
    _devCurrentController = TextEditingController();
    _devNewController = TextEditingController();
    _techCurrentController = TextEditingController();
    _techNewController = TextEditingController();
  }

  @override
  void dispose() {
    _devCurrentController.dispose();
    _devNewController.dispose();
    _techCurrentController.dispose();
    _techNewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: IOSCard(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.settings.text('passwords'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.settings.text('leave_empty_keep'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: IOSButton(
                        text: widget.settings.text('mode_developer'),
                        secondary: true,
                        color: _selectedTarget == UserMode.developer
                            ? AppTheme.primaryPurple
                            : (isDark ? Colors.white38 : Colors.black45),
                        onPressed: () {
                          setState(() {
                            _selectedTarget = UserMode.developer;
                            _errorText = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: IOSButton(
                        text: widget.settings.text('mode_technician'),
                        secondary: true,
                        color: _selectedTarget == UserMode.technician
                            ? AppTheme.secondaryBlue
                            : (isDark ? Colors.white38 : Colors.black45),
                        onPressed: () {
                          setState(() {
                            _selectedTarget = UserMode.technician;
                            _errorText = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedTarget == UserMode.developer
                      ? widget.settings.text('developer_password')
                      : widget.settings.text('technician_password'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                IOSTextField(
                  label: widget.settings.text('current_password'),
                  controller: _selectedTarget == UserMode.developer
                      ? _devCurrentController
                      : _techCurrentController,
                  prefixIcon: Icons.lock,
                  obscureText: !_showCurrentPassword,
                  suffixIcon: _showCurrentPassword ? Icons.visibility_off : Icons.visibility,
                  onSuffixTap: () {
                    setState(() {
                      _showCurrentPassword = !_showCurrentPassword;
                    });
                  },
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                IOSTextField(
                  label: widget.settings.text('new_password'),
                  controller: _selectedTarget == UserMode.developer
                      ? _devNewController
                      : _techNewController,
                  prefixIcon: Icons.lock,
                  obscureText: !_showNewPassword,
                  suffixIcon: _showNewPassword ? Icons.visibility_off : Icons.visibility,
                  onSuffixTap: () {
                    setState(() {
                      _showNewPassword = !_showNewPassword;
                    });
                  },
                  keyboardType: TextInputType.number,
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorText!,
                    style: TextStyle(
                      color: AppTheme.errorRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: IOSButton(
                        text: widget.settings.text('cancel'),
                        secondary: true,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: IOSButton(
                        text: widget.settings.text('save'),
                        onPressed: () async {
                          final current = _selectedTarget == UserMode.developer
                              ? _devCurrentController.text.trim()
                              : _techCurrentController.text.trim();
                          final next = _selectedTarget == UserMode.developer
                              ? _devNewController.text.trim()
                              : _techNewController.text.trim();

                          if (next.isEmpty) {
                            setState(() {
                              _errorText = widget.settings.text('enter_password');
                            });
                            return;
                          }

                          if (current.isEmpty) {
                            setState(() {
                              _errorText = widget.settings.text('current_password_required');
                            });
                            return;
                          }

                          final valid = widget.settings.verifyModePassword(
                            _selectedTarget,
                            current,
                          );
                          if (!valid) {
                            setState(() {
                              _errorText = widget.settings.text('wrong_password');
                            });
                            return;
                          }

                          if (_selectedTarget == UserMode.developer) {
                            await widget.settings.setDeveloperPassword(next);
                          } else {
                            await widget.settings.setTechnicianPassword(next);
                          }

                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(widget.settings.text('passwords_updated')),
                              backgroundColor: AppTheme.successGreen,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
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
  }
}

class _MqttDialog extends StatefulWidget {
  final AppSettings settings;
  final TextEditingController serverController;
  final TextEditingController portController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  const _MqttDialog({
    required this.settings,
    required this.serverController,
    required this.portController,
    required this.usernameController,
    required this.passwordController,
  });

  @override
  State<_MqttDialog> createState() => _MqttDialogState();
}

class _MqttDialogState extends State<_MqttDialog> {
  String? _errorText;
  bool _showMqttPassword = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IOSCard(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.settings.text('mqtt_connection'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 20),
              IOSTextField(
                label: widget.settings.text('mqtt_server'),
                controller: widget.serverController,
                prefixIcon: Icons.dns,
              ),
              const SizedBox(height: 12),
              IOSTextField(
                label: widget.settings.text('port'),
                controller: widget.portController,
                prefixIcon: Icons.settings_input_component,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              IOSTextField(
                label: widget.settings.text('username'),
                controller: widget.usernameController,
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 12),
              IOSTextField(
                label: widget.settings.text('password'),
                controller: widget.passwordController,
                prefixIcon: Icons.lock,
                obscureText: !_showMqttPassword,
                suffixIcon: _showMqttPassword ? Icons.visibility_off : Icons.visibility,
                onSuffixTap: () {
                  setState(() {
                    _showMqttPassword = !_showMqttPassword;
                  });
                },
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() {
                      _errorText = null;
                    });
                  }
                },
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: TextStyle(
                    color: AppTheme.errorRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: IOSButton(
                      text: widget.settings.text('cancel'),
                      secondary: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: IOSButton(
                      text: widget.settings.text('save'),
                      onPressed: () {
                        final server = widget.serverController.text;
                        final port = int.tryParse(widget.portController.text) ?? widget.settings.mqttPort;
                        final username = widget.usernameController.text;
                        final password = widget.passwordController.text.trim();

                        if (password.isEmpty) {
                          setState(() {
                            _errorText = widget.settings.text('enter_password');
                          });
                          return;
                        }

                        widget.settings.setMqttConfig(
                          server: server,
                          port: port,
                          username: username,
                          password: password,
                        );

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(widget.settings.text('restart_required')),
                            backgroundColor: AppTheme.warningOrange,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

