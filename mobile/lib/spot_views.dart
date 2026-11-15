import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'game.dart';
import 'market.dart';
import 'market_screens.dart';
import 'spot.dart';
import 'spots_repository.dart';
import 'ui/motion.dart';
import 'ui/piko.dart';
import 'ui/spot_icons.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

String friendlyError(Object error) {
  if (error is PostgrestException) return error.message;
  if (error is AuthException) {
    final text = error.message.toLowerCase();
    if (text.contains('invalid login')) return 'Email atau kata sandi salah.';
    if (text.contains('already registered')) {
      return 'Email ini sudah terdaftar.';
    }
    return error.message;
  }
  final text = error.toString();
  if (text.contains('SocketException') || text.contains('ClientException')) {
    return 'Koneksi putus. Cek internetmu.';
  }
  return text.replaceFirst('Bad state: ', '');
}

String distanceLabel(double km) => km < 1
    ? '${(km * 1000).round()} m'
    : km < 100
    ? '${km.toStringAsFixed(1)} km'
    : '${km.round()} km';

String compact(int value) => value >= 1000
    ? '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}rb'
    : '$value';

/// Status suka dan simpan yang langsung berubah di layar,
/// lalu dikembalikan jika permintaan ke server gagal.
class Reactions extends ChangeNotifier {
  Reactions(Spot spot)
    : liked = spot.liked,
      saved = spot.saved,
      likes = spot.likes;

  bool liked, saved;
  int likes;

  Future<bool> toggle(
    BuildContext context,
    SpotsRepository repo,
    String postId,
    String kind, {
    bool? value,
  }) async {
    if (repo.userId == null) {
      await openAuth(context, repo);
      return false;
    }
    final on = value ?? !(kind == 'like' ? liked : saved);
    final before = (liked, saved, likes);
    if (kind == 'like') {
      if (liked == on) return true;
      liked = on;
      likes += on ? 1 : -1;
    } else {
      saved = on;
    }
    notifyListeners();
    try {
      await repo.setReaction(postId, kind, on);
      return true;
    } catch (e) {
      liked = before.$1;
      saved = before.$2;
      likes = before.$3;
      notifyListeners();
      if (context.mounted) message(context, friendlyError(e));
      return false;
    }
  }
}

class SpotCard extends StatefulWidget {
  const SpotCard({
    super.key,
    required this.spot,
    required this.repo,
    required this.onChanged,
    required this.onOpen,
  });
  final Spot spot;
  final SpotsRepository repo;
  final VoidCallback onChanged, onOpen;

  @override
  State<SpotCard> createState() => _SpotCardState();
}

class _SpotCardState extends State<SpotCard>
    with SingleTickerProviderStateMixin {
  late Reactions reactions = Reactions(widget.spot);
  late final heart = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didUpdateWidget(SpotCard old) {
    super.didUpdateWidget(old);
    if (old.spot != widget.spot) reactions = Reactions(widget.spot);
  }

  @override
  void dispose() {
    heart.dispose();
    super.dispose();
  }

  Future<void> doubleTapLike() async {
    if (!calm(context)) heart.forward(from: 0);
    HapticFeedback.mediumImpact();
    final was = reactions.liked;
    final ok = await reactions.toggle(
      context,
      widget.repo,
      widget.spot.id,
      'like',
      value: true,
    );
    if (ok && !was) GameState.instance.track('like');
  }

  Future<void> toggle(String kind) async {
    final was = kind == 'like' ? reactions.liked : reactions.saved;
    final ok = await reactions.toggle(
      context,
      widget.repo,
      widget.spot.id,
      kind,
    );
    if (ok && !was) GameState.instance.track(kind);
    if (ok && kind == 'save') widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final spot = widget.spot;
    final category = categoryOf(spot.category);
    return Bouncy(
      scale: .985,
      onTap: widget.onOpen,
      onDoubleTap: doubleTapLike,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: line, width: 2),
          boxShadow: const [BoxShadow(color: line, offset: Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Stack(
                children: [
                  Hero(
                    tag: 'media-${spot.id}',
                    child: SpotGallery(
                      media: spot.media,
                      repo: widget.repo,
                      height: 330,
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 14,
                    child: CategorySticker(category),
                  ),
                  if (spot.distanceKm != null)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Pill(
                        color: Colors.white.withValues(alpha: .9),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SpotIcon(Glyph.pin, size: 15, accent: coral),
                            const SizedBox(width: 3),
                            Text(distanceLabel(spot.distanceKm!)),
                          ],
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: IgnorePointer(child: _BigHeart(controller: heart)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          spot.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: title,
                        ),
                      ),
                      if (spot.rating != null) ...[
                        const SizedBox(width: 8),
                        _RatingBadge(spot.rating!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Avatar(spot.author, size: 22),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          '${spot.author} · ${spot.city}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: small,
                        ),
                      ),
                    ],
                  ),
                  if (spot.story.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      spot.story,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF3B4670),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ListenableBuilder(
              listenable: reactions,
              builder: (context, _) => Row(
                children: [
                  PopToggle(
                    active: reactions.liked,
                    label: reactions.liked ? 'Batal suka' : 'Suka',
                    onTap: () => toggle('like'),
                    builder: (on) => SpotIcon(
                      Glyph.heart,
                      size: 26,
                      color: on ? edgeOf(coral) : ink,
                      accent: on ? coral : const Color(0xFFFFD6DD),
                    ),
                  ),
                  _Count(reactions.likes),
                  const SizedBox(width: 6),
                  Bouncy(
                    onTap: widget.onOpen,
                    child: Semantics(
                      button: true,
                      label: 'Komentar',
                      child: const SizedBox.square(
                        dimension: 44,
                        child: Center(
                          child: SpotIcon(
                            Glyph.chat,
                            size: 25,
                            accent: Color(0xFFCFD9FF),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _Count(spot.comments),
                  const Spacer(),
                  PopToggle(
                    active: reactions.saved,
                    label: reactions.saved ? 'Hapus dari simpanan' : 'Simpan',
                    colors: const [yellow, caramel, piko],
                    onTap: () => toggle('save'),
                    builder: (on) => SpotIcon(
                      Glyph.bookmark,
                      size: 26,
                      color: on ? edgeOf(caramel) : ink,
                      accent: on ? yellow : const Color(0xFFFFEBC2),
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

class _Count extends StatelessWidget {
  const _Count(this.value);
  final int value;
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 260),
    transitionBuilder: (child, animation) => SlideTransition(
      position: Tween(
        begin: const Offset(0, .6),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    ),
    child: Text(
      compact(value),
      key: ValueKey(value),
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
    ),
  );
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge(this.rating);
  final double rating;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4D6),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SpotIcon(
          Glyph.star,
          size: 17,
          color: Color(0xFFB77A0E),
          accent: yellow,
        ),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            color: Color(0xFF8A5B06),
          ),
        ),
      ],
    ),
  );
}

class _BigHeart extends StatelessWidget {
  const _BigHeart({required this.controller});
  final AnimationController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final t = controller.value;
      if (t == 0 || t == 1) return const SizedBox.shrink();
      final grow = Curves.elasticOut.transform((t * 1.6).clamp(0, 1));
      final fade = t < .7 ? 1.0 : 1 - (t - .7) / .3;
      return Opacity(
        opacity: fade,
        child: CustomPaint(
          painter: BurstPainter(t, const [
            coral,
            yellow,
            Colors.white,
          ], count: 12),
          child: Center(
            child: Transform.rotate(
              angle: -.12,
              child: Transform.scale(
                scale: grow,
                child: SpotIcon(
                  Glyph.heart,
                  size: 110,
                  color: Colors.white,
                  accent: coral,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class SpotGallery extends StatefulWidget {
  const SpotGallery({
    super.key,
    required this.media,
    required this.repo,
    this.height = 320,
  });
  final List<SpotMedia> media;
  final SpotsRepository repo;
  final double height;
  @override
  State<SpotGallery> createState() => _SpotGalleryState();
}

class _SpotGalleryState extends State<SpotGallery> {
  int current = 0;
  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const DemoCover(seed: 'kosong:destinasi'),
      );
    }
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.media.length,
            onPageChanged: (value) => setState(() => current = value),
            itemBuilder: (context, index) {
              final item = widget.media[index];
              if (item.path.startsWith('demo:')) {
                return DemoCover(seed: item.path);
              }
              final url = widget.repo.publicMediaUrl(item.path);
              return item.type == 'video'
                  ? SpotVideo(
                      key: ValueKey(item.path),
                      url: url,
                      active: current == index,
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      frameBuilder: (context, child, frame, sync) =>
                          AnimatedOpacity(
                            opacity: frame == null && !sync ? 0 : 1,
                            duration: const Duration(milliseconds: 300),
                            child: child,
                          ),
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : const Shimmer(child: Bone(height: double.infinity)),
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: pale,
                        child: Center(
                          child: Piko(
                            size: 64,
                            mood: PikoMood.wow,
                            bounce: false,
                          ),
                        ),
                      ),
                    );
            },
          ),
          if (widget.media.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.media.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    width: current == i ? 20 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: current == i
                          ? Colors.white
                          : Colors.white.withValues(alpha: .55),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Sampul ilustrasi untuk data demo: gradasi, bukit, dan ikon kategori.
class DemoCover extends StatelessWidget {
  const DemoCover({super.key, required this.seed});
  final String seed;

  @override
  Widget build(BuildContext context) {
    final parts = seed.split(':');
    final category = categoryOf(parts.length > 1 ? parts[1] : 'destinasi');
    final hash = seed.hashCode.abs();
    final palettes = <List<Color>>[
      [const Color(0xFFFFB199), const Color(0xFFFF6A88)],
      [const Color(0xFF8EC5FF), const Color(0xFF6A7BFF)],
      [const Color(0xFFFFE29F), const Color(0xFFFFA36C)],
      [const Color(0xFFA1F2D3), const Color(0xFF3FB6A8)],
      [const Color(0xFFD4B8FF), const Color(0xFF8B6CF3)],
    ];
    final colors = palettes[hash % palettes.length];
    return CustomPaint(
      painter: _CoverPainter(colors, hash),
      child: Center(
        child: Transform.rotate(
          angle: ((hash % 7) - 3) * .05,
          child: SpotIcon(
            category.glyph,
            size: 96,
            color: Colors.white,
            accent: edgeOf(colors.last),
          ),
        ),
      ),
    );
  }
}

class _CoverPainter extends CustomPainter {
  _CoverPainter(this.colors, this.seed);
  final List<Color> colors;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(rect),
    );
    final random = math.Random(seed);
    canvas.drawCircle(
      Offset(size.width * (.2 + random.nextDouble() * .6), size.height * .26),
      size.shortestSide * .16,
      Paint()..color = Colors.white.withValues(alpha: .35),
    );
    for (var layer = 0; layer < 2; layer++) {
      final path = Path()..moveTo(0, size.height);
      final base = size.height * (.68 + layer * .12);
      path.lineTo(0, base);
      final waves = 2 + random.nextInt(2);
      for (var i = 0; i < waves; i++) {
        final x1 = size.width * (i + .5) / waves;
        final x2 = size.width * (i + 1) / waves;
        path.quadraticBezierTo(
          x1,
          base - size.height * (.12 + random.nextDouble() * .12),
          x2,
          base,
        );
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = Colors.white.withValues(alpha: .18 + layer * .14),
      );
    }
  }

  @override
  bool shouldRepaint(_CoverPainter old) => old.seed != seed;
}

class SpotVideo extends StatefulWidget {
  const SpotVideo({super.key, required this.url, required this.active});
  final String url;
  final bool active;
  @override
  State<SpotVideo> createState() => _SpotVideoState();
}

class _SpotVideoState extends State<SpotVideo> {
  late final VideoPlayerController controller;
  bool ready = false;
  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize()
          .then((_) {
            if (mounted) setState(() => ready = true);
          })
          .catchError((Object _) {});
    controller.setLooping(true);
    controller.setVolume(0);
  }

  @override
  void didUpdateWidget(covariant SpotVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) controller.pause();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    color: ink,
    child: ready
        ? Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
              Center(
                child: GlassButton(
                  dark: true,
                  label: controller.value.isPlaying
                      ? 'Jeda video'
                      : 'Putar video',
                  glyph: controller.value.isPlaying ? Glyph.close : Glyph.play,
                  onTap: () => setState(
                    () => controller.value.isPlaying
                        ? controller.pause()
                        : controller.play(),
                  ),
                ),
              ),
            ],
          )
        : const Center(child: CircularProgressIndicator(color: Colors.white)),
  );
}

Future<void> openSpot(
  BuildContext context,
  Spot spot,
  SpotsRepository repo,
  VoidCallback onChanged,
) => Navigator.push(
  context,
  PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) =>
        SpotDetail(spot: spot, repo: repo, onChanged: onChanged),
    transitionsBuilder: (context, animation, _, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, .06),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  ),
);

class SpotDetail extends StatefulWidget {
  const SpotDetail({
    super.key,
    required this.spot,
    required this.repo,
    required this.onChanged,
  });
  final Spot spot;
  final SpotsRepository repo;
  final VoidCallback onChanged;
  @override
  State<SpotDetail> createState() => _SpotDetailState();
}

class _SpotDetailState extends State<SpotDetail> {
  final comment = TextEditingController();
  late Future<List<SpotComment>> comments = widget.repo.comments(
    widget.spot.id,
  );
  late final reactions = Reactions(widget.spot);
  int myRating = 0;
  int commentCount = 0;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    commentCount = widget.spot.comments;
  }

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (comment.text.trim().isEmpty) return;
    if (widget.repo.userId == null) {
      await openAuth(context, widget.repo);
      return;
    }
    setState(() => sending = true);
    try {
      await widget.repo.addComment(widget.spot.id, comment.text);
      GameState.instance.track('comment');
      comment.clear();
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        comments = widget.repo.comments(widget.spot.id);
        commentCount++;
      });
      widget.onChanged();
    } catch (e) {
      if (mounted) message(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> rate(int score) async {
    if (widget.repo.userId == null) {
      await openAuth(context, widget.repo);
      return;
    }
    final before = myRating;
    setState(() => myRating = score);
    HapticFeedback.selectionClick();
    try {
      await widget.repo.rate(widget.spot.id, score);
      if (before == 0) GameState.instance.track('rate');
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        setState(() => myRating = before);
        message(context, friendlyError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spot = widget.spot;
    final category = categoryOf(spot.category);
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final body = ListView(
      padding: EdgeInsets.zero,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(36),
          ),
          child: Stack(
            children: [
              Hero(
                tag: 'media-${spot.id}',
                child: SpotGallery(
                  media: spot.media,
                  repo: widget.repo,
                  height: wide ? 460 : 420,
                ),
              ),
              Positioned(
                left: 16,
                top: MediaQuery.paddingOf(context).top + 10,
                child: GlassButton(
                  glyph: Glyph.back,
                  label: 'Kembali',
                  onTap: () => Navigator.maybePop(context),
                ),
              ),
              Positioned(
                right: 16,
                top: MediaQuery.paddingOf(context).top + 10,
                child: ListenableBuilder(
                  listenable: reactions,
                  builder: (context, _) => GlassButton(
                    glyph: Glyph.bookmark,
                    label: reactions.saved ? 'Hapus dari simpanan' : 'Simpan',
                    onTap: () async {
                      final ok = await reactions.toggle(
                        context,
                        widget.repo,
                        spot.id,
                        'save',
                      );
                      if (ok) widget.onChanged();
                      if (ok && context.mounted) {
                        message(
                          context,
                          reactions.saved
                              ? 'Tersimpan!'
                              : 'Dihapus dari simpanan',
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Rise(child: CategorySticker(category)),
              const SizedBox(height: 14),
              Rise(
                index: 1,
                child: Text(spot.title, style: display(32, height: 1.05)),
              ),
              const SizedBox(height: 12),
              Rise(
                index: 2,
                child: Row(
                  children: [
                    Avatar(spot.author, size: 30),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '${spot.author} · ${spot.city}',
                        style: small.copyWith(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Rise(
                index: 3,
                child: Text(
                  spot.story,
                  style: const TextStyle(
                    height: 1.55,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E3A64),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Rise(
                index: 4,
                child: ListenableBuilder(
                  listenable: reactions,
                  builder: (context, _) => Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          glyph: Glyph.heart,
                          color: coral,
                          tint: const Color(0xFFFFEDF0),
                          value: compact(reactions.likes),
                          label: 'suka',
                          active: reactions.liked,
                          onTap: () async {
                            final was = reactions.liked;
                            final ok = await reactions.toggle(
                              context,
                              widget.repo,
                              spot.id,
                              'like',
                            );
                            if (ok && !was) GameState.instance.track('like');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          glyph: Glyph.chat,
                          color: piko,
                          tint: const Color(0xFFEDF1FF),
                          value: compact(commentCount),
                          label: 'komentar',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          glyph: Glyph.star,
                          color: caramel,
                          tint: const Color(0xFFFFF5DD),
                          value: spot.rating?.toStringAsFixed(1) ?? '—',
                          label: 'rating',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Rise(
                index: 5,
                child: Chunky(
                  expand: true,
                  color: mint,
                  label: 'Buka rute di Google Maps',
                  onTap: () => launchUrl(
                    Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=${spot.lat},${spot.lng}',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SpotIcon(
                        Glyph.route,
                        size: 22,
                        color: Colors.white,
                        accent: Color(0xFF1E8F70),
                      ),
                      SizedBox(width: 8),
                      Text('Gas ke sini'),
                    ],
                  ),
                ),
              ),
              if (spot.storeId != null) ...[
                const SizedBox(height: 16),
                Rise(
                  index: 6,
                  child: _StoreTeaser(
                    repo: widget.repo,
                    storeId: spot.storeId!,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Text('Kasih bintang', style: display(22)),
              const SizedBox(height: 10),
              _StarPicker(value: myRating, onChanged: rate),
              const SizedBox(height: 28),
              Row(
                children: [
                  Text('Obrolan', style: display(22)),
                  const SizedBox(width: 8),
                  Pill(
                    color: const Color(0xFFEDF1FF),
                    child: Text('$commentCount'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<SpotComment>>(
                future: comments,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      friendlyError(snapshot.error!),
                      style: const TextStyle(color: danger),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Shimmer(
                      child: Column(
                        children: [
                          Bone(height: 56, radius: 20),
                          SizedBox(height: 10),
                          Bone(height: 56, radius: 20),
                        ],
                      ),
                    );
                  }
                  if (snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Masih sepi. Mulai obrolannya!',
                        style: small,
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final (i, c) in snapshot.data!.indexed)
                        Rise(index: i, from: 14, child: _Bubble(c)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ],
    );
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: body,
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: line, width: 2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: comment,
                        maxLength: 500,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => send(),
                        decoration: const InputDecoration(
                          hintText: 'Tulis sesuatu…',
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chunky(
                      onTap: sending ? null : send,
                      color: piko,
                      radius: 18,
                      depth: 4,
                      label: 'Kirim komentar',
                      padding: const EdgeInsets.all(12),
                      child: const SpotIcon(
                        Glyph.send,
                        size: 22,
                        color: Colors.white,
                        accent: Color(0xFF2A4BC6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.glyph,
    required this.color,
    required this.tint,
    required this.value,
    required this.label,
    this.active = false,
    this.onTap,
  });
  final Glyph glyph;
  final Color color, tint;
  final String value, label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Bouncy(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: active ? color : tint,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpotIcon(
            glyph,
            size: 24,
            color: active ? Colors.white : edgeOf(color),
            accent: active ? edgeOf(color) : color.withValues(alpha: .45),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: active ? Colors.white : ink,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: active ? Colors.white70 : muted,
            ),
          ),
        ],
      ),
    ),
  );
}

class _StarPicker extends StatelessWidget {
  const _StarPicker({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(5, (i) {
      final on = i < value;
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: PopToggle(
          active: on,
          label: 'Beri ${i + 1} bintang',
          size: 50,
          colors: const [yellow, caramel, coral],
          onTap: () => onChanged(i + 1),
          builder: (on) => AnimatedRotation(
            turns: on ? .1 : 0,
            duration: Duration(milliseconds: 250 + i * 60),
            curve: Curves.easeOutBack,
            child: SpotIcon(
              Glyph.star,
              size: 38,
              color: on ? const Color(0xFFB77A0E) : const Color(0xFFC3C9DC),
              accent: on ? yellow : const Color(0xFFEFF1F8),
            ),
          ),
        ),
      );
    }),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.comment);
  final SpotComment comment;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Avatar(comment.author, size: 34),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: const BoxDecoration(
              color: pale,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
                topLeft: Radius.circular(6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.author,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  comment.body,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
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

Future<void> openAuth(
  BuildContext context,
  SpotsRepository repo, {
  VoidCallback? onSuccess,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => AuthSheet(repo: repo, onSuccess: onSuccess),
);

class AuthSheet extends StatefulWidget {
  const AuthSheet({super.key, required this.repo, this.onSuccess});
  final SpotsRepository repo;
  final VoidCallback? onSuccess;
  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool register = false, busy = false, hidden = true;
  String? error, info;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!email.text.contains('@') ||
        password.text.length < 6 ||
        (register && name.text.trim().length < 2)) {
      setState(
        () => error = register
            ? 'Isi nama, email, dan sandi minimal 6 karakter.'
            : 'Isi email dan sandi yang benar.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
      info = null;
    });
    try {
      if (register) {
        final ready = await widget.repo.signUp(
          name.text,
          email.text,
          password.text,
        );
        if (!ready) {
          if (mounted) {
            setState(() {
              info = 'Cek email buat aktivasi, lalu masuk ya.';
              register = false;
            });
          }
          return;
        }
      } else {
        await widget.repo.signIn(email.text, password.text);
      }
      widget.onSuccess?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      0,
      24,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.centerLeft,
                          children: [...previous, ?current],
                        ),
                        child: Text(
                          register ? 'Gabung\nSpots' : 'Hai lagi!',
                          key: ValueKey(register),
                          style: display(34),
                        ),
                      ),
                    ),
                    Piko(
                      size: 86,
                      mood: register ? PikoMood.wow : PikoMood.wink,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  child: register
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextField(
                            controller: name,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.nickname],
                            decoration: const InputDecoration(
                              hintText: 'Nama panggilan',
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(hintText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: hidden,
                  onSubmitted: (_) => submit(),
                  autofillHints: [
                    register
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  decoration: InputDecoration(
                    hintText: 'Kata sandi',
                    suffixIcon: IconButton(
                      tooltip: hidden ? 'Tampilkan sandi' : 'Sembunyikan sandi',
                      onPressed: () => setState(() => hidden = !hidden),
                      icon: Text(
                        hidden ? 'lihat' : 'tutup',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: blue,
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: error == null && info == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            error ?? info!,
                            style: TextStyle(
                              color: error != null ? danger : blue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                Chunky(
                  expand: true,
                  color: register ? coral : piko,
                  onTap: busy ? null : submit,
                  child: Text(
                    busy
                        ? 'Sebentar…'
                        : register
                        ? 'Bikin akun'
                        : 'Masuk',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          register = !register;
                          error = null;
                          info = null;
                        }),
                  child: Text(
                    register
                        ? 'Udah punya akun? Masuk'
                        : 'Belum punya akun? Daftar',
                    style: const TextStyle(fontWeight: FontWeight.w900),
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

class _StoreTeaser extends StatefulWidget {
  const _StoreTeaser({required this.repo, required this.storeId});
  final SpotsRepository repo;
  final String storeId;
  @override
  State<_StoreTeaser> createState() => _StoreTeaserState();
}

class _StoreTeaserState extends State<_StoreTeaser> {
  late final Future<(Store?, List<Product>)> data = () async {
    final results = await Future.wait([
      widget.repo.store(widget.storeId),
      widget.repo.products(widget.storeId),
    ]);
    return (
      results[0] as Store?,
      (results[1] as List<Product>).where((p) => p.active).toList(),
    );
  }();

  @override
  Widget build(BuildContext context) => FutureBuilder<(Store?, List<Product>)>(
    future: data,
    builder: (context, snapshot) {
      final store = snapshot.data?.$1;
      if (store == null) return const SizedBox.shrink();
      final products = snapshot.data!.$2;
      return Bouncy(
        scale: .97,
        onTap: () => openStore(context, widget.repo, store.id, initial: store),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4D6),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFFFE19A), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SpotIcon(Glyph.bag, size: 30, accent: yellow),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Belanja di sini', style: display(20)),
                        Text(
                          store.onlineOrders
                              ? '${products.length} produk · bisa pesan online'
                              : 'Beli di lokasi',
                          style: small.copyWith(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  Transform.rotate(
                    angle: 3.1416,
                    child: const SpotIcon(Glyph.back, size: 20, tint: false),
                  ),
                ],
              ),
              if (products.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final p in products.take(3))
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: ProductImage(
                                    product: p,
                                    repo: widget.repo,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                rupiah(p.price),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                  color: Color(0xFFD9541E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
