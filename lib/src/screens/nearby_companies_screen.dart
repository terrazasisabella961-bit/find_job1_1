import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../geo/map_defaults.dart';
import '../models/company.dart';
import '../models/user_profile.dart';
import '../services/job_application_repository.dart';
import '../services/recruitment_repository.dart';
import '../widgets/app_bottom_navigation.dart';
import 'company_public_screen.dart';

class NearbyCompaniesScreen extends StatefulWidget {
  const NearbyCompaniesScreen({
    required this.repository,
    this.profile,
    this.applicationRepository,
    super.key,
  });

  final RecruitmentRepository repository;
  final UserProfile? profile;
  final JobApplicationRepository? applicationRepository;

  @override
  State<NearbyCompaniesScreen> createState() => _NearbyCompaniesScreenState();
}

class _NearbyCompaniesScreenState extends State<NearbyCompaniesScreen> {
  final _mapController = MapController();
  LatLng _origin = cochabambaCenter;
  var _usingGps = false;
  String? _gpsError;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    if (profile != null && profile.hasCoordinates) {
      _origin = LatLng(profile.latitude!, profile.longitude!);
    } else if (profile != null && profile.city.trim().isNotEmpty) {
      _origin = centerForCity(profile.city);
    }
  }

  Future<void> _useGps() async {
    setState(() {
      _usingGps = true;
      _gpsError = null;
    });
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw StateError('Activa el GPS o la ubicación del navegador.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('No hay permiso para usar tu ubicación.');
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _origin = LatLng(position.latitude, position.longitude);
        _usingGps = false;
      });
      if (!isFlutterWidgetTest) {
        _mapController.move(_origin, 13);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _usingGps = false;
        _gpsError = error is StateError
            ? error.message
            : 'No se pudo leer tu ubicación.';
      });
    }
  }

  void _openCompany(Company company, String distanceLabel) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CompanyPublicScreen(
          company: company,
          repository: widget.repository,
          distanceLabel: distanceLabel,
          applicationRepository: widget.applicationRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Company>>(
      stream: widget.repository.watchLocatedCompanies(),
      builder: (context, snapshot) {
        final located = (snapshot.data ?? const <Company>[])
            .where((company) => company.hasCoordinates)
            .toList();
        located.sort((a, b) {
          final da = distanceKm(
            fromLat: _origin.latitude,
            fromLng: _origin.longitude,
            toLat: a.latitude!,
            toLng: a.longitude!,
          );
          final db = distanceKm(
            fromLat: _origin.latitude,
            fromLng: _origin.longitude,
            toLat: b.latitude!,
            toLng: b.longitude!,
          );
          return da.compareTo(db);
        });
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            Text(
              'EMPRESAS CERCANAS',
              style: TextStyle(
                color: Color(0xFFB48BF1),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Prende tu ubicación para ordenar las empresas por distancia y ver su ficha, rubro y vacantes.',
              style: TextStyle(color: appMutedColor, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _usingGps ? null : _useGps,
              icon: _usingGps
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.my_location),
              label: Text(
                _usingGps ? 'Obteniendo ubicación...' : 'Usar mi ubicación',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: appOrangeColor,
                foregroundColor: Colors.white,
              ),
            ),
            if (_gpsError != null) ...[
              const SizedBox(height: 8),
              Text(
                _gpsError!,
                style: TextStyle(color: Color(0xFFFF8A9B), fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 220,
                child: isFlutterWidgetTest
                    ? ColoredBox(
                        color: appSurfaceColor,
                        child: Center(
                          child: Text(
                            'Mapa de empresas cercanas',
                            style: TextStyle(color: appMutedColor),
                          ),
                        ),
                      )
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _origin,
                          initialZoom: 13,
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
                                point: _origin,
                                width: 36,
                                height: 36,
                                child: Icon(
                                  Icons.person_pin_circle,
                                  color: appPurpleColor,
                                  size: 36,
                                ),
                              ),
                              for (final company in located)
                                Marker(
                                  point: LatLng(
                                    company.latitude!,
                                    company.longitude!,
                                  ),
                                  width: 36,
                                  height: 36,
                                  child: GestureDetector(
                                    onTap: () {
                                      final km = distanceKm(
                                        fromLat: _origin.latitude,
                                        fromLng: _origin.longitude,
                                        toLat: company.latitude!,
                                        toLng: company.longitude!,
                                      );
                                      _openCompany(
                                        company,
                                        'A ${formatDistanceKm(km)}',
                                      );
                                    },
                                    child: Icon(
                                      Icons.location_on,
                                      color: appOrangeColor,
                                      size: 34,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            if (located.isEmpty)
              Text(
                'Aún no hay empresas con ubicación publicada.',
                style: TextStyle(color: appMutedColor),
              )
            else
              for (final company in located)
                _NearbyCompanyCard(
                  company: company,
                  distanceKm: distanceKm(
                    fromLat: _origin.latitude,
                    fromLng: _origin.longitude,
                    toLat: company.latitude!,
                    toLng: company.longitude!,
                  ),
                  onTap: () {
                    final km = distanceKm(
                      fromLat: _origin.latitude,
                      fromLng: _origin.longitude,
                      toLat: company.latitude!,
                      toLng: company.longitude!,
                    );
                    _openCompany(company, 'A ${formatDistanceKm(km)}');
                  },
                ),
          ],
        );
      },
    );
  }
}

class _NearbyCompanyCard extends StatelessWidget {
  const _NearbyCompanyCard({
    required this.company,
    required this.distanceKm,
    required this.onTap,
  });

  final Company company;
  final double distanceKm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: appSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: appBorderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        company.name,
                        style: TextStyle(
                          color: appTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      formatDistanceKm(distanceKm),
                      style: TextStyle(
                        color: appOrangeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  company.sector,
                  style: TextStyle(color: appPurpleColor, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${company.city}${company.address.isEmpty ? '' : ' · ${company.address}'}',
                  style: TextStyle(color: appMutedColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
