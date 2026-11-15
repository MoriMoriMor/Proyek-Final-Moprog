import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'game.dart';
import 'profile_page.dart';
import 'share.dart';
import 'route_page.dart';
import 'spot.dart';
import 'spot_views.dart';
import 'spots_repository.dart';
import 'ui/motion.dart';
import 'ui/piko.dart';
import 'ui/spot_icons.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

/// Feed vertikal layar penuh. Geser ke atas untuk spot berikutnya.
class ReelsView extends StatefulWidget {
  const ReelsView({
    super.key,
    required this.spots,
    required this.repo,
    required this.onChanged,
    required this.onOpenStore,
    this.initialIndex = 0,
    this.loading = false,
    this.bottomInset = 0,
  });

  final List<Spot> spots;
  final SpotsRepository repo;
  final VoidCallback onChanged;
  final ValueChanged<String> onOpenStore;
  final int initialIndex;
  final bool loading;
  final double bottomInset;

  @override
  State<ReelsView> createState() => _ReelsViewState();
}

class _ReelsViewState extends State<ReelsView> {
  late final controller = PageController(initialPage: widget.initialIndex);
  late int current = widget.initialIndex;
  bool hint = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => hint = false);
    });
    GameState.instance.track('reel');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading && widget.spots.isEmpty) {
      return const ColoredBox(
        color: ink,
        child: Center(
          child: Piko(size: 120, mood: PikoMood.wow, kind: MascotKind.pino),
        ),
      );
    }
    if (widget.spots.isEmpty) {
      return const ColoredBox(
        color: ink,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Piko(size: 120, mood: PikoMood.sleepy),
              SizedBox(height: 14),
              Text(
                'Belum ada reels.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: controller,
            scrollDirection: Axis.vertical,
            itemCount: widget.spots.length,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() {
                current = i;
                hint = false;
              });
              GameState.instance.track('reel');
            },
            itemBuilder: (context, i) => ReelPage(
              key: ValueKey(widget.spots[i].id),
              spot: widget.spots[i],
              repo: widget.repo,
              active: i == current,
              onChanged: widget.onChanged,
              onOpenStore: widget.onOpenStore,
              bottomInset: widget.bottomInset,
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 20,
            child: IgnorePointer(
              child: Text('Reels', style: display(28, color: Colors.white)),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            right: 16,
            child: StreakChip(dark: true, onTap: () => openQuests(context)),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: hint ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: const Align(
                alignment: Alignment(0, .25),
                child: _SwipeHint(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeHint extends StatefulWidget {
  const _SwipeHint();
  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: controller,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, 10 - controller.value * 20),
            child: child,
          ),
          child: Transform.rotate(
            angle: 1.5708,
            child: const SpotIcon(
              Glyph.back,
              size: 34,
              color: Colors.white,
              tint: false,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Geser ke atas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class ReelPage extends StatefulWidget {
  const ReelPage({
    super.key,
    required this.spot,
    required this.repo,
    required this.active,
    required this.onChanged,
    required this.onOpenStore,
    this.bottomInset = 0,
  });
  final Spot spot;
  final SpotsRepository repo;
  final bool active;
  final VoidCallback onChanged;
  final ValueChanged<String> onOpenStore;
  final double bottomInset;

  @override
  State<ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<ReelPage> with TickerProviderStateMixin {
  static const slide = Duration(milliseconds: 5200);
  late final reactions = Reactions(widget.spot);
  late final progress = AnimationController(vsync: this, duration: slide);
  late final heart = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  int index = 0;
  bool paused = false, expanded = false;

  int get count => widget.spot.media.isEmpty ? 1 : widget.spot.media.length;

  @override
  void initState() {
    super.initState();
    progress.addStatusListener((status) {
      if (status == AnimationStatus.completed) next(loop: true);
    });
    if (widget.active) progress.forward();
  }

  @override
  void didUpdateWidget(ReelPage old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      progress.forward(from: 0);
    } else if (!widget.active && old.active) {
      progress.stop();
      setState(() => index = 0);
    }
  }

  @override
  void dispose() {
    progress.dispose();
    heart.dispose();
    super.dispose();
  }

  void next({bool loop = false}) {
    setState(() => index = index + 1 < count ? index + 1 : (loop ? 0 : index));
    progress.forward(from: 0);
  }

  void previous() {
    setState(() => index = index > 0 ? index - 1 : 0);
    progress.forward(from: 0);
  }

  Future<void> like({bool fromDoubleTap = false}) async {
    if (fromDoubleTap) {
      if (!calm(context)) heart.forward(from: 0);
      HapticFeedback.mediumImpact();
    }
    final was = reactions.liked;
    final ok = await reactions.toggle(
      context,
      widget.repo,
      widget.spot.id,
      'like',
      value: fromDoubleTap ? true : null,
    );
    if (ok && !was && reactions.liked) GameState.instance.track('like');
  }

  Future<void> save() async {
    final was = reactions.saved;
    final ok = await reactions.toggle(
      context,
      widget.repo,
      widget.spot.id,
      'save',
    );
    if (ok && !was) GameState.instance.track('save');
    if (ok) widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final spot = widget.spot;
    final category = categoryOf(spot.category);
    final media = spot.media.isEmpty
        ? null
        : spot.media[index.clamp(0, spot.media.length - 1)];
    final bottom = widget.bottomInset + 18;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: () => like(fromDoubleTap: true),
      onLongPressStart: (_) {
        setState(() => paused = true);
        progress.stop();
      },
      onLongPressEnd: (_) {
        setState(() => paused = false);
        progress.forward();
      },
      onTapUp: (details) {
        final width = context.size?.width ?? 1;
        details.localPosition.dx < width * .3 ? previous() : next();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: KeyedSubtree(
              key: ValueKey('${spot.id}-$index'),
              child: media == null || media.path.startsWith('demo:')
                  ? _KenBurns(
                      active: widget.active && !paused,
                      child: DemoCover(
                        seed: media?.path ?? 'demo:${spot.category}:${spot.id}',
                      ),
                    )
                  : media.type == 'video'
                  ? _ReelVideo(
                      url: widget.repo.publicMediaUrl(media.path),
                      playing: widget.active && !paused,
                    )
                  : _KenBurns(
                      active: widget.active && !paused,
                      child: Image.network(
                        widget.repo.publicMediaUrl(media.path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            DemoCover(seed: 'demo:${spot.category}:${spot.id}'),
                      ),
                    ),
            ),
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, .18, .55, 1],
                  colors: [
                    Color(0x88000000),
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0xCC0B1233),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 56,
            left: 14,
            right: 14,
            child: Row(
              children: [
                for (var i = 0; i < count; i++)
                  Expanded(
                    child: Container(
                      height: 3.5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.centerLeft,
                      child: i < index
                          ? Container(color: Colors.white)
                          : i == index
                          ? AnimatedBuilder(
                              animation: progress,
                              builder: (_, _) => FractionallySizedBox(
                                widthFactor: progress.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: heart,
                builder: (_, _) {
                  final t = heart.value;
                  if (t == 0 || t == 1) return const SizedBox.shrink();
                  final grow = Curves.elasticOut.transform(
                    (t * 1.6).clamp(0, 1),
                  );
                  return Opacity(
                    opacity: t < .7 ? 1 : 1 - (t - .7) / .3,
                    child: CustomPaint(
                      painter: BurstPainter(t, const [
                        coral,
                        yellow,
                        Colors.white,
                      ], count: 14),
                      child: Center(
                        child: Transform.rotate(
                          angle: -.15,
                          child: Transform.scale(
                            scale: grow,
                            child: const SpotIcon(
                              Glyph.heart,
                              size: 130,
                              color: Colors.white,
                              accent: coral,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (paused)
            const Center(
              child: IgnorePointer(
                child: SpotIcon(
                  Glyph.play,
                  size: 72,
                  color: Colors.white,
                  accent: Color(0x55000000),
                ),
              ),
            ),
          Positioned(
            right: 10,
            bottom: bottom + 6,
            child: ListenableBuilder(
              listenable: reactions,
              builder: (context, _) => Column(
                children: [
                  _RailButton(
                    label: spot.author,
                    child: GestureDetector(
                      onTap: () =>
                          openProfile(context, widget.repo, spot.ownerId),
                      child: Avatar(
                        spot.author,
                        size: 46,
                        url: widget.repo.avatarUrl(spot.authorAvatar),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _RailToggle(
                    glyph: Glyph.heart,
                    active: reactions.liked,
                    color: coral,
                    count: compact(reactions.likes),
                    label: 'Suka',
                    onTap: like,
                  ),
                  _RailToggle(
                    glyph: Glyph.chat,
                    active: false,
                    color: piko,
                    count: compact(spot.comments),
                    label: 'Komentar',
                    onTap: () =>
                        openSpot(context, spot, widget.repo, widget.onChanged),
                  ),
                  _RailToggle(
                    glyph: Glyph.bookmark,
                    active: reactions.saved,
                    color: yellow,
                    count: 'Simpan',
                    label: 'Simpan',
                    onTap: save,
                  ),
                  _RailToggle(
                    glyph: Glyph.share,
                    active: false,
                    color: mint,
                    count: 'Bagikan',
                    label: 'Bagikan',
                    onTap: () => shareSpot(context, widget.repo, spot),
                  ),
                  _RailToggle(
                    glyph: Glyph.route,
                    active: false,
                    color: sky,
                    count: 'Rute',
                    label: 'Buka rute',
                    onTap: () => openRoute(context, spot),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 84,
            bottom: bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (spot.storeId != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShopPill(
                      onTap: () => widget.onOpenStore(spot.storeId!),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Mascot(kind: category.mascot, size: 52, wave: true),
                    const SizedBox(width: 6),
                    CategorySticker(category),
                    const SizedBox(width: 10),
                    if (spot.distanceKm != null)
                      Pill(
                        color: Colors.white.withValues(alpha: .2),
                        child: Text(
                          distanceLabel(spot.distanceKm!),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  spot.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: display(28, color: Colors.white, height: 1.05),
                ),
                const SizedBox(height: 6),
                Text(
                  '${spot.author} · ${spot.city}${spot.rating == null ? '' : ' · ${spot.rating!.toStringAsFixed(1)}/5'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => setState(() => expanded = !expanded),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    alignment: Alignment.topLeft,
                    child: Text(
                      spot.story,
                      maxLines: expanded ? 8 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .88),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
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

class _ShopPill extends StatefulWidget {
  const _ShopPill({required this.onTap});
  final VoidCallback onTap;
  @override
  State<_ShopPill> createState() => _ShopPillState();
}

class _ShopPillState extends State<_ShopPill>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Bouncy(
    onTap: widget.onTap,
    child: AnimatedBuilder(
      animation: controller,
      builder: (_, child) {
        final t = controller.value;
        final wiggle = t < .2 ? (t < .1 ? t : .2 - t) * 1.2 : 0.0;
        return Transform.rotate(angle: wiggle, child: child);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 7, 14, 7),
        decoration: BoxDecoration(
          color: yellow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ink, width: 2),
          boxShadow: const [BoxShadow(color: ink, offset: Offset(0, 3))],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpotIcon(Glyph.bag, size: 20, accent: Colors.white),
            SizedBox(width: 6),
            Text(
              'Belanja di sini',
              style: TextStyle(fontWeight: FontWeight.w900, color: ink),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RailButton extends StatelessWidget {
  const _RailButton({required this.child, required this.label});
  final Widget child;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(label: label, child: child);
}

class _RailToggle extends StatelessWidget {
  const _RailToggle({
    required this.glyph,
    required this.active,
    required this.color,
    required this.count,
    required this.label,
    required this.onTap,
  });
  final Glyph glyph;
  final bool active;
  final Color color;
  final String count, label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      children: [
        PopToggle(
          active: active,
          label: label,
          size: 52,
          colors: [color, yellow, Colors.white],
          onTap: onTap,
          builder: (on) => SpotIcon(
            glyph,
            size: 34,
            color: Colors.white,
            accent: on ? color : Colors.black.withValues(alpha: .35),
          ),
        ),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            shadows: [Shadow(color: Color(0x88000000), blurRadius: 6)],
          ),
        ),
      ],
    ),
  );
}

/// Foto yang perlahan membesar seperti efek Ken Burns.
class _KenBurns extends StatefulWidget {
  const _KenBurns({required this.child, required this.active});
  final Widget child;
  final bool active;
  @override
  State<_KenBurns> createState() => _KenBurnsState();
}

class _KenBurnsState extends State<_KenBurns>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) controller.forward();
  }

  @override
  void didUpdateWidget(_KenBurns old) {
    super.didUpdateWidget(old);
    widget.active ? controller.forward() : controller.stop();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
    child: AnimatedBuilder(
      animation: controller,
      child: SizedBox.expand(child: widget.child),
      builder: (_, child) => Transform.scale(
        scale: 1 + Curves.easeOut.transform(controller.value) * .14,
        alignment: const Alignment(.2, -.1),
        child: child,
      ),
    ),
  );
}

class _ReelVideo extends StatefulWidget {
  const _ReelVideo({required this.url, required this.playing});
  final String url;
  final bool playing;
  @override
  State<_ReelVideo> createState() => _ReelVideoState();
}

class _ReelVideoState extends State<_ReelVideo> {
  late final VideoPlayerController controller;
  bool ready = false;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    unawaited(
      controller
          .initialize()
          .then((_) async {
            await controller.setLooping(true);
            await controller.setVolume(0);
            if (!mounted) return;
            setState(() => ready = true);
            if (widget.playing) await controller.play();
          })
          .catchError((Object _) {}),
    );
  }

  @override
  void didUpdateWidget(_ReelVideo old) {
    super.didUpdateWidget(old);
    if (!ready) return;
    widget.playing ? controller.play() : controller.pause();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: ready
        ? FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          )
        : const Center(child: CircularProgressIndicator(color: Colors.white)),
  );
}
