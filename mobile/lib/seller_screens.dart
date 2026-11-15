import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

import 'game.dart';
import 'market.dart';
import 'market_screens.dart';
import 'spot.dart';
import 'spot_views.dart';
import 'spots_repository.dart';
import 'ui/motion.dart';
import 'ui/piko.dart';
import 'ui/spot_icons.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

Future<String?> askReason(BuildContext context, String heading) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(heading, style: display(24)),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 200,
        decoration: const InputDecoration(hintText: 'Alasannya apa?'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text(
            'Kirim',
            style: TextStyle(color: danger, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

// ---------- Daftarkan toko ----------

class ApplyStorePage extends StatefulWidget {
  const ApplyStorePage({super.key, required this.repo, this.start});
  final SpotsRepository repo;
  final LatLng? start;
  @override
  State<ApplyStorePage> createState() => _ApplyStorePageState();
}

class _ApplyStorePageState extends State<ApplyStorePage> {
  final name = TextEditingController();
  final address = TextEditingController();
  final contact = TextEditingController();
  final note = TextEditingController();
  final map = MapController();
  late LatLng? point = widget.start;
  String category = 'kuliner', relation = 'pemilik';
  List<Spot> nearby = [];
  Spot? linked;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    for (final c in [name, address, contact, note]) {
      c.dispose();
    }
    map.dispose();
    super.dispose();
  }

  Future<void> findSpots() async {
    final p = point;
    if (p == null) return;
    try {
      final found = await widget.repo.feed(
        lat: p.latitude,
        lng: p.longitude,
        mode: 'near',
      );
      if (mounted) setState(() => nearby = found.take(6).toList());
    } catch (_) {}
  }

  Future<void> submit() async {
    final problem = name.text.trim().length < 2
        ? 'Nama tokonya apa?'
        : address.text.trim().length < 5
        ? 'Alamatnya belum lengkap.'
        : contact.text.trim().length < 5
        ? 'Isi nomor atau kontak usaha.'
        : point == null
        ? 'Tandai lokasi toko di peta.'
        : null;
    if (problem != null) {
      setState(() => error = problem);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repo.applyStore(
        name: name.text,
        category: category,
        address: address.text,
        lat: point!.latitude,
        lng: point!.longitude,
        contact: contact.text,
        relation: relation,
        note: note.text,
        postId: linked?.id,
      );
      GameState.instance.track('store');
      if (!mounted) return;
      final navigator = Navigator.of(context);
      await showCelebration(
        context,
        title: 'Pengajuan\nterkirim!',
        subtitle: 'Admin akan cek dulu, ya.',
        color: grape,
      );
      navigator.pop(true);
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            children: [
              Row(
                children: [
                  GlassButton(
                    glyph: Glyph.close,
                    label: 'Tutup',
                    onTap: () => Navigator.maybePop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Text('Daftarkan\ntoko', style: display(38))),
                  const SpotIcon(Glyph.store, size: 72, accent: yellow),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Admin cek manual. Biasanya nggak lama.',
                style: small,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: name,
                maxLength: 80,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
                decoration: const InputDecoration(
                  hintText: 'Nama toko',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 14),
              _chips<String>(
                values: const ['kuliner', 'kafe', 'destinasi', 'lainnya'],
                selected: category,
                label: (v) => v == 'destinasi'
                    ? 'Wisata/suvenir'
                    : marketCategoryOf(v).label,
                color: (v) => marketCategoryOf(v).color,
                onTap: (v) => setState(() => category = v),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: address,
                maxLength: 200,
                decoration: const InputDecoration(
                  hintText: 'Alamat lengkap',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contact,
                maxLength: 80,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'No. WhatsApp / kontak usaha',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kamu siapanya toko ini?',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              _chips<String>(
                values: relationLabel.keys.toList(),
                selected: relation,
                label: (v) => relationLabel[v]!,
                color: (_) => piko,
                onTap: (v) => setState(() => relation = v),
              ),
              const SizedBox(height: 16),
              _mapCard(),
              if (nearby.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Sudah ada di Spots?',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final spot in nearby)
                      ChoiceChip(
                        label: Text(spot.title),
                        selected: linked?.id == spot.id,
                        onSelected: (on) => setState(() {
                          linked = on ? spot : null;
                          if (on && name.text.isEmpty) name.text = spot.title;
                        }),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: note,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Info tambahan buat admin (opsional)',
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: error == null
                    ? const SizedBox(width: double.infinity)
                    : Notice(error!),
              ),
              const SizedBox(height: 16),
              Chunky(
                expand: true,
                color: grape,
                onTap: busy ? null : submit,
                child: Text(busy ? 'Mengirim…' : 'Kirim pengajuan'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _mapCard() => Container(
    height: 200,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: line, width: 2),
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: [
        FlutterMap(
          mapController: map,
          options: MapOptions(
            initialCenter: point ?? const LatLng(-6.2088, 106.8456),
            initialZoom: point == null ? 11 : 16,
            onTap: (_, latLng) {
              setState(() {
                point = latLng;
                linked = null;
              });
              findSpots();
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.spots.app',
            ),
            if (point != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: point!,
                    width: 44,
                    height: 52,
                    alignment: Alignment.topCenter,
                    child: SpotIcon(
                      Glyph.pin,
                      size: 44,
                      accent: marketCategoryOf(category).color,
                    ),
                  ),
                ],
              ),
          ],
        ),
        Positioned(
          left: 12,
          top: 12,
          child: Pill(
            child: Text(
              point == null ? 'Ketuk peta buat pin toko' : 'Pin terpasang',
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _chips<T>({
  required List<T> values,
  required T selected,
  required String Function(T) label,
  required Color Function(T) color,
  required ValueChanged<T> onTap,
}) => Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    for (final v in values)
      Bouncy(
        onTap: () => onTap(v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: v == selected ? color(v) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: v == selected ? edgeOf(color(v)) : line,
              width: 2,
            ),
          ),
          child: Text(
            label(v),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: v == selected ? Colors.white : ink,
            ),
          ),
        ),
      ),
  ],
);

// ---------- Dashboard toko ----------

class SellerPage extends StatefulWidget {
  const SellerPage({super.key, required this.repo, required this.store});
  final SpotsRepository repo;
  final Store store;
  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  late Store store = widget.store;
  int tab = 0;
  List<StoreOrder> orders = [];
  List<Product> products = [];
  bool loading = true, busy = false;
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
        widget.repo.storeOrders(store.id),
        widget.repo.products(store.id),
      ]);
      if (!mounted) return;
      setState(() {
        orders = results[0] as List<StoreOrder>;
        products = results[1] as List<Product>;
      });
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> act(StoreOrder order, String action) async {
    String? reason;
    if (action == 'reject') {
      reason = await askReason(context, 'Tolak pesanan?');
      if (reason == null) return;
    }
    setState(() => busy = true);
    try {
      await widget.repo.orderAction(order.id, action, reason);
      if (mounted) {
        message(context, switch (action) {
          'accept' => 'Pesanan diterima, stok sudah dipotong.',
          'reject' => 'Pesanan ditolak.',
          'confirm_payment' => 'Pembayaran lunas. Gas proses!',
          _ => 'Status diperbarui.',
        });
      }
      await load();
    } catch (e) {
      if (mounted) message(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final waiting = orders.where((o) => o.status == 'menunggu').length;
    return Scaffold(
      backgroundColor: pale,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
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
                          Bouncy(
                            onTap: () => openStore(
                              context,
                              widget.repo,
                              store.id,
                              initial: store,
                            ),
                            child: const Pill(
                              color: Colors.white,
                              child: Text('Lihat toko'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(store.name, style: display(32)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: store.onlineOrders ? mint : muted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            store.onlineOrders
                                ? 'Terima pesanan online'
                                : 'Hanya beli di lokasi',
                            style: small,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _StatBox(
                            value: '$waiting',
                            label: 'baru',
                            color: caramel,
                          ),
                          const SizedBox(width: 10),
                          _StatBox(
                            value:
                                '${orders.where((o) => const ['diterima', 'diproses', 'siap'].contains(o.status)).length}',
                            label: 'berjalan',
                            color: piko,
                          ),
                          const SizedBox(width: 10),
                          _StatBox(
                            value: '${products.length}',
                            label: 'produk',
                            color: mint,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _tabs(waiting),
                      const SizedBox(height: 14),
                      if (error != null) Notice(error!, onRetry: load),
                      if (loading)
                        const Shimmer(
                          child: Column(
                            children: [
                              Bone(height: 120, radius: 24),
                              SizedBox(height: 10),
                              Bone(height: 120, radius: 24),
                            ],
                          ),
                        )
                      else
                        switch (tab) {
                          0 => _orders(),
                          1 => _products(),
                          _ => _StoreSettings(
                            store: store,
                            repo: widget.repo,
                            onSaved: (s) => setState(() => store = s),
                          ),
                        },
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: tab == 1
          ? Chunky(
              onTap: () => editProduct(null),
              color: coral,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpotIcon(Glyph.plus, size: 22, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Produk'),
                ],
              ),
            )
          : null,
    );
  }

  Widget _tabs(int waiting) => Container(
    height: 52,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: line, width: 2),
    ),
    child: Row(
      children: [
        for (final (i, label) in ['Pesanan', 'Produk', 'Atur'].indexed)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => tab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tab == i ? ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: tab == i ? Colors.white : muted,
                      ),
                    ),
                    if (i == 0 && waiting > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: coral,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$waiting',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _orders() {
    if (orders.isEmpty) {
      return const EmptyState(
        title: 'Belum ada pesanan\nmasuk.',
        mood: PikoMood.sleepy,
      );
    }
    return Column(
      children: [
        for (final (i, o) in orders.indexed)
          Rise(index: i, child: _sellerOrder(o)),
      ],
    );
  }

  Widget _sellerOrder(StoreOrder o) {
    final actions = <Widget>[
      if (o.status == 'menunggu') ...[
        Expanded(
          child: Chunky(
            expand: true,
            color: Colors.white,
            edge: line,
            border: line,
            onTap: busy ? null : () => act(o, 'reject'),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Text('Tolak', style: TextStyle(color: danger)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Chunky(
            expand: true,
            color: mint,
            onTap: busy ? null : () => act(o, 'accept'),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Text('Terima'),
          ),
        ),
      ],
      if (o.status == 'diterima')
        Expanded(
          child: Chunky(
            expand: true,
            color: piko,
            onTap: busy ? null : () => act(o, 'confirm_payment'),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              o.paymentStatus == 'menunggu_konfirmasi'
                  ? 'Konfirmasi lunas'
                  : 'Tandai lunas',
            ),
          ),
        ),
      if (o.status == 'diproses' || o.status == 'siap')
        Expanded(
          child: Chunky(
            expand: true,
            color: grape,
            onTap: busy ? null : () => act(o, 'advance'),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(o.status == 'diproses' ? 'Tandai siap' : 'Selesai'),
          ),
        ),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: o.status == 'menunggu' ? caramel : line,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Avatar(o.buyerName, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.buyerName, style: title.copyWith(fontSize: 15)),
                    Text(
                      o.fulfillment == 'kirim'
                          ? 'Kirim · ${o.address}'
                          : 'Ambil di lokasi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: small.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              StatusChip(o.status),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in o.items)
            Text(
              '${item.qty}× ${item.name}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          if (o.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '"${o.note}"',
                style: small.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(rupiah(o.total), style: display(20)),
              const Spacer(),
              if (o.status != 'menunggu' && !o.closed)
                Pill(
                  color: o.paymentStatus == 'lunas'
                      ? const Color(0xFFDDF7EE)
                      : const Color(0xFFFFF4D6),
                  child: Text(paymentStatusLabel[o.paymentStatus] ?? ''),
                ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: actions),
          ],
        ],
      ),
    );
  }

  Widget _products() {
    if (products.isEmpty) {
      return EmptyState(
        title: 'Tambah produk\npertamamu.',
        action: 'Tambah produk',
        color: coral,
        onAction: () => editProduct(null),
      );
    }
    return Column(
      children: [
        for (final (i, p) in products.indexed)
          Rise(
            index: i,
            child: Bouncy(
              scale: .97,
              onTap: () => editProduct(p),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: line, width: 2),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox.square(
                        dimension: 58,
                        child: ProductImage(product: p, repo: widget.repo),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: title.copyWith(fontSize: 15)),
                          Text(
                            '${rupiah(p.price)} · stok ${p.stock}',
                            style: small.copyWith(fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    if (!p.active)
                      const Pill(
                        color: Color(0xFFE9ECF7),
                        child: Text('Disembunyikan'),
                      )
                    else if (p.soldOut)
                      const Pill(
                        color: Color(0xFFFFEEF0),
                        child: Text('Habis', style: TextStyle(color: danger)),
                      ),
                    const SizedBox(width: 4),
                    const SpotIcon(Glyph.pencil, size: 20, accent: yellow),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> editProduct(Product? product) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _ProductForm(repo: widget.repo, storeId: store.id, product: product),
    );
    if (saved == true) load();
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value, label;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: edgeOf(color), offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(value, style: display(26, color: Colors.white)),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProductForm extends StatefulWidget {
  const _ProductForm({required this.repo, required this.storeId, this.product});
  final SpotsRepository repo;
  final String storeId;
  final Product? product;
  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  late final name = TextEditingController(text: widget.product?.name);
  late final description = TextEditingController(
    text: widget.product?.description,
  );
  late final price = TextEditingController(
    text: widget.product?.price.toString(),
  );
  late final stock = TextEditingController(
    text: widget.product?.stock.toString() ?? '10',
  );
  late bool active = widget.product?.active ?? true;
  XFile? image;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    for (final c in [name, description, price, stock]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    final p = int.tryParse(price.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final s = int.tryParse(stock.text.trim());
    if (name.text.trim().length < 2 ||
        p == null ||
        p < 100 ||
        s == null ||
        s < 0) {
      setState(() => error = 'Isi nama, harga (min Rp100), dan stok.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repo.saveProduct(
        storeId: widget.storeId,
        id: widget.product?.id,
        name: name.text,
        description: description.text,
        price: p,
        stock: s,
        active: active,
        image: image,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> remove() async {
    setState(() => busy = true);
    try {
      await widget.repo.deleteProduct(widget.product!.id);
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
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.product == null ? 'Produk baru' : 'Ubah produk',
                  style: display(28),
                ),
                const SizedBox(height: 14),
                Bouncy(
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (picked != null) setState(() => image = picked);
                  },
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F2FF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: grape.withValues(alpha: .4),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SpotIcon(Glyph.camera, size: 34, accent: grape),
                        const SizedBox(height: 4),
                        Text(
                          image != null ? image!.name : 'Pilih foto produk',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: grape,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: name,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    hintText: 'Nama produk',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Harga',
                          prefixText: 'Rp ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: stock,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Stok',
                          suffixText: 'pcs',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: description,
                  maxLength: 300,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Deskripsi singkat (opsional)',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: active,
                  activeThumbColor: mint,
                  onChanged: (v) => setState(() => active = v),
                  title: const Text(
                    'Tampilkan di katalog',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                if (error != null) Notice(error!),
                const SizedBox(height: 10),
                Chunky(
                  expand: true,
                  color: coral,
                  onTap: busy ? null : save,
                  child: Text(busy ? 'Menyimpan…' : 'Simpan'),
                ),
                if (widget.product != null)
                  TextButton(
                    onPressed: busy ? null : remove,
                    child: const Text(
                      'Hapus produk',
                      style: TextStyle(
                        color: danger,
                        fontWeight: FontWeight.w900,
                      ),
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

class _StoreSettings extends StatefulWidget {
  const _StoreSettings({
    required this.store,
    required this.repo,
    required this.onSaved,
  });
  final Store store;
  final SpotsRepository repo;
  final ValueChanged<Store> onSaved;
  @override
  State<_StoreSettings> createState() => _StoreSettingsState();
}

class _StoreSettingsState extends State<_StoreSettings> {
  late bool online = widget.store.onlineOrders,
      pickup = widget.store.pickup,
      delivery = widget.store.delivery;
  late final fee = TextEditingController(text: '${widget.store.deliveryFee}');
  late final payment = TextEditingController(text: widget.store.paymentInfo);
  late final description = TextEditingController(
    text: widget.store.description,
  );
  late final contact = TextEditingController(text: widget.store.contact);
  bool busy = false;
  String? error;

  @override
  void dispose() {
    for (final c in [fee, payment, description, contact]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (online && !pickup && !delivery) {
      setState(() => error = 'Pilih minimal ambil atau kirim.');
      return;
    }
    if (online && payment.text.trim().length < 5) {
      setState(
        () => error = 'Tulis cara bayar dulu, misal nomor rekening atau QRIS.',
      );
      return;
    }
    final updated = widget.store.copyWith(
      onlineOrders: online,
      pickup: pickup,
      delivery: delivery,
      deliveryFee:
          int.tryParse(fee.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      paymentInfo: payment.text.trim(),
      description: description.text.trim(),
      contact: contact.text.trim(),
    );
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repo.updateStore(updated);
      widget.onSaved(updated);
      if (mounted) message(context, 'Pengaturan toko tersimpan.');
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _switch(
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    String? sub,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: line, width: 2),
    ),
    child: SwitchListTile(
      value: value,
      activeThumbColor: mint,
      onChanged: onChanged,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: sub == null
          ? null
          : Text(sub, style: small.copyWith(fontSize: 12)),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _switch(
        'Terima pesanan online',
        online,
        (v) => setState(() => online = v),
        sub: online ? null : 'Pembeli melihat tombol "Beli di lokasi".',
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 250),
        child: !online
            ? const SizedBox(width: double.infinity)
            : Column(
                children: [
                  _switch(
                    'Ambil di lokasi',
                    pickup,
                    (v) => setState(() => pickup = v),
                  ),
                  _switch(
                    'Kirim ke alamat',
                    delivery,
                    (v) => setState(() => delivery = v),
                  ),
                  if (delivery)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: fee,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Ongkir tetap',
                          prefixText: 'Rp ',
                        ),
                      ),
                    ),
                  TextField(
                    controller: payment,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Cara bayar: rekening, e-wallet, atau QRIS',
                    ),
                  ),
                ],
              ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: description,
        maxLength: 500,
        maxLines: 3,
        decoration: const InputDecoration(hintText: 'Deskripsi toko'),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: contact,
        maxLength: 80,
        decoration: const InputDecoration(hintText: 'Kontak', counterText: ''),
      ),
      if (error != null) Notice(error!),
      const SizedBox(height: 14),
      Chunky(
        expand: true,
        color: ink,
        edge: Colors.black,
        onTap: busy ? null : save,
        child: Text(busy ? 'Menyimpan…' : 'Simpan pengaturan'),
      ),
    ],
  );
}

// ---------- Review admin ----------

class AdminReviewPage extends StatefulWidget {
  const AdminReviewPage({super.key, required this.repo});
  final SpotsRepository repo;
  @override
  State<AdminReviewPage> createState() => _AdminReviewPageState();
}

class _AdminReviewPageState extends State<AdminReviewPage> {
  late Future<List<StoreApplication>> items = widget.repo.pendingApplications();
  bool busy = false;

  Future<void> review(StoreApplication app, bool approve) async {
    String? reason;
    if (!approve) {
      reason = await askReason(context, 'Tolak pengajuan?');
      if (reason == null) return;
    }
    setState(() => busy = true);
    try {
      await widget.repo.reviewApplication(app.id, approve, reason);
      if (mounted) {
        message(
          context,
          approve ? '${app.storeName} disetujui.' : 'Pengajuan ditolak.',
        );
      }
      setState(() => items = widget.repo.pendingApplications());
    } catch (e) {
      if (mounted) message(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: pale,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Review toko', style: display(34)),
                  const SizedBox(height: 14),
                  FutureBuilder<List<StoreApplication>>(
                    future: items,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Notice(friendlyError(snapshot.error!));
                      }
                      if (!snapshot.hasData) {
                        return const Shimmer(
                          child: Bone(height: 200, radius: 26),
                        );
                      }
                      if (snapshot.data!.isEmpty) {
                        return const EmptyState(
                          title: 'Semua pengajuan\nsudah dicek.',
                          mood: PikoMood.wink,
                        );
                      }
                      return Column(
                        children: [
                          for (final (i, app) in snapshot.data!.indexed)
                            Rise(index: i, child: _application(app)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _application(StoreApplication app) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: line, width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CategorySticker(marketCategoryOf(app.category)),
            const Spacer(),
            Text(app.applicantName, style: small),
          ],
        ),
        const SizedBox(height: 10),
        Text(app.storeName, style: display(24)),
        const SizedBox(height: 6),
        Text(app.address, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text('${relationLabel[app.relation]} · ${app.contact}', style: small),
        if (app.note.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '"${app.note}"',
            style: small.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
        TextButton.icon(
          onPressed: () => launchUrl(
            Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=${app.lat},${app.lng}',
            ),
            mode: LaunchMode.externalApplication,
          ),
          icon: const SpotIcon(Glyph.pin, size: 18, accent: coral),
          label: const Text(
            'Cek lokasi',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Chunky(
                expand: true,
                color: Colors.white,
                edge: line,
                border: line,
                onTap: busy ? null : () => review(app, false),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Text('Tolak', style: TextStyle(color: danger)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Chunky(
                expand: true,
                color: mint,
                onTap: busy ? null : () => review(app, true),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Text('Setujui'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Kartu status toko untuk Profil: daftar, menunggu, ditolak, atau kelola.
class StoreEntryCard extends StatefulWidget {
  const StoreEntryCard({super.key, required this.repo, this.start});
  final SpotsRepository repo;
  final LatLng? start;
  @override
  State<StoreEntryCard> createState() => _StoreEntryCardState();
}

class _StoreEntryCardState extends State<StoreEntryCard> {
  Store? store;
  StoreApplication? latest;
  bool admin = false, loaded = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        widget.repo.myStore(),
        widget.repo.myApplications(),
        widget.repo.isAdmin(),
      ]);
      if (!mounted) return;
      setState(() {
        store = results[0] as Store?;
        final apps = results[1] as List<StoreApplication>;
        latest = apps.isEmpty ? null : apps.first;
        admin = results[2] as bool;
        loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const Shimmer(child: Bone(height: 76, radius: 24));
    final shop = store;
    final pending = latest?.status == 'menunggu';
    final rejected = latest?.status == 'ditolak' && shop == null;
    return Column(
      children: [
        _EntryTile(
          glyph: Glyph.store,
          color: shop != null
              ? mint
              : pending
              ? caramel
              : rejected
              ? danger
              : yellow,
          title:
              shop?.name ?? (pending ? 'Toko lagi direview' : 'Daftarkan toko'),
          sub: shop != null
              ? 'Kelola pesanan & produk'
              : pending
              ? latest!.storeName
              : rejected
              ? 'Ditolak: ${latest!.rejectReason ?? '-'}'
              : 'Jual produk dari tempatmu',
          onTap: pending
              ? null
              : () async {
                  if (shop != null) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SellerPage(repo: widget.repo, store: shop),
                      ),
                    );
                  } else {
                    await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => ApplyStorePage(
                          repo: widget.repo,
                          start: widget.start,
                        ),
                      ),
                    );
                  }
                  load();
                },
        ),
        if (admin)
          _EntryTile(
            glyph: Glyph.shield,
            color: grape,
            title: 'Review pengajuan toko',
            sub: 'Khusus admin',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminReviewPage(repo: widget.repo),
                ),
              );
              load();
            },
          ),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.glyph,
    required this.color,
    required this.title,
    required this.sub,
    required this.onTap,
  });
  final Glyph glyph;
  final Color color;
  final String title, sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Bouncy(
      scale: .97,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: line, width: 2),
          boxShadow: const [BoxShadow(color: line, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: edgeOf(color), offset: const Offset(0, 3)),
                ],
              ),
              child: SpotIcon(
                glyph,
                size: 26,
                color: Colors.white,
                accent: edgeOf(color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _tileTitle,
                  ),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: small.copyWith(fontSize: 12.5),
                  ),
                ],
              ),
            ),
            if (onTap != null)
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
    ),
  );
}

final _tileTitle = title.copyWith(fontSize: 15.5);
