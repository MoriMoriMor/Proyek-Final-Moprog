import 'package:flutter_test/flutter_test.dart';
import 'package:spots/demo_repository.dart';
import 'package:spots/market.dart';

const shopA = Store(
  id: 'a',
  ownerId: 'x',
  name: 'Toko A',
  category: 'kafe',
  address: 'Jl. A No. 1',
  lat: 0,
  lng: 0,
  contact: '0812',
  onlineOrders: true,
);
const shopB = Store(
  id: 'b',
  ownerId: 'y',
  name: 'Toko B',
  category: 'kuliner',
  address: 'Jl. B No. 2',
  lat: 0,
  lng: 0,
  contact: '0813',
  onlineOrders: true,
);
const kopi = Product(
  id: 'k',
  storeId: 'a',
  name: 'Kopi',
  price: 22000,
  stock: 2,
);
const roti = Product(
  id: 'r',
  storeId: 'b',
  name: 'Roti',
  price: 18000,
  stock: 9,
);

void main() {
  test('rupiah memakai titik ribuan', () {
    expect(rupiah(22000), 'Rp22.000');
    expect(rupiah(1250000), 'Rp1.250.000');
    expect(rupiah(500), 'Rp500');
  });

  test('keranjang hanya untuk satu toko dan tidak melebihi stok', () {
    final cart = Cart();
    cart.add(shopA, kopi);
    cart.add(shopA, kopi);
    cart.add(shopA, kopi);
    expect(cart.qtyOf('k'), 2);
    expect(cart.subtotal, 44000);

    final key = cart.requestKey;
    cart.add(shopB, roti);
    expect(cart.store?.id, 'b');
    expect(cart.qtyOf('k'), 0);
    expect(cart.requestKey, isNot(key));
  });

  test('pesanan demo memakai kunci permintaan agar tidak ganda', () async {
    final repo = DemoSpotsRepository();
    await repo.signIn('mira@mail.com', 'rahasia1');
    final shop = (await repo.store('s1'))!;
    final products = await repo.products('s1');
    final cart = Cart()..add(shop, products.first);

    final first = await repo.placeOrder(
      cart: cart,
      fulfillment: 'ambil',
      address: '',
      note: '',
    );
    final again = await repo.placeOrder(
      cart: cart,
      fulfillment: 'ambil',
      address: '',
      note: '',
    );
    expect(again, first);
    expect((await repo.myOrders()).length, 1);
  });

  test('pemilik tidak bisa memesan di tokonya sendiri', () async {
    final repo = DemoSpotsRepository();
    await repo.signIn('mira@mail.com', 'rahasia1');
    final own = (await repo.myStore())!;
    final cart = Cart()..add(own, (await repo.products(own.id)).first);
    expect(
      () => repo.placeOrder(
        cart: cart,
        fulfillment: 'ambil',
        address: '',
        note: '',
      ),
      throwsStateError,
    );
  });
}
