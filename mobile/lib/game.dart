import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'spots_repository.dart';
import 'ui/motion.dart';
import 'ui/piko.dart';
import 'ui/spot_icons.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

final rootNavigator = GlobalKey<NavigatorState>();

/// Diisi oleh share.dart agar game.dart tidak bergantung balik ke sana.
void Function(BuildContext context)? onShareAchievement;

class Quest {
  const Quest(
    this.key,
    this.label,
    this.target,
    this.xp,
    this.glyph,
    this.color,
  );
  final String key, label;
  final int target, xp;
  final Glyph glyph;
  final Color color;
}

const quests = [
  Quest('reel', 'Tonton 5 reels', 5, 20, Glyph.play, grape),
  Quest('like', 'Kasih 3 suka', 3, 15, Glyph.heart, coral),
  Quest('save', 'Simpan 1 spot', 1, 10, Glyph.bookmark, caramel),
  Quest('comment', 'Tulis 1 komentar', 1, 15, Glyph.chat, piko),
  Quest('share', 'Bagikan 1 spot', 1, 25, Glyph.share, mint),
];

const _xpFor = {
  'reel': 1,
  'like': 2,
  'save': 3,
  'rate': 3,
  'comment': 5,
  'post': 30,
  'order': 20,
  'store': 25,
  'share': 5,
  'invited': 30,
};

/// Streak, XP, level, dan misi harian. Disimpan di perangkat.
class GameState extends ChangeNotifier {
  GameState._();
  static final instance = GameState._();

  static const perLevel = 120;

  SharedPreferences? _prefs;
  SpotsRepository? _repo;
  int xp = 0, streak = 0;
  String _day = '';
  final progress = <String, int>{};
  final claimed = <String>{};
  List<String> activeDays = [];
  bool streakGrewToday = false;

  void bind(SpotsRepository repo) {
    _repo = repo;
  }

  bool get onboarded => _prefs?.getBool('onboarded') ?? false;
  Future<void> markOnboarded() async => _prefs?.setBool('onboarded', true);

  /// Hadiah sekali untuk orang yang datang lewat kode undangan.
  bool claimInvite(String code) {
    if (_prefs?.getString('invite') != null) return false;
    _prefs?.setString('invite', code);
    track('invited');
    return true;
  }

  int get level => xp ~/ perLevel + 1;
  double get levelProgress => (xp % perLevel) / perLevel;
  int get questsDone => quests.where((q) => claimed.contains(q.key)).length;

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null;
    }
    final p = _prefs;
    xp = p?.getInt('xp') ?? 0;
    streak = p?.getInt('streak') ?? 0;
    activeDays = p?.getStringList('days') ?? [];
    final today = _key(DateTime.now());
    final last = p?.getString('last_day');
    final yesterday = _key(DateTime.now().subtract(const Duration(days: 1)));
    if (last != today) {
      streak = last == yesterday ? streak + 1 : 1;
      streakGrewToday = true;
      activeDays = [...activeDays.where((d) => d != today), today];
      if (activeDays.length > 7) {
        activeDays = activeDays.sublist(activeDays.length - 7);
      }
      await p?.setString('last_day', today);
      await p?.setInt('streak', streak);
      await p?.setStringList('days', activeDays);
    }
    _day = p?.getString('quest_day') ?? '';
    if (_day != today) {
      _day = today;
      progress.clear();
      claimed.clear();
      await p?.setString('quest_day', today);
      for (final q in quests) {
        await p?.remove('q_${q.key}');
        await p?.remove('c_${q.key}');
      }
    } else {
      for (final q in quests) {
        progress[q.key] = p?.getInt('q_${q.key}') ?? 0;
        if (p?.getBool('c_${q.key}') ?? false) claimed.add(q.key);
      }
    }
    notifyListeners();
  }

  /// Sinkronkan XP, streak, dan progres misi harian dari server saat masuk.
  Future<void> syncFromServer() async {
    final repo = _repo;
    if (repo == null || repo.userId == null) return;
    final today = _key(DateTime.now());
    try {
      final state = await repo.fetchGameState(today);
      if (state == null) return;
      _day = today;
      xp = state.xp;
      if (state.streak > streak) streak = state.streak;
      progress.clear();
      claimed.clear();
      for (final q in quests) {
        final item = state.quests[q.key];
        final val = item?.progress ?? 0;
        final done = item?.claimed ?? false;
        progress[q.key] = val;
        if (done) claimed.add(q.key);
        await _prefs?.setInt('q_${q.key}', val);
        await _prefs?.setBool('c_${q.key}', done);
      }
      await _prefs?.setString('quest_day', today);
      await _prefs?.setInt('xp', xp);
      await _prefs?.setInt('streak', streak);
      notifyListeners();
    } catch (_) {}
  }

  /// Catat aksi, beri XP, dan rayakan jika misi atau level tercapai.
  void track(String action) {
    final today = _key(DateTime.now());
    if (_day != today) {
      _day = today;
      progress.clear();
      claimed.clear();
      _prefs?.setString('quest_day', today);
    }
    final before = level;
    var gained = _xpFor[action] ?? 1;
    Quest? finished;
    for (final q in quests) {
      if (q.key != action || claimed.contains(q.key)) continue;
      final value = (progress[q.key] ?? 0) + 1;
      progress[q.key] = value;
      _prefs?.setInt('q_${q.key}', value);
      if (value >= q.target) {
        claimed.add(q.key);
        _prefs?.setBool('c_${q.key}', true);
        gained += q.xp;
        finished = q;
      }
    }
    xp += gained;
    _prefs?.setInt('xp', xp);
    notifyListeners();
    if (action != 'reel' || finished != null) _toast('+$gained XP');
    if (finished != null) _questBanner(finished);
    if (level > before) {
      Future.delayed(const Duration(milliseconds: 900), () => _levelUp(level));
    }
    unawaited(_syncAction(action, today));
  }

  Future<void> _syncAction(String action, String day) async {
    final repo = _repo;
    if (repo == null || repo.userId == null) return;
    try {
      final res = await repo.recordGameAction(action, day);
      if (res == null) return;
      if (res.xp != xp) {
        xp = res.xp;
        await _prefs?.setInt('xp', xp);
        notifyListeners();
      }
    } catch (_) {}
  }

  OverlayState? get _overlay => rootNavigator.currentState?.overlay;

  OverlayEntry? _toastEntry;
  void _toast(String text) {
    final overlay = _overlay;
    if (overlay == null) return;
    _toastEntry?.remove();
    final entry = OverlayEntry(builder: (_) => _XpToast(text: text));
    _toastEntry = entry;
    overlay.insert(entry);
    Timer(const Duration(milliseconds: 1300), () {
      if (_toastEntry == entry) _toastEntry = null;
      if (entry.mounted) entry.remove();
    });
  }

  void _questBanner(Quest quest) {
    final overlay = _overlay;
    if (overlay == null) return;
    HapticFeedback.mediumImpact();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _QuestBanner(quest: quest, onDone: () => entry.remove()),
    );
    overlay.insert(entry);
  }

  void _levelUp(int value) {
    final context = rootNavigator.currentContext;
    if (context == null) return;
    HapticFeedback.heavyImpact();
    showCelebration(
      context,
      title: 'Level $value!',
      subtitle: 'Makin jago nyari spot.',
      color: grape,
      badge: const MascotCrew(
        kinds: [MascotKind.cici, MascotKind.piko, MascotKind.bobi],
        size: 96,
        mood: MascotMood.laugh,
      ),
      actionLabel: 'Pamerin ke teman',
      onAction: () {
        final ctx = rootNavigator.currentContext;
        if (ctx != null) onShareAchievement?.call(ctx);
      },
    );
  }
}

Future<void> showCelebration(
  BuildContext context, {
  required String title,
  required String subtitle,
  Color color = piko,
  Widget? badge,
  String? actionLabel,
  VoidCallback? onAction,
}) => Navigator.of(context, rootNavigator: true).push(
  PageRouteBuilder<void>(
    opaque: false,
    barrierDismissible: true,
    pageBuilder: (_, _, _) => _Celebration(
      title: title,
      subtitle: subtitle,
      color: color,
      badge: badge,
      actionLabel: actionLabel,
      onAction: onAction,
    ),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  ),
);

class _Celebration extends StatefulWidget {
  const _Celebration({
    required this.title,
    required this.subtitle,
    required this.color,
    this.badge,
    this.actionLabel,
    this.onAction,
  });
  final String title, subtitle;
  final Color color;
  final Widget? badge;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration> {
  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration(milliseconds: widget.onAction == null ? 2600 : 5200),
      () {
        if (mounted) Navigator.maybePop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.maybePop(context),
    child: Material(
      color: widget.color.withValues(alpha: .96),
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child:
                        widget.badge ??
                        const Piko(size: 170, mood: PikoMood.wow),
                  ),
                  const SizedBox(height: 22),
                  Rise(
                    index: 2,
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: display(44, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Rise(
                    index: 3,
                    child: Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  if (widget.onAction != null) ...[
                    const SizedBox(height: 26),
                    Rise(
                      index: 4,
                      child: Chunky(
                        color: ink,
                        edge: Colors.black,
                        onTap: () {
                          Navigator.maybePop(context);
                          widget.onAction!();
                        },
                        child: Text(widget.actionLabel ?? 'Bagikan'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Positioned.fill(child: IgnorePointer(child: Confetti())),
        ],
      ),
    ),
  );
}

class _XpToast extends StatelessWidget {
  const _XpToast({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    bottom: MediaQuery.paddingOf(context).bottom + 108,
    child: IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1250),
          builder: (_, t, child) {
            final rise = Curves.easeOutBack.transform(math.min(1, t * 2.5));
            final fade = t < .75 ? 1.0 : 1 - (t - .75) / .25;
            return Opacity(
              opacity: fade.clamp(0, 1),
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - rise) - t * 18),
                child: Transform.scale(scale: .6 + rise * .4, child: child),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
            decoration: BoxDecoration(
              color: yellow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ink, width: 2),
              boxShadow: const [BoxShadow(color: ink, offset: Offset(0, 3))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SpotIcon(Glyph.sparkle, size: 18, accent: Colors.white),
                const SizedBox(width: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontFamily: fontBody,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: ink,
                    decoration: TextDecoration.none,
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

class _QuestBanner extends StatefulWidget {
  const _QuestBanner({required this.quest, required this.onDone});
  final Quest quest;
  final VoidCallback onDone;
  @override
  State<_QuestBanner> createState() => _QuestBannerState();
}

class _QuestBannerState extends State<_QuestBanner>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned(
    left: 16,
    right: 16,
    top: MediaQuery.paddingOf(context).top + 10,
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        final inT = Curves.elasticOut.transform(math.min(1, t * 3));
        final out = t > .85 ? (t - .85) / .15 : 0.0;
        return Transform.translate(
          offset: Offset(0, -120 * (1 - inT) - 120 * out),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 18, 10),
              decoration: BoxDecoration(
                color: widget.quest.color,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: edgeOf(widget.quest.color),
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Mascot(
                    kind: MascotKind.cici,
                    size: 54,
                    mood: MascotMood.laugh,
                    wave: true,
                    interactive: false,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Misi beres!',
                          style: display(20, color: Colors.white),
                        ),
                        Text(
                          '${widget.quest.label} · +${widget.quest.xp} XP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
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

/// Chip api streak di bagian atas layar.
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.onTap, this.dark = false});
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: GameState.instance,
    builder: (context, _) {
      final game = GameState.instance;
      return Semantics(
        button: true,
        label: 'Streak ${game.streak} hari',
        child: Bouncy(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withValues(alpha: .16)
                  : const Color(0xFFFFF1E4),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreakFlame(streak: game.streak, size: 22),
                const SizedBox(width: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: game.streak.toDouble()),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => Text(
                    '${v.round()}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: dark ? Colors.white : const Color(0xFFD9541E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Tingkat api streak. Makin lama streak, apinya berevolusi.
class FlameTier {
  const FlameTier(
    this.name,
    this.from,
    this.stroke,
    this.accent,
    this.glow,
    this.sparkles,
    this.scale,
  );
  final String name;
  final int from;
  final Color stroke, accent, glow;
  final int sparkles;
  final double scale;
}

const flameTiers = [
  FlameTier(
    'Padam',
    0,
    Color(0xFF9AA3BD),
    Color(0xFFE2E6F5),
    Colors.transparent,
    0,
    .9,
  ),
  FlameTier(
    'Percikan',
    1,
    Color(0xFFD9541E),
    Color(0xFFFFC56B),
    Colors.transparent,
    0,
    .9,
  ),
  FlameTier(
    'Api',
    3,
    Color(0xFFC8321A),
    Color(0xFFFF8A3D),
    Color(0x33FF6A2B),
    0,
    1,
  ),
  FlameTier(
    'Api Biru',
    7,
    Color(0xFF1F4FD1),
    Color(0xFF7FC8FF),
    Color(0x553B8BFF),
    1,
    1.06,
  ),
  FlameTier(
    'Api Ungu',
    14,
    Color(0xFF5B2DC2),
    Color(0xFFC9A6FF),
    Color(0x558B5CF6),
    2,
    1.1,
  ),
  FlameTier(
    'Api Emas',
    30,
    Color(0xFFA86A05),
    Color(0xFFFFE066),
    Color(0x66FFC83D),
    3,
    1.15,
  ),
  FlameTier(
    'Api Legenda',
    100,
    Color(0xFFD9265B),
    Color(0xFFFFFFFF),
    Color(0x66FF4FA0),
    4,
    1.2,
  ),
];

FlameTier flameTierOf(int streak) => flameTiers.lastWhere(
  (t) => streak >= t.from,
  orElse: () => flameTiers.first,
);

FlameTier? nextFlameTier(int streak) {
  for (final t in flameTiers) {
    if (t.from > streak) return t;
  }
  return null;
}

/// Api streak yang menyala, bergoyang, dan berganti wujud sesuai tingkat.
class StreakFlame extends StatefulWidget {
  const StreakFlame({super.key, required this.streak, this.size = 24});
  final int streak;
  final double size;
  @override
  State<StreakFlame> createState() => _StreakFlameState();
}

class _StreakFlameState extends State<StreakFlame>
    with SingleTickerProviderStateMixin {
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
  Widget build(BuildContext context) {
    final tier = flameTierOf(widget.streak);
    final size = widget.size * tier.scale;
    final legend = tier.from >= 100;
    return SizedBox.square(
      dimension: widget.size * 1.25,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = calm(context) ? 0.0 : controller.value;
          final wave = math.sin(t * math.pi * 2);
          final accent = legend
              ? HSVColor.fromAHSV(1, (t * 360) % 360, .55, 1).toColor()
              : tier.accent;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (tier.glow != Colors.transparent)
                Container(
                  width: size * (1 + wave.abs() * .15),
                  height: size * (1 + wave.abs() * .15),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: tier.glow,
                        blurRadius: size * .6,
                        spreadRadius: size * .05,
                      ),
                    ],
                  ),
                ),
              CustomPaint(
                size: Size.square(size),
                painter: ApoPainter(
                  tier: tier,
                  inner: accent,
                  t: t,
                  face: widget.size >= 26,
                ),
              ),
              for (var i = 0; i < tier.sparkles; i++)
                Positioned(
                  left:
                      widget.size * 1.25 / 2 +
                      math.cos(
                            t * math.pi * 2 + i * math.pi * 2 / tier.sparkles,
                          ) *
                          size *
                          .62 -
                      size * .12,
                  top:
                      widget.size * 1.25 / 2 +
                      math.sin(
                            t * math.pi * 2 + i * math.pi * 2 / tier.sparkles,
                          ) *
                          size *
                          .5 -
                      size * .12,
                  child: SpotIcon(
                    Glyph.sparkle,
                    size: size * .26,
                    color: tier.stroke,
                    accent: tier.accent,
                    tint: false,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class XpBar extends StatelessWidget {
  const XpBar({super.key, this.height = 14, this.dark = false});
  final double height;
  final bool dark;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: GameState.instance,
    builder: (context, _) => LayoutBuilder(
      builder: (context, box) => Container(
        height: height,
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withValues(alpha: .22)
              : const Color(0xFFE9ECF7),
          borderRadius: BorderRadius.circular(height),
        ),
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: GameState.instance.levelProgress),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
          builder: (_, v, _) => Container(
            width: math.max(height, box.maxWidth * v.clamp(0, 1)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [yellow, caramel]),
              borderRadius: BorderRadius.circular(height),
            ),
            alignment: Alignment.topCenter,
            padding: EdgeInsets.fromLTRB(
              height * .4,
              height * .2,
              height * .4,
              0,
            ),
            child: Container(
              height: height * .22,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Kartu misi harian ringkas untuk Beranda.
class QuestCard extends StatelessWidget {
  const QuestCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: GameState.instance,
    builder: (context, _) {
      final game = GameState.instance;
      final next = quests.firstWhere(
        (q) => !game.claimed.contains(q.key),
        orElse: () => quests.first,
      );
      final allDone = game.questsDone == quests.length;
      return Bouncy(
        scale: .97,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: line, width: 2),
            boxShadow: const [BoxShadow(color: line, offset: Offset(0, 5))],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: grape,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: edgeOf(grape), offset: const Offset(0, 4)),
                  ],
                ),
                child: Text(
                  '${game.level}',
                  style: display(28, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Level ${game.level}',
                          style: title.copyWith(fontSize: 16),
                        ),
                        const Spacer(),
                        Text(
                          '${game.xp % GameState.perLevel}/${GameState.perLevel} XP',
                          style: small.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    const XpBar(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SpotIcon(next.glyph, size: 16, accent: next.color),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            allDone
                                ? 'Semua misi beres. Gokil!'
                                : '${next.label} · ${game.progress[next.key] ?? 0}/${next.target}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: small.copyWith(color: ink, fontSize: 12.5),
                          ),
                        ),
                        Pill(
                          color: const Color(0xFFF1ECFF),
                          child: Text(
                            '${game.questsDone}/${quests.length}',
                            style: const TextStyle(color: grape),
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
    },
  );
}

void openQuests(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => const _QuestSheet(),
);

class _QuestSheet extends StatelessWidget {
  const _QuestSheet();
  static const _days = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: GameState.instance,
    builder: (context, _) {
      final game = GameState.instance;
      final today = DateTime.now();
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      StreakFlame(streak: game.streak, size: 60),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${game.streak} hari', style: display(34)),
                            Text(
                              flameTierOf(game.streak).name,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: flameTierOf(game.streak).stroke,
                              ),
                            ),
                            Text(
                              nextFlameTier(game.streak) == null
                                  ? 'Api tertinggi. Kamu legenda!'
                                  : '${nextFlameTier(game.streak)!.from - game.streak} hari lagi jadi ${nextFlameTier(game.streak)!.name}',
                              style: small,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final tier in flameTiers.skip(1))
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Opacity(
                              opacity: game.streak >= tier.from ? 1 : .35,
                              child: Column(
                                children: [
                                  StreakFlame(streak: tier.from, size: 30),
                                  Text(
                                    '${tier.from} hari',
                                    style: small.copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final day = today.subtract(Duration(days: 6 - i));
                      final on = game.activeDays.contains(GameState._key(day));
                      final isToday = i == 6;
                      return Column(
                        children: [
                          Text(
                            _days[day.weekday - 1],
                            style: small.copyWith(
                              color: isToday ? ink : muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Rise(
                            index: i,
                            from: 10,
                            child: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: on ? const Color(0xFFFFE3CC) : pale,
                                shape: BoxShape.circle,
                                border: isToday
                                    ? Border.all(
                                        color: const Color(0xFFD9541E),
                                        width: 2.5,
                                      )
                                    : null,
                              ),
                              child: on
                                  ? const SpotIcon(
                                      Glyph.fire,
                                      size: 22,
                                      color: Color(0xFFD9541E),
                                      accent: Color(0xFFFFB648),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: 22),
                  Text('Misi hari ini', style: display(24)),
                  const SizedBox(height: 12),
                  for (final (i, q) in quests.indexed)
                    Rise(
                      index: i + 2,
                      child: _QuestRow(
                        quest: q,
                        value: game.progress[q.key] ?? 0,
                        done: game.claimed.contains(q.key),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.quest,
    required this.value,
    required this.done,
  });
  final Quest quest;
  final int value;
  final bool done;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: done ? quest.color.withValues(alpha: .12) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: done ? quest.color : line, width: 2),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: quest.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SpotIcon(
            quest.glyph,
            size: 24,
            color: Colors.white,
            accent: edgeOf(quest.color),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(quest.label, style: title.copyWith(fontSize: 15)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (value / quest.target).clamp(0, 1),
                  minHeight: 9,
                  color: quest.color,
                  backgroundColor: const Color(0xFFE9ECF7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        done
            ? const SpotIcon(
                Glyph.star,
                size: 28,
                color: Color(0xFFB77A0E),
                accent: yellow,
              )
            : Text(
                '+${quest.xp}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: edgeOf(quest.color),
                ),
              ),
      ],
    ),
  );
}

/// Apo, si api streak. Bentuknya berkobar, wajahnya ikut tingkat streak.
class ApoPainter extends CustomPainter {
  ApoPainter({
    required this.tier,
    required this.inner,
    required this.t,
    this.face = true,
  });
  final FlameTier tier;
  final Color inner;
  final double t;
  final bool face;

  static const ink = Color(0xFF3B3A4A);

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide / 120;
    canvas.translate(
      (size.width - 120 * unit) / 2,
      (size.height - 120 * unit) / 2,
    );
    canvas.scale(unit);
    final w = t * math.pi * 2;
    final sway = math.sin(w) * 6;
    final lick = math.sin(w * 2 + 1) * 4;
    final out = tier.from == 0;
    final body = out
        ? const Color(0xFFB9C0D6)
        : Color.lerp(tier.stroke, inner, .2)!;

    final flame = Path()
      ..moveTo(60 + sway, 4)
      ..cubicTo(74 + sway, 26, 104, 42, 104, 76)
      ..cubicTo(104, 102, 84, 118, 60, 118)
      ..cubicTo(36, 118, 16, 102, 16, 76)
      ..cubicTo(16, 58, 26, 46, 34 + lick, 34)
      ..cubicTo(36, 48, 42, 56, 48, 58)
      ..cubicTo(44, 36, 50, 18, 60 + sway, 4)
      ..close();
    canvas.drawPath(flame, Paint()..color = body);
    final b = flame.getBounds();
    canvas.save();
    canvas.clipPath(flame);
    canvas.drawRect(
      b,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .25),
            Colors.black.withValues(alpha: .14),
          ],
        ).createShader(b),
    );
    final core = Path()
      ..moveTo(60 - sway * .5, 44)
      ..cubicTo(72, 60, 88, 72, 88, 90)
      ..cubicTo(88, 106, 76, 116, 60, 116)
      ..cubicTo(44, 116, 32, 106, 32, 90)
      ..cubicTo(32, 72, 50, 62, 60 - sway * .5, 44)
      ..close();
    canvas.drawPath(
      core,
      Paint()
        ..color = out ? const Color(0xFFE2E6F5) : inner.withValues(alpha: .9),
    );
    canvas.restore();

    if (!face) return;
    const l = Offset(47, 84), r = Offset(73, 84);
    final blush = Paint()
      ..color = const Color(0xFFFF8E9B).withValues(alpha: .55);
    canvas.drawOval(
      Rect.fromCenter(center: l + const Offset(-9, 13), width: 12, height: 7),
      blush,
    );
    canvas.drawOval(
      Rect.fromCenter(center: r + const Offset(9, 13), width: 12, height: 7),
      blush,
    );

    Paint line([double width = 4]) => Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    final blink = t > .62 && t < .66;
    if (tier.from >= 100) {
      final glasses = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: l, width: 28, height: 18),
            const Radius.circular(6),
          ),
        )
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: r, width: 28, height: 18),
            const Radius.circular(6),
          ),
        );
      canvas.drawPath(glasses, Paint()..color = const Color(0xFF2E2D3A));
      canvas.drawLine(
        l + const Offset(13, -3),
        r - const Offset(13, 3),
        line(3.5),
      );
    } else if (out || blink) {
      for (final e in [l, r]) {
        canvas.drawPath(
          Path()
            ..moveTo(e.dx - 8, e.dy)
            ..quadraticBezierTo(e.dx, e.dy + 6, e.dx + 8, e.dy),
          line(),
        );
      }
    } else if (tier.from >= 30) {
      for (final e in [l, r]) {
        canvas.drawPath(
          Path()
            ..moveTo(e.dx - 8, e.dy + 3)
            ..quadraticBezierTo(e.dx, e.dy - 9, e.dx + 8, e.dy + 3),
          line(4.4),
        );
      }
    } else {
      for (final (e, side) in [(l, 1.0), (r, -1.0)]) {
        canvas.drawCircle(e, 10, Paint()..color = Colors.white);
        final p = e + Offset(side * 2.4, 1.2);
        canvas.drawOval(
          Rect.fromCenter(center: p, width: 10, height: 12),
          Paint()..color = ink,
        );
        canvas.drawCircle(
          p + const Offset(-2, -3),
          2.4,
          Paint()..color = Colors.white,
        );
      }
    }

    const m = Offset(60, 102);
    if (out) {
      canvas.drawLine(
        m - const Offset(5, 0),
        m + const Offset(5, 0),
        line(3.6),
      );
    } else {
      final big = tier.from >= 30;
      final d = big ? 10.0 : 7.0, half = big ? 9.0 : 7.0;
      final mouth = Path()
        ..moveTo(m.dx - half, m.dy - 2)
        ..quadraticBezierTo(m.dx, m.dy, m.dx + half, m.dy - 2)
        ..quadraticBezierTo(m.dx + 6, m.dy + d, m.dx, m.dy + d)
        ..quadraticBezierTo(m.dx - 6, m.dy + d, m.dx - half, m.dy - 2)
        ..close();
      canvas.drawPath(mouth, Paint()..color = ink);
      canvas.drawOval(
        Rect.fromCenter(center: m + Offset(0, d - 4), width: 7, height: 4),
        Paint()..color = const Color(0xFFFF6F86),
      );
    }
  }

  @override
  bool shouldRepaint(ApoPainter old) =>
      old.t != t || old.tier != tier || old.inner != inner;
}
