import 'package:flutter/material.dart';

import 'app_bottom_navigation.dart';

class CochaConectaLogo extends StatelessWidget {
  const CochaConectaLogo({
    this.height = 96,
    super.key,
  });

  static const assetPath = 'assets/branding/cochaconecta_logo.jpg';

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class HoverScale extends StatefulWidget {
  const HoverScale({
    required this.child,
    this.scale = 1.03,
    super.key,
  });

  final Widget child;
  final double scale;

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  var _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? widget.scale : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class DevelopedByCredit extends StatelessWidget {
  const DevelopedByCredit({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Text.rich(
        const TextSpan(
          children: [
            TextSpan(text: 'Desarrollado por: '),
            TextSpan(
              text: '3π +2',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: appMutedColor,
          fontSize: 12,
          height: 1.3,
        ),
      ),
    );
  }
}
