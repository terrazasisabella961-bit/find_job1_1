import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

bool get isFlutterWidgetTest =>
    WidgetsBinding.instance.runtimeType.toString().contains('TestWidgets');

const cochabambaCenter = LatLng(-17.3935, -66.1570);

LatLng centerForCity(String city) {
  return switch (city.trim()) {
    'La Paz' || 'El Alto' => const LatLng(-16.5000, -68.1500),
    'Santa Cruz de la Sierra' => const LatLng(-17.7833, -63.1821),
    'Sucre' => const LatLng(-19.0333, -65.2627),
    'Oruro' => const LatLng(-17.9833, -67.1500),
    'Potosí' => const LatLng(-19.5836, -65.7531),
    'Tarija' => const LatLng(-21.5355, -64.7296),
    'Trinidad' => const LatLng(-14.8333, -64.9000),
    'Cobija' => const LatLng(-11.0267, -68.7692),
    'Cochabamba' => cochabambaCenter,
    _ => cochabambaCenter,
  };
}

double distanceKm({
  required double fromLat,
  required double fromLng,
  required double toLat,
  required double toLng,
}) {
  const earthKm = 6371.0;
  final dLat = _toRad(toLat - fromLat);
  final dLng = _toRad(toLng - fromLng);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(fromLat)) *
          math.cos(_toRad(toLat)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * earthKm * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

String formatDistanceKm(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
}

double _toRad(double degrees) => degrees * math.pi / 180;
