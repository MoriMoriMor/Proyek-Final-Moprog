import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ui/motion.dart';
import 'ui/piko.dart';
import 'ui/spot_icons.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

final rootNavigator = GlobalKey<NavigatorState>();

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
};

/// Streak, XP, level, dan misi harian. Disimpan di perangkat.
class GameState extends ChangeNotifier {
  GameState._();
  static final instance = GameState._();

  static const perLevel = 120;

  SharedPreferences? _prefs;
  int xp = 0, streak = 0;
  String _day = '';
  final progress = <String, int>{};
  final claimed = <String>{};
  List<String> activeDays = [];
  bool streakGrewToday = false;

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

  /// Catat aksi, beri XP, dan rayakan jika misi atau level tercapai.
  void track(String action) {
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
    );
  }
}

Future<void> showCelebration(
  BuildContext context, {
  required String title,
  required String subtitle,
  Color color = piko,
  Widget? badge,
}) => Navigator.of(context, rootNavigator: true).push(
  PageRouteBuilder<void>(
    opaque: false,
    barrierDismissible: true,
    pageBuilder: (_, _, _) => _Celebration(
      title: title,
      subtitle: subtitle,
      color: color,
      badge: badge,
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
  });
  final String title, subtitle;
  final Color color;
  final Widget? badge;
  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) Navigator.maybePop(context);
    });
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.maybePop(context),
    child: Material(
      color: widget.color.withValues(alpha: .96),
      child: Stack(
        children: [
          Center(
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
                      widget.badge ?? const Piko(size: 170, mood: PikoMood.wow),
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
              ],
            ),
          ),
          const Positioned.fill(child: Confetti()),
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
                  const Piko(size: 52, mood: PikoMood.wink, bounce: false),
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
                _Flame(size: 24, lit: game.streak > 0),
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

class _Flame extends StatefulWidget {
  const _Flame({required this.size, required this.lit});
  final double size;
  final bool lit;
  @override
  State<_Flame> createState() => _FlameState();
}

class _FlameState extends State<_Flame> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, child) => Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.diagonal3Values(
        1 - controller.value * .06,
        1 + (calm(context) ? 0 : controller.value * .1),
        1,
      ),
      child: child,
    ),
    child: SpotIcon(
      Glyph.fire,
      size: widget.size,
      color: widget.lit ? const Color(0xFFD9541E) : muted,
      accent: widget.lit ? const Color(0xFFFFB648) : line,
    ),
  );
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
                      const _Flame(size: 64, lit: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${game.streak} hari', style: display(34)),
                            const Text(
                              'Buka Spots tiap hari biar apinya nyala.',
                              style: small,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
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
