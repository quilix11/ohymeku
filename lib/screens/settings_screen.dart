// lib/screens/settings_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsService settings;
  const SettingsScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'НАЛАШТУВАННЯ', // SETTINGS
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // balance back button
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                children: [
                  const Text('ЗАГАЛЬНІ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  
                  // GENERAL SETTINGS CARD
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderDefault, width: 2),
                    ),
                    child: Column(
                      children: [
                        _SettingsToggleRow(
                          iconPath: Icons.volume_up_rounded,
                          iconBg: AppColors.secondary,
                          label: 'Звукові ефекти',
                          value: true,
                          onChanged: (_) {},
                        ),
                        const Divider(height: 1, color: AppColors.borderDefault),
                        _SettingsToggleRow(
                          iconPath: Icons.vibration,
                          iconBg: AppColors.bossPurple,
                          label: 'Вібрація',
                          value: true,
                          onChanged: (_) {},
                        ),
                        const Divider(height: 1, color: AppColors.borderDefault),
                        _SettingsToggleRow(
                          iconPath: Icons.notifications,
                          iconBg: AppColors.bossRed,
                          label: 'Сповіщення',
                          value: false,
                          onChanged: (_) {},
                        ),
                        const Divider(height: 1, color: AppColors.borderDefault),
                        _SettingsToggleRow(
                          iconPath: Icons.dark_mode,
                          iconBg: const Color(0xFF333333),
                          label: 'Темна тема',
                          value: settings.isDark,
                          onChanged: (val) {
                            settings.setTheme(val ? AppThemeMode.dark : AppThemeMode.light);
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  const Text('АКАУНТ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  
                  // ACCOUNT CARD
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderDefault, width: 2),
                    ),
                    child: Column(
                      children: [
                        _SettingsTextRow(
                          iconPath: Icons.person,
                          label: "Ім'я",
                          value: 'Олена К.',
                        ),
                        const Divider(height: 1, color: AppColors.borderDefault),
                        _SettingsTextRow(
                          iconPath: Icons.email,
                          label: 'Пошта',
                          value: 'olena@mail.com',
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // EXIT LOGOUT BUTTON
                  GestureDetector(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: AppColors.bossRed,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.bossRedDark, width: 2),
                        boxShadow: const [BoxShadow(color: AppColors.bossRedDark, offset: Offset(0, 5), blurRadius: 0)],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.logout, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'ВИЙТИ',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final IconData iconPath;
  final Color iconBg;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleRow({
    required this.iconPath,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(iconPath, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          CupertinoSwitch(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsTextRow extends StatelessWidget {
  final IconData iconPath;
  final String label;
  final String value;
  const _SettingsTextRow({required this.iconPath, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(iconPath, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textHint, size: 12),
        ],
      ),
    );
  }
}
