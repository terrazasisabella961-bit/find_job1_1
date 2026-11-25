import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../geo/map_defaults.dart';
import 'app_bottom_navigation.dart';
import 'form_field_label.dart';

class LocationPickerMap extends StatelessWidget {
  const LocationPickerMap({
    required this.point,
    required this.onChanged,
    this.label = 'Ubicación en el mapa',
    this.required = false,
    this.hint = 'Toca el mapa para mover el pin.',
    super.key,
  });

  final LatLng? point;
  final ValueChanged<LatLng> onChanged;
  final String label;
  final bool required;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final marker = point ?? cochabambaCenter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(label, required: required),
        Text(
          hint,
          style: TextStyle(color: appMutedColor, fontSize: 12),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: isFlutterWidgetTest ? 80 : 220,
            child: isFlutterWidgetTest
                ? ColoredBox(
                    color: appSurfaceColor,
                    child: Center(
                      child: Text(
                        '${marker.latitude.toStringAsFixed(4)}, ${marker.longitude.toStringAsFixed(4)}',
                        style: TextStyle(color: appMutedColor, fontSize: 12),
                      ),
                    ),
                  )
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: marker,
                      initialZoom: 13,
                      onTap: (_, latLng) => onChanged(latLng),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.find_job1_1',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: marker,
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.location_on,
                              color: appOrangeColor,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
