import 'dart:math' as math;

import 'package:flutter/foundation.dart';

String rupiah(int value) {
  final digits = value.abs().toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  return '${value < 0 ? '-' : ''}Rp$out';
}

/// UUID acak untuk kunci permintaan pesanan.
String newRequestKey() {
  final random = math.Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}

int _int(Object? value) => (value as num?)?.toInt() ?? 0;
double _double(Object? value) => (value as num?)?.toDouble() ?? 0;

class Store {
  const Store({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    required this.address,
    required this.lat,
    required this.lng,
    required this.contact,
    this.description = '',
    this.onlineOrders = false,
    this.pickup = true,
    this.delivery = false,
    this.deliveryFee = 0,
    this.paymentInfo = '',
    this.active = true,
  });

  final String id, ownerId, name, category, address, contact, description;
  final String paymentInfo;
  final double lat, lng;
  final bool onlineOrders, pickup, delivery, active;
  final int deliveryFee;

  factory Store.fromJson(Map<String, dynamic> json) => Store(
    id: json['id'] as String,
    ownerId: json['owner_id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    category: json['category'] as String? ?? 'lainnya',
    address: json['address'] as String? ?? '',
    lat: _double(json['lat']),
    lng: _double(json['lng']),
    contact: json['contact'] as String? ?? '',
    description: json['description'] as String? ?? '',
    onlineOrders: json['online_orders'] as bool? ?? false,
    pickup: json['pickup'] as bool? ?? true,
    delivery: json['delivery'] as bool? ?? false,
    deliveryFee: _int(json['delivery_fee']),
    paymentInfo: json['payment_info'] as String? ?? '',
    active: json['active'] as bool? ?? true,
  );

  Map<String, dynamic> settings() => {
    'description': description,
    'contact': contact,
    'online_orders': onlineOrders,
    'pickup': pickup,
    'delivery': delivery,
    'delivery_fee': deliveryFee,
    'payment_info': paymentInfo,
  };

  Store copyWith({
    String? description,
    String? contact,
    bool? onlineOrders,
    bool? pickup,
    bool? delivery,
    int? deliveryFee,
    String? paymentInfo,
  }) => Store(
    id: id,
    ownerId: ownerId,
    name: name,
    category: category,
    address: address,
    lat: lat,
    lng: lng,
    contact: contact ?? this.contact,
    description: description ?? this.description,
    onlineOrders: onlineOrders ?? this.onlineOrders,
    pickup: pickup ?? this.pickup,
    delivery: delivery ?? this.delivery,
    deliveryFee: deliveryFee ?? this.deliveryFee,
    paymentInfo: paymentInfo ?? this.paymentInfo,
    active: active,
  );
}

class Product {
  const Product({
    required this.id,
    required this.storeId,
    required this.name,
    required this.price,
    required this.stock,
    this.description = '',
    this.imagePath,
    this.active = true,
    this.storeName,
  });

  final String id, storeId, name, description;
  final int price, stock;
  final String? imagePath, storeName;
  final bool active;

  bool get soldOut => stock <= 0;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    storeId: json['store_id'] as String,
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    price: _int(json['price']),
    stock: _int(json['stock']),
    imagePath: json['image_path'] as String?,
    active: json['active'] as bool? ?? true,
    storeName: (json['stores'] as Map?)?['name'] as String?,
  );
}

class OrderLine {
  const OrderLine({
    required this.name,
    required this.unitPrice,
    required this.qty,
  });
  final String name;
  final int unitPrice, qty;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
    name: json['name'] as String? ?? '',
    unitPrice: _int(json['unit_price']),
    qty: _int(json['qty']),
  );
}

const orderSteps = ['menunggu', 'diterima', 'diproses', 'siap', 'selesai'];

const orderStatusLabel = {
  'menunggu': 'Menunggu toko',
  'diterima': 'Diterima',
  'ditolak': 'Ditolak',
  'diproses': 'Diproses',
  'siap': 'Siap',
  'selesai': 'Selesai',
  'dibatalkan': 'Dibatalkan',
};

const paymentStatusLabel = {
  'belum': 'Belum bayar',
  'menunggu_konfirmasi': 'Cek pembayaran',
  'lunas': 'Lunas',
};

class StoreOrder {
  const StoreOrder({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.buyerName,
    required this.status,
    required this.paymentStatus,
    required this.fulfillment,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.items,
    required this.createdAt,
    this.address = '',
    this.note = '',
    this.rejectReason,
    this.paymentInfo = '',
  });

  final String id, storeId, storeName, buyerName, status, paymentStatus;
  final String fulfillment, address, note, paymentInfo;
  final String? rejectReason;
  final int subtotal, shippingFee, total;
  final List<OrderLine> items;
  final DateTime createdAt;

  bool get closed =>
      const ['ditolak', 'selesai', 'dibatalkan'].contains(status);
  int get itemCount => items.fold(0, (sum, item) => sum + item.qty);

  factory StoreOrder.fromJson(Map<String, dynamic> json) {
    final store = json['stores'] as Map?;
    final buyer = json['profiles'] as Map?;
    final lines =
        ((json['order_items'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
          ..sort((a, b) => _int(a['line']).compareTo(_int(b['line'])));
    return StoreOrder(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      storeName: store?['name'] as String? ?? '',
      paymentInfo: store?['payment_info'] as String? ?? '',
      buyerName: buyer?['display_name'] as String? ?? 'Pembeli',
      status: json['status'] as String? ?? 'menunggu',
      paymentStatus: json['payment_status'] as String? ?? 'belum',
      fulfillment: json['fulfillment'] as String? ?? 'ambil',
      address: json['address'] as String? ?? '',
      note: json['note'] as String? ?? '',
      rejectReason: json['reject_reason'] as String?,
      subtotal: _int(json['subtotal']),
      shippingFee: _int(json['shipping_fee']),
      total: _int(json['total']),
      items: lines.map(OrderLine.fromJson).toList(),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

const relationLabel = {
  'pemilik': 'Pemilik',
  'pengelola': 'Pengelola',
  'keluarga': 'Keluarga pemilik',
  'karyawan': 'Karyawan',
};

class StoreApplication {
  const StoreApplication({
    required this.id,
    required this.storeName,
    required this.category,
    required this.address,
    required this.lat,
    required this.lng,
    required this.contact,
    required this.relation,
    required this.status,
    required this.createdAt,
    this.note = '',
    this.rejectReason,
    this.applicantName = '',
    this.applicantId = '',
  });

  final String id, storeName, category, address, contact, relation, status;
  final String note, applicantName, applicantId;
  final String? rejectReason;
  final double lat, lng;
  final DateTime createdAt;

  factory StoreApplication.fromJson(Map<String, dynamic> json) =>
      StoreApplication(
        id: json['id'] as String,
        storeName: json['store_name'] as String? ?? '',
        category: json['category'] as String? ?? 'lainnya',
        address: json['address'] as String? ?? '',
        lat: _double(json['lat']),
        lng: _double(json['lng']),
        contact: json['contact'] as String? ?? '',
        relation: json['relation'] as String? ?? 'pemilik',
        note: json['note'] as String? ?? '',
        status: json['status'] as String? ?? 'menunggu',
        rejectReason: json['reject_reason'] as String?,
        applicantId: json['applicant_id'] as String? ?? '',
        applicantName:
            (json['profiles'] as Map?)?['display_name'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

class CartLine {
  CartLine(this.product, this.qty);
  Product product;
  int qty;
}

/// Keranjang untuk satu toko per pesanan.
class Cart extends ChangeNotifier {
  Store? store;
  final lines = <String, CartLine>{};

  /// Kunci dipakai ulang sampai pesanan berhasil, supaya kirim ulang aman.
  String requestKey = newRequestKey();

  int get count => lines.values.fold(0, (sum, line) => sum + line.qty);
  int get subtotal =>
      lines.values.fold(0, (sum, line) => sum + line.product.price * line.qty);
  int qtyOf(String productId) => lines[productId]?.qty ?? 0;

  bool belongsTo(Store other) => store == null || store!.id == other.id;

  void add(Store shop, Product product) {
    if (!belongsTo(shop)) clear();
    store = shop;
    final line = lines[product.id];
    if (line == null) {
      lines[product.id] = CartLine(product, 1);
    } else if (line.qty < math.min(99, product.stock)) {
      line.qty++;
    }
    requestKey = newRequestKey();
    notifyListeners();
  }

  void remove(String productId) {
    final line = lines[productId];
    if (line == null) return;
    line.qty--;
    if (line.qty <= 0) lines.remove(productId);
    if (lines.isEmpty) store = null;
    requestKey = newRequestKey();
    notifyListeners();
  }

  /// Menyegarkan harga dan stok dari katalog terbaru.
  void refreshProducts(List<Product> fresh) {
    for (final product in fresh) {
      final line = lines[product.id];
      if (line == null) continue;
      line.product = product;
      if (!product.active || product.stock <= 0) {
        lines.remove(product.id);
      } else if (line.qty > product.stock) {
        line.qty = product.stock;
      }
    }
    if (lines.isEmpty) store = null;
    notifyListeners();
  }

  void clear() {
    lines.clear();
    store = null;
    requestKey = newRequestKey();
    notifyListeners();
  }
}
