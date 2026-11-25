import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_bottom_navigation.dart';

const simulatedCvAssetPath = 'assets/docs/cv_simulado.pdf';
const simulatedCvWebFile = 'cv_simulado.pdf';
const simulatedCvDisplayName =
    'CV_ficticio_Ingeniero_Ambiental_CochaConecta.pdf';

Future<bool> openSimulatedCvDocument() async {
  try {
    final uri = kIsWeb
        ? Uri.base.resolve(simulatedCvWebFile)
        : Uri.parse('assets/$simulatedCvAssetPath');
    return launchUrl(uri, mode: LaunchMode.platformDefault);
  } on Exception {
    return false;
  }
}

Future<void> showSimulatedCvScreen(
  BuildContext context, {
  required String heading,
  required String detail,
  bool openDocument = true,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => SimulatedCvScreen(
        heading: heading,
        detail: detail,
        openDocument: openDocument,
      ),
    ),
  );
}

class SimulatedCvScreen extends StatefulWidget {
  const SimulatedCvScreen({
    required this.heading,
    required this.detail,
    this.openDocument = true,
    super.key,
  });

  final String heading;
  final String detail;
  final bool openDocument;

  @override
  State<SimulatedCvScreen> createState() => _SimulatedCvScreenState();
}

class _SimulatedCvScreenState extends State<SimulatedCvScreen> {
  var _opened = false;

  @override
  void initState() {
    super.initState();
    if (widget.openDocument) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open());
    }
  }

  Future<void> _open() async {
    final opened = await openSimulatedCvDocument();
    if (mounted) setState(() => _opened = opened);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Volver',
                    icon: Icon(Icons.arrow_back),
                    color: appTextColor,
                    style: IconButton.styleFrom(
                      backgroundColor: appSurfaceColor,
                      side: BorderSide(color: appBorderColor),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'CURRÍCULUM SIMULADO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFB48BF1),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 24),
              Icon(
                Icons.picture_as_pdf,
                color: appOrangeColor,
                size: 72,
              ),
              const SizedBox(height: 16),
              Text(
                widget.heading,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: appTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.detail,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: appMutedColor,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: appSurfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: appBorderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      simulatedCvDisplayName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: appTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Ingeniero Ambiental · Cochabamba (CV de demostración)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: appMutedColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _open,
                icon: Icon(Icons.open_in_new),
                label: Text(_opened ? 'Abrir CV de nuevo' : 'Abrir CV'),
                style: FilledButton.styleFrom(
                  backgroundColor: appOrangeColor,
                  foregroundColor: const Color(0xFF171323),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
