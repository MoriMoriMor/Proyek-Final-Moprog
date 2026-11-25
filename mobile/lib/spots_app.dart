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
import 'game.dart';
import 'market.dart';
import 'market_screens.dart';
import 'people_page.dart';
import 'profile_page.dart';
import 'reels.dart';
import 'share.dart';
import 'seller_screens.dart';
import 'route_page.dart';
import 'spot.dart';
import 'spot_views.dart';
import 'spots_repository.dart';
import 'welcome.dart';
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
    navigatorKey: rootNavigator,
    debugShowCheckedModeBanner: false,
    theme: spotsTheme(),
    builder: (context, child) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(
          textScaler: media.textScaler.clamp(maxScaleFactor: 1.3),
        ),
        child: child!,
      );
    },
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
                SvgPicture.asset('assets/logo.svg', width: 190),
                const SizedBox(height: 26),
                const MascotCrew(size: 76, mood: MascotMood.laugh),
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
  const _Tab(this.label, this.glyph, this.color, this.index);
  final String label;
  final Glyph glyph;
  final Color color;
  final int index;
}

// Indeks tab: 0 Beranda, 1 Jelajah, 2 Peta, 3 Reels, 4 Market, 5 Profil.
const _tabs = [
  _Tab('Beranda', Glyph.home, coral, 0),
  _Tab('Jelajah', Glyph.compass, caramel, 1),
  _Tab('Peta', Glyph.map, mint, 2),
  _Tab('Reels', Glyph.play, piko, 3),
  _Tab('Market', Glyph.bag, yellow, 4),
  _Tab('Profil', Glyph.face, grape, 5),
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
  int tab = 0, focused = 0, reelStart = 0, profileView = 0;
  List<Store> nearStores = [];
  String? category;
  bool loading = true, locating = false, locationDenied = false;
  bool farAway = false;
  String? error;
  StreamSubscription<void>? authSubscription;
  Timer? debounce;
  int request = 0;

  @override
  void initState() {
    super.initState();
    GameState.instance.bind(repo);
    authSubscription = repo.authChanges.listen((_) {
      if (mounted) refresh(silent: true);
      syncStreak();
      GameState.instance.syncFromServer();
    });
    unawaited(refresh());
    locate();
    onShareAchievement = shareAchievement;
    GameState.instance.load().then((_) {
      syncStreak();
      GameState.instance.syncFromServer();
      welcome();
    });
  }

  /// Simpan streak ke profil supaya teman bisa melihatnya.
  Future<void> syncStreak() async {
    final streak = GameState.instance.streak;
    if (repo.userId == null || streak == 0) return;
    try {
      await repo.syncStreak(streak);
    } catch (_) {}
  }

  Future<void> welcome() async {
    final game = GameState.instance;
    if (!mounted) return;
    if (repo.userId == null) {
      await Navigator.of(context).push(
        PageRouteBuilder<void>(
          pageBuilder: (context, _, _) => WelcomePage(
            repo: repo,
            onDone: () {
              game.markOnboarded();
              Navigator.of(context).maybePop();
            },
          ),
          transitionsBuilder: (_, a, _, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      );
    } else if (game.streakGrewToday && game.streak >= 2 && mounted) {
      await showCelebration(
        context,
        title: 'Streak ${game.streak} hari!',
        subtitle: '${flameTierOf(game.streak).name} menyala. Pertahankan!',
        color: const Color(0xFFFF8A3D),
        badge: StreakFlame(streak: game.streak, size: 140),
        actionLabel: 'Pamerin streak',
        onAction: () => shareAchievement(context),
      );
    }
    await openIncoming();
  }

  /// Membuka spot, toko, atau undangan dari tautan yang dibagikan.
  Future<void> openIncoming() async {
    final link = parseIncoming(Uri.base);
    if (link == null || !mounted) return;
    switch (link.kind) {
      case 's':
        try {
          final spot = await repo.spotById(link.value);
          if (spot != null && mounted) open(spot);
        } catch (_) {}
      case 't':
        await openStore(context, repo, link.value);
      case 'u':
        await openProfileByUsername(context, repo, link.value);
      default:
        if (GameState.instance.claimInvite(link.value) && mounted) {
          message(context, 'Kamu datang lewat undangan teman. +30 XP!');
        }
    }
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
    await refresh(silent: spots.isNotEmpty);
  }

  Future<void> refresh({bool silent = false}) async {
    if (!mounted) return;
    final ticket = ++request;
    if (tab == 4) {
      setState(() => loading = false);
      return;
    }
    setState(() {
      if (!silent) loading = true;
      error = null;
    });
    try {
      if (tab == 5) {
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
        final near = (tab == 0 || tab == 2) && position != null;
        var found = await repo.feed(
          lat: position?.latitude,
          lng: position?.longitude,
          mode: near ? 'near' : 'popular',
          category: tab == 3 ? null : category,
          query: tab == 1 ? search.text.trim() : null,
        );
        // Belum ada spot di sekitar: tampilkan yang lagi ramai di kota lain.
        final fallback = near && found.isEmpty;
        if (fallback) {
          found = await repo.feed(
            lat: position?.latitude,
            lng: position?.longitude,
            mode: 'popular',
            category: category,
          );
        }
        if (ticket != request || !mounted) return;
        setState(() {
          farAway = fallback && found.isNotEmpty;
          spots = found;
          focused = 0;
        });
        if (tab == 0) {
          try {
            final shops = await repo.stores();
            if (mounted) setState(() => nearStores = shops.take(8).toList());
          } catch (_) {}
        }
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
      if (index == 3) reelStart = 0;
    });
    refresh();
  }

  void openReels(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      reelStart = index;
      tab = 3;
    });
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
      GameState.instance.track('post');
      setState(() {
        tab = 5;
        profileView = 0;
      });
      refresh();
    }
  }

  void open(Spot spot) =>
      openSpot(context, spot, repo, () => refresh(silent: true));

  void rememberReaction(Spot updated) {
    if (!mounted) return;
    setState(() {
      spots = [
        for (final spot in spots) spot.id == updated.id ? updated : spot,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    final page = AnimatedSwitcher(
      duration: motionTime(context, motionPage),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [
          for (final child in previous)
            ExcludeSemantics(
              child: ExcludeFocus(
                child: IgnorePointer(
                  child: TickerMode(enabled: false, child: child),
                ),
              ),
            ),
          ?current,
        ],
      ),
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
      child: KeyedSubtree(
        key: ValueKey(tab),
        child: TickerMode(
          enabled: TickerMode.valuesOf(context).enabled,
          child: _content(wide),
        ),
      ),
    );
    if (wide) {
      return Scaffold(
        body: SpotsBackdrop(
          market: tab == 4,
          child: Row(
            children: [
              _SideRail(
                tab: tab,
                onTab: chooseTab,
                onCreate: create,
                repo: repo,
              ),
              Expanded(child: page),
            ],
          ),
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
        dark: tab == 3,
      ),
    );
  }

  Widget _content(bool wide) => switch (tab) {
    2 => _map(wide),
    3 => ReelsView(
      key: ValueKey('reels-$reelStart'),
      spots: spots,
      repo: repo,
      loading: loading,
      initialIndex: spots.isEmpty ? 0 : reelStart.clamp(0, spots.length - 1),
      bottomInset: wide ? 0 : 92 + MediaQuery.paddingOf(context).bottom,
      onChanged: () => refresh(silent: true),
      onOpenStore: (id) => openStore(context, repo, id),
    ),
    4 => MarketTab(repo: repo),
    5 => _profile(wide),
    _ => _feed(wide),
  };

  // ---------- Beranda & Jelajah ----------

  Widget _feed(bool wide) {
    final explore = tab == 1;
    final top = MediaQuery.paddingOf(context).top;
    final feed = RefreshIndicator(
      color: piko,
      onRefresh: refresh,
      edgeOffset: top,
      child: CustomScrollView(
        key: PageStorageKey('feed-$explore'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: top + 8),
                    if (explore)
                      _exploreHeader(wide)
                    else ...[
                      _topBar(wide),
                      _greeting(),
                      _stories(),
                    ],
                    const SizedBox(height: 18),
                    CategoryRow(selected: category, onSelected: chooseCategory),
                    if (!explore && !loading) ..._homeExtras(),
                    SectionTitle(
                      explore
                          ? (search.text.isEmpty ? 'Lagi rame' : 'Hasil cari')
                          : farAway
                          ? 'Lagi rame di kota lain'
                          : position != null
                          ? 'Dekat kamu'
                          : 'Buat kamu',
                      trailing: explore
                          ? null
                          : _LocationChip(
                              active: position != null,
                              busy: locating,
                              onTap: locate,
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
                kind: explore ? MascotKind.gugu : MascotKind.pino,
                color: coral,
              ),
            )
          else
            _cards(spots, wide),
          const SliverToBoxAdapter(child: SizedBox(height: 130)),
        ],
      ),
    );
    return SpotsBackdrop(market: explore, child: feed);
  }

  Widget _cards(List<Spot> items, bool wide) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final columns = wide && constraints.crossAxisExtent >= 940 ? 2 : 1;
      final contentWidth = math.min(
        constraints.crossAxisExtent,
        columns == 2 ? 1100.0 : 600.0,
      );
      final inset = (constraints.crossAxisExtent - contentWidth) / 2 + 16;
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: inset),
        sliver: SliverList.builder(
          itemCount: (items.length / columns).ceil(),
          itemBuilder: (context, row) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var column = 0; column < columns; column++) ...[
                  if (column > 0) const SizedBox(width: 20),
                  Expanded(
                    child: row * columns + column >= items.length
                        ? const SizedBox()
                        : RepaintBoundary(
                            child: Rise(
                              index: row,
                              child: SpotCard(
                                key: ValueKey(items[row * columns + column].id),
                                spot: items[row * columns + column],
                                repo: repo,
                                onReactionChanged: rememberReaction,
                                onChanged: () => refresh(silent: true),
                                onOpen: () =>
                                    open(items[row * columns + column]),
                              ),
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _skeleton(bool wide) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 22),
              child: SpotsLogoLoader(compact: true),
            ),
            Shimmer(
              child: Column(
                children: List.generate(
                  2,
                  (_) => Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: glassStrong,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: glassBorder),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Bone(height: 300, radius: 25),
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
          ],
        ),
      ),
    ),
  );

  Widget _topBar(bool wide) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 14, 6),
    child: Row(
      children: [
        if (!wide) ...[
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SvgPicture.asset('assets/logo.svg', height: 30),
              ),
            ),
          ),
          const SizedBox(width: 8),
          StreakChip(onTap: () => openQuests(context)),
          const SizedBox(width: 8),
        ] else
          const Spacer(),
        _RoundButton(
          glyph: Glyph.search,
          label: 'Jelajah',
          accent: yellow,
          onTap: () => chooseTab(1),
        ),
        const SizedBox(width: 8),
        _RoundButton(
          glyph: Glyph.map,
          label: 'Peta',
          accent: mint,
          onTap: () => chooseTab(2),
        ),
        const SizedBox(width: 8),
        _RoundButton(
          glyph: Glyph.people,
          label: 'Cari teman',
          accent: grape,
          onTap: () => openPeople(context, repo),
        ),
      ],
    ),
  );

  Widget _greeting() {
    final hour = DateTime.now().hour;
    final hello = hour < 11
        ? 'Pagi'
        : hour < 15
        ? 'Siang'
        : hour < 19
        ? 'Sore'
        : 'Malam';
    final name = repo.userId == null ? 'kamu' : repo.displayName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$hello, $name!', style: small.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  'Mau ke mana\nhari ini?',
                  style: display(34, height: 1.08),
                ),
                const SizedBox(height: 12),
                Bouncy(
                  onTap: () => chooseTab(2),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SpotIcon(Glyph.pin, size: 18, color: blue, tint: false),
                        SizedBox(width: 6),
                        Text(
                          'Buka peta sekitar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: blue,
                          ),
                        ),
                        SizedBox(width: 6),
                        SpotIcon(
                          Glyph.route,
                          size: 16,
                          color: blue,
                          tint: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Piko(size: 78, wave: true),
        ],
      ),
    );
  }

  Widget _stories() {
    final items = spots.take(10).toList();
    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        children: [
          _StoryBubble(
            label: 'Bagikan',
            onTap: create,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .86),
              ),
              child: const Center(
                child: SpotIcon(
                  Glyph.plus,
                  size: 26,
                  color: piko,
                  tint: false,
                ),
              ),
            ),
          ),
          if (loading && items.isEmpty)
            for (var i = 0; i < 5; i++)
              const Padding(
                padding: EdgeInsets.only(left: 14),
                child: Shimmer(
                  child: Column(
                    children: [
                      Bone(width: 66, height: 66, radius: 33),
                      SizedBox(height: 6),
                      Bone(width: 50, height: 10),
                    ],
                  ),
                ),
              ),
          for (final (i, spot) in items.indexed)
            Rise(
              index: i,
              from: 16,
              child: _StoryBubble(
                label: spot.title,
                ring: true,
                onTap: () => openReels(i),
                child: _Cover(spot: spot, repo: repo),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _homeExtras() {
    final viral = [...spots]
      ..sort((a, b) => b.viralScore().compareTo(a.viralScore()));
    return [
      if (spots.length >= 3) ...[
        SectionTitle(
          'Lagi viral',
          trailing: const SpotIcon(
            Glyph.fire,
            size: 28,
            color: Color(0xFFD9541E),
            accent: Color(0xFFFFB648),
          ),
        ),
        SizedBox(
          height: 262,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: math.min(6, viral.length),
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => Rise(
              index: i,
              child: _ViralCard(
                spot: viral[i],
                rank: i + 1,
                repo: repo,
                onTap: () => openReels(spots.indexOf(viral[i])),
              ),
            ),
          ),
        ),
      ],
      if (nearStores.isNotEmpty) ...[
        SectionTitle(
          'Bisa dipesan',
          trailing: Bouncy(
            onTap: () => chooseTab(4),
            child: const Pill(
              color: Color(0xFFFFF4D6),
              child: Text('Market', style: TextStyle(color: Color(0xFF8A5B06))),
            ),
          ),
        ),
        SizedBox(
          height: 128 * MediaQuery.textScalerOf(context).scale(1),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: nearStores.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => Rise(
              index: i,
              child: StoreCard(
                store: nearStores[i],
                compactWidth: 300,
                onTap: () => openStore(
                  context,
                  repo,
                  nearStores[i].id,
                  initial: nearStores[i],
                ),
              ),
            ),
          ),
        ),
      ],
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
        child: QuestCard(onTap: () => openQuests(context)),
      ),
    ];
  }

  Widget _exploreHeader(bool wide) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (!wide) ...[
              GlassButton(
                glyph: Glyph.back,
                label: 'Kembali',
                onTap: () => chooseTab(0),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Rise(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Jelajah', style: display(40)),
                  ),
                ),
              ),
            ),
          ],
        ),
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
        (farAway ? null : here) ??
        (spots.isNotEmpty
            ? LatLng(spots.first.lat, spots.first.lng)
            : const LatLng(-6.2088, 106.8456));
    final bottomInset = wide ? 24.0 : 112.0;
    return Stack(
      children: [
        FlutterMap(
          key: ValueKey('map-$farAway-${spots.isEmpty}'),
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
              if (!wide) ...[
                GlassButton(
                  glyph: Glyph.back,
                  label: 'Kembali',
                  onTap: () => chooseTab(0),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        color: Colors.white.withValues(alpha: .86),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Mascot(
                              kind: MascotKind.pino,
                              size: 36,
                              wave: true,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Peta', style: display(26)),
                              ),
                            ),
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
                ),
              ),
              const SizedBox(width: 10),
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
            height: 124,
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
              itemBuilder: (context, i) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _MiniCard(
                      spot: spots[i],
                      repo: repo,
                      onTap: () => open(spots[i]),
                      onRoute: () => openRoute(context, spots[i]),
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
    final me = repo.userId;
    if (me == null) {
      return Center(
        child: EmptyState(
          title: 'Masuk dulu,\nbiar spotmu awet.',
          action: 'Masuk / Daftar',
          mood: PikoMood.wink,
          kind: MascotKind.piko,
          onAction: () => openAuth(context, repo),
        ),
      );
    }
    return ProfilePage(
      key: ValueKey('profile-$me'),
      repo: repo,
      userId: me,
      embedded: true,
      onCreate: create,
      onSignOut: () async {
        await repo.signOut();
        if (mounted) refresh();
      },
      extras: [
        StoreEntryCard(
          key: ValueKey(me),
          repo: repo,
          start: position == null
              ? null
              : LatLng(position!.latitude, position!.longitude),
        ),
        _InviteCard(onTap: () => shareInvite(context, repo)),
      ],
    );
  }
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
          border: Border.all(color: line),
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
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncMotion();
  }

  @override
  void didUpdateWidget(_Pulse old) {
    super.didUpdateWidget(old);
    syncMotion();
  }

  void syncMotion() {
    if (!widget.on || calm(context) || !TickerMode.valuesOf(context).enabled) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat();
    }
  }

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
  const _Twinkle({required this.size, required this.color}) : delay = 0;
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
  );

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (calm(context) || !TickerMode.valuesOf(context).enabled) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat();
    }
  }

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
    this.dark = false,
  });
  final int tab;
  final ValueChanged<int> onTab;
  final VoidCallback onCreate;
  final bool dark;

  static const left = [0, 3], right = [4, 5];

  bool active(int index) => index == 0 ? tab <= 2 : tab == index;

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
    child: FrostedSurface(
      radius: 28,
      sigma: 22,
      dark: dark,
      shadows: [
        BoxShadow(
          color: ink.withValues(alpha: dark ? .28 : .13),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ],
      child: SizedBox(
        height: 76,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              for (final i in left)
                Expanded(
                  child: _NavItem(
                    item: _tabs[i],
                    active: active(i),
                    dark: dark,
                    onTap: () => onTab(i),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Tooltip(
                  message: 'Bagikan spot',
                  child: Chunky(
                    onTap: onCreate,
                    color: piko,
                    radius: 20,
                    depth: 3,
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
              for (final i in right)
                Expanded(
                  child: _NavItem(
                    item: _tabs[i],
                    active: active(i),
                    dark: dark,
                    onTap: () => onTab(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.active,
    required this.onTap,
    this.dark = false,
  });
  final _Tab item;
  final bool active, dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final idle = dark ? Colors.white60 : muted;
    final on = dark ? Colors.white : piko;
    return Semantics(
      selected: active,
      button: true,
      label: item.label,
      child: Tooltip(
        message: item.label,
        child: Bouncy(
          onTap: onTap,
          scale: .94,
          child: AnimatedContainer(
            duration: motionTime(context, motionPage),
            curve: motionCurve,
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? (dark
                        ? Colors.white.withValues(alpha: .16)
                        : Colors.white.withValues(alpha: .86))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: active
                  ? Border.all(
                      color: dark ? darkGlassBorder : Colors.white,
                      width: 1.2,
                    )
                  : null,
              boxShadow: active && !dark ? surfaceShadow : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  key: ValueKey(active),
                  tween: Tween(begin: active ? 0 : 1, end: 1),
                  duration: motionTime(context, motionPage),
                  curve: motionCurve,
                  builder: (_, v, child) => Transform.scale(
                    scale: active ? .92 + v * .08 : 1,
                    child: child,
                  ),
                  child: SpotIcon(
                    item.glyph,
                    size: 24,
                    color: active ? on : idle,
                    accent: piko,
                    tint: active,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: active ? (dark ? Colors.white : ink) : idle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.tab,
    required this.onTab,
    required this.onCreate,
    required this.repo,
  });
  final SpotsRepository repo;
  final int tab;
  final ValueChanged<int> onTab;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
      child: SizedBox(
        width: 244,
        child: FrostedSurface(
          radius: 30,
          sigma: 22,
          fill: Colors.white.withValues(alpha: .84),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          shadows: [
            BoxShadow(
              color: ink.withValues(alpha: .09),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SvgPicture.asset('assets/logo.svg', height: 34),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StreakChip(onTap: () => openQuests(context)),
                  ],
                ),
              ),
              for (final item in _tabs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Semantics(
                    selected: tab == item.index,
                    button: true,
                    child: Bouncy(
                      scale: .97,
                      onTap: () => onTab(item.index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          gradient: tab == item.index
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF62A2FF),
                                  Color(0xFF3B76F6),
                                  ],
                                )
                              : null,
                          color: tab == item.index ? piko : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: tab == item.index
                              ? const [
                                  BoxShadow(
                                    color: Color(0x2B3B76F6),
                                    blurRadius: 12,
                                    offset: Offset(0, 5),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            SpotIcon(
                              item.glyph,
                              size: 22,
                              color: tab == item.index ? Colors.white : muted,
                              accent: piko,
                              tint: false,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: tab == item.index ? Colors.white : ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Chunky(
                onTap: onCreate,
                color: piko,
                radius: 99,
                expand: true,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpotIcon(
                      Glyph.plus,
                      size: 20,
                      color: Colors.white,
                      tint: false,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Bagikan spot',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(child: RailExtras(repo: repo)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.glyph,
    required this.label,
    required this.accent,
    required this.onTap,
  });
  final Glyph glyph;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      button: true,
      label: label,
      child: Bouncy(
        onTap: onTap,
        child: FrostedSurface(
          radius: 99,
          sigma: 16,
          fill: glassStrong,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: SpotIcon(glyph, size: 20, color: ink, accent: piko),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Sampul kecil dari media pertama sebuah spot.
class _Cover extends StatelessWidget {
  const _Cover({required this.spot, required this.repo});
  final Spot spot;
  final SpotsRepository repo;

  @override
  Widget build(BuildContext context) {
    final media = spot.media.isEmpty ? null : spot.media.first;
    if (media == null ||
        media.path.startsWith('demo:') ||
        media.type == 'video') {
      return DemoCover(seed: media?.path ?? 'demo:${spot.category}:${spot.id}');
    }
    return SpotImage(
      url: repo.publicMediaUrl(media.path),
      fallback: DemoCover(seed: 'demo:${spot.category}:${spot.id}'),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({
    required this.label,
    required this.child,
    required this.onTap,
    this.ring = false,
  });
  final String label;
  final Widget child;
  final VoidCallback onTap;
  final bool ring;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 14),
    child: Semantics(
      button: true,
      label: label,
      child: Bouncy(
        onTap: onTap,
        child: SizedBox(
          width: 70,
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: ring
                      ? const SweepGradient(
                          colors: [coral, yellow, mint, piko, grape, coral],
                        )
                      : null,
                  border: ring
                      ? null
                      : Border.all(color: const Color(0xFFFFC2CC), width: 2.5),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    color: pale,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(child: child),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ViralCard extends StatelessWidget {
  const _ViralCard({
    required this.spot,
    required this.rank,
    required this.repo,
    required this.onTap,
  });
  final Spot spot;
  final int rank;
  final SpotsRepository repo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Bouncy(
    onTap: onTap,
    child: Container(
      width: 172,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: surfaceShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Cover(spot: spot, repo: repo),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(0, -.1),
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xDD141B3D)],
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: Pill(
                color: ink.withValues(alpha: .65),
                child: Text(
                  '#$rank',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .25),
                  shape: BoxShape.circle,
                ),
                child: const SpotIcon(
                  Glyph.play,
                  size: 16,
                  color: Colors.white,
                  tint: false,
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 12,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: title.copyWith(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const SpotIcon(
                        Glyph.heart,
                        size: 16,
                        color: Colors.white,
                        accent: coral,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        compact(spot.likes),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          spot.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
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
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (calm(context) || !TickerMode.valuesOf(context).enabled) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat();
    }
  }

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
    duration: motionReveal,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 30 * math.min(widget.index, 4)), () {
      if (mounted) controller.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (calm(context)) controller.value = 1;
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
                (.86 + motionCurve.transform(controller.value) * .14) *
                (widget.active ? 1.1 : 1),
            child: child,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: motionTime(context, motionPage),
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.active ? blue : Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: widget.active ? ink : line,
                    width: 2,
                  ),
                  boxShadow: surfaceShadow,
                ),
                child: SpotIcon(
                  category.glyph,
                  size: 28,
                  color: widget.active ? Colors.white : ink,
                  accent: widget.active ? yellow : category.color,
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
    required this.onRoute,
  });
  final Spot spot;
  final SpotsRepository repo;
  final VoidCallback onTap, onRoute;

  @override
  Widget build(BuildContext context) => Bouncy(
    scale: .97,
    onTap: onTap,
    child: FrostedSurface(
      radius: 26,
      sigma: 18,
      fill: Colors.white.withValues(alpha: .86),
      padding: const EdgeInsets.all(8),
      shadows: [
        BoxShadow(
          color: ink.withValues(alpha: .16),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ],
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
                  maxLines: MediaQuery.textScalerOf(context).scale(1) > 1.1
                      ? 1
                      : 2,
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Bouncy(
            onTap: onRoute,
            child: Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF62A2FF), Color(0xFF3B76F6)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .36),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x283B76F6),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpotIcon(
                    Glyph.route,
                    size: 20,
                    color: Colors.white,
                    tint: false,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Rute',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    ),
  );
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Bouncy(
    scale: .97,
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1C7), Color(0xFFFFE0E6)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFFD98A), width: 2),
      ),
      child: Row(
        children: [
          const MascotCrew(
            kinds: [MascotKind.mimi, MascotKind.piko, MascotKind.jojo],
            size: 38,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ajak squad-mu', style: title.copyWith(fontSize: 16)),
                Text(
                  'Kirim kartu undangan ke teman',
                  style: small.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: ink,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'Ajak',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
