import 'package:flutter/material.dart';

const appBackgroundColor = Color(0xFF151226);
const appSurfaceColor = Color(0xFF1A172F);
const appBorderColor = Color(0xFF302B49);
const appMutedColor = Color(0xFFAAA6BE);
const appPurpleColor = Color(0xFF8950F5);
const appOrangeColor = Color(0xFFFF7845);

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (label: 'Empleo', icon: Icons.menu),
    (label: 'Reclutar', icon: Icons.person_add_alt_1),
    (label: 'Instituciones', icon: Icons.account_balance_outlined),
    (label: 'Cuenta', icon: Icons.person_outline),
    (label: 'Cursos', icon: Icons.school_outlined),
    (label: 'Extras', icon: Icons.info_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: appSurfaceColor,
        border: Border(top: BorderSide(color: appBorderColor)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < _items.length; index++)
            Expanded(
              child: _NavigationItem(
                label: _items[index].label,
                icon: _items[index].icon,
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          body,
          style: const TextStyle(
            color: appMutedColor,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendido'),
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
