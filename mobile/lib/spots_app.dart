import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'create_spot_screen.dart';
import 'demo_repository.dart';
import 'spot.dart';
import 'spot_views.dart';
import 'spots_repository.dart';
import 'ui/motion.dart';
import 'ui/piko.dart';
import 'ui/spot_icons.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class SpotsApp extends StatefulWidget {
  const SpotsApp({super.key, required this.configured, this.demo = false});
  final bool configured, demo;

  @override
  State<SpotsApp> createState() => _SpotsAppState();
}

class _SpotsAppState extends State<SpotsApp> {
  late SpotsRepository? repo = widget.demo
      ? DemoSpotsRepository()
      : widget.configured
      ? SpotsRepository(Supabase.instance.client)
      : null;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Spots',
    debugShowCheckedModeBanner: false,
    theme: spotsTheme(),
    home: repo == null
        ? SetupScreen(
            onDemo: () => setState(() => repo = DemoSpotsRepository()),
          )
        : SpotsShell(repo: repo!),
  );
}

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key, required this.onDemo});
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                SvgPicture.asset('assets/logo.svg', width: 170),
                const SizedBox(height: 26),
                const Piko(size: 150),
                const SizedBox(height: 22),
                Text(
                  'Tempat seru\nlagi nunggu.',
                  textAlign: TextAlign.center,
                  style: display(36),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sambungkan Supabase lewat config.json, atau intip dulu pakai data contoh.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 26),
                Chunky(
                  expand: true,
                  color: coral,
                  onTap: onDemo,
                  child: const Text('Coba mode demo'),
                ),
                const SizedBox(height: 18),
                const SelectableText(
                  'flutter run --dart-define-from-file=config.json',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Tab {
  const _Tab(this.label, this.glyph, this.color);
  final String label;
  final Glyph glyph;
  final Color color;
}

const _tabs = [
  _Tab('Beranda', Glyph.home, coral),
  _Tab('Jelajah', Glyph.compass, caramel),
  _Tab('Peta', Glyph.map, mint),
  _Tab('Profil', Glyph.face, grape),
];

class SpotsShell extends StatefulWidget {
  const SpotsShell({super.key, required this.repo});
  final SpotsRepository repo;
  @override
  State<SpotsShell> createState() => _SpotsShellState();
}

class _SpotsShellState extends State<SpotsShell> {
  SpotsRepository get repo => widget.repo;
  final mapController = MapController();
  final carousel = PageController(viewportFraction: .84);
  final search = TextEditingController();
  List<Spot> spots = [], mine = [], saved = [];
  Position? position;
  int tab = 0, focused = 0;
  bool showSaved = false;
  String? category;
  bool loading = true, locating = false, locationDenied = false;
  String? error;
  StreamSubscription<void>? authSubscription;
  Timer? debounce;
  int request = 0;

  @override
  void initState() {
    super.initState();
    authSubscription = repo.authChanges.listen((_) {
      if (mounted) refresh(silent: true);
    });
    locate();
  }

  @override
  void dispose() {
    authSubscription?.cancel();
    debounce?.cancel();
    search.dispose();
    carousel.dispose();
    mapController.dispose();
    super.dispose();
  }

  Future<void> locate() async {
    setState(() => locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('GPS tidak aktif.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Izin lokasi belum diberikan.');
      }
      final found = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      setState(() {
        position = found;
        locationDenied = false;
      });
      if (tab == 2) {
        mapController.move(LatLng(found.latitude, found.longitude), 12);
      }
    } catch (_) {
      if (mounted) setState(() => locationDenied = true);
    } finally {
      if (mounted) setState(() => locating = false);
    }
    await refresh();
  }

  Future<void> refresh({bool silent = false}) async {
    if (!mounted) return;
    final ticket = ++request;
    setState(() {
      if (!silent) loading = true;
      error = null;
    });
    try {
      if (tab == 3) {
        if (repo.userId == null) {
          mine = [];
          saved = [];
        } else {
          final results = await Future.wait([
            repo.feed(mode: 'mine'),
            repo.feed(mode: 'saved'),
          ]);
          if (ticket != request || !mounted) return;
          setState(() {
            mine = results[0];
            saved = results[1];
          });
        }
      } else {
        final near = tab != 1 && position != null;
        final found = await repo.feed(
          lat: position?.latitude,
          lng: position?.longitude,
          mode: near ? 'near' : 'popular',
          category: category,
          query: tab == 1 ? search.text.trim() : null,
        );
        if (ticket != request || !mounted) return;
        setState(() {
          spots = found;
          focused = 0;
        });
      }
    } catch (e) {
      if (ticket == request && mounted) {
        setState(() => error = friendlyError(e));
      }
    } finally {
      if (ticket == request && mounted) setState(() => loading = false);
    }
  }

  void chooseTab(int index) {
    if (index == tab) return;
    HapticFeedback.selectionClick();
    setState(() {
      tab = index;
      category = null;
      search.clear();
      spots = index == 0 || index == 2 ? spots : [];
    });
    refresh();
  }

  void chooseCategory(String? value) {
    setState(() => category = value);
    refresh();
  }

  Future<void> create() async {
    if (repo.userId == null) {
      await openAuth(context, repo);
      if (repo.userId == null || !mounted) return;
    }
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CreateSpotScreen(repo: repo, position: position),
      ),
    );
    if (created == true && mounted) {
      setState(() {
        tab = 3;
        showSaved = false;
      });
      refresh();
    }
  }

  void open(Spot spot) =>
      openSpot(context, spot, repo, () => refresh(silent: true));

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    final page = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, .02),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(tab), child: _content(wide)),
    );
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _SideRail(tab: tab, onTab: chooseTab, onCreate: create),
            Expanded(child: page),
          ],
        ),
      );
    }
    return Scaffold(
      extendBody: true,
      body: page,
      bottomNavigationBar: _FloatingNav(
        tab: tab,
        onTab: chooseTab,
        onCreate: create,
      ),
    );
  }

  Widget _content(bool wide) => switch (tab) {
    2 => _map(wide),
    3 => _profile(wide),
    _ => _feed(wide),
  };

  // ---------- Beranda & Jelajah ----------

  Widget _feed(bool wide) {
    final explore = tab == 1;
    final top = MediaQuery.paddingOf(context).top;
    return RefreshIndicator(
      color: piko,
      onRefresh: refresh,
      edgeOffset: top,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: top + 8),
                    if (!wide) _topBar(),
                    if (explore) _exploreHeader() else _hero(),
                    const SizedBox(height: 18),
                    CategoryRow(selected: category, onSelected: chooseCategory),
                    SectionTitle(
                      explore
                          ? (search.text.isEmpty ? 'Lagi rame' : 'Hasil cari')
                          : position != null
                          ? 'Dekat kamu'
                          : 'Lagi rame',
                      trailing: loading
                          ? null
                          : Pill(
                              color: const Color(0xFFEDF1FF),
                              child: Text('${spots.length} spot'),
                            ),
                    ),
                    if (error != null) Notice(error!, onRetry: refresh),
                  ],
                ),
              ),
            ),
          ),
          if (loading)
            SliverToBoxAdapter(child: _skeleton(wide))
          else if (error == null && spots.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: explore
                    ? 'Belum ketemu.\nCoba kata lain?'
                    : 'Sekitar sini\nmasih sepi.',
                action: explore ? null : 'Jadi yang pertama',
                onAction: create,
                mood: explore ? PikoMood.wow : PikoMood.sleepy,
                color: coral,
              ),
            )
          else
            SliverToBoxAdapter(child: _cards(spots, wide)),
          const SliverToBoxAdapter(child: SizedBox(height: 130)),
        ],
      ),
    );
  }

  Widget _cards(List<Spot> items, bool wide) {
    Widget card(int i) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Rise(
        index: i,
        child: SpotCard(
          key: ValueKey(items[i].id),
          spot: items[i],
          repo: repo,
          onChanged: () => refresh(silent: true),
          onOpen: () => open(items[i]),
        ),
      ),
    );
    final columns = wide && MediaQuery.sizeOf(context).width >= 1180 ? 2 : 1;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: columns == 2 ? 1100 : 560),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      for (var i = c; i < items.length; i += columns) card(i),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeleton(bool wide) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Shimmer(
          child: Column(
            children: List.generate(
              2,
              (_) => Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Bone(height: 330, radius: 25),
                    SizedBox(height: 14),
                    Bone(width: 220, height: 20),
                    SizedBox(height: 10),
                    Bone(width: 140, height: 14),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _topBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 14, 10),
    child: Row(
      children: [
        SvgPicture.asset('assets/logo.svg', height: 36),
        const Spacer(),
        _LocationChip(active: position != null, busy: locating, onTap: locate),
      ],
    ),
  );

  Widget _hero() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Rise(
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [piko, Color(0xFF6E5BF0)],
          ),
          boxShadow: const [
            BoxShadow(color: Color(0xFF2B3FA8), offset: Offset(0, 6)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const Positioned(
              right: 128,
              top: 18,
              child: _Twinkle(size: 22, color: yellow),
            ),
            const Positioned(
              right: 24,
              top: 26,
              child: _Twinkle(size: 14, color: coral, delay: .4),
            ),
            const Positioned(
              left: 150,
              bottom: 22,
              child: _Twinkle(size: 12, color: Colors.white, delay: .7),
            ),
            Positioned(
              right: -6,
              bottom: -28,
              child: Transform.rotate(
                angle: -.12,
                child: const Piko(size: 150, mood: PikoMood.happy),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 140, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mau ke mana\nhari ini?',
                    style: display(30, color: Colors.white, height: 1.05),
                  ),
                  Bouncy(
                    onTap: () => chooseTab(1),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 9, 16, 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF2B3FA8),
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SpotIcon(Glyph.compass, size: 20, accent: yellow),
                          SizedBox(width: 6),
                          Text(
                            'Jelajah',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _exploreHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Rise(child: Text('Jelajah', style: display(40))),
        const SizedBox(height: 14),
        Rise(
          index: 1,
          child: TextField(
            controller: search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => refresh(),
            onChanged: (_) {
              debounce?.cancel();
              debounce = Timer(const Duration(milliseconds: 450), refresh);
            },
            style: const TextStyle(fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              hintText: 'Cari tempat atau kota',
              fillColor: Colors.white,
              prefixIcon: const Padding(
                padding: EdgeInsets.all(13),
                child: SpotIcon(Glyph.search, size: 22, accent: yellow),
              ),
              suffixIcon: ListenableBuilder(
                listenable: search,
                builder: (context, _) => search.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: 'Hapus',
                        onPressed: () {
                          search.clear();
                          refresh();
                        },
                        icon: const SpotIcon(
                          Glyph.close,
                          size: 18,
                          tint: false,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // ---------- Peta ----------

  Widget _map(bool wide) {
    final here = position == null
        ? null
        : LatLng(position!.latitude, position!.longitude);
    final center =
        here ??
        (spots.isNotEmpty
            ? LatLng(spots.first.lat, spots.first.lng)
            : const LatLng(-6.2088, 106.8456));
    final bottomInset = wide ? 24.0 : 112.0;
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(initialCenter: center, initialZoom: 12),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.spots.app',
            ),
            if (here != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: here,
                    radius: 20000,
                    useRadiusInMeter: true,
                    color: piko.withValues(alpha: .06),
                    borderColor: piko.withValues(alpha: .3),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            if (here != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: here,
                    width: 60,
                    height: 60,
                    child: const _MeDot(),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final (i, spot) in spots.indexed)
                  Marker(
                    point: LatLng(spot.lat, spot.lng),
                    width: 60,
                    height: 66,
                    alignment: Alignment.topCenter,
                    child: _MapPin(
                      spot: spot,
                      index: i,
                      active: i == focused,
                      onTap: () {
                        setState(() => focused = i);
                        if (carousel.hasClients) {
                          carousel.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 12,
          left: 16,
          right: 16,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 10, 14, 10),
                    color: Colors.white.withValues(alpha: .86),
                    child: Row(
                      children: [
                        Text('Peta', style: display(26)),
                        const SizedBox(width: 10),
                        Pill(
                          color: mint,
                          child: Text(
                            loading ? '…' : '${spots.length}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              GlassButton(
                glyph: Glyph.locate,
                label: 'Lokasiku',
                onTap: () {
                  if (here != null) mapController.move(here, 13);
                  locate();
                },
              ),
            ],
          ),
        ),
        if (error != null)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 80,
            left: 0,
            right: 0,
            child: Notice(error!, onRetry: refresh),
          ),
        if (spots.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset,
            height: 112,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: PageView.builder(
                  controller: carousel,
                  itemCount: spots.length,
                  onPageChanged: (i) {
                    setState(() => focused = i);
                    mapController.move(
                      LatLng(spots[i].lat, spots[i].lng),
                      math.max(mapController.camera.zoom, 12),
                    );
                  },
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _MiniCard(
                      spot: spots[i],
                      repo: repo,
                      onTap: () => open(spots[i]),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------- Profil ----------

  Widget _profile(bool wide) {
    final top = MediaQuery.paddingOf(context).top;
    if (repo.userId == null) {
      return Center(
        child: EmptyState(
          title: 'Masuk dulu,\nbiar spotmu awet.',
          action: 'Masuk / Daftar',
          mood: PikoMood.wink,
          onAction: () => openAuth(context, repo),
        ),
      );
    }
    final list = showSaved ? saved : mine;
    final likes = mine.fold<int>(0, (sum, s) => sum + s.likes);
    return RefreshIndicator(
      color: piko,
      onRefresh: refresh,
      edgeOffset: top,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, top + 12, 16, 140),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Rise(child: _profileCard(likes)),
                  const SizedBox(height: 20),
                  Rise(index: 1, child: _segment()),
                  const SizedBox(height: 16),
                  if (error != null) Notice(error!, onRetry: refresh),
                  if (loading)
                    Shimmer(
                      child: GridView.count(
                        crossAxisCount: wide ? 3 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: .8,
                        children: List.generate(
                          4,
                          (_) => const Bone(height: 200, radius: 26),
                        ),
                      ),
                    )
                  else if (list.isEmpty)
                    EmptyState(
                      title: showSaved
                          ? 'Belum ada yang\nkamu simpan.'
                          : 'Spot pertamamu\nmasih kosong.',
                      action: showSaved ? 'Cari inspirasi' : 'Bagikan spot',
                      color: showSaved ? caramel : coral,
                      onAction: showSaved ? () => chooseTab(1) : create,
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: wide ? 3 : 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: .8,
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, i) => Rise(
                        index: i,
                        child: _SpotTile(
                          spot: list[i],
                          repo: repo,
                          onTap: () => open(list[i]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCard(int likes) => Container(
    padding: const EdgeInsets.fromLTRB(20, 20, 14, 20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(34),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [grape, Color(0xFFE071C9)],
      ),
      boxShadow: const [
        BoxShadow(color: Color(0xFF6A49D6), offset: Offset(0, 6)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Avatar(repo.displayName, size: 66),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    repo.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: display(26, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    repo.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            GlassButton(
              glyph: Glyph.exit,
              label: 'Keluar',
              dark: true,
              onTap: () async {
                await repo.signOut();
                if (mounted) refresh();
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _ProfileStat(value: '${mine.length}', label: 'spot'),
            const SizedBox(width: 10),
            _ProfileStat(value: compact(likes), label: 'suka'),
            const SizedBox(width: 10),
            _ProfileStat(value: '${saved.length}', label: 'disimpan'),
          ],
        ),
      ],
    ),
  );

  Widget _segment() => Container(
    height: 54,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: line, width: 2),
    ),
    child: Stack(
      children: [
        AnimatedAlign(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          alignment: showSaved ? Alignment.centerRight : Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: .5,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: showSaved ? caramel : coral,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        Row(
          children: [
            for (final (i, label) in const ['Ceritaku', 'Tersimpan'].indexed)
              Expanded(
                child: Semantics(
                  selected: showSaved == (i == 1),
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => showSaved = i == 1);
                    },
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontFamily: fontBody,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: showSaved == (i == 1) ? Colors.white : muted,
                        ),
                        child: Text(label),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

// ---------- Komponen kecil ----------

class _LocationChip extends StatelessWidget {
  const _LocationChip({
    required this.active,
    required this.busy,
    required this.onTap,
  });
  final bool active, busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Bouncy(
    onTap: onTap,
    child: Semantics(
      button: true,
      label: active ? 'Lokasi aktif, perbarui' : 'Nyalakan lokasi',
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: line, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            else
              _Pulse(
                color: active ? mint : const Color(0xFFC3C8D9),
                on: active,
              ),
            const SizedBox(width: 8),
            Text(
              active ? 'Dekatmu' : 'Lokasi off',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.color, required this.on});
  final Color color;
  final bool on;
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 14,
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Stack(
        alignment: Alignment.center,
        children: [
          if (widget.on)
            Container(
              width: 6 + controller.value * 12,
              height: 6 + controller.value * 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(
                  alpha: (1 - controller.value) * .5,
                ),
              ),
            ),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Twinkle extends StatefulWidget {
  const _Twinkle({required this.size, required this.color, this.delay = 0});
  final double size, delay;
  final Color color;
  @override
  State<_Twinkle> createState() => _TwinkleState();
}

class _TwinkleState extends State<_Twinkle>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final t = (controller.value + widget.delay) % 1;
      final s = .7 + math.sin(t * math.pi * 2) * .3;
      return Transform.rotate(
        angle: t * math.pi / 2,
        child: Transform.scale(
          scale: calm(context) ? 1 : s,
          child: SpotIcon(
            Glyph.sparkle,
            size: widget.size,
            color: widget.color,
            accent: widget.color,
          ),
        ),
      );
    },
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({
    required this.tab,
    required this.onTab,
    required this.onCreate,
  });
  final int tab;
  final ValueChanged<int> onTab;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
    child: Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: line, width: 2),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: .10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < 2; i++)
            Expanded(
              child: _NavItem(
                item: _tabs[i],
                active: tab == i,
                onTap: () => onTab(i),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Tooltip(
              message: 'Bagikan spot',
              child: Chunky(
                onTap: onCreate,
                color: coral,
                radius: 22,
                depth: 5,
                label: 'Bagikan spot',
                padding: const EdgeInsets.all(13),
                child: const SpotIcon(
                  Glyph.plus,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          for (var i = 2; i < 4; i++)
            Expanded(
              child: _NavItem(
                item: _tabs[i],
                active: tab == i,
                onTap: () => onTab(i),
              ),
            ),
        ],
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.active,
    required this.onTap,
  });
  final _Tab item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: active,
    button: true,
    label: item.label,
    child: Tooltip(
      message: item.label,
      child: Bouncy(
        onTap: onTap,
        scale: .82,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              key: ValueKey(active),
              tween: Tween(begin: active ? 0 : 1, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.rotate(
                angle: active ? (1 - v) * .5 : 0,
                child: Transform.scale(
                  scale: active ? .7 + v * .3 : 1,
                  child: child,
                ),
              ),
              child: SpotIcon(
                item.glyph,
                size: 28,
                color: active ? ink : muted,
                accent: item.color,
                tint: active,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: active
                  ? Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    )
                  : const SizedBox(width: 24),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.tab,
    required this.onTab,
    required this.onCreate,
  });
  final int tab;
  final ValueChanged<int> onTab;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Container(
    width: 240,
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(right: BorderSide(color: line, width: 2)),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 28),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SvgPicture.asset('assets/logo.svg', height: 42),
              ),
            ),
            for (final (i, item) in _tabs.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Semantics(
                  selected: tab == i,
                  button: true,
                  child: Bouncy(
                    scale: .96,
                    onTap: () => onTab(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: tab == i
                            ? item.color.withValues(alpha: .14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          SpotIcon(
                            item.glyph,
                            size: 26,
                            color: tab == i ? ink : muted,
                            accent: item.color,
                            tint: tab == i,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: tab == i ? ink : muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Chunky(
              onTap: onCreate,
              color: coral,
              expand: true,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpotIcon(Glyph.plus, size: 22, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Bagikan spot'),
                ],
              ),
            ),
            const Spacer(),
            const Align(child: Piko(size: 96)),
          ],
        ),
      ),
    ),
  );
}

class _MeDot extends StatefulWidget {
  const _MeDot();
  @override
  State<_MeDot> createState() => _MeDotState();
}

class _MeDotState extends State<_MeDot> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 18 + controller.value * 40,
          height: 18 + controller.value * 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: piko.withValues(alpha: (1 - controller.value) * .35),
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: piko,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(color: Color(0x55192553), blurRadius: 8),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MapPin extends StatefulWidget {
  const _MapPin({
    required this.spot,
    required this.index,
    required this.active,
    required this.onTap,
  });
  final Spot spot;
  final int index;
  final bool active;
  final VoidCallback onTap;
  @override
  State<_MapPin> createState() => _MapPinState();
}

class _MapPinState extends State<_MapPin> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 60 * math.min(widget.index, 12)), () {
      if (mounted) controller.forward();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = categoryOf(widget.spot.category);
    return Semantics(
      button: true,
      label: widget.spot.title,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) => Transform.scale(
            alignment: Alignment.bottomCenter,
            scale:
                Curves.elasticOut.transform(controller.value) *
                (widget.active ? 1.18 : 1),
            child: child,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.active ? category.color : Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: ink, width: 2.4),
                  boxShadow: const [
                    BoxShadow(color: ink, offset: Offset(0, 4)),
                  ],
                ),
                child: SpotIcon(
                  category.glyph,
                  size: 28,
                  color: widget.active ? Colors.white : ink,
                  accent: widget.active
                      ? edgeOf(category.color)
                      : category.color,
                ),
              ),
              CustomPaint(size: const Size(14, 10), painter: _Tail()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tail extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(_Tail old) => false;
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.spot,
    required this.repo,
    required this.onTap,
  });
  final Spot spot;
  final SpotsRepository repo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Bouncy(
    scale: .97,
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: line, width: 2),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: .14),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: SizedBox.square(
              dimension: 92,
              child: AbsorbPointer(
                child: SpotGallery(
                  media: spot.media.take(1).toList(),
                  repo: repo,
                  height: 92,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spot.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: title.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    spot.city,
                    if (spot.distanceKm != null)
                      distanceLabel(spot.distanceKm!),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: small,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const SpotIcon(
                      Glyph.star,
                      size: 16,
                      color: Color(0xFFB77A0E),
                      accent: yellow,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      spot.rating?.toStringAsFixed(1) ?? 'Baru',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const SpotIcon(
                      Glyph.heart,
                      size: 16,
                      color: Color(0xFFB8455A),
                      accent: coral,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      compact(spot.likes),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(value, style: display(22, color: Colors.white)),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SpotTile extends StatelessWidget {
  const _SpotTile({
    required this.spot,
    required this.repo,
    required this.onTap,
  });
  final Spot spot;
  final SpotsRepository repo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Bouncy(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AbsorbPointer(
            child: SpotGallery(
              media: spot.media.take(1).toList(),
              repo: repo,
              height: double.infinity,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC192553)],
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 12,
            child: Transform.scale(
              alignment: Alignment.topLeft,
              scale: .85,
              child: CategorySticker(categoryOf(spot.category)),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Text(
              spot.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: title.copyWith(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    ),
  );
}
