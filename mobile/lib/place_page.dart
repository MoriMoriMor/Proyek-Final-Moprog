import 'package:flutter/material.dart';

import 'profile_page.dart';
import 'spot.dart';
import 'spot_views.dart';
import 'spots_repository.dart';
import 'ui/motion.dart';
import 'ui/piko.dart';
import 'ui/spot_icons.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

/// Satu foto dari dokumentasi sebuah tempat, beserta spot asalnya.
typedef PlacePhoto = ({Spot spot, SpotMedia media});

/// Foto dari semua dokumentasi di satu tempat, diurutkan dari spot paling
/// viral. Hanya foto (bukan video) supaya sorotan selalu ringan dimuat.
List<PlacePhoto> rankedPhotos(List<Spot> spots, {int limit = 10}) {
  final sorted = [...spots]
    ..sort((a, b) => b.engagement.compareTo(a.engagement));
  final out = <PlacePhoto>[];
  for (final spot in sorted) {
    for (final media in spot.media) {
      if (media.type != 'image') continue;
      out.add((spot: spot, media: media));
      if (out.length == limit) return out;
    }
  }
  return out;
}

Future<void> openPlace(
  BuildContext context, {
  required SpotsRepository repo,
  required Spot from,
  required List<Spot> spots,
  required VoidCallback onChanged,
}) => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) =>
        PlacePage(repo: repo, from: from, initial: spots, onChanged: onChanged),
  ),
);

/// Sorotan di halaman detail: 10 foto paling viral dari semua orang yang
/// mendokumentasikan tempat ini. Hanya muncul bila ada lebih dari satu
/// dokumentasi.
class PlaceHighlights extends StatelessWidget {
  const PlaceHighlights({
    super.key,
    required this.repo,
    required this.spot,
    required this.spots,
    required this.onChanged,
  });
  final SpotsRepository repo;
  final Spot spot;
  final List<Spot> spots;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (spots.length < 2) return const SizedBox.shrink();
    final photos = rankedPhotos(spots);
    final people = spots.map((s) => s.ownerId).toSet().length;
    void open() => openPlace(
      context,
      repo: repo,
      from: spot,
      spots: spots,
      onChanged: onChanged,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dokumentasi tempat ini', style: display(22)),
                  const SizedBox(height: 2),
                  Text(
                    '${spots.length} dokumentasi dari $people orang',
                    style: small,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Bouncy(
              onTap: open,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Lihat semua',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: blue,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) => Rise(
              index: i,
              from: 12,
              child: _PhotoTile(
                photo: photos[i],
                rank: i + 1,
                repo: repo,
                onTap: open,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.rank,
    required this.repo,
    required this.onTap,
  });
  final PlacePhoto photo;
  final int rank;
  final SpotsRepository repo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Foto dari ${photo.spot.author}',
    child: Bouncy(
      onTap: onTap,
      scale: .96,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 108,
          height: 132,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AbsorbPointer(
                child: SpotGallery(
                  media: [photo.media],
                  repo: repo,
                  height: 132,
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x99000000)],
                  ),
                ),
              ),
              if (rank <= 3)
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: yellow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ink, width: 1.6),
                    ),
                    child: Text(
                      '#$rank',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                        color: ink,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Row(
                  children: [
                    Avatar(
                      photo.spot.author,
                      size: 20,
                      url: repo.avatarUrl(photo.spot.authorAvatar),
                    ),
                    const SizedBox(width: 5),
                    const SpotIcon(
                      Glyph.heart,
                      size: 13,
                      color: Colors.white,
                      tint: false,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        compact(photo.spot.likes),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
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
    ),
  );
}

/// Semua dokumentasi satu tempat dari semua pengunggah, dari yang paling
/// viral ke yang paling sepi.
class PlacePage extends StatefulWidget {
  const PlacePage({
    super.key,
    required this.repo,
    required this.from,
    required this.initial,
    required this.onChanged,
  });
  final SpotsRepository repo;
  final Spot from;
  final List<Spot> initial;
  final VoidCallback onChanged;

  @override
  State<PlacePage> createState() => _PlacePageState();
}

class _PlacePageState extends State<PlacePage> {
  late List<Spot> spots = _sorted(widget.initial);

  static List<Spot> _sorted(List<Spot> list) =>
      [...list]..sort((a, b) => b.engagement.compareTo(a.engagement));

  Future<void> reload() async {
    final id = widget.from.placeId;
    if (id == null) return;
    try {
      final found = await widget.repo.placeSpots(id);
      if (mounted) setState(() => spots = _sorted(found));
    } catch (e) {
      if (mounted) message(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = categoryOf(widget.from.category);
    final people = spots.map((s) => s.ownerId).toSet().length;
    final photos = spots.fold<int>(0, (n, s) => n + s.media.length);
    return Scaffold(
      backgroundColor: pale,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: RefreshIndicator(
              onRefresh: reload,
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
                      const Spacer(),
                      Mascot(kind: category.mascot, size: 52),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CategorySticker(category),
                  ),
                  const SizedBox(height: 10),
                  Text(widget.from.title, style: display(30, height: 1.05)),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.from.city} · $photos foto · ${spots.length} '
                    'dokumentasi · $people orang',
                    style: small.copyWith(fontSize: 13.5),
                  ),
                  const SizedBox(height: 4),
                  const Text('Diurutkan dari yang paling viral.', style: small),
                  const SizedBox(height: 16),
                  for (final (i, spot) in spots.indexed)
                    Rise(
                      index: i,
                      from: 14,
                      child: _Documentation(
                        spot: spot,
                        rank: i + 1,
                        repo: widget.repo,
                        current: spot.id == widget.from.id,
                        onOpen: () => openSpot(context, spot, widget.repo, () {
                          widget.onChanged();
                          reload();
                        }),
                      ),
                    ),
                  if (spots.isEmpty)
                    const EmptyState(
                      title: 'Belum ada\ndokumentasi.',
                      mood: PikoMood.wow,
                      kind: MascotKind.pino,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Documentation extends StatelessWidget {
  const _Documentation({
    required this.spot,
    required this.rank,
    required this.repo,
    required this.current,
    required this.onOpen,
  });
  final Spot spot;
  final int rank;
  final SpotsRepository repo;
  final bool current;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: current ? piko : line, width: 2),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rank <= 3 ? yellow : pale,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Bouncy(
                  onTap: () => openProfile(context, repo, spot.ownerId),
                  child: Row(
                    children: [
                      Avatar(
                        spot.author,
                        size: 30,
                        url: repo.avatarUrl(spot.authorAvatar),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spot.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (spot.authorUsername.isNotEmpty)
                              Text(
                                '@${spot.authorUsername}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: small.copyWith(fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (current)
                const Pill(
                  color: Color(0xFFEDF1FF),
                  child: Text('Sedang dilihat'),
                ),
            ],
          ),
        ),
        Bouncy(
          onTap: onOpen,
          scale: .99,
          child: SpotGallery(media: spot.media, repo: repo, height: 240),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                spot.story,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E3A64),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Count(Glyph.heart, coral, compact(spot.likes)),
                  _Count(Glyph.bookmark, caramel, compact(spot.saves)),
                  _Count(Glyph.chat, piko, compact(spot.comments)),
                  if (spot.rating != null)
                    _Count(Glyph.star, yellow, spot.rating!.toStringAsFixed(1)),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Count extends StatelessWidget {
  const _Count(this.glyph, this.color, this.value);
  final Glyph glyph;
  final Color color;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SpotIcon(glyph, size: 17, accent: color),
      const SizedBox(width: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
    ],
  );
}
