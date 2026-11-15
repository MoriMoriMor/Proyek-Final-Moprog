import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import 'game.dart';
import 'market.dart';
import 'spot.dart';
import 'spot_views.dart';
import 'spots_repository.dart';
import 'ui/mascots.dart';
import 'ui/motion.dart';
import 'ui/spot_icons.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

/// Alamat publik untuk tautan bagikan. Ganti lewat
/// `--dart-define=SHARE_BASE_URL=https://domain-kamu` saat build.
const shareBase = String.fromEnvironment(
  'SHARE_BASE_URL',
  defaultValue: 'https://morimorimor.github.io/Proyek-Final-Moprog',
);

String spotLink(String id) => '$shareBase/s/$id';
String storeLink(String id) => '$shareBase/t/$id';
String inviteLink(String code) => '$shareBase/i/$code';
String profileLink(String username) => '$shareBase/u/$username';

String inviteCode(String userId) {
  final clean = userId.replaceAll('-', '').toUpperCase();
  return clean.length >= 6 ? clean.substring(0, 6) : clean.padRight(6, 'X');
}

/// Membaca tautan masuk seperti `/s/id`, `/t/id`, `/i/kode`, atau `?spot=id`.
({String kind, String value})? parseIncoming(Uri uri) {
  final q = uri.queryParameters;
  if (q['spot'] != null) return (kind: 's', value: q['spot']!);
  if (q['store'] != null) return (kind: 't', value: q['store']!);
  if (q['invite'] != null) return (kind: 'i', value: q['invite']!);
  final parts = uri.pathSegments.where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2 &&
      const ['s', 't', 'i', 'u'].contains(parts[parts.length - 2])) {
    return (kind: parts[parts.length - 2], value: parts.last);
  }
  return null;
}

Future<void> shareSpot(BuildContext context, SpotsRepository repo, Spot spot) {
  final link = spotLink(spot.id);
  return _open(
    context,
    title: 'Bagikan spot',
    card: SpotShareCard(
      spot: spot,
      repo: repo,
      sharer: repo.userId == null ? null : repo.displayName,
    ),
    text:
        '${spot.title} di ${spot.city} wajib didatangi! Lihat di Spots: $link',
    link: link,
    fileName: 'spots-${spot.id}.png',
  );
}

Future<void> shareStore(BuildContext context, Store store) {
  final link = storeLink(store.id);
  return _open(
    context,
    title: 'Bagikan toko',
    card: StoreShareCard(store: store),
    text: 'Jajan dari ${store.name} lewat Spots: $link',
    link: link,
    fileName: 'spots-toko-${store.id}.png',
  );
}

Future<void> shareInvite(BuildContext context, SpotsRepository repo) {
  final code = repo.userId == null ? 'SPOTS' : inviteCode(repo.userId!);
  final link = inviteLink(code);
  return _open(
    context,
    title: 'Ajak teman',
    card: InviteShareCard(name: repo.displayName, code: code),
    text: 'Yuk cari spot seru bareng di Spots! Pakai kode $code: $link',
    link: link,
    fileName: 'spots-ajak-$code.png',
  );
}

Future<void> shareProfile(
  BuildContext context,
  UserProfile profile,
  ProfileStats stats,
) {
  final link = profileLink(profile.username);
  return _open(
    context,
    title: 'Bagikan profil',
    card: ProfileShareCard(profile: profile, stats: stats),
    text: 'Cek spot-spot pilihan @${profile.username} di Spots: $link',
    link: link,
    fileName: 'spots-${profile.username}.png',
  );
}

Future<void> shareAchievement(BuildContext context) {
  final game = GameState.instance;
  return _open(
    context,
    title: 'Pamerin progresmu',
    card: AchievementShareCard(
      level: game.level,
      streak: game.streak,
      xp: game.xp,
    ),
    text:
        'Aku udah Level ${game.level} dengan streak ${game.streak} hari di Spots. Kejar aku! $shareBase',
    link: shareBase,
    fileName: 'spots-level-${game.level}.png',
  );
}

Future<void> _open(
  BuildContext context, {
  required String title,
  required Widget card,
  required String text,
  required String link,
  required String fileName,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _ShareSheet(
    title: title,
    card: card,
    text: text,
    link: link,
    fileName: fileName,
  ),
);

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({
    required this.title,
    required this.card,
    required this.text,
    required this.link,
    required this.fileName,
  });
  final String title, text, link, fileName;
  final Widget card;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final boundary = GlobalKey();
  bool busy = false;

  void done(String note) {
    GameState.instance.track('share');
    if (mounted) message(context, note);
  }

  Future<void> shareImage() async {
    setState(() => busy = true);
    try {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = XFile.fromData(
        data!.buffer.asUint8List(),
        mimeType: 'image/png',
        name: widget.fileName,
      );
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [file],
          text: widget.text,
          fileNameOverrides: [widget.fileName],
        ),
      );
      if (result.status != ShareResultStatus.dismissed) {
        done('Mantap, sudah dibagikan!');
      }
    } catch (_) {
      await copy();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> copy() async {
    await Clipboard.setData(ClipboardData(text: widget.link));
    HapticFeedback.mediumImpact();
    done('Link disalin. Tempel di mana aja!');
  }

  Future<void> shareText() async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: widget.text),
      );
      if (result.status != ShareResultStatus.dismissed) {
        done('Sudah dibagikan!');
      }
    } catch (_) {
      await copy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: display(26)),
            const SizedBox(height: 14),
            SizedBox(
              height: (height * .46).clamp(240, 420),
              child: Rise(
                child: FittedBox(
                  child: RepaintBoundary(
                    key: boundary,
                    child: SizedBox(
                      width: 360,
                      height: 640,
                      child: widget.card,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _Action(
                    glyph: Glyph.gallery,
                    label: busy ? 'Menyiapkan…' : 'Kirim gambar',
                    color: coral,
                    onTap: busy ? null : shareImage,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Action(
                    glyph: Glyph.route,
                    label: 'Salin link',
                    color: piko,
                    onTap: copy,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Action(
                    glyph: Glyph.share,
                    label: 'Lainnya',
                    color: mint,
                    onTap: shareText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SelectableText(widget.link, style: small.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.glyph,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final Glyph glyph;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Chunky(
    onTap: onTap,
    color: color,
    radius: 22,
    expand: true,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpotIcon(glyph, size: 26, color: Colors.white, accent: edgeOf(color)),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    ),
  );
}

// ---------- Kartu yang dibagikan (ukuran story 9:16) ----------

class _CardFrame extends StatelessWidget {
  const _CardFrame({
    required this.colors,
    required this.word,
    required this.child,
  });
  final List<Color> colors;
  final String word;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
    ),
    child: Stack(
      children: [
        // Kata besar bergaris di latar, seperti poster.
        Positioned(
          left: -10,
          top: 150,
          child: Transform.rotate(
            angle: -.08,
            child: Text(
              word,
              style: TextStyle(
                fontFamily: fontDisplay,
                fontSize: 120,
                height: .9,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 3
                  ..color = Colors.white.withValues(alpha: .35),
              ),
            ),
          ),
        ),
        Positioned(
          left: 22,
          top: 22,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SvgPicture.asset('assets/logo.svg', height: 26),
          ),
        ),
        Positioned.fill(child: child),
      ],
    ),
  );
}

class _LinkPill extends StatelessWidget {
  const _LinkPill(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
    decoration: BoxDecoration(
      color: ink,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Transform.rotate(
            angle: 3.1416,
            child: const SpotIcon(Glyph.back, size: 16, tint: false),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Sticker extends StatelessWidget {
  const _Sticker(this.text, {this.color = yellow, this.tilt = .08});
  final String text;
  final Color color;
  final double tilt;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: tilt,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ink, width: 2.4),
        boxShadow: const [BoxShadow(color: ink, offset: Offset(2, 3))],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: ink,
          fontSize: 14,
        ),
      ),
    ),
  );
}

String _short(String link) => link.replaceFirst(RegExp(r'^https?://'), '');

class SpotShareCard extends StatelessWidget {
  const SpotShareCard({
    super.key,
    required this.spot,
    required this.repo,
    this.sharer,
  });
  final Spot spot;
  final SpotsRepository repo;
  final String? sharer;

  @override
  Widget build(BuildContext context) {
    final category = categoryOf(spot.category);
    final media = spot.media.isEmpty ? null : spot.media.first;
    return _CardFrame(
      colors: [category.color, Color.lerp(category.color, grape, .5)!],
      word: 'SPOTS',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 80, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Transform.rotate(
                      angle: -.035,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child:
                              media == null ||
                                  media.path.startsWith('demo:') ||
                                  media.type == 'video'
                              ? DemoCover(
                                  seed:
                                      media?.path ??
                                      'demo:${spot.category}:${spot.id}',
                                )
                              : Image.network(
                                  repo.publicMediaUrl(media.path),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -6,
                    top: -14,
                    child: _Sticker('Wajib didatangi!', color: yellow),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: CategorySticker(category),
                  ),
                  Positioned(
                    right: -10,
                    bottom: -34,
                    child: Mascot(
                      kind: MascotKind.forCategory(spot.category),
                      size: 108,
                      mood: MascotMood.love,
                      wave: true,
                      interactive: false,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text(
              spot.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: display(34, color: Colors.white, height: 1.02),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SpotIcon(
                  Glyph.pin,
                  size: 20,
                  color: Colors.white,
                  accent: yellow,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    spot.city,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (spot.rating != null) ...[
                  const SizedBox(width: 12),
                  const SpotIcon(
                    Glyph.star,
                    size: 20,
                    color: Colors.white,
                    accent: yellow,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    spot.rating!.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                const SpotIcon(
                  Glyph.heart,
                  size: 20,
                  color: Colors.white,
                  accent: coral,
                ),
                const SizedBox(width: 3),
                Text(
                  compact(spot.likes),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _LinkPill(_short(spotLink(spot.id))),
            if (sharer != null) ...[
              const SizedBox(height: 8),
              Text(
                'Dibagikan $sharer',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .85),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StoreShareCard extends StatelessWidget {
  const StoreShareCard({super.key, required this.store});
  final Store store;

  @override
  Widget build(BuildContext context) => _CardFrame(
    colors: const [yellow, coral],
    word: 'JAJAN',
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 90, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Sticker('Bisa pesan online', color: Colors.white, tilt: -.06),
          const Spacer(),
          const Center(
            child: MascotCrew(
              kinds: [MascotKind.mimi, MascotKind.tote, MascotKind.jojo],
              size: 92,
              mood: MascotMood.laugh,
            ),
          ),
          const Spacer(),
          Text(store.name, style: display(38, color: Colors.white, height: 1)),
          const SizedBox(height: 8),
          Text(
            store.address,
            maxLines: 2,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 18),
          _LinkPill(_short(storeLink(store.id))),
        ],
      ),
    ),
  );
}

class InviteShareCard extends StatelessWidget {
  const InviteShareCard({super.key, required this.name, required this.code});
  final String name, code;

  @override
  Widget build(BuildContext context) => _CardFrame(
    colors: const [piko, grape],
    word: 'SQUAD',
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 96, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$name ngajak\nkamu jalan!',
            style: display(36, color: Colors.white, height: 1.05),
          ),
          const Spacer(),
          const Center(child: MascotCrew(size: 64, mood: MascotMood.laugh)),
          const Spacer(),
          const Text(
            'Kode undangan',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Transform.rotate(
            angle: -.03,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: yellow,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ink, width: 2.6),
                boxShadow: const [BoxShadow(color: ink, offset: Offset(3, 4))],
              ),
              child: Text(code, style: display(34).copyWith(letterSpacing: 4)),
            ),
          ),
          const SizedBox(height: 18),
          _LinkPill(_short(inviteLink(code))),
        ],
      ),
    ),
  );
}

class AchievementShareCard extends StatelessWidget {
  const AchievementShareCard({
    super.key,
    required this.level,
    required this.streak,
    required this.xp,
  });
  final int level, streak, xp;

  @override
  Widget build(BuildContext context) => _CardFrame(
    colors: const [Color(0xFFFF8A3D), grape],
    word: 'LV $level',
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 96, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Sticker('Pencapaian baru', color: Colors.white, tilt: -.06),
          const Spacer(),
          const Center(
            child: Mascot(
              kind: MascotKind.cici,
              size: 190,
              mood: MascotMood.cool,
              wave: true,
              interactive: false,
            ),
          ),
          const Spacer(),
          Text(
            'Level $level',
            style: display(56, color: Colors.white, height: 1),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SpotIcon(
                Glyph.fire,
                size: 26,
                color: Colors.white,
                accent: yellow,
              ),
              const SizedBox(width: 6),
              Text(
                '$streak hari streak · $xp XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _LinkPill(_short(shareBase)),
        ],
      ),
    ),
  );
}

class ProfileShareCard extends StatelessWidget {
  const ProfileShareCard({
    super.key,
    required this.profile,
    required this.stats,
  });
  final UserProfile profile;
  final ProfileStats stats;

  @override
  Widget build(BuildContext context) => _CardFrame(
    colors: const [piko, Color(0xFFE071C9)],
    word: 'SPOTS',
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 96, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Sticker('Ikuti jejakku', color: yellow, tilt: -.06),
          const Spacer(),
          Center(child: Avatar(profile.displayName, size: 120, ring: true)),
          const SizedBox(height: 14),
          Center(
            child: Text(
              profile.displayName,
              style: display(36, color: Colors.white),
            ),
          ),
          Center(
            child: Text(
              '@${profile.username}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final (value, label) in [
                ('${stats.posts}', 'spot'),
                ('${stats.cities}', 'kota'),
                (compact(stats.likes), 'suka'),
              ])
                Column(
                  children: [
                    Text(value, style: display(30, color: Colors.white)),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 18),
          _LinkPill(_short(profileLink(profile.username))),
        ],
      ),
    ),
  );
}
