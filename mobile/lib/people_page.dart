import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game.dart';
import 'profile_page.dart';
import 'spot.dart';
import 'spot_views.dart';
import 'spots_repository.dart';
import 'ui/motion.dart';
import 'ui/piko.dart';
import 'ui/spot_icons.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

Future<void> openPeople(BuildContext context, SpotsRepository repo) =>
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PeoplePage(repo: repo)),
    );

/// Tombol ikuti yang langsung berubah dan memantul.
class FollowButton extends StatefulWidget {
  const FollowButton({
    super.key,
    required this.repo,
    required this.userId,
    required this.following,
    this.compact = false,
  });
  final SpotsRepository repo;
  final String userId;
  final bool following;
  final bool compact;

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  late bool on = widget.following;

  @override
  void didUpdateWidget(FollowButton old) {
    super.didUpdateWidget(old);
    if (old.following != widget.following) on = widget.following;
  }

  Future<void> toggle() async {
    if (widget.repo.userId == null) {
      await openAuth(context, widget.repo);
      if (widget.repo.userId == null) return;
    }
    final next = !on;
    HapticFeedback.mediumImpact();
    setState(() => on = next);
    try {
      await widget.repo.setFollow(widget.userId, next);
      if (next) GameState.instance.track('follow');
    } catch (e) {
      if (!mounted) return;
      setState(() => on = !next);
      message(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) => Bouncy(
    onTap: toggle,
    scale: .9,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 12 : 16,
        vertical: widget.compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: on ? Colors.white : coral,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: on ? line : edgeOf(coral), width: 2),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, a) =>
            ScaleTransition(scale: a, child: child),
        child: Text(
          on ? 'Mengikuti' : 'Ikuti',
          key: ValueKey(on),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: widget.compact ? 12.5 : 13.5,
            color: on ? ink : Colors.white,
          ),
        ),
      ),
    ),
  );
}

/// Cari teman dan lihat saran orang untuk diikuti.
class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key, required this.repo});
  final SpotsRepository repo;
  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  final query = TextEditingController();
  Timer? debounce;
  List<UserProfile> suggested = [], results = [];
  Set<String> following = {};
  bool loading = true, searching = false;

  @override
  void initState() {
    super.initState();
    loadSuggested();
  }

  @override
  void dispose() {
    debounce?.cancel();
    query.dispose();
    super.dispose();
  }

  Future<void> loadSuggested() async {
    try {
      final found = await widget.repo.suggestedUsers(limit: 12);
      if (mounted) setState(() => suggested = found);
    } catch (_) {
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void onChanged(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 300), () => search(value));
  }

  Future<void> search(String value) async {
    if (value.trim().length < 2) {
      setState(() => results = []);
      return;
    }
    setState(() => searching = true);
    try {
      final found = await widget.repo.searchUsers(value);
      final follows = await widget.repo.followingAmong([
        for (final p in found) p.id,
      ]);
      if (!mounted || query.text != value) return;
      setState(() {
        results = found;
        following = {...following, ...follows};
      });
    } catch (e) {
      if (mounted) message(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typing = query.text.trim().length >= 2;
    return Scaffold(
      backgroundColor: pale,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
              children: [
                Row(
                  children: [
                    GlassButton(
                      glyph: Glyph.back,
                      label: 'Kembali',
                      onTap: () => Navigator.maybePop(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Cari teman', style: display(30))),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: query,
                  autofocus: true,
                  onChanged: (v) {
                    setState(() {});
                    onChanged(v);
                  },
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    hintText: 'Nama atau @username',
                    fillColor: Colors.white,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(13),
                      child: SpotIcon(Glyph.search, size: 22, accent: yellow),
                    ),
                    suffixIcon: searching
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 18),
                if (typing) ...[
                  if (results.isEmpty && !searching)
                    const EmptyState(
                      title: 'Belum ketemu.\nCoba nama lain?',
                      mood: PikoMood.wow,
                      kind: MascotKind.pino,
                    )
                  else
                    for (final (i, person) in results.indexed)
                      Rise(index: i, from: 10, child: _personRow(person)),
                ] else ...[
                  Text('Saran untuk kamu', style: display(22)),
                  const SizedBox(height: 4),
                  const Text('Orang yang aktif berbagi spot.', style: small),
                  const SizedBox(height: 12),
                  if (loading)
                    const Shimmer(
                      child: Column(
                        children: [
                          Bone(height: 64),
                          SizedBox(height: 8),
                          Bone(height: 64),
                        ],
                      ),
                    )
                  else if (suggested.isEmpty)
                    const EmptyState(
                      title: 'Kamu sudah\nmengikuti semuanya!',
                      mood: PikoMood.love,
                      kind: MascotKind.cici,
                    )
                  else
                    for (final (i, person) in suggested.indexed)
                      Rise(index: i, from: 10, child: _personRow(person)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _personRow(UserProfile person) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: line, width: 2),
    ),
    child: UserRow(
      profile: person,
      repo: widget.repo,
      onTap: () => openProfile(context, widget.repo, person.id),
      trailing: person.id == widget.repo.userId
          ? null
          : FollowButton(
              repo: widget.repo,
              userId: person.id,
              following: following.contains(person.id),
              compact: true,
            ),
    ),
  );
}

/// Panel bawah sidebar desktop: level yang jelas dan saran teman.
class RailExtras extends StatefulWidget {
  const RailExtras({super.key, required this.repo});
  final SpotsRepository repo;
  @override
  State<RailExtras> createState() => _RailExtrasState();
}

class _RailExtrasState extends State<RailExtras> {
  List<UserProfile> people = [];

  @override
  void initState() {
    super.initState();
    load();
    widget.repo.authChanges.listen((_) => load());
  }

  Future<void> load() async {
    try {
      final found = await widget.repo.suggestedUsers(limit: 3);
      if (mounted) setState(() => people = found);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (people.isNotEmpty) ...[
        Row(
          children: [
            const Expanded(
              child: Text(
                'Saran teman',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
            Bouncy(
              onTap: () => openPeople(context, widget.repo),
              child: const Text(
                'Lihat semua',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                  color: blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final person in people)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Bouncy(
                  onTap: () => openProfile(context, widget.repo, person.id),
                  child: Avatar(
                    person.displayName,
                    size: 34,
                    url: widget.repo.avatarUrl(person.avatarPath),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => openProfile(context, widget.repo, person.id),
                    child: Text(
                      '@${person.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
                FollowButton(
                  repo: widget.repo,
                  userId: person.id,
                  following: false,
                  compact: true,
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
      ],
      ListenableBuilder(
        listenable: GameState.instance,
        builder: (context, _) {
          final game = GameState.instance;
          return Bouncy(
            onTap: () => openQuests(context),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: pale,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Level ${game.level}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      const SpotIcon(
                        Glyph.fire,
                        size: 16,
                        color: Color(0xFFD9541E),
                        accent: Color(0xFFFFB648),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${game.streak} hari',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                          color: Color(0xFFD9541E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const XpBar(height: 10),
                  const SizedBox(height: 6),
                  Text(
                    '${game.xp % GameState.perLevel}/${GameState.perLevel} XP · misi ${game.questsDone}/${quests.length}',
                    style: small.copyWith(fontSize: 11.5),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  );
}
