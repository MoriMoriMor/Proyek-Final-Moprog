@echo off
rem Jalankan Spots dari terminal Windows.
rem   run            mode demo di Chrome
rem   run live       data Supabase (butuh mobile\config.json)
rem   run demo ID    perangkat lain, lihat ID dengan: flutter devices
rem   run setup      buat mobile\config.json lalu buka untuk diisi
setlocal
set MODE=%~1
set DEVICE=%~2
if "%MODE%"=="" set MODE=demo
if "%DEVICE%"=="" set DEVICE=chrome
cd /d "%~dp0mobile"
if /i "%MODE%"=="setup" (
  if not exist config.json copy config.example.json config.json >nul
  echo Isi SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY, simpan, lalu jalankan: run live
  notepad config.json
  exit /b 0
)
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter belum terpasang. Panduan: https://docs.flutter.dev/get-started/install
  exit /b 1
)
if /i "%MODE%"=="live" (
  if not exist config.json (
    echo mobile\config.json belum ada. Salin dari config.example.json lalu isi URL dan key Supabase.
    exit /b 1
  )
  flutter run -d %DEVICE% --dart-define-from-file=config.json
) else (
  flutter run -d %DEVICE% --dart-define=SPOTS_DEMO=true
)
