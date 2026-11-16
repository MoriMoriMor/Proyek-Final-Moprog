// Audit ukuran: render setiap layar di berbagai ukuran perangkat dan
// pastikan tidak ada overflow (garis kuning-hitam).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spots/demo_repository.dart';
import 'package:spots/game.dart';
import 'package:spots/market_screens.dart';
import 'package:spots/people_page.dart';
import 'package:spots/profile_page.dart';
import 'package:spots/route_page.dart';
import 'package:spots/seller_screens.dart';
import 'package:spots/spot_views.dart';
import 'package:spots/spots_app.dart';
import 'package:spots/create_spot_screen.dart';
import 'package:spots/ui/theme.dart';
import 'package:spots/welcome.dart';

const sizes = <String, Size>{
  'android-kecil 320x568': Size(320, 568),
  'android 360x640': Size(360, 640),
  'iphone-se 375x667': Size(375, 667),
  'iphone 390x844': Size(390, 844),
  'android-besar 412x915': Size(412, 915),
  'iphone-pro-max 430x932': Size(430, 932),
  'android-landscape 640x360': Size(640, 360),
  'iphone-landscape 844x390': Size(844, 390),
  'tablet 768x1024': Size(768, 1024),
  'tablet-landscape 1024x768': Size(1024, 768),
  'laptop 1280x720': Size(1280, 720),
  'desktop 1920x1080': Size(1920, 1080),
};

Future<void> loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('assets/fonts/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('Nunito', [
    'Nunito-600.ttf',
    'Nunito-700.ttf',
    'Nunito-800.ttf',
    'Nunito-900.ttf',
  ]);
  await load('Bagel Fat One', ['BagelFatOne-Regular.ttf']);
}

final problems = <String>{};

Future<void> audit(
  WidgetTester tester,
  String screen,
  Widget Function(DemoSpotsRepository repo) build, {
  Future<void> Function(WidgetTester t)? act,
  double textScale = 1,
  bool signedIn = true,
}) async {
  for (final entry in sizes.entries) {
    tester.view.physicalSize = entry.value;
    tester.view.devicePixelRatio = 1;
    final repo = DemoSpotsRepository();
    if (signedIn) {
      await tester.runAsync(() => repo.signIn('mira@mail.com', 'rahasia1'));
    }
    final old = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.toString();
      if (text.contains('overflowed')) {
        final where = RegExp(r'file:///[^\s]*lib/([^\s:]+:\d+)')
            .firstMatch(text)
            ?.group(1);
        final amount = RegExp(r'overflowed by ([\d.]+) pixels on the (\w+)')
            .firstMatch(text);
        problems.add(
          '$screen @ ${entry.key}${textScale != 1 ? ' teks x$textScale' : ''}: '
          '${amount?.group(1)}px ${amount?.group(2)} — ${where ?? '?'}',
        );
      }
    };
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: rootNavigator,
        theme: spotsTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: build(repo),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    if (act != null) {
      try {
        await act(tester);
      } catch (_) {}
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
    }
    FlutterError.onError = old;
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
  }
  tester.view.resetPhysicalSize();
}

Future<void> tapText(WidgetTester t, String text) async {
  var f = find.text(text);
  if (f.evaluate().isEmpty) f = find.byTooltip(text);
  if (f.evaluate().isEmpty) f = find.bySemanticsLabel(text);
  if (f.evaluate().isEmpty) {
    problems.add('(audit) tidak menemukan tombol "$text"');
    return;
  }
  await t.tap(f.last, warnIfMissed: false);
}

void main() {
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('spots_audit').path;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => dir,
        );
    SharedPreferences.setMockInitialValues({'onboarded': true});
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadFonts();
    await GameState.instance.load();
  });

  tearDownAll(() {
    final out = problems.toList()..sort();
    File('build/layout_audit.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync(out.join('\n'));
    // ignore: avoid_print
    print('OVERFLOW: ${out.length}\n${out.join('\n')}');
  });

  for (final scale in [1.0, 1.3]) {
    final s = scale == 1 ? '' : ' (teks 1.3)';
    testWidgets('welcome$s', (t) async {
      await audit(
        t,
        'Welcome',
        (r) => WelcomePage(repo: r, onDone: () {}),
        textScale: scale,
        signedIn: false,
      );
    });
    const expected = {
      'Beranda': 'Mau ke mana',
      'Reels': 'Simpan',
      'Market': 'Lagi laris',
      'Profil': 'Edit profil',
      'Peta': 'Lokasiku',
      'Jelajah': 'Lagi rame',
    };
    for (final tab in expected.keys) {
      testWidgets('shell $tab$s', (t) async {
        await audit(
          t,
          'Shell/$tab',
          (r) => SpotsShell(repo: r),
          textScale: scale,
          act: (t) async {
            if (tab == 'Beranda') return;
            await tapText(t, tab);
            for (var i = 0; i < 4; i++) {
              await t.pump(const Duration(milliseconds: 300));
            }
            final want = expected[tab]!;
            final ok =
                find.text(want).evaluate().isNotEmpty ||
                find.byTooltip(want).evaluate().isNotEmpty ||
                find.bySemanticsLabel(want).evaluate().isNotEmpty;
            if (!ok) {
              problems.add(
                '(audit) tab $tab tidak terbuka @ ${t.view.physicalSize}',
              );
            }
          },
        );
      });
    }
    testWidgets('pesanan detail$s', (t) async {
      await audit(
        t,
        'Detail pesanan',
        (r) => _Async(
          load: () => r.myOrders(),
          builder: (o) => (o as List).isEmpty
              ? const Text('kosong')
              : OrderPage(repo: r, orderId: o.first.id),
        ),
        textScale: scale,
      );
    });
    testWidgets('edit profil$s', (t) async {
      await audit(
        t,
        'Edit profil',
        (r) => _Async(
          load: () => r.myProfile(),
          builder: (p) => Scaffold(
            body: SingleChildScrollView(
              child: EditProfileSheet(repo: r, profile: p as dynamic),
            ),
          ),
        ),
        textScale: scale,
      );
    });
    testWidgets('keranjang isi$s', (t) async {
      await audit(
        t,
        'Keranjang berisi',
        (r) => _Async(
          load: () async {
            final st = (await r.stores()).first;
            final ps = await r.products(st.id);
            cart.lines.clear();
            cart.store = null;
            for (final p in ps.take(3)) {
              cart.add(st, p);
            }
            return null;
          },
          builder: (_) => Scaffold(body: CartSheet(repo: r)),
        ),
        textScale: scale,
      );
    });
    testWidgets('level up$s', (t) async {
      await audit(
        t,
        'Level up',
        (r) => Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => showCelebration(
                context,
                title: 'Level 12!',
                subtitle: 'Makin jago nyari spot.',
                actionLabel: 'Pamerin ke teman',
                onAction: () {},
              ),
            );
            return const SizedBox.expand();
          },
        ),
        textScale: scale,
      );
    });
    testWidgets('detail$s', (t) async {
      late DemoSpotsRepository repo;
      await audit(t, 'Detail spot', (r) {
        repo = r;
        return _Async(
          load: () => r.feed(mode: 'popular'),
          builder: (spots) => SpotDetail(
            spot: (spots as List).first,
            repo: repo,
            onChanged: () {},
          ),
        );
      }, textScale: scale);
    });
    testWidgets('people$s', (t) async {
      await audit(
        t,
        'Cari teman',
        (r) => PeoplePage(repo: r),
        textScale: scale,
      );
    });
    testWidgets('route$s', (t) async {
      await audit(
        t,
        'Rute',
        (r) => const RoutePage(
          name: 'Rawon Setan Mbak Endang',
          lat: -7.26,
          lng: 112.73,
        ),
        textScale: scale,
      );
    });
    testWidgets('create$s', (t) async {
      await audit(
        t,
        'Bagikan spot',
        (r) => CreateSpotScreen(repo: r),
        textScale: scale,
      );
    });
    testWidgets('profile$s', (t) async {
      await audit(
        t,
        'Profil orang',
        (r) => ProfilePage(repo: r, userId: 'u-Nadia'),
        textScale: scale,
      );
    });
    testWidgets('market$s', (t) async {
      await audit(
        t,
        'Market',
        (r) => Scaffold(body: MarketTab(repo: r)),
        textScale: scale,
      );
    });
    testWidgets('store$s', (t) async {
      await audit(
        t,
        'Toko',
        (r) => _Async(
          load: () => r.stores(),
          builder: (s) => StorePage(repo: r, storeId: (s as List).first.id),
        ),
        textScale: scale,
      );
    });
    testWidgets('cart$s', (t) async {
      await audit(
        t,
        'Keranjang',
        (r) => Scaffold(body: CartSheet(repo: r)),
        textScale: scale,
      );
    });
    testWidgets('orders$s', (t) async {
      await audit(
        t,
        'Pesanan saya',
        (r) => MyOrders(repo: r),
        textScale: scale,
      );
    });
    testWidgets('apply$s', (t) async {
      await audit(
        t,
        'Daftar toko',
        (r) => ApplyStorePage(repo: r),
        textScale: scale,
      );
    });
    testWidgets('seller$s', (t) async {
      await audit(
        t,
        'Penjual',
        (r) => _Async(
          load: () => r.myStore(),
          builder: (s) => s == null
              ? const SizedBox()
              : SellerPage(repo: r, store: s as dynamic),
        ),
        textScale: scale,
      );
    });
    testWidgets('admin$s', (t) async {
      await audit(
        t,
        'Admin',
        (r) => AdminReviewPage(repo: r),
        textScale: scale,
      );
    });
    testWidgets('auth$s', (t) async {
      await audit(
        t,
        'Masuk',
        (r) => Scaffold(
          body: SingleChildScrollView(child: AuthSheet(repo: r)),
        ),
        textScale: scale,
        signedIn: false,
      );
    });
    testWidgets('quests$s', (t) async {
      await audit(
        t,
        'Misi',
        (r) => const Scaffold(body: _Quests()),
        textScale: scale,
      );
    });
  }
}

class _Quests extends StatelessWidget {
  const _Quests();
  @override
  Widget build(BuildContext context) => Builder(
    builder: (context) {
      WidgetsBinding.instance.addPostFrameCallback((_) => openQuests(context));
      return const SizedBox.expand();
    },
  );
}

class _Async extends StatefulWidget {
  const _Async({required this.load, required this.builder});
  final Future<Object?> Function() load;
  final Widget Function(Object?) builder;
  @override
  State<_Async> createState() => _AsyncState();
}

class _AsyncState extends State<_Async> {
  Object? data;
  bool done = false;
  @override
  void initState() {
    super.initState();
    widget.load().then((v) {
      if (mounted)
        setState(() {
          data = v;
          done = true;
        });
    });
  }

  @override
  Widget build(BuildContext context) =>
      done ? widget.builder(data) : const SizedBox();
}
