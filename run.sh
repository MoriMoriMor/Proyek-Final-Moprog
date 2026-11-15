#!/usr/bin/env bash
# Jalankan Spots dari terminal macOS/Linux.
#   ./run.sh            mode demo di Chrome
#   ./run.sh live       data Supabase (butuh mobile/config.json)
#   ./run.sh demo ID    perangkat lain, lihat ID dengan: flutter devices
#   ./run.sh setup      buat mobile/config.json lalu isi
set -e
mode="${1:-demo}"
device="${2:-chrome}"
cd "$(dirname "$0")/mobile"
if [ "$mode" = "setup" ]; then
  [ -f config.json ] || cp config.example.json config.json
  echo "Isi SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY di mobile/config.json, lalu jalankan: ./run.sh live"
  "${EDITOR:-nano}" config.json
  exit 0
fi
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter belum terpasang. Panduan: https://docs.flutter.dev/get-started/install"
  exit 1
fi
if [ "$mode" = "live" ]; then
  if [ ! -f config.json ]; then
    echo "mobile/config.json belum ada. Salin dari config.example.json lalu isi URL dan key Supabase."
    exit 1
  fi
  flutter run -d "$device" --dart-define-from-file=config.json
else
  flutter run -d "$device" --dart-define=SPOTS_DEMO=true
fi
