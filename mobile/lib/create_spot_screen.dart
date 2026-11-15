import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' hide Path;

import 'spot_views.dart';
import 'spots_repository.dart';
import 'ui/motion.dart';
import 'ui/piko.dart';
import 'ui/spot_icons.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class CreateSpotScreen extends StatefulWidget {
  const CreateSpotScreen({super.key, required this.repo, this.position});
  final SpotsRepository repo;
  final Position? position;
  @override
  State<CreateSpotScreen> createState() => _CreateSpotScreenState();
}

class _CreateSpotScreenState extends State<CreateSpotScreen> {
  final title = TextEditingController();
  final city = TextEditingController();
  final story = TextEditingController();
  final map = MapController();
  final picker = ImagePicker();
  final files = <XFile>[];
  final previews = <XFile, Future<Uint8List>>{};
  late LatLng? point = widget.position == null
      ? null
      : LatLng(widget.position!.latitude, widget.position!.longitude);
  String category = 'kuliner';
  bool busy = false, locating = false;
  String? error;

  @override
  void dispose() {
    title.dispose();
    city.dispose();
    story.dispose();
    map.dispose();
    super.dispose();
  }

  static bool isVideo(XFile file) =>
      RegExp(r'\.(mp4|mov|webm)$').hasMatch(file.name.toLowerCase());

  void add(Iterable<XFile> picked) => setState(() {
    for (final file in picked.take(5 - files.length)) {
      files.add(file);
      if (!isVideo(file)) previews[file] = file.readAsBytes();
    }
    error = null;
  });

  Future<void> pick(String choice) async {
    Navigator.pop(context);
    try {
      switch (choice) {
        case 'gallery':
          add(await picker.pickMultiImage(imageQuality: 85));
        case 'camera':
          final file = await picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 85,
          );
          if (file != null) add([file]);
        default:
          final file = await picker.pickVideo(
            source: choice == 'video'
                ? ImageSource.gallery
                : ImageSource.camera,
            maxDuration: const Duration(seconds: 90),
          );
          if (file != null) add([file]);
      }
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    }
  }

  void chooseSource() => showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _Source('Galeri', Glyph.gallery, grape, () => pick('gallery')),
            _Source('Kamera', Glyph.camera, coral, () => pick('camera')),
            _Source('Video', Glyph.video, caramel, () => pick('video')),
            _Source('Rekam', Glyph.record, mint, () => pick('record')),
          ],
        ),
      ),
    ),
  );

  Future<void> useGps() async {
    setState(() => locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('GPS-nya nyalain dulu.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Izin lokasi belum diberikan.');
      }
      final p = await Geolocator.getCurrentPosition();
      final found = LatLng(p.latitude, p.longitude);
      setState(() {
        point = found;
        error = null;
      });
      map.move(found, 16);
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  String? missing() {
    if (files.isEmpty) return 'Tambah minimal satu foto atau video.';
    if (title.text.trim().length < 3) return 'Nama tempat minimal 3 huruf.';
    if (city.text.trim().length < 2) return 'Kotanya di mana?';
    if (story.text.trim().length < 5) {
      return 'Ceritain sedikit, minimal 5 huruf.';
    }
    if (point == null) return 'Tandai titik lokasinya di peta.';
    return null;
  }

  Future<void> submit() async {
    final problem = missing();
    if (problem != null) {
      setState(() => error = problem);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repo.createSpot(
        title: title.text,
        city: city.text,
        category: category,
        story: story.text,
        lat: point!.latitude,
        lng: point!.longitude,
        files: files,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        PageRouteBuilder<void>(
          opaque: false,
          pageBuilder: (_, _, _) => const _Celebrate(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            children: [
              Row(
                children: [
                  GlassButton(
                    glyph: Glyph.close,
                    label: 'Tutup',
                    onTap: () => Navigator.maybePop(context),
                  ),
                  const Spacer(),
                  Text('${files.length}/5', style: small),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Text('Spot\nbaru!', style: display(40))),
                  const Piko(size: 80, mood: PikoMood.wow),
                ],
              ),
              const SizedBox(height: 22),
              _media(),
              const SizedBox(height: 22),
              TextField(
                controller: title,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
                decoration: const InputDecoration(
                  hintText: 'Nama tempatnya',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: city,
                maxLength: 70,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Kota',
                  counterText: '',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: SpotIcon(Glyph.pin, size: 22, accent: coral),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              CategoryRow(
                selected: category,
                includeAll: false,
                padding: EdgeInsets.zero,
                onSelected: (value) =>
                    setState(() => category = value ?? 'kuliner'),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: story,
                maxLength: 2000,
                minLines: 3,
                maxLines: 7,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Kenapa orang wajib ke sini?',
                ),
              ),
              const SizedBox(height: 14),
              _location(),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                child: error == null
                    ? const SizedBox(width: double.infinity)
                    : Notice(error!),
              ),
              const SizedBox(height: 18),
              Chunky(
                expand: true,
                color: coral,
                onTap: busy ? null : submit,
                child: Text(busy ? 'Lagi diunggah…' : 'Bagikan spot'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _media() => SizedBox(
    height: 118,
    child: ListView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      children: [
        if (files.length < 5)
          Bouncy(
            onTap: chooseSource,
            child: Semantics(
              button: true,
              label: 'Tambah foto atau video',
              child: CustomPaint(
                painter: _DashedBox(),
                child: Container(
                  width: 110,
                  height: 110,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F2FF),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SpotIcon(Glyph.plus, size: 34, color: grape),
                      SizedBox(height: 4),
                      Text(
                        'Tambah',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: grape,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        for (final (i, file) in files.indexed)
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Rise(
              key: ValueKey(file),
              from: 14,
              child: _Thumb(
                file: file,
                bytes: previews[file],
                tilt: i.isEven ? -.03 : .03,
                onRemove: () => setState(() {
                  files.remove(file);
                  previews.remove(file);
                }),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _location() {
    final center = point ?? const LatLng(-6.2088, 106.8456);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: line, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: map,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: point == null ? 11 : 16,
                    onTap: (_, latLng) => setState(() {
                      point = latLng;
                      error = null;
                    }),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.spots.app',
                    ),
                    if (point != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: point!,
                            width: 44,
                            height: 52,
                            alignment: Alignment.topCenter,
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey(point),
                              tween: Tween(begin: -30, end: 0),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.bounceOut,
                              builder: (_, dy, child) => Transform.translate(
                                offset: Offset(0, dy),
                                child: child,
                              ),
                              child: SpotIcon(
                                Glyph.pin,
                                size: 44,
                                color: ink,
                                accent: categoryOf(category).color,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (point == null)
                  const Positioned(
                    left: 12,
                    top: 12,
                    child: Pill(child: Text('Ketuk peta buat pasang pin')),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    point == null
                        ? 'Belum ada titik'
                        : '${point!.latitude.toStringAsFixed(5)}, ${point!.longitude.toStringAsFixed(5)}',
                    style: small,
                  ),
                ),
                Chunky(
                  onTap: locating ? null : useGps,
                  color: piko,
                  depth: 4,
                  radius: 16,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SpotIcon(
                        Glyph.locate,
                        size: 18,
                        color: Colors.white,
                        tint: false,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        locating ? 'Mencari…' : 'Lokasiku',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Source extends StatelessWidget {
  const _Source(this.label, this.glyph, this.color, this.onTap);
  final String label;
  final Glyph glyph;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Chunky(
    onTap: onTap,
    color: color,
    radius: 24,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpotIcon(glyph, size: 32, color: Colors.white, accent: edgeOf(color)),
        const SizedBox(height: 6),
        Text(label),
      ],
    ),
  );
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.file,
    required this.bytes,
    required this.tilt,
    required this.onRemove,
  });
  final XFile file;
  final Future<Uint8List>? bytes;
  final double tilt;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: tilt,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 106,
          height: 106,
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: line, offset: Offset(0, 4))],
          ),
          clipBehavior: Clip.antiAlias,
          child: bytes == null
              ? const Center(
                  child: SpotIcon(
                    Glyph.play,
                    size: 34,
                    color: Colors.white,
                    accent: coral,
                  ),
                )
              : FutureBuilder<Uint8List>(
                  future: bytes,
                  builder: (context, snapshot) => snapshot.hasData
                      ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                      : const Shimmer(child: Bone(height: 106)),
                ),
        ),
        Positioned(
          right: -6,
          top: -6,
          child: Bouncy(
            onTap: onRemove,
            child: Semantics(
              button: true,
              label: 'Hapus ${file.name}',
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: ink, width: 2),
                ),
                child: const SpotIcon(Glyph.close, size: 14, tint: false),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DashedBox extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = grape.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(26)),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 14) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBox old) => false;
}

class _Celebrate extends StatefulWidget {
  const _Celebrate();
  @override
  State<_Celebrate> createState() => _CelebrateState();
}

class _CelebrateState extends State<_Celebrate> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) Navigator.maybePop(context);
    });
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.maybePop(context),
    child: Material(
      color: piko,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: const Piko(size: 170, mood: PikoMood.wow),
                ),
                const SizedBox(height: 22),
                Rise(
                  index: 3,
                  child: Text(
                    'Spot kamu\ntayang!',
                    textAlign: TextAlign.center,
                    style: display(40, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const Positioned.fill(child: Confetti()),
        ],
      ),
    ),
  );
}
