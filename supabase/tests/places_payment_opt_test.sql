\ir ../migrations/202611240001_places_media_payment_opt.sql
-- Uji deduplikasi tempat berdekatan & pengamanan pesanan dari akun terblokir / spam antrean.

select pg_temp.act('00000000-0000-0000-0000-00000000000c');

do $$
declare
  v_first uuid;
  v_second uuid;
begin
  v_first := public.resolve_or_create_place(null, 'Kopi Sudut', 'kafe', 'Surabaya', -7.2600, 112.7400);
  v_second := public.resolve_or_create_place(null, '  kopi   sudut ', 'kafe', 'Surabaya', -7.2602, 112.7401);
  if v_first <> v_second then
    raise exception 'Tempat dengan nama sama dalam 65 m harus digabung otomatis';
  end if;
end $$;

-- Pembeli yang diblokir pemilik toko harus ditolak saat memesan.
select pg_temp.act('00000000-0000-0000-0000-00000000000b');
insert into public.user_blocks (blocker_id, blocked_id)
  values ('00000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-00000000000d')
  on conflict do nothing;

select pg_temp.act('00000000-0000-0000-0000-00000000000d');
select pg_temp.fails($$select public.place_order(
  (select id from public.stores where name = 'Kopi Teras' limit 1),
  jsonb_build_array(jsonb_build_object('product_id', (select id from public.products limit 1), 'qty', 1)),
  'ambil',
  gen_random_uuid()
)$$, 'Tidak dapat membuat pesanan');

\echo 'SEMUA UJI OPTIMASI TEMPAT & PEMBAYARAN LULUS'
