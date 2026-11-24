import 'package:flutter/material.dart';

const appPurpleColor = Color(0xFF8950F5);
const appOrangeColor = Color(0xFFFF7845);

const _darkBackground = Color(0xFF151226);
const _darkSurface = Color(0xFF1A172F);
const _darkBorder = Color(0xFF302B49);
const _darkMuted = Color(0xFFAAA6BE);
const _darkText = Color(0xFFFFFFFF);

const _lightBackground = Color(0xFFF4F1FA);
const _lightSurface = Color(0xFFFFFFFF);
const _lightBorder = Color(0xFFD9D3E8);
const _lightMuted = Color(0xFF6B6580);
const _lightText = Color(0xFF1A1528);

Color appBackgroundColor = _darkBackground;
Color appSurfaceColor = _darkSurface;
Color appBorderColor = _darkBorder;
Color appMutedColor = _darkMuted;
Color appTextColor = _darkText;

void applyDarkAppPalette() {
  appBackgroundColor = _darkBackground;
  appSurfaceColor = _darkSurface;
  appBorderColor = _darkBorder;
  appMutedColor = _darkMuted;
  appTextColor = _darkText;
}

void applyLightAppPalette() {
  appBackgroundColor = _lightBackground;
  appSurfaceColor = _lightSurface;
  appBorderColor = _lightBorder;
  appMutedColor = _lightMuted;
  appTextColor = _lightText;
}

class AppNavDestination {
  const AppNavDestination({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<AppNavDestination> items;

  static const studentItems = [
    AppNavDestination(label: 'Empleo', icon: Icons.menu),
    AppNavDestination(label: 'Cercanas', icon: Icons.place_outlined),
    AppNavDestination(label: 'Cursos', icon: Icons.school_outlined),
    AppNavDestination(label: 'Cuenta', icon: Icons.person_outline),
  ];

  static const companyItems = [
    AppNavDestination(label: 'Reclutar', icon: Icons.person_add_alt_1),
    AppNavDestination(label: 'Cuenta', icon: Icons.person_outline),
  ];

  static const institutionItems = [
    AppNavDestination(
      label: 'Instituciones',
      icon: Icons.account_balance_outlined,
    ),
    AppNavDestination(label: 'Cursos', icon: Icons.school_outlined),
    AppNavDestination(label: 'Cuenta', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: appSurfaceColor,
        border: Border(top: BorderSide(color: appBorderColor)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++)
            Expanded(
              child: _NavigationItem(
                label: items[index].label,
                icon: items[index].icon,
                selected: selectedIndex == index,
                onTap: () => onSelected(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
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
    final color = selected ? appPurpleColor : const Color(0xFF77748A);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 60;
        return Tooltip(
          message: label,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: isNarrow ? 15 : 17),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(color: color, fontSize: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> showSimulatedLegalDialog(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: appSurfaceColor,
        title: Text(
          title,
          style: TextStyle(
            color: appTextColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          body,
          style: TextStyle(
            color: appMutedColor,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Entendido'),
          ),
        ],
      );
    },
  );
}

const simulatedTermsBody =
    'Simulación: CochaConecta conecta empleo y formación en Cochabamba. '
    'Al registrarte aceptas usar datos verídicos y no publicar contenido ilegal. '
    'Este aviso es una vista previa; el documento legal final se publicará más adelante.';

const simulatedPrivacyBody =
    'Simulación: usamos tu correo y datos de perfil para crear tu cuenta y mostrarte ofertas. '
    'No vendemos tu información. Esta es una vista previa de la política de privacidad.';
