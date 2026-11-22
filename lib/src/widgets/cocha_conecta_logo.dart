import 'package:flutter/material.dart';

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
