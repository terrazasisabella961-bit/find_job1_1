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
