import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game.dart';
import 'share.dart';
import 'market.dart';
import 'spot_views.dart';
import 'route_page.dart';
import 'spots_repository.dart';
import 'ui/motion.dart';
import 'ui/piko.dart';
import 'ui/spot_icons.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

/// Keranjang dipakai bersama oleh semua layar.
final cart = Cart();

const marketCategories = spotCategories;

SpotCategory marketCategoryOf(String key) => categoryOf(key);

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.product, required this.repo});
  final Product product;
  final SpotsRepository repo;

  @override
  Widget build(BuildContext context) {
    final path = product.imagePath;
    if (path == null || path.isEmpty) {
      return ColoredBox(
        color: const Color(0xFFFFF4D6),
        child: Center(
          child: SpotIcon(
            Glyph.bag,
            size: 44,
            accent: marketCategoryOf('lainnya').color,
          ),
        ),
      );
    }
    if (path.startsWith('demo:')) return DemoCover(seed: path);
    return Image.network(
      repo.productImageUrl(path),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(color: pale),
    );
  }
}

class CartButton extends StatelessWidget {
  const CartButton({super.key, required this.repo, this.dark = false});
  final SpotsRepository repo;
  final bool dark;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: cart,
    builder: (context, _) => Semantics(
      button: true,
      label: 'Keranjang, ${cart.count} barang',
      child: Bouncy(
        onTap: () => openCart(context, repo),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: .85)
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: line, width: 2),
              ),
              child: const SpotIcon(Glyph.bag, size: 24, accent: yellow),
            ),
            if (cart.count > 0)
              Positioned(
                right: -4,
                top: -4,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(cart.count),
                  tween: Tween(begin: 1.6, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (_, s, child) =>
                      Transform.scale(scale: s, child: child),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: coral,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '${cart.count}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
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
}

// ---------- Tab Market ----------

class MarketTab extends StatefulWidget {
  const MarketTab({super.key, required this.repo});
  final SpotsRepository repo;
  @override
  State<MarketTab> createState() => _MarketTabState();
}

class _MarketTabState extends State<MarketTab> {
  final search = TextEditingController();
  String? category;
  List<Store> stores = [];
  List<Product> featured = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final results = await Future.wait([
        widget.repo.stores(query: search.text, category: category),
        if (featured.isEmpty) widget.repo.featuredProducts(),
      ]);
      if (!mounted) return;
      setState(() {
        stores = results[0] as List<Store>;
        if (results.length > 1) featured = results[1] as List<Product>;
      });
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return RefreshIndicator(
      color: piko,
      edgeOffset: top,
      onRefresh: load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(0, top + 10, 0, 140),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Rise(
                            child: Text('Market', style: display(40)),
                          ),
                        ),
                        CartButton(repo: widget.repo),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Rise(index: 1, child: _promo()),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: search,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => load(),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                      decoration: const InputDecoration(
                        hintText: 'Cari toko atau alamat',
                        fillColor: Colors.white,
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(13),
                          child: SpotIcon(
                            Glyph.search,
                            size: 22,
                            accent: yellow,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  CategoryRow(
                    selected: category,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onSelected: (value) {
                      setState(() => category = value);
                      load();
                    },
                  ),
                  if (featured.isNotEmpty) ...[
                    SectionTitle(
                      'Lagi laris',
                      trailing: const SpotIcon(
                        Glyph.fire,
                        size: 28,
                        color: Color(0xFFD9541E),
                        accent: Color(0xFFFFB648),
                      ),
                    ),
                    SizedBox(
                      height: 222,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        clipBehavior: Clip.none,
                        itemCount: featured.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, i) => Rise(
                          index: i,
                          child: _FeaturedProduct(
                            product: featured[i],
                            repo: widget.repo,
                            onTap: () => openStore(
                              context,
                              widget.repo,
                              featured[i].storeId,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  SectionTitle(
                    'Toko',
                    trailing: loading
                        ? null
                        : Pill(
                            color: const Color(0xFFEDF1FF),
                            child: Text('${stores.length}'),
                          ),
                  ),
                  if (error != null) Notice(error!, onRetry: load),
                  if (loading)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Shimmer(
                        child: Column(
                          children: List.generate(
                            3,
                            (_) => const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Bone(height: 104, radius: 26),
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (stores.isEmpty)
                    const EmptyState(
                      title: 'Belum ada toko\ndi sini.',
                      mood: PikoMood.wow,
                      kind: MascotKind.tote,
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final (i, store) in stores.indexed)
                            SizedBox(
                              width: wide ? 480 : double.infinity,
                              child: Rise(
                                index: i,
                                child: StoreCard(
                                  store: store,
                                  onTap: () => openStore(
                                    context,
                                    widget.repo,
                                    store.id,
                                    initial: store,
                                  ),
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
        ],
      ),
    );
  }

  Widget _promo() => Container(
    height: 132,
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: const LinearGradient(colors: [coral, Color(0xFFFFA46B)]),
      boxShadow: const [
        BoxShadow(color: Color(0xFFD45E73), offset: Offset(0, 6)),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: [
        Positioned(
          right: 4,
          bottom: 4,
          child: Transform.rotate(
            angle: .1,
            child: const Piko(
              size: 112,
              mood: PikoMood.wink,
              kind: MascotKind.tote,
              wave: true,
            ),
          ),
        ),
        Positioned(
          right: 108,
          top: 14,
          child: Transform.rotate(
            angle: -.2,
            child: const SpotIcon(
              Glyph.bag,
              size: 40,
              color: Colors.white,
              accent: yellow,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 150, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Jajan dari\nspot favorit',
                style: display(26, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pesan online atau ambil di tempat.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FeaturedProduct extends StatelessWidget {
  const _FeaturedProduct({
    required this.product,
    required this.repo,
    required this.onTap,
  });
  final Product product;
  final SpotsRepository repo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Bouncy(
    onTap: onTap,
    child: Container(
      width: 156,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: line, width: 2),
        boxShadow: const [BoxShadow(color: line, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 118,
              width: double.infinity,
              child: ProductImage(product: product, repo: repo),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: title.copyWith(fontSize: 14),
                ),
                Text(
                  product.storeName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: small.copyWith(fontSize: 11.5),
                ),
                const SizedBox(height: 4),
                Text(
                  rupiah(product.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD9541E),
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

class StoreCard extends StatelessWidget {
  const StoreCard({
    super.key,
    required this.store,
    required this.onTap,
    this.compactWidth,
  });
  final Store store;
  final VoidCallback onTap;
  final double? compactWidth;

  @override
  Widget build(BuildContext context) {
    final category = marketCategoryOf(store.category);
    return Bouncy(
      scale: .97,
      onTap: onTap,
      child: Container(
        width: compactWidth,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: line, width: 2),
          boxShadow: const [BoxShadow(color: line, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox.square(
                dimension: 84,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        category.color.withValues(alpha: .22),
                        category.color.withValues(alpha: .5),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Mascot(
                      kind: category.mascot,
                      size: 60,
                      bounce: false,
                      interactive: false,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: title.copyWith(fontSize: 16.5),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    store.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: small.copyWith(fontSize: 12.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _Badge(
                        store.onlineOrders ? 'Pesan online' : 'Beli di lokasi',
                        store.onlineOrders ? mint : muted,
                      ),
                      if (store.onlineOrders && store.delivery)
                        const _Badge('Bisa kirim', piko),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Transform.rotate(
              angle: 3.1416,
              child: const SpotIcon(
                Glyph.back,
                size: 20,
                color: muted,
                tint: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: edgeOf(color),
        fontWeight: FontWeight.w900,
        fontSize: 11.5,
      ),
    ),
  );
}

// ---------- Halaman toko ----------

Future<void> openStore(
  BuildContext context,
  SpotsRepository repo,
  String storeId, {
  Store? initial,
}) => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => StorePage(repo: repo, storeId: storeId, initial: initial),
  ),
);

class StorePage extends StatefulWidget {
  const StorePage({
    super.key,
    required this.repo,
    required this.storeId,
    this.initial,
  });
  final SpotsRepository repo;
  final String storeId;
  final Store? initial;
  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  late Store? store = widget.initial;
  List<Product> products = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final results = await Future.wait([
        widget.repo.store(widget.storeId),
        widget.repo.products(widget.storeId),
      ]);
      if (!mounted) return;
      setState(() {
        store = results[0] as Store?;
        products = (results[1] as List<Product>)
            .where((p) => p.active)
            .toList();
      });
      if (cart.store?.id == widget.storeId) cart.refreshProducts(products);
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> add(Product product) async {
    final shop = store!;
    if (!cart.belongsTo(shop)) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text('Ganti keranjang?', style: display(24)),
          content: Text(
            'Keranjangmu berisi barang dari ${cart.store!.name}. Satu pesanan hanya untuk satu toko.',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ganti'),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }
    HapticFeedback.lightImpact();
    cart.add(shop, product);
  }

  @override
  Widget build(BuildContext context) {
    final shop = store;
    final top = MediaQuery.paddingOf(context).top;
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      backgroundColor: pale,
      body: shop == null
          ? Center(
              child: loading
                  ? const Piko(size: 110, mood: PikoMood.wow)
                  : EmptyState(
                      title: error ?? 'Toko tidak ditemukan.',
                      action: 'Kembali',
                      onAction: () => Navigator.pop(context),
                    ),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 140),
                children: [
                  _header(shop, top),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!shop.onlineOrders)
                              Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4D6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    SpotIcon(
                                      Glyph.store,
                                      size: 26,
                                      accent: yellow,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Belum bisa pesan online. Beli langsung di lokasi ya.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (error != null) Notice(error!, onRetry: load),
                            Text('Menu', style: display(26)),
                            const SizedBox(height: 12),
                            if (loading && products.isEmpty)
                              Shimmer(
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: List.generate(
                                    4,
                                    (_) => const SizedBox(
                                      width: 160,
                                      child: Bone(height: 220, radius: 26),
                                    ),
                                  ),
                                ),
                              )
                            else if (products.isEmpty)
                              const EmptyState(
                                title: 'Menunya belum\ndiisi.',
                                mood: PikoMood.sleepy,
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: products.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: wide ? 4 : 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      mainAxisExtent: 262,
                                    ),
                                itemBuilder: (context, i) => Rise(
                                  index: i,
                                  child: _ProductCard(
                                    product: products[i],
                                    repo: widget.repo,
                                    online: shop.onlineOrders,
                                    onAdd: () => add(products[i]),
                                    onRemove: () => cart.remove(products[i].id),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _CartBar(repo: widget.repo, storeId: widget.storeId),
    );
  }

  Widget _header(Store shop, double top) {
    final category = marketCategoryOf(shop.category);
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 10, 16, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [category.color, Color.lerp(category.color, grape, .55)!],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassButton(
                glyph: Glyph.back,
                label: 'Kembali',
                onTap: () => Navigator.maybePop(context),
              ),
              const Spacer(),
              CartButton(repo: widget.repo),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Rise(child: CategorySticker(category)),
                    const SizedBox(height: 10),
                    Rise(
                      index: 1,
                      child: Text(
                        shop.name,
                        style: display(32, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      shop.address,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (shop.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        shop.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Rise(
                index: 2,
                child: Mascot(kind: category.mascot, size: 92, wave: true),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (shop.onlineOrders && shop.pickup)
                _HeaderChip(Glyph.store, 'Ambil di lokasi'),
              if (shop.onlineOrders && shop.delivery)
                _HeaderChip(
                  Glyph.route,
                  shop.deliveryFee == 0
                      ? 'Kirim gratis'
                      : 'Kirim ${rupiah(shop.deliveryFee)}',
                ),
              Bouncy(
                onTap: () =>
                    openRouteTo(context, shop.name, shop.lat, shop.lng),
                child: _HeaderChip(Glyph.pin, 'Rute'),
              ),
              Bouncy(
                onTap: () => shareStore(context, shop),
                child: _HeaderChip(Glyph.share, 'Bagikan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip(this.glyph, this.text);
  final Glyph glyph;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .22),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpotIcon(glyph, size: 17, color: Colors.white, tint: false),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12.5,
          ),
        ),
      ],
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.repo,
    required this.online,
    required this.onAdd,
    required this.onRemove,
  });
  final Product product;
  final SpotsRepository repo;
  final bool online;
  final VoidCallback onAdd, onRemove;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: line, width: 2),
      boxShadow: const [BoxShadow(color: line, offset: Offset(0, 4))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductImage(product: product, repo: repo),
                if (product.soldOut)
                  Container(
                    color: Colors.white.withValues(alpha: .7),
                    alignment: Alignment.center,
                    child: Transform.rotate(
                      angle: -.15,
                      child: const Pill(
                        color: ink,
                        child: Text(
                          'Habis',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  )
                else if (product.stock <= 3)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Pill(
                      color: coral,
                      child: Text(
                        'Sisa ${product.stock}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 8, 5, 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: title.copyWith(fontSize: 14, height: 1.15),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rupiah(product.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD9541E),
                      ),
                    ),
                  ),
                  if (online && !product.soldOut)
                    ListenableBuilder(
                      listenable: cart,
                      builder: (context, _) {
                        final qty = cart.qtyOf(product.id);
                        if (qty == 0) {
                          return Chunky(
                            onTap: onAdd,
                            color: piko,
                            radius: 14,
                            depth: 3,
                            label: 'Tambah ${product.name}',
                            padding: const EdgeInsets.all(7),
                            child: const SpotIcon(
                              Glyph.plus,
                              size: 18,
                              color: Colors.white,
                            ),
                          );
                        }
                        return _Stepper(
                          qty: qty,
                          canAdd: qty < product.stock,
                          onAdd: onAdd,
                          onRemove: onRemove,
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.qty,
    required this.canAdd,
    required this.onAdd,
    required this.onRemove,
  });
  final int qty;
  final bool canAdd;
  final VoidCallback onAdd, onRemove;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFEDF1FF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Bouncy(
          onTap: onRemove,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Text(
              '–',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: blue,
              ),
            ),
          ),
        ),
        TweenAnimationBuilder<double>(
          key: ValueKey(qty),
          tween: Tween(begin: 1.5, end: 1),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (_, s, child) => Transform.scale(scale: s, child: child),
          child: Text(
            '$qty',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
        ),
        Bouncy(
          onTap: canAdd ? onAdd : null,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: SpotIcon(
              Glyph.plus,
              size: 16,
              color: canAdd ? blue : muted,
              tint: false,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CartBar extends StatelessWidget {
  const _CartBar({required this.repo, required this.storeId});
  final SpotsRepository repo;
  final String storeId;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: cart,
    builder: (context, _) {
      final show = cart.count > 0 && cart.store?.id == storeId;
      return AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: !show
            ? const SizedBox(width: double.infinity)
            : SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Chunky(
                      expand: true,
                      color: ink,
                      edge: Colors.black,
                      onTap: () => openCart(context, repo),
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: yellow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${cart.count}',
                              style: const TextStyle(color: ink),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text('Lihat keranjang'),
                          const Spacer(),
                          Text(rupiah(cart.subtotal)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      );
    },
  );
}

// ---------- Keranjang dan checkout ----------

Future<void> openCart(BuildContext context, SpotsRepository repo) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CartSheet(repo: repo),
    );

class CartSheet extends StatefulWidget {
  const CartSheet({super.key, required this.repo});
  final SpotsRepository repo;
  @override
  State<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<CartSheet> {
  final address = TextEditingController();
  final note = TextEditingController();
  late String fulfillment = cart.store?.pickup ?? true ? 'ambil' : 'kirim';
  bool busy = false;
  String? error;

  @override
  void dispose() {
    address.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> checkout() async {
    if (widget.repo.userId == null) {
      await openAuth(context, widget.repo);
      if (widget.repo.userId == null) return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final shop = cart.store!;
      final id = await widget.repo.placeOrder(
        cart: cart,
        fulfillment: fulfillment,
        address: address.text,
        note: note.text,
      );
      cart.clear();
      GameState.instance.track('order');
      if (!mounted) return;
      final navigator = Navigator.of(context);
      navigator.pop();
      await showCelebration(
        navigator.context,
        title: 'Pesanan\nterkirim!',
        subtitle: 'Tunggu ${shop.name} menerima pesananmu.',
        color: mint,
        badge: const Mascot(
          kind: MascotKind.tote,
          size: 170,
          mood: MascotMood.laugh,
          wave: true,
        ),
      );
      if (navigator.mounted) {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => OrderPage(repo: widget.repo, orderId: id),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => error = friendlyError(e));
      final shop = cart.store;
      if (shop != null) {
        try {
          cart.refreshProducts(await widget.repo.products(shop.id));
        } catch (_) {}
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: cart,
    builder: (context, _) {
      final shop = cart.store;
      if (shop == null || cart.lines.isEmpty) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: EmptyState(
              title: 'Keranjang\nmasih kosong.',
              mood: PikoMood.sleepy,
              kind: MascotKind.tote,
            ),
          ),
        );
      }
      final fee = fulfillment == 'kirim' ? shop.deliveryFee : 0;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .86,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Keranjang', style: display(30)),
                      Text(shop.name, style: small),
                      const SizedBox(height: 14),
                      for (final line in cart.lines.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox.square(
                                  dimension: 54,
                                  child: ProductImage(
                                    product: line.product,
                                    repo: widget.repo,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.product.name,
                                      style: title.copyWith(fontSize: 15),
                                    ),
                                    Text(
                                      rupiah(line.product.price),
                                      style: small,
                                    ),
                                  ],
                                ),
                              ),
                              _Stepper(
                                qty: line.qty,
                                canAdd: line.qty < line.product.stock,
                                onAdd: () => cart.add(shop, line.product),
                                onRemove: () => cart.remove(line.product.id),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (shop.pickup)
                            Expanded(
                              child: _Choice(
                                glyph: Glyph.store,
                                label: 'Ambil',
                                sub: 'Gratis',
                                active: fulfillment == 'ambil',
                                onTap: () =>
                                    setState(() => fulfillment = 'ambil'),
                              ),
                            ),
                          if (shop.pickup && shop.delivery)
                            const SizedBox(width: 10),
                          if (shop.delivery)
                            Expanded(
                              child: _Choice(
                                glyph: Glyph.route,
                                label: 'Kirim',
                                sub: shop.deliveryFee == 0
                                    ? 'Gratis'
                                    : rupiah(shop.deliveryFee),
                                active: fulfillment == 'kirim',
                                onTap: () =>
                                    setState(() => fulfillment = 'kirim'),
                              ),
                            ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        child: fulfillment == 'kirim'
                            ? Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: TextField(
                                  controller: address,
                                  maxLength: 300,
                                  minLines: 2,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    hintText: 'Alamat lengkap pengiriman',
                                    counterText: '',
                                  ),
                                ),
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: note,
                        maxLength: 300,
                        decoration: const InputDecoration(
                          hintText: 'Catatan buat toko (opsional)',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SummaryRow('Subtotal', rupiah(cart.subtotal)),
                      if (fulfillment == 'kirim')
                        _SummaryRow('Ongkir', rupiah(fee)),
                      const Divider(height: 22, color: line, thickness: 2),
                      _SummaryRow(
                        'Total',
                        rupiah(cart.subtotal + fee),
                        strong: true,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Total akhir dicek ulang oleh toko. Bayar setelah pesanan diterima.',
                        style: TextStyle(
                          color: muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: error == null
                            ? const SizedBox(width: double.infinity)
                            : Notice(error!),
                      ),
                      const SizedBox(height: 14),
                      Chunky(
                        expand: true,
                        color: coral,
                        onTap: busy ? null : checkout,
                        child: Text(busy ? 'Mengirim…' : 'Pesan sekarang'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.glyph,
    required this.label,
    required this.sub,
    required this.active,
    required this.onTap,
  });
  final Glyph glyph;
  final String label, sub;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: active,
    button: true,
    child: Bouncy(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEDF1FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? piko : line, width: 2.4),
        ),
        child: Row(
          children: [
            SpotIcon(glyph, size: 26, accent: active ? yellow : line),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: title.copyWith(fontSize: 15)),
                Text(sub, style: small.copyWith(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.strong = false});
  final String label, value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(label, style: strong ? title : small.copyWith(color: ink)),
        const Spacer(),
        Text(
          value,
          style: strong
              ? display(22)
              : const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

// ---------- Pesanan ----------

Color statusColor(String status) => switch (status) {
  'menunggu' => caramel,
  'diterima' || 'diproses' => piko,
  'siap' => grape,
  'selesai' => mint,
  _ => danger,
};

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) => Pill(
    color: statusColor(status).withValues(alpha: .15),
    child: Text(
      orderStatusLabel[status] ?? status,
      style: TextStyle(color: edgeOf(statusColor(status))),
    ),
  );
}

class OrderTile extends StatelessWidget {
  const OrderTile({
    super.key,
    required this.order,
    required this.onTap,
    this.seller = false,
  });
  final StoreOrder order;
  final VoidCallback onTap;
  final bool seller;

  @override
  Widget build(BuildContext context) => Bouncy(
    scale: .97,
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: line, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusColor(order.status).withValues(alpha: .15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SpotIcon(
              Glyph.receipt,
              size: 26,
              accent: statusColor(order.status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seller ? order.buyerName : order.storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: title.copyWith(fontSize: 15.5),
                ),
                Text(
                  '${order.itemCount} barang · ${rupiah(order.total)}',
                  style: small.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(order.status),
              if (!order.closed && order.status != 'menunggu') ...[
                const SizedBox(height: 4),
                Text(
                  paymentStatusLabel[order.paymentStatus] ?? '',
                  style: small.copyWith(fontSize: 11),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}

class OrderPage extends StatefulWidget {
  const OrderPage({super.key, required this.repo, required this.orderId});
  final SpotsRepository repo;
  final String orderId;
  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  StoreOrder? order;
  String? error;
  bool busy = false;

  Timer? poll;

  @override
  void initState() {
    super.initState();
    load();
    poll = Timer.periodic(const Duration(seconds: 6), (_) {
      if (order != null && !order!.closed && !busy) load();
    });
  }

  @override
  void dispose() {
    poll?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final before = order?.status;
      final found = await widget.repo.order(widget.orderId);
      if (before != null && before != found.status && mounted) {
        HapticFeedback.mediumImpact();
        message(context, 'Status: ${orderStatusLabel[found.status]}');
      }
      if (mounted) setState(() => order = found);
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    }
  }

  Future<void> act(String action) async {
    setState(() => busy = true);
    try {
      await widget.repo.orderAction(widget.orderId, action);
      await load();
      if (mounted && action == 'report_payment') {
        message(context, 'Sip, toko akan cek pembayaranmu.');
      }
    } catch (e) {
      if (mounted) message(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = order;
    return Scaffold(
      backgroundColor: pale,
      body: SafeArea(
        child: o == null
            ? Center(
                child: error == null
                    ? const Piko(size: 100, mood: PikoMood.wow)
                    : EmptyState(
                        title: error!,
                        action: 'Coba lagi',
                        onAction: load,
                      ),
              )
            : RefreshIndicator(
                onRefresh: load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                GlassButton(
                                  glyph: Glyph.back,
                                  label: 'Kembali',
                                  onTap: () => Navigator.maybePop(context),
                                ),
                                const Spacer(),
                                StatusChip(o.status),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(o.storeName, style: display(30)),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 350),
                                  transitionBuilder: (child, a) =>
                                      ScaleTransition(scale: a, child: child),
                                  child: Mascot(
                                    key: ValueKey(o.status),
                                    size: 76,
                                    kind: switch (o.status) {
                                      'menunggu' => MascotKind.jojo,
                                      'selesai' => MascotKind.cici,
                                      'ditolak' ||
                                      'dibatalkan' => MascotKind.piko,
                                      _ => MascotKind.tote,
                                    },
                                    mood: switch (o.status) {
                                      'menunggu' => MascotMood.sleepy,
                                      'selesai' => MascotMood.love,
                                      'ditolak' ||
                                      'dibatalkan' => MascotMood.wow,
                                      'siap' => MascotMood.laugh,
                                      _ => MascotMood.happy,
                                    },
                                    wave: o.status == 'siap',
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              o.fulfillment == 'kirim'
                                  ? 'Dikirim ke ${o.address}'
                                  : 'Ambil di lokasi',
                              style: small,
                            ),
                            const SizedBox(height: 18),
                            OrderTimeline(order: o),
                            const SizedBox(height: 18),
                            _receipt(o),
                            const SizedBox(height: 14),
                            if (o.status == 'ditolak')
                              Notice('Ditolak: ${o.rejectReason ?? '-'}')
                            else if (o.status == 'diterima' &&
                                o.paymentStatus != 'lunas')
                              _payment(o),
                            if (o.status == 'menunggu') ...[
                              const SizedBox(height: 8),
                              Chunky(
                                expand: true,
                                color: Colors.white,
                                edge: line,
                                border: line,
                                onTap: busy ? null : () => act('cancel'),
                                child: const Text(
                                  'Batalkan pesanan',
                                  style: TextStyle(color: danger),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _receipt(StoreOrder o) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: line, width: 2),
    ),
    child: Column(
      children: [
        for (final item in o.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Text(
                  '${item.qty}×',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  rupiah(item.unitPrice * item.qty),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        const Divider(height: 20, color: line, thickness: 2),
        _SummaryRow('Subtotal', rupiah(o.subtotal)),
        if (o.shippingFee > 0) _SummaryRow('Ongkir', rupiah(o.shippingFee)),
        _SummaryRow('Total', rupiah(o.total), strong: true),
        if (o.note.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Catatan: ${o.note}', style: small),
          ),
        ],
      ],
    ),
  );

  Widget _payment(StoreOrder o) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFEDF1FF),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Cara bayar', style: display(22)),
        const SizedBox(height: 6),
        SelectableText(
          o.paymentInfo.isEmpty ? 'Tanya toko lewat kontaknya.' : o.paymentInfo,
          style: const TextStyle(fontWeight: FontWeight.w800, height: 1.4),
        ),
        const SizedBox(height: 4),
        Text('Bayar tepat ${rupiah(o.total)}.', style: small),
        const SizedBox(height: 14),
        if (o.paymentStatus == 'belum')
          Chunky(
            expand: true,
            color: piko,
            onTap: busy ? null : () => act('report_payment'),
            child: const Text('Aku sudah bayar'),
          )
        else
          const Row(
            children: [
              Piko(size: 44, mood: PikoMood.wink, kind: MascotKind.tote),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Toko lagi cek pembayaranmu.',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
      ],
    ),
  );
}

class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.order});
  final StoreOrder order;

  @override
  Widget build(BuildContext context) {
    final stopped = const ['ditolak', 'dibatalkan'].contains(order.status);
    final reached = stopped ? 0 : orderSteps.indexOf(order.status);
    const labels = ['Dikirim', 'Diterima', 'Diproses', 'Siap', 'Selesai'];
    return Row(
      children: [
        for (var i = 0; i < orderSteps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: i <= reached ? 1 : 0),
                  duration: Duration(milliseconds: 400 + i * 120),
                  curve: Curves.elasticOut,
                  builder: (_, v, _) => Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        const Color(0xFFE2E6F5),
                        stopped ? danger : mint,
                        v,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Transform.scale(
                      scale: .6 + v * .4,
                      child: const SpotIcon(
                        Glyph.check,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: i <= reached ? ink : muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Daftar pesanan pembeli, dipakai di Profil.
class MyOrders extends StatefulWidget {
  const MyOrders({super.key, required this.repo});
  final SpotsRepository repo;
  @override
  State<MyOrders> createState() => _MyOrdersState();
}

class _MyOrdersState extends State<MyOrders> {
  late Future<List<StoreOrder>> orders = widget.repo.myOrders();

  @override
  Widget build(BuildContext context) => FutureBuilder<List<StoreOrder>>(
    future: orders,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Notice(
          friendlyError(snapshot.error!),
          onRetry: () => setState(() => orders = widget.repo.myOrders()),
        );
      }
      if (!snapshot.hasData) {
        return const Shimmer(
          child: Column(
            children: [
              Bone(height: 76, radius: 24),
              SizedBox(height: 10),
              Bone(height: 76, radius: 24),
            ],
          ),
        );
      }
      if (snapshot.data!.isEmpty) {
        return const EmptyState(
          title: 'Belum ada\npesanan.',
          mood: PikoMood.sleepy,
          kind: MascotKind.tote,
        );
      }
      return Column(
        children: [
          for (final (i, order) in snapshot.data!.indexed)
            Rise(
              index: i,
              child: OrderTile(
                order: order,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          OrderPage(repo: widget.repo, orderId: order.id),
                    ),
                  );
                  if (mounted) setState(() => orders = widget.repo.myOrders());
                },
              ),
            ),
        ],
      );
    },
  );
}
