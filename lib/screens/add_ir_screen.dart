import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/ios_widgets.dart';
import '../services/app_settings.dart';

class AddIRScreen extends StatefulWidget {
  const AddIRScreen({super.key});

  @override
  State<AddIRScreen> createState() => _AddIRScreenState();
}

class _AddIRScreenState extends State<AddIRScreen> {
  final AppSettings _settings = AppSettings();
  final TextEditingController _nameController = TextEditingController();
  String? _selectedType;
  final List<String> _deviceTypeKeys = [
    'ir_type_tv',
    'ir_type_air_conditioner',
    'ir_type_ac_unit',
    'ir_type_lighting',
    'ir_type_other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
          _settings.text('add_peripheral'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Formulaire
              IOSCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _settings.text('peripheral_info'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      IOSTextField(
                        label: _settings.text('peripheral_name'),
                        hint: _settings.text('peripheral_name_example'),
                        controller: _nameController,
                        prefixIcon: Icons.device_unknown_rounded,
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _settings.text('device_type'),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.labelMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedType,
                            hint: Text(_settings.text('select_type')),
                            items: _deviceTypeKeys.map((typeKey) {
                              return DropdownMenuItem(
                                value: typeKey,
                                child: Text(_settings.text(typeKey)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedType = value);
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark ? AppTheme.darkCard : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Bouton d'ajout
              SizedBox(
                width: double.infinity,
                child: IOSButton(
                  text: _settings.text('add_peripheral_button'),
                  icon: Icons.add_rounded,
                  onPressed: () {
                    if (_nameController.text.isEmpty || _selectedType == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_settings.text('fill_all_fields')),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    HapticFeedback.mediumImpact();
                    // Logique d'ajout ici
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
