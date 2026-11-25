import 'package:flutter/material.dart';

import '../theme/app_theme_settings.dart';
import 'app_bottom_navigation.dart';

class AppearanceSettingsCard extends StatelessWidget {
  const AppearanceSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeSettings.instance,
      builder: (context, _) {
        final isDark = AppThemeSettings.instance.isDark;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: appSurfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: appBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'APARIENCIA',
                style: TextStyle(
                  color: Color(0xFFB48BF1),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Elegí modo noche o modo claro. Se guarda en este dispositivo.',
                style: TextStyle(color: appMutedColor, fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      label: 'Noche',
                      icon: Icons.dark_mode_outlined,
                      selected: isDark,
                      onTap: () => AppThemeSettings.instance.setDark(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModeButton(
                      label: 'Claro',
                      icon: Icons.light_mode_outlined,
                      selected: !isDark,
                      onTap: () => AppThemeSettings.instance.setDark(false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? appPurpleColor : appBackgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : appMutedColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : appTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
