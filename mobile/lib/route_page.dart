import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'spot.dart';
import 'ui/motion.dart';
import 'ui/spot_icons.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

Future<void> openRoute(BuildContext context, Spot spot) => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => RoutePage(spot: spot)),
);

enum Travel {
  motor('Motor', 'driving', 1.0),
  mobil('Mobil', 'driving', 1.25),
  jalan('Jalan', 'foot', 1.0);

  const Travel(this.label, this.profile, this.slowdown);
  final String label, profile;

  /// Motor lebih gesit di kota; mobil sedikit lebih lama.
  final double slowdown;
}

class RoutePage extends StatefulWidget {
  const RoutePage({super.key, required this.spot});
  final Spot spot;
  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  final map = MapController();
  Travel travel = Travel.motor;
  LatLng? from;
  List<LatLng> path = [];
  double? meters, seconds;
  String? error;
  bool loading = true;

  LatLng get to => LatLng(widget.spot.lat, widget.spot.lng);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (from == null) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw 'Izinkan lokasi dulu supaya rutenya bisa dihitung.';
        }
        final p = await Geolocator.getCurrentPosition();
        from = LatLng(p.latitude, p.longitude);
      }
      final a = from!;
      final profile = travel.profile;
      final host = profile == 'foot'
          ? 'routing.openstreetmap.de/routed-foot'
          : 'router.project-osrm.org';
      final url = Uri.parse(
        'https://$host/route/v1/$profile/'
        '${a.longitude},${a.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw 'Rute belum bisa dihitung.';
      final routes = (jsonDecode(res.body) as Map)['routes'] as List? ?? [];
      if (routes.isEmpty) throw 'Tidak ada jalan ke sana dari sini.';
      final r = routes.first as Map;
      final coords = (r['geometry'] as Map)['coordinates'] as List;
      if (!mounted) return;
      setState(() {
        path = [
          for (final c in coords)
            LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
        ];
        meters = (r['distance'] as num).toDouble();
        seconds = (r['duration'] as num).toDouble() * travel.slowdown;
      });
      fit();
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              error = e is String ? e : 'Rute belum bisa dihitung. Coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void fit() {
    final points = [...path, to, ?from];
    if (points.length < 2) return;
    map.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.fromLTRB(40, 120, 40, 240),
      ),
    );
  }

  String get distanceText {
    final m = meters ?? 0;
    return m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';
  }

  String get durationText {
    final min = math.max(1, ((seconds ?? 0) / 60).round());
    if (min < 60) return '$min mnt';
    return '${min ~/ 60} j ${min % 60} mnt';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: map,
            options: MapOptions(initialCenter: to, initialZoom: 14),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.spots.app',
              ),
              if (path.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(points: path, strokeWidth: 9, color: Colors.white),
                    Polyline(
                      points: path,
                      strokeWidth: 5.5,
                      color: blue,
                      pattern: travel == Travel.jalan
                          ? StrokePattern.dotted(spacingFactor: 1.6)
                          : const StrokePattern.solid(),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (from != null)
                    Marker(
                      point: from!,
                      width: 26,
                      height: 26,
                      child: Container(
                        decoration: BoxDecoration(
                          color: blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: blue.withValues(alpha: .35),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Marker(
                    point: to,
                    width: 46,
                    height: 52,
                    alignment: Alignment.topCenter,
                    child: SpotIcon(
                      Glyph.pin,
                      size: 46,
                      color: coral,
                      accent: Colors.white,
                    ),
                  ),
                ],
              ),
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors · OSRM'),
                ],
              ),
            ],
          ),
          Positioned(
            top: top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                GlassButton(
                  glyph: Glyph.back,
                  label: 'Kembali',
                  onTap: () => Navigator.maybePop(context),
                ),
                const Spacer(),
                GlassButton(glyph: Glyph.locate, label: 'Pas-kan', onTap: fit),
              ],
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _panel(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel() => Container(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: line, width: 2),
      boxShadow: [
        BoxShadow(
          color: ink.withValues(alpha: .16),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.spot.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: title.copyWith(fontSize: 17),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: loading
              ? const Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.6),
                  ),
                )
              : error != null
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text(error!, style: small),
                )
              : Row(
                  children: [
                    Text(durationText, style: display(26)),
                    const SizedBox(width: 10),
                    Text(distanceText, style: small.copyWith(fontSize: 14)),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final t in Travel.values) ...[
              Expanded(
                child: Bouncy(
                  onTap: () {
                    if (t == travel) return;
                    final sameRoad =
                        t.profile == travel.profile && path.isNotEmpty;
                    final before = travel;
                    setState(() => travel = t);
                    if (sameRoad && seconds != null) {
                      setState(
                        () => seconds = seconds! / before.slowdown * t.slowdown,
                      );
                    } else {
                      load();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t == travel ? blue : pale,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      t.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: t == travel ? Colors.white : ink,
                      ),
                    ),
                  ),
                ),
              ),
              if (t != Travel.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Chunky(
            onTap: load,
            color: blue,
            expand: true,
            label: 'Coba lagi',
            child: const Text('Coba lagi'),
          ),
        ],
      ],
    ),
  );
}
