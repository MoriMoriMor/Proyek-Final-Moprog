import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' hide Path;

import 'game.dart';
import 'market_screens.dart';
import 'people_page.dart';
import 'share.dart';
import 'spot.dart';
import 'spot_views.dart';
import 'spots_repository.dart';
import 'ui/motion.dart';
import 'ui/piko.dart';
import 'ui/spot_icons.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

Future<void> openProfile(
  BuildContext context,
  SpotsRepository repo,
  String userId,
) {
  if (userId.isEmpty) return Future.value();
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProfilePage(repo: repo, userId: userId),
    ),
  );
}

Future<void> openProfileByUsername(
  BuildContext context,
  SpotsRepository repo,
  String username,
) async {
  try {
    final found = await repo.profileByUsername(username);
    if (!context.mounted) return;
    if (found == null) {
      message(context, '@$username belum ada di Spots.');
      return;
    }
    await openProfile(context, repo, found.id);
  } catch (e) {
    if (context.mounted) message(context, friendlyError(e));
  }
}

/// Teks yang membuat @username bisa diketuk.
class MentionText extends StatefulWidget {
  const MentionText(
    this.text, {
    super.key,
    required this.repo,
    this.style,
    this.maxLines,
  });
  final String text;
  final SpotsRepository repo;
  final TextStyle? style;
  final int? maxLines;

  @override
  State<MentionText> createState() => _MentionTextState();
}

class _MentionTextState extends State<MentionText> {
  final recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in recognizers) {
      r.dispose();
    }
    recognizers.clear();
    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in mentionPattern.allMatches(widget.text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: widget.text.substring(last, match.start)));
      }
      final handle = match.group(1)!;
      final tap = TapGestureRecognizer()
        ..onTap = () => openProfileByUsername(context, widget.repo, handle);
      recognizers.add(tap);
      spans.add(
        TextSpan(
          text: '@$handle',
          recognizer: tap,
          style: const TextStyle(color: blue, fontWeight: FontWeight.w900),
        ),
      );
      last = match.end;
    }
    if (last < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(last)));
    }
    return Text.rich(
      TextSpan(children: spans),
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

/// Halaman profil: milik sendiri atau orang lain.
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.repo,
    required this.userId,
    this.embedded = false,
    this.extras = const [],
    this.onCreate,
    this.onSignOut,
  });

  final SpotsRepository repo;
  final String userId;

  /// Tampil sebagai tab Profil (tanpa tombol kembali).
  final bool embedded;

  /// Kartu tambahan khusus pemilik, misalnya toko dan ajak teman.
  final List<Widget> extras;
  final VoidCallback? onCreate, onSignOut;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  SpotsRepository get repo => widget.repo;
  bool get self => repo.userId == widget.userId;

  UserProfile? profile;
  ProfileStats stats = const ProfileStats();
  List<Spot> posts = [];
  List<Spot>? tagged, saved;
  int tab = 0;
  bool loading = true, busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = profile == null;
      error = null;
    });
    try {
      final results = await Future.wait([
        repo.profile(widget.userId),
        repo.profileStats(widget.userId),
        repo.feed(mode: 'user', user: widget.userId),
      ]);
      if (!mounted) return;
      setState(() {
        profile = results[0] as UserProfile?;
        stats = results[1] as ProfileStats;
        posts = results[2] as List<Spot>;
        tagged = null;
        saved = null;
      });
      loadTab(tab);
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> loadTab(int index) async {
    try {
      if (index == 2 && tagged == null) {
        final found = await repo.feed(mode: 'tagged', user: widget.userId);
        if (mounted) setState(() => tagged = found);
      } else if (index == 3 && saved == null && self) {
        final found = await repo.feed(mode: 'saved');
        if (mounted) setState(() => saved = found);
      }
    } catch (e) {
      if (mounted) message(context, friendlyError(e));
    }
  }

  Future<void> toggleFollow() async {
    if (repo.userId == null) {
      await openAuth(context, repo);
      if (repo.userId == null) return;
    }
    final on = !stats.isFollowing;
    final before = stats;
    HapticFeedback.mediumImpact();
    setState(() {
      stats = ProfileStats(
        posts: stats.posts,
        followers: stats.followers + (on ? 1 : -1),
        following: stats.following,
        likes: stats.likes,
        saves: stats.saves,
        cities: stats.cities,
        isFollowing: on,
      );
    });
    try {
      await repo.setFollow(widget.userId, on);
      if (on) GameState.instance.track('follow');
    } catch (e) {
      if (!mounted) return;
      setState(() => stats = before);
      message(context, friendlyError(e));
    }
  }

  Future<void> edit() async {
    final current = profile;
    if (current == null) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditProfileSheet(repo: repo, profile: current),
    );
    if (saved == true) load();
  }

  void openFollows(bool followers) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        _FollowSheet(repo: repo, userId: widget.userId, followers: followers),
  );

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final top = MediaQuery.paddingOf(context).top;
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final body = p == null
        ? Center(
            child: loading
                ? const Piko(size: 110, mood: PikoMood.wow)
                : EmptyState(
                    title: error ?? 'Profil tidak ditemukan.',
                    action: 'Coba lagi',
                    onAction: load,
                  ),
          )
        : RefreshIndicator(
            color: piko,
            edgeOffset: top,
            onRefresh: load,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                top + 8,
                16,
                widget.embedded ? 140 : 40,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _topRow(p),
                        const SizedBox(height: 14),
                        Rise(child: _header(p)),
                        const SizedBox(height: 14),
                        Rise(index: 1, child: _passport()),
                        const SizedBox(height: 14),
                        Rise(index: 2, child: _actions(p)),
                        if (self && widget.extras.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          ...widget.extras,
                        ],
                        const SizedBox(height: 10),
                        _tabs(),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: KeyedSubtree(
                            key: ValueKey(tab),
                            child: _tabBody(wide),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
    if (widget.embedded) return body;
    return Scaffold(backgroundColor: pale, body: body);
  }

  Widget _topRow(UserProfile p) => Row(
    children: [
      if (!widget.embedded) ...[
        GlassButton(
          glyph: Glyph.back,
          label: 'Kembali',
          onTap: () => Navigator.maybePop(context),
        ),
        const SizedBox(width: 10),
      ],
      Expanded(
        child: Text(
          '@${p.username}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: title.copyWith(fontSize: 20),
        ),
      ),
      if (self) ...[
        GlassButton(
          glyph: Glyph.people,
          label: 'Cari teman',
          onTap: () => openPeople(context, repo),
        ),
        const SizedBox(width: 8),
      ],
      if (self && widget.onSignOut != null)
        GlassButton(
          glyph: Glyph.exit,
          label: 'Keluar',
          onTap: widget.onSignOut!,
        ),
    ],
  );

  Widget _header(UserProfile p) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Bouncy(
            onTap: self ? edit : null,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Avatar(
                  p.displayName,
                  size: 92,
                  url: repo.avatarUrl(p.avatarPath),
                  ring: true,
                ),
                if (self)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: piko,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const SpotIcon(
                        Glyph.plus,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(value: compact(stats.posts), label: 'Spot'),
                _Stat(
                  value: compact(stats.followers),
                  label: 'Pengikut',
                  onTap: () => openFollows(true),
                ),
                _Stat(
                  value: compact(stats.following),
                  label: 'Mengikuti',
                  onTap: () => openFollows(false),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(p.displayName, style: title.copyWith(fontSize: 18)),
      if (p.bio.isNotEmpty) ...[
        const SizedBox(height: 4),
        MentionText(
          p.bio,
          repo: repo,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            height: 1.45,
            color: Color(0xFF2E3A64),
          ),
        ),
      ],
    ],
  );

  /// "Paspor": ciri khas Spots, merangkum jejak tempat seseorang.
  Widget _passport() {
    final chips = <Widget>[
      _PassportChip(
        glyph: Glyph.pin,
        color: coral,
        text: '${stats.cities} kota',
      ),
      _PassportChip(
        glyph: Glyph.heart,
        color: coral,
        text: '${compact(stats.likes)} suka',
      ),
      _PassportChip(
        glyph: Glyph.bookmark,
        color: caramel,
        text: '${compact(stats.saves)} disimpan',
      ),
    ];
    if (self) {
      chips.add(
        ListenableBuilder(
          listenable: GameState.instance,
          builder: (context, _) => Bouncy(
            onTap: () => openQuests(context),
            child: _PassportChip(
              glyph: Glyph.fire,
              color: const Color(0xFFFF8A3D),
              text:
                  'Lv ${GameState.instance.level} · ${GameState.instance.streak} hari',
            ),
          ),
        ),
      );
    }
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _actions(UserProfile p) {
    final share = Expanded(
      child: Chunky(
        color: Colors.white,
        edge: line,
        border: line,
        expand: true,
        padding: const EdgeInsets.symmetric(vertical: 12),
        onTap: () => shareProfile(context, p, stats),
        child: const Text(
          'Bagikan profil',
          style: TextStyle(color: ink, fontSize: 15),
        ),
      ),
    );
    if (self) {
      return Row(
        children: [
          Expanded(
            child: Chunky(
              color: piko,
              expand: true,
              padding: const EdgeInsets.symmetric(vertical: 12),
              onTap: edit,
              child: const Text('Edit profil', style: TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(width: 10),
          share,
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Chunky(
            color: stats.isFollowing ? Colors.white : coral,
            edge: stats.isFollowing ? line : null,
            border: stats.isFollowing ? line : null,
            expand: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            onTap: busy ? null : toggleFollow,
            child: Text(
              stats.isFollowing ? 'Mengikuti' : 'Ikuti',
              style: TextStyle(
                fontSize: 15,
                color: stats.isFollowing ? ink : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        share,
      ],
    );
  }

  List<(Glyph, String)> get _tabList => [
    (Glyph.gallery, 'Spot'),
    (Glyph.map, 'Peta'),
    (Glyph.face, 'Ditandai'),
    if (self) (Glyph.bookmark, 'Simpanan'),
    if (self) (Glyph.receipt, 'Pesanan'),
  ];

  Widget _tabs() {
    final items = _tabList;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: line, width: 2)),
      ),
      child: Row(
        children: [
          for (final (i, (glyph, label)) in items.indexed)
            Expanded(
              child: Semantics(
                selected: tab == i,
                button: true,
                label: label,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => tab = i);
                    loadTab(i);
                  },
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      SpotIcon(
                        glyph,
                        size: 24,
                        color: tab == i ? ink : muted,
                        accent: yellow,
                        tint: tab == i,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: tab == i ? ink : muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 3,
                        width: tab == i ? 32 : 0,
                        decoration: BoxDecoration(
                          color: ink,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tabBody(bool wide) {
    switch (tab) {
      case 0:
        if (posts.isEmpty) {
          return EmptyState(
            title: self
                ? 'Spot pertamamu\nmasih kosong.'
                : 'Belum ada spot\ndari sini.',
            action: self && widget.onCreate != null ? 'Bagikan spot' : null,
            onAction: widget.onCreate,
            color: coral,
          );
        }
        return _grid(posts, wide);
      case 1:
        return _SpotMap(spots: posts, repo: repo, cities: stats.cities);
      case 2:
        final list = tagged;
        if (list == null) return const _GridSkeleton();
        if (list.isEmpty) {
          return const EmptyState(
            title: 'Belum ada yang\nnandain di sini.',
            mood: PikoMood.sleepy,
            kind: MascotKind.pino,
          );
        }
        return _grid(list, wide);
      case 3:
        final list = saved;
        if (list == null) return const _GridSkeleton();
        if (list.isEmpty) {
          return const EmptyState(
            title: 'Belum ada yang\nkamu simpan.',
            kind: MascotKind.jojo,
          );
        }
        return _grid(list, wide);
      default:
        return MyOrders(repo: repo);
    }
  }

  Widget _grid(List<Spot> items, bool wide) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: wide ? 4 : 3,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
    ),
    itemCount: items.length,
    itemBuilder: (context, i) => Rise(
      index: i,
      from: 12,
      child: _GridTile(
        spot: items[i],
        repo: repo,
        onTap: () => openSpot(context, items[i], repo, load),
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.onTap});
  final String value, label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: '$value $label',
    child: Bouncy(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              builder: (_, v, child) =>
                  Transform.scale(scale: .6 + v * .4, child: child),
              child: Text(value, style: display(22)),
            ),
            Text(label, style: small.copyWith(fontSize: 12.5)),
          ],
        ),
      ),
    ),
  );
}

class _PassportChip extends StatelessWidget {
  const _PassportChip({
    required this.glyph,
    required this.color,
    required this.text,
  });
  final Glyph glyph;
  final Color color;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpotIcon(
          glyph,
          size: 18,
          color: edgeOf(color),
          accent: color.withValues(alpha: .5),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            color: edgeOf(color),
          ),
        ),
      ],
    ),
  );
}

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.spot,
    required this.repo,
    required this.onTap,
  });
  final Spot spot;
  final SpotsRepository repo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final media = spot.media.isEmpty ? null : spot.media.first;
    final category = categoryOf(spot.category);
    return Bouncy(
      scale: .95,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            media == null ||
                    media.path.startsWith('demo:') ||
                    media.type == 'video'
                ? DemoCover(
                    seed: media?.path ?? 'demo:${spot.category}:${spot.id}',
                  )
                : Image.network(
                    repo.publicMediaUrl(media.path),
                    fit: BoxFit.cover,
                  ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(0, .2),
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x99141B3D)],
                ),
              ),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: SpotIcon(
                  category.glyph,
                  size: 16,
                  accent: category.color,
                ),
              ),
            ),
            if (media?.type == 'video' || spot.media.length > 1)
              Positioned(
                left: 6,
                top: 6,
                child: SpotIcon(
                  media?.type == 'video' ? Glyph.play : Glyph.gallery,
                  size: 18,
                  color: Colors.white,
                  tint: false,
                ),
              ),
            Positioned(
              left: 7,
              bottom: 6,
              right: 6,
              child: Row(
                children: [
                  const SpotIcon(
                    Glyph.heart,
                    size: 14,
                    color: Colors.white,
                    accent: coral,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    compact(spot.likes),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();
  @override
  Widget build(BuildContext context) => Shimmer(
    child: GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: List.generate(6, (_) => const Bone(height: 100, radius: 14)),
    ),
  );
}

class _SpotMap extends StatelessWidget {
  const _SpotMap({
    required this.spots,
    required this.repo,
    required this.cities,
  });
  final List<Spot> spots;
  final SpotsRepository repo;
  final int cities;

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return const EmptyState(
        title: 'Petanya masih\nkosong.',
        kind: MascotKind.pino,
        mood: PikoMood.sleepy,
      );
    }
    final points = [for (final s in spots) LatLng(s.lat, s.lng)];
    final bounds = LatLngBounds.fromPoints(points);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${spots.length} spot di $cities kota',
          style: title.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: SizedBox(
            height: 340,
            child: FlutterMap(
              options: MapOptions(
                initialCameraFit: points.length == 1
                    ? null
                    : CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(48),
                      ),
                initialCenter: points.first,
                initialZoom: 12,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.spots.app',
                ),
                MarkerLayer(
                  markers: [
                    for (final s in spots)
                      Marker(
                        point: LatLng(s.lat, s.lng),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => openSpot(context, s, repo, () {}),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: categoryOf(s.category).color,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: ink.withValues(alpha: .25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: SpotIcon(
                              categoryOf(s.category).glyph,
                              size: 22,
                              color: Colors.white,
                              tint: false,
                            ),
                          ),
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

class _FollowSheet extends StatelessWidget {
  const _FollowSheet({
    required this.repo,
    required this.userId,
    required this.followers,
  });
  final SpotsRepository repo;
  final String userId;
  final bool followers;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .75,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(followers ? 'Pengikut' : 'Mengikuti', style: display(26)),
            const SizedBox(height: 12),
            Flexible(
              child: FutureBuilder<List<UserProfile>>(
                future: repo.followList(userId, followers: followers),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Notice(friendlyError(snapshot.error!));
                  }
                  if (!snapshot.hasData) {
                    return const Shimmer(
                      child: Column(
                        children: [
                          Bone(height: 56),
                          SizedBox(height: 8),
                          Bone(height: 56),
                        ],
                      ),
                    );
                  }
                  if (snapshot.data!.isEmpty) {
                    return EmptyState(
                      title: followers
                          ? 'Belum ada\npengikut.'
                          : 'Belum mengikuti\nsiapa pun.',
                      mood: PikoMood.sleepy,
                    );
                  }
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      for (final (i, person) in snapshot.data!.indexed)
                        Rise(
                          index: i,
                          from: 10,
                          child: UserRow(
                            profile: person,
                            repo: repo,
                            onTap: () {
                              Navigator.pop(context);
                              openProfile(context, repo, person.id);
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class UserRow extends StatelessWidget {
  const UserRow({
    super.key,
    required this.profile,
    required this.repo,
    required this.onTap,
    this.trailing,
  });
  final UserProfile profile;
  final SpotsRepository repo;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Bouncy(
    scale: .98,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Avatar(
            profile.displayName,
            size: 46,
            url: repo.avatarUrl(profile.avatarPath),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.displayName, style: title.copyWith(fontSize: 15)),
                Text(
                  '@${profile.username}',
                  style: small.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    ),
  );
}

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({
    super.key,
    required this.repo,
    required this.profile,
  });
  final SpotsRepository repo;
  final UserProfile profile;
  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final name = TextEditingController(text: widget.profile.displayName);
  late final username = TextEditingController(text: widget.profile.username);
  late final bio = TextEditingController(text: widget.profile.bio);
  XFile? photo;
  Uint8ListPreview? preview;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    username.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      photo = picked;
      preview = Uint8ListPreview(bytes);
    });
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repo.updateProfile(
        displayName: name.text,
        username: username.text,
        bio: bio.text,
        avatar: photo,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Edit profil', style: display(28)),
                const SizedBox(height: 16),
                Center(
                  child: Bouncy(
                    onTap: pick,
                    child: Column(
                      children: [
                        preview != null
                            ? Container(
                                padding: const EdgeInsets.all(3.5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(40),
                                  gradient: const SweepGradient(
                                    colors: [
                                      coral,
                                      yellow,
                                      mint,
                                      piko,
                                      grape,
                                      coral,
                                    ],
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(36),
                                  child: Image.memory(
                                    preview!.bytes,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : Avatar(
                                widget.profile.displayName,
                                size: 96,
                                url: widget.repo.avatarUrl(
                                  widget.profile.avatarPath,
                                ),
                                ring: true,
                              ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ganti foto',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: name,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    hintText: 'Nama',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: username,
                  maxLength: 20,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_.]')),
                    TextInputFormatter.withFunction(
                      (_, value) =>
                          value.copyWith(text: value.text.toLowerCase()),
                    ),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'username',
                    prefixText: '@',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bio,
                  maxLength: 150,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Bio singkat. Bisa tag @teman juga.',
                  ),
                ),
                if (error != null) Notice(error!),
                const SizedBox(height: 10),
                Chunky(
                  expand: true,
                  color: piko,
                  onTap: busy ? null : save,
                  child: Text(busy ? 'Menyimpan…' : 'Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Pembungkus kecil agar pratinjau foto tidak memicu salinan ulang.
class Uint8ListPreview {
  Uint8ListPreview(this.bytes);
  final Uint8List bytes;
}

/// Pemilih teman untuk ditandai di postingan.
class TagPicker extends StatefulWidget {
  const TagPicker({
    super.key,
    required this.repo,
    required this.selected,
    required this.onChanged,
  });
  final SpotsRepository repo;
  final List<UserProfile> selected;
  final ValueChanged<List<UserProfile>> onChanged;
  @override
  State<TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<TagPicker> {
  final query = TextEditingController();
  List<UserProfile> results = [];

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> search(String q) async {
    if (q.trim().length < 2) {
      setState(() => results = []);
      return;
    }
    try {
      final found = await widget.repo.searchUsers(q);
      if (mounted && query.text == q) setState(() => results = found);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: query,
        onChanged: search,
        decoration: const InputDecoration(
          hintText: 'Tandai teman (@username)',
          prefixIcon: Padding(
            padding: EdgeInsets.all(12),
            child: SpotIcon(Glyph.face, size: 22, accent: grape),
          ),
        ),
      ),
      if (widget.selected.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final person in widget.selected)
              InputChip(
                avatar: Avatar(
                  person.displayName,
                  size: 24,
                  url: widget.repo.avatarUrl(person.avatarPath),
                ),
                label: Text(
                  '@${person.username}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                onDeleted: () =>
                    widget.onChanged([...widget.selected]..remove(person)),
              ),
          ],
        ),
      ],
      for (final person
          in results
              .where((r) => !widget.selected.any((s) => s.id == r.id))
              .take(5))
        UserRow(
          profile: person,
          repo: widget.repo,
          onTap: () {
            widget.onChanged([...widget.selected, person]);
            query.clear();
            setState(() => results = []);
          },
          trailing: const SpotIcon(Glyph.plus, size: 20, color: blue),
        ),
    ],
  );
}
